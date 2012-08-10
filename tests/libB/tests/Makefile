ROOT   ?= ../..
include $(ROOT)/buildsystem/Makefile.header


BIN_TARGET_NOINST = libb_test
CCXXFLAGS += -I$(dir)/..

LDLIBS += ../libB.so

$(dir)/check: $(dir)/libb_test
	./$<

include $(ROOT)/buildsystem/Makefile.footer
