# Multi-stage Dockerfile for all Zedex Node.js services.
# Stage 1 (build): installs deps, runs turbo build for the target service.
# Stage 2 (runtime): distroless Node 24, copies compiled output only.
# Usage: docker build --build-arg SERVICE=workspace -t zedex-workspace .
# Gate 2 — placeholder
ARG SERVICE=workspace
FROM node:24-slim AS build
WORKDIR /app
ARG SERVICE
COPY . .
RUN corepack enable && pnpm install --frozen-lockfile
RUN pnpm turbo run build --filter=@zedex/\

FROM gcr.io/distroless/nodejs24-debian12 AS runtime
WORKDIR /app
ARG SERVICE
COPY --from=build /app/services/\/dist ./dist
COPY --from=build /app/services/\/package.json .
CMD ["dist/main.js"]
