# Use Node.js Alpine for smaller image size and better security
FROM node:18-alpine

# Install system dependencies for native modules and health checks
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    wget \
    && rm -rf /var/cache/apk/*

# Set the working directory
WORKDIR /usr/src/app

# Copy dependency files first for better layer caching
COPY package*.json ./

# Install npm dependencies (including devDependencies for build)
RUN npm ci --silent && \
    npm cache clean --force

# Copy application files
COPY . .

# Build the application
RUN npm run build

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S aitown -u 1001

# Change ownership of the app directory
RUN chown -R aitown:nodejs /usr/src/app
USER aitown

# Expose the port
EXPOSE 5173

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:5173/ || exit 1

# Use production-optimized command
CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "5173"]
