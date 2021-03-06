# Based from https://github.com/paritytech/substrate/blob/master/.maintain/Dockerfile

FROM phusion/baseimage:0.10.2 as builder
LABEL maintainer="hello@acala.network"
LABEL description="This is the build stage for Acala Node. Here we create the binary."

ENV DEBIAN_FRONTEND=noninteractive

ARG PROFILE=release
WORKDIR /acala

COPY . /acala

RUN apt-get update && \
	apt-get dist-upgrade -y -o Dpkg::Options::="--force-confold" && \
	apt-get install -y cmake cmake pkg-config libssl-dev git clang libclang-dev

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y && \
	export PATH="$PATH:$HOME/.cargo/bin" && \
	rustup default nightly-2020-11-16 && \
	rustup target add wasm32-unknown-unknown --toolchain nightly-2020-11-16 && \
	cargo build "--$PROFILE" --manifest-path bin/acala-dev/Cargo.toml --features with-ethereum-compatibility

# ===== SECOND STAGE ======

FROM phusion/baseimage:0.10.2
LABEL maintainer="hello@acala.network"
LABEL description="This is the 2nd stage: a very small image where we copy the Acala Node binary."
ARG PROFILE=release

RUN mv /usr/share/ca* /tmp && \
	rm -rf /usr/share/*  && \
	mv /tmp/ca-certificates /usr/share/ && \
	useradd -m -u 1000 -U -s /bin/sh -d /acala acala

COPY --from=builder /acala/target/$PROFILE/acala-dev /usr/local/bin

# checks
RUN ldd /usr/local/bin/acala-dev && \
	/usr/local/bin/acala-dev --version

# Shrinking
RUN rm -rf /usr/lib/python* && \
	rm -rf /usr/bin /usr/sbin /usr/share/man

USER acala
EXPOSE 30333 9933 9944

RUN mkdir /acala/data

VOLUME ["/acala/data"]

ENTRYPOINT ["/usr/local/bin/acala-dev"]
