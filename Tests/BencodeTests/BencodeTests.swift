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

import XCTest
@testable import Bencode

internal final class BencodeTests: XCTestCase {
    var encoder: BencodeEncoder!
    var decoder: BencodeDecoder!

    override func setUp() {
        encoder = BencodeEncoder()
        decoder = BencodeDecoder()

        super.setUp()
    }

    func testEncode_IntPositive() throws {
        let number = 14
        let data = try encoder.encode(number)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("i14e", string)
    }

    func testEncode_IntNegative() throws {
        let number = -14
        let data = try encoder.encode(number)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("i-14e", string)
    }

    func testEncode_IntZero() throws {
        let number = 0
        let data = try encoder.encode(number)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("i0e", string)
    }

    func testEncode_String() throws {
        let str = "Hello, world!"
        let data = try encoder.encode(str)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("\(str.utf8.count):\(str)", string)
    }

    func testEncode_Data() throws {
        let str = "Hello, world!"
        let strData = "Hello, world!".data(using: .utf8)
        let data = try encoder.encode(strData)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("\(str.utf8.count):\(str)", string)
    }

    func testEncode_ArrayInt() throws {
        let arr = [1, 2]
        let data = try encoder.encode(arr)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("li1ei2ee", string)
    }

    func testEncode_ArrayString() throws {
        let arr: [String] = ["spam", "egg"]
        let data = try encoder.encode(arr)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("l4:spam3:egge", string)
    }

    func testEncode_Dictionary() throws {
        let dict: [String: String] = ["spam": "egg", "foo": "bar"]
        let data = try encoder.encode(dict)
        guard let string = String(data: data, encoding: .utf8) else {
            XCTFail("Could not decode data")
            return
        }
        XCTAssertEqual("d3:foo3:bar4:spam3:egge", string)
    }

    func testDecode_IntPositive() throws {
        let number = 14
        let data = try encoder.encode(number)

        let value = try decoder.decode(Int.self, from: data)
        XCTAssertEqual(14, value)
    }

    func testDecode_IntNegative() throws {
        let number = -14
        let data = try encoder.encode(number)

        let value = try decoder.decode(Int.self, from: data)
        XCTAssertEqual(-14, value)
    }

    func testDecode_IntZero() throws {
        let number = 0
        let data = try encoder.encode(number)

        let value = try decoder.decode(Int.self, from: data)
        XCTAssertEqual(number, value)
    }

    func testDecode_UIntPositive() throws {
        let number = 14
        let data = try encoder.encode(number)

        let value = try decoder.decode(UInt.self, from: data)
        XCTAssertEqual(14, value)
    }

    func testDecode_String() throws {
        let str = "Hello, world!"
        let data = try encoder.encode(str)

        let value = try decoder.decode(String.self, from: data)
        XCTAssertEqual(str, value)
    }

    func testDecode_Data() throws {
        let str = "Hello, world!"
        let data = try encoder.encode(str.data(using: .utf8))

        let value = try decoder.decode(Data.self, from: data)
        XCTAssertEqual(str, String(data: value, encoding: .utf8))
    }

    func testDecode_ArrayInt() throws {
        let arr = [1, 2]
        let data = try encoder.encode(arr)

        let value = try decoder.decode([Int].self, from: data)
        XCTAssertEqual(arr, value)
    }

    func testDecode_ArrayString() throws {
        let arr: [String] = ["spam", "egg"]
        let data = try encoder.encode(arr)

        let value = try decoder.decode([String].self, from: data)
        XCTAssertEqual(arr, value)
    }

    func testDecode_Dictionary() throws {
        let dict: [String: String] = ["spam": "egg", "foo": "bar"]
        let data = try encoder.encode(dict)

        let value = try decoder.decode([String: String].self, from: data)
        XCTAssertEqual(dict, value)
    }
}
