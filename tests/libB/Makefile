ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

CCXXFLAGS += -I$(ROOT)

LIB_OBJECTS = b.o b2.o
CCXXFLAGS += -DB

BIN_TARGET = utilb

#CCXXFLAGS += -O1
$(dir)/b2.o: CCXXFLAGS += -DB2 -O0 -pedantic

LDLIBS += ../libC/libC.so

DAEMON_COMMAND = utilb
define UPSTART_STANZAS
libb upstart stanza
endef

include $(ROOT)/buildsystem/Makefile.footer
