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

extension _BencodeEncoder {
    internal final class EncoderKeyedContainer<Key> where Key: CodingKey {
        private var storage: [AnyCodingKey: BencodeEncodingContainer] = [:]

        func nestedCodingPath(forKey key: CodingKey) -> [CodingKey] {
            return self.codingPath + [key]
        }

        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        init(
            codingPath: [CodingKey],
            userInfo: [CodingUserInfoKey: Any]
        ) {
            self.codingPath = codingPath
            self.userInfo = userInfo
        }
    }
}

extension _BencodeEncoder.EncoderKeyedContainer: KeyedEncodingContainerProtocol {
    func encodeNil(forKey key: Key) throws {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encodeNil()
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T: Encodable {
        var container = self.nestedSingleValueContainer(forKey: key)
        try container.encode(value)
    }

    private func nestedSingleValueContainer(forKey key: Key) -> SingleValueEncodingContainer {
        let container = _BencodeEncoder.EncoderSingleValueContainer(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo
        )
        self.storage[AnyCodingKey(key)] = container
        return container
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _BencodeEncoder.EncoderUnkeyedContainer(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo
        )
        self.storage[AnyCodingKey(key)] = container
        return container
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey {
        let container = _BencodeEncoder.EncoderKeyedContainer<NestedKey>(
            codingPath: self.nestedCodingPath(forKey: key),
            userInfo: self.userInfo
        )
        self.storage[AnyCodingKey(key)] = container
        return KeyedEncodingContainer(container)
    }

    // swiftlint:disable unavailable_function

    func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }

    func superEncoder(forKey _: Key) -> Encoder {
        fatalError("Unimplemented")
    }

    // swiftlint:enable unavailable_function
}

extension _BencodeEncoder.EncoderKeyedContainer: BencodeEncodingContainer {
    var data: Data {
        var data = Data()

        guard let encodedLValue = "d".data(using: .ascii) else {
            fatalError("Could not encode 'd'")
        }
        data.append(encodedLValue)

        storage.keys.sorted().forEach { key in
            let keyContainer = _BencodeEncoder.EncoderSingleValueContainer(
                codingPath: self.codingPath,
                userInfo: self.userInfo
            )
            try! keyContainer.encode(key.stringValue)
            data.append(keyContainer.data)

            guard let container = storage[key] else {
                fatalError()
            }
            data.append(container.data)
        }

        guard let encodedEValue = "e".data(using: .ascii) else {
            fatalError("Could not encode 'e'")
        }
        data.append(encodedEValue)
        return data
    }
}
