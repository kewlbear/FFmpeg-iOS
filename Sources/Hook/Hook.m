//
//  Hook.m
//  
//
//  Created by Changbeom Ahn on 2021/11/05.
//

#import <Foundation/Foundation.h>
#import "Hook.h"
@import ffmpeg;

#define HOOK0 1973

int j;

void FFmpeg_exit(int code) {
    longjmp(&j, code ?: HOOK0);
}

int HookMain(int argc, char **argv) {
    int ret = setjmp(&j);
    if (ret) {
        return ret == HOOK0 ? 0 : ret;
    }
    
    FFmpeg_main(argc, argv);
}
