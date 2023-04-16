TEST_HARNESS ?= https://github.com/cloudposse/test-harness.git
TEST_HARNESS_BRANCH ?= master
TEST_HARNESS_PATH = $(realpath .test-harness)
BATS_ARGS ?= --tap
BATS_LOG ?= test.log

# Define a macro to run the tests
define RUN_TESTS
@echo "Running tests in $(1)"
@cd $(1) && bats $(BATS_ARGS) $(addsuffix .bats,$(addprefix $(TEST_HARNESS_PATH)/test/terraform/,$(TESTS)))
endef

default: all

-include Makefile.*

## Provision the test-harnesss
.test-harness:
	[ -d $@ ] || git clone --depth=1 -b $(TEST_HARNESS_BRANCH) $(TEST_HARNESS) $@

## Initialize the tests
init: .test-harness

## Install all dependencies (OS specific)
deps::
	@exit 0

## Clean up the test harness
clean:
	[ "$(TEST_HARNESS_PATH)" == "/" ] || rm -rf $(TEST_HARNESS_PATH)

## Run all tests
all: module examples/complete examples/no-replication

# This module does not pass `terraform validate` because of
# https://github.com/hashicorp/terraform/issues/28490
# so we remove it from the list of tests on the module
## Run basic sanity checks against the module itself
module: export TESTS ?= installed lint module-pinning provider-pinning terraform-docs input-descriptions output-descriptions
module: deps
	$(call RUN_TESTS, ../)

## Run tests against example
examples/complete examples/no-replication: export TESTS ?= installed lint validate
examples/complete examples/no-replication: deps
	$(call RUN_TESTS, ../$@)
