# Cross compiling with `Docker`
The manual process sets some environment variables and writes to config files on your host machine. Thus it can be difficult to remember these changes when you want to remove or upgrade the cross compiler or even repeat that process for different versions of rust on the same machine.

Thats why you can also use `Docker` in order not only to ease the process necessary for building your cross compiler but also for your workstation to stay as it is and keep all changes necessary for the cross compiler to work inside an isolated container.

Basically the steps for cross compiling your project with the help of docker look like:

1. Building a `Docker image` which contains the cross compiler
2. Running a `Docker container` from that `Docker image` which takes your `rust` project (and it's platform dependencies) and then cross compiles it

## Prerequisites
* `Docker` 1.9
* Optional: Prefetched platform dependencies (e.g. `openssl`)

### Platform dependencies (optional)
*NOTE*: Only Raspbian `.deb` files are supported currently (but we appreciate patches for other formats)

Let's say your project uses some crate that depends on having openssl
installed on the system. In this case you have download the correspondig Raspbian `.deb` packages
into a folder on your host system and then mount this directory into your `docker` container (See section "Cross compiling your project").

Get these packages either from the raspberry, or download them online.

If you do `apt-cache show libssl1.0.0` on the raspberry, you'll see this in the
output:

    Filename:    pool/main/o/openssl/libssl1.0.0_1.0.1e-2+rvt+deb7u17_armhf.deb

You should be able to find a match for that under ftp.debian.org/debian/pool, so
the resulting URL in this case is

    http://ftp.debian.org/debian/pool/main/o/openssl/libssl-dev_1.0.1e-2+deb7u17_armhf.deb

If it's not there, see if it is still on the raspberry under
`/var/cache/apt/archive`.

If you still can't find it, try searching for the filename online.

## Building the Docker image
```
$ git clone https://github.com/Ogeon/rust-on-raspberry-pi.git
$ cd rust-on-raspberry-pi/docker
$ docker build \
    --build-arg PI_TOOLS_GIT_REF=<branch/tag/commit> \ # defaults to "master"
    --build-arg RUST_VERSION=<rustup version stable/beta/nightly> \ # defaults to "stable"
    --tag <tag for your docker image> \ # e.g. "rust-nightly-pi-cross"
    .
```

By setting different tags for your `Docker image` and `RUST_VERSION` you could easily build images for different version of rust and use them as need.

## Cross compiling your project
If you successfully built the `Docker image` containing the cross compiler, you can finally cross compile your project:
```
$ docker run \
    --volume <path to your rust project directory>:/home/cross/project \
    --volume <path to directory containing the platform dependencies>:/home/cross/deb-deps \ # optional, see section "Platform dependencies"
    <tag of your previously built docker image> \ # e.g. "rust-nightly-pi-cross"
    <cargo command> # e.g. "build --release"
```

The compiled project can then be found in your `target` directory.
