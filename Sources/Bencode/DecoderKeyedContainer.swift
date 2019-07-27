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
    final class DecoderKeyedContainer<Key> where Key: CodingKey {
        var data: Data
        var index: Data.Index
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]
        // swiftlint:disable discouraged_optional_collection
        var cachedNestedContainers: [String: BencodeDecodingContainer]?
        // swiftlint:enable discouraged_optional_collection

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        // swiftlint:disable function_body_length
        func decodeNestedContainers() throws -> [String: BencodeDecodingContainer] {
            if let cachedNestedContainers = cachedNestedContainers {
                return cachedNestedContainers
            }

            var nestedContainers: [String: BencodeDecodingContainer] = [:]
            let nextByte = try readByte()
            guard Unicode.Scalar(nextByte) == "d" else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Expected dictionary to start with 'd'. Got: \(Unicode.Scalar(nextByte))"
                )
                throw DecodingError.dataCorrupted(context)
            }

            while true {
                guard let nextByte = try peekByte() else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Could not peek next character"
                    )
                    throw DecodingError.dataCorrupted(context)
                }

                let unicodeScalarE: Unicode.Scalar = "e"
                if Unicode.Scalar(nextByte) == unicodeScalarE {
                    _ = try readByte()
                    break
                }

                let startIndex = self.index

                let remainingCountBytes = try readNumbers()
                guard !remainingCountBytes.isEmpty else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Empty number for byte string length"
                    )
                    throw DecodingError.dataCorrupted(context)
                }
                let colonByte = try readByte()
                guard Unicode.Scalar(colonByte) == ":" else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Expected ':' after byte string length. Got: \(Unicode.Scalar(colonByte))"
                    )
                    throw DecodingError.dataCorrupted(context)
                }
                guard let numberStr = String(data: Data(remainingCountBytes), encoding: .utf8),
                    let count = Int(numberStr) else {
                    let context = DecodingError.Context(
                        codingPath: self.codingPath,
                        debugDescription: "Could not decode number for byte string length. Data: "
                            + "\(Data(remainingCountBytes).hexadecimalString)"
                    )
                    throw DecodingError.dataCorrupted(context)
                }
                _ = try read(count)

                let range = startIndex..<self.index
                let keyContainer = _BencodeDecoder.DecoderSingleValueContainer(
                    data: self.data.subdata(in: range),
                    codingPath: self.codingPath,
                    userInfo: self.userInfo
                )
                let key = try keyContainer.decode(String.self)

                let container = try decodeContainer()
                container.codingPath += [AnyCodingKey(stringValue: key)!]
                nestedContainers[key] = container
            }

            self.cachedNestedContainers = nestedContainers
            return nestedContainers
        }

        // swiftlint:enable function_body_length

        func checkCanDecodeValue(forKey key: Key) throws {
            guard try self.decodeNestedContainers().keys.contains(key.stringValue) else {
                let context = DecodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Could not find key \(key) from \(allKeys)"
                )
                throw DecodingError.keyNotFound(key, context)
            }
        }
    }
}

extension _BencodeDecoder.DecoderKeyedContainer: KeyedDecodingContainerProtocol {
    var allKeys: [Key] {
        do {
            return try self.decodeNestedContainers().keys.compactMap {
                guard let key = Key(stringValue: $0) else {
                    return nil
                }
                return key
            }
        } catch {
            return []
        }
    }

    func contains(_ key: Key) -> Bool {
        do {
            return try self.decodeNestedContainers().keys.contains(key.stringValue)
        } catch {
            return false
        }
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        try checkCanDecodeValue(forKey: key)

        return false
    }

    func decode<T>(_: T.Type, forKey key: Key) throws -> T where T: Decodable {
        try checkCanDecodeValue(forKey: key)

        let container = try self.decodeNestedContainers()[key.stringValue]!
        let decoder = BencodeDecoder()
        let value = try decoder.decode(T.self, from: container.data)

        return value
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        try checkCanDecodeValue(forKey: key)

        guard let unkeyedContainer = try self.decodeNestedContainers()[key.stringValue]
            as? _BencodeDecoder.DecoderUnkeyedContainer else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Cannot decode nested unkeyed container for key: \(key)"
            )
        }

        return unkeyedContainer
    }

    func nestedContainer<NestedKey>(
        keyedBy _: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        try checkCanDecodeValue(forKey: key)
        guard let container = try self.decodeNestedContainers()[key.stringValue] else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Cannot decode nested container for key: \(key)"
            )
        }
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

    func superDecoder(forKey key: Key) throws -> Decoder {
        guard let container = try self.decodeNestedContainers()[key.stringValue] else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: self,
                debugDescription: "Cannot decode value for key: \(key)"
            )
        }

        let decoder = _BencodeDecoder(data: container.data)
        decoder.codingPath = self.codingPath + [key]
        return decoder
    }
}

extension _BencodeDecoder.DecoderKeyedContainer: BencodeDecodingContainer {}
