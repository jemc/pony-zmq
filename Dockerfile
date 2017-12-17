FROM ponylang/ponyc:release

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "D401AB61 DBE1D0A2" && \
    echo "deb http://dl.bintray.com/pony-language/pony-stable-debian /" | tee -a /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install pony-stable libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /src/main/
WORKDIR /src/main
RUN ponyc --version
RUN stable --version

CMD make all
