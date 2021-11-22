//
//  FFmpeg-iOSTests.swift
//  
//
//  Created by 안창범 on 2021/11/08.
//

import XCTest
@testable import FFmpegSupport

class FFmpeg_iOSTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @available(iOS 13.0, *)
    func testExample() throws {
        guard let url = Bundle.module.url(forResource: "bear-320x240-video-only", withExtension: "webm") else { fatalError() }
        for _ in 1...2 {
            _ = try transcode(from: url, to: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.mp4"))
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
