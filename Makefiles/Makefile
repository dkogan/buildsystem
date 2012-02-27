# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs

# directories in arbitrary order
DIRS :=

define DIRS_template

# We're about to include a user file. I wipe all the active variables so
# that it can start with a clean slate. I do this here and NOT in the
# header because $(dir) is an active var, and doing it here will restore
# this variable immediately afterward
$$(eval $$(reset-active-vars))
dir := $(dirhere)
include $$(dir)/Makefile

# include the $(dirhere)/tests Makefile if there is one
ifneq ($$(wildcard $(dirhere)/tests/Makefile),)
$$(eval $$(reset-active-vars))
dir := $(dirhere)/tests
include $$(dir)/Makefile
endif
endef


$(foreach dirhere,$(DIRS),$(eval $(DIRS_template)))

.DEFAULT_GOAL := all
