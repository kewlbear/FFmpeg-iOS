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
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/avcodec.zip", checksum: "f08fea9dde6803859df6a6cc4f2dd324c0e81b6b5adad11d55a90d8c7452626e"),
        .binaryTarget(name: "avutil", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/avutil.zip", checksum: "f9c38287dbdef81356f7908eb98586ea2c2fb6b111cb919a066dfdd4832371b0"),
        .binaryTarget(name: "avformat", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/avformat.zip", checksum: "07fa3f6dc9dc3655db3a9336d31d171fc17f25d62d46c0ee3ff457f4ef3b26c7"),
        .binaryTarget(name: "avfilter", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/avfilter.zip", checksum: "73168547bfe8e3b3b9e51b0a606e84344b9bd0e4daf50dcc7c276a94a89d60f2"),
        .binaryTarget(name: "avdevice", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/avdevice.zip", checksum: "1ee7dca682b6537c43d55838c3f2f54974fd2b43ba2c4ad6a4da3ce9d1a91b42"),
        .binaryTarget(name: "swscale", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/swscale.zip", checksum: "227a7eb4a00bfc0face1ff66ebfec57f933abbb6ab9fa164c4a3881943296a2f"),
        .binaryTarget(name: "swresample", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/swresample.zip", checksum: "a6a5a98aeda4cabb4e967907775ff2a7816d25d38cba7d717a4f50964ae1216e"),
        .binaryTarget(name: "ffmpeg", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.5/ffmpeg.zip", checksum: "d4a485d5a33d69c4bb06290ba08c49c30d53fd9d8084613d9342feb126511e88"),
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
