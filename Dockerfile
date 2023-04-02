# build stage for compiling odamex
FROM ubuntu:20.04 AS build
WORKDIR /build
ENV DEBIAN_FRONTEND=noninteractive
RUN true \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends tzdata\
    && apt-get install -y -qq --no-install-recommends \
        ca-certificates \
        git \
        clang \
        cmake \
        make \
        deutex \
        libssl-dev \
        libsdl2-dev libsdl2-mixer-dev \
        libpng-dev libpng++-dev \
        libcurl4-openssl-dev libcurlpp-dev \
        patch \
        > /dev/null

# So we can use bash arrays (default /bin/sh doesn't support this)
SHELL ["/bin/bash","-c"]

ARG REPO_URL
ARG REPO_TAG

# Clone the repository
RUN true \
    && test -n "$REPO_URL" && test -n "$REPO_TAG" \
    && git clone --depth 1 --branch "$REPO_TAG" "$REPO_URL" odamex

WORKDIR /build/odamex

# Apply Manual Patches (make sure they are UTF-8 encoded)
COPY docker-files/patches /patches
RUN true \
    && shopt -s nullglob \
    && for p in /patches/*.patch; do patch -p1 < $p; done

# Update submodules
RUN true \
    && git submodule init \
    && git submodule update

# Setup Build
RUN true \
    && mkdir build

# Build the Wad
# WORKDIR /build/odamex/wad
# RUN true \
#     && /usr/games/deutex -rgb 0 255 255 -doom2 bootstrap -build wadinfo.txt ../odamex.wad

# Build Odamex
WORKDIR /build/odamex/build
RUN true \
    && cmake -W no-dev \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_CXX_COMPILER=clang++ \
        -D CMAKE_C_COMPILER=clang \
        -D CMAKE_C_FLAGS="-w" \
        -D CMAKE_CXX_FLAGS="-w" \
        .. \
    && cmake --build . --target odasrv

# Install Odamex
ENV INSTALL_DIR=/usr/local/games/odamex
COPY docker-files/odamex-server.sh /usr/local/bin/odamex-server
RUN true \
    && COPY_PATTERNS=(\
        server/odamex.wad \
        server/odasrv \
    ) \
    && mkdir -p "$INSTALL_DIR" \
    && cp "${COPY_PATTERNS[@]}" "$INSTALL_DIR/" \
    && bin_path=/usr/local/bin/odamex-server \
    && chmod a+x $bin_path \
    && sed -i "s|INSTALL_DIR|${INSTALL_DIR}|" $bin_path

# Final stage for running the odamex server
# Copies over everything /usr/local
FROM ubuntu:20.04
COPY --from=build /usr/local /usr/local/
RUN true \
    && apt-get update -qq \
    && apt-get install -qq --no-install-recommends \
        tini \
        libssl1.1 \
        libsdl2-2.0-0 \
        libsdl2-mixer-2.0-0 \
        libpng16-16 \
        libcurl4 \
        gosu \
        > /dev/null \
    && rm -rf /var/lib/apt/lists/*

# Environment variables used to map host UID/GID to internal
# user used to launch odamex-server
ENV ODAMEX_UID= \
    ODAMEX_GID=

COPY ./docker-files/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "tini", "--", "/entrypoint.sh" ]
