# Stage 1: Base image for common dependencies
FROM ubuntu:latest AS base

USER root

RUN \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update \
    && apt-get install -y wget ca-certificates tzdata libpq-dev curl procps libuv1 libuv1-dev libssl-dev \
    && wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb \
    && dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb \
    && wget http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb \
    && dpkg -i multiarch-support_2.27-3ubuntu1_amd64.deb \
    && wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver_2.15.3-1_amd64.deb \
    && wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver-dev_2.15.3-1_amd64.deb \
    && dpkg -i cassandra-cpp-driver_2.15.3-1_amd64.deb cassandra-cpp-driver-dev_2.15.3-1_amd64.deb \
    && ln -s /usr/lib/x86_64-linux-gnu/libcassandra.so.2 /usr/lib/libcassandra.so		

# Stage 2: Planner image
FROM lukemathwalker/cargo-chef:latest-rust-1.78.0 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

# # Stage 3: Builder image
FROM chef AS cooking
WORKDIR /app

ENV CARGO_INCREMENTAL=0
ENV CARGO_NET_RETRY=2
ENV RUSTUP_MAX_RETRIES=2
ENV RUST_BACKTRACE="short"
ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL="sparse"
ENV RUSTC_WRAPPER=sccache SCCACHE_DIR=/sccache

RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \ 
    cargo install sccache --locked

COPY --from=base / /

COPY . .
COPY --from=planner /app/recipe.json recipe.json
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
		cargo chef cook --recipe-path recipe.json

COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/usr/local/cargo/git \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
		cargo build

# Stage 4: Final image
FROM base

ARG BIN_DIR=/local/bin
ARG BINARY=ha-setup

RUN mkdir -p ${BIN_DIR}

COPY --from=cooking /app/target/debug/${BINARY} ${BIN_DIR}/${BINARY}

WORKDIR ${BIN_DIR}

CMD ./ha-setup
