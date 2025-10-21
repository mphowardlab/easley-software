#!/bin/bash

module load gcc/9.3.0
module load python/3.11.1
module load cmake/3.31.4

package=pybind11
version=2.13.6

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
curl -sSLO https://github.com/pybind/pybind11/archive/refs/tags/v${version}.tar.gz && \
tar -xzf v${version}.tar.gz && \
cd pybind11-${version} && \
mkdir build && \
cd build && \
cmake .. \
    -DCMAKE_INSTALL_PREFIX=$install \
    -DPYBIND11_TEST=OFF && \
make install && \
cd $build && \
mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
