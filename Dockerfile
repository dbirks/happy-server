# Stage 1: Building the application
FROM node:24-alpine AS builder

# Install build dependencies
RUN apk add --no-cache python3 ffmpeg make g++ gcc musl-dev

WORKDIR /app

# Copy package.json and yarn.lock
COPY package.json yarn.lock ./
COPY ./prisma ./prisma

# Install dependencies
RUN yarn install --frozen-lockfile --ignore-engines

# Copy the rest of the application code
COPY ./tsconfig.json ./tsconfig.json
COPY ./vitest.config.ts ./vitest.config.ts
COPY ./sources ./sources

# Build the application
RUN yarn build

# Stage 2: Runtime
FROM node:24-alpine AS runner

WORKDIR /app

# Install runtime dependencies only
RUN apk add --no-cache python3 ffmpeg

# Create non-root user (Alpine uses addgroup/adduser)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs && \
    chown -R nodejs:nodejs /app

# Set environment to production
ENV NODE_ENV=production

# Copy necessary files from the builder stage
COPY --from=builder --chown=nodejs:nodejs /app/tsconfig.json ./tsconfig.json
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/sources ./sources
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma

# Switch to non-root user
USER nodejs

# Expose the port the app will run on
EXPOSE 3005

# Command to run the application
CMD ["yarn", "start"] 