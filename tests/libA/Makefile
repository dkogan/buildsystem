ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = a.o
CCXXFLAGS += -DA

BIN_TARGET = utila
LDLIBS += ../libB/libB.so

include $(ROOT)/buildsystem/Makefile.footer
