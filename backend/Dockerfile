FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies including dev (needed for nest CLI)
RUN npm install

# Copy source code
COPY . .

# Clear any cached build artifacts and build fresh
RUN rm -rf dist && npm run build

# List dist to debug what was created
RUN ls -la dist/ || echo "dist folder is empty or missing"

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start application
CMD ["node", "dist/main"]
