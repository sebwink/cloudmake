FROM rust:1.33.0-slim as build

RUN apt-get update && \
    apt-get upgrade -y

WORKDIR /app 

COPY Cargo.toml .
COPY src src

RUN cargo build --release && \
    cp /app/target/release/$(cat Cargo.toml | grep "name = " | awk ' { print $3 } ' | sed 's/"//g') /app/app

FROM debian:stretch-slim 

RUN mkdir /app

WORKDIR /app

COPY --from=build /app/app app 

ENTRYPOINT ["./app"]
