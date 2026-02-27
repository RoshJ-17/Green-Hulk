FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev) so @nestjs/cli is available for build
RUN npm install

# Copy source code
COPY . .

# Build the NestJS application
RUN npm run build

# Verify dist/main.js was created — fails early if build didn't work
RUN test -f dist/main.js || (echo "ERROR: dist/main.js not found! Build failed." && exit 1)

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
