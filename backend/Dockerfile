FROM node:18-alpine

WORKDIR /app

# Install build tools for native modules (sqlite3, sharp, bcrypt)
RUN apk add --no-cache python3 make g++

# Copy everything needed
COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Install ALL dependencies including dev
RUN npm install

# Copy source code
COPY . .

# Remove any stale build cache and rebuild
RUN rm -rf dist tsconfig.tsbuildinfo

# Use nest CLI directly with full path
RUN ./node_modules/.bin/nest build --skip-type-check

# Show what was built for debugging
RUN ls -la dist/ && echo "=== dist contents ===" && find dist -name "*.js" | head -10

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
