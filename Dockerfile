# Stage 1: Build
FROM fpco/stack-build:lts AS builder

WORKDIR /build/scotty-web

# Copy ONLY dependency files first (Docker caches this layer)
COPY scotty-web/package.yaml .
COPY scotty-web/stack.yaml .
COPY scotty-web/stack.yaml.lock* .

# Install dependencies (cached unless package.yaml changes)
RUN stack setup --no-terminal
RUN stack build --only-dependencies --no-terminal

# Now copy source code and build the app
COPY scotty-web/ .
RUN stack build --copy-bins --no-terminal

# Stage 2: Lightweight runtime
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgmp10 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /root/.local/bin/scotty-web-exe .
COPY scotty-web/static ./static

EXPOSE 3000

CMD ["./scotty-web-exe"]