# top level Makefile. I simply relay whatever I'm asked to do to the lower levels

DIRS=libRetro libAttic libPipeline devices/isense
RULES=clean all check install

.DEFAULT_GOAL := all

# This looks convoluted, but really, it just relays any listed rule to
# ALL the listed directories
define DIRS_template

define RULES_template
$(1)_$$(1)_BUILD:
	$$$$(MAKE) -C $(1) $$(1)
.PHONY: $$(1)_$(1)_BUILD $$(1)
$$(1): $(1)_$$(1)_BUILD
endef

$$(foreach rule,$$(RULES),$$(eval $$(call RULES_template,$$(rule))))

endef

$(foreach dir,$(DIRS),$(eval $(call DIRS_template,$(dir))))
