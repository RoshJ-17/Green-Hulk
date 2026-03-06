# ── Stage 1: Build Flutter Web ──────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /frontend

COPY frontend/ .

RUN flutter pub get && \
    flutter build web --release \
      --dart-define=ENVIRONMENT=production \
      --dart-define=BACKEND_URL=https://green-hulk-production.up.railway.app \
      --base-href /

# ── Stage 2: Build NestJS Backend ───────────────
FROM node:18-alpine AS backend-builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY backend/package*.json ./
COPY backend/tsconfig*.json ./

RUN printf '{"$schema":"https://json.schemastore.org/nest-cli","collection":"@nestjs/schematics","sourceRoot":"src","compilerOptions":{"deleteOutDir":false,"webpack":false,"tsConfigPath":"tsconfig.build.json"}}' > nest-cli.json

RUN npm install

COPY backend/src ./src

RUN ./node_modules/.bin/nest build

RUN test -f dist/main.js && echo "BUILD OK" || (echo "BUILD FAILED" && exit 1)

# ── Stage 3: Production ──────────────────────────
FROM node:18-alpine AS production

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY backend/package*.json ./
RUN npm install --omit=dev

COPY --from=backend-builder /app/dist ./dist
COPY backend/tsconfig*.json ./

RUN mkdir -p assets/model data public

# Copy Flutter web build from stage 1
COPY --from=flutter-builder /frontend/build/web ./public

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
