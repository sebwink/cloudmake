FROM maven:3-jdk-8-alpine as build

RUN apk update && \
    apk upgrade && \
	apk add xmlstarlet && \
	mkdir /app

WORKDIR /app

COPY pom.xml .
COPY src src
COPY scripts scripts

RUN mvn package && \
	cp target/$(scripts/get-app-name.sh)-$(scripts/get-app-version.sh).jar app.jar 

FROM openjdk:8-jre-alpine

RUN apk update && \
    apk upgrade  

COPY --from=build /app/app.jar /app.jar

CMD ["java", "-jar", "app.jar"]
