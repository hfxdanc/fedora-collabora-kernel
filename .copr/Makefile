srpm:
	#cp SOURCES/* $(shell echo '%{_sourcedir}' | rpmspec --shell 2>/dev/null | grep -vE '^>')
	cp SOURCES/* $(outdir)
	spectool -gR --define "_sourcedir $(outdir)" $(spec)
	rpmbuild -v -bs --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)" $(spec)
