# Ship Checklist — pdfgen v0.1.0

## ✅ Done

- [x] Go source code compiles and passes all tests (5/5)
- [x] Sample PDF generated (91KB, valid %PDF-1.4)
- [x] Docker image configured (chrome-headless-shell)
- [x] Git repo initialized, first commit made
- [x] All `yourusername` references replaced with `pdfgen`
- [x] Guide PDF rendered (2.2MB, 10 chapters + appendices)
- [x] Source code ZIP created (74KB)
- [x] CHANGELOG updated with release date

## 📦 Sellable Files (in `dist/`)

| File | Size | Purpose |
|------|------|---------|
| `Bulletproof-PDF-Generation-in-Go-v0.1.0.pdf` | 2.2 MB | The guide (upload to Gumroad) |
| `Bulletproof-PDF-Generation-in-Go-source-code-v0.1.0.zip` | 74 KB | Source code (upload to Gumroad) |

## 🚀 What You Need To Do (requires your accounts)

### 1. GitHub (5 min)
```bash
cd C:\Users\ivanc\.qwenpaw\workspaces\default\pdfgen-guide
gh repo create pdfgen --public --source . --push
# OR: create repo on github.com, then:
git remote add origin https://github.com/<yourusername>/pdfgen.git
git branch -M main
git push -u origin main
```

### 2. Gumroad (15 min)
1. Go to https://gumroad.com → Settings → Products → New Product
2. Product type: **Digital product (PDF + ZIP)**
3. Name: `Bulletproof PDF Generation in Go`
4. Price: **$29** (early bird: **$19** with coupon `EARLYBIRD`, first 50)
5. Upload both files from `dist/`
6. Paste description from `docs/landing-page.md`
7. Configure variants: Guide Only ($29), Guide + Repo ($59), Team License ($149)
8. Create coupons: `EARLYBIRD`, `LAUNCH20`, `STUDENT`, `NEWSLETTER`
9. Customize email receipt (template in `docs/gumroad-setup.md`)
10. Test purchase with 100% coupon
11. Publish

### 3. Landing Page (10 min)
- Use the copy from `docs/landing-page.md`
- Quickest option: Carrd.co (free) or Gumroad's built-in page
- Add the Gumroad buy button

### 4. Launch (optional)
- Post on r/golang, r/devops, Hacker News (Show HN)
- Tweet with code `EARLYBIRD`
- Dev.to article linking to Gumroad

## 🔧 Key Details

- **Module path:** `github.com/pdfgen/pdfgen` (update to your actual GitHub username)
- **Tests:** `go test -v -timeout 60s ./internal/pdfgen/`
- **Build:** `go build -o bin/pdfgen.exe ./cmd/pdfgen/`
- **Docker:** `docker build -t pdfgen .`
- **Guide build:** pandoc + Chrome headless (see build-guide.ps1)