ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT) -I$(dir)

LIB_OBJECTS = a.o
CCXXFLAGS += -DA

BIN_TARGET = utila utila2

$(dir)/utila: $(dir)/subdir/utila_helper.o
EXTRACLEAN += subdir/utila_helper.o

$(dir)/utila2.o: CCXXFLAGS += -DUTILA2

# just an arbitrary option to test the build system's handling of such things
$(dir)/utila2: LDFLAGS += -Wl,--stats
$(dir)/utila2: LDLIBS  += -lc

# -lm to test LDLIBS_SYSTEM
LDLIBS += ../libB/libB.so -lm

include $(ROOT)/buildsystem/Makefile.footer
