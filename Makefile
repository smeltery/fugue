# fugue — quality gate.
#
# `make check` runs every gate CI runs, in the same order. Each gate is also a
# standalone target so you can run just the one you're iterating on. Tool paths
# are overridable (e.g. `make check SHELLCHECK=/path/to/shellcheck`).

SHELLCHECK   ?= shellcheck
SHFMT        ?= shfmt
HADOLINT     ?= hadolint
ACTIONLINT   ?= actionlint
BATS         ?= bats
DOCKER       ?= docker
MARKDOWNLINT ?= markdownlint-cli2
MMDC         ?= mmdc
NPM          ?= npm
NODE         ?= node

# Shell sources, split by how they're invoked:
#   SCRIPTS  — executable entrypoints and helpers (have shebangs)
#   PROFILES — sourced env fragments (carry a `# shellcheck shell=bash` directive)
SCRIPTS  := bin/fugue $(wildcard bin/lib/fugue-*) src/fugue-entry install.sh $(wildcard scripts/*.sh)
PROFILES := $(wildcard profiles/*.env)
SHELL_SRC := $(SCRIPTS) $(PROFILES)

# Match the project's hand-tuned style: two-space indent, switch-case indented.
SHFMT_FLAGS := -i 2 -ci

IMAGE ?= ghcr.io/smeltery/fugue:latest

.PHONY: help check fmt \
        check\:format check\:lint check\:dockerfile check\:tests check\:build \
        check\:markdown check\:mermaid check\:site check\:actions check\:secrets \
        check\:budgets

help:
	@echo "fugue make targets:"
	@echo "  make check            run the full quality gate (what CI runs)"
	@echo "  make fmt              auto-format shell sources with shfmt"
	@echo "  make check:format     verify shell sources are shfmt-clean"
	@echo "  make check:lint       shellcheck the scripts and profiles"
	@echo "  make check:dockerfile hadolint the Dockerfile"
	@echo "  make check:tests      run the bats test suite"
	@echo "  make check:build      build the container image"
	@echo "  make check:markdown   markdownlint the docs"
	@echo "  make check:mermaid    validate the mermaid diagrams"
	@echo "  make check:site       type-check and build the docs site"
	@echo "  make check:actions    actionlint the workflow YAML"
	@echo "  make check:secrets    gitleaks secret scan"
	@echo "  make check:budgets    enforce file-size and flat-directory budgets"

# The aggregate gate, mirroring the CI job order. Invoke the colon-named targets
# recursively so both GNU Make and BSD Make handle the target names consistently.
check:
	$(MAKE) check:budgets
	$(MAKE) check:format
	$(MAKE) check:lint
	$(MAKE) check:dockerfile
	$(MAKE) check:tests
	$(MAKE) check:markdown
	$(MAKE) check:mermaid
	$(MAKE) check:build
	$(MAKE) check:actions
	$(MAKE) check:secrets
	$(MAKE) check:site

fmt:
	$(SHFMT) $(SHFMT_FLAGS) -w $(SHELL_SRC)

check\:format:
	$(SHFMT) $(SHFMT_FLAGS) -d $(SHELL_SRC)

check\:lint:
	$(SHELLCHECK) -x $(SCRIPTS)
	$(SHELLCHECK) $(PROFILES)

check\:dockerfile:
	$(HADOLINT) Dockerfile

check\:tests:
	$(BATS) test/

check\:markdown:
	$(MARKDOWNLINT)

check\:mermaid:
	MMDC="$(MMDC)" bash scripts/check-mermaid.sh

check\:site:
	cd site && $(NPM) ci && $(NPM) run build

check\:build:
	$(DOCKER) build -t $(IMAGE) .

check\:actions:
	$(ACTIONLINT) -color

check\:secrets:
	gitleaks detect --no-banner --redact --source .

check\:budgets:
	$(NODE) scripts/check-file-sizes.mjs
	$(NODE) scripts/check-flat-directories.mjs
