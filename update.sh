BUILDID=".copr"
REPO="https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree/Packages/k/"
TMPDIR=${TMPDIR:-/tmp}

ODIR=$(mktemp -d)
trap "rmdir $ODIR || echo \"Warning: files uncopied from SRPM\"" EXIT INT

[ -d KERNEL ] && rm -f KERNEL/* || mkdir KERNEL

SRPM=$(wget -O - -q $REPO | awk '
    /href="kernel-[[:digit:]]*\.[[:digit:]]*\..*\.src\.rpm"/ {
        print gensub(/^(.*")(kernel-[[:digit:]]*\.[[:digit:]]*\..*\.src\.rpm)(".*)$/, "\\2", 1)
    }') 

pushd $ODIR && wget -O - $REPO/$SRPM | rpm2cpio - | cpio -id
popd

SOURCE0=$(awk '
    /^%define tarfile_release[[:space:]]/ {
        tarfile_release = $3 
    }
    /Source0:[[:space:]]/ {
        print gensub(/%{tarfile_release}/, tarfile_release, 1, $2)
    }' $ODIR/kernel.spec)

TAG=$(awk '
    /^%define tarfile_release[[:space:]]/ {
        split($3, a, "-")
        print sprintf("v%s-%s", a[1], a[2])
    }' $ODIR/kernel.spec)

TARFILE_RELEASE=$(echo $TAG | sed 's/^v//')

rm $ODIR/$SOURCE0 || exit 1

mv $ODIR/* KERNEL/

for p in *.patch; do cat $p | patch -p1; done

sed -i "s/^# \(define buildid \).*\$/%\1${BUILDID}/" KERNEL/kernel.spec
sed -i "s/^\(%define tarfile_release \).*\$/\1 ${TARFILE_RELEASE}/" KERNEL/kernel.spec
sed -i "s|^\(Source0:\).*\$|\1 https://github.com/torvalds/linux/archive/refs/tags/${TAG}.tar.gz|" KERNEL/kernel.spec

