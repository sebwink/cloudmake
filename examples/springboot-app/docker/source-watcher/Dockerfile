FROM docker:18

RUN apk update && \
    apk upgrade && \
	apk add inotify-tools && \
	mkdir /app

WORKDIR /app

COPY entrypoint.sh .

ENTRYPOINT ["./entrypoint.sh"]
