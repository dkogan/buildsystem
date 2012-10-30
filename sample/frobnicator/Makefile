ROOT ?= ..
include $(ROOT)/buildsystem/Makefile.header

# by default, this project has the same name as its directory. If something else
# is desired, set it here. This controls the target package name, the
# configuration file path, etc. Here, I do override the name, so instead of
# "oblong-frobnicator" the package will be called "oblong-dofrobnicate"
TARGET_NAME := dofrobnicate

CCXXFLAGS += -I$(ROOT)

BIN_TARGET = dofrobnicate
LDLIBS += ../libAAA/libAAA.so

DAEMON_COMMAND = dofrobnicate

include $(ROOT)/buildsystem/Makefile.footer
