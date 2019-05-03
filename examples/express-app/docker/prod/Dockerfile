FROM node:10-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && mkdir /app 

WORKDIR /app

COPY package.json .
COPY src src

RUN npm install \
    && npm audit fix

CMD ["node", "src/main.js"]
