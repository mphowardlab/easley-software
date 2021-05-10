#!/bin/bash

# load intel first in case packages use tbb
module load intel/2021.1
module load python/3.8.6

# compilers
module load gcc/8.4.0
module load mpich/3.3.2
module load cmake/3.19.1

package=python
version=2021Apr
azplugins=0.10.1
fieldkit=master
hoomd=2.9.6

# build info
user=$(whoami)
today=$(date "+%Y-%m-%d")
build=$SCRATCH/$package
install=$GROUP/software/install/$package/$version
module=$GROUP/software/modulefiles/$package

# build hoomd
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

# install base python stuff from pip first
mkdir -p $build && \
sed -e "s|<<VERSION>>|${version}|g" -e "s|<<USER>>|${user}|g" -e "s|<<INSTALL>>|${install}|g" -e "s|<<DATE>>|${today}|g" modulefile > $build/modulefile && \
python3 -m venv $install && \
source $install/bin/activate && \
pip3 install --upgrade pip && \
pip3 install -r requirements.txt

# this is the sitepackages directory where packages will get installed
# we use it to check if we've already built things that take a long time to install
sitepackages=$(python3 -c "import site; print(site.getsitepackages()[0])")

# install fieldkit
if [ ! -d "$sitepackages/fieldkit" ]
then
    mkdir -p $build/fieldkit && \
    cd $build/fieldkit && \
    curl -sSLO https://github.com/mphoward/fieldkit/archive/refs/heads/${fieldkit}.zip && \
    unzip ${fieldkit}.zip && \
    pip3 install -r fieldkit-${fieldkit}/requirements.txt && \
    cd fieldkit-${fieldkit} && \
    python3 setup.py install
fi

# build hoomd
if [ ! -d "$sitepackages/hoomd" ]
then
    mkdir -p $build/hoomd && \
    cd $build/hoomd && \
    curl -sSLO https://github.com/glotzerlab/hoomd-blue/releases/download/v${hoomd}/hoomd-v${hoomd}.tar.gz && \
    tar -xzf hoomd-v${hoomd}.tar.gz && \
    cd hoomd-v${hoomd} && \
    rm hoomd/example_plugin && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$sitepackages \
        -DCMAKE_CXX_FLAGS=-march=native \
        -DCMAKE_C_FLAGS=-march=native \
        -DENABLE_CUDA=OFF \
        -DENABLE_MPI=ON \
        -DSINGLE_PRECISION=OFF \
        -DBUILD_CGCMM=OFF \
        -DBUILD_DEM=OFF \
        -DBUILD_DEPRECATED=OFF \
        -DBUILD_HPMC=OFF \
        -DBUILD_JIT=OFF \
        -DBUILD_METAL=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_VALIDATION=OFF && \
    make install -j 4
fi

# build azplugins
if [ ! -d "$sitepackages/azplugins" ]
then
    mkdir -p $build/azplugins && \
    cd $build/azplugins && \
    curl -sSLO https://github.com/mphowardlab/azplugins/archive/refs/tags/v${azplugins}.tar.gz && \
    tar -xzf v${azplugins}.tar.gz && \
    cd azplugins-${azplugins} && \
    mkdir build && \
    cd build && \
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=$sitepackages \
        -DCMAKE_CXX_FLAGS=-march=native \
        -DCMAKE_C_FLAGS=-march=native \
        -DBUILD_TESTING=OFF && \
    make install -j 4
fi

mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
