BUILDID=".copr"
RAWHIDE=0
REPO="https://dl.fedoraproject.org/pub/fedora/linux/development/rawhide/Everything/source/tree/Packages/k/"
TARFILE_RELEASE="linux-rk3588"
TMPDIR=${TMPDIR:-/tmp}
URL="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux/-/archive/rk3588/${TARFILE_RELEASE}.tar.gz"

ODIR=$(mktemp -d)
trap "rmdir $ODIR || echo \"Warning: files uncopied from SRPM\"" EXIT INT

[ -d SOURCES ] && rm -f SOURCES/* || mkdir SOURCES
[ -d SPECS ] && rm -f SPECS/* || mkdir SPECS

case "$1" in
rawhide)
    RAWHIDE=1
    URL="https://github.com/torvalds/linux/archive/refs/tags"
    ;;
*)
    :
esac

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

rm $ODIR/$SOURCE0 || exit 1

mv $ODIR/kernel.spec SPECS/ || exit 1
mv $ODIR/* SOURCES/

if [ $RAWHIDE -eq 1 ]; then
    TARFILE_RELEASE=$(echo $TAG | sed 's/^v//')
    URL="${URL}/${TAG}.tar.gz"
fi

for p in *.patch; do cat $p | patch -p1; done

sed -i "s/^# \(define buildid \).*\$/%\1${BUILDID}/" SPECS/kernel.spec
sed -i "s/^\(%define tarfile_release \).*\$/\1 ${TARFILE_RELEASE}/" SPECS/kernel.spec
sed -i "s|^\(Source0:\).*\$|\1 ${URL}|" SPECS/kernel.spec

