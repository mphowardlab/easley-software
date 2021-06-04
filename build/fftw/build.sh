#!/bin/bash

module load gcc/8.4.0
module load mpich/3.3.2
module load cmake/3.19.1

package=fftw
version=3.3.9

# build info
user=$(whoami)
today=$(date "+%Y-%m-%d")
build=$SCRATCH/$package
install=$GROUP/software/install/$package/$version
module=$GROUP/software/modulefiles/$package

src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

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
cmake $src/fftw \
    -DCMAKE_INSTALL_PREFIX=$install \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_TESTS=OFF \
    -DENABLE_AVX=ON \
    -DENABLE_AVX2=ON \
    -DENABLE_SSE=ON \
    -DENABLE_SSE2=ON \
    -DENABLE_OPENMP=ON \
    -DENABLE_THREADS=OFF \
    && \
make install -j 4 && \
cd $build && \
mkdir -p $module && \
cp $build/modulefile $module/$version && \
rm -r $build
