ROOT ?= .

# if we don't yet know whether this is a local build or not, it is NOT. This
# Makefile must have been seen first, which implies that we're starting at the
# root
LOCALDIR_BUILD ?= 0

TOPLEVEL_INCLUDED := 1


DIRS = $(addprefix $(ROOT)/, )

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


# I include the lower-level Makefile if it's not already marked as processed
ifndef $$(abspath $(1))/INCLUDED

ifneq ($(MAKE_DEBUG),)
$$(info Including $(1)/Makefile)
endif

include $(1)/Makefile
$$(abspath $(1))/INCLUDED := 1


endif


endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))


ifeq ($(LOCALDIR_BUILD),1)
clean: clean_local
else
clean: clean_world
endif
.PHONY: clean



ifeq ($(LOCALDIR_BUILD),0)
.DEFAULT_GOAL := all
endif
