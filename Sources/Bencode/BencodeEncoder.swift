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

/// Encodes values using Bencode.
public final class BencodeEncoder {
    public init() {}
    /// Customization options
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    /// Encodes a value.
    public func encode(_ value: Encodable) throws -> Data {
        let encoder = _BencodeEncoder()
        encoder.userInfo = self.userInfo

        switch value {
        case let data as Data:
            try Box<Data>(data).encode(to: encoder)
        default:
            try value.encode(to: encoder)
        }

        return encoder.data
    }
}

internal protocol BencodeEncodingContainer {
    var data: Data { get }
}

// swiftlint:disable type_name
internal class _BencodeEncoder {
    var codingPath: [CodingKey] = []

    var userInfo: [CodingUserInfoKey: Any] = [:]

    fileprivate var container: BencodeEncodingContainer?

    var data: Data {
        return container?.data ?? Data()
    }
}

extension _BencodeEncoder: Encoder {
    fileprivate func assertCanCreateContainer() {
        precondition(self.container == nil)
    }

    func container<Key>(keyedBy _: Key.Type) -> KeyedEncodingContainer<Key> where Key: CodingKey {
        assertCanCreateContainer()

        let container = EncoderKeyedContainer<Key>(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        assertCanCreateContainer()

        let container = EncoderUnkeyedContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        assertCanCreateContainer()

        let container = EncoderSingleValueContainer(codingPath: self.codingPath, userInfo: self.userInfo)
        self.container = container

        return container
    }
}
