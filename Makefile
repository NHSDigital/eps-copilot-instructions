.PHONY: install install-node compile lint test
install:
	echo "Nothing to install"
install-node:
	echo "Nothing to install"
compile:
	echo "Nothing to compile"
lint:
	echo "Nothing to lint"
test:
	echo "Nothing to test"
%:
	@$(MAKE) -f /usr/local/share/eps/Mk/common.mk $@
