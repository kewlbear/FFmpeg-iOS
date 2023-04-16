// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FFmpeg-iOS",
    platforms: [.iOS(.v13)],
    products: [
        .library(
            name: "FFmpeg-iOS",
            targets: [
                "avcodec", "avutil", "avformat", "avfilter", "avdevice", "swscale", "swresample",
                "fftools", "Dummy",
            ]),
    ],
    dependencies: [
        .package(path: "../FFmpeg-iOS-Support"),
    ],
    targets: [
        .binaryTarget(name: "avcodec", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/avcodec.zip", checksum: "a17ecaf98cfd9616bcc05ac30598e862c5383b6a31a4ac5b91a1659b924a33c6"),
        .binaryTarget(name: "avutil", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/avutil.zip", checksum: "1264b08152a797301a35933b34a2f3e32473a84005facf00de8ffec30eff75b8"),
        .binaryTarget(name: "avformat", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/avformat.zip", checksum: "d23b99ffc99435e949ae549297798949f447227db1180cc60eda17720c8ab6a4"),
        .binaryTarget(name: "avfilter", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/avfilter.zip", checksum: "d6c0a08eacff190e22038ed9ffc1cc6ccc618d7e4b31ff20cf8e49769a02bd35"),
        .binaryTarget(name: "avdevice", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/avdevice.zip", checksum: "5e8bebaae6ef03dfeab3166fa34852728a4c1eac40d9dafcd6b4cb1f71055174"),
        .binaryTarget(name: "swscale", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/swscale.zip", checksum: "1a963ee6cdef07ac93ec66b682ad7d6b353bdcd41e356838a1ea9f42f8433060"),
        .binaryTarget(name: "swresample", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/swresample.zip", checksum: "25f7fa14185507d3850095aa5eaa5e0ee4fb9c1bbdba3182d6a66cfedfe27702"),
        .binaryTarget(name: "fftools", url: "https://github.com/kewlbear/FFmpeg-iOS/releases/download/v0.0.6-b20230416-173821/fftools.zip", checksum: "da3e909deb1ee98ef2425a2a4640b663fbb84ecc4204d663b1959c8de587acc7"),
        .target(name: "Dummy", dependencies: [
            "fftools",
            "avcodec", "avformat", "avfilter", "avdevice", "avutil", "swscale", "swresample",
            "FFmpeg-iOS-Support",
        ]),
        .testTarget(name: "FFmpeg-iOSTests",
                    dependencies: ["Dummy",]),
    ]
)
