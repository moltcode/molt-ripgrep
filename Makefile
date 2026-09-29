NAME    := molt-ripgrep
VERSION := $(shell jq -r .version package.json)
# package.json version is <ripgrep>-<revision>, e.g. 15.1.0-1: the upstream
# BurntSushi/ripgrep release plus the packaging revision.
RIPGREP := $(word 1,$(subst -, ,$(VERSION)))

PLATFORMS := darwin-arm64 darwin-x64 linux-x64 linux-arm64 win32-x64
CACHE     ?= $(or $(XDG_CACHE_HOME),$(HOME)/.cache)/molt-ripgrep

.PHONY: dist release clean

# out/: one npm-layout plugin tarball per platform (package/ root) and
# artifacts.json with url/sha256/size per platform for the Molt catalog.
dist:
	@rm -rf build out && mkdir -p build out "$(CACHE)"
	@for p in $(PLATFORMS); do \
		./scripts/package.sh "$$p" "$(RIPGREP)" "$(CACHE)" build "out/$(NAME)-$(VERSION)-$$p.tgz" || exit 1; \
	done
	@./scripts/artifacts.sh "$(NAME)" "$(VERSION)" $(PLATFORMS) > out/artifacts.json
	@cat out/artifacts.json

# Publishes the existing out/ as GitHub release v$(VERSION) (run `make dist`
# first). No rebuild here: the Molt catalog pins these exact tarballs' sha256,
# and assets are never replaced.
release:
	@test -f out/artifacts.json || (echo "run make dist first"; exit 1)
	gh release create "v$(VERSION)" out/*.tgz out/artifacts.json --repo moltcode/$(NAME) \
		--title "$(NAME) $(VERSION)" \
		--notes "ripgrep $(RIPGREP) for Molt Code: the official BurntSushi/ripgrep release binaries, unmodified (checked against upstream's published sha256)."

clean:
	rm -rf build out
