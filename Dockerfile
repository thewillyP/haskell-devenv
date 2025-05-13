FROM debian:bookworm-slim

ENV LANG=C.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
        # Common Haskell + Stack dependencies
        dpkg-dev \
        gcc \
        gnupg \
        g++ \
        libc6-dev \
        libffi-dev \
        libgmp-dev \
        libnuma-dev \
        libtinfo-dev \
        make \
        netbase \
        xz-utils \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/*

# Install SDL2
RUN mkdir -p /usr/local/src && cd /usr/local/src && \
    wget https://www.libsdl.org/release/SDL2-2.30.8.tar.gz && \
    tar -xvzf SDL2-2.30.8.tar.gz && \
    cd SDL2-2.30.8 && \
    mkdir build && cd build && \
    cmake .. && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /usr/local/src/SDL2-2.30.8* && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ghcup
RUN mkdir -p /root/.ghcup/bin && \
    curl -LJ "https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup" -o "/root/.ghcup/bin/ghcup" && \
    chmod +x "/root/.ghcup/bin/ghcup"

# Add ghcup and cabal to PATH
ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:$PATH"

# Install GHC, Cabal, Stack, and HLS
ARG GHC_VERSION="9.8.4"
RUN ghcup install ghc "${GHC_VERSION}" --set
RUN ghcup install cabal recommended --set
RUN ghcup install stack recommended --set
RUN ghcup install hls recommended --set
RUN cabal update

# Copy VSCode settings and entrypoint
COPY entrypoint.sh /entrypoint.sh
COPY .vscode /workspace/.vscode
RUN chmod +x /entrypoint.sh

# Install Haskell packages with Stack
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
