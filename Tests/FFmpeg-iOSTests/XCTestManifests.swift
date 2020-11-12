import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FFmpeg_iOSTests.allTests),
    ]
}
#endif
