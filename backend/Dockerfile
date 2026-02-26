FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including dev) so @nestjs/cli is available for the build step
RUN npm install

# Copy source code
COPY . .

# Build the NestJS application (requires nest CLI from devDependencies)
RUN npm run build

# Remove dev dependencies — keeps the final image lean
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start application
CMD ["node", "dist/main"]
