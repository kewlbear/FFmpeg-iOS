//
//  Hook.m
//  
//
//  Created by Changbeom Ahn on 2021/11/05.
//

#import <Foundation/Foundation.h>
//#import "Hook.h"
@import ffmpeg;

#define HOOK0 1973

jmp_buf j;

void reset(void) {
    // FIXME: replace with #include <ffmpeg.h>
    extern int nb_output_files;
    extern int nb_filtergraphs;
    
    nb_output_files = 0;
    nb_filtergraphs = 0;
}

void FFmpeg_exit(int code) {
    longjmp(j, code ?: HOOK0);
}

int HookMain(int argc, char **argv) {
    int ret = setjmp(j);
    if (ret) {
        reset();
        return ret == HOOK0 ? 0 : ret;
    }
    
    ret = FFmpeg_main(argc, argv);
    reset();
    return ret;
}
