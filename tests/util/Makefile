ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

TARGET_NAME := test-utility

CFLAGS += -DCFLAGS
CCXXFLAGS += -I$(ROOT)

BIN_TARGET = main
LDLIBS += ../libA/libA.so

# this project has an embedded library
LIB_OBJECTS += lib_embeddedutil.o

DAEMON_COMMAND = util

include $(ROOT)/buildsystem/Makefile.footer
