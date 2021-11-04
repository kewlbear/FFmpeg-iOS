include ../../../ffmpeg/Makefile

xinstall: install-libs install-headers libffmpeg.a
	$(INSTALL) -m 644 libffmpeg.a "$(LIBDIR)"
	$(Q)mkdir -p "$(INCDIR)/libffmpeg"
	$(INSTALL) -m 644 ../../../libffmpeg/*.h "$(INCDIR)/libffmpeg"

$(SRC_PATH)/fftools/ffmpeg.o: CFLAGS += -Dmain=FFmpeg_main

libffmpeg.a: fftools/ffmpeg.o fftools/ffmpeg_opt.o fftools/ffmpeg_filter.o fftools/ffmpeg_hw.o fftools/ffmpeg_videotoolbox.o fftools/cmdutils.o
	$(RM) $@
	$(AR) $(ARFLAGS) $(AR_O) $^
