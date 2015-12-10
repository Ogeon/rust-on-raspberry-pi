# Cross Compiling for Raspberry Pi

This guide will show how Rust programs can be cross compiled for the Raspberry
Pi using Cargo. These instructions may or may not work for your particular
system, so you may have to adjust the procedure to fit your configuration.

You can build the cross compiler and your rust project...
* ...by hand on your host machine -- flexible but also more complex ([see MANUAL.md](MANUAL.md))
* ...utilizing a docker image and running inside a docker container -- simple but a little less flexible ([see DOCKER.md](DOCKER.md))

Pull requests with enhancements, corrections or additional instructions are
very much appreciated. Good luck!
