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
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/codec.zip", checksum: "50fc7c75f51600f49539cef20826008813ff91722fe1c2269d6fb949621e56ae"),
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
