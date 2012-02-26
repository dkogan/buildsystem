# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs

# directories in arbitrary order
DIRS :=

define DIRS_template

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

# done with $(dir). Any use of it at this point is a bug, so I poison
# all my variables to make this obvious
$(eval $(poison-active-vars))

.DEFAULT_GOAL := all
