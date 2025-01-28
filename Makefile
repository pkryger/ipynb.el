export EMACS ?= $(shell command -v emacs 2>/dev/null)
CASK_DIR := $(shell cask package-directory)

files = $$(cask files | grep -Ev 'ipynb-(pkg|autoloads).el')

$(CASK_DIR): Cask
	cask install
	@touch $(CASK_DIR)

.PHONY: cask
cask: $(CASK_DIR)

.PHONY: bytecompile
bytecompile: cask
	cask emacs -batch -L . -L test \
	  --eval "(setq byte-compile-error-on-warn t)" \
	  -f batch-byte-compile $(files)
	  (ret=$$? ; cask clean-elc ; exit $$ret)

.PHONY: lint
lint: cask
	cask emacs -batch -L . \
	  --load package-lint \
      --eval '(setq package-lint-main-file "ipynb.el")' \
	  --funcall package-lint-batch-and-exit $(files)

.PHONY: relint
relint: cask
	cask emacs -batch -L . -L test \
	  --load relint \
	  --funcall relint-batch $(files)

.PHONY: checkdoc
checkdoc: cask
	cask emacs -batch -L . \
	  --load checkdoc-batch \
	  --funcall checkdoc-batch $(files)
