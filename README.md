# FFmpeg-iOS

This swift package enables you to use FFmpeg libraries in your iOS, Mac Catalyst and tvOS apps.

## Installation

```
.package(url: "https://github.com/kewlbear/FFmpeg-iOS.git", from: "0.0.1")
```

## Usage

```
import avformat

var ifmt_ctx: UnsafeMutablePointer<AVFormatContext>?
var ret = avformat_open_input(&ifmt_ctx, filename, nil, nil)
```

See https://github.com/kewlbear/YoutubeDL-iOS.

## Building Libraries

You can install build tool

### [Mint](https://github.com/yonaskolb/mint)
```
$ mint install kewlbear/FFmpeg-iOS
```

or run from source.

### Swift Package Manager
```
git clone https://github.com/kewlbear/FFmpeg-iOS.git
cd FFmpeg-iOS
```

You should omit "swift run" from following commands if you installed build tool.

To download FFmpeg source and build .xcframeworks:

```
$ swift run ffmpeg-ios
```

To build fat libraries:

```
$ swift run ffmpeg-ios --disable-xcframework 
```

To download x264 source and build fat libraries:

```
$ swift run ffmpeg-ios x264 --disable-xcframework
```

For other usages:

```
$ swift run ffmpeg-ios -h
OVERVIEW: Build FFmpeg libraries for iOS as xcframeworks

USAGE: ffmpeg-ios <subcommand>

OPTIONS:
 -h, --help              Show help information.

SUBCOMMANDS:
 build (default)         Build framework module
 framework               Create .xcframework
 module                  Enable modules to allow import from Swift
 fat                     Create fat library
 dep                     Install build dependency
 source                  Download library source code

 See 'ffmpeg-ios help <subcommand>' for detailed help.
 $ swift run ffmpeg-ios build -h
 OVERVIEW: Build framework module

 USAGE: ffmpeg-ios build <options>

 ARGUMENTS:
   <lib>                   ffmpeg, fdk-aac, lame or x264 (default: ffmpeg)

 OPTIONS:
   --enable-libfdk-aac     enable AAC de/encoding via libfdk-aac 
   --enable-libx264        enable H.264 encoding via x264 
   --enable-libmp3lame     enable MP3 encoding via libmp3lame 
   --disable-xcframework   Create fat library instead of .xcframework 
   --disable-module
   --source-directory <source-directory>
                           Library source directory (default: ./<lib>) 
   --build-directory <build-directory>
                           directory to contain build artifacts (default: ./build)
   --arch <arch>           architectures to include (default: arm64, x86_64)
   --library <library>     libraries to include (default: avcodec, avdevice, avfilter, avformat, avutil, swresample, swscale)
   --deployment-target <deployment-target>
                           (default: 12.0)
   --extra-options <extra-options>
                           additional options for configure script 
   --release <release>     FFmpeg release (default: snapshot)
   --url <url>
   --frameworks <frameworks>
                           (default: ./Frameworks)
   --output <output>       default: <lib>-fat 
   --fdk-aac-source <fdk-aac-source>
                           (default: ./fdk-aac-2.0.1)
   --x264-source <x264-source>
                           (default: ./x264-master)
   --lame-source <lame-source>
                           (default: ./lame-3.100)
   -h, --help              Show help information.

$
```
 
## License

LGPL v2.1+
