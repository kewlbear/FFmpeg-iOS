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
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avcodec.zip", checksum: "cc709dfe7d1ce5e3528b8d94c114b1c463db9c77f0d7b4b473b1d5435100e6d1"),
        .binaryTarget(name: "avutil", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avutil.zip", checksum: "fe8018d4e5614cf7ab31b02b9b1ca256e9a956fdb008ccf27dc1827e7f91e62a"),
        .binaryTarget(name: "avformat", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avformat.zip", checksum: "66ca999ca1a3a8b9b98081822a5fb2cb4cd1ab0772fc6199ee84f32c5408a560"),
        .binaryTarget(name: "avfilter", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avfilter.zip", checksum: "da7f98aad2fd99175adc80e4562de4f826f59db0d4fe76a550561d7da2e65d6e"),
        .binaryTarget(name: "avdevice", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/avdevice.zip", checksum: "ba0f475eb430de50a920dba3be6c3cd254be65d051eb51b94370fa3421199a29"),
        .binaryTarget(name: "swscale", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/swscale.zip", checksum: "e603c4d9989841683335752f1544f47dafcce4f046ea7c177799190080c4a550"),
        .binaryTarget(name: "swresample", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/swresample.zip", checksum: "5be24cf1ab7cd3ab051a93094e697ea695c8bd0adbaa5db827d9411e69ee20b2"),
        .binaryTarget(name: "ffmpeg", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.4/ffmpeg.zip", checksum: "02c0c125edc881b7fc8374a779e143967a7037b894bff3130deec2b9e111a67b"),
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
