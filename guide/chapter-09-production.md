# Chapter 9: Production Hardening — Security, Limits, Observability

> **TL;DR** — The difference between "it works" and "it runs for 2 years without pages."

---

## Security — Defense in Depth

### Container Hardening (Dockerfile)
```dockerfile
# Non-root user (distroless:nonroot = UID 65532)
USER nonroot:nonroot

# Read-only filesystem
# (No /tmp writes? Use --tmpfs /tmp in k8s)

# Drop all capabilities
# docker run --cap-drop=ALL ...

# Seccomp profile (Chrome needs some syscalls)
# docker run --security-opt seccomp=chrome-seccomp.json
```

### Chrome Flags — Minimal Attack Surface
```go
const secureChromeFlags = `
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
    --disable-web-security=false
    --allow-running-insecure-content=false
`
```

**Never enable:** `--disable-web-security`, `--allow-file-access-from-files`, `--remote-debugging-address=0.0.0.0`

### Input Validation
```go
func (s *Service) Generate(ctx context.Context, req GenerateRequest) ([]byte, error) {
    // Size limits
    if len(req.HTML) > 2_000_000 { // 2MB max HTML
        return nil, ErrHTMLTooLarge
    }
    if len(req.Options.HeaderHTML) > 50_000 {
        return nil, ErrHeaderTooLarge
    }
    if len(req.Options.FooterHTML) > 50_000 {
        return nil, ErrFooterTooLarge
    }

    // Sanitize: No <script>, no javascript: URLs
    if strings.Contains(strings.ToLower(req.HTML), "<script") {
        return nil, ErrScriptTagForbidden
    }
    // ... more validation
}
```

---

## Resource Limits

### Memory
```yaml
# Kubernetes
resources:
  limits:
    memory: "512Mi"  # PoolSize=4 → ~40MB × 4 + Go runtime + buffer
  requests:
    memory: "256Mi"
```

**Formula:** `PoolSize × 40MB + 100MB (Go) + 50MB (buffer)`

### CPU
```yaml
resources:
  limits:
    cpu: "500m"  # Half core per context? No — Chrome is bursty. 500m for PoolSize=4.
  requests:
    cpu: "250m"
```

### Timeouts
```go
ServiceConfig{
    RequestTimeout: 30 * time.Second,  // Per PDF
}

// HTTP server
server := &http.Server{
    ReadTimeout:  10 * time.Second,
    WriteTimeout: 35 * time.Second,  // RequestTimeout + 5s buffer
    IdleTimeout:  60 * time.Second,
}
```

### Concurrency Limit (Pool = Semaphore)
```go
// PoolSize = max concurrent PDFs
// Excess requests get temporary contexts (slower, but no queue)
// For strict queue: use semaphore before acquireContext
```

---

## Observability

### Structured Logging (zerolog)
```go
log.Info().
    Str("request_id", requestID).
    Str("page_size", req.Options.PageSize).
    Int("html_bytes", len(req.HTML)).
    Dur("duration", elapsed).
    Msg("PDF generated")

log.Error().
    Err(err).
    Str("request_id", requestID).
    Msg("PDF generation failed")
```

**Output (JSON):**
```json
{"level":"info","time":1699999999,"request_id":"abc123","page_size":"A4","html_bytes":5432,"duration_ms":234,"message":"PDF generated"}
```

### Prometheus Metrics
```go
// Exposes via GET /metrics
pdfgen_requests_total 1423
pdfgen_requests_success_total 1418
pdfgen_requests_failed_total 5
pdfgen_request_duration_ms_avg 1247
```

**Alerting rules:**
```yaml
- alert: PDFGenHighErrorRate
  expr: rate(pdfgen_requests_failed_total[5m]) / rate(pdfgen_requests_total[5m]) > 0.01
  for: 2m
  labels: { severity: warning }
  annotations:
    summary: "PDF generation error rate > 1%"

- alert: PDFGenHighLatency
  expr: histogram_quantile(0.99, rate(pdfgen_request_duration_ms_bucket[5m])) > 5000
  for: 5m
  labels: { severity: warning }
```

### Health Checks
```go
// GET /healthz
func (s *Service) Healthy() bool {
    s.mu.RLock()
    defer s.mu.RUnlock()
    return !s.closed
}

// Kubernetes probe
livenessProbe:
  httpGet: { path: /healthz, port: 8080 }
  initialDelaySeconds: 10
  periodSeconds: 30
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet: { path: /healthz, port: 8080 }
  initialDelaySeconds: 5
  periodSeconds: 10
```

---

## Graceful Degradation

### Circuit Breaker (Simple)
```go
var consecutiveFailures int32
const maxFailures = 10

func (s *Service) Generate(ctx context.Context, req GenerateRequest) ([]byte, error) {
    if atomic.LoadInt32(&consecutiveFailures) >= maxFailures {
        return nil, ErrCircuitOpen
    }
    pdf, err := s.generateInternal(ctx, req)
    if err != nil {
        atomic.AddInt32(&consecutiveFailures, 1)
        return nil, err
    }
    atomic.StoreInt32(&consecutiveFailures, 0)
    return pdf, nil
}
```

### Fallback: Static Error PDF
```go
var errorPDF = []byte("%PDF-1.4\n%Error generating PDF\n%%EOF")

func pdfHandler(svc *Service) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        pdf, err := svc.Generate(ctx, req)
        if err != nil {
            if errors.Is(err, ErrCircuitOpen) {
                w.Header().Set("Content-Type", "application/pdf")
                w.WriteHeader(http.StatusServiceUnavailable)
                w.Write(errorPDF)  // Valid PDF with error message
                return
            }
            http.Error(w, err.Error(), http.StatusInternalServerError)
            return
        }
        w.Header().Set("Content-Type", "application/pdf")
        w.Write(pdf)
    }
}
```

---

## Deployment Checklist

- [ ] Container runs as non-root (UID 65532)
- [ ] Read-only rootfs (or `--read-only` + `--tmpfs /tmp`)
- [ ] Seccomp profile applied
- [ ] Resource limits set (memory, CPU)
- [ ] `CHROME_FLAGS` hardened (no `--disable-web-security`)
- [ ] Input size limits enforced
- [ ] Request timeout < HTTP write timeout
- [ ] Prometheus scraping `/metrics`
- [ ] Liveness/readiness probes configured
- [ ] Logs structured (JSON) → Loki/Elastic
- [ ] Circuit breaker / fallback PDF
- [ ] Load tested at 2× expected peak

---

## Next Chapter

Chapter 10: **Real-World Recipes** — Invoice, Certificate, Multi-page Report, Shipping Label. Copy-paste ready.

---

> **Action item:** Deploy to staging. Run `hey -n 500 -c 20 ...`. Check p99, error rate, memory. Tune `PoolSize` and resource limits.