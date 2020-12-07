// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FFmpeg-iOS",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "FFmpeg-iOS",
            targets: [
                "avcodec", "avutil", "avformat", "avfilter", "swscale", "swresample"]),
        .executable(name: "ffmpeg-ios", targets: ["Tool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .binaryTarget(name: "avcodec", path: "Frameworks/avcodec.xcframework"),
        .binaryTarget(name: "avutil", path: "Frameworks/avutil.xcframework"),
        .binaryTarget(name: "avformat", path: "Frameworks/avformat.xcframework"),
        .binaryTarget(name: "avfilter", path: "Frameworks/avfilter.xcframework"),
        .binaryTarget(name: "swscale", path: "Frameworks/swscale.xcframework"),
        .binaryTarget(name: "swresample", path: "Frameworks/swresample.xcframework"),
        .target(name: "Tool", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
