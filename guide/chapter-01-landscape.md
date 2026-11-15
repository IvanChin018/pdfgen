# Chapter 1: The Landscape — Why Everything Else Sucks

> **TL;DR** — Every Go PDF approach has a fatal flaw. This chapter saves you the weeks I spent discovering them.

---

## The Four Categories

| Category | Examples | Fatal Flaw |
|----------|----------|------------|
| **HTML → PDF (WebKit/Qt)** | `wkhtmltopdf`, `go-wkhtmltopdf` | Dead project. QtWebKit hasn't been updated since 2017. No CSS Grid, Flexbox, custom properties. 500MB+ containers. |
| **HTML → PDF (Chromium)** | `chromedp`, `rod`, Puppeteer, `go-rod` | Works great *locally*. In CI/prod: 1GB+ images, flaky startup, memory leaks, no official headless-shell builds documented. |
| **Programmatic (Go-only)** | `gofpdf`/`fpdf2`, `pdfcpu`, `unidoc`, `go-pdf` | Total control, tiny binaries. But: **you write layout code**. Coordinate math for every element. Tables = pain. Pagination = manual. |
| **Commercial APIs** | DocRaptor, PDFShift, Gotenberg, AWS Lambda + Chrome | $0.10–$0.50/page. Latency (200ms–2s). Data leaves your network. Vendor lock-in. Rate limits. |

---

## My Journey (So You Don't Repeat It)

### Attempt 1: `wkhtmltopdf` (2019)
```dockerfile
FROM ubuntu:18.04
RUN apt-get install -y wkhtmltopdf  # 400MB layer
```
**Result:** Invoices looked fine until a client needed CSS Grid for a dashboard snapshot. `wkhtmltopdf` uses QtWebKit (WebKit from 2012). No Grid. No Flex. No `var(--custom-props)`. **Dead end.**

### Attempt 2: Puppeteer/ChromeDP (2020)
```go
browser, _ := chromedp.NewExecAllocator(ctx, chromedp.ExecPath("/usr/bin/chromium"))
```
**Result:** Worked beautifully on my Mac. In GitHub Actions: random "context canceled" errors, 3GB RAM spikes, 45s cold starts. Docker image: 1.2GB. **Unreliable in CI.**

### Attempt 3: `gofpdf` (2021)
```go
pdf.CellFormat(40, 10, "Item", "1", 0, "", false, 0, "")
pdf.CellFormat(30, 10, "Qty", "1", 0, "R", false, 0, "")
```
**Result:** Total control. But adding a wrapped paragraph? 20 lines of `MultiCell` math. A table with dynamic row heights? 100+ lines. Header on every page? Manual `SetY` + `Header()` override. **Not maintainable.**

### Attempt 4: Commercial API (2022)
```go
resp, _ := http.Post("https://api.docraptor.com/docs", "application/json", bytes.NewReader(body))
```
**Result:** $0.25/page. 500 invoices/month = $1,500/year. One day API latency hit 8s — our checkout timed out. **No control, recurring cost.**

---

## The Breakthrough: `headless-shell` + `chromedp`

Chrome 112+ ships **`headless-shell`** — a stripped-down Chromium binary (~120MB) with **only the print-to-PDF pipeline**. No V8 debugger, no DevTools protocol overhead, no GPU process.

```dockerfile
# 20MB final image
FROM gcr.io/distroless/static-debian12
COPY --from=builder /usr/bin/headless-shell /usr/bin/chromium
COPY --from=builder /app/pdfgen /pdfgen
```

**What you get:**
- Full modern CSS (Grid, Flex, `@container`, `::marker`, `@property`)
- `@page` rules: margins, headers, footers, counters, named pages
- `print.css` media query support
- Unicode, RTL, emoji, variable fonts
- PDF/A-1b via `PrintToPDF` options
- **Deterministic, fast, tiny**

---

## Decision Matrix

| Your Constraint | Best Choice |
|-----------------|-------------|
| **Full CSS (Grid/Flex/Print)** + tiny container | `chromedp` + `headless-shell` ← **This guide** |
| Simpler layouts, absolute smallest binary | `go-wkhtmltopdf` (static build) |
| No HTML — pure Go data → PDF | `pdfcpu` / `gofpdf` (programmatic) |
| PDF/A compliance, accessibility tags | `unidoc` (but manual layout) |
| Zero ops, happy to pay | DocRaptor / PDFShift / Gotenberg Cloud |

---

## What This Guide Builds

A **production PDF service** (`pdfgen`) that:

1. **Pools ChromeDP contexts** — 4 contexts, reused, no leaks
2. **Accepts HTML + options via HTTP** — `POST /pdf` → returns `application/pdf`
3. **Injects headers/footers** via CSS `position: running()` — perfect on every page
4. **Runs in 20MB** — `distroless` + `headless-shell`
5. **Observability built-in** — Prometheus metrics, zerolog, `/healthz`
6. **CI/CD ready** — GitHub Actions → goreleaser → multi-arch images

**Source code:** `github.com/pdfgen/pdfgen` (included with guide)

---

## What's Next

Chapter 2: **Picking Your Stack** — the exact decision matrix for your constraints, plus the `headless-shell` version pinning strategy that keeps builds reproducible.

---

> **Action item:** Clone the repo, run `make docker && make pdf-sample`. Open `testdata/output/sample.pdf`. That's your service working.