from debian:bullseye-slim

RUN groupadd -g 1000 dev && useradd -u 1000 -g 1000 -m dev # TODO: use ARGS instead

RUN apt update && apt install git wget flex bison gperf python3 \
      python3-pip python3-venv cmake ninja-build ccache \
      libffi-dev libssl-dev dfu-util libusb-1.0-0 -y
