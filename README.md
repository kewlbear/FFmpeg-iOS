# FFmpeg-iOS

This swift package enables you to use FFmpeg libraries in your iOS apps.

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

## License

LGPL v2.1+
