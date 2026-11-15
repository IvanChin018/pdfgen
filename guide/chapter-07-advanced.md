# Chapter 7: Advanced Features — TOC, Watermarks, PDF/A, Accessibility

> **TL;DR** — Features that separate "works" from "production-ready."

---

## Table of Contents Generation

**HTML structure:**
```html
<nav class="toc" id="toc">
    <h2>Table of Contents</h2>
    <ul>
        <li><a href="#chapter-1">Chapter 1: Introduction</a></li>
        <li><a href="#chapter-2">Chapter 2: Getting Started</a></li>
    </ul>
</nav>

<section id="chapter-1" class="chapter">...</section>
```

**CSS for TOC page:**
```css
@page toc { @top-center {}; @bottom-center { content: "Page " counter(page, lower-roman); } }
.toc-page { page: toc; page-break-after: always; }
.toc a::after { content: leader(".") target-counter(attr(href), page); }
```

**PDF bookmarks (outline):** Chromium auto-generates from `<h1>`-`<h6>`. Ensure semantic heading structure.

---

## Watermarks

**CSS-only (repeating):**
```css
@page {
    @top-center {
        content: "CONFIDENTIAL";
        font-size: 72pt;
        color: rgba(0,0,0,0.05);
        transform: rotate(-45deg);
        transform-origin: center;
        width: 100%; height: 100%;
        display: flex; align-items: center; justify-content: center;
        pointer-events: none;
        z-index: -1;
    }
}
```

**Per-page (different per page):** Use named pages + `@page name { @top-center { content: ... } }`

**Image watermark:**
```css
@page {
    background-image: url('watermark.png');
    background-repeat: no-repeat;
    background-position: center;
    background-size: 60%;
    opacity: 0.1;
}
```

---

## PDF/A-1b Compliance (Archival)

**Requirements:**
- All fonts embedded (subset OK)
- Color space: ICC profile (sRGB or CMYK)
- XMP metadata (title, author, creator, dates)
- No encryption, no JavaScript, no external refs
- Device-independent colors

**In pdfgen (via ChromeDP):**
```go
printOpts := []chromedp.PrintToPDFOption{
    // ... other options ...
    chromedp.PrintToPDFGenerateTaggedPDF(true),  // PDF/A-1b requires tagged
    chromedp.PrintToPDFGenerateDocumentOutline(true),
}
```

**ICC Profile:** Embed sRGB.icc via post-processing (pdfcpu) or ensure Chrome uses sRGB.

**XMP Metadata:** Not directly supported in ChromeDP PrintToPDF. Post-process with `pdfcpu`:
```go
pdfcpu.AddMetadata(pdfBytes, pdfcpu.Metadata{
    Title: "Invoice #123",
    Author: "Acme Corp",
    Subject: "Billing",
    Keywords: []string{"invoice", "pdf/a"},
    Producer: "pdfgen v0.1.0",
})
```

---

## Accessibility (Tagged PDF / PDF/UA)

**Tagged PDF** = semantic structure (headings, lists, tables, alt text) for screen readers.

**ChromeDP support:** `PrintToPDFGenerateTaggedPDF(true)` — generates tags from HTML semantics.

**Your HTML must be semantic:**
```html
<header><h1>Invoice</h1></header>
<nav><ul><li><a href="#items">Items</a></li></ul></nav>
<main>
    <section aria-labelledby="items-heading">
        <h2 id="items-heading">Line Items</h2>
        <table>
            <thead><tr><th scope="col">Item</th><th scope="col">Price</th></tr></thead>
            <tbody>...</tbody>
        </table>
    </section>
</main>
<footer><p>Page <span class="pageNumber"></span></p></footer>
```

**Alt text for images:** `<img src="logo.png" alt="Acme Corp logo">`

**Verify:** Open in Adobe Acrobat → View → Show/Hide → Navigation Panes → Tags. Or `pdfcpu validate -mode=accessibility file.pdf`

---

## Merging/Splitting (pdfcpu)

```go
import "github.com/pdfcpu/pdfcpu/pkg/api"

// Merge
pdfcpu.MergeCreateFile([]string{"cover.pdf", "content.pdf", "appendix.pdf"}, "merged.pdf")

// Split
pdfcpu.SplitFile("merged.pdf", "output_dir", 1, nil)  // 1 page per file

// Extract pages 3-5
pdfcpu.TrimFile("merged.pdf", "extracted.pdf", "3-5", nil)
```

**In pdfgen:** Add `/merge` endpoint that accepts multiple HTMLs → generates each → merges → returns single PDF.

---

## Next Chapter

Chapter 8: **Testing & CI** — Golden files, property tests, benchmarks, load testing.

---

> **Action item:** Enable `PrintToPDFGenerateTaggedPDF(true)`. Generate a PDF. Run `pdfcpu validate -mode=accessibility output.pdf`. Fix any HTML semantics issues.