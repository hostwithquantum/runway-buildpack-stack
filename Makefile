.PHONY: build test

EXAMPLES_DIR=../runway-examples/content

META_BUILDPACKS=$(patsubst %, %buildpack.cnb, $(wildcard meta/*/))

build: $(META_BUILDPACKS)
	docker build -t r.planetary-quantum.com/runway-public/runway-runimage:jammy-full ./runimage
	pack builder create builder --config builder.toml --pull-policy if-not-present

meta/%/buildpack.cnb: meta/%/*
	pack buildpack package $@ --config meta/$*/package.toml --format file --pull-policy if-not-present

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
