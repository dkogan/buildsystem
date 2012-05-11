ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT) -I$(dir)

LIB_OBJECTS = a.o
CCXXFLAGS += -DA

BIN_TARGET = utila

$(dir)/utila: $(dir)/subdir/utila_helper.o
EXTRACLEAN += subdir/utila_helper.o

LDLIBS += ../libB/libB.so

include $(ROOT)/buildsystem/Makefile.footer
