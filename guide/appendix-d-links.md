# Appendix D: Links & Resources

---

## pdfgen Project

- **Source code:** https://github.com/pdfgen/pdfgen
- **Releases:** https://github.com/pdfgen/pdfgen/releases
- **Docker images:** https://github.com/pdfgen/pdfgen/pkgs/container/pdfgen
- **Issues:** https://github.com/pdfgen/pdfgen/issues
- **Discussions:** https://github.com/pdfgen/pdfgen/discussions

---

## Core Dependencies

| Project | Repository | Docs |
|---------|------------|------|
| chromedp | https://github.com/chromedp/chromedp | https://pkg.go.dev/github.com/chromedp/chromedp |
| headless-shell | https://chromium.googlesource.com/chromium/src/+/main/headless/ | https://developer.chrome.com/docs/chromium/headless-shell |
| zerolog | https://github.com/rs/zerolog | https://pkg.go.dev/github.com/rs/zerolog |
| goreleaser | https://github.com/goreleaser/goreleaser | https://goreleaser.com/ |
| pdfcpu | https://github.com/pdfcpu/pdfcpu | https://pdfcpu.io/ |
| distroless | https://github.com/GoogleContainerTools/distroless | N/A |

---

## Chrome / headless-shell

- **Chrome for Testing downloads:** https://googlechromelabs.github.io/chrome-for-testing/
- **Known good versions JSON:** https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json
- **headless-shell announcement:** https://developer.chrome.com/blog/headless-shell/
- **Chrome DevTools Protocol:** https://chromedevtools.github.io/devtools-protocol/
- **PrintToPDF CDP command:** https://chromedevtools.github.io/devtools-protocol/tot/Page/#method-printToPDF

---

## CSS Print Specification

- **CSS Paged Media Module Level 3:** https://www.w3.org/TR/css-page-3/
- **CSS Generated Content for Paged Media:** https://www.w3.org/TR/css-gcpm-3/
- **MDN @page:** https://developer.mozilla.org/en-US/docs/Web/CSS/@page
- **MDN Running elements:** https://developer.mozilla.org/en-US/docs/Web/CSS/position#running_elements
- **MDN Print media:** https://developer.mozilla.org/en-US/docs/Web/CSS/@media/print

---

## PDF Standards

- **PDF/A-1b (ISO 19005-1):** https://www.iso.org/standard/38920.html
- **PDF/UA (ISO 14289-1):** https://www.iso.org/standard/64599.html
- **PDF 1.7 (ISO 32000-1):** https://www.adobe.com/content/dam/acom/en/devnet/pdf/pdfs/PDF32000_2008.pdf
- **pdfcpu validation:** https://pdfcpu.io/core/validation.html

---

## Fonts

| Font | License | Repo | CDN |
|------|---------|------|-----|
| Inter | SIL OFL | https://github.com/rsms/inter | https://fonts.google.com/specimen/Inter |
| JetBrains Mono | SIL OFL | https://github.com/JetBrains/JetBrainsMono | https://fonts.google.com/specimen/JetBrains+Mono |
| IBM Plex | SIL OFL | https://github.com/IBM/plex | https://fonts.google.com/specimen/IBM+Plex+Sans |
| Noto Sans | SIL OFL | https://github.com/googlefonts/noto-fonts | https://fonts.google.com/noto/specimen/Noto+Sans |
| Noto Sans SC/TC/JP/KR | SIL OFL | https://github.com/googlefonts/noto-cjk | https://fonts.google.com/noto |
| Noto Color Emoji | SIL OFL | https://github.com/googlefonts/noto-emoji | N/A |
| Source Sans/Serif/Code | SIL OFL | https://github.com/adobe-fonts/source-sans | https://fonts.google.com/specimen/Source+Sans+3 |

**Subsetting tool:** https://github.com/fonttools/fonttools (pyftsubset)

---

## Go PDF Libraries (Alternatives)

| Library | Approach | Stars | Last Update |
|---------|----------|-------|-------------|
| chromedp | Chrome DevTools Protocol | 9k+ | Active |
| rod | High-level ChromeDP | 6k+ | Active |
| pdfcpu | Pure Go (manipulation) | 3k+ | Active |
| unidoc | Pure Go (creation) | 2k+ | Active |
| gofpdf / fpdf2 | Pure Go (FPDF port) | 5k+ | Maintenance |
| wkhtmltopdf (go-wrapper) | QtWebKit | 1k+ | Dead (2017) |

---

## Hosting / Deployment

| Platform | Free Tier | Notes |
|----------|-----------|-------|
| Fly.io | 3 shared VMs | Native Docker, global, ARM |
| Cloud Run | 2M requests/mo | Scale to zero, pay per use |
| Railway | $5 credit/mo | Simple, GitHub deploy |
| Render | 750 hrs/mo | Web services + cron |
| Hetzner | €4/mo VPS | Best price/performance |
| DigitalOcean | $5/mo droplet | Simple, predictable |

**All support:** Docker, custom domains, HTTPS, env vars, metrics.

---

## Payment / Storefront

| Platform | Fee | VAT Handling | Best For |
|----------|-----|--------------|----------|
| Gumroad | 10% + $0.30 | MoR (handles EU) | Digital products, simple |
| Lemon Squeezy | 5% + $0.50 | MoR (better EU) | SaaS, subscriptions |
| Paddle | 5% + $0.50 | MoR (B2B focus) | B2B, invoices |
| Stripe + own checkout | 2.9% + $0.30 | You handle | Full control, volume |

**MoR = Merchant of Record** (they handle sales tax/VAT globally).

---

## Email / Newsletter

| Platform | Free Tier | Best For |
|----------|-----------|----------|
| Buttondown | 1k subs | Simple, Markdown, API |
| Beehiiv | 2.5k subs | Growth, referrals, ads |
| ConvertKit | 1k subs | Creators, automations |
| MailerLite | 1k subs | E-commerce, landing pages |

---

## Analytics (Privacy-Friendly)

| Tool | Self-Hosted | Cloud | Price |
|------|-------------|-------|-------|
| Umami | ✅ | ✅ | Free / $9/mo |
| Plausible | ✅ | ✅ | $9/mo |
| GoatCounter | ✅ | ✅ | Free / donation |
| Matomo | ✅ | ✅ | Free / €19/mo |

---

## Monitoring / Observability

| Tool | Type | Free Tier |
|------|------|-----------|
| Prometheus + Grafana | Metrics + Dashboards | Self-hosted free |
| Loki + Grafana | Logs | Self-hosted free |
| Tempo + Grafana | Traces | Self-hosted free |
| Vector | Log pipeline | Free |
| Uptrace | APM | 10M spans/mo |

---

## Learning Resources

### Articles
- "Print CSS — The Definitive Guide" — https://www.smashingmagazine.com/2015/01/understanding-css-print-process/
- "Generating PDFs with Chrome Headless" — https://developers.google.com/web/updates/2017/04/headless-chrome
- "PDF Generation in Go" — https://blog.gopheracademy.com/advent-2017/pdf-generation/

### Videos
- "Chrome Headless for PDF Generation" — Google Chrome Developers (YouTube)
- "Go + ChromeDP" — GopherCon talks

### Books
- "CSS Paged Media" — Anton Prowse (W3C)
- "PDF Explained" — John Whitington (O'Reilly)

---

## Community

- **Gophers Slack:** `#pdf`, `#chromedp` — https://invite.slack.golangbridge.org/
- **Reddit:** r/golang, r/chromedp
- **Discord:** Gophers Discord, Chrome DevTools Protocol Discord

---

## License

This guide: Personal/team use only (purchased via Gumroad).

Source code (pdfgen): MIT License — see LICENSE in repository.

Fonts: SIL OFL / Apache 2.0 — see Appendix B for details.

---

## Author

**[Your Name]**
- Blog: https://yourblog.dev
- Newsletter: https://yournewsletter.com
- Twitter: https://twitter.com/yourhandle
- GitHub: https://github.com/pdfgen
- Email: you@yourdomain.com

---

*Last updated: 2024. Guide version matches pdfgen v0.1.0+.*