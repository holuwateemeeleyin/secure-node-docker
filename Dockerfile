
# Stage 1: Install application dependencies
FROM node:22.23.3-alpine3.24 AS build

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci --omit=dev && npm cache clean --force

# Stage 2: Create the production image
FROM node:22.23.3-alpine3.24 AS runtime

ENV NODE_ENV=production \
    PORT=3000 \
    NODE_OPTIONS=--max-old-space-size=256

WORKDIR /app

# Create a dedicated non-root user
RUN addgroup -S appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Copy only the files required to run the application
COPY --from=build --chown=1001:appgroup /app/node_modules ./node_modules
COPY --chown=1001:appgroup package.json ./
COPY --chown=1001:appgroup server.js ./

# Remove package managers that are not needed at runtime
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /opt/yarn-v1.22.22 && \
    rm -f /usr/local/bin/npm \
          /usr/local/bin/npx \
          /usr/local/bin/corepack \
          /usr/local/bin/yarn \
          /usr/local/bin/yarnpkg

USER 1001:1001

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://127.0.0.1:3000/health', r => process.exit(r.statusCode === 200 ? 0 : 1)).on('error', () => process.exit(1))"

CMD ["node", "server.js"]