FROM rust:1.33.0-slim 

RUN apt-get update && \
    apt-get upgrade -y && \
	cargo install cargo-watch && \
	mkdir /app

WORKDIR /app 

COPY Cargo.toml .
COPY src src

RUN cargo build

CMD ["cargo", "watch", "-x", "run"] 
