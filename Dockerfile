FROM node:20-slim

WORKDIR /app

# Install build essentials for native modules
RUN apt-get update && apt-get install -y python3 make g++ git curl sqlite3 && rm -rf /var/lib/apt/lists/* || true

# Disable proxy for npm
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
ENV http_proxy=""
ENV https_proxy=""
ENV NO_PROXY="*"

# Configure npm
RUN npm config set registry https://registry.npmjs.org/ && \
    npm config set fetch-timeout 120000 && \
    npm config set fetch-retries 3

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Install rolldown binding for Linux
RUN npm install @rolldown/binding-linux-x64-gnu || true

# Install OpenClaw globally
RUN npm install -g openclaw@latest || true

# Copy source code
COPY . ./

# Build TypeScript
RUN npm run build

CMD ["npm", "run", "dev"]