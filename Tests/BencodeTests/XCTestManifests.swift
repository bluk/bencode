#if !canImport(ObjectiveC)
import XCTest

extension BencodeTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__BencodeTests = [
        ("testDecode_ArrayInt", testDecode_ArrayInt),
        ("testDecode_ArrayString", testDecode_ArrayString),
        ("testDecode_Data", testDecode_Data),
        ("testDecode_Dictionary", testDecode_Dictionary),
        ("testDecode_IntNegative", testDecode_IntNegative),
        ("testDecode_IntPositive", testDecode_IntPositive),
        ("testDecode_IntZero", testDecode_IntZero),
        ("testDecode_String", testDecode_String),
        ("testDecode_UIntPositive", testDecode_UIntPositive),
        ("testEncode_ArrayInt", testEncode_ArrayInt),
        ("testEncode_ArrayString", testEncode_ArrayString),
        ("testEncode_Data", testEncode_Data),
        ("testEncode_Dictionary", testEncode_Dictionary),
        ("testEncode_IntNegative", testEncode_IntNegative),
        ("testEncode_IntPositive", testEncode_IntPositive),
        ("testEncode_IntZero", testEncode_IntZero),
        ("testEncode_String", testEncode_String),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BencodeTests.__allTests__BencodeTests),
    ]
}
#endif