FROM debian:jessie

ARG PI_TOOLS_GIT_REF=master
ARG RUST_VERSION=stable

# update system
RUN apt-get update
RUN apt-get install -y curl git gcc

# config and set variables
#
# On OS X, the user needs to have uid set to 1000
# in order to access files from the shared volumes.
# https://medium.com/@brentkearney/docker-on-mac-os-x-9793ac024e94
RUN groupadd --system cross && useradd --create-home --system --gid cross --uid 1000 cross;
USER cross
ENV HOME=/home/cross
ENV URL_GIT_PI_TOOLS=https://github.com/raspberrypi/tools.git \
    TOOLCHAIN_64=$HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin \
    TOOLCHAIN_32=$HOME/pi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian/bin

# install rustup with raspberry target
RUN curl https://sh.rustup.rs -sSf > $HOME/install_rustup.sh
RUN sh $HOME/install_rustup.sh -y --default-toolchain $RUST_VERSION
RUN $HOME/.cargo/bin/rustup target add arm-unknown-linux-gnueabihf

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

# configure cargo
COPY conf/cargo-config $HOME/.cargo/config

COPY bin $HOME/bin
ENV PATH=$HOME/bin:$PATH
ENTRYPOINT ["run.sh"]

CMD ["help"]
