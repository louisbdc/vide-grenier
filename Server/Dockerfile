FROM node:22-alpine

WORKDIR /app

# Toutes les dépendances (dont devDependencies) pour compiler le TypeScript.
COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN npm run build && npm prune --omit=dev

EXPOSE 8080
CMD ["node", "dist/server.js"]
