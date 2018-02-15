FROM ubuntu:18.04
ENV SRC /home/tester/src
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y && apt-get install -qy \
        locales \
        git \
        wget \
        python \
        python3 \
        python-dev \
        python3-dev \
        python-pip \
        librocksdb-dev \
        libsnappy-dev \
        zlib1g-dev \
        libbz2-dev \
        liblz4-dev \
        && rm -rf /var/lib/apt/lists/*

#NOTE(sileht): really no utf-8 in 2017 !?
ENV LANG en_US.UTF-8
RUN update-locale
RUN locale-gen $LANG

#NOTE(sileht): Upgrade python dev tools
RUN pip install -U pip tox virtualenv

RUN groupadd --gid 2000 tester
RUN useradd --uid 2000 --gid 2000 --create-home --shell /bin/bash tester
USER tester

WORKDIR $SRC
