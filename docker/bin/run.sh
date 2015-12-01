#!/bin/bash
set -e;

printf "*** Extracting target dependencies ***\n";
if [ -d "$HOME/deb-deps" ]; then
	cd $HOME/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot/;

	for i in `find $HOME/deb-deps -name "*.deb" -type f`; do
    	echo "Extracting: $i";
    	#ar p $i data.tar.xz | unxz | tar x;
    	ar p $i data.tar.gz | tar zx;
	done
fi

printf "\n*** Cross compiling project ***\n";
cd $HOME/project;

if [ $(uname -m) == 'x86_64' ]; then
	TOOLCHAIN=$TOOLCHAIN_64;
	CARGO_PATH=$HOME/cargo-nightly-x86_64-unknown-linux-gnu/cargo/bin;
else
	TOOLCHAIN=$TOOLCHAIN_32;
	CARGO_PATH=$HOME/cargo-nightly-i686-unknown-linux-gnu/cargo/bin; 
fi

export PATH=$CARGO_PATH:"$HOME/pi-rust/bin":$TOOLCHAIN:$PATH;
export SYSROOT="$HOME/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot";
#Point rustc to the standard libraries
export LD_LIBRARY_PATH="$HOME/pi-rust/lib":$LD_LIBRARY_PATH;
#Include the cross copilation binaries
export CC="$TOOLCHAIN/gcc-sysroot";
export AR="$TOOLCHAIN/arm-linux-gnueabihf-ar";

flags="--target=arm-unknown-linux-gnueabihf";
cargo clean;
cargo $@ $flags;
