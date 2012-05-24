ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = c.o
CCXXFLAGS += -DC

$(dir)/c.c: $(dir)/c.generated.h

$(dir)/c.generated.h:
	echo 'static int gen = 5;' > $@

EXTRACLEAN += c.generated.h


# just to test LDLIBS_SYSTEM
LDLIBS = -lstdc++

include $(ROOT)/buildsystem/Makefile.footer
