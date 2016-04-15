#Cross Compiling on a Linux Host

These instructions are based on [the rusty-pi guide](https://github.com/npryce/rusty-pi/blob/master/doc/compile-the-compiler.asciidoc),
but with some additions and adaptations for the current build systems.

##Preparing the Tools

The first step is to download the Raspberry Pi toolchain. It's a collection of
binaries and libraries for cross compiling. Begin by installing `git` if it's
not already installed:

```
sudo apt-get install git
```

(replace `apt-get install` with the install command for your favorite package
manager)

and procede by cloning the toolchain repository:

```
git clone https://github.com/raspberrypi/tools.git ~/pi-tools
```

##Compiling the Compiler

The next step is to compile the Rust compiler and standard libraries. The
standard libraries are particularly important, since they have to be compiled
for the ARM platform to make them usable in your program. See Appendix A
for information on how to add more libraries.

start by cloning the Rust repository and `cd` into it:

```
git clone http://github.com/rust-lang/rust.git
cd rust
```

You may want to check out the same revision as your current copy of `rustc` to
keep everything in sync. You can find the revision hash by running `rustc`
with the `-V` flag:

```
$ rustc -V
rustc 1.0.0-nightly (30e1f9a1c 2015-03-14) (built 2015-03-15)
                     ^-------^ This is what you are looking for
```

Copy the hash and use it to reset the repository to the same revision:

```
git reset --hard 30e1f9a1c
```

Alright, finally time to build it. Begin by adding the binary directory from
the Raspberry Pi toolchain to your path. Use the following command to use the
64 bit tools:

```
export PATH=~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:$PATH
```

or use this command for the 32 bit tools:

```
export PATH=~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin:$PATH
```

Configure the compiler to build everything for ARM Linux and set the install
destination to `$HOME/pi-rust`:

```
./configure --target=arm-unknown-linux-gnueabihf --prefix=$HOME/pi-rust
```

And build+install!

```
make -j4 && make install
```

(Change the 4 to your preferred number of parallel build processes)

This is will take a while, so go and grab some coffee or take a walk while
waiting.

Is it done? Great! Now, move on to the next part.

##Pointing Cargo in the Right Direction

We are almost ready to actually build things. You may actually be able to use
`rustc` directly, but we want more, right? We want the convenience of Cargo!
But Cargo doesn't come without demands. It has to know what we are using to
link our program, so let's tell it. Cargo will be looking for [configuration
files](doc.crates.io/config.html) where we can specify what to use when
building ARM programs.

You may already have a directory in your `$HOME` called `.cargo`. Create one,
if you don't have it. Now, create a file called `config`, or edit an existing
one, and add the following lines to associate the target triple
`arm-unknown-linux-gnueabihf` with our cross compilers:

```
[target.arm-unknown-linux-gnueabihf]
ar = "arm-linux-gnueabihf-gcc-ar"
linker = "gcc-sysroot"
```

Wait a minute! What is `gcc-sysroot`? Well, that is a semi ugly hack and we
are going to use it.

The thing is that Cargo has some problems when it comes to cross compiling
while depending on share libraries. These libraries are placed somewhere in
the `sysroot` and `gcc` is using `ld` to link them. The problem is that the
default `sysroot` is where the host libraries are located and those are not
built for ARM. There is currently no good way to tell Cargo to tell `rustc` to
tell `gcc` to tell `ld` to look somewhere else, so we have to do it for them.

The Raspberry Pi toolchain contains a directory with various system
directories filled with common libraries (if you want to add more libraries,
see Appendix A). This is where we want `ld` to look
for things, so we are going to use a simple script to tell `gcc` to tell it
where this directory can be found. Create a file in the binary directory you
added to your `$PATH` before
(`~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin`
if you used the 64 bit tools or
`~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin`
if you prefer the 32 bit tools) and call it `gcc-sysroot`.

Add the following lines in `gcc-sysroot`:

```
#!/bin/bash
arm-linux-gnueabihf-gcc --sysroot=$HOME/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot "$@"
```

This is basically an alias for `arm-linux-gnueabihf-gcc`, but with the
`--sysroot` set to where the libraries are kept. The `"$@"` part is there to
pass all the incoming argument forwards to `arm-linux-gnueabihf-gcc`. Alright,
make the file executable:

```
chmod +x ~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/gcc-sysroot
```

or

```
chmod +x ~/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/gcc-sysroot
```

If your crate requires building C++ code, then you'll need to create a `g++-sysroot` just
like `gcc-sysroot`, substituting `arm-linux-gnueabihf-g++` for `arm-linux-gnueabihf-gcc`
inside.

And you should be done! Or, kind of done. There is one thing left.

##Running Cargo

It would be nice to just be able to run `cargo build` and be done with it, but
the reality is not exactly that nice. Almost, but not exactly. You will have
to add the binaries to your `$PATH` every time you open a new terminal and get
ready for compiling. You may also have to define some other variables to
satisfy some other systems. Sound tedious and boring, right? Well, that's what
we have scripts for.

This repository contains two versions of the same script (`cross32` for 32 bit
and `cross64` for 64 bit). They can be used as a substitute for Cargo, like
this:

```
./cross64 cargo-command path/to/rust path/to/pi/toolchain

Examples:
./cross64 build ~/some-other-rust ~/some-other-pi-tools
./cross64 doc
./cross64 "build --release"
```

The first argument is what you would normally pass to `cargo`. It can be
single commands, like `build` or `doc`, or multiple arguments like `"build
--release"`. Note that the combined commands have to be passed as a single
string. `path/to/rust` and `path/to/pi/toolchain` are optional and should only
be used if you want to use tools from somewhere else than what this guide
recommends.

These scripts will set up the required environment variables and run cargo for
you. All without polluting the external environment. You can include them in
your projects and modify them however you want.

That's it! You should now be ready to cross compile your Raspberry Pi
projects.

Have fun!


# Appendix A: Extending the toolset to support more system dependencies

Let's say your project uses some crate that depends on having openssl
installed on the system. In this case you have to install the package
manually into the ARM toolset.

Get these packages either from the raspberry, or download them online.

We'll assume that you're running Raspbian (i.e. deb files), but it should be
straight forward to adapt the steps to your dist/packages.

If you do `apt-cache show libssl1.0.0` on the raspberry, you'll see this in the
output:

    Filename:    pool/main/o/openssl/libssl1.0.0_1.0.1e-2+rvt+deb7u17_armhf.deb

You should be able to find a match for that under ftp.debian.org/debian/pool, so
the resulting URL in this case is

    http://ftp.debian.org/debian/pool/main/o/openssl/libssl-dev_1.0.1e-2+deb7u17_armhf.deb

If it's not there, see if it is still on the raspberry under
`/var/cache/apt/archive`.

If you still can't find it, try searching for the filename online.

When you have the dependencies downloaded, extract them into the ARM toolchain:

    # cd into the sysroot of the arm toolchain
    cd ~/pi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/arm-bcm2708hardfp-linux-gnueabi/sysroot/

    # move the deb files here and use `ar` to extract the contents:
    ar p libssl1.0.0_1.0.1e-2+rvt+deb7u17_armhf.deb data.tar.gz | tar zx

    # Repeat for any other dependencies you may have..
    ar p libssl-dev_1.0.1e-2+rvt+deb7u17_armhf.deb data.tar.gz | tar zx
    ar p zlib1g_1.2.7.dfsg-13_armhf.deb data.tar.gz | tar zx
    ar p zlib1g-dev_1.2.7.dfsg-13_armhf.deb data.tar.gz | tar zx

Now you're ready to build the project.
