# Chapter 8: Testing & CI — Golden Files, Property Tests, Benchmarks, Load

> **TL;DR** — PDF testing is hard. This chapter gives you a practical strategy.

---

## Test Pyramid for PDF Generation

```
         ┌─────────────┐
         │  E2E (1)    │  Full HTTP → PDF → pixel diff
        ┌┴─────────────┴┐
       │ Integration (3)│  Service.Generate → PDF structure
      ┌┴────────────────┴┐
     │  Unit (10+)       │  Options parsing, margin calc, pool logic
    ┌┴────────────────────┴┐
   └────────────────────────┘
```

---

## Unit Tests (Fast, No Chrome)

```go
func TestBuildPrintOptions(t *testing.T) {
    svc := &Service{}
    opts := Options{
        PageSize: "A4",
        Margins: Margins{Top: "25mm", Right: "20mm", Bottom: "25mm", Left: "20mm"},
        Landscape: true,
        Scale: 0.9,
    }
    printOpts := svc.buildPrintOptions(opts)
    // Assert paper width/height, margins, landscape, scale
}
```

**Run:** `make test` — no Chrome needed.

---

## Integration Tests (With Chrome)

```go
func TestService_Generate(t *testing.T) {
    svc, _ := NewService(ServiceConfig{PoolSize: 2, RequestTimeout: 10*time.Second})
    defer svc.Close()

    ctx := context.Background()
    req := GenerateRequest{
        HTML: `<html><body><h1>Test</h1></body></html>`,
        Options: DefaultOptions(),
    }
    pdf, err := svc.Generate(ctx, req)
    require.NoError(t, err)
    require.True(t, len(pdf) > 1000)
    assert.Equal(t, "%PDF", string(pdf[:4]))
}
```

**Run:** `make test` — requires Chrome/Chromium installed.

---

## Golden File Tests (Pixel-Perfect Regression)

**Concept:** Store reference PDF → compare new output pixel-by-pixel.

```go
func TestGoldenFiles(t *testing.T) {
    svc, _ := NewService(ServiceConfig{PoolSize: 1})
    defer svc.Close()

    testCases := []struct{
        name string
        html string
        opts Options
    }{
        {"simple", "<h1>Hello</h1>", DefaultOptions()},
        {"with-header", "<h1>Hello</h1>", Options{HeaderHTML: "<header>H</header>"}},
        {"landscape", "<h1>Wide</h1>", Options{Landscape: true}},
    }

    for _, tc := range testCases {
        t.Run(tc.name, func(t *testing.T) {
            pdf, _ := svc.Generate(context.Background(), GenerateRequest{HTML: tc.html, Options: tc.opts})
            
            // Write to temp
            tmp := filepath.Join(t.TempDir(), tc.name+".pdf")
            os.WriteFile(tmp, pdf, 0644)
            
            // Compare with golden (if exists)
            golden := filepath.Join("testdata", "expected", tc.name+".pdf")
            if _, err := os.Stat(golden); err == nil {
                diff, err := pdfdiff.Compare(golden, tmp)
                require.NoError(t, err)
                assert.Equal(t, 0.0, diff, "PDF differs from golden: %f%%", diff*100)
            } else {
                t.Logf("Golden not found: %s (run with -update-golden to create)", golden)
            }
        })
    }
}
```

**pdfdiff** (or `go-pdfdiff`): Renders both PDFs to images, compares pixel differences.

**Update goldens:** `go test -run TestGoldenFiles -update-golden ./...`

---

## Property-Based Tests

```go
func TestGenerate_Properties(t *testing.T) {
    svc, _ := NewService(ServiceConfig{PoolSize: 2})
    defer svc.Close()

    // Property: Valid HTML always produces valid PDF header
    quick.Check(func(html string) bool {
        pdf, err := svc.Generate(context.Background(), GenerateRequest{
            HTML: html, Options: DefaultOptions(),
        })
        if err != nil { return true } // Ignore generation errors
        return len(pdf) >= 4 && string(pdf[:4]) == "%PDF"
    }, nil)
}
```

**Run:** `go test -run TestGenerate_Properties -count=100 ./...`

---

## Benchmarks

```go
func BenchmarkService_Generate(b *testing.B) {
    svc, _ := NewService(ServiceConfig{PoolSize: 4})
    defer svc.Close()

    req := GenerateRequest{
        HTML: benchmarkHTML(), // ~5KB HTML
        Options: DefaultOptions(),
    }

    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            _, _ = svc.Generate(context.Background(), req)
        }
    })
}
```

**Run:** `make bench`
```
BenchmarkService_Generate-8    50   23456789 ns/op   1024 B/op   12 allocs/op
```

**Track:** ns/op, B/op, allocs/op over commits. Regressions = investigate.

---

## Load Testing

```bash
# Build release binary
make build

# Start server
./bin/pdfgen -port=8080 -pool=8 &

# Load test with hey
hey -n 1000 -c 10 -m POST \
  -H "Content-Type: application/json" \
  -d '{"html":"<h1>Load</h1>","options":{"page_size":"A4"}}' \
  http://localhost:8080/pdf

# Results:
# Summary:
#   Total:    12.34 secs
#   Slowest:  2.34 secs
#   Fastest:  0.08 secs
#   Average:  0.12 secs
#   Requests/sec: 81.02
#   ...
```

**CI Integration:** Run nightly. Alert if p99 > 2s or error rate > 0.5%.

---

## CI Pipeline (Recap)

```yaml
# .github/workflows/ci.yml
test:
  - make test          # Unit + integration
  - make bench         # Benchmarks (fail if >20% regression)

build:
  - make build         # Binary

docker:
  - make docker        # Multi-arch image
  - docker run ... make pdf-sample  # Smoke test in container
```

---

## Next Chapter

Chapter 9: **Production Hardening** — Security, resource limits, observability, graceful degradation.

---

> **Action item:** Add `testdata/expected/simple.pdf` (run test with `-update-golden`). Commit. Break HTML → watch test fail.