import XCTest

import BencodeTests

var tests = [XCTestCaseEntry]()
tests += BencodeTests.__allTests()

XCTMain(tests)
