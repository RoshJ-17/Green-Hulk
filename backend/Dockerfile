FROM node:18-alpine

WORKDIR /app

# Install build tools needed for native modules (sqlite3, sharp, bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package*.json ./

# Install ALL dependencies including dev (needed for nest CLI to build)
RUN npm install

# Copy source code
COPY . .

# Clear any old build artifacts and build fresh
RUN rm -rf dist && npm run build

# Remove dev dependencies after build (keeps image lean)
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start with tsconfig-paths so path aliases (@ml, @image etc.) resolve correctly
CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
