DIRS =


define DIRS_template

CFLAGS                  :=
CXXFLAGS                :=
LDFLAGS                 :=
LDLIBS                  :=
DIST_BINS		:=
DIST_MANS		:=
DIST_DOCS		:=
DIST_ETC_OBLONG		:=
DIST_UPSTART		:=
LIB_OBJECTS		:=
BIN_TARGET		:=
BIN_TARGET_NOINST	:=
EXTRACLEAN              :=



include $(1)/Makefile

$(dir)/%.o: CXXFLAGS := -I$(1) $$(CXXFLAGS)
$(dir)/%.o: CFLAGS   := -I$(1) $$(CFLAGS)

$$(BIN_TARGET_ALL): LDFLAGS := $$(LDFLAGS)
$$(BIN_TARGET_ALL): LDLIBS  := $$(LDLIBS)
$$(LIB_TARGET_SO):  LDFLAGS := $$(LDFLAGS)
$$(LIB_TARGET_SO):  LDLIBS  := $$(LDLIBS)



clean: $(1)/CLEAN
install: $(1)/INSTALL

endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))




.DEFAULT_GOAL := all
