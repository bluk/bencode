//  Copyright 2019 Bryant Luk
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

import struct Foundation.Data

/// Decodes bencoded data.
public final class BencodeDecoder {
    /// Designated initializer.
    public init() {}
    /// Decoding options.
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Decode data to a type.
    public func decode<T>(_ type: T.Type, from data: Data) throws -> T where T: Decodable {
        let decoder = _BencodeDecoder(data: data)
        decoder.userInfo = self.userInfo

        switch type {
        case is Data.Type:
            let box = try Box<Data>(from: decoder)
            guard let value = box.value as? T else {
                let context = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Cannot cast type to \(T.self)"
                )
                throw DecodingError.typeMismatch(T.self, context)
            }
            return value
        default:
            return try T(from: decoder)
        }
    }
}

// swiftlint:disable type_name
/// The internal BencodeDecoder to use.
public final class _BencodeDecoder {
    public var codingPath: [CodingKey] = []
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    var container: BencodeDecodingContainer?
    /// The data that is being decoded.
    internal var data: Data

    public var decodedData: Data {
        if let container = container {
            return container.data.subdata(in: container.data.startIndex..<container.index)
        }

        return data
    }

    init(data: Data) {
        self.data = data
    }
}

// swiftlint:enable type_name

extension _BencodeDecoder: Decoder {
    private func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    public func container<Key>(keyedBy _: Key.Type) -> KeyedDecodingContainer<Key> where Key: CodingKey {
        assertCanCreateContainer()

        let container = DecoderKeyedContainer<Key>(
            data: self.data,
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )
        self.container = container

        return KeyedDecodingContainer(container)
    }

    public func unkeyedContainer() -> UnkeyedDecodingContainer {
        assertCanCreateContainer()

        let container = DecoderUnkeyedContainer(
            data: self.data,
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )
        self.container = container

        return container
    }

    public func singleValueContainer() -> SingleValueDecodingContainer {
        assertCanCreateContainer()

        let container = DecoderSingleValueContainer(
            data: self.data,
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )
        self.container = container

        return container
    }
}

internal protocol BencodeDecodingContainer: AnyObject {
    var codingPath: [CodingKey] { get set }

    var userInfo: [CodingUserInfoKey: Any] { get }

    var data: Data { get set }
    var index: Data.Index { get set }
}

private let number0: Unicode.Scalar = "0"
private let number9: Unicode.Scalar = "9"

extension BencodeDecodingContainer {
    func readByte() throws -> UInt8 {
        return try read(1).first!
    }

    func peekByte() throws -> UInt8? {
        guard self.index < self.data.endIndex else {
            return nil
        }
        return self.data[self.index]
    }

    func isNumber(byte: UInt8) -> Bool {
        let scalar = Unicode.Scalar(byte)
        return (number0 <= scalar) && (scalar <= number9)
    }

    func readNumbers() throws -> Data {
        var numbers: [UInt8] = []
        while let nextByte = try peekByte() {
            if isNumber(byte: nextByte) {
                numbers.append(try readByte())
            } else {
                break
            }
        }
        return Data(numbers)
    }

    func read(_ length: Int) throws -> Data {
        let nextIndex = self.index.advanced(by: length)
        guard nextIndex <= self.data.endIndex else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Unexpected end of data"
            )
            throw DecodingError.dataCorrupted(context)
        }
        defer { self.index = nextIndex }

        return self.data.subdata(in: self.index..<nextIndex)
    }

    // swiftlint:disable function_body_length
    func decodeContainer() throws -> BencodeDecodingContainer {
        let startIndex = self.index

        let nextChar = try readByte()
        let unicodeNextChar = Unicode.Scalar(nextChar)

        switch unicodeNextChar {
        case "l":
            let container = _BencodeDecoder.DecoderUnkeyedContainer(
                data: self.data.suffix(from: startIndex),
                codingPath: self.codingPath,
                userInfo: self.userInfo
            )
            _ = try container.decodeNestedContainers()
            self.index = container.index

            return container
        case "d":
            let container = _BencodeDecoder.DecoderKeyedContainer<AnyCodingKey>(
                data: self.data.suffix(from: startIndex),
                codingPath: self.codingPath,
                userInfo: self.userInfo
            )
            _ = try container.decodeNestedContainers()
            self.index = container.index

            return container
        case "i":
            _ = try readNumbers()
            let eByte = try readByte()
            guard Unicode.Scalar(eByte) == "e" else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Expected 'e' for ending integer. Got: \(Unicode.Scalar(eByte))"
                )
                throw DecodingError.dataCorrupted(context)
            }
        case Unicode.Scalar("0")...Unicode.Scalar("9"):
            let remainingCountBytes = try readNumbers()
            let countBytes = [nextChar] + remainingCountBytes
            let colonByte = try readByte()
            guard Unicode.Scalar(colonByte) == ":" else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Expected ':' after byte string length. Got: \(Unicode.Scalar(colonByte))"
                )
                throw DecodingError.dataCorrupted(context)
            }

            guard let numberStr = String(data: Data(countBytes), encoding: .utf8),
                let count = Int(numberStr) else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Could not decode number for byte string length. Data: "
                        + "\(Data(countBytes).hexadecimalString)"
                )
                throw DecodingError.dataCorrupted(context)
            }
            _ = try read(count)
        default:
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Unknown bencode value start delimiter: \(unicodeNextChar)"
            )
            throw DecodingError.dataCorrupted(context)
        }
        let range: Range<Data.Index> = startIndex..<self.index

        let container = _BencodeDecoder.DecoderSingleValueContainer(
            data: self.data.subdata(in: range),
            codingPath: self.codingPath,
            userInfo: self.userInfo
        )
        return container
    }

    // swiftlint:enable function_body_length
}

internal extension Data {
    var hexadecimalString: String {
        return self
            .compactMap { byte in
                if byte <= 15 {
                    return "0" + String(byte, radix: 16)
                }
                return String(byte, radix: 16)
            }
            .joined()
    }
}
