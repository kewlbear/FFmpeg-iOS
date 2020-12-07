//
//  main.swift
//  
//
//  Created by 안창범 on 2020/12/01.
//

import ArgumentParser
import Foundation

struct Tool: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "ffmpeg-ios",
        abstract: "Build FFmpeg libraries for iOS as xcframeworks",
        subcommands: [
            BuildCommand.self,
            XCFrameworkCommand.self,
            ModuleCommand.self,
            FatCommand.self,
            DepCommand.self,
            SourceCommand.self,
//            Clean.self,
        ],
        defaultSubcommand: BuildCommand.self)
}

struct LibraryOptions: ParsableArguments {
    @Option(help: "libraries to include")
    var library = [
        "avcodec",
        "avdevice",
        "avfilter",
        "avformat",
        "avutil",
        "swresample",
        "swscale",
    ]
}

struct SourceOptions: ParsableArguments {
    @Option(help: "Library source directory (default: ./<lib>)")
    var sourceDirectory: String?
    
    var sourceURL: URL { URL(fileURLWithPath: sourceDirectory ?? "./\(lib)") }
    
    var configureScriptExists: Bool {
        FileManager.default.fileExists(atPath: sourceURL.appendingPathComponent("configure").path)
    }
    
    @Argument(help: "ffmpeg, fdk-aac, lame or x264")
    var lib = "ffmpeg"
}

struct BuildOptions: ParsableArguments {
    @Option(help: "directory to contain build artifacts")
    var buildDirectory = "./build"
    
    @Option(help: "architectures to include")
    var arch = ["arm64", "x86_64"]
}

struct ConfigureOptions: ParsableArguments {
    @Option
    var deploymentTarget = "12.0"
    
    @Option(help: "additional options for configure script")
    var extraOptions: [String] = []
}

struct FatLibraryOptions: ParsableArguments {
    @Option(help: "default: <lib>-fat")
    var output: String?
}

struct XCFrameworkOptions: ParsableArguments {
    @Option
    var frameworks = "./Frameworks"
}

struct DownloadOptions: ParsableArguments {
    @Option(help: "FFmpeg release")
    var release = "snapshot"
    
    @Option
    var url: String?
}

struct FdkAacOptions: ParsableArguments {
    @Option
    var fdkAacSource = "./fdk-aac-2.0.1"
}

struct X264Options: ParsableArguments {
    @Option
    var x264Source = "./x264-master"
}

struct LameOptions: ParsableArguments {
    @Option
    var lameSource = "./lame-3.100"
}

extension Tool {
    struct BuildCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "build", abstract: "Build framework module")
        
        @Flag(help: "enable AAC de/encoding via libfdk-aac")
        var enableLibfdkAac = false
        
        @Flag(help: "enable H.264 encoding via x264")
        var enableLibx264 = false
        
        @Flag(help: "enable MP3 encoding via libmp3lame")
        var enableLibmp3lame = false
        
        @Flag(help: "Create fat library instead of .xcframework")
        var disableXcframework = false
        
        @Flag
        var disableModule = false
        
        @OptionGroup var sourceOptions: SourceOptions
        @OptionGroup var buildOptions: BuildOptions
        @OptionGroup var libraryOptions: LibraryOptions
        @OptionGroup var configureOptions: ConfigureOptions
        @OptionGroup var downloadOptions: DownloadOptions
        @OptionGroup var xcframeworkOptions: XCFrameworkOptions
        @OptionGroup var fatLibraryOptions: FatLibraryOptions
        @OptionGroup var fdkAacOptions: FdkAacOptions
        @OptionGroup var x264Options: X264Options
        @OptionGroup var lameOptions: LameOptions
        
        mutating func run() throws {
            try DepCommand().run()

            if enableLibfdkAac {
                try build(lib: "fdk-aac", sourceDirectory: "./fdk-aac")
                
                configureOptions.extraOptions += ["--enable-libfdk-aac", "--enable-nonfree",]
            }

            if enableLibmp3lame {
                try build(lib: "lame", sourceDirectory: "./lame")
                
                configureOptions.extraOptions += ["--enable-libmp3lame",]
            }
            
            if enableLibx264 {
                try build(lib: "x264", sourceDirectory: "./x264")
                
                configureOptions.extraOptions += ["--enable-libx264", "--enable-gpl",]
            }

            try build(lib: sourceOptions.lib, sourceDirectory: sourceOptions.sourceURL.path)
            
            if !disableXcframework {
                print("building xcframeworks...")
                var createXcframeworks = XCFrameworkCommand()
                createXcframeworks.buildOptions = buildOptions
                createXcframeworks.libraryOptions = libraryOptions
                createXcframeworks.xcframeworkOptions = xcframeworkOptions
                createXcframeworks.sourceOptions = sourceOptions
                try createXcframeworks.run()

                if !disableModule {
                    print("modularizing...")
                    var modularize = ModuleCommand()
                    modularize.buildOptions = buildOptions
                    modularize.libraryOptions = libraryOptions
                    modularize.xcframeworkOptions = xcframeworkOptions
                    modularize.sourceOptions = sourceOptions
                    try modularize.run()
                }
            } else {
                print("building fat binaries...")
                var fatCommand = FatCommand()
                fatCommand.buildOptions = buildOptions
                fatCommand.fatLibraryOptions = fatLibraryOptions
                fatCommand.libraryOptions = libraryOptions
                fatCommand.sourceOptions = sourceOptions
                try fatCommand.run()
            }
            
            print("Done")
        }
        
        func build(lib: String, sourceDirectory: String) throws {
            if !FileManager.default.fileExists(atPath: sourceDirectory) {
                print("\(lib) source not found. Trying to download...")
                var downloadSource = SourceCommand()
                downloadSource.sourceOptions = sourceOptions
                downloadSource.sourceOptions.sourceDirectory = sourceDirectory
                downloadSource.downloadOptions = downloadOptions
                try downloadSource.run()
            }
            
            switch lib {
            case "ffmpeg":
                try buildFFmpeg(sourceDirectory: sourceDirectory)
            case "fdk-aac":
                try buildFdkAac(sourceDirectory: sourceDirectory)
            case "lame":
                try buildLame(sourceDirectory: sourceDirectory)
            case "x264":
                try buildX264(sourceDirectory: sourceDirectory)
            default:
                throw ExitCode.failure
            }
        }
        
        func buildFFmpeg(sourceDirectory: String) throws {
            class FFmpegConfiguration: ConfigurationHelper, Configuration {
                override var `as`: String { "gas-preprocessor.pl \(aarch64) -- \(cc)" }
                
                var options: [String] {
                    [
                        "--prefix=\(installPrefix)",
                        "--enable-cross-compile",
                        "--disable-debug",
                        "--disable-programs",
                        "--disable-doc",
                        "--enable-pic",
                        "--disable-audiotoolbox",
                        "--target-os=darwin",
                        "--arch=\(arch)",
                        "--cc=\(cc)",
                        "--as=\(`as`)",
                        "--extra-cflags=\(cFlags) -I\(installPrefix)/include",
                        "--extra-ldflags=\(ldFlags) -L\(installPrefix)/lib",
                    ]
                }
            }
            
            try buildLibrary(name: "FFmpeg", sourceDirectory: sourceDirectory, arch: buildOptions.arch, deploymentTarget: configureOptions.deploymentTarget, buildDirectory: buildOptions.buildDirectory, configuration: FFmpegConfiguration.self) {
                $0.options + configureOptions.extraOptions
            }
        }
        
        func buildFdkAac(sourceDirectory: String) throws {
            class FdkAacConfiguration: ConfigurationHelper, Configuration {
                override var `as`: String { "\(sourceDirectory)/extras/gas-preprocessor.pl \(aarch64) -- \(cc)" }
                
                var options: [String] {
                    [
                        "--host=\(host(arch))-apple-darwin",
                        "--prefix=\(installPrefix)",
                        "--enable-static",
                        "--disable-shared",
                        "--with-pic=yes",
                        "CC=\(cc)",
                        "CXX=\(cc)",
                        "CPP=\(cc) -E",
                        "AS=\(`as`)",
                        "CFLAGS=\(cFlags)",
                        "CPPFLAGS=\(cFlags)",
                        "LDFLAGS=\(ldFlags)",
                    ]
                }
            }
            
            try buildLibrary(name: "fdk-aac", sourceDirectory: sourceDirectory, arch: buildOptions.arch, deploymentTarget: configureOptions.deploymentTarget, buildDirectory: buildOptions.buildDirectory, configuration: FdkAacConfiguration.self)
        }
        
        func buildLame(sourceDirectory: String) throws {
            class LameConfiguration: ConfigurationHelper, Configuration {
                override var cc: String { "xcrun -sdk \(sdk) clang -arch \(arch)" }
                
                var options: [String] {
                    [
                        "--host=\(host(arch))-apple-darwin",
                        "--prefix=\(installPrefix)",
                        "--disable-frontend",
                        "--disable-shared",
                    ]
                }
                
                override var environment: [String : String]? {
                    [
                        "CC": cc,
                        "CPP": "\(cc) -E",
                        "CFLAGS": cFlags,
                        "LDFLAGS": ldFlags,
                    ]
                }
            }
            
            try buildLibrary(name: "lame", sourceDirectory: sourceDirectory, arch: buildOptions.arch, deploymentTarget: configureOptions.deploymentTarget, buildDirectory: buildOptions.buildDirectory, configuration: LameConfiguration.self)
        }
        
        func buildX264(sourceDirectory: String) throws {
            class X264Configuration: ConfigurationHelper, Configuration {
                override var `as`: String { "\(URL(fileURLWithPath: sourceDirectory).path)/tools/gas-preprocessor.pl \(aarch64) -- \(cc)" }
                
                var options: [String] {
                    [
                        arch != "x86_64" ? "--host=\(host(arch))-apple-darwin" : "",
                        "--prefix=\(installPrefix)",
                        "--enable-static",
                        "--disable-cli",
                        "--enable-pic",
                        "--extra-cflags=\(cFlags)",
                        "--extra-asflags=\(arch.hasPrefix("arm") ? cFlags : "")",
                        "--extra-ldflags=\(ldFlags)",
                    ]
                }
                
                override var environment: [String : String]? {
                    var env = [
                        "CC": cc,
                    ]
                    if arch.hasPrefix("arm") {
                        env["AS"] = `as`
                    }
                    return env
                }
            }
            
            try buildLibrary(name: "x264", sourceDirectory: sourceDirectory, arch: buildOptions.arch, deploymentTarget: configureOptions.deploymentTarget, buildDirectory: buildOptions.buildDirectory, configuration: X264Configuration.self)
        }
        
        func buildLibrary<T>(name: String, sourceDirectory: String, arch: [String], deploymentTarget: String, buildDirectory: String, configuration: T.Type, customize: (T) -> [String] = { $0.options }) throws where T: Configuration {
            let buildDir = URL(fileURLWithPath: buildDirectory)
                .appendingPathComponent(name)
            for arch in arch {
                print("building \(arch)...")
                let archDir = buildDir.appendingPathComponent(arch)
                try createDirectory(at: archDir.path)
                
                let prefix = buildDir
                    .deletingLastPathComponent()
                    .appendingPathComponent("install")
                    .appendingPathComponent(name)
                    .appendingPathComponent(arch)
                
                let conf = T(sourceDirectory: sourceDirectory, arch: arch, platform: nil, deploymentTarget: deploymentTarget, installPrefix: prefix.path)
                let options = customize(conf)
                try launch(launchPath: "\(sourceDirectory)/configure",
                           arguments: options,
                           currentDirectoryPath: archDir.path,
                           environment: conf.environment)
                
                try launch(launchPath: "/usr/bin/make",
                           arguments: [
                            "-j3",
                            "install",
                           ], // FIXME: GASPP_FIX_XCODE5=1 ?
                           currentDirectoryPath: archDir.path)
                
                let all = buildDir
                    .deletingLastPathComponent()
                    .appendingPathComponent("install")
                    .appendingPathComponent(arch)
                let include = all.appendingPathComponent("include").path
                let lib = all.appendingPathComponent("lib").path
                try createDirectory(at: include)
                try createDirectory(at: lib)
                try system("""
                    ln -sf \(prefix.path)/include/* \(include)
                    ln -sf \(prefix.path)/lib/* \(lib)
                    """)
            }
        }
    }

    struct InstallHomebrew: ParsableCommand {
        func run() throws {
            try system(#"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)""#)
        }
    }
    
    struct InstallYasm: ParsableCommand {
        func run() throws {
            try system("brew install yasm")
        }
    }
    
    struct InstallGasPreprocessor: ParsableCommand {
        func run() throws {
            try system("""
                curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
                -o /usr/local/bin/gas-preprocessor.pl \
                && chmod +x /usr/local/bin/gas-preprocessor.pl
                """)
        }
    }
    
    struct DepCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "dep", abstract: "Install build dependency")
        
        func run() throws {
            if !which("yasm") {
                print("Yasm not found")

                if !which("brew") {
                    print("Homebrew not found. Trying to install...")
                    try InstallHomebrew().run()
                }

                print("Trying to install Yasm...")
                try InstallYasm().run()
            }
            
            if !which("gas-preprocessor.pl") {
                print("gas-preprocessor.pl not found. Trying to install...")
                try InstallGasPreprocessor().run()
            }
        }
    }
    
    struct SourceCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "source", abstract: "Download library source code")
        
        @OptionGroup var downloadOptions: DownloadOptions
        
        @OptionGroup var sourceOptions: SourceOptions
        
        var defaultURL: String {
            switch sourceOptions.lib {
            case "ffmpeg":
                return "http://www.ffmpeg.org/releases/ffmpeg-\(downloadOptions.release).tar.bz2"
            case "fdk-aac":
                return "https://sourceforge.net/projects/opencore-amr/files/latest/download"
            case "lame":
                return "https://sourceforge.net/projects/lame/files/latest/download"
            case "x264":
                return "https://code.videolan.org/videolan/x264/-/archive/master/x264-master.tar.bz2"
            default:
                fatalError("unknown library: \(sourceOptions.lib)")
            }
        }
        
        func run() throws {
            let url = downloadOptions.url ?? defaultURL
            let t = "/tmp/ffmpeg-ios"
            // FIXME: J for .xz
            try system("""
                mkdir \(t)
                curl -L \(url) | tar xjC \(t)
                mv \(t)/* \(sourceOptions.sourceURL.path)
                rmdir \(t)
                """)
        }
    }
    
    struct LibCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "lib", abstract: "Build a library")
        func run() throws {
            // FIXME: ...
        }
    }
    
    struct FatCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "fat", abstract: "Create fat library")
        
        @OptionGroup var libraryOptions: LibraryOptions
        
        @OptionGroup var buildOptions: BuildOptions
        
        @OptionGroup var fatLibraryOptions: FatLibraryOptions
        
        @OptionGroup var sourceOptions: SourceOptions
        
        mutating func run() throws {
            let output = URL(fileURLWithPath: fatLibraryOptions.output ?? (sourceOptions.lib + "-fat"))
            try createDirectory(at: output.appendingPathComponent("lib").path)
            
            let installDir = URL(fileURLWithPath: buildOptions.buildDirectory)
                .appendingPathComponent("install")
                .appendingPathComponent(sourceOptions.lib)
            try system("""
                cd \(installDir.path)/\(buildOptions.arch[0])/lib
                for LIB in *.a
                do
                    lipo `find \(installDir.path) -name $LIB` -create -output \(output.path)/lib/$LIB
                done
                """)

            let to = output.appendingPathComponent("include")

            try removeItem(at: to.path)
            
            try copyItem(at: installDir
                            .appendingPathComponent(buildOptions.arch[0])
                            .appendingPathComponent("include").path,
                         to: to.path)
        }
    }
    
    struct XCFrameworkCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "framework", abstract: "Create .xcframework")
        
        @OptionGroup var libraryOptions: LibraryOptions
        
        @OptionGroup var buildOptions: BuildOptions
        
        @OptionGroup var xcframeworkOptions: XCFrameworkOptions

        @OptionGroup var sourceOptions: SourceOptions
        
        func run() throws {
            let lib = URL(fileURLWithPath: buildOptions.buildDirectory).appendingPathComponent("install").appendingPathComponent(sourceOptions.lib)
            let contents = try FileManager.default.contentsOfDirectory(at: lib.appendingPathComponent(buildOptions.arch[0]).appendingPathComponent("lib"), includingPropertiesForKeys: nil, options: [])
            let modules = contents.filter { $0.pathExtension == "a" }.map { $0.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "lib", with: "") }
            
            for library in modules {
                var args: [String] = []
                let temp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ffmpeg-ios")
                for arch in buildOptions.arch {
                    let dir = lib.appendingPathComponent(arch)

                    let include: URL
                    if modules.count > 1 {
                        include = temp
                            .appendingPathComponent(arch)
                            .appendingPathComponent("include")
                        try removeItem(at: include.path)
                        try createDirectory(at: include.path)
                        
                        let copy = include.appendingPathComponent("lib\(library)").path
                        try removeItem(at: copy)
                        try copyItem(at: "\(dir.path)/include/lib\(library)", to: copy)
                    } else {
                        include = dir.appendingPathComponent("include")
                    }
                    
                    args += [
                        "-library", "\(dir.path)/lib/lib\(library).a",
                        "-headers", include.path,
                    ]
                }
                
                let output = "\(xcframeworkOptions.frameworks)/\(library).xcframework"
                
                try removeItem(at: output)
                
                try launch(launchPath: "/usr/bin/xcodebuild",
                           arguments:
                            ["-create-xcframework"]
                            + args
                            + [
                                "-output", output,
                            ])
            }
        }
    }
    
    struct ModuleCommand: ParsableCommand {
        static var configuration = CommandConfiguration(commandName: "module", abstract: "Enable modules to allow import from Swift")
        
        @OptionGroup var libraryOptions: LibraryOptions
        
        @OptionGroup var buildOptions: BuildOptions
        
        @OptionGroup var xcframeworkOptions: XCFrameworkOptions

        @OptionGroup var sourceOptions: SourceOptions
        
        func run() throws {
            func convert(_ arch: String) -> String {
                switch arch {
                case "arm64":
                    return "ios-arm64"
                case "x86_64":
                    return "ios-x86_64-simulator"
                default:
                    fatalError()
                }
            }
            
            let lib = URL(fileURLWithPath: buildOptions.buildDirectory).appendingPathComponent("install").appendingPathComponent(sourceOptions.lib)
            let contents = try FileManager.default.contentsOfDirectory(at: lib.appendingPathComponent(buildOptions.arch[0]).appendingPathComponent("lib"), includingPropertiesForKeys: nil, options: [])
            let modules = contents.filter { $0.pathExtension == "a" }.map { $0.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "lib", with: "") }
            
            for library in modules {
                for arch in buildOptions.arch {
                    let directory = convert(arch)
                    
                    let to = URL(fileURLWithPath: "\(xcframeworkOptions.frameworks)/\(library).xcframework/\(directory)/Headers/lib\(library)/module.modulemap")
                    
                    try createDirectory(at: to.deletingLastPathComponent().path)
                    
                    try removeItem(at: to.path)
                    
                    do {
                        try copyItem(at: "ModuleMaps/\(library)/\(directory)/module.modulemap",
                                     to: to.path)
                    }
                    catch {
                        let nserror = error as NSError
                        guard let posixError = nserror.userInfo[NSUnderlyingErrorKey] as? POSIXError,
                              posixError.code == .ENOENT
                        else {
                            print(#line, error)
                            throw error
                        }
                        
                        let content = """
                            module \(library) {
                                umbrella "."
                                export *
                            }
                            """
                        try content.write(to: to, atomically: false, encoding: .utf8)
                    }
                }
            }
        }
    }
    
    struct Lipo: ParsableCommand {
        @Argument
        var input: String
        
        @Option
        var arch: String
        
        @Option
        var output: String
        
        func run() throws {
            try launch(launchPath: "/usr/bin/lipo",
                       arguments: [
                        input,
                        "-thin",
                        arch,
                        "-output",
                        output,
                       ])
        }
    }
    
    struct Clean: ParsableCommand {
        func run() throws {
            // FIXME: ...
        }
    }
}

func launch(launchPath: String, arguments: [String], currentDirectoryPath: String? = nil, environment: [String: String]? = nil) throws {
    let process = Process()
    
    if #available(OSX 10.13, *) {
        process.executableURL = URL(fileURLWithPath: launchPath)
    } else {
        process.launchPath = launchPath
    }
    
    process.arguments = arguments
    
    currentDirectoryPath.map { path in
        if #available(OSX 10.13, *) {
            process.currentDirectoryURL = URL(fileURLWithPath: path)
        } else {
            process.currentDirectoryPath = path
        }
        print("current directory:", path)
    }
    
    environment.map { environment in
        process.environment = environment
        print("environment:", environment)
    }
    
    print(launchPath, arguments)
    process.launch()
    
    process.waitUntilExit()
    if process.terminationStatus != 0 {
        print("'\(launchPath)' exit code: \(process.terminationStatus)")
        throw ExitCode(process.terminationStatus)
    }
}

func createDirectory(at path: String, withIntermediateDirectories: Bool = true, attributes: [FileAttributeKey: Any]? = nil) throws {
    try FileManager.default.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
    print("created directory:", path)
}

func copyItem(at src: String, to dst: String) throws {
    try FileManager.default.copyItem(at: URL(fileURLWithPath: src),
                                     to: URL(fileURLWithPath: dst))
    print("copied:", src, "to", dst)
}

func removeItem(at path: String) throws {
    do {
        try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
        print("removed:", path)
    }
    catch {
        let nserror = error as NSError
        guard let posixError = nserror.userInfo[NSUnderlyingErrorKey] as? POSIXError,
              posixError.code == .ENOENT
        else {
            print(#line, error)
            throw error
        }
    }

}
func which(_ command: String) -> Bool {
    do {
        try system("which \(command)")
        return true
    }
    catch {
        return false
    }
}

func system(_ command: String) throws {
    try spawn(["sh", "-c", command])
}

func spawn(_ args: [String]) throws {
    var pid: pid_t = -1
    var argv = args.map { strdup($0) }
    argv.append(nil)
    
    print(#function, args)
    let errno = posix_spawnp(&pid, args.first, nil, nil, argv, environ)
    print(#function, "posix_spawn()=\(errno) pid=\(pid)")
    
    argv.dropLast().forEach { free($0) }
    
    guard errno == 0 else {
        throw ExitCode.failure
    }
    
    var status: Int32 = 0
    let ret = waitpid(pid, &status, 0)
    print(#function, "waitpid()=\(ret) status=\(status)")
    guard WIFEXITED(status) else {
        throw ExitCode.failure
    }
    status = WEXITSTATUS(status)
    if status != 0 {
        print(#function, "exit status:", status)
        throw ExitCode.failure
    }
}

// FIXME: rename
func host(_ arch: String) -> String {
    switch arch {
    case "armv7":
        return "arm"
    case "arm64":
        return "aarch64"
    default:
        return arch
    }
}

protocol Configuration {
    var options: [String] { get }
    
    var environment: [String: String]? { get }
    
    init(sourceDirectory: String, arch: String, platform: String?, deploymentTarget: String, installPrefix: String)
}

class ConfigurationHelper {
    let sourceDirectory: String
    
    let arch: String
    
    let platform: String
    
    var sdk: String { platform.lowercased() }
    
    var cc: String { "xcrun -sdk \(sdk) clang" }
    
    var aarch64: String { arch == "arm64" ? "-arch aarch64" : "" }
    
    var `as`: String { "\(sourceDirectory)/extras/gas-preprocessor.pl \(aarch64) -- \(cc)" }
    
    var cFlags: String
    
    var ldFlags: String { cFlags }
    
    let installPrefix: String
    
    var environment: [String: String]? { nil }
    
    required init(sourceDirectory: String, arch: String, platform: String? = nil, deploymentTarget: String, installPrefix: String) {
        self.sourceDirectory = sourceDirectory
        self.arch = arch
        self.installPrefix = installPrefix
    
        cFlags = "-arch \(arch)"
        
        if let platform = platform {
            self.platform = platform
        } else {
            switch arch {
            case "x86_64", "i386":
                self.platform = "iPhoneSimulator"
            default:
                self.platform = "iPhoneOS"
            }
        }

        switch self.platform {
        case "iPhoneSimulator":
            cFlags.append(" -mios-simulator-version-min=\(deploymentTarget)")
        default:
            cFlags.append(" -mios-version-min=\(deploymentTarget) -fembed-bitcode")
        }
    }
}

// https://github.com/aciidb0mb3r/Configuration/blob/master/Sources/POSIX/system.swift

private func _WSTATUS(_ status: CInt) -> CInt {
    return status & 0x7f
}

private func WIFEXITED(_ status: CInt) -> Bool {
    return _WSTATUS(status) == 0
}

private func WEXITSTATUS(_ status: CInt) -> CInt {
    return (status >> 8) & 0xff
}

Tool.main()
