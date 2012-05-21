ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = b.o b2.o
CCXXFLAGS += -DB

$(dir)/b2.o: CCXXFLAGS += -DB2 -O0

LDLIBS += ../libC/libC.so

include $(ROOT)/buildsystem/Makefile.footer
