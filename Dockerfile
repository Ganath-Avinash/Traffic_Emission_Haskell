# Stage 1 — build
FROM fpco/stack-build:lts AS builder

WORKDIR /build
COPY . .

WORKDIR /build/scotty-web
RUN stack setup
RUN stack build --copy-bins

# Stage 2 — runtime
FROM debian:bookworm-slim

WORKDIR /app/scotty-web

COPY --from=builder /root/.local/bin/scotty-web-exe .
COPY scotty-web/static ./static

EXPOSE 3000

CMD ["./scotty-web-exe"]
