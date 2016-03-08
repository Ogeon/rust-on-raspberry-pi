FROM debian:jessie

ARG PI_TOOLS_GIT_REF=master
ARG RUST_GIT_REF

# install debian dependencies before we lose root privileges
RUN apt-get update \
&& apt-get install -y git build-essential file wget python libjemalloc1 llvm;

# create & get cross user and drop root privileges
#
# On OS X, the user needs to have uid set to 1000
# in order to access files from the shared volumes.
# https://medium.com/@brentkearney/docker-on-mac-os-x-9793ac024e94
RUN groupadd --system cross \
&& useradd --create-home --system --gid cross --uid 1000 cross;
USER cross
ENV HOME=/home/cross \
URL_GIT_RUST=https://github.com/rust-lang/rust.git \
URL_GIT_PI_TOOLS=https://github.com/raspberrypi/tools.git \
URL_CARGO_ARCHIVE_64=https://static.rust-lang.org/cargo-dist/cargo-nightly-x86_64-unknown-linux-gnu.tar.gz \
URL_CARGO_ARCHIVE_32=https://static.rust-lang.org/cargo-dist/cargo-nightly-i686-unknown-linux-gnu.tar.gz

ENV TOOLCHAIN_64=$HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin \
TOOLCHAIN_32=$HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin

# install pi tools
RUN if [ $PI_TOOLS_GIT_REF = master ]; \
then git clone --depth 1 $URL_GIT_PI_TOOLS $HOME/pi-tools; \
else \
  git clone $URL_GIT_PI_TOOLS $HOME/pi-tools \
  && cd $HOME/pi-tools \
  && git reset --hard $PI_TOOLS_GIT_REF; \
fi
COPY bin/gcc-sysroot $HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin/gcc-sysroot
COPY bin/gcc-sysroot $HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin/gcc-sysroot

# install rust (default release: latest stable)
RUN git clone $URL_GIT_RUST $HOME/rust; \
cd $HOME/rust; \
DEFAULT_RUST_GIT_REF=$(git tag --list | grep "^[0-9]\+\.[0-9]\+\.[0-9]\+$" | sort -V | tail --lines 1); \
RUST_GIT_REF=${RUST_GIT_REF:-$DEFAULT_RUST_GIT_REF}; \
git reset --hard $RUST_GIT_REF; \

export TOOLCHAIN=$TOOLCHAIN_32 && [ $(uname -m) = 'x86_64' ] && export TOOLCHAIN=$TOOLCHAIN_64; \
export PATH=$TOOLCHAIN:$PATH; \

./configure --target=arm-unknown-linux-gnueabihf --prefix=$HOME/pi-rust \
&& make -j4 \
&& make install;

# install cargo
RUN URL_CARGO_ARCHIVE=$URL_CARGO_ARCHIVE_32 && [ $(uname -m) = 'x86_64' ] && URL_CARGO_ARCHIVE=$URL_CARGO_ARCHIVE_64; \
wget -qO- $URL_CARGO_ARCHIVE | tar xvz -C $HOME; \
mkdir $HOME/.cargo;
COPY conf/cargo-config $HOME/.cargo/config

COPY bin $HOME/bin
ENV PATH=$HOME/bin:$PATH

ENTRYPOINT ["run.sh"]
CMD ["help"]
