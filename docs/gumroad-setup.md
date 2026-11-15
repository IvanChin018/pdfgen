# Gumroad Product Setup Checklist

---

## 1. Create Product

**Product type:** Digital product (PDF + ZIP)

**Name:** `Bulletproof PDF Generation in Go`

**Tagline:** `Build a production-ready PDF service from HTML/CSS — tiny containers, perfect pagination, zero vendor lock-in.`

**Price:** `$29` (early bird: `$19` with coupon `EARLYBIRD`, first 50)

**Files to upload:**
- `Bulletproof-PDF-Generation-in-Go.pdf` (the guide, ~72 pages)
- `pdfgen-source-code.zip` (complete Go project: `cmd/`, `internal/`, `Dockerfile`, `Makefile`, `.github/workflows/`, `testdata/`, `README.md`)

**Cover image:** 1200×628 px — code editor screenshot + PDF output side by side

---

## 2. Product Description (Gumroad Editor)

*Paste from `docs/landing-page.md` — use the "Problem → Solution → What's Inside → Who This Is For → FAQ" structure.*

**Key sections to include:**
- What you'll build (bullet list with ✅)
- Table of contents (collapsible)
- Sample chapter excerpt ("Headers/Footers That Don't Drift")
- Pricing tiers table
- FAQ (8–10 most common questions)
- Author bio + link to blog/newsletter

**Formatting tips:**
- Use **bold** for scanning
- Keep paragraphs ≤3 lines
- Add `---` horizontal rules between sections
- Gumroad supports Markdown-ish formatting

---

## 3. Pricing Tiers (Gumroad "Variants")

| Variant Name | Price | Files Included | Description |
|--------------|-------|----------------|-------------|
| Guide Only | $29 | PDF + source ZIP | Complete guide + MIT-licensed code |
| Guide + Private Repo | $59 | PDF + source ZIP + repo invite | GitHub repo access (issues, updates, PRs) |
| Team License (5 seats) | $149 | PDF + source ZIP + repo invite | Internal use for up to 5 developers |

**Setup:** Gumroad → Product → Variants → Add each tier

---

## 4. Coupons (Gumroad → Marketing → Coupons)

| Code | Discount | Max Uses | Expires | Notes |
|------|----------|----------|---------|-------|
| `EARLYBIRD` | $10 off ($19) | 50 | 30 days | Launch week only |
| `LAUNCH20` | 20% off | 100 | 14 days | General launch |
| `STUDENT` | 50% off | 20 | — | Verify .edu email manually |
| `NEWSLETTER` | $5 off | ∞ | — | For email subscribers |

---

## 5. Email Receipt Customization

**Gumroad → Settings → Email Receipts → Customize**

**Subject:** `Your pdfgen guide is ready 📄`

**Body:**
```
Hi {{ purchaser_name }},

Thanks for grabbing **Bulletproof PDF Generation in Go**!

**Your downloads:**
{{ download_links }}

**What's next:**
1. Download the PDF guide + source code ZIP
2. Unzip → `cd pdfgen` → `make build` → `./bin/pdfgen sample`
3. Open `testdata/output/sample.pdf` — that's your service working
4. Read Chapter 3 (Project Setup) to wire it into your stack

**Private repo access** (if you bought that tier):
- Check your email for a GitHub invitation from me
- Accept → you'll see the private repo with issues, CI, and future updates

**Questions? Reply to this email** — I read every one.

Happy PDF generating!
— [Your Name]
```

---

## 6. Post-Purchase Automation (Gumroad → Marketing → Workflows)

**Workflow 1: "Welcome Sequence"**
- **Trigger:** Purchase completed
- **Delay 0 min:** Send receipt (above)
- **Delay 1 day:** Email #2 — "Chapter 4 deep dive: Core service architecture" (link to blog post or private repo README)
- **Delay 3 days:** Email #3 — "Real-world recipe: Invoice generation" (code snippet + link to Chapter 10)
- **Delay 7 days:** Email #4 — "How to deploy to Cloud Run / Fly.io" (Docker + env vars)
- **Delay 14 days:** Email #5 — "Ask me anything" (reply-to for questions)

**Workflow 2: "Update Notifications"**
- **Trigger:** New file uploaded to product (v0.2, v1.0, etc.)
- **Action:** Email all buyers: "vX.Y released — [changelog link] — free for you"

---

## 7. Analytics & Tracking

**Gumroad → Analytics**
- Track: Views → Purchases conversion rate
- Traffic sources (UTM parameters on all links)
- Revenue by variant
- Refund rate (target: <3%)

**UTM parameters for every link:**
```
?utm_source=twitter&utm_medium=social&utm_campaign=pdfgen-launch
?utm_source=newsletter&utm_medium=email&utm_campaign=pdfgen-weekly
?utm_source=devto&utm_medium=referral&utm_campaign=pdfgen-article
?utm_source=hn&utm_medium=social&utm_campaign=pdfgen-showhn
```

---

## 8. Launch Checklist

- [ ] Product created on Gumroad (draft mode)
- [ ] PDF guide finalized (v0.1 → `make pdf-sample` → review)
- [ ] Source code ZIP built (`git archive -o pdfgen-source.zip HEAD`)
- [ ] Cover image uploaded (1200×628)
- [ ] Description pasted + formatted
- [ ] Variants configured (3 tiers)
- [ ] Coupons created (`EARLYBIRD`, `LAUNCH20`, `STUDENT`, `NEWSLETTER`)
- [ ] Email receipt customized
- [ ] Welcome workflow activated
- [ ] Test purchase (use coupon `TEST` → 100% off → verify flow)
- [ ] Landing page live (Carrd/Framer/Netlify) with Gumroad buy button
- [ ] Launch tweets/LinkedIn posts scheduled
- [ ] Dev.to article published (canonical → landing page)
- [ ] HN "Show HN" submitted (weekday 8–10 AM PST)
- [ ] Email to waitlist sent

---

## 9. Post-Launch (Week 1)

| Day | Action |
|-----|--------|
| 1 | Respond to every buyer email < 2h |
| 2 | Collect "what's missing?" → prioritize v0.2 |
| 3 | Push v0.2 (fixes + 1 new recipe) → notify buyers |
| 4 | Write "Week 1 retrospective" blog post (revenue, lessons) |
| 5 | Answer HN/Reddit/Twitter questions → link to guide |
| 6 | Plan v1.0 scope (PDF/A, accessibility, more recipes) |
| 7 | Rest 🎉 |

---

## 10. File Naming Convention

```
Bulletproof-PDF-Generation-in-Go-v1.0.pdf
pdfgen-source-code-v1.0.zip
```

**Update on each release:** Increment version in filename + Gumroad file description.

---

## 11. Legal

**Gumroad → Settings → Legal**
- Refund policy: "30-day money-back guarantee if the guide doesn't save you 10+ hours. Email for full refund."
- License: "Guide: Personal/team use only. Source code: MIT License (see LICENSE in ZIP)."
- VAT: Handled by Gumroad (Merchant of Record)

---

## 12. Backup Plan

If Gumroad issues:
- **Lemon Squeezy** — better EU VAT, same features
- **Stripe + own checkout** — more work, full control
- **Paddle** — B2B focus, handles invoicing

Keep product files + buyer emails exported weekly.