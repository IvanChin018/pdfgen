# Chapter 3: Project Setup — From Zero to `make pdf-sample`

> **TL;DR** — Every file in the repo, explained. Copy this structure for any Go service.

---

## Repository Layout

```
pdfgen/
├── cmd/pdfgen/              # Main package (public API)
│   └── main.go              # CLI, HTTP server, sample generator
├── internal/pdfgen/         # Private implementation
│   ├── service.go           # Core: pooling, generation, metrics
│   └── service_test.go      # Unit + concurrency tests
├── assets/templates/        # HTML templates (embed or file)
│   ├── header.html
│   ├── footer.html
│   └── invoice.html
├── testdata/                # Golden files for testing
│   ├── expected/            # Reference PDFs (gitignored large)
│   └── output/              # Generated during test (gitignored)
├── docs/                    # Guide chapters, landing page
├── .github/workflows/       # CI/CD
│   └── ci.yml
├── Dockerfile               # Multi-stage, distroless, headless-shell
├── Makefile                 # build, test, bench, docker, release
├── .goreleaser.yml          # Release automation
├── .air.toml                # Hot reload (dev only)
├── go.mod / go.sum
├── README.md
├── CHANGELOG.md
├── LICENSE
└── .gitignore
```

**Rule:** `internal/` = private (enforced by Go). `cmd/` = entry points. Everything else = supporting.

---

## `go.mod` — Minimal Dependencies

```go
module github.com/pdfgen/pdfgen

go 1.23

require (
    github.com/chromedp/chromedp v0.9.2
    github.com/zerolog/zerolog v1.33.0
    gopkg.in/yaml.v3 v3.0.1
)
```

**Why these three?**
- `chromedp` — Only maintained CDP client for Go
- `zerolog` — Fastest structured logger, zero alloc hot path
- `yaml.v3` — Config parsing (simpler than viper/koanf)

**No:** `cobra`, `viper`, `gin`, `echo`, `prometheus/client_golang` — we write our own CLI, config, HTTP, metrics. Less code, no updates, no vulnerabilities.

---

## `Makefile` — The Command Center

```makefile
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE    := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)

build:
    CGO_ENABLED=0 go build -ldflags="$(LDFLAGS)" -o bin/pdfgen ./cmd/pdfgen

test:
    go test -v -race -count=1 ./...

bench:
    go test -bench=. -benchmem -benchtime=10s ./...

docker:
    docker build --build-arg VERSION=$(VERSION) --build-arg COMMIT=$(COMMIT) --build-arg DATE=$(DATE) -t pdfgen:$(VERSION) -t pdfgen:latest .

pdf-sample: build
    ./bin/pdfgen sample --output testdata/output/sample.pdf

dev:
    air -c .air.toml

release:
    goreleaser release --clean
```

**Key targets:**
- `make build` → `bin/pdfgen` (version embedded)
- `make test` → race detector, count=1 (no flakes)
- `make bench` → 10s benches, prints allocs/op
- `make pdf-sample` → end-to-end verification
- `make dev` → hot reload with `air`
- `make release` → goreleaser (tags only)

---

## `Dockerfile` — 20MB Production Image

```dockerfile
# Stage 1: Builder
FROM golang:1.23-alpine AS builder

# Install headless-shell + fonts + build deps
ARG CHROME_VERSION=126.0.6478.0
RUN apk add --no-cache \
    wget unzip ca-certificates \
    freetype fontconfig ttf-freefont \
    git make gcc musl-dev

RUN wget -q "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/headless-shell-linux64.zip" \
    && unzip -q headless-shell-linux64.zip \
    && mv headless-shell-linux64/headless-shell /usr/bin/chromium \
    && rm -rf headless-shell-linux64*

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w -X main.version={{.Version}} -X main.commit={{.Commit}} -X main.date={{.Date}}" -o pdfgen ./cmd/pdfgen

# Stage 2: Runtime (distroless)
FROM gcr.io/distroless/static-debian12:nonroot

# Copy only what's needed
COPY --from=builder /usr/bin/chromium /usr/bin/chromium
COPY --from=builder /usr/share/fonts/truetype/freefont/ /usr/share/fonts/truetype/freefont/
COPY --from=builder /etc/fonts/ /etc/fonts/
COPY --from=builder /app/pdfgen /pdfgen

ENV CHROME_PATH=/usr/bin/chromium
ENV CHROME_FLAGS="--no-sandbox --disable-gpu --disable-dev-shm-usage --disable-extensions --disable-background-networking --disable-sync --disable-translate --hide-scrollbars --metrics-recording-only --mute-audio --no-first-run --safebrowsing-disable-auto-update --disable-default-apps --disable-component-extensions-with-background-pages"

USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/pdfgen"]
```

**Why this works:**
- `distroless:nonroot` — No shell, no package manager, runs as UID 65532
- `headless-shell` — Single binary, no GPU process
- Fonts copied explicitly — FreeFont covers Latin/Cyrillic/Greek; add Noto for CJK
- Chrome flags hardened — No sandbox needed in distroless

**Build:** `make docker` → `docker images pdfgen` shows ~22MB.

---

## `.goreleaser.yml` — Automated Releases

```yaml
version: 2

before:
  hooks:
    - go mod tidy
    - go generate ./...

builds:
  - id: pdfgen
    main: ./cmd/pdfgen
    binary: pdfgen
    ldflags:
      - -s -w
      - -X main.version={{.Version}}
      - -X main.commit={{.Commit}}
      - -X main.date={{.Date}}
    goos: [linux, darwin, windows]
    goarch: [amd64, arm64]
    ignore:
      - goos: windows
        goarch: arm64
    env:
      - CGO_ENABLED=0

archives:
  - format: tar.gz
    name_template: "{{ .ProjectName }}_{{ .Os }}_{{ .Arch }}"
    files:
      - README.md
      - LICENSE
      - CHANGELOG.md

checksum:
  name_template: 'checksums.txt'

snapshot:
  version_template: "{{ incpatch .Version }}-next"

changelog:
  sort: asc
  filters:
    exclude:
      - '^docs:'
      - '^test:'
      - '^chore:'
      - 'Merge pull request'

release:
  github:
    owner: pdfgen
    name: pdfgen
  draft: false
  prerelease: auto

dockers:
  - image_templates: ["ghcr.io/pdfgen/pdfgen"]
    dockerfile: Dockerfile
    build_flag_templates:
      - "--platform=linux/amd64,linux/arm64"
      - "--build-arg=VERSION={{.Version}}"
      - "--build-arg=COMMIT={{.Commit}}"
      - "--build-arg=DATE={{.Date}}"
      - "--build-arg=CHROME_VERSION={{.Env.CHROME_VERSION}}"
    goos: linux
    goarch: [amd64, arm64]
    ids: [pdfgen]
```

**Trigger:** Push a tag → `git tag v0.1.0 && git push origin v0.1.0`

**Produces:**
- GitHub Release with `pdfgen_Linux_x86_64.tar.gz`, `pdfgen_Darwin_arm64.tar.gz`, `pdfgen_Windows_x86_64.zip`
- `checksums.txt` (SHA256)
- Multi-arch Docker images on `ghcr.io/pdfgen/pdfgen`
- Auto-generated changelog from conventional commits

---

## `.github/workflows/ci.yml` — CI Pipeline

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  release:
    types: [published]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23', cache: true }
      - name: Install Chrome
        run: |
          wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
          echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
          sudo apt-get update && sudo apt-get install -y google-chrome-stable
      - run: make test
      - run: make bench

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.23', cache: true }
      - run: make build
      - uses: actions/upload-artifact@v4
        with: { name: pdfgen-linux-amd64, path: bin/pdfgen }

  docker:
    needs: build
    if: github.event_name != 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with: { registry: ghcr.io, username: ${{ github.actor }}, password: ${{ secrets.GITHUB_TOKEN }} }
      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ghcr.io/pdfgen/pdfgen
          tags: |
            type=semver,pattern={{version}}
            type=sha
            type=raw,value=latest,enable={{is_default_branch}}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          platforms: linux/amd64,linux/arm64
          cache-from: type=gha
          cache-to: type=gha,mode=max

  goreleaser:
    needs: [test, build]
    if: github.event_name == 'release' && github.event.action == 'published'
    runs-on: ubuntu-latest
    permissions: { contents: write, packages: write, issues: write }
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }
      - uses: actions/setup-go@v5
        with: { go-version: '1.23', cache: true }
      - uses: goreleaser/goreleaser-action@v6
        with: { version: latest, args: release --clean }
        env: { GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }} }
```

**Flow:**
1. `test` → `build` → `docker` (on push to main)
2. On tag push → `test` → `build` → `goreleaser` (release + Docker)

**Secrets needed:** `GITHUB_TOKEN` (auto), `CHROME_VERSION` (repo variable)

---

## `.air.toml` — Hot Reload for Dev

```toml
root = "."
tmp_dir = "tmp"

[build]
  bin = "./tmp/pdfgen"
  cmd = "go build -o ./tmp/pdfgen ./cmd/pdfgen"
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata", "docs", ".git"]
  include_ext = ["go", "html", "tpl"]
  stop_on_error = true
```

**Usage:** `make dev` (requires `go install github.com/air-verse/air@latest`)

**Watches:** `*.go`, `*.html` in `cmd/`, `internal/`, `assets/templates/`

---

## `README.md` — Dual Purpose

Your README serves two audiences:

1. **Developers** — "How do I use this library/service?"
2. **Buyers** — "Why should I buy the guide?"

**Structure:**
```markdown
# pdfgen — Bulletproof PDF Generation in Go

[Badges: Go version, License, Docker, GoReportCard]

> **Companion source for:** [*Bulletproof PDF Generation in Go*](https://gumroad.com/l/pdfgen-go)

## Features (table)
## Quick Start (build, run, curl)
## Configuration (flags + env)
## API (POST /pdf, GET /healthz, GET /metrics)
## Project Structure (tree)
## Real-World Recipes (table)
## Testing (commands)
## Deploying (Cloud Run, K8s)
## Why This Exists (your story)
## Guide Pitch (CTA link)
## License + Contributing + Author
```

---

## `.gitignore` — Keep It Clean

```gitignore
/bin/
/tmp/
/dist/
*.exe
pdfgen
*.log
build-errors.log
/testdata/output/
*.pdf
.env
vendor/
go.work
coverage.out
cpu.prof
mem.prof
```

---

## Your First Run

```bash
# 1. Clone
git clone https://github.com/pdfgen/pdfgen
cd pdfgen

# 2. Build
make build

# 3. Generate sample PDF
make pdf-sample
# Output: testdata/output/sample.pdf

# 4. Run server
./bin/pdfgen -port=8080

# 5. Test API
curl -X POST http://localhost:8080/pdf \
  -H "Content-Type: application/json" \
  -d '{"html": "<h1>Hello</h1>", "options": {"page_size": "A4"}}' \
  -o test.pdf
```

**Expected:** `test.pdf` opens with "Hello" on A4, 20mm margins.

---

## Next Chapter

Chapter 4: **Core Service** — Every line of `internal/pdfgen/service.go` explained. Pooling, generation, metrics, graceful shutdown.

---

> **Action item:** Run `make docker && docker run -p 8080:8080 pdfgen:latest`. Hit `curl localhost:8080/healthz` → `ok`.