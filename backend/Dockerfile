FROM node:18-alpine

WORKDIR /app

# Install build tools for native modules (sqlite3, sharp, bcrypt)
RUN apk add --no-cache python3 make g++

# Copy package files and configs
COPY package*.json ./
COPY tsconfig*.json ./

# Write nest-cli.json with deleteOutDir set to false
RUN echo '{"$schema":"https://json.schemastore.org/nest-cli","collection":"@nestjs/schematics","sourceRoot":"src","compilerOptions":{"deleteOutDir":false,"webpack":false,"tsConfigPath":"tsconfig.json"}}' > nest-cli.json

# Install ALL dependencies including dev
RUN npm install

# Copy source code
COPY . .

# Overwrite nest-cli.json again after COPY (in case it got overwritten)
RUN echo '{"$schema":"https://json.schemastore.org/nest-cli","collection":"@nestjs/schematics","sourceRoot":"src","compilerOptions":{"deleteOutDir":false,"webpack":false,"tsConfigPath":"tsconfig.json"}}' > nest-cli.json

# Clear old dist and build fresh
RUN rm -rf dist tsconfig.tsbuildinfo && ./node_modules/.bin/nest build

# Show what was built
RUN find dist -name "*.js" | head -10

# Remove dev dependencies after build
RUN npm prune --omit=dev

# Create directories for assets and data
RUN mkdir -p assets/model data

EXPOSE 3000
ENV NODE_ENV=production

CMD ["node", "-r", "tsconfig-paths/register", "dist/main"]
