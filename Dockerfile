FROM debian:bookworm-slim AS base

ENV LANG=C.UTF-8

ENV DEBIAN_FRONTEND=noninteractive \
    LLVM_VERSION=17

RUN VERSION_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d'=' -f2) && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
      software-properties-common \
      wget && \
  # LLVM repository needs to be added twice for it to work (unknown issue)
  add-apt-repository -y -s -n "deb http://apt.llvm.org/${VERSION_CODENAME}/ llvm-toolchain-${VERSION_CODENAME}-${LLVM_VERSION} main" && \
  add-apt-repository -y -s -n "deb http://apt.llvm.org/${VERSION_CODENAME}/ llvm-toolchain-${VERSION_CODENAME}-${LLVM_VERSION} main" && \
  wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
      # Base utilities and dev tools
      apt-utils \
      bash \
      build-essential \
      ca-certificates \
      curl \
      git \
      gnupg \
      gcc \
      g++ \
      make \
      sudo \
      nano \
      zip \
      htop \
      lsof \
      strace \
      man \
      procps \
      lsb-release \
      xz-utils \
      zlib1g-dev \
      netbase \
      dpkg-dev \
      # LLVM components
      clang-$LLVM_VERSION \
      lldb-$LLVM_VERSION \
      lld-$LLVM_VERSION \
      clangd-$LLVM_VERSION \
      # Haskell and system-level deps
      libffi-dev \
      libgmp-dev \
      libnuma-dev \
      libtinfo-dev \
      libc6-dev \
      # Extra runtime deps
      libffi8 \
      libgmp10 \
      libicu-dev \
      libncurses-dev \
      libncurses5 \
      libnuma1 \
      libtinfo5 \
      # GUI & VNC
      xfce4 \
      xfce4-goodies \
      tigervnc-standalone-server \
      tigervnc-common \
      openssh-server \
      pandoc \
      # SDL2 + graphics/audio dev headers
      cmake \
      libx11-dev \
      libxcursor-dev \
      libxi-dev \
      libxrandr-dev \
      libxss-dev \
      libgl1-mesa-dev \
      libasound2-dev \
      libpulse-dev \
      libudev-dev && \
  rm -rf /var/lib/apt/lists/*

FROM base as SDL2

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


FROM SDL2 as setup 

SHELL ["/bin/bash", "-c"]
RUN mkdir /var/run/sshd
COPY entrypoint.sh /entrypoint.sh
COPY .vscode /workspace/.vscode
RUN chmod +x /entrypoint.sh


FROM setup AS tooling

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=yes \
    BOOTSTRAP_HASKELL_NO_UPGRADE=yes

# Install ghcup
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:$PATH"

# Install GHC, Cabal, Stack, and HLS
ARG GHC_VERSION="9.8.4"
RUN ghcup install ghc "${GHC_VERSION}" --set
RUN ghcup install cabal recommended --set
RUN ghcup install stack recommended --set
RUN ghcup install hls recommended --set
RUN cabal update

FROM tooling AS packages

# Set global defaults for stack.
RUN stack config set install-ghc false --global && \
    stack config set system-ghc true --global  

# Install Haskell packages with Stack
RUN stack install --resolver lts-23.21 \
    haskell-dap \
    ghci-dap \
    haskell-debug-adapter \
    hlint \
    apply-refact \
    stylish-haskell \
    hoogle \
    ormolu
    # beam-core \
    # beam-sqlite \
    # hspec \
    # QuickCheck \
    # quickcheck-classes \
    # linear \
    # sdl2 \
    # vector \
    # transformers \
    # monad-loops \
    # deque \
    # optics \
    # apecs \
    # random \
    # containers \
    # pqueue \
    # template-haskell \
    # extra \
    # mtl \
    # free

ENTRYPOINT ["/entrypoint.sh"]
CMD []
