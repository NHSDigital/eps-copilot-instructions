.PHONY: install install-node compile lint test
install: install-node install-python install-hooks
install-node:
	echo "Nothing to install"
install-python:
	poetry install
install-hooks: install-python
	poetry run pre-commit install --install-hooks --overwrite
compile:
	echo "Nothing to compile"
lint:
	echo "Nothing to lint"
test:
	echo "Nothing to test"
%:
	@$(MAKE) -f /usr/local/share/eps/Mk/common.mk $@
