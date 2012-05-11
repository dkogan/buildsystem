ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = b.o
CCXXFLAGS += -DB

LDLIBS += ../libC/libC.so

include $(ROOT)/buildsystem/Makefile.footer
