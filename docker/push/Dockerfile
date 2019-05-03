FROM docker:latest

RUN apk update && \
    apk upgrade && \
	apk add bash

COPY push.sh /push.sh

ENTRYPOINT ["/push.sh"]
