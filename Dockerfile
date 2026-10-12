FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache iputils

COPY package*.json ./

RUN npm install --omit=dev

COPY server.js .

ENV PORT=3000

EXPOSE 3000

CMD ["node", "server.js"]
