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
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avcodec.zip", checksum: "e1c053e9e74f94d79b2cd0bf4626a52e19379a7c31697a08b63b27cacd222514"),
        .binaryTarget(name: "avutil", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avutil.zip", checksum: "7178f9a7731daa1b9fe0a4f2283e5d0cf745c77aa7dd8a7caeddfe28e64028da"),
        .binaryTarget(name: "avformat", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avformat.zip", checksum: "fd70e7d5165d156fbb3cec08ff82417f083c9db79ab675bc47e3cde47113d305"),
        .binaryTarget(name: "avfilter", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avfilter.zip", checksum: "1ee20cf33fbbc0ece0c9e8d09f90178f9c1022383cd70958b1b7634081a7e595"),
        .binaryTarget(name: "avdevice", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avdevice.zip", checksum: "c5efa88d7e64f7b769cd2f745e89946675187668e900bae20f6b630e15792501"),
        .binaryTarget(name: "swscale", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/swscale.zip", checksum: "e2c395c2e2e27f92f69684299d41598c5bfb5d3cc3f4fb5d053c6a985f497152"),
        .binaryTarget(name: "swresample", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/swresample.zip", checksum: "bd68f8879f48d20f3c57772433dc30928f08ff2641c72994b9e6c5de104d37a9"),
        .binaryTarget(name: "ffmpeg", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/ffmpeg.zip", checksum: "972142d0244536a2176c57f87c8cec4254e8b616c777f23d26f2b5d851351c21"),
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
                    dependencies: ["FFmpegSupport",]),
    ]
)
