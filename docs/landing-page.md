# Landing Page: "Bulletproof PDF Generation in Go"

---

## Hero

**Headline:** Generate Professional PDFs from HTML/CSS in Go — No Brittle Hacks, No 500MB Containers

**Subhead:** A production-ready guide + complete source code for building a PDF service that handles pagination, headers/footers, Unicode, PDF/A compliance, and runs in a 20MB scratch container.

**CTA:** [Get the Guide for $29] → Gumroad

**Trust signals:**
- ✅ 200+ lines of production Go code included
- ✅ Dockerfile + GitHub Actions CI/CD ready
- ✅ Tested in real billing/invoicing systems
- ✅ Free updates for v1.x

---

## The Problem

You need PDFs in your Go backend. Invoices, reports, certificates, shipping labels.

**What you've tried:**
| Approach | Reality |
|----------|---------|
| `wkhtmltopdf` | Dead project. QtWebKit bugs. No CSS Grid/Flex. Container = 500MB+. |
| `chromedp` / Puppeteer | Works, but 1GB+ images. Flaky in CI. Headless-shell helps but undocumented. |
| `gofpdf` / `pdfcpu` | Manual layout = hours of coordinate math. No HTML/CSS. |
| Commercial APIs (DocRaptor, PDFShift) | $0.10–$0.50/page. Latency. Vendor lock-in. Data leaves your infra. |

**Result:** You waste days debugging pagination, header drift, missing fonts, CI timeouts — or you pay forever.

---

## The Solution

**This guide teaches you to build your own PDF service** — one you own, control, and run for pennies.

### What You'll Build

A **complete, production-ready PDF microservice** (~200 LOC) that:

- ✅ Renders **full HTML/CSS** → PDF (Grid, Flex, custom fonts, `print.css`)
- ✅ **Perfect pagination** — headers/footers that never drift, page counters, TOC
- ✅ **Tiny containers** — 20MB scratch image with headless-shell (no Chromium bloat)
- ✅ **Unicode & RTL** — Arabic, Hebrew, CJK, emoji — just works
- ✅ **PDF/A-1b & accessibility** — tagged PDF, embedded fonts, ICC profiles
- ✅ **Observability built-in** — Prometheus metrics, structured logging, health checks
- ✅ **CI/CD ready** — GitHub Actions → goreleaser → multi-arch Docker images

### What's Inside

| Section | Pages | What You Get |
|---------|-------|--------------|
| 1. The Landscape | 4 | Honest comparison of every Go PDF approach |
| 2. Picking Your Stack | 3 | Decision matrix + recommendation |
| 3. Project Setup | 5 | `go.mod`, `Dockerfile`, `Makefile`, CI pipeline |
| 4. Core Service | 8 | Complete `pdfgen.go` with pooling, timeouts, metrics |
| 5. HTML/CSS That Prints | 10 | `@page`, `print.css`, fonts, debugging |
| 6. Headers/Footers | 6 | CSS `running()` elements, dynamic data, counters |
| 7. Advanced Features | 8 | TOC, watermarks, PDF/A, accessibility, merging |
| 8. Testing & CI | 6 | Golden files, property tests, benchmarks, load testing |
| 9. Production Hardening | 7 | Security, graceful shutdown, resource limits |
| 10. Real-World Recipes | 10 | Invoice, certificate, report, shipping label (copy-paste) |
| **Appendices** | 5 | Cheatsheet, font licensing, troubleshooting index |

**Total: ~72 pages of dense, zero-fluff content + complete source code.**

---

## Sample Chapter: "Headers/Footers That Don't Drift"

> Most guides skip this. It's where PDF projects die.
>
> The trick: **CSS `position: running()` / `element()`** — supported in Chromium's print engine.
>
> ```css
> @page {
>   @top-center { content: element(header); }
>   @bottom-center { content: element(footer); }
> }
> header { position: running(header); }
> footer { position: running(footer); }
> ```
>
> Inject header/footer HTML via ChromeDP, and they repeat on **every page** — perfectly aligned, with dynamic page numbers:
>
> ```html
> <footer>Page <span class="pageNumber"></span> of <span class="totalPages"></span></footer>
> ```
>
> The guide shows the exact Go code to inject this, handle dynamic data (invoice #, date, user), and debug via `chrome://inspect` on the container.

---

## Who This Is For

- **Go backend developers** generating invoices, reports, certificates, labels
- **Teams migrating off** `wkhtmltopdf`, Puppeteer, or commercial APIs
- **Anyone who's hit**: pagination bugs, header/footer drift, font embedding failures, CI flakes, container size limits

**Not for:** Frontend-only devs, people wanting a no-code tool, or those happy paying $0.50/page forever.

---

## Pricing

| Tier | Price | Includes |
|------|-------|----------|
| **Guide Only** | **$29** | PDF guide (72 pg) + complete source code (MIT) + sample PDFs |
| **Guide + Private Repo** | **$59** | Above + private GitHub repo access (issues, PRs, updates) |
| **Team License (5 seats)** | **$149** | Guide + repo + team can fork/modify for internal use |

**Early bird:** First 50 buyers get **$19** (Guide Only) / **$39** (Guide + Repo).

**Money-back guarantee:** If it doesn't save you 10+ hours, email me within 30 days for a full refund.

---

## FAQ

**Q: Why not just use a library?**
A: Libraries give you primitives. This guide gives you a **complete, hardened service** — pooling, timeouts, metrics, security, CI, recipes. The difference between "it works on my machine" and "it runs in prod for 2 years."

**Q: Do I need to know ChromeDP?**
A: No. The guide explains every ChromeDP call used. Basic Go knowledge is enough.

**Q: Will this work in Kubernetes / Cloud Run / Fly.io / Lambda?**
A: Yes. The Dockerfile is multi-arch (amd64/arm64), runs as non-root, reads config from env. Includes resource limits and health checks.

**Q: What about PDF/A compliance / accessibility?**
A: Chapter 7 covers PDF/A-1b (ICC profile, XMP metadata, font embedding) and tagged PDF for screen readers. It's the only Go guide that does.

**Q: Can I use this commercially?**
A: Yes. Source code is MIT licensed. Guide is for your personal/team use.

**Q: What if Chrome/Chromium updates break something?**
A: The guide pins `headless-shell` versions in Dockerfile. Updates = rebuild. I'll publish v1.x updates free.

**Q: Is there a community / support?**
A: Private repo tier includes GitHub Issues. I answer within 24h on weekdays.

---

## About the Author

**[Your Name]** — Go developer since 201X. Built PDF systems for [fintech/logistics/SaaS] processing 10M+ docs/month. Writes about Go, systems, and dev tooling at [blog/newsletter].

---

## Footer CTA

**Stop debugging PDFs. Start shipping.**

[Get the Guide for $29 → Gumroad]

*First 50 buyers: $19 with code `EARLYBIRD`*