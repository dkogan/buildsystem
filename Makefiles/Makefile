# ROOT is assumed relative
ROOT := .
include buildsystem/Makefile.defs


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


COND_DARWIN := $(if $(findstring Darwin,$(shell uname -a)),1)

include Makefile.projectdefs

# include the system-dependent variables and anything oblong-specific. I clear
# out all the customizable variables first, and then absorb the new
# customizations
$(foreach v,$(ACTIVE_VARS_CUSTOMIZABLE),$(eval $v :=))
include Makefile.sys
$(foreach v,$(ACTIVE_VARS_CUSTOMIZABLE),$(if $($v),$(eval _CUSTOMIZED_$v += $($v))))

# default compilers, linkers
CC        ?= gcc
CXX       ?= g++
CC_LINKER ?= $(CC)




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

# any errors delete half-built targets
.DELETE_ON_ERROR:

#}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}} have -Rr. Build!
endif # ifeq ($(_make_will_recurse),)
