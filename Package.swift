// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FFmpeg-iOS",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "FFmpeg-iOS",
            targets: [
                "avcodec", "avutil", "avformat", "avfilter", "swscale", "swresample", "Depend"]),
        .executable(name: "ffmpeg-ios", targets: ["Tool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
    ],
    targets: [
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/avcodec.zip", checksum: "50fc7c75f51600f49539cef20826008813ff91722fe1c2269d6fb949621e56ae"),
        .binaryTarget(name: "avutil", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/avutil.zip", checksum: "ea23b8e04c16ba47a05b2bb0b648f360ea4d7b51b527b0b3f7f502ed5ea4f1d8"),
        .binaryTarget(name: "avformat", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/avformat.zip", checksum: "b4fedd70d28deb237314490d67899578984ce638e9702459484fdc53c373b7b7"),
        .binaryTarget(name: "avfilter", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/avfilter.zip", checksum: "965b90de1324033ce2956f07e4cb05ba343af3e0a88faa09b42d263b332cb396"),
        .binaryTarget(name: "avdevice", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/avdevice.zip", checksum: "492eec13b86009b2eb1c3ff2f0a41380bda230ec3f1c1d35b97f4e660ac56b6d"),
        .binaryTarget(name: "swscale", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/swscale.zip", checksum: "6430cab90b477a0bfdf0891ab4c5ce2eb26bed27c4eb46ffc1365e37c82b179d"),
        .binaryTarget(name: "swresample", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/0.0.2/swresample.zip", checksum: "ff2c8e9ef5b8acac334763acc308f418bb311ab8d628122c67a7ddcc7f78b550"),
        .target(name: "Tool", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
        .target(name: "Depend",
                linkerSettings: [
                    .linkedLibrary("z"),
                    .linkedLibrary("bz2"),
                    .linkedLibrary("iconv"),
                ]
        ),
    ]
)
