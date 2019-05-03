FROM rust:1.33.0-slim 

RUN apt-get update && \
    apt-get upgrade -y && \
	rustup default nightly && \ 
    cargo install cargo-watch 

ENV USER app

RUN cargo new --vcs none --bin app && \
	rm app/Cargo.toml

WORKDIR /app 

COPY Cargo.toml .

RUN cargo build

CMD ["cargo", "watch", "-x", "run"] 
