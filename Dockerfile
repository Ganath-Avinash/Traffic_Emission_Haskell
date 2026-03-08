# Stage 1: Build
FROM fpco/stack-build:lts AS builder

WORKDIR /build
COPY . .

WORKDIR /build/scotty-web
RUN stack setup
RUN stack build --copy-bins

# Stage 2: Runtime
FROM debian:bookworm-slim

WORKDIR /app
COPY --from=builder /root/.local/bin/scotty-web-exe .
COPY --from=builder /build/scotty-web/static ./static

EXPOSE 3000

CMD ["./scotty-web-exe"]
