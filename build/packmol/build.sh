#!/bin/bash

module load gcc/8.4.0

package=packmol
version=20.12.0

# build info
user=$(whoami)
today=$(date "+%Y-%m-%d")
build=$SCRATCH/$package
install=$GROUP/software/install/$package/$version
module=$GROUP/software/modulefiles/$package

if [ -d "$build" ]
then
    echo "Build directory $build already exists."
    exit 1
fi

if [ -d "$install" ]
then
    echo "${package} ${version} already installed at ${install}."
    exit 1
fi

mkdir -p $build && \
sed -e "s|<<VERSION>>|${version}|g" -e "s|<<USER>>|${user}|g" -e "s|<<INSTALL>>|${install}|g" -e "s|<<DATE>>|${today}|g" modulefile > $build/modulefile && \
cd $build && \
curl -sSLO https://github.com/m3g/packmol/archive/refs/tags/v${version}.tar.gz
tar -xzf v${version}.tar.gz && \
cd packmol-${version} && \
./configure && \
make && \
mkdir -p $install/bin && \
cp packmol $install/bin && \
cd $build && \
mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
