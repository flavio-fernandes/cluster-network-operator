MIN_GOLANGCI_LINT_VER_MAJOR=1
MIN_GOLANGCI_LINT_VER_MINOR=53
GOLANGCI_LINT_VER_MAJOR := $(shell golangci-lint --version | grep -o "version [0-9\.]*" | cut -f2 -d " " | cut -f1 -d ".")
GOLANGCI_LINT_VER_MINOR := $(shell golangci-lint --version | grep -o "version [0-9\.]*" | cut -f2 -d " " | cut -f2 -d ".")
GOLANGCI_GT_1_53 := $(shell [ $(GOLANGCI_LINT_VER_MAJOR) -gt 1 -o \( $(GOLANGCI_LINT_VER_MAJOR) -eq 1 -a $(GOLANGCI_LINT_VER_MINOR) -ge 53 \) ] && echo true)

all: build
.PHONY: all

# Include the library makefile
include $(addprefix ./vendor/github.com/openshift/build-machinery-go/make/, \
	golang.mk \
	targets/openshift/deps-gomod.mk \
	targets/openshift/operator/profile-manifests.mk \
)

# This will include additional actions on the update and verify targets to ensure that profile patches are applied
# to manifest files
# $0 - macro name
# $1 - target name
# $2 - profile patches directory
# $3 - manifests directory
$(call add-profile-manifests,manifests,./profile-patches,./manifests)

# Run core verification and all self contained tests.
#
# Example:
#   make check
check: | verify test-unit golangci-lint
.PHONY: check

ifneq ($(GOLANGCI_GT_1_53),true)
golangci-lint: install.tools
endif

golangci-lint:
	golangci-lint run --verbose --print-resources-usage --modules-download-mode=vendor --timeout=5m0s
.PHONY: golangci-lint

install.tools:
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | bash -s -- -b ${GOPATH}/bin
.PHONY: install.tools



clean:
	$(RM) cluster-network-operator cluster-network-check-endpoints cluster-network-check-target
.PHONY: clean

GO_TEST_PACKAGES :=./pkg/... ./cmd/...
