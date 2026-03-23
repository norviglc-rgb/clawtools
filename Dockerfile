FROM node:20-slim

WORKDIR /app

# Install build essentials for native modules
RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/* || true

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Install rolldown binding for Linux
RUN npm install @rolldown/binding-linux-x64-gnu || true

# Install coverage provider
RUN npm install -D @vitest/coverage-v8 || true

# Copy source code
COPY . ./

# Build TypeScript
RUN npm run build

# Run tests
CMD ["npm", "test"]