from debian:bullseye-slim

RUN groupadd -g 1000 dev && useradd -u 1000 -g 1000 -m dev # TODO: use ARGS instead

RUN apt update && apt install gawk wget git diffstat unzip \
      texinfo gcc build-essential chrpath socat cpio python3 \
      python3-pip python3-pexpect xz-utils debianutils \
      iputils-ping python3-git python3-jinja2 libegl1-mesa \
      libsdl1.2-dev python3-subunit mesa-common-dev zstd \
      liblz4-tool file locales libacl1 ncurses-base -y
