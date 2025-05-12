FROM haskell:9.8.4 AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    openssh-server \
    apt-utils \
    bash \
    build-essential \
    ca-certificates \
    curl \
    wget \
    git \
    nano \
    zip \
    htop \
    lsof \
    strace \
    man \
    pandoc \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-common \
    # Dependencies for building SDL2
    cmake \
    libx11-dev \
    libxcursor-dev \
    libxi-dev \
    libxrandr-dev \
    libxss-dev \
    libgl1-mesa-dev \
    libasound2-dev \
    libpulse-dev \
    libudev-dev \
    && mkdir -p /usr/local/src \
    && cd /usr/local/src \
    && wget https://www.libsdl.org/release/SDL2-2.30.8.tar.gz \
    && tar -xvzf SDL2-2.30.8.tar.gz \
    && cd SDL2-2.30.8 \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /usr/local/src/SDL2-2.30.8* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS setup

SHELL ["/bin/bash", "-c"]

RUN mkdir /var/run/sshd

COPY .vscode /workspace/.vscode

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

FROM setup AS packages

RUN cabal update && cabal install --minimize-conflict-set haskell-language-server


RUN stack install --resolver lts-23.21 \
  haskell-dap \
  ghci-dap \
  haskell-debug-adapter \
  hlint \
  apply-refact \
  stylish-haskell \
  hoogle \
  ormolu \
  beam-core \ 
  beam-sqlite \
  hspec \
  QuickCheck \
  quickcheck-classes \
  linear \
  sdl2 \  
  vector \  
  transformers \  
  monad-loops \  
  deque \  
  optics \  
  apecs \  
  random \  
  containers \  
  pqueue \  
  template-haskell \  
  extra \  
  mtl \  
  free


ENTRYPOINT ["/entrypoint.sh"]
CMD []