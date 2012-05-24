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

# override the Makefile.sys GLOBAL_EXTRA settings
#
# GLOBAL_EXTRA has a default of 3 (in Makefile.sys), a per-project override of
# 5, and a per-target override of 7. The 7 should win
#
# GLOBAL_EXTRA_OTHER has a default of 33 (in Makefile.sys) and a per-project
# override of 55
CCXXFLAGS := $(patsubst -DGLOBAL_EXTRA=%,-DGLOBAL_EXTRA=5,$(CCXXFLAGS))
CCXXFLAGS := $(patsubst -DGLOBAL_EXTRA_OTHER=%,-DGLOBAL_EXTRA_OTHER=55,$(CCXXFLAGS))
$(dir)/c.o: CCXXFLAGS := $(patsubst -DGLOBAL_EXTRA=%,-DGLOBAL_EXTRA=7,$(CCXXFLAGS))



# just to test LDLIBS_SYSTEM
LDLIBS = -lstdc++

include $(ROOT)/buildsystem/Makefile.footer
