FROM haskell:9.12.2 AS base

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
    tigervnc-tools \
    libsdl2-2.0-0 \
    libsdl2-dev \
    # libsdl2-mixer-2.0-0 \
    # libsdl2-mixer-dev \
    # libsdl2-image-2.0-0 \
    # libsdl2-image-dev \
    # libsdl2-ttf-2.0-0 \
    # libsdl2-ttf-dev \
    # libsdl2-net-2.0-0 \
    # libsdl2-net-dev \
    # libsdl2-gpu-2.0-0 \
    # libsdl2-gpu-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM base AS setup

SHELL ["/bin/bash", "-c"]

RUN mkdir /var/run/sshd

COPY .vscode /workspace/.vscode

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

FROM setup AS packages

RUN stack install --resolver ghc-9.12.2 \
  haskell-dap \
  ghci-dap \
  haskell-debug-adapter \
  hlint \
  apply-refact \
  retrie \
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


RUN cabal update && cabal install --haddock-hoogle --minimize-conflict-set haskell-language-server


FROM packages AS hoogle

# Generate hoogle db
RUN hoogle generate --download --haskell
  

ENTRYPOINT ["/entrypoint.sh"]
CMD []