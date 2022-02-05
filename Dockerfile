#FROM buildpack-deps:buster
#Download base image ubuntu 20.04
FROM ubuntu:20.04

#RUN groupadd --gid 1000 node \
#  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 16.6.0
ENV ASY_VERSION 2.77

RUN apt-get update -y
RUN apt-get install -yq apt-utils
RUN apt-get install curl gpg xz-utils git -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install cmake -y

RUN apt-get install libx11-dev mesa-common-dev libglu1-mesa-dev libxrandr-dev libxi-dev zlib1g-dev -y 
RUN apt-get install texlive-latex-base texlive-latex-recommended texlive-fonts-recommended texlive-latex-extra texinfo -y

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version

ENV YARN_VERSION 1.22.5

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  # smoke test
  && yarn --version


RUN apt-get install -y zlib1g-dev

RUN cp /etc/apt/sources.list /etc/apt/sources.list~

RUN mkdir -p /vectorgraphics/freeglut


RUN sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list

RUN apt-get update -y

RUN apt-get build-dep asymptote -y

RUN apt-get install libcurl4-openssl-dev -y

RUN apt-get install librsvg2-bin -y

RUN apt install dvisvgm -y

RUN groupadd --gid 1000 asymptote \
  && useradd --uid 1000 --gid asymptote --shell /bin/bash --create-home asymptote

RUN set -ex \
    && curl -SLO "https://sourceforge.net/projects/asymptote/files/$ASY_VERSION/asymptote-$ASY_VERSION.src.tgz" \
    && tar -xzf "asymptote-$ASY_VERSION.src.tgz" -C /vectorgraphics --strip-components=1 \
    && rm "asymptote-$ASY_VERSION.src.tgz"

RUN curl -SLO "https://github.com/ivmai/bdwgc/releases/download/v8.0.4/gc-8.0.4.tar.gz"

RUN curl -SLO "http://www.ivmaisoft.com/_bin/atomic_ops/libatomic_ops-7.6.10.tar.gz"

RUN mv gc-8.0.4.tar.gz /vectorgraphics
RUN mv libatomic_ops-7.6.10.tar.gz /vectorgraphics

RUN set -ex \
    && curl -SLO "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs9550/ghostscript-9.55.0-linux-x86_64.tgz" \
    && tar -xzf "ghostscript-9.55.0-linux-x86_64.tgz" -C /vectorgraphics --strip-components=1 \
    && rm "ghostscript-9.55.0-linux-x86_64.tgz" 

ENV ASYMPTOTE_GS /vectorgraphics/gs-9550-linux-x86_64

RUN export ASYMPTOTE_GS=/vectorgraphics/gs-9550-linux-x86_64

RUN set -ex \
    && curl -SLO "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs9550/ghostscript-9.55.0-linux-x86_64.tgz" \
    && tar -xzf "ghostscript-9.55.0-linux-x86_64.tgz" -C /vectorgraphics --strip-components=1 \
    && rm "ghostscript-9.55.0-linux-x86_64.tgz" 

RUN set -ex \
    && curl -SLO "https://prdownloads.sourceforge.net/freeglut/freeglut-3.2.1.tar.gz" \
    && tar -xzf "freeglut-3.2.1.tar.gz" -C /vectorgraphics/freeglut --strip-components=1 \
    && rm "freeglut-3.2.1.tar.gz"


RUN cd /vectorgraphics/freeglut && cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_C_FLAGS=-fcommon . \
    && make \
    && make install

RUN cd /vectorgraphics && ./configure \
    && make clean 

RUN cd /vectorgraphics && make

RUN cd /vectorgraphics && make install 

RUN asy --version

RUN git clone https://github.com/vectorgraphics/asymptote-server.git

RUN mv asymptote-server /home/asymptote \
  && chown -R asymptote /home/asymptote
  
USER 1000

WORKDIR "/home/asymptote/asymptote-server"

RUN npm i
  
RUN sed -i s/80/8110/g server.js \
  && make 
  
EXPOSE 8110

CMD [ "make", "run" ]
