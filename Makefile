.PHONY: all
all:
	@echo "No default target. Try 'make test' or 'make prove'."

.PHONY: test
test:
	make -C test test

.PHONY: prove
prove:
	make -C test prove

