# Chapter 6: Headers/Footers Deep Dive

> **TL;DR** — The #1 PDF pain point. This chapter solves it completely.

---

## The Running Element Pattern (Recap)

```css
@page {
    @top-center { content: element(header); }
    @bottom-center { content: element(footer); }
}
header { position: running(header); }
footer { position: running(footer); }
```

**Injected via Go** (see Chapter 4 `injectHeaderFooter`):
```go
headerHTML := `<header>Invoice #{{.Invoice.Number}} | {{.Date}}</header>`
footerHTML := `<footer>Page <span class="pageNumber"></span> of <span class="totalPages"></span></footer>`
```

---

## Dynamic Data in Headers/Footers

**Option 1: Template in Go, inject full HTML**
```go
type HeaderData struct {
    InvoiceNumber string
    Date          string
    CompanyName   string
}

tmpl := template.Must(template.New("header").Parse(`
<header>{{.CompanyName}} • Invoice {{.InvoiceNumber}} • {{.Date}}</header>
`))
var buf bytes.Buffer
tmpl.Execute(&buf, HeaderData{...})
req.Options.HeaderHTML = buf.String()
```

**Option 2: CSS variables + JS injection**
```go
script := fmt.Sprintf(`
    document.documentElement.style.setProperty('--invoice-number', %q);
    document.documentElement.style.setProperty('--date', %q);
`, invoice.Number, invoice.Date)
chromedp.Evaluate(script, nil).Do(ctx)
```
```css
header::before { content: var(--invoice-number); }
```

**Option 1 is simpler and more reliable.** Use Option 2 only for runtime-computed values.

---

## Page Number Formats

```css
/* Default: 1, 2, 3... */
footer::before { content: "Page " counter(page); }

/* Roman numerals for TOC */
.toc-page { page: toc; }
@page toc {
    @bottom-center { content: "Page " counter(page, lower-roman); }
}

/* Chapter-relative: 1-1, 1-2, 2-1... */
@page chapter {
    @bottom-center { content: "Page " counter(chapter) "-" counter(page); }
}
.chapter-start { counter-increment: chapter; counter-reset: page; }
```

---

## Conditional Headers (First Page Different)

```css
@page :first {
    @top-center { content: none; }  /* No header on first page */
    @bottom-center { content: element(footer-first); }
}

footer.first-page { position: running(footer-first); }
```

**In Go:** Inject different footer for first page via conditional logic.

---

## Header/Footer Height → Margin Calculation

**Rule:** `margin-top >= header height + 4mm buffer`

```css
header { height: 18px; }  /* ~12pt + border + padding */
@page { margin-top: 25mm; }  /* 25mm ≈ 71pt > 18px + buffer */
```

**Measure in DevTools:** `chrome://inspect` → Elements → header → Computed → height.

---

## Common Drift Causes & Fixes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Header cuts off | `margin-top` too small | Increase `margin-top` in `@page` |
| Footer overlaps content | `margin-bottom` too small | Increase `margin-bottom` |
| Page numbers wrong | Multiple `@page` rules conflict | Use named pages, single `@page` per type |
| Header missing on page 2 | `position: running()` not in print media | Wrap in `@media print` |
| Content jumps | Dynamic header height | Fixed height header (`height: 18px`) |

---

## Debugging Checklist

```bash
# 1. Generate PDF with debug HTML
curl -X POST localhost:8080/pdf -d '{"html": "...", "options": {"header_html": "<header>DEBUG</header>"}}' -o debug.pdf

# 2. Inspect in container
docker run -p 9222:9222 pdfgen:latest
# chrome://inspect → inspect → Console:
document.querySelector('header').outerHTML
getComputedStyle(document.querySelector('header')).height
```

---

## Next Chapter

Chapter 7: **Advanced Features** — TOC, watermarks, PDF/A-1b, accessibility, merging/splitting.

---

> **Action item:** Add `height: 18px` to your header CSS. Set `margin-top: 25mm`. Generate 5-page PDF. Verify header on every page.