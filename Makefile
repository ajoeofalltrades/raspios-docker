# ==================== default / meta targets ============================
.PHONY: help pre-commit lint all test clean

all: pre-commit

test: pre-commit

help: ## List all targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

clean:                ## Remove venv and build artefacts
	rm -rf .venv dist tmp
	
# ==================== Python virtual-env bootstrap ======================
VENV := .venv
python := $(VENV)/bin/python
pip    := $(VENV)/bin/pip      # ← := (immediate) is safer than = here

$(VENV)/bin/activate: ## Initialise python venv with pre-commit
	python3 -m venv $(VENV)
	$(pip) install --upgrade pip pre-commit
	@touch $@                 # create the stamp file so target is up-to-date

pre-commit: $(VENV)/bin/activate ## Run all pre-commit hooks
	$(VENV)/bin/pre-commit run --all-files

# ==================== Linters ==========================================
lint: ## Run all linters locally
	shellcheck scripts/*.sh
	shfmt -i 2 -d scripts
	actionlint -oneline
	markdownlint-cli2 *.md