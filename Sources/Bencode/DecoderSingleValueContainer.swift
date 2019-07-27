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
    internal final class DecoderSingleValueContainer {
        var codingPath: [CodingKey]
        var userInfo: [CodingUserInfoKey: Any]

        var data: Data
        var index: Data.Index

        init(data: Data, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
            self.codingPath = codingPath
            self.userInfo = userInfo
            self.data = data
            self.index = self.data.startIndex
        }
    }
}

extension _BencodeDecoder.DecoderSingleValueContainer: SingleValueDecodingContainer {
    private func cannotDecode<T>(type: T.Type) throws -> T {
        let context = DecodingError.Context(
            codingPath: self.codingPath,
            debugDescription: "Cannot decode \(type)"
        )
        throw DecodingError.typeMismatch(Double.self, context)
    }

    func decodeNil() -> Bool {
        return false
    }

    func decode(_: Bool.Type) throws -> Bool {
        return try cannotDecode(type: Bool.self)
    }

    func decode(_: Double.Type) throws -> Double {
        return try cannotDecode(type: Double.self)
    }

    func decode(_: Float.Type) throws -> Float {
        return try cannotDecode(type: Float.self)
    }

    func decode(_: String.Type) throws -> String {
        let strData = try decode(Data.self)
        guard let string = String(data: strData, encoding: .utf8) else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Couldn't decode string with UTF-8 encoding: \(strData.hexadecimalString)"
            )
            throw DecodingError.dataCorrupted(context)
        }
        return string
    }

    func decode<T>(_: T.Type) throws -> T where T: BinaryInteger & Decodable {
        let prefix = try readByte()
        guard Unicode.Scalar(prefix) == Unicode.Scalar("i") else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected 'i' for starting integer. Got: \(Unicode.Scalar(prefix))"
            )
            throw DecodingError.dataCorrupted(context)
        }

        let negativeSignByte: [UInt8]
        if let nextByte = try peekByte() {
            if Unicode.Scalar(nextByte) == "-" {
                _ = try readByte()
                negativeSignByte = [nextByte]
            } else {
                negativeSignByte = []
            }
        } else {
            negativeSignByte = []
        }

        let numberBytes = try readNumbers()
        guard !numberBytes.isEmpty else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected integer to be non-empty"
            )
            throw DecodingError.dataCorrupted(context)
        }

        let suffix = try readByte()
        guard Unicode.Scalar(suffix) == Unicode.Scalar("e") else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Expected 'e' for ending integer. Got: \(Unicode.Scalar(suffix))"
            )
            throw DecodingError.dataCorrupted(context)
        }

        var binInt: T?
        if let numberStr = String(data: negativeSignByte + numberBytes, encoding: .utf8),
            let int64Value = Int64(numberStr) {
            binInt = T(exactly: int64Value)
        }

        guard let value = binInt else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Invalid type: \(T.self) for \((negativeSignByte + numberBytes).hexadecimalString)"
            )
            throw DecodingError.typeMismatch(T.self, context)
        }

        return value
    }

    func decode(_: Data.Type) throws -> Data {
        let numberBytes = try readNumbers()
        guard !numberBytes.isEmpty else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Invalid format: String"
            )
            throw DecodingError.typeMismatch(String.self, context)
        }

        let colonByte = try readByte()
        guard Unicode.Scalar(colonByte) == ":" else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Invalid format: String"
            )
            throw DecodingError.typeMismatch(String.self, context)
        }

        guard let numberStr = String(data: numberBytes, encoding: .utf8),
            let count = Int(numberStr) else {
            let context = DecodingError.Context(
                codingPath: self.codingPath,
                debugDescription: "Invalid format: String"
            )
            throw DecodingError.typeMismatch(String.self, context)
        }

        return try read(count)
    }

    func decode<T>(_ type: T.Type) throws -> T where T: Decodable {
        switch type {
        case is Data.Type:
            guard let value = try decode(Data.self) as? T else {
                let context = DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Cannot cast type to \(T.self)"
                )
                throw DecodingError.typeMismatch(T.self, context)
            }
            return value
        default:
            let decoder = _BencodeDecoder(data: self.data)
            let value = try T(from: decoder)
            if let nextIndex = decoder.container?.index {
                self.index = nextIndex
            }

            return value
        }
    }
}

extension _BencodeDecoder.DecoderSingleValueContainer: BencodeDecodingContainer {}
