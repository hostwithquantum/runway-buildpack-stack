.PHONY: build test

EXAMPLES_DIR=../runway-examples/content

META_BUILDPACKS=$(patsubst %, %buildpack.cnb, $(wildcard meta/*/))

build: build-builder
	docker build -t r.planetary-quantum.com/runway-public/runway-runimage:jammy-full ./runimage

# build the builder in its full glory so we can inspect
build-builder-unflattened: $(META_BUILDPACKS)
	$(info Build unflattened)
	pack builder create builder-unflattened \
		--target linux/amd64 \
		--config builder.toml

build-builder: $(META_BUILDPACKS)
	$(info Build flattened)
	pack builder create --publish "$(PUBLISH_TAG)" \
		--target linux/amd64 \
		--flatten "$(ALL_BUILDPACKS)" \
		--config builder.toml \
		--verbose

meta/%/buildpack.cnb: meta/%/*.toml
	pack -v buildpack package $@ --config meta/$*/package.toml --format file --pull-policy if-not-present

test: $(patsubst $(EXAMPLES_DIR)/%/, test-%, $(wildcard $(EXAMPLES_DIR)/*/))
show-tests:
	@echo $(patsubst $(EXAMPLES_DIR)/%/, test-%, $(wildcard $(EXAMPLES_DIR)/*/))

test-%: FORCE
	pack build runway-buildpack-test --path "$(EXAMPLES_DIR)/$*" \
		--builder builder \
        --verbose --pull-policy if-not-present
FORCE:

test-hugo: FORCE # (needs env vars, set by builder in real life)
	pack build runway-buildpack-test --path "$(EXAMPLES_DIR)/hugo" \
		--env BP_WEB_SERVER_ROOT=./ --env BP_WEB_SERVER=nginx \
		--builder builder \
        --verbose --pull-policy if-not-present

test-docker test-jekyll test-ruby test-README.md.m4:
	@echo "ignored (does not use buildpacks)"
