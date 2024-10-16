.PHONY: build test

EXAMPLES_DIR=../runway-examples/content

build:
	pack builder create builder --config builder.toml

test: $(patsubst $(EXAMPLES_DIR)/%/, test-%, $(wildcard $(EXAMPLES_DIR)/*/))
show-tests:
	@echo $(patsubst $(EXAMPLES_DIR)/%/, test-%, $(wildcard $(EXAMPLES_DIR)/*/))

test-%: FORCE
	pack build runway-buildpack-test --path "$(EXAMPLES_DIR)/$*" \
		--builder builder \
        --verbose --pull-policy if-not-present
FORCE:

test-docker test-hugo test-jekyll test-ruby test-README.md.m4:
	@echo "ignored (does not use buildpacks)"
