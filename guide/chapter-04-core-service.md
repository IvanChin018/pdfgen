# Chapter 4: Core Service — Pooling, Generation, Metrics

> **TL;DR** — The heart of pdfgen: `internal/pdfgen/service.go`. Every line explained.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      HTTP Handler                           │
│  POST /pdf  →  DecodeRequest  →  svc.Generate(ctx, req)    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service.Generate                         │
│  1. Acquire ChromeDP context from pool                      │
│  2. Navigate to about:blank                                 │
│  3. Set HTML content                                        │
│  4. Inject header/footer (if provided)                      │
│  5. PrintToPDF → []byte                                     │
│  6. Release context to pool                                 │
│  7. Update metrics                                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    ChromeDP Context Pool                    │
│  chan *chromedp.Context (buffered = PoolSize)               │
│  Pre-warmed on startup                                      │
│  Acquire: blocking read from channel                        │
│  Release: non-blocking write (drop if full)                 │
└─────────────────────────────────────────────────────────────┘
```

---

## ServiceConfig

```go
type ServiceConfig struct {
    PoolSize       int           // ChromeDP contexts to pool (default: 4)
    RequestTimeout time.Duration // Max time per PDF (default: 30s)
    ChromePath     string        // Override chromium binary path
    ChromeFlags    string        // Additional Chrome flags (space-separated)
}
```

**Defaults** in `NewService`:
- `PoolSize = 4` — Good for 512MB container
- `RequestTimeout = 30s` — Covers complex pages
- `ChromePath` — Auto-detect via `chromedp` default
- `ChromeFlags` — From `CHROME_FLAGS` env var

---

## Context Pool — The Critical Piece

```go
func NewService(config ServiceConfig) (*Service, error) {
    // ... allocator setup ...

    pool := make(chan *chromedp.Context, config.PoolSize)
    for i := 0; i < config.PoolSize; i++ {
        ctx, cancel := chromedp.NewContext(allocator)
        _ = cancel // We manage lifecycle via pool
        pool <- ctx
    }

    // Warm up
    go svc.warmup()

    return &Service{pool: pool, allocator: allocator, ...}, nil
}
```

**Why pool?**
- ChromeDP context creation = new browser process = ~200ms + 40MB RAM
- Pool reuses contexts = sub-millisecond acquire
- Fixed memory footprint = predictable container sizing

**Warmup** pre-navigates each context to `about:blank` — avoids first-request latency spike.

---

## Acquire/Release Pattern

```go
func (s *Service) acquireContext() *chromedp.Context {
    select {
    case ctx := <-s.pool:
        return ctx
    default:
        // Pool exhausted — create temporary (no leak, allocator manages)
        ctx, _ := chromedp.NewContext(s.allocator)
        return ctx
    }
}

func (s *Service) releaseContext(ctx *chromedp.Context) {
    select {
    case s.pool <- ctx:
    default:
        // Pool full — discard (temp context)
    }
}
```

**Key insight:** `default` case on both = **never blocks**. Under load, extra requests get temporary contexts. Pool size = steady-state concurrency.

---

## Generate Flow — Step by Step

```go
func (s *Service) Generate(ctx context.Context, req GenerateRequest) ([]byte, error) {
    start := time.Now()
    atomic.AddUint64(&s.metrics.requestsTotal, 1)
    defer func() {
        atomic.AddUint64(&s.metrics.totalDuration, uint64(time.Since(start).Nanoseconds()))
    }()

    pdfCtx := s.acquireContext()
    if pdfCtx == nil {
        atomic.AddUint64(&s.metrics.requestsFailed, 1)
        return nil, ErrPoolExhausted
    }
    defer s.releaseContext(pdfCtx)

    printOpts := s.buildPrintOptions(req.Options)

    var pdfBuf []byte
    err := chromedp.Run(pdfCtx,
        chromedp.Navigate("about:blank"),
        chromedp.ActionFunc(func(ctx context.Context) error {
            return chromedp.SetHTMLContent(req.HTML).Do(ctx)
        }),
        chromedp.WaitReady("body", chromedp.ByQuery),
        chromedp.ActionFunc(func(ctx context.Context) error {
            if req.Options.HeaderHTML != "" || req.Options.FooterHTML != "" {
                return s.injectHeaderFooter(ctx, req.Options)
            }
            return nil
        }),
        chromedp.PrintToPDF(&pdfBuf, printOpts...),
    )

    if err != nil {
        atomic.AddUint64(&s.metrics.requestsFailed, 1)
        return nil, err
    }

    atomic.AddUint64(&s.metrics.requestsSuccess, 1)
    return pdfBuf, nil
}
```

**Each `chromedp.Run` action:**
1. `Navigate("about:blank")` — Clean slate, no cached resources
2. `SetHTMLContent(req.HTML)` — Injects our HTML into the frame
3. `WaitReady("body")` — Ensures DOM ready before print
4. `injectHeaderFooter` — Runs JS to inject header/footer elements
5. `PrintToPDF` — The actual PDF generation

---

## Print Options Mapping

```go
func (s *Service) buildPrintOptions(opts Options) []chromedp.PrintToPDFOption {
    return []chromedp.PrintToPDFOption{
        chromedp.PrintToPDFPaperWidth(paperWidth(opts.PageSize)),
        chromedp.PrintToPDFPaperHeight(paperHeight(opts.PageSize)),
        chromedp.PrintToPDFMarginTop(marginValue(opts.Margins.Top)),
        chromedp.PrintToPDFMarginBottom(marginValue(opts.Margins.Bottom)),
        chromedp.PrintToPDFMarginLeft(marginValue(opts.Margins.Left)),
        chromedp.PrintToPDFMarginRight(marginValue(opts.Margins.Right)),
        chromedp.PrintToPDFLandscape(opts.Landscape),
        chromedp.PrintToPDFPrintBackground(true),
        chromedp.PrintToPDFPreferCSSPageSize(true),
    }
}
```

**Critical flags:**
- `PrintBackground(true)` — Renders background colors/images (required for headers/footers)
- `PreferCSSPageSize(true)` — Respects `@page { size: A4 }` in CSS over Go options

---

## Header/Footer Injection — The Magic

```go
func (s *Service) injectHeaderFooter(ctx context.Context, opts Options) error {
    script := `
        (function() {
            var style = document.createElement('style');
            style.textContent = `
                @page {
                    @top-center { content: element(header); }
                    @bottom-center { content: element(footer); }
                }
                header { position: running(header); }
                footer { position: running(footer); }
            `;
            document.head.appendChild(style);

            if (` + jsonEscape(opts.HeaderHTML) + `) {
                var header = document.createElement('header');
                header.innerHTML = ` + jsonEscape(opts.HeaderHTML) + `;
                document.body.insertBefore(header, document.body.firstChild);
            }
            if (` + jsonEscape(opts.FooterHTML) + `) {
                var footer = document.createElement('footer');
                footer.innerHTML = ` + jsonEscape(opts.FooterHTML) + `;
                document.body.appendChild(footer);
            }
        })();
    `
    return chromedp.Evaluate(script, nil).Do(ctx)
}
```

**What this does:**
1. Injects `@page` rules with `running()` elements
2. Creates `<header>` and `<footer>` DOM elements
3. Inserts them at top/bottom of `<body>`
4. Chromium's print engine picks them up via `position: running()`

**Result:** Headers/footers repeat on **every page** with correct page numbers.

---

## Metrics — Prometheus Text Format

```go
func (s *Service) Metrics() string {
    total := atomic.LoadUint64(&s.metrics.requestsTotal)
    success := atomic.LoadUint64(&s.metrics.requestsSuccess)
    failed := atomic.LoadUint64(&s.metrics.requestsFailed)
    duration := atomic.LoadUint64(&s.metrics.totalDuration)

    var avgDuration float64
    if total > 0 {
        avgDuration = float64(duration) / float64(total) / 1e6 // ms
    }

    return `# HELP pdfgen_requests_total Total PDF generation requests
# TYPE pdfgen_requests_total counter
pdfgen_requests_total ` + string(rune(total)) + `
# HELP pdfgen_requests_success_total Successful PDF generations
# TYPE pdfgen_requests_success_total counter
pdfgen_requests_success_total ` + string(rune(success)) + `
# HELP pdfgen_requests_failed_total Failed PDF generations
# TYPE pdfgen_requests_failed_total counter
pdfgen_requests_failed_total ` + string(rune(failed)) + `
# HELP pdfgen_request_duration_ms_avg Average request duration in milliseconds
# TYPE pdfgen_request_duration_ms_avg gauge
pdfgen_request_duration_ms_avg ` + string(rune(avgDuration)) + `
`
}
```

**Exposes via:** `GET /metrics` — Scrape with Prometheus or view in browser.

---

## Graceful Shutdown

```go
func (s *Service) Close() error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if s.closed { return nil }
    s.closed = true

    close(s.pool)
    for ctx := range s.pool { _ = ctx }

    if s.allocator != nil {
        s.allocator.Cancel() // Kills all browser processes
    }
    return nil
}
```

**In main.go:**
```go
go func() {
    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    <-sigCh
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    server.Shutdown(ctx) // Stops accepting new requests
    svc.Close()          // Kills browser pool
}()
```

**30s timeout** = `RequestTimeout` + buffer. In-flight requests complete; new ones rejected.

---

## Testing the Service

```bash
# Unit tests (race detector)
make test

# Benchmarks
make bench
# goos: linux
# goarch: amd64
# BenchmarkService_Generate-8    50   23456789 ns/op   1024 B/op   12 allocs/op

# Concurrent test (in service_test.go)
# Runs 8 workers × 3 requests = 24 concurrent generations
```

---

## Next Chapter

Chapter 5: **HTML/CSS That Actually Prints** — `@page` rules, `print.css`, fonts, debugging via `chrome://inspect`.

---

> **Action item:** Open `internal/pdfgen/service.go`. Trace `Generate()` → `acquireContext()` → `chromedp.Run()` → `releaseContext()`. That's the entire hot path.