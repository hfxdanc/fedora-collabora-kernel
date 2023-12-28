srpm:
	dnf -y install rpm-build
	cp * $(outdir)
	spectool -gR --define "_sourcedir $(outdir)" $(spec)
	rpmbuild -v -bs --define "_sourcedir $(outdir)" --define "_srcrpmdir $(outdir)" $(spec)
