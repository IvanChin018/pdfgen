# pdfgen — Bulletproof PDF Generation in Go

[![Go Version](https://img.shields.io/badge/Go-1.23+-00ADD8?logo=go)](https://golang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-ghcr.io%2Fpdfgen-2496ED?logo=docker)](https://github.com/pdfgen/pdfgen/pkgs/container/pdfgen)
[![GoReportCard](https://goreportcard.com/badge/github.com/pdfgen/pdfgen)](https://goreportcard.com/report/github.com/pdfgen/pdfgen)

A production-ready PDF generation service for Go. Render HTML/CSS → PDF with perfect pagination, headers/footers, Unicode support, and run it in a **20MB scratch container**.

> **This is the companion source code for the guide:** [*Bulletproof PDF Generation in Go*](https://gumroad.com/l/pdfgen-go) — 72 pages of dense, zero-fluff content covering everything from stack selection to production hardening.

---

## Features

| Feature | Details |
|---------|---------|
| **Full HTML/CSS rendering** | Grid, Flex, custom fonts, `print.css`, `@page` rules |
| **Perfect pagination** | Headers/footers via CSS `position: running()`, page counters, TOC |
| **Tiny containers** | 20MB scratch image with `headless-shell` (no Chromium bloat) |
| **Unicode & RTL** | Arabic, Hebrew, CJK, emoji — just works |
| **PDF/A-1b & accessibility** | Tagged PDF, embedded fonts, ICC profiles |
| **Observability** | Prometheus metrics, structured logging (zerolog), health checks |
| **Production hardening** | Resource limits, graceful shutdown, non-root, seccomp |
| **CI/CD ready** | GitHub Actions → goreleaser → multi-arch Docker images |

---

## Quick Start

### Prerequisites
- Go 1.23+
- Docker (for containerized deployment)

### Build & Run Locally

```bash
# Clone
git clone https://github.com/pdfgen/pdfgen
cd pdfgen

# Build binary
make build

# Generate sample PDF
make pdf-sample
# Output: testdata/output/sample.pdf

# Run server
./bin/pdfgen -port=8080 -pool=4
```

### Generate a PDF via HTTP

```bash
curl -X POST http://localhost:8080/pdf \
  -H "Content-Type: application/json" \
  -d '{
    "html": "<h1>Hello pdfgen</h1><p>Generated at {{.Now}}</p>",
    "options": {
      "page_size": "A4",
      "margins": {"top": "20mm", "right": "20mm", "bottom": "20mm", "left": "20mm"},
      "header_html": "<header>My App</header>",
      "footer_html": "<footer>Page <span class=\"pageNumber\"></span></footer>"
    }
  }' \
  -o output.pdf
```

### Docker

```bash
# Build
make docker

# Run
docker run -p 8080:8080 \
  -e CHROME_FLAGS="--no-sandbox --disable-gpu" \
  pdfgen:latest
```

---

## Configuration

All config via environment variables or CLI flags:

| Flag / Env | Default | Description |
|------------|---------|-------------|
| `-port` / `PORT` | `8080` | HTTP server port |
| `-pool` / `POOL_SIZE` | `4` | ChromeDP context pool size |
| `-timeout` / `REQUEST_TIMEOUT` | `30s` | Max time per PDF generation |
| `-log-level` / `LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error` |
| `CHROME_PATH` | auto | Path to Chrome/Chromium binary |
| `CHROME_FLAGS` | (see Dockerfile) | Additional Chrome flags |

---

## API

### `POST /pdf`

Generate a PDF from HTML.

**Request:**
```json
{
  "html": "<!DOCTYPE html><html><body><h1>Invoice #123</h1>...</body></html>",
  "options": {
    "page_size": "A4",
    "landscape": false,
    "margins": {"top": "20mm", "right": "20mm", "bottom": "20mm", "left": "20mm"},
    "scale": 1.0,
    "header_html": "<header>My Company</header>",
    "footer_html": "<footer>Page <span class=\"pageNumber\"></span> of <span class=\"totalPages\"></span></footer>",
    "pdf_version": "1.7"
  }
}
```

**Response:** `application/pdf` binary stream.

### `GET /healthz`

Health check. Returns `200 OK` with body `ok` if service is healthy.

### `GET /metrics`

Prometheus-format metrics:
```
pdfgen_requests_total 142
pdfgen_requests_success_total 138
pdfgen_requests_failed_total 4
pdfgen_request_duration_ms_avg 1247
```

---

## Project Structure

```
pdfgen/
├── cmd/pdfgen/           # Main entry point
│   └── main.go           # CLI, HTTP server, sample generator
├── internal/pdfgen/      # Core service (private)
│   └── service.go        # Pooling, generation, metrics
├── assets/templates/     # HTML templates (header, footer, recipes)
├── testdata/             # Golden files for testing
├── docs/                 # Guide chapters, landing page, Gumroad setup
├── .github/workflows/    # CI/CD (test, build, docker, release)
├── Dockerfile            # Multi-stage, scratch, headless-shell
├── Makefile              # build, test, bench, docker, release
├── .goreleaser.yml       # Release automation
├── .air.toml             # Hot reload config
└── go.mod / go.sum
```

---

## Real-World Recipes (Chapter 10)

The guide includes copy-paste recipes for:

| Recipe | Use Case | Key Techniques |
|--------|----------|----------------|
| **Invoice** | Billing, SaaS | Line items, tax calc, QR code (`go-qrcode`), dynamic totals |
| **Certificate** | Courses, events | Dynamic name, border, signature image, watermark |
| **Multi-page Report** | Analytics, audits | Cover → TOC → chapters → appendix, page refs |
| **Shipping Label** | Logistics, e-commerce | 4×6 thermal, exact dimensions, no margins, barcode |

---

## Testing

```bash
# Unit tests (with race detector)
make test

# Benchmarks
make bench

# Golden file tests (pixel diff)
# Adds testdata/expected/*.pdf → compares on each run
```

---

## Deploying

### Cloud Run / Fly.io / Render / Railway

```dockerfile
# Use the provided Dockerfile — it's multi-arch, non-root, health-check ready
```

**Required env:**
```bash
PORT=8080
POOL_SIZE=4
REQUEST_TIMEOUT=30s
CHROME_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage"
```

### Kubernetes

```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "256Mi"
    cpu: "250m"
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 30
```

---

## Why This Exists

I built PDF systems for a fintech processing **10M+ docs/month**. Every approach failed:

- `wkhtmltopdf` → QtWebKit bugs, no modern CSS, 500MB containers
- Puppeteer/ChromeDP → 1GB+ images, flaky CI, memory leaks
- `gofpdf` → manual layout = coordinate math hell
- Commercial APIs → $0.50/page, latency, data leaves your infra

**This service** is what I wish existed: **HTML/CSS in, perfect PDF out, runs in 20MB, you own it.**

---

## Guide: "Bulletproof PDF Generation in Go"

The **72-page guide** walks through every line of this codebase:

1. **The Landscape** — Honest comparison of every Go PDF approach
2. **Picking Your Stack** — Decision matrix for your constraints
3. **Project Setup** — `go.mod`, `Dockerfile`, `Makefile`, CI pipeline
4. **Core Service** — Pooling, timeouts, metrics, graceful shutdown
5. **HTML/CSS That Prints** — `@page`, `print.css`, fonts, debugging
6. **Headers/Footers** — CSS `running()` elements, dynamic data, counters
7. **Advanced** — TOC, watermarks, PDF/A-1b, accessibility, merging
8. **Testing & CI** — Golden files, property tests, benchmarks, load testing
9. **Production Hardening** — Security, resource limits, observability
10. **Real-World Recipes** — Invoice, certificate, report, shipping label

**[Get the guide →](https://gumroad.com/l/pdfgen-go)** (includes this source code + free v1.x updates)

---

## License

**Source code:** MIT License — see [LICENSE](LICENSE)

**Guide content:** Personal/team use only (purchased separately)

---

## Contributing

Issues and PRs welcome! For major changes, open an issue first.

```bash
# Development with hot reload
make dev  # requires: go install github.com/air-verse/air@latest
```

---

## Author

**[Your Name]** — Go developer, systems builder, PDF survivor.

- Blog: [yourblog.dev](https://yourblog.dev)
- Newsletter: [yournewsletter.com](https://yournewsletter.com)
- Twitter: [@yourhandle](https://twitter.com/yourhandle)