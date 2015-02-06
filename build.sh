#! /bin/sh -x
#
# NO FANCY STUFF HERE!
# We use plain shellscript like real men do!

UPSTREAM_DIR=/var/www/dl.ffks.de/htdocs/images
RELEASE=2014.4.x

build_images() {
	local gluon_branch=
	[ "$1" ] && gluon_branch="GLUON_BRANCH=$1"
	make update && \
	make clean && \
	make $gluon_branch
}

sign_images() {
	local gluon_branch="GLUON_BRANCH=$1" sign_key=$2
	make manifest $gluon_branch && \
	contrib/sign.sh "$sign_key" "images/sysupgrade/${gluon_branch}.manifest"
}

publish_images() {
	local branch=$1
	cp -r images ${UPSTREAM_DIR}/${branch}.new && \
	mv ${UPSTREAM_DIR}/${branch} ${UPSTREAM_DIR}/${branch}.old && \
	mv ${UPSTREAM_DIR}/${branch}.new ${UPSTREAM_DIR}/${branch} && \
	rm ${UPSTREAM_DIR}/${branch}.old
}

die() {
	echo $@ >&2
	exit 1
}

cd $(dirname $(which $0))
branch=`git rev-parse --abbrev-ref HEAD`
if [ "$branch" = master ]; then
	branch=
fi

cd ..

# check if the release is right:
[ "$(git rev-parse --abbrev-ref HEAD)" = "$RELEASE" ] || die "We're building on $RELEASE."

build_images $branch || die "Building images failed"
if [ "$branch" ]; then
	sign_images $branch $2 || die "Signing manifest failed"
	publish_images $branch || die "Publishing images failed"
fi
