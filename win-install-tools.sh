#/bin/bash

sudo apt install automake cmake curl git libtool meson mingw-w64 mingw-w64-tools \
     ninja-build pkg-config yasm

curl -L -O https://www.nasm.us/pub/nasm/releasebuilds/2.15.01/nasm-2.15.01.tar.xz
if [ '28a50f80d2f4023e444b113e9ddc57fcec2b2f295a07ce158cf3f18740375831' = "$(sha256sum "nasm-2.15.01.tar.xz" | cut -d " " -f 1)" ]; then
    echo "nasm downloaded successfully and passed hash check"
else
    echo "nasm downloaded successfully and failed hash check"
    exit 1
fi

tar -xf nasm-2.15.01.tar.xz
cd ./nasm-2.15.01
./configure
make
sudo make install
