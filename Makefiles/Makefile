# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs

# directories in arbitrary order
DIRS :=

define DIRS_template

dir := $(dirhere)
$$(eval $$(reset-nonpersistent))
include $$(dir)/Makefile

# include the $(dirhere)/tests Makefile if there is one
ifneq ($$(wildcard $(dirhere)/tests/Makefile),)
dir := $(dirhere)/tests
$$(eval $$(reset-nonpersistent))
include $$(dir)/Makefile
endif
endef

$(foreach dirhere,$(DIRS),$(eval $(DIRS_template)))

# done with $(dir). Any use of it at this point is a bug, so I poison
# the variable to make this obvious
dir = /DIR_poison

.DEFAULT_GOAL := all
