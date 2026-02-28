FROM node:18-alpine

WORKDIR /app

# Install build tools for native modules (sqlite3, sharp, bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./

# Install ALL dependencies including dev (needed for nest CLI)
RUN npm install

# Copy source code
COPY . .

# Build using tsc directly (bypasses incremental cache issues)
RUN ./node_modules/.bin/tsc -p tsconfig.json --outDir dist

# Verify dist/main.js exists
RUN ls dist/main.js && echo "✅ Build successful"

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

# Expose port
EXPOSE 3000

ENV NODE_ENV=production

# Start with tsconfig-paths for path alias resolution
CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
