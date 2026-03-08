# ---------- Stage 1 : Build ----------

FROM fpco/stack-build:lts AS builder

WORKDIR /build

# Copy dependency files first (for Docker caching)

COPY scotty-web/stack.yaml ./stack.yaml
COPY scotty-web/scotty-web.cabal ./scotty-web.cabal

# Install dependencies only

RUN stack build --only-dependencies

# Copy the rest of the project

COPY scotty-web .

# Build executable

RUN stack build --copy-bins

# ---------- Stage 2 : Runtime ----------

FROM debian:bookworm-slim

WORKDIR /app

# Copy compiled binary

COPY --from=builder /root/.local/bin/scotty-web-exe .

# Copy static files

COPY --from=builder /build/static ./static

EXPOSE 3000

CMD ["./scotty-web-exe"]
