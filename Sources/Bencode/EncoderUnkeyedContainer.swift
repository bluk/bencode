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
    internal final class EncoderUnkeyedContainer {
        private var storage: [BencodeEncodingContainer] = []

        var count: Int {
            return storage.count
        }

        var nestedCodingPath: [CodingKey] {
            return self.codingPath + [AnyCodingKey(intValue: self.count)!]
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

extension _BencodeEncoder.EncoderUnkeyedContainer: UnkeyedEncodingContainer {
    func encodeNil() throws {
        var container = self.nestedSingleValueContainer()
        try container.encodeNil()
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        var container = self.nestedSingleValueContainer()
        try container.encode(value)
    }

    private func nestedSingleValueContainer() -> SingleValueEncodingContainer {
        let container = _BencodeEncoder.EncoderSingleValueContainer(
            codingPath: self.nestedCodingPath,
            userInfo: self.userInfo
        )
        self.storage.append(container)
        return container
    }

    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _BencodeEncoder.EncoderUnkeyedContainer(
            codingPath: self.nestedCodingPath,
            userInfo: self.userInfo
        )
        self.storage.append(container)
        return container
    }

    func nestedContainer<NestedKey>(keyedBy _: NestedKey.Type) -> KeyedEncodingContainer<NestedKey>
        where NestedKey: CodingKey {
        let container = _BencodeEncoder.EncoderKeyedContainer<NestedKey>(
            codingPath: self.nestedCodingPath,
            userInfo: self.userInfo
        )
        self.storage.append(container)
        return KeyedEncodingContainer(container)
    }

    func superEncoder() -> Encoder {
        fatalError("Unimplemented")
    }
}

extension _BencodeEncoder.EncoderUnkeyedContainer: BencodeEncodingContainer {
    var data: Data {
        var data = Data()
        guard let encodedLValue = "l".data(using: .ascii) else {
            fatalError("Could not encode 'l'")
        }
        data.append(encodedLValue)

        for container in storage {
            data.append(container.data)
        }

        guard let encodedEValue = "e".data(using: .ascii) else {
            fatalError("Could not encode 'e'")
        }
        data.append(encodedEValue)

        return data
    }
}
