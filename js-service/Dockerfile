# syntax=docker/dockerfile:1
FROM node:20-alpine

WORKDIR /app

# сначала зависимости (лучше кешируется)
COPY package*.json ./
RUN npm ci --omit=dev

# потом код
COPY server.js ./

ENV NODE_ENV=production
EXPOSE 3000

CMD ["npm", "start"]
