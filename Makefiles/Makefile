# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs

# directories in arbitrary order
DIRS :=

define DIRS_template

$$(eval $$(reset-nonpersistent))

include $(1)/Makefile

endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))

# done with $(dir). Any use of it at this point is a bug, so I poison
# the variable to make this obvious
dir = /DIR_poison

.DEFAULT_GOAL := all
