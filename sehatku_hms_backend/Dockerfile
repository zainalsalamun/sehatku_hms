# Multi-stage Dockerfile for SehatKu HMS Backend (NestJS + Prisma)

# Stage 1: Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Install build dependencies (for bcrypt, etc.)
RUN apk add --no-cache python3 make g++

# Copy package files & install dependencies
COPY package*.json ./
COPY prisma ./prisma/

RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Copy source code and build
COPY . .
RUN npm run build

# Stage 2: Production runner
FROM node:18-alpine AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Copy package files and install production dependencies only
COPY package*.json ./
COPY prisma ./prisma/

RUN apk add --no-cache openssl
RUN npm ci --only=production && npx prisma generate

# Copy built application from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

# Expose backend port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/v1/doctors || exit 1

# Start production server
CMD ["node", "dist/main"]
