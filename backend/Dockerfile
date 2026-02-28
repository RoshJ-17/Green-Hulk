FROM node:18-alpine

WORKDIR /app

# Install build tools for native module (sqlite3, sharp, bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package files and configs
COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Install ALL dependencies including dev
RUN npm install

# Copy source code
COPY . .

# Temporarily disable deleteOutDir, build, then restore
RUN node -e "
  const fs = require('fs');
  const cfg = JSON.parse(fs.readFileSync('nest-cli.json'));
  cfg.compilerOptions.deleteOutDir = false;
  fs.writeFileSync('nest-cli.json', JSON.stringify(cfg, null, 2));
"

# Clear old dist and build fresh
RUN rm -rf dist tsconfig.tsbuildinfo

# Build NestJS app
RUN ./node_modules/.bin/nest build

# Show what was built
RUN echo "=== dist contents ===" && find dist -name "*.js" | head -20

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
