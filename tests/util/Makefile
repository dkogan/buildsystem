ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

TARGET_NAME := test-utility

CCXXFLAGS += -I$(ROOT)

BIN_TARGET = main
LDLIBS += ../libA/libA.so

DAEMON_COMMAND = tuner --restore

include $(ROOT)/buildsystem/Makefile.footer
