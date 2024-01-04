FROM debian:bullseye-slim

RUN groupadd -g 1000 dev && useradd -u 1000 -g 1000 -m dev # TODO: use ARGS instead
RUN apt update && apt install libegl1 openjdk-17-jdk -y 

RUN echo 'cd /home/dev/$PROJECT' >> /home/dev/.bashrc # starts docker exec in project folder
