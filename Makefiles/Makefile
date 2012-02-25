# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs


DIRS = 

define DIRS_template

ALLCFLAGS          :=
CFLAGS             :=
CXXFLAGS           :=
LDFLAGS            :=
LDLIBS             :=
DIST_BINS          :=
DIST_MANS          :=
DIST_DOCS          :=
DIST_ETC_OBLONG    :=
DIST_UPSTART       :=
LIB_OBJECTS        :=
BIN_TARGET         :=
BIN_TARGET_NOINST  :=
EXTRACLEAN         :=
TARGET_NAME        :=
LIB_TARGET_SO_BARE :=
LIB_TARGET_SO      :=
LIB_TARGET_A       :=

include $(1)/Makefile

endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))


.DEFAULT_GOAL := all
