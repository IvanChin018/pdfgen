# Appendix C: Troubleshooting Index

> **TL;DR** — Every PDF bug I've hit, with the fix. Search by symptom.

---

## Blank / White Pages

| Symptom | Cause | Fix |
|---------|-------|-----|
| Entire PDF blank | HTML not loaded | Add `chromedp.WaitReady("body")` before `PrintToPDF` |
| First page blank | Margin too small | Increase `@page { margin-top }` |
| Random blank pages | `page-break-before: always` on first element | Remove or guard with `:not(:first-child)` |
| Last page blank | Footer height > margin-bottom | Increase `margin-bottom` or reduce footer height |

---

## Header/Footer Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Header missing on page 2+ | `position: running()` not in `@media print` | Wrap header/footer CSS in `@media print` |
| Header cuts off | `margin-top` < header height | `margin-top: header-height + 4mm` |
| Footer overlaps content | `margin-bottom` < footer height | `margin-bottom: footer-height + 4mm` |
| Page numbers wrong | Multiple `@page` rules | Use named pages (`@page name`) consistently |
| Header on cover page | `@page :first` not defined | Add `@page :first { @top-center { content: none; } }` |
| Drift (misaligned) | Dynamic header height | Fixed `height: 18px` on header/footer |

---

## Font Problems

| Symptom | Cause | Fix |
|---------|-------|-----|
| Missing glyphs (□) | Font not embedded / subset missing char | Subset with required chars; use Noto for CJK |
| Wrong font (fallback) | `@font-face` not loaded | `font-display: block`; self-host; check `fc-list` in container |
| Bold/italic not working | Variable font weight axis | Use `font-weight: 100 900` in `@font-face`; verify `font-variation-settings` |
| Emoji not colored | No color emoji font | Install `noto-color-emoji`; verify `pdffonts` shows it |

---

## Layout / CSS

| Symptom | Cause | Fix |
|---------|-------|-----|
| Table splits mid-row | `page-break-inside: auto` | `tr { break-inside: avoid; page-break-inside: avoid; }` |
| Flex/Grid broken | Print media resets | Wrap layout CSS in `@media print` or use `@media screen` for screen-only |
| Background missing | `print-color-adjust` | `* { -webkit-print-color-adjust: exact; print-color-adjust: exact; }` |
| Text cut at page edge | No margin / overflow | Adequate `@page margin`; `overflow: visible` |
| Images huge | No max-width | `img { max-width: 100% !important; }` |

---

## ChromeDP / Generation Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `context deadline exceeded` | Generation > `RequestTimeout` | Increase timeout; optimize HTML (remove heavy JS) |
| `target closed` / `context canceled` | Browser crashed / OOM | Increase container memory; reduce pool size; check `--disable-dev-shm-usage` |
| `navigation error` | `SetHTMLContent` failed | HTML too large (>2MB); invalid charset; add `<meta charset="utf-8">` |
| `print to pdf failed` | Chrome internal error | Update headless-shell; check Chrome flags; simplify CSS |
| `pool exhausted` | All contexts busy | Increase `PoolSize`; add circuit breaker; check for context leaks |

---

## Docker / Container

| Symptom | Cause | Fix |
|---------|-------|-----|
| `exec format error` | Arch mismatch | Build multi-arch: `--platform=linux/amd64,linux/arm64` |
| `permission denied` | Non-root user can't write | `--tmpfs /tmp` in k8s; or `USER root` for specific dirs |
| Fontconfig warnings | Font cache missing | `fc-cache -f` in builder; copy `/etc/fonts` to runtime |
| OOM killed | Memory limit too low | Increase limit: `PoolSize × 40MB + 150MB` |
| Slow startup (>10s) | No warmup | Call `warmup()` in `NewService`; pre-navigate to `about:blank` |

---

## PDF Output Validation

| Check | Command | Pass Criteria |
|-------|---------|---------------|
| Valid PDF | `pdfinfo file.pdf` | Returns metadata, no errors |
| Fonts embedded | `pdffonts file.pdf` | All `emb=yes` |
| Page count | `pdfinfo file.pdf \| grep Pages` | Expected count |
| PDF/A compliance | `pdfcpu validate -mode=pdfa file.pdf` | No errors |
| Accessibility | `pdfcpu validate -mode=accessibility file.pdf` | No errors |
| File size | `ls -lh file.pdf` | < 500KB for text, < 5MB for images |

---

## Performance Debugging

```go
// Add to Generate() for timing breakdown
start := time.Now()
defer func() {
    log.Debug().
        Dur("total", time.Since(start)).
        Dur("acquire", acquireDur).
        Dur("navigate", navDur).
        Dur("html", htmlDur).
        Dur("print", printDur).
        Msg("PDF generation timing")
}()
```

**Typical breakdown (A4, simple HTML):**
- Acquire context: 0.5ms
- Navigate: 15ms
- Set HTML: 5ms
- Wait ready: 10ms
- PrintToPDF: 80ms
- **Total: ~110ms**

**If PrintToPDF > 500ms:** Complex CSS (many elements, shadows, filters). Simplify.

---

## Common Fixes Checklist

- [ ] HTML has `<meta charset="utf-8">`
- [ ] CSS in `@media print { ... }`
- [ ] `@page` margins ≥ header/footer height + 4mm
- [ ] `break-inside: avoid` on tables, cards, pre
- [ ] Fonts self-hosted, SIL OFL, subsetted
- [ ] `font-display: block` in `@font-face`
- [ ] `PrintToPDFPrintBackground(true)` for header/footer backgrounds
- [ ] `PrintToPDFPreferCSSPageSize(true)` for `@page size`
- [ ] Container memory ≥ `PoolSize × 40MB + 150MB`
- [ ] Chrome flags include `--disable-dev-shm-usage`
- [ ] Request timeout < HTTP write timeout
- [ ] Golden file tests for critical templates

---

## Still Stuck?

1. **Generate minimal reproduction** — Strip HTML to smallest failing case
2. **Enable debug logging** — `-log-level=debug`
3. **Inspect in DevTools** — `chrome://inspect` on port 9222
4. **Check Chrome version** — `headless-shell --version` matches Dockerfile
5. **Search issues** — `github.com/chromedp/chromedp/issues`
6. **Ask** — GitHub Discussions on pdfgen repo

---

> **Remember:** 90% of PDF bugs are CSS (`@page` margins, `break-inside`, `@media print`). Fix CSS first.