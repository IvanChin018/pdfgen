# Chapter 5: HTML/CSS That Actually Prints

> **TL;DR** — Screen CSS ≠ Print CSS. This chapter covers the exact CSS you need for professional PDFs.

---

## The Print Media Query

```css
@media print {
    /* Hide screen-only elements */
    .no-print { display: none !important; }

    /* Reset for print */
    body { font-size: 11pt; line-height: 1.5; color: #000; }

    /* Ensure backgrounds print */
    * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
}
```

**Always wrap print-specific styles in `@media print`.** Screen styles (animations, hover states, dark mode) will leak into PDF otherwise.

---

## @page Rules — The Foundation

```css
@page {
    size: A4;                    /* A4, Letter, Legal, A5, or "210mm 297mm" */
    margin: 20mm;                /* All margins */
    margin-top: 25mm;            /* Individual */
    margin-bottom: 30mm;         /* Leave room for footer */

    /* Headers/footers via running elements */
    @top-left { content: element(header-left); }
    @top-center { content: element(header-center); }
    @top-right { content: element(header-right); }
    @bottom-left { content: element(footer-left); }
    @bottom-center { content: element(footer-center); }
    @bottom-right { content: element(footer-right); }
}
```

**Page margins** must accommodate your running headers/footers. If header is 15px tall, `margin-top: 25mm` minimum.

---

## Running Elements — Headers/Footers That Work

```css
/* Define the running elements */
header.running-header {
    position: running(header-center);
    font-size: 8pt;
    color: #666;
    width: 100%;
    text-align: center;
    border-bottom: 0.5pt solid #ddd;
    padding-bottom: 4pt;
}

footer.running-footer {
    position: running(footer-center);
    font-size: 8pt;
    color: #666;
    width: 100%;
    text-align: center;
    border-top: 0.5pt solid #ddd;
    padding-top: 4pt;
}

/* Page counters */
footer.running-footer::before {
    content: "Page " counter(page) " of " counter(pages);
}
```

**In HTML:**
```html
<header class="running-header">My Document Title</header>
<footer class="running-footer"></footer>
```

**Result:** Header/footer on **every page**, page numbers auto-updated.

---

## Named Pages — Different Layouts Per Section

```css
@page cover { margin: 0; @top-center {}; @bottom-center {}; }
@page content { margin: 20mm; }
@page appendix { margin: 25mm; }

.cover-page { page: cover; }
.main-content { page: content; }
.appendix-page { page: appendix; }
```

**Use cases:** Cover page (no margins, no header), TOC (roman numerals), Content (arabic), Appendix (different margins).

---

## Page Breaks — Control the Flow

```css
/* Avoid breaking inside these */
.card, .invoice-row, table, pre, blockquote {
    page-break-inside: avoid;
}

/* Force break before */
.chapter-start, .new-section {
    page-break-before: always;
}

/* Force break after */
.page-end {
    page-break-after: always;
}

/* Orphan/widow control */
p { orphans: 3; widows: 3; }
```

**Table rows** — `tr { page-break-inside: avoid; }` keeps rows together.

---

## Fonts — Embedding for Portability

```css
/* Self-hosted (recommended) */
@font-face {
    font-family: 'Inter';
    src: url('fonts/Inter-Regular.woff2') format('woff2');
    font-weight: 400;
    font-display: block;
}

@font-face {
    font-family: 'Inter';
    src: url('fonts/Inter-Medium.woff2') format('woff2');
    font-weight: 500;
    font-display: block;
}

/* Google Fonts (SIL/OFL — free for commercial) */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=block');
```

**Critical:** `font-display: block` — prevents FOIT (Flash of Invisible Text) during print rendering.

**CJK/RTL:** Add Noto Sans SC/JP/KR, Noto Sans Arabic. Font files ~2-5MB each.

---

## Print-Optimized CSS Reset

```css
@media print {
    *, *::before, *::after {
        box-sizing: border-box;
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
    }

    html { font-size: 11pt; }
    body { margin: 0; padding: 0; }

    /* Remove shadows, animations, transforms */
    * {
        text-shadow: none !important;
        box-shadow: none !important;
        animation: none !important;
        transition: none !important;
        transform: none !important;
    }

    /* Links — show URLs */
    a[href]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: #666; }
    a[href^="#"]::after { content: ""; } /* Skip internal links */

    /* Images — don't split across pages */
    img { max-width: 100% !important; page-break-inside: avoid; }

    /* Tables */
    thead { display: table-header-group; }
    tr { page-break-inside: avoid; }
}
```

---

## Debugging — See What Chrome Sees

```bash
# Run container with debug port
docker run -p 9222:9222 -p 8080:8080 pdfgen:latest

# Open Chrome on host
# Navigate to: chrome://inspect
# Click "inspect" on the headless-shell target
```

**In DevTools:**
- Console: `document.body.innerHTML` — see injected header/footer
- Elements: Inspect `@page` rules in Styles panel
- Network: Verify font loads
- Rendering: Emulate `print` media type

---

## Sample Print CSS (Copy-Paste Ready)

```css
/* print.css — include in your HTML <head> */
@media print {
    @page {
        size: A4;
        margin: 20mm 20mm 30mm;
        @top-center { content: element(header); }
        @bottom-center { content: element(footer); }
    }

    header { position: running(header); font-size: 8pt; color: #666; border-bottom: 0.5pt solid #ddd; padding-bottom: 4pt; text-align: center; width: 100%; }
    footer { position: running(footer); font-size: 8pt; color: #666; border-top: 0.5pt solid #ddd; padding-top: 4pt; text-align: center; width: 100%; }
    footer::before { content: "Page " counter(page) " of " counter(pages); }

    body { font-family: 'Inter', system-ui, sans-serif; font-size: 11pt; line-height: 1.5; color: #000; }

    .no-print { display: none !important; }

    h1, h2, h3 { page-break-after: avoid; }
    table, pre, .card, .invoice-row { page-break-inside: avoid; }
    thead { display: table-header-group; }
    tr { page-break-inside: avoid; }

    a[href^="http"]::after { content: " (" attr(href) ")"; font-size: 0.8em; color: #666; }

    * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
}
```

---

## Next Chapter

Chapter 6: **Headers/Footers Deep Dive** — Dynamic data, conditional headers, page number formats, troubleshooting drift.

---

> **Action item:** Add `<link rel="stylesheet" href="print.css" media="print">` to your HTML. Generate a PDF. Check header/footer alignment.