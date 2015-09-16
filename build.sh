#! /bin/sh -x
#
# NO FANCY STUFF HERE!
# We use plain shellscript like real men do!

UPSTREAM_DIR=/var/www/dl.ffks.de/htdocs/images
RELEASE=v2015.1.x

cd $(dirname $(which $0))

build_images() {
	local gluon_branch= version=
	[ "$1" ] && gluon_branch="GLUON_BRANCH=$1"
	[ "$2" ] && release="GLUON_RELEASE=$2"
	make V=s update && \
	make V=s clean && \
	make V=s $gluon_branch $release
}

sign_images() {
	local gluon_branch="GLUON_BRANCH=$1" branch=$1 sign_key=$2
	make manifest $gluon_branch && \
	contrib/sign.sh "$sign_key" "images/sysupgrade/${branch}.manifest"
}

publish_images() {
	local branch=$1
	mkdir -p ${UPSTREAM_DIR}/${branch} && \
	cp -r images ${UPSTREAM_DIR}/${branch}.new && \
	mv ${UPSTREAM_DIR}/${branch} ${UPSTREAM_DIR}/${branch}.old && \
	mv ${UPSTREAM_DIR}/${branch}.new ${UPSTREAM_DIR}/${branch} && \
	rm -r ${UPSTREAM_DIR}/${branch}.old
}

die() {
	echo $@ >&2
	exit 1
}

mk_version() {
	local timestamp= version= yesterday= extraversion=
	timestamp=$(git show -s --format=%ci HEAD)
	version=$(TZ='Europe/Berlin' date --date "$timestamp" '+%Y.%m.%d')

	yesterday=$(date -d "`git show -s --format=%ci HEAD` - 1 day" +"%F")
	extraversion=$(git rev-list --since $yesterday HEAD --count)
	extraversion=`expr $extraversion - 1`
	if [ $extraversion -ne 0 ]; then
		version=${version}.${extraversion}
	fi
	echo "$version"
}

branch=`git rev-parse --abbrev-ref HEAD`
version=$(mk_version)
if [ "$branch" = master ]; then
	branch=
fi

cd ..

# check if the release is right:
[ "$(git rev-parse --abbrev-ref HEAD)" = "$RELEASE" ] || die "We're building on $RELEASE."

build_images $branch $version || die "Building images failed"
if [ "$branch" -a "$1" ]; then
	sign_images $branch $1 || die "Signing manifest failed"
	publish_images $branch || die "Publishing images failed"
else
	echo "Warning: Images not signed/published" >&2
fi
