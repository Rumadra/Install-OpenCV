#!/bin/bash
# Dan Walkes
# 2014-01-29
# Call this script after configuring variables:
# version - the version of OpenCV to be installed
# downloadfile - the name of the OpenCV download file
# dldir - the download directory (optional, if not specified creates an OpenCV directory in the working dir)
if [[ -z "$version" ]]; then
    echo "Please define version before calling `basename $0` or use a wrapper like opencv_latest.sh"
    exit 1
fi
if [[ -z "$downloadfile" ]]; then
    echo "Please define downloadfile before calling `basename $0` or use a wrapper like opencv_latest.sh"
    exit 1
fi
if [[ -z "$dldir" ]]; then
    dldir=OpenCV
fi
# if ! sudo true; then
#     echo "You must have root privileges to run this script."
#     exit 1
# fi
set -e

echo "--- Installing OpenCV" $version

echo "--- Installing Dependencies"
source dependencies.sh

echo "--- Downloading OpenCV" $version
mkdir -p $dldir
cd $dldir
wget --content-disposition -c -O $downloadfile https://sourceforge.net/projects/opencvlibrary/files/opencv-unix/$version/$downloadfile/download

echo "--- Installing OpenCV" $version
echo $downloadfile | grep ".zip"
if [ $? -eq 0 ]; then
    unzip $downloadfile
else
    tar -xvf $downloadfile
fi
cd opencv-$version

# 環境変数の値を一時的なファイルに保存
echo $version > version.txt
# OpenCVPackaging.cmake内の該当行を置き換え
sed -i 's/set(CPACK_PACKAGE_VERSION_PATCH "${OPENCV_VERSION_PATCH}")/set(OPENCV_VCSVERSION \"'"$(cat version.txt)"'\")/' cmake/OpenCVPackaging.cmake
cat cmake/OpenCVPackaging.cmake
# 一時的なファイルを削除
rm version.txt

sed -i '84i\set(CMAKE_OPENCV_GCC_VERSIONS "4;2;1")' cmake/OpenCVDetectCXXCompiler.cmake
find modules/ -type f -exec sed -i 's|#include <sys/sysctl.h>|//#include <sys/sysctl.h>|g' {} +

mkdir build
cd build
cmake -D CMAKE_BUILD_TYPE=RELEASE -D BUILD_NEW_PYTHON_SUPPORT=ON -D WITH_CUDA=OFF -D WITH_CUFFT=OFF -D WITH_JASPER=OFF -D WITH_FFMPEG=OFF ..
make -j 4
# sudo make install
make install
# sudo sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
sh -c 'echo "/usr/local/lib" > /etc/ld.so.conf.d/opencv.conf'
# sudo ldconfig
ldconfig
echo "OpenCV" $version "ready to be used"
