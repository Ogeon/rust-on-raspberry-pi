#!/bin/bash
set -e;

printf "*** Extracting target dependencies ***\n";
if [ -d "$HOME/deb-deps" ]; then
	cd $HOME/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot/;

	for i in `find $HOME/deb-deps -name "*.deb" -type f`; do
    	echo "Extracting: $i";
    	ar p $i data.tar.gz | tar zx;
	done
fi

printf "\n*** Cross compiling project ***\n";
cd $HOME/project;

if [ $(uname -m) == 'x86_64' ]; then
	TOOLCHAIN=$TOOLCHAIN_64;
else
	TOOLCHAIN=$TOOLCHAIN_32;
fi

#Include the cross compilation binaries
export PATH=$TOOLCHAIN:$PATH;
export SYSROOT="$HOME/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot";
export CC="$TOOLCHAIN/gcc-sysroot";
export AR="$TOOLCHAIN/arm-linux-gnueabihf-ar";

flags="--target=arm-unknown-linux-gnueabihf";
$HOME/.cargo/bin/cargo clean;
$HOME/.cargo/bin/cargo $@ $flags;
