# ── Stage 1: Build ──────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./
COPY tsconfig*.json ./

# Write nest-cli.json pointing to tsconfig.build.json
RUN printf '{"$schema":"https://json.schemastore.org/nest-cli","collection":"@nestjs/schematics","sourceRoot":"src","compilerOptions":{"deleteOutDir":false,"webpack":false,"tsConfigPath":"tsconfig.build.json"}}' > nest-cli.json

RUN npm install

COPY src ./src

# Build TypeScript → JavaScript
RUN ./node_modules/.bin/nest build

# Confirm dist/main.js exists — fail loudly if not
RUN test -f dist/main.js && echo "BUILD OK: dist/main.js exists" || (echo "BUILD FAILED: dist/main.js missing" && ls -la dist/ && exit 1)

# ── Stage 2: Production ─────────────────────────
FROM node:18-alpine AS production

WORKDIR /app

RUN apk add --no-cache python3 make g++

COPY package*.json ./
RUN npm install --omit=dev

# Copy compiled output from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules/tsconfig-paths ./node_modules/tsconfig-paths
COPY tsconfig*.json ./

RUN mkdir -p assets/model data

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
