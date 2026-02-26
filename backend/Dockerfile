FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
# NOTE: 'npm ci' requires a package-lock.json — using 'npm install --omit=dev' instead.
# Long-term fix: commit a package-lock.json to your repo and switch back to 'npm ci'.
RUN npm install --omit=dev

# Copy source code
COPY . .

# Build application
RUN npm run build

# Create directories for assets and data
RUN mkdir -p assets/model data

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Start application
CMD ["node", "dist/main"]
