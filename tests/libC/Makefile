ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = c.o
CCXXFLAGS += -DC

# just to test LDLIBS_SYSTEM
LDLIBS = -lstdc++

include $(ROOT)/buildsystem/Makefile.footer
