include site.mk

GLUON_BUILD_DIR := gluon-build
GLUON_GIT_URL := https://github.com/freifunk-gluon/gluon

JOBS ?= $(shell cat /proc/cpuinfo | grep processor | wc -l)

all: info build

clean-output:
	rm -rf ${GLUON_BUILD_DIR}/output

clean:
	rm -rf ${GLUON_BUILD_DIR}

info:
	@echo '##########################################'
	@echo '## Building gluon release ${GLUON_RELEASE}	##'
	@echo '##########################################'

update:
ifeq "$(wildcard ${GLUON_BUILD_DIR} )" ""
	git clone ${GLUON_GIT_URL} ${GLUON_BUILD_DIR} -b ${GLUON_RELEASE};
else
	cd ${GLUON_BUILD_DIR}
	git --git-dir=${GLUON_BUILD_DIR}/.git pull
endif

prepare: update
	ln -sfT .. ${GLUON_BUILD_DIR}/site
	${MAKE} -C ${GLUON_BUILD_DIR} update
build: clean-output prepare
	@echo 'starting build...'
	${MAKE} -j ${JOBS} -C ${GLUON_BUILD_DIR} FORCE_UNSAFE_CONFIGURE=1 BROKEN=1
