# Build stage
FROM golang:1.23-alpine AS builder

# Install build tools
RUN apk add --no-cache git make gcc musl-dev

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build static binary
ARG VERSION=dev
ARG COMMIT=unknown
ARG DATE=unknown
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -X main.date=${DATE}" \
    -o pdfgen ./cmd/pdfgen

# Runtime stage — use Chrome headless shell for PDF rendering
FROM chromedp/chrome-headless-shell:latest AS chrome

# Final stage
FROM debian:bookworm-slim

# Install runtime dependencies for Chromium
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    libnss3 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Copy headless shell from the chrome image
COPY --from=chrome /headless-shell /usr/bin/chromium
COPY --from=chrome /usr/lib/ /usr/lib/

# Copy binary
COPY --from=builder /app/pdfgen /pdfgen

ENV CHROME_PATH=/usr/bin/chromium
ENV CHROME_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage --disable-extensions --disable-background-networking --disable-sync --disable-translate --hide-scrollbars --metrics-recording-only --mute-audio --no-first-run --safebrowsing-disable-auto-update --disable-default-apps --disable-component-extensions-with-background-pages"

# Create non-root user
RUN useradd -m -u 1000 pdfgen && \
    mkdir -p /home/pdfgen && \
    chown -R pdfgen:pdfgen /home/pdfgen

USER pdfgen
EXPOSE 8080
ENTRYPOINT ["/pdfgen"]