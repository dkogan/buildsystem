ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = c.o
CCXXFLAGS += -DC

# distribute ALL the headers
DIST_HEADERS = *.h


$(dir)/c.c: $(dir)/c.generated.h

$(dir)/c.generated.h:
	echo 'static int gen = 5;' > $@

EXTRACLEAN += c.generated.h

# override the Makefile.sys GLOBAL_EXTRA setting
CCXXFLAGS := $(patsubst -DGLOBAL_EXTRA=%,-DGLOBAL_EXTRA=5,$(CCXXFLAGS))

# just to test LDLIBS_SYSTEM
LDLIBS = -lstdc++

include $(ROOT)/buildsystem/Makefile.footer
