# FROM lukemathwalker/cargo-chef:latest-rust-slim-bookworm AS chef
# WORKDIR /app

# FROM chef AS planner
# COPY . .
# RUN cargo chef prepare --recipe-path recipe.json

# FROM chef as builder
# WORKDIR /app

# ENV CARGO_INCREMENTAL=0
# ENV CARGO_NET_RETRY=2
# ENV RUSTUP_MAX_RETRIES=2
# ENV RUST_BACKTRACE="short"
# ENV CARGO_REGISTRIES_CRATES_IO_PROTOCOL="sparse"

# COPY --from=planner /app/recipe.json recipe.json
# RUN cargo chef cook --recipe-path recipe.json

# COPY . .

FROM --platform=linux/amd64 rust:1.78 as builder

USER root

WORKDIR /app

COPY . .

RUN apt-get update \
    && apt-get install -y wget ca-certificates tzdata libpq-dev curl procps libuv1 libuv1-dev libssl-dev

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb \
		&& dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb \
		&& dpkg -i multiarch-support_2.27-3ubuntu1_amd64.deb

RUN wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver_2.15.3-1_amd64.deb \
		&& wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver-dev_2.15.3-1_amd64.deb \
		&& dpkg -i cassandra-cpp-driver_2.15.3-1_amd64.deb cassandra-cpp-driver_2.15.3-1_amd64.deb

ENV RUSTC_LOG=rustc_codegen_ssa::back::link=info

RUN ln -s /usr/lib/x86_64-linux-gnu/libcassandra.so.2 /usr/lib/libcassandra.so

RUN cargo build -v 

FROM --platform=linux/amd64 ubuntu:latest

USER root

RUN apt-get update \
    && apt-get install -y wget ca-certificates tzdata libpq-dev curl procps libuv1 libuv1-dev libssl-dev

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb \
		&& dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb \
		&& dpkg -i multiarch-support_2.27-3ubuntu1_amd64.deb

RUN wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver_2.15.3-1_amd64.deb \
		&& wget https://downloads.datastax.com/cpp-driver/ubuntu/18.04/cassandra/v2.15.3/cassandra-cpp-driver-dev_2.15.3-1_amd64.deb \
		&& dpkg -i cassandra-cpp-driver_2.15.3-1_amd64.deb cassandra-cpp-driver_2.15.3-1_amd64.deb

ARG BIN_DIR=/local/bin
ARG BINARY=ha-setup

RUN mkdir -p ${BIN_DIR}

COPY --from=builder /app/target/debug/${BINARY} ${BIN_DIR}/${BINARY}

WORKDIR ${BIN_DIR}

CMD ["ha-setup"]
