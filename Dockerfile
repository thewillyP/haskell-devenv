FROM debian:bookworm-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends locales-all && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8


ENV DEBIAN_FRONTEND=noninteractive \
    LLVM_VERSION=15

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
      pinentry-curses \
      gcc \
      g++ \
      make \
      sudo \
      nano \
      zip \
      unzip \
      htop \
      lsof \
      strace \
      man \
      less \
      procps \
      lsb-release \
      xz-utils \
      zlib1g-dev \
      netbase \
      dpkg-dev \
      sqlite3 \
      libpq-dev \
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
      pkg-config \
      # GUI & VNC
      xfce4 \
      xfce4-goodies \
      dbus-x11 \
      tigervnc-standalone-server \
      tigervnc-common \
      tigervnc-tools \
      openssh-server \
      pandoc \
      # SDL2 + graphics/audio dev headers
      cmake \
      libsdl2-dev \
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

RUN gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys A6310ACC4672475C && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig && \
    gpg --verify awscliv2.sig awscliv2.zip && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip awscliv2.sig aws

RUN curl -fsSL "https://github.com/99designs/aws-vault/releases/download/v7.2.0/aws-vault-linux-amd64" -o /usr/local/bin/aws-vault \
    && chmod +x /usr/local/bin/aws-vault

FROM base AS sdl2

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


FROM sdl2 AS setup 

SHELL ["/bin/bash", "-c"]
RUN mkdir /var/run/sshd
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

FROM setup AS tooling

ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=yes \
    BOOTSTRAP_HASKELL_NO_UPGRADE=yes \
    BOOTSTRAP_HASKELL_MINIMAL=yes \
    GHCUP_INSTALL_BASE_PREFIX=/opt

# Install GHCup to /opt/ghcup
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# Set PATH to include GHCup and Cabal binaries
ENV PATH="/opt/.ghcup/bin:/opt/.cabal/bin:$PATH"

# Install GHC, Cabal, Stack, and HLS
ARG GHC_VERSION="9.8.4"
RUN ghcup install ghc "${GHC_VERSION}" --set
RUN ghcup install cabal recommended --set
RUN ghcup install stack recommended --set
RUN ghcup install hls recommended --set
RUN cabal update

RUN ln -s /opt/.ghcup/bin/* /usr/local/bin/ && \
    ln -s /opt/.cabal/bin/* /usr/local/bin/

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
