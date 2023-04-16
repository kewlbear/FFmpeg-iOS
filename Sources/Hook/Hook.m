// FFmpeg-iOS: Swift package to use FFmpeg in your iOS apps
// Copyright (C) 2023  Changbeom Ahn
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#import <Foundation/Foundation.h>
#import "Hook.h"
//@import ffmpeg;

#define HOOK0 1973

jmp_buf j;

static void resetFFmpeg(void) {
    // FIXME: replace with #include <ffmpeg.h>
    extern int nb_input_files;
    extern int nb_output_files;
    extern int nb_filtergraphs;
    
    nb_input_files = 0;
    nb_output_files = 0;
    nb_filtergraphs = 0;
}

static void resetFFprobe() {
    // FIXME: ...
}

void FFmpeg_exit(int code) {
    NSLog(@"%s=%d, will longjmp", __func__, code);
    longjmp(j, code ?: HOOK0);
}

int HookMain(int argc, char **argv, int (*realMain)(int, char**), void (*reset)()) {
    int ret = setjmp(j);
    NSLog(@"%s: setjmp=%d", __func__, ret);
    if (ret) {
        reset();
        
        return ret == HOOK0 ? 0 : ret;
    }
    
    ret = realMain(argc, argv);
    NSLog(@"%s: realMain=%d", __func__, ret);
    
    reset();
    
    return ret;
}

int HookFFmpeg(int argc, char **argv) {
    extern int FFmpeg_main(int, char**);
    return HookMain(argc, argv, FFmpeg_main, resetFFmpeg);
}

int HookFFprobe(int argc, char **argv) {
    extern int FFprobe_main(int, char**);
    return HookMain(argc, argv, FFprobe_main, resetFFprobe);
}
