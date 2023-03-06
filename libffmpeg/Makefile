include ../../../ffmpeg/Makefile

xinstall: install-libs install-headers libffmpeg.a
	$(INSTALL) -m 644 libffmpeg.a "$(LIBDIR)"
	$(Q)mkdir -p "$(INCDIR)/libffmpeg"
	$(INSTALL) -m 644 ../../../libffmpeg/*.h "$(INCDIR)/libffmpeg"
	$(INSTALL) -m 644 src/fftools/ffmpeg.h "$(INCDIR)/libffmpeg"

fftools/ffmpeg.o: CFLAGS += -Dmain="FFmpeg_main(int, char**); extern int FFmpeg_main"

OBJS-ffmpeg +=                  \
	fftools/cmdutils.o fftools/opt_common.o fftools/ffmpeg.o \
    fftools/ffmpeg_demux.o      \
    fftools/ffmpeg_filter.o     \
    fftools/ffmpeg_hw.o         \
    fftools/ffmpeg_mux.o        \
    fftools/ffmpeg_mux_init.o   \
    fftools/ffmpeg_opt.o        \
    fftools/objpool.o           \
    fftools/sync_queue.o        \
    fftools/thread_queue.o      \

$(OBJS-ffmpeg): CFLAGS += -Dexit=FFmpeg_exit

libffmpeg.a: $(OBJS-ffmpeg)
	$(RM) $@
	$(AR) $(ARFLAGS) $(AR_O) $^
