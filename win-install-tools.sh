#/bin/bash

sudo apt install automake cmake curl git libtool mingw-w64 mingw-w64-tools \
	pkg-config wget

curl -L -O http://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.xz
tar -xf nasm-2.14.02.tar.xz
cd ./nasm-2.14.02
./configure
make
sudo make install

