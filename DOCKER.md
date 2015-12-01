# Cross compiling with Docker
The manual process sets lots of environment variables and writes to various config files and thus kind of pollutes your workstation. Thus it can be difficult to remove or upgrade these files and settings or even repeat that process for different versions of rust on the same machine.

Thats why you can also use Docker in order not only to ease the process necessary for building your cross compiler but also for your workstation to stay clean. 

Basically the steps for cross compiling your project with the help of docker look like:
1. Building a docker image which contains the cross compiler
2. Running a docker container from that image which takes your rust project (and it's platform dependencies) and then cross compiles it

## Prerequisites
* Docker 1.9

## Building the Docker image
```
$ cd docker
$ docker build \
    --build-arg RUST_GIT_REF=<branch/tag/commit> \ # defaults to "1.4.0" (stable)
    --build-arg PI_TOOLS_GIT_REF=<branch/tag/commit> \ # defaults to "master"
    --tag <tag for your docker image> \ # e.g. "rust-nightly-pi-cross"
    .
```

By setting different tags for your Docker image and RUST_GIT_REF you could easily build images for different version of rust and use them as need.

## Cross compiling your project
```
$ docker run \
    --volume <your rust project directory>:/home/cross/project \
    --volume <.deb dependency dir>:/home/cross/deb-deps \ # e.g openssl
    <tag of your previously built docker image> \ # e.g. "rust-nightly-pi-cross"
    <cargo command> # e.g. "build --release"
```

The compiled project can then be found in your target directory .

