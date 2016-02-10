#! /bin/sh -x

if [ $# -ne 6 ]; then
 echo "use: ./build.sh <branch> <gluon release> <build number> <broken>\
 <gracetime in days> </path/to/signing_key>"
 echo "example: ./build.sh stable v2015.1.2 1 0 5 /etc/sign_key"
 exit 1;
fi


branch="GLUON_BRANCH=$1"
broken="BROKEN=$4"
prio="PRIORITY=$5"
cores=$(nproc)
release="GLUON_RELEASE=$2-$3"

# update repos
git pull 
git checkout $1
cd ..
git pull
git checkout $2

# build targets
make -j$cores update && \
make -j$cores clean GLUON_TARGET=ar71xx-generic && \
make -j$cores clean GLUON_TARGET=ar71xx-nand && \
make -j$cores clean GLUON_TARGET=mpc85xx-generic && \
make -j$cores clean GLUON_TARGET=x86-kvm_guest && \
make -j$cores clean GLUON_TARGET=x86-generic && \
make -j$cores $branch $release $broken $prio GLUON_TARGET=ar71xx-generic && \
make -j$cores $branch $release $broken $prio GLUON_TARGET=ar71xx-nand && \
make -j$cores $branch $release $broken $prio GLUON_TARGET=mpc85xx-generic && \
make -j$cores $branch $release $broken $prio GLUON_TARGET=x86-kvm_guest && \
# include cf-card support for futros
echo "CONFIG_PATA_ATIIXP=y" >> openwrt/target/linux/x86/generic/config-3.10;
make -j$cores $branch $release $broken $prio GLUON_TARGET=x86-generic;
sed -i '/CONFIG_PATA_ATIIXP=y/d' openwrt/target/linux/x86/generic/config-3.10;

# sign images
make manifest $branch && \
contrib/sign.sh $6 "images/sysupgrade/$1.manifest"
