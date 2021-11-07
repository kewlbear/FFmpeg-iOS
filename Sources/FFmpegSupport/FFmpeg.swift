//
//  FFmpeg.swift
//  
//
//  Created by Changbeom Ahn on 2021/11/05.
//

import Foundation
import ffmpeg
import Hook

@available(iOS 13.0, *)
var task: Task<Any, Error>?

@available(iOS 13.0, *)
public func transcode(from: URL, to url: URL) async -> Int {
    defer {
        print(#function, "exit")
    }
    let task = Task { () -> Int in
        let arguments = ["ffmpeg-ios", "-i", from.path, url.path]
        print(#function, arguments)
        var argv = arguments.map { strdup($0) }
        let ret = HookMain(Int32(arguments.count), &argv)
        print(#function, "FFmpeg_main:", ret)
        return Int(ret)
    }
    return await task.value
}

public class Bridge: NSObject {
    @objc public static var main: ((Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int)?
    
    @objc public static func exit(_ code: Int) {
        print(#function, code)
        if #available(iOS 13.0, *) {
            task?.cancel()
            sleep(.max)
        } else {
            // Fallback on earlier versions
        }
    }
}
