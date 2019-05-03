FROM node:10-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && mkdir /app \
    && npm install --global nodemon

WORKDIR /app

COPY package.json .
COPY src src

RUN npm install 

CMD ["nodemon", "src/main.js"]
