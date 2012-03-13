# ROOT assumed to be absolute later
ROOT := $(abspath .)
include Makefile.defs


# I want to support custom make variables passed in on the commandline.
# Ideally I want the user to pass in a variable such as CFLAGS, then
# have those flags be used automatically, in addition to all other flags
# that are determined later. Only some of my variables are customizable.
# Any ACTIVE_VAR that isn't customizable isn't allowed to be set at this
# point. For instance the user shouldn't be trying to customize
# LIB_OBJECTS, as it's a fundamental Makefile setting. Non-active vars
# could be customized, though, and the user is responsible for making
# sure they don't clash with anything
$(foreach var,$(ACTIVE_VARS),$(if $($(var)),$(if $(filter-out $(ACTIVE_VARS_CUSTOMIZABLE),$(var)),$(error Var "$(var)" not customizable. Are you SURE you want to set it yourself?))))
# There are two ways to pass variables to make:
#
# make CFLAGS=-foo
#   and
# CFLAGS=-foo make
#
# The former creates a "command line" variable and the latter an
# "environment variable". In order to be able to modify a "command line"
# variable (to add other flags, say), one MUST use 'override'. So one would have to do
#
# override CFLAGS += -bar
#
# without the "override" nothing would happen. I want to avoid this
# rabbithole entirely, so I disallow "command line" variables for things
# that I modify. Environment variables are OK, though
$(foreach var,$(ACTIVE_VARS_CUSTOMIZABLE),$(if $(filter command line,$(origin $(var))), $(error Var "$(var)" not allowed as a make parameter. Please do "$(var)=xxxx make yyyy" instead)))
#
# OK. Any user-customized vars are valid. I'm going to apply these to
# all the sub-makefiles. Thus I copy the values of these variables
# (CFLAGS to _USER_CUSTOMIZED_CFLAGS for instance), and apply them one
# at a time when I need them
$(foreach var,$(ACTIVE_VARS_CUSTOMIZABLE),$(if $($(var)),$(eval _USER_CUSTOMIZED_$(var) := $($(var)))))

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
