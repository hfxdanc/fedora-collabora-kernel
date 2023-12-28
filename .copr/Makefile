srpm:
	cp SOURCES/* $(shell echo '%{_sourcedir}' | rpmspec --shell 2>/dev/null | grep -vE '^>')
	spectool -g -R SPECS/kernel.spec
	rpmbuild -v -bs SPECS/kernel.spec
