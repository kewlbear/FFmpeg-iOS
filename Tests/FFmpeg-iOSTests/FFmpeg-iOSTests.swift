// FFmpeg-iOS: Swift package to use FFmpeg in your iOS apps
// Copyright (C) 2023  Changbeom Ahn
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

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
    func testFFmpeg() throws {
        for _ in 1..<2 {
            _ = ffmpeg([
                "ffmpeg",
//                "-bsfs"
                "-y",
                "-i", "https://dl6.webmfiles.org/big-buck-bunny_trailer.webm",
                URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("test.mp4")
                    .path
            ])
        }
    }

    @available(iOS 13.0, *)
    func testFFprobe() throws {
        for _ in 1..<2 {
            _ = ffprobe([
                "ffprobe",
                "https://dl6.webmfiles.org/big-buck-bunny_trailer.webm",
            ])
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
