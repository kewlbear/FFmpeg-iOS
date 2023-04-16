include ../../../ffmpeg/Makefile

install-libfftools: install-libs install-headers libfftools.a
	$(INSTALL) -m 644 libfftools.a "$(LIBDIR)"
	$(Q)mkdir -p "$(INCDIR)/libfftools"
	$(INSTALL) -m 644 ../../../libfftools/*.h "$(INCDIR)/libfftools"
	$(INSTALL) -m 644 src/fftools/ffmpeg.h "$(INCDIR)/libfftools"

fftools/ffmpeg.o: CFLAGS += -Dmain="FFmpeg_main(int, char**); extern int FFmpeg_main"

fftools/ffprobe.o: CFLAGS += -Dmain="FFprobe_main(int, char**); extern int FFprobe_main"

LIBFFTOOLS = ffmpeg ffprobe

$(foreach P,$(LIBFFTOOLS),$(eval $(call DOFFTOOL,$(P))))

$(OBJS-ffmpeg) $(OBJS-ffprobe): CFLAGS += -Dexit=FFmpeg_exit

libfftools.a: $(OBJS-ffmpeg) $(OBJS-ffprobe)
	$(RM) $@
	$(AR) $(ARFLAGS) $(AR_O) $^
