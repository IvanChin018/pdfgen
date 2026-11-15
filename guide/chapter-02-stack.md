# Chapter 2: Picking Your Stack — The Decision Matrix

> **TL;DR** — For 90% of Go teams generating PDFs from HTML: **`chromedp` + `headless-shell`**. This chapter proves it.

---

## The Stack We Use

| Layer | Choice | Version (Pinned) | Why |
|-------|--------|------------------|-----|
| **Language** | Go | 1.23+ | Stdlib, static binaries, great tooling |
| **PDF Engine** | `chromedp` | v0.9.2 | Official Chrome DevTools Protocol client |
| **Browser** | `headless-shell` | 126.0.6478.0 | Stripped Chromium, print-only, ~120MB |
| **Base Image** | `gcr.io/distroless/static-debian12` | latest | No shell, no package manager, non-root |
| **Logging** | `zerolog` | v1.33.0 | Zero-allocation, structured, fast |
| **Config** | Env vars + CLI flags | — | 12-factor, container-native |
| **Build** | `goreleaser` | v2.5.0 | Multi-arch, changelog, Docker, Homebrew |
| **CI** | GitHub Actions | — | Free for public, matrix builds |

---

## Why `headless-shell` Not Full Chromium?

| Aspect | Full Chromium | `headless-shell` |
|--------|---------------|------------------|
| Size | ~200MB | ~120MB |
| Processes | Browser + GPU + Utility + Renderer | Single process |
| DevTools Protocol | Full | Print-to-PDF only |
| Startup time | ~2s | ~800ms |
| Memory (idle) | ~150MB | ~40MB |
| Docker layer | Multiple | Single binary |

**For PDF generation, you don't need:** V8 debugger, DevTools frontend, GPU process, extension system, sync, translations, Widevine, crash reporter.

---

## Version Pinning Strategy (Critical)

**Never use `latest` or `stable` in production Dockerfiles.**

```dockerfile
# BAD - breaks reproducibly
RUN apt-get install -y chromium

# GOOD - pinned to specific headless-shell release
ARG CHROME_VERSION=126.0.6478.0
RUN wget -q "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/headless-shell-linux64.zip" \
    && unzip -q headless-shell-linux64.zip \
    && mv headless-shell-linux64/headless-shell /usr/bin/chromium \
    && rm -rf headless-shell-linux64*
```

**Where to find versions:** https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json

**Pin in three places:**
1. `Dockerfile` → `ARG CHROME_VERSION=...`
2. `.goreleaser.yml` → `build_flag_templates: ["--build-arg=CHROME_VERSION={{.Env.CHROME_VERSION}}"]`
3. GitHub Actions → `env: CHROME_VERSION: 126.0.6478.0`

**Update process:** Monthly. Test `make docker && make pdf-sample`. If sample.pdf renders → tag release.

---

## Chrome Flags — Minimal Set for Production

```go
const defaultChromeFlags = `
  --no-sandbox
  --disable-gpu
  --disable-dev-shm-usage
  --disable-extensions
  --disable-background-networking
  --disable-sync
  --disable-translate
  --hide-scrollbars
  --metrics-recording-only
  --mute-audio
  --no-first-run
  --safebrowsing-disable-auto-update
  --disable-default-apps
  --disable-component-extensions-with-background-pages
  --disable-features=TranslateUI,BlinkGenPropertyTrees
  --run-all-compositor-stages-before-draw
`
```

| Flag | Purpose |
|------|---------|
| `--no-sandbox` | Required in containers (no USER_NS) |
| `--disable-dev-shm-usage` | Use `/tmp` not `/dev/shm` (avoids OOM in small containers) |
| `--disable-gpu` | No GPU process = less memory |
| `--disable-extensions` | No extension loading |
| `--disable-background-networking` | No phoning home |
| `--run-all-compositor-stages-before-draw` | Fixes rare blank-page race |

**Don't add:** `--disable-web-security`, `--allow-running-insecure-content` — security holes.

---

## Pool Sizing Formula

```go
// Rule of thumb: POOL_SIZE = CPU_CORES * 2 (for I/O bound)
// But: each context ~40MB RAM. Limit by container memory.

func optimalPoolSize(memoryLimitMB int) int {
    // Reserve 100MB for Go runtime + OS
    availableForChrome := memoryLimitMB - 100
    if availableForChrome < 80 { // minimum 2 contexts
        return 2
    }
    contexts := availableForChrome / 40
    return min(contexts, runtime.NumCPU()*2)
}
```

| Container Memory | Pool Size | Max Concurrent PDFs |
|------------------|-----------|---------------------|
| 256MB | 2 | 2 |
| 512MB | 4 | 4 |
| 1GB | 8 | 8 |
| 2GB | 16 | 16 |

**Monitor:** `pdfgen_request_duration_ms_avg` + `pdfgen_requests_failed_total`. If p99 > 5s or failures > 1% → increase pool or memory.

---

## Dependencies — Minimal & Audited

```go
// go.mod (excerpt)
require (
    github.com/chromedp/chromedp v0.9.2      // Core - actively maintained
    github.com/zerolog/zerolog v1.33.0       // Logging - zero alloc
    gopkg.in/yaml.v3 v3.0.1                  // Config - stdlib alternative
)
```

**No:** ORM, web framework, DI container, config library, metrics library (we write Prometheus text format directly).

**Supply chain:** `go mod verify` in CI. `goreleaser` signs artifacts with cosign.

---

## What We Explicitly Don't Use

| Tool | Reason |
|------|--------|
| `rod` / `go-rod` | Higher-level, but more opaque. `chromedp` is closer to CDP. |
| `gotenberg` | Great product, but adds HTTP layer. We want library, not service. |
| `wkhtmltopdf` | Dead. No modern CSS. |
| `pdfcpu` for HTML→PDF | It doesn't do HTML→PDF. Only programmatic/merge/split. |
| Custom fonts in container | Use `@font-face` in HTML + Google Fonts (SIL/OFL). Smaller image. |

---

## Your Decision Checklist

Answer each. If **mostly "yes"** → use this stack.

- [ ] Input is HTML/CSS (not raw data)
- [ ] Need modern CSS (Grid, Flex, custom properties)
- [ ] Need headers/footers on every page
- [ ] Run in containers (K8s, Cloud Run, Fly.io, Lambda)
- [ ] Want <100MB image
- [ ] Team knows Go (or willing to learn)
- [ ] Need observability (metrics, logs, health)
- [ ] Want to own the stack (no vendor)

**If 3+ "no":** Consider commercial API or programmatic (`pdfcpu`/`gofpdf`).

---

## Next Chapter

Chapter 3: **Project Setup** — `go.mod`, `Dockerfile`, `Makefile`, GitHub Actions CI, goreleaser config. Every file explained, copy-paste ready.

---

> **Action item:** Open `pdfgen-guide/Dockerfile` and `pdfgen-guide/.goreleaser.yml`. Compare Chrome version pins. They match.