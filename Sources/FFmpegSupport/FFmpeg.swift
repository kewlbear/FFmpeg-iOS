//
//  FFmpeg.swift
//  
//
//  Created by Changbeom Ahn on 2021/11/05.
//

import Foundation
import ffmpeg
import Hook
import avformat
import avcodec
import avutil
import avfilter
import swscale

@available(iOS 13.0, *)
var task: Task<Any, Error>?

var argv: [UnsafeMutablePointer<CChar>?] = []

public func ffmpeg(_ args: [String]) -> Int {
    argv = args.map { strdup($0) }
    let ret = HookMain(Int32(args.count), &argv)
    return Int(ret)
}

@available(iOS 13.0, *)
public func transcode(from: URL, to url: URL) throws {
    var (ifmt_ctx, stream_ctx) = try openInputFile(from.path)
    defer {
        for i in 0..<Int(ifmt_ctx!.pointee.nb_streams) {
            avcodec_free_context(&stream_ctx[i].dec_ctx)
        }
        avformat_close_input(&ifmt_ctx)
    }
    
    let ofmt_ctx = try openOutputFile(url.path, ifmt_ctx: ifmt_ctx!, stream_ctx: &stream_ctx)
    defer {
        for i in 0..<Int(ifmt_ctx!.pointee.nb_streams) {
            if ofmt_ctx.pointee.nb_streams > i && ofmt_ctx.pointee.streams[i] != nil && stream_ctx[i].enc_ctx != nil {
                avcodec_free_context(&stream_ctx[i].enc_ctx)
            }
        }
        
        if ofmt_ctx.pointee.oformat.pointee.flags & AVFMT_NOFILE != 0 {
            avio_closep(&ofmt_ctx.pointee.pb)
        }
        avformat_free_context(ofmt_ctx)
    }
    
    var filter_ctx = try initFilters(ifmt_ctx: ifmt_ctx!, stream_ctx: stream_ctx)
    defer {
        for i in 0..<Int(ifmt_ctx!.pointee.nb_streams) {
            if filter_ctx[i].filter_graph != nil {
                avfilter_graph_free(&filter_ctx[i].filter_graph)
                av_packet_free(&filter_ctx[i].enc_pkt)
                av_frame_free(&filter_ctx[i].filtered_frame)
            }
        }
    }
    
    var packet: UnsafeMutablePointer<AVPacket>? = av_packet_alloc()
    guard packet != nil else {
        throw FFmpegError.av_err(code: AVERROR(ENOMEM))
    }
    defer { av_packet_free(&packet) }
    
    while true {
        let ret = av_read_frame(ifmt_ctx, packet)
        guard ret >= 0 else {
            av_log(nil, AV_LOG_ERROR, "Error occurred: \(FFmpegError.av_err(code: ret).errorDescription ?? "\(ret)")")
            break
        }
        let stream_index = Int(packet!.pointee.stream_index)
        av_log(nil, AV_LOG_DEBUG, "Demuxer gave frame of stream_index \(stream_index)")
        
        if filter_ctx[stream_index].filter_graph != nil {
            let stream = stream_ctx[stream_index]
            
            av_log(nil, AV_LOG_DEBUG, "Going to reencode&filter the frame")
            
            av_packet_rescale_ts(packet, ifmt_ctx!.pointee.streams[stream_index]!.pointee.time_base, stream.dec_ctx!.pointee.time_base)
            try check(avcodec_send_packet(stream.dec_ctx, packet), message: "Decoding failed")
            
            while true {
                let ret = avcodec_receive_frame(stream.dec_ctx, stream.dec_frame)
                if ret == AVERROR_EOF || ret == AVERROR(EAGAIN) { break }
                else if ret < 0 { throw FFmpegError.av_err(code: ret) }
                
                stream.dec_frame?.pointee.pts = stream.dec_frame!.pointee.best_effort_timestamp
                try filter_encode_write_frame(stream.dec_frame!, stream_index: stream_index, filter_ctx: filter_ctx, stream_ctx: stream_ctx, ofmt_ctx: ofmt_ctx)
            }
        } else {
            av_packet_rescale_ts(packet, ifmt_ctx!.pointee.streams[stream_index]!.pointee.time_base, ofmt_ctx.pointee.streams[stream_index]!.pointee.time_base)
            
            try check(av_interleaved_write_frame(ofmt_ctx, packet))
        }
        av_packet_unref(packet)
    }
    
    for i in 0..<Int(ifmt_ctx!.pointee.nb_streams) {
        guard filter_ctx[i].filter_graph != nil else { continue }
        try filter_encode_write_frame(nil, stream_index: i, filter_ctx: filter_ctx, stream_ctx: stream_ctx, ofmt_ctx: ofmt_ctx)
        
        try flush_encoder(stream_index: i, stream_ctx: stream_ctx, filter_ctx: filter_ctx, ofmt_ctx: ofmt_ctx)
    }
    
    av_write_trailer(ofmt_ctx)
}

struct StreamContext {
    var dec_ctx: UnsafeMutablePointer<AVCodecContext>?
    var enc_ctx: UnsafeMutablePointer<AVCodecContext>?
    
    var dec_frame: UnsafeMutablePointer<AVFrame>?
}

struct FilteringContext {
    var buffersink_ctx: UnsafeMutablePointer<AVFilterContext>?
    var buffersrc_ctx: UnsafeMutablePointer<AVFilterContext>?
    var filter_graph: UnsafeMutablePointer<AVFilterGraph>?
    
    var enc_pkt: UnsafeMutablePointer<AVPacket>?
    var filtered_frame: UnsafeMutablePointer<AVFrame>?
}

let AVERROR_EOF = FFERRTAG("E", "O", "F", " ")

enum FFmpegError: LocalizedError {
    case av_err(code: Int32)
    
    static let decoderNotFound: Self = .av_err(code: FFERRTAG("\u{F8}", "D", "E", "C"))
    static let unknown: Self = .av_err(code: FFERRTAG("U", "N", "K", "N"))
    static let invalidData: Self = .av_err(code: FFERRTAG("I", "N", "D", "A"))
    
    var errorDescription: String? {
        guard case .av_err(let code) = self else { fatalError() }
        var buffer = [CChar](repeating: 0, count: 1024)
        let ret = av_strerror(code, &buffer, buffer.count)
        return ret == 0 ? String(cString: buffer, encoding: .utf8) : "Error \(code) (av_strerror=\(ret))"
    }
}

func openInputFile(_ filename: String) throws -> (UnsafeMutablePointer<AVFormatContext>?, [StreamContext]) {
    var ifmt_ctx: UnsafeMutablePointer<AVFormatContext>?
    try check(avformat_open_input(&ifmt_ctx, filename, nil, nil))
    var shouldClose = true
    defer {
        if shouldClose {
            avformat_close_input(&ifmt_ctx)
        }
    }
    
    try check(avformat_find_stream_info(ifmt_ctx, nil))
    var stream_ctx: [StreamContext] = []
    for i in 0..<Int(ifmt_ctx!.pointee.nb_streams) {
        let stream = ifmt_ctx?.pointee.streams[i]
        guard let dec = avcodec_find_decoder(stream!.pointee.codecpar.pointee.codec_id) else {
            throw FFmpegError.decoderNotFound
        }
        guard let codec_ctx = avcodec_alloc_context3(dec) else {
            throw FFmpegError.av_err(code: AVERROR(ENOMEM))
        }
        try check(avcodec_parameters_to_context(codec_ctx, stream!.pointee.codecpar))
        
        switch codec_ctx.pointee.codec_type {
        case AVMEDIA_TYPE_VIDEO, AVMEDIA_TYPE_AUDIO:
            if codec_ctx.pointee.codec_type == AVMEDIA_TYPE_VIDEO {
                codec_ctx.pointee.framerate = av_guess_frame_rate(ifmt_ctx, stream, nil)
            }
            try check(avcodec_open2(codec_ctx, dec, nil))
        default: break
        }
        stream_ctx.append(StreamContext(dec_ctx: codec_ctx, enc_ctx: nil, dec_frame: av_frame_alloc()))
        guard stream_ctx[i].dec_frame != nil else {
            throw FFmpegError.av_err(code: AVERROR(ENOMEM))
        }
    }
    
    av_dump_format(ifmt_ctx, 0, filename, 0)
    shouldClose = false
    return (ifmt_ctx, stream_ctx)
}

func openOutputFile(_ filename: String, ifmt_ctx: UnsafeMutablePointer<AVFormatContext>, stream_ctx: inout [StreamContext]) throws -> UnsafeMutablePointer<AVFormatContext> {
    var ofmt_ctx: UnsafeMutablePointer<AVFormatContext>?
    try check(avformat_alloc_output_context2(&ofmt_ctx, nil, nil, filename), message: "Could not create output context")
    
    for i in 0..<Int(ifmt_ctx.pointee.nb_streams) {
        guard let out_stream = avformat_new_stream(ofmt_ctx, nil) else {
            av_log(nil, AV_LOG_ERROR, "Failed allocating output stream")
            throw FFmpegError.unknown
        }
        
        let in_stream = ifmt_ctx.pointee.streams[i]!
        let dec_ctx = stream_ctx[i].dec_ctx!
        
        let type = dec_ctx.pointee.codec_type
        switch type {
        case AVMEDIA_TYPE_VIDEO, AVMEDIA_TYPE_AUDIO:
            out_stream.pointee.codecpar.pointee.codec_id = AV_CODEC_ID_H264//av_guess_codec(ofmt_ctx!.pointee.oformat, nil, filename, nil, type)
            
            let qcr = avformat_query_codec(ofmt_ctx!.pointee.oformat, ofmt_ctx!.pointee.oformat.pointee.video_codec, 0)
            assert(qcr >= 0)
            
            guard let encoder = avcodec_find_encoder(out_stream.pointee.codecpar.pointee.codec_id) else {
                av_log(nil, AV_LOG_FATAL, "Necessary encoder not found")
                throw FFmpegError.invalidData
            }
            guard let enc_ctx = avcodec_alloc_context3(encoder) else {
                av_log(nil, AV_LOG_FATAL, "Failed to allocate the encoder context")
                throw FFmpegError.av_err(code: AVERROR(ENOMEM))
            }
            
            // FIXME: choose suitable properties?
            if dec_ctx.pointee.codec_type == AVMEDIA_TYPE_VIDEO {
                enc_ctx.pointee.height = dec_ctx.pointee.height
                enc_ctx.pointee.width = dec_ctx.pointee.width
                enc_ctx.pointee.sample_aspect_ratio = dec_ctx.pointee.sample_aspect_ratio
                // FIXME: choose suitable format
                if encoder.pointee.pix_fmts != nil {
                    enc_ctx.pointee.pix_fmt = encoder.pointee.pix_fmts.pointee
                } else {
                    enc_ctx.pointee.pix_fmt = dec_ctx.pointee.pix_fmt
                }
                enc_ctx.pointee.time_base = av_inv_q(dec_ctx.pointee.framerate)
            } else {
                enc_ctx.pointee.sample_rate = dec_ctx.pointee.sample_rate
                enc_ctx.pointee.channel_layout = dec_ctx.pointee.channel_layout
                enc_ctx.pointee.channels = av_get_channel_layout_nb_channels(enc_ctx.pointee.channel_layout)
                // FIXME: choose suitable format
                enc_ctx.pointee.sample_fmt = encoder.pointee.sample_fmts.pointee
                enc_ctx.pointee.time_base = AVRational(num: 1, den: enc_ctx.pointee.sample_rate)
            }
            
            if (ofmt_ctx!.pointee.oformat.pointee.flags & AVFMT_GLOBALHEADER) != 0 {
                enc_ctx.pointee.flags |= AV_CODEC_FLAG_GLOBAL_HEADER
            }
            
            // FIXME: pass settings to encoder
            try check(avcodec_open2(enc_ctx, encoder, nil), message: "Cannot open video encoder for stream #\(i)")
            try check(avcodec_parameters_from_context(out_stream.pointee.codecpar, enc_ctx), message: "Failed to copy encoder parameters to output stream #\(i)")
            
            out_stream.pointee.time_base = enc_ctx.pointee.time_base
            stream_ctx[i].enc_ctx = enc_ctx
        case AVMEDIA_TYPE_UNKNOWN:
            av_log(nil, AV_LOG_FATAL, "Elementary stream #\(i) is of unknown type, cannot proceed")
            throw FFmpegError.invalidData
        default:
            try check(avcodec_parameters_copy(out_stream.pointee.codecpar, in_stream.pointee.codecpar), message: "Copying parameters for stream #\(i) failed")
            out_stream.pointee.time_base = in_stream.pointee.time_base
        }
    }
    av_dump_format(ofmt_ctx, 0, filename, 1)
    
    if (ofmt_ctx!.pointee.oformat.pointee.flags & AVFMT_NOFILE) == 0 {
        try check(avio_open(&ofmt_ctx!.pointee.pb, filename, AVIO_FLAG_WRITE), message: "Could not open output file '\(filename)'")
    }
    
    try check(avformat_write_header(ofmt_ctx, nil), message: "Error occurred when opening output file")
    
    return ofmt_ctx!
}

func initFilters(ifmt_ctx: UnsafeMutablePointer<AVFormatContext>, stream_ctx: [StreamContext]) throws -> [FilteringContext] {
    var filter_ctx: [FilteringContext] = []
    
    for i in 0..<Int(ifmt_ctx.pointee.nb_streams) {
        let type = ifmt_ctx.pointee.streams[i]?.pointee.codecpar.pointee.codec_type
        guard type == AVMEDIA_TYPE_AUDIO || type == AVMEDIA_TYPE_VIDEO else { continue }
        
        let filter_spec: String
        switch type {
        case AVMEDIA_TYPE_VIDEO: filter_spec = "format=nv12,hwupload"
        case AVMEDIA_TYPE_AUDIO: filter_spec = "anull"
        default: fatalError()
        }
        filter_ctx.append(try init_filter(dec_ctx: stream_ctx[i].dec_ctx!, enc_ctx: stream_ctx[i].enc_ctx!, filter_spec: filter_spec))
        
        filter_ctx[i].enc_pkt = av_packet_alloc()
        guard filter_ctx[i].enc_pkt != nil else {
            throw FFmpegError.av_err(code: AVERROR(ENOMEM))
        }
        
        filter_ctx[i].filtered_frame = av_frame_alloc()
        guard filter_ctx[i].filtered_frame != nil else {
            throw FFmpegError.av_err(code: AVERROR(ENOMEM))
        }
    }
    
    return filter_ctx
}

func init_filter(dec_ctx: UnsafeMutablePointer<AVCodecContext>,
                 enc_ctx: UnsafeMutablePointer<AVCodecContext>,
                 filter_spec: String) throws -> FilteringContext {
    var inputs: UnsafeMutablePointer<AVFilterInOut>? = avfilter_inout_alloc()
    var outputs: UnsafeMutablePointer<AVFilterInOut>? = avfilter_inout_alloc()
    guard outputs != nil && inputs != nil,
          let filter_graph = avfilter_graph_alloc()
    else {
        throw FFmpegError.av_err(code: AVERROR(ENOMEM))
    }
    
    defer {
        avfilter_inout_free(&inputs)
        avfilter_inout_free(&outputs)
    }
    
    var buffersrc_ctx: UnsafeMutablePointer<AVFilterContext>?
    var buffersink_ctx: UnsafeMutablePointer<AVFilterContext>?
    
    switch dec_ctx.pointee.codec_type {
    case AVMEDIA_TYPE_VIDEO:
        guard let buffersrc = avfilter_get_by_name("buffer"),
              let buffersink = avfilter_get_by_name("buffersink")
        else {
            av_log(nil, AV_LOG_ERROR, "filtering source or sink element not found")
            throw FFmpegError.unknown
        }
        
        let args = "video_size=\(dec_ctx.pointee.width)x\(dec_ctx.pointee.height):pix_fmt=\(dec_ctx.pointee.pix_fmt.rawValue):time_base=\(dec_ctx.pointee.time_base.num)/\(dec_ctx.pointee.time_base.den):pixel_aspect=\(dec_ctx.pointee.sample_aspect_ratio.num)/\(dec_ctx.pointee.sample_aspect_ratio.den)"
        
        try check(avfilter_graph_create_filter(&buffersrc_ctx, buffersrc, "in", args, nil, filter_graph), message: "Cannot create buffer source")
        
        try check(avfilter_graph_create_filter(&buffersink_ctx, buffersink, "out", nil, nil, filter_graph), message: "Cannot create buffer sink")
        
        let size = MemoryLayout.size(ofValue: enc_ctx.pointee.pix_fmt)
        try withUnsafePointer(to: enc_ctx.pointee.pix_fmt) {
            try $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                try check(av_opt_set_bin(buffersink_ctx, "pix_fmts", $0, Int32(size), AV_OPT_SEARCH_CHILDREN), message: "Cannot set output pixel format")
            }
        }
    case AVMEDIA_TYPE_AUDIO:
        guard let buffersrc = avfilter_get_by_name("abuffer"),
              let buffersink = avfilter_get_by_name("abuffersink")
        else {
            av_log(nil, AV_LOG_ERROR, "filtering source or sink element not found")
            throw FFmpegError.unknown
        }
        
        if dec_ctx.pointee.channel_layout == 0 {
            dec_ctx.pointee.channel_layout = UInt64(av_get_default_channel_layout(dec_ctx.pointee.channels))
        }
        let args = "time_base=\(dec_ctx.pointee.time_base.num)/\(dec_ctx.pointee.time_base.den):sample_rate=\(dec_ctx.pointee.sample_rate):sample_fmt=\(av_get_sample_fmt_name(dec_ctx.pointee.sample_fmt)!):channel_layout=0x\(String(dec_ctx.pointee.channel_layout, radix: 16, uppercase: false))"
        try check(avfilter_graph_create_filter(&buffersrc_ctx, buffersrc, "in", args, nil, filter_graph), message: "Cannot create audio buffer source")

        try check(avfilter_graph_create_filter(&buffersink_ctx, buffersink, "out", nil, nil, filter_graph), message: "Cannot create audio buffer sink")

        func av_opt_set_bin<T>(name: String, keyPath: WritableKeyPath<AVCodecContext, T>, message: String) throws {
            let size = MemoryLayout.size(ofValue: enc_ctx.pointee[keyPath: keyPath])
            try withUnsafePointer(to: enc_ctx.pointee[keyPath: keyPath]) {
                try $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                    try check(avutil.av_opt_set_bin(buffersink_ctx, name, $0, Int32(size), AV_OPT_SEARCH_CHILDREN), message: message)
                }
            }
        }
        
        try av_opt_set_bin(name: "sample_fmts", keyPath: \.sample_fmt, message: "Cannot set output sample format")

        try av_opt_set_bin(name: "channel_layouts", keyPath: \.channel_layout, message: "Cannot set output channel layout")

        try av_opt_set_bin(name: "sample_rates", keyPath: \.sample_rate, message: "Cannot set output sample rate")
    default:
        throw FFmpegError.unknown
    }
    
    outputs?.pointee.name = av_strdup("in")
    outputs?.pointee.filter_ctx = buffersrc_ctx
    outputs?.pointee.pad_idx = 0
    outputs?.pointee.next = nil
    
    inputs?.pointee.name = av_strdup("out")
    inputs?.pointee.filter_ctx = buffersink_ctx
    inputs?.pointee.pad_idx = 0
    inputs?.pointee.next = nil
    
    guard outputs?.pointee.name != nil && inputs?.pointee.name != nil else {
        throw FFmpegError.av_err(code: AVERROR(ENOMEM))
    }
    
    try check(avfilter_graph_parse_ptr(filter_graph, filter_spec, &inputs, &outputs, nil))
    
    try check(avfilter_graph_config(filter_graph, nil))
    
    return FilteringContext(
        buffersink_ctx: buffersink_ctx,
        buffersrc_ctx: buffersrc_ctx,
        filter_graph: filter_graph)
}

func filter_encode_write_frame(_ frame: UnsafeMutablePointer<AVFrame>?, stream_index: Int, filter_ctx: [FilteringContext], stream_ctx: [StreamContext], ofmt_ctx: UnsafeMutablePointer<AVFormatContext>) throws {
    let filter = filter_ctx[stream_index]
    
    av_log(nil, AV_LOG_INFO, "Pushing decoded frame to filters")
    try check(av_buffersrc_add_frame_flags(filter.buffersrc_ctx, frame, 0), message: "Error while feeding the filtergraph")
    
    while true {
        av_log(nil, AV_LOG_INFO, "Pulling filtered frame from filters")
        let ret = av_buffersink_get_frame(filter.buffersink_ctx, filter.filtered_frame)
        if ret < 0 {
            guard ret == AVERROR(EAGAIN) || ret == AVERROR_EOF else {
                throw FFmpegError.av_err(code: ret)
            }
            break
        }
        
        filter.filtered_frame?.pointee.pict_type = AV_PICTURE_TYPE_NONE
        defer { av_frame_unref(filter.filtered_frame)}
        try encode_write_frame(stream_index: stream_index, flush: false, stream_ctx: stream_ctx, filter_ctx: filter_ctx, ofmt_ctx: ofmt_ctx)
    }
}

func encode_write_frame(stream_index: Int, flush: Bool, stream_ctx: [StreamContext], filter_ctx: [FilteringContext], ofmt_ctx: UnsafeMutablePointer<AVFormatContext>) throws {
    let stream = stream_ctx[stream_index]
    let filter = filter_ctx[stream_index]
    let filt_frame = flush ? nil : filter.filtered_frame
    let enc_pkt = filter.enc_pkt
    
    av_log(nil, AV_LOG_INFO, "Encoding frame")
    av_packet_unref(enc_pkt)
    
    try check(avcodec_send_frame(stream.enc_ctx, filt_frame))
    
    while true {
        let ret = avcodec_receive_packet(stream.enc_ctx, enc_pkt)
        
        if ret == AVERROR(EAGAIN) || ret == AVERROR_EOF {
            return
        }
        
        enc_pkt?.pointee.stream_index = Int32(stream_index)
        av_packet_rescale_ts(enc_pkt, stream.enc_ctx!.pointee.time_base, ofmt_ctx.pointee.streams[stream_index]!.pointee.time_base)
        
        av_log(nil, AV_LOG_DEBUG, "Muxing frame")
        try check(av_interleaved_write_frame(ofmt_ctx, enc_pkt))
    }
}

func flush_encoder(stream_index: Int, stream_ctx: [StreamContext], filter_ctx: [FilteringContext], ofmt_ctx: UnsafeMutablePointer<AVFormatContext>) throws {
    guard stream_ctx[stream_index].enc_ctx!.pointee.codec.pointee.capabilities & AV_CODEC_CAP_DELAY != 0 else { return }
    
    av_log(nil, AV_LOG_INFO, "Flushing stream #\(stream_index) encoder")
    try encode_write_frame(stream_index: stream_index, flush: true, stream_ctx: stream_ctx, filter_ctx: filter_ctx, ofmt_ctx: ofmt_ctx)
}

let logLevels = [
    AV_LOG_QUIET: "QUIET",
    AV_LOG_PANIC: "PANIC",
    AV_LOG_FATAL: "FATAL",
    AV_LOG_ERROR: "ERROR",
    AV_LOG_WARNING: "WARNING",
    AV_LOG_INFO: "INFO",
    AV_LOG_VERBOSE: "VERBOSE",
    AV_LOG_DEBUG: "DEBUG",
    AV_LOG_TRACE: "TRACE",
]

func av_log(_ avcl: Any?, _ level: Int32, _ fmt: String, function: String = #function) {
    guard level > AV_LOG_QUIET else { return }
    print(logLevels[level] ?? level, function, fmt)
}

func MKTAG(_ a: Character, _ b: Character, _ c: Character, _ d: Character) -> Int32 {
    func i(_ c: Character) -> Int32 { Int32(c.asciiValue!) }
    return i(a) | i(b) << 8 | i(c) << 16 | i(d) << 24
}

func FFERRTAG(_ a: Character, _ b: Character, _ c: Character, _ d: Character) -> Int32 {
    -MKTAG(a, b, c, d)
}

func AVERROR(_ e: Int32) -> Int32 { EDOM > 0 ? -e : e }

func check(_ expression: @autoclosure () -> Int32, message: String? = nil, function: String = #function) throws {
    let error = expression()
    if error < 0 {
        if let message = message {
            print(function, message)
        }
        throw FFmpegError.av_err(code: error)
    }
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
