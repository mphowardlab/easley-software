#!/bin/bash

module load gcc/8.4.0
module load mpich/3.3.2
module load cmake/3.19.1
module load fftw/3.3.9

package=lammps
version=29Oct2020
lammps_label=stable

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
curl -sSLO https://github.com/lammps/lammps/archive/refs/tags/${lammps_label}_${version}.tar.gz && \
tar -xzf ${lammps_label}_${version}.tar.gz && \
cd lammps-${lammps_label}_${version} && \
mkdir -p build && \
cd build && \
cmake ../cmake \
    -C ../cmake/presets/most.cmake \
    -C ../cmake/presets/gcc.cmake \
    -DCMAKE_INSTALL_PREFIX=$install \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_MPI=ON \
    -DBUILD_OMP=ON \
    -DOpenMP_gomp_LIBRARY=/tools/gcc-8.4.0/lib64/libgomp.so \
    -DBUILD_SHARED_LIBS=OFF \
    -DLAMMPS_EXCEPTIONS=OFF \
    -DPKG_PYTHON=OFF \
    -DFFT=FFTW3 \
    -DCMAKE_PREFIX_PATH=$GROUP/software/install/fftw/3.3.9/lib64 \
    && \
make install -j 4 && \
mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
