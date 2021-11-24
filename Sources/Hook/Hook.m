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
    extern int nb_input_files;
    extern int nb_input_streams;
    extern int nb_output_files;
    extern int nb_output_streams;
    extern int nb_filtergraphs;
    
    nb_input_files = 0;
    nb_input_streams = 0;
    nb_output_files = 0;
    nb_output_streams = 0;
    nb_filtergraphs = 0;
}

void FFmpeg_exit(int code) {
    NSLog(@"%s=%d, will longjmp", __func__, code);
    longjmp(j, code ?: HOOK0);
}

int HookMain(int argc, char **argv) {
    int ret = setjmp(j);
    NSLog(@"%s: setjmp=%d", __func__, ret);
    if (ret) {
        reset();
        
        return ret == HOOK0 ? 0 : ret;
    }
    
    ret = FFmpeg_main(argc, argv);
    NSLog(@"%s: FFmpeg_main=%d", __func__, ret);
    
    reset();
    
    return ret;
}
