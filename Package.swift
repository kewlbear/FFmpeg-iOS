// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FFmpeg-iOS",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FFmpeg-iOS",
            targets: [
//                "FFmpeg-iOS",
                "avcodec", "avutil", "avformat", "avfilter", "swscale", "swresample"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
//        .target(
//            name: "FFmpeg-iOS",
//            dependencies: ["avcodec", "avutil", "avformat"]),
        .binaryTarget(name: "avcodec", path: "Frameworks/avcodec.xcframework"),
        .binaryTarget(name: "avutil", path: "Frameworks/avutil.xcframework"),
        .binaryTarget(name: "avformat", path: "Frameworks/avformat.xcframework"),
        .binaryTarget(name: "avfilter", path: "Frameworks/avfilter.xcframework"),
        .binaryTarget(name: "swscale", path: "Frameworks/swscale.xcframework"),
        .binaryTarget(name: "swresample", path: "Frameworks/swresample.xcframework"),
//        .testTarget(
//            name: "FFmpeg-iOSTests",
//            dependencies: ["FFmpeg-iOS"]),
    ]
)
