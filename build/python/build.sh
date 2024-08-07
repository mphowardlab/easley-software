#!/bin/bash

module load gcc/8.4.0

module load mpich/3.3.2
module load cereal/1.3.2

module load fftw/3.3.10
module load lapack/3.9.0
module load eigen/3.4.0

module load python/3.11.1
module load pybind11/2.13.1

module load cmake/3.19.1

package=python
version=2024Aug
hoomd=4.8.2
azplugins=1.0.0
lammps_label=stable
lammps_version=2Aug2023_update3
lammps=${lammps_label}_${lammps_version}
contents="hoomd ${hoomd}, azplugins ${azplugins}, lammps ${lammps_version}"

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
sed -e "s|<<VERSION>>|${version}|g" -e "s|<<USER>>|${user}|g" -e "s|<<INSTALL>>|${install}|g" -e "s|<<DATE>>|${today}|g" -e "s|<<CONTENTS>>|${contents}|g" modulefile > $build/modulefile && \
python3 -m venv $install && \
source $install/bin/activate && \
pip3 install --upgrade pip && \
pip3 install --no-cache-dir -r requirements.txt

# build hoomd
mkdir -p $build/hoomd && \
cd $build/hoomd && \
curl -sSLO https://github.com/glotzerlab/hoomd-blue/releases/download/v${hoomd}/hoomd-${hoomd}.tar.gz && \
tar -xzf hoomd-${hoomd}.tar.gz && \
cd hoomd-${hoomd} && \
rm hoomd/example_plugins && \
mkdir build && \
cd build && \
cmake .. \
    -DBUILD_METAL=OFF \
    -DBUILD_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS=-march=native \
    -DCMAKE_CXX_FLAGS=-march=native \
    -DENABLE_GPU=OFF \
    -DENABLE_LLVM=OFF \
    -DENABLE_MPI=ON \
    -DENABLE_TBB=OFF \
    -DHOOMD_LONGREAL_SIZE=64 \
    -DHOOMD_SHORTREAL_SIZE=64 \
    -Dpybind11_DIR=$GROUP/software/install/pybind11/2.13.1/share/cmake/pybind11 && \
make install -j 4

# build azplugins
mkdir -p $build/azplugins && \
cd $build/azplugins && \
curl -sSLO https://github.com/mphowardlab/azplugins/archive/refs/tags/v${azplugins}.tar.gz && \
tar -xzf v${azplugins}.tar.gz && \
cd azplugins-${azplugins} && \
mkdir build && \
cd build && \
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_FLAGS=-march=native \
    -DCMAKE_CXX_FLAGS=-march=native \
    -DPython_EXECUTABLE=`which python` \
    -Dpybind11_DIR=$GROUP/software/install/pybind11/2.13.1/share/cmake/pybind11 && \
make install -j 4

# build lammps
mkdir -p $build/lammps && \
cd $build/lammps && \
curl -sSLO https://github.com/lammps/lammps/archive/refs/tags/${lammps}.tar.gz && \
tar -xzf ${lammps}.tar.gz && \
cd lammps-${lammps} && \
mkdir -p build && \
cd build && \
cmake ../cmake \
    -C ../cmake/presets/most.cmake \
    -C ../cmake/presets/gcc.cmake \
    -DCMAKE_INSTALL_PREFIX=${VIRTUAL_ENV} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_MPI=ON \
    -DBUILD_OMP=ON \
    -DOpenMP_gomp_LIBRARY=/tools/gcc-8.4.0/lib64/libgomp.so \
    -DBUILD_SHARED_LIBS=ON \
    -DLAMMPS_EXCEPTIONS=ON \
    -DPKG_PYTHON=ON \
    -DPython_ROOT_DIR=$(python3 -c "import sys; print(sys.exec_prefix)") \
    -DPython_FIND_STRATEGY=LOCATION \
    -DFFT=FFTW3 \
    -DCMAKE_PREFIX_PATH=$GROUP/software/install/fftw/3.3.10/lib64 && \
make install -j 4 && \
make install-python

mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
