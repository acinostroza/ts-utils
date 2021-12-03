PREFIX ?= /usr/local

.PHONY: install

install:
	install -Dm755 build-rdevel.sh $(DESTDIR)$(PREFIX)/bin/build-rdevel
	install -Dm755 ts-build-check.sh $(DESTDIR)$(PREFIX)/bin/ts-build-check
	install -Dm755 ts-quick-install.sh $(DESTDIR)$(PREFIX)/bin/ts-quick-install
