# ROOT is assumed relative
ROOT := .
include Makefile.defs


# call the make again with -Rr unless those options are both already
# there. This is mostly a performance optimization measure
_make_will_recurse := 1
ifneq ($(findstring r,$(MAKEFLAGS)),)
ifneq ($(findstring R,$(MAKEFLAGS)),)
_make_will_recurse :=
endif
endif

ifneq ($(_make_will_recurse),)
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{ need to recurse with -Rr

$(eval $(_define_recursive_make))

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} need to recurse with -Rr
else
#{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{ have -Rr. Build!




# directories in arbitrary order
DIRS :=

$(eval $(_read_subsets))





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


#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} have -Rr. Build!
endif # ifeq ($(_make_will_recurse),)
