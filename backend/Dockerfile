# ── Stage 1: Build ──────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./
COPY tsconfig*.json ./

RUN printf '{"$schema":"https://json.schemastore.org/nest-cli","collection":"@nestjs/schematics","sourceRoot":"src","compilerOptions":{"deleteOutDir":false,"webpack":false,"tsConfigPath":"tsconfig.build.json"}}' > nest-cli.json

RUN npm install

COPY src ./src

RUN ./node_modules/.bin/nest build

RUN test -f dist/main.js && echo "BUILD OK: dist/main.js exists" || (echo "BUILD FAILED: dist/main.js missing" && exit 1)

# ── Stage 2: Production ─────────────────────────
FROM node:18-alpine AS production

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/dist ./dist
COPY tsconfig*.json ./

RUN mkdir -p assets/model data public

# CI places the Flutter web build at backend/frontend-web before docker build.
# This copies it into the image. No-op if folder is absent (local dev).
COPY frontend-web/ ./public/

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
