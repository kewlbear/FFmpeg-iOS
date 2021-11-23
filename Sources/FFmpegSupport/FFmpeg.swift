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
    argv = args.map { strdup($0) }
    let ret = HookMain(Int32(args.count), &argv)
    return Int(ret)
}
