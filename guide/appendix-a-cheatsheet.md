# Appendix A: Cheatsheet — @page, CSS Print, ChromeDP

---

## @page Properties Quick Reference

| Property | Values | Description |
|----------|--------|-------------|
| `size` | `A4`, `Letter`, `Legal`, `A5`, `A3`, `auto`, `landscape`, `portrait`, `210mm 297mm` | Page size |
| `margin` | `20mm`, `1in`, `2cm` | All margins |
| `margin-top` / `margin-right` / `margin-bottom` / `margin-left` | Length | Individual margins |
| `marks` | `crop`, `cross`, `none` | Registration marks |
| `bleed` | Length | Bleed area |

---

## @page Margin Boxes (16 boxes)

```
@top-left-corner   @top-left   @top-center   @top-right   @top-right-corner
@left-top          @left-middle @left-bottom
@right-top         @right-middle @right-bottom
@bottom-left-corner @bottom-left @bottom-center @bottom-right @bottom-right-corner
```

**Usage:**
```css
@page {
    @top-center { content: element(header); }
    @bottom-center { content: "Page " counter(page); }
    @bottom-right { content: "Confidential"; font-size: 8pt; color: #999; }
}
```

---

## Running Elements (Headers/Footers)

```css
/* Define */
header { position: running(header); }
footer { position: running(footer); }

/* Use in @page */
@page {
    @top-center { content: element(header); }
    @bottom-center { content: element(footer); }
}
```

**Properties on running elements:**
- Fixed height recommended: `height: 18px;`
- Full width: `width: 100%;`
- Text align: `text-align: center;`

---

## CSS Counters

```css
/* Page counter */
counter(page)           /* Current page */
counter(pages)          /* Total pages (Chromium) */

/* Chapter counter */
.chapter { counter-increment: chapter; }
.chapter::before { content: "Chapter " counter(chapter) ". "; }

/* Nested */
.section { counter-increment: section; }
.section::before { content: counter(chapter) "." counter(section) " "; }

/* Styles */
counter(page, lower-roman)    /* i, ii, iii */
counter(page, upper-roman)    /* I, II, III */
counter(page, lower-alpha)    /* a, b, c */
```

---

## Page Break Properties

| Property | Values | Use On |
|----------|--------|--------|
| `page-break-before` | `auto`, `always`, `avoid`, `left`, `right`, `inherit` | Block elements |
| `page-break-after` | `auto`, `always`, `avoid`, `left`, `right`, `inherit` | Block elements |
| `page-break-inside` | `auto`, `avoid`, `inherit` | Block elements (tables, cards, pre) |
| `break-before` | `page`, `column`, `avoid-page`, `avoid-column` | Modern alias |
| `break-after` | `page`, `column`, `avoid-page`, `avoid-column` | Modern alias |
| `break-inside` | `avoid-page`, `avoid-column`, `auto` | Modern alias |

**Best practice:** Use `break-inside: avoid` (modern) + `page-break-inside: avoid` (fallback).

---

## Print Media Query

```css
@media print {
    /* Hide screen UI */
    .no-print, nav, .sidebar, .btn, .toolbar { display: none !important; }

    /* Force backgrounds */
    * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }

    /* Reset */
    body { font-size: 11pt; line-height: 1.5; color: #000; background: #fff; }

    /* Links */
    a[href^="http"]::after { content: " (" attr(href) ")"; font-size: 0.85em; color: #666; }
    a[href^="#"]::after { content: ""; }

    /* Images */
    img { max-width: 100% !important; page-break-inside: avoid; }

    /* Tables */
    thead { display: table-header-group; }
    tr { page-break-inside: avoid; }
}
```

---

## ChromeDP PrintToPDF Options

```go
chromedp.PrintToPDF(&pdfBuf,
    chromedp.PrintToPDFPaperWidth(8.27),      // inches
    chromedp.PrintToPDFPaperHeight(11.69),
    chromedp.PrintToPDFMarginTop(0.787),      // inches (20mm)
    chromedp.PrintToPDFMarginBottom(0.787),
    chromedp.PrintToPDFMarginLeft(0.787),
    chromedp.PrintToPDFMarginRight(0.787),
    chromedp.PrintToPDFLandscape(false),
    chromedp.PrintToPDFPrintBackground(true),
    chromedp.PrintToPDFPreferCSSPageSize(true),
    chromedp.PrintToPDFScale(1.0),
    chromedp.PrintToPDFGenerateTaggedPDF(true),      // PDF/A, accessibility
    chromedp.PrintToPDFGenerateDocumentOutline(true), // Bookmarks
)
```

**Units:** All dimensions in **inches**. Convert mm: `mm / 25.4`.

---

## Common Page Sizes (inches)

| Size | Width × Height | mm |
|------|----------------|-----|
| A4 | 8.27 × 11.69 | 210 × 297 |
| Letter | 8.5 × 11.0 | 216 × 279 |
| Legal | 8.5 × 14.0 | 216 × 356 |
| A5 | 5.83 × 8.27 | 148 × 210 |
| A3 | 11.69 × 16.54 | 297 × 420 |
| 4×6 Label | 4.0 × 6.0 | 101.6 × 152.4 |

---

## Chrome Flags Reference

| Flag | Effect | Production? |
|------|--------|-------------|
| `--no-sandbox` | Required in containers | ✅ Yes |
| `--disable-gpu` | No GPU process | ✅ Yes |
| `--disable-dev-shm-usage` | Use /tmp not /dev/shm | ✅ Yes |
| `--disable-extensions` | No extensions | ✅ Yes |
| `--disable-background-networking` | No phoning home | ✅ Yes |
| `--disable-web-security` | **DANGEROUS** | ❌ Never |
| `--allow-file-access-from-files` | **DANGEROUS** | ❌ Never |
| `--remote-debugging-port=9222` | Enable DevTools | 🔧 Debug only |
| `--headless=new` | New headless mode (Chrome 112+) | ✅ Default in headless-shell |

---

## Debugging Commands

```bash
# Inspect running container
docker run -p 9222:9222 pdfgen:latest
# Open chrome://inspect in host Chrome

# Generate PDF with verbose logging
./pdfgen -log-level=debug sample --output debug.pdf

# Check PDF structure
pdfinfo output.pdf
pdffonts output.pdf
pdfimages -list output.pdf

# Validate PDF/A
pdfcpu validate -mode=pdfa output.pdf

# Validate accessibility
pdfcpu validate -mode=accessibility output.pdf
```

---

## Unit Conversions

```go
func mmToInches(mm float64) float64 { return mm / 25.4 }
func inchesToMm(in float64) float64 { return in * 25.4 }
func ptToInches(pt float64) float64 { return pt / 72.0 }
```

| From | To | Formula |
|------|-----|---------|
| mm | inches | `mm / 25.4` |
| inches | mm | `inches * 25.4` |
| pt | inches | `pt / 72` |
| px (96 DPI) | inches | `px / 96` |
| px (96 DPI) | mm | `px * 25.4 / 96` |

---

## Quick HTML Template

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>{{.Title}}</title>
  <style>
    @media print {
      @page { size: A4; margin: 20mm; @top-center { content: element(h); } @bottom-center { content: element(f); } }
      header { position: running(h); font-size: 8pt; color: #666; border-bottom: 1px solid #ddd; padding-bottom: 4pt; text-align: center; width: 100%; }
      footer { position: running(f); font-size: 8pt; color: #666; border-top: 1px solid #ddd; padding-top: 4pt; text-align: center; width: 100%; }
      footer::before { content: "Page " counter(page) " of " counter(pages); }
      body { font-family: system-ui, sans-serif; font-size: 11pt; line-height: 1.5; }
      .no-print { display: none !important; }
      * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    }
  </style>
</head>
<body>
  <header>{{.Header}}</header>
  <footer></footer>
  <main>{{.Content}}</main>
</body>
</html>
```