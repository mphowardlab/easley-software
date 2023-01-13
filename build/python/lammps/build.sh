#!/bin/bash

module load gcc/8.4.0
module load mpich/3.3.2
module load fftw/3.3.9
module load lapack/3.9.0
module load python/3.11.1

module load cmake/3.19.1

package=python/2023Jan
version=lammps
lammps_label=stable
lammps_version=23Jun2022
lammps=${lammps_label}_${lammps_version}
contents="lammps ${lammps_version}"

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

# install base python stuff from pip first
mkdir -p $build && \
sed -e "s|<<VERSION>>|${version}|g" -e "s|<<USER>>|${user}|g" -e "s|<<INSTALL>>|${install}|g" -e "s|<<DATE>>|${today}|g" -e "s|<<CONTENTS>>|${contents}|g" modulefile > $build/modulefile && \
python3 -m venv $install && \
source $install/bin/activate && \
pip3 install --upgrade pip && \
pip3 install --no-cache-dir -r ../requirements.txt

mkdir -p $build && \
sed -e "s|<<VERSION>>|${version}|g" -e "s|<<USER>>|${user}|g" -e "s|<<INSTALL>>|${install}|g" -e "s|<<DATE>>|${today}|g" modulefile > $build/modulefile && \
cd $build && \
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
    -DCMAKE_PREFIX_PATH=$GROUP/software/install/fftw/3.3.9/lib64 && \
make install -j 4

mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
