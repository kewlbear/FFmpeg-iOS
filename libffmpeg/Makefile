include ../../../ffmpeg/Makefile

xinstall: install-libs install-headers libffmpeg.a
	$(INSTALL) -m 644 libffmpeg.a "$(LIBDIR)"
	$(Q)mkdir -p "$(INCDIR)/libffmpeg"
	$(INSTALL) -m 644 ../../../libffmpeg/*.h "$(INCDIR)/libffmpeg"
	$(INSTALL) -m 644 src/fftools/ffmpeg.h "$(INCDIR)/libffmpeg"

fftools/ffmpeg.o: CFLAGS += -Dmain="FFmpeg_main(int, char**); extern int FFmpeg_main"

fftools/ffmpeg.o fftools/ffmpeg_opt.o fftools/ffmpeg_filter.o fftools/ffmpeg_hw.o fftools/ffmpeg_videotoolbox.o fftools/cmdutils.o: CFLAGS += -Dexit=FFmpeg_exit

libffmpeg.a: fftools/ffmpeg.o fftools/ffmpeg_opt.o fftools/ffmpeg_filter.o fftools/ffmpeg_hw.o fftools/ffmpeg_videotoolbox.o fftools/cmdutils.o
	$(RM) $@
	$(AR) $(ARFLAGS) $(AR_O) $^
