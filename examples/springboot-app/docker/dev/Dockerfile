FROM maven:3-jdk-8-alpine

RUN apk update && \
    apk upgrade && \
    apk add xmlstarlet && \
	mkdir /app

WORKDIR /app

COPY pom.xml .
COPY scripts scripts
COPY src src

RUN mvn package 

CMD ["mvn", "spring-boot:run"]
