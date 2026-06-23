FROM node:22-alpine

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY . .
RUN npm install typescript@5.6.0 && npm run build && npm prune --omit=dev

EXPOSE 8080
CMD ["node", "dist/server.js"]
