ROOT ?= .

DIRS = $(addprefix $(ROOT)/, )


TOPLEVEL_INCLUDED := 1

define DIRS_template

ALLCFLAGS               :=
CFLAGS                  :=
CXXFLAGS                :=
LDFLAGS                 :=
LDLIBS                  :=
LDLIBS_PROJECT          :=
DIST_BINS		:=
DIST_MANS		:=
DIST_DOCS		:=
DIST_ETC_OBLONG		:=
DIST_UPSTART		:=
LIB_OBJECTS		:=
BIN_TARGET		:=
BIN_TARGET_NOINST	:=
EXTRACLEAN              :=


# I include the lower-level Makefile if it's not already marked as processed
ifndef $$(abspath $(1))/INCLUDED
include $(1)/Makefile
$$(abspath $(1))/INCLUDED := 1
endif


endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))




.DEFAULT_GOAL := all
