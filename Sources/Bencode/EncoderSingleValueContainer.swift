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
    internal final class EncoderSingleValueContainer {
        private var storage = Data()

        fileprivate var canEncodeNewValue = true

        fileprivate func checkCanEncode(value: Any?) throws {
            guard self.canEncodeNewValue else {
                let context = EncodingError.Context(
                    codingPath: self.codingPath,
                    debugDescription: "Cannot encode multiple values with the same encoder."
                )
                throw EncodingError.invalidValue(value as Any, context)
            }
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

extension _BencodeEncoder.EncoderSingleValueContainer: SingleValueEncodingContainer {
    private func cannotEncode(_ value: Any, type: String) throws {
        let context = EncodingError.Context(
            codingPath: self.codingPath,
            debugDescription: "Cannot encode \(type)."
        )
        throw EncodingError.invalidValue(value, context)
    }

    private func encodeNumber<T>(_ value: T, type: String) throws {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        guard let encodedValue = "i\(value)e".data(using: .ascii) else {
            try cannotEncode(value, type: type)
            return
        }
        storage.append(encodedValue)
    }

    func encodeNil() throws {
        // Should pass in nil instead of false but making error handling easier
        try cannotEncode(false, type: "Nil")
    }

    func encode(_ value: Bool) throws {
        try cannotEncode(value, type: "Bool")
    }

    func encode(_ value: Float) throws {
        try cannotEncode(value, type: "Float")
    }

    func encode(_ value: Double) throws {
        try cannotEncode(value, type: "Double")
    }

    func encode(_ value: Int) throws {
        try encodeNumber(value, type: "Int")
    }

    func encode(_ value: UInt) throws {
        try encodeNumber(value, type: "UInt")
    }

    func encode(_ value: Int8) throws {
        try encodeNumber(value, type: "Int8")
    }

    func encode(_ value: Int16) throws {
        try encodeNumber(value, type: "Int16")
    }

    func encode(_ value: Int32) throws {
        try encodeNumber(value, type: "Int32")
    }

    func encode(_ value: Int64) throws {
        try encodeNumber(value, type: "Int64")
    }

    func encode(_ value: UInt8) throws {
        try encodeNumber(value, type: "UInt8")
    }

    func encode(_ value: UInt16) throws {
        try encodeNumber(value, type: "UInt16")
    }

    func encode(_ value: UInt32) throws {
        try encodeNumber(value, type: "UInt32")
    }

    func encode(_ value: UInt64) throws {
        try encodeNumber(value, type: "UInt64")
    }

    func encode(_ value: String) throws {
        let data = value.data(using: .utf8)
        try encode(data)
    }

    func encode<T>(_ value: T) throws where T: Encodable {
        try checkCanEncode(value: value)
        defer { self.canEncodeNewValue = false }

        switch value {
        case let data as Data:
            guard let encodedLength = "\(data.count):".data(using: .ascii) else {
                try cannotEncode(value, type: "Data")
                return
            }
            storage.append(encodedLength)
            storage.append(data)
        default:
            let encoder = _BencodeEncoder()
            try value.encode(to: encoder)
            storage.append(encoder.data)
        }
    }
}

extension _BencodeEncoder.EncoderSingleValueContainer: BencodeEncodingContainer {
    var data: Data {
        return storage
    }
}
