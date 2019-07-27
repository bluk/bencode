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

extension _BencodeDecoder {
    final class DecoderUnkeyedContainer {
        var codingPath: [CodingKey]

        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.currentIndex)!]
        }

        var userInfo: [CodingUserInfoKey: Any]

        var data: Data
        var index: Data.Index

        lazy var count: Int? = {
            guard builtNestedContainers else {
                return nil
            }
            return try? decodeNestedContainers().count
        }()

        var currentIndex: Int = 0
        var builtNestedContainers = false

        // swiftlint:disable discouraged_optional_collection
        var cachedNestedContainers: [BencodeDecodingContainer]?
        // swiftlint:enable discouraged_optional_collection

        func decodeNestedContainers() throws -> [BencodeDecodingContainer] {
            if let cachedNestedContainers = cachedNestedContainers {
                return cachedNestedContainers
            }

            var nestedContainers: [BencodeDecodingContainer] = []

            let nextByte = try readByte()
            guard Unicode.Scalar(nextByte) == "l" else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Expected list to start with 'l'. Got: \(Unicode.Scalar(nextByte))"
                )
                throw DecodingError.dataCorrupted(context)
            }

            while true {
                guard let nextByte = try peekByte() else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Expected list to end with 'e'. Could not read next byte"
                    )
                    throw DecodingError.dataCorrupted(context)
                }

                let unicodeScalarE: Unicode.Scalar = "e"
                if Unicode.Scalar(nextByte) == unicodeScalarE {
                    _ = try readByte()
                    break
                }

                let container = try self.decodeContainer()
                nestedContainers.append(container)
            }
            self.builtNestedContainers = true
            self.currentIndex = 0
            self.cachedNestedContainers = nestedContainers
            return nestedContainers
        }

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }

        var isAtEnd: Bool {
            do {
                let count = try decodeNestedContainers().count
                return currentIndex >= count
            } catch {
                return true
            }
        }

        func checkCanDecodeValue() throws {
            guard builtNestedContainers else {
                return
            }

            guard !self.isAtEnd else {
                let context = DecodingError.Context(
                    codingPath: self.nestedCodingPath,
                    debugDescription: "Unexpected end of data at index: \(currentIndex)"
                )
                throw DecodingError.dataCorrupted(context)
            }
        }
    }
}

extension _BencodeDecoder.DecoderUnkeyedContainer: UnkeyedDecodingContainer {
    func decodeNil() throws -> Bool {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        guard let container = try self.decodeNestedContainers()[self.currentIndex]
            as? _BencodeDecoder.DecoderSingleValueContainer else {
            let context = DecodingError.Context(
                codingPath: self.nestedCodingPath,
                debugDescription: "Cannot decode nested single value for index: \(self.currentIndex)"
            )
            throw DecodingError.dataCorrupted(context)
        }

        let value = container.decodeNil()
        return value
    }

    func decode<T>(_: T.Type) throws -> T where T: Decodable {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = try self.decodeNestedContainers()[self.currentIndex]
        let decoder = BencodeDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        guard let container = try self.decodeNestedContainers()[self.currentIndex]
            as? _BencodeDecoder.DecoderUnkeyedContainer else {
            let context = DecodingError.Context(
                codingPath: self.nestedCodingPath,
                debugDescription: "Cannot decode nested unkeyed container for index: \(self.currentIndex)"
            )
            throw DecodingError.dataCorrupted(context)
        }

        return container
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey>
        where NestedKey: CodingKey {
        try checkCanDecodeValue()
        defer { self.currentIndex += 1 }

        let container = try self.decodeNestedContainers()[self.currentIndex]
        let keyedContainer = _BencodeDecoder.DecoderKeyedContainer<NestedKey>(
            data: container.data,
            codingPath: container.codingPath,
            userInfo: container.userInfo
        )

        return KeyedDecodingContainer(keyedContainer)
    }

    func superDecoder() throws -> Decoder {
        return _BencodeDecoder(data: self.data)
    }
}

extension _BencodeDecoder.DecoderUnkeyedContainer: BencodeDecodingContainer {}
