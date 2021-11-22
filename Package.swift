// swift-tools-version:5.3

import PackageDescription

var products: [Product] = [
    .library(
        name: "FFmpeg-iOS",
        targets: [
            "avcodec", "avutil", "avformat", "avfilter", "avdevice", "swscale", "swresample",
            "Depend", "ffmpeg", "Hook", "FFmpegSupport",
        ]),
]

#if os(macOS)
products += [
    .executable(name: "ffmpeg-ios", targets: ["Tool"]),
]
#endif

let package = Package(
    name: "FFmpeg-iOS",
    platforms: [.iOS(.v13)],
    products: products,
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .binaryTarget(name: "avcodec", path: "Frameworks/avcodec.xcframework"),
        .binaryTarget(name: "avutil", path: "Frameworks/avutil.xcframework"),
        .binaryTarget(name: "avformat", path: "Frameworks/avformat.xcframework"),
        .binaryTarget(name: "avfilter", path: "Frameworks/avfilter.xcframework"),
        .binaryTarget(name: "avdevice", path: "Frameworks/avdevice.xcframework"),
        .binaryTarget(name: "swscale", path: "Frameworks/swscale.xcframework"),
        .binaryTarget(name: "swresample", path: "Frameworks/swresample.xcframework"),
        .binaryTarget(name: "ffmpeg", path: "Frameworks/ffmpeg.xcframework"),
        .target(name: "Tool", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "Depend",
                linkerSettings: [
                    .linkedLibrary("z"),
                    .linkedLibrary("bz2"),
                    .linkedLibrary("iconv"),
                    .linkedFramework("AVFoundation"),
                    .linkedFramework("VideoToolbox"),
                    .linkedFramework("CoreMedia"),
                ]
        ),
        .target(name: "Hook", dependencies: [
            "ffmpeg",
            "avcodec", "avformat", "avfilter", "avdevice", "avutil", "swscale", "swresample",
            "Depend",
        ]),
        .target(name: "FFmpegSupport", dependencies: [
            "Hook",
        ]),
        .testTarget(name: "FFmpeg-iOSTests",
                    dependencies: ["FFmpegSupport",],
                    resources: [.copy("bear-320x240-video-only.webm"),]),
    ]
)
