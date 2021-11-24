//
//  FFmpeg.swift
//  
//
//  Created by Changbeom Ahn on 2021/11/05.
//

import Foundation
import ffmpeg
import Hook

var argv: [UnsafeMutablePointer<CChar>?] = []

public func ffmpeg(_ args: String...) -> Int {
    ffmpeg(args)
}

public func ffmpeg(_ args: [String]) -> Int {
    print(#function, args)
    argv = args.map { strdup($0) } // FIXME: free
    let ret = HookMain(Int32(args.count), &argv)
    return Int(ret)
}
