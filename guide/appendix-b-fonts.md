# Appendix B: Font Licensing & Self-Hosting

> **TL;DR** — Use SIL/OFL fonts. Self-host. Never rely on external font services in PDF generation.

---

## License Categories

| License | Commercial Use | Modification | Redistribution | Embed in PDF | Examples |
|---------|----------------|--------------|----------------|--------------|----------|
| **SIL OFL 1.1** | ✅ Yes | ✅ Yes | ✅ Yes (with renamed font) | ✅ Yes | Inter, Roboto, Noto, JetBrains Mono, IBM Plex |
| **Apache 2.0** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | Source Sans, Source Code Pro, Noto (some) |
| **MIT** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes | Some variable fonts |
| **Custom/Proprietary** | ❌ Usually no | ❌ No | ❌ No | ❌ Check EULA | Helvetica, Futura, Gotham, most Monotype/Adobe |

**Rule:** Only use SIL OFL, Apache 2.0, or MIT fonts for commercial PDF products.

---

## Recommended Font Stacks

### Latin + Cyrillic + Greek (UI/Body)
```css
@font-face {
    font-family: 'Inter';
    src: url('fonts/Inter-Variable.woff2') format('woff2-variations'),
         url('fonts/Inter-Regular.woff2') format('woff2');
    font-weight: 100 900;
    font-display: block;
}
```
**Files:** `Inter-Variable.woff2` (~100KB, all weights), or individual weights (~15KB each).
**Source:** https://github.com/rsms/inter/releases (SIL OFL)

### Monospace (Code)
```css
@font-face {
    font-family: 'JetBrains Mono';
    src: url('fonts/JetBrainsMono-Variable.woff2') format('woff2-variations');
    font-weight: 100 800;
    font-display: block;
}
```
**Source:** https://github.com/JetBrains/JetBrainsMono (SIL OFL)

### Serif (Certificates, Formal)
```css
@font-face {
    font-family: 'IBM Plex Serif';
    src: url('fonts/IBMPlexSerif-Variable.woff2') format('woff2-variations');
    font-weight: 100 700;
    font-display: block;
}
```
**Source:** https://github.com/IBM/plex (SIL OFL)

---

## CJK Fonts (Chinese/Japanese/Korean)

| Language | Font | License | Size |
|----------|------|---------|------|
| Simplified Chinese | Noto Sans SC | SIL OFL | ~15MB (variable) / ~4MB (subset) |
| Traditional Chinese | Noto Sans TC | SIL OFL | ~15MB |
| Japanese | Noto Sans JP | SIL OFL | ~15MB |
| Korean | Noto Sans KR | SIL OFL | ~12MB |

**Subsetting (critical for container size):**
```bash
# pyftsubset (from fonttools)
pip install fonttools brotli

# Subset to Latin + Common CJK (~3000 chars)
pyftsubset NotoSansSC-VF.woff2 \
    --text-file=common-chars.txt \
    --flavor=woff2 \
    --output-file=NotoSansSC-Subset.woff2
```

**Common chars file:** Include your domain-specific terms + 2000 most frequent CJK chars.

---

## Arabic/Hebrew (RTL)

```css
@font-face {
    font-family: 'Noto Sans Arabic';
    src: url('fonts/NotoSansArabic-Variable.woff2') format('woff2-variations');
    font-weight: 100 900;
    font-display: block;
}

@font-face {
    font-family: 'Noto Sans Hebrew';
    src: url('fonts/NotoSansHebrew-Variable.woff2') format('woff2-variations');
    font-weight: 100 900;
    font-display: block;
}
```

**RTL in HTML:**
```html
<html dir="rtl" lang="ar">
<body style="font-family: 'Noto Sans Arabic', system-ui;">
<p>مرحبا بالعالم</p>
```

---

## Emoji

**Option 1: Noto Color Emoji (SIL OFL)**
- File: `NotoColorEmoji.ttf` (~10MB) or `NotoColorEmoji.woff2` (not standard)
- Chrome renders color glyphs automatically

**Option 2: Twemoji (CC-BY 4.0)**
- PNG/SVG per emoji
- Use via `<img class="emoji" src="https://cdn.jsdelivr.net/gh/twitter/twemoji@latest/assets/svg/1f600.svg">`

**Recommendation:** For PDF, use Noto Color Emoji font. Subset to used emojis only.

---

## Self-Hosting Checklist

- [ ] Download font files (`.woff2` preferred, `.woff` fallback)
- [ ] Verify license (SIL OFL / Apache 2.0 / MIT)
- [ ] Subset if >500KB (pyftsubset)
- [ ] Place in `assets/fonts/` or embed as base64 in CSS
- [ ] `@font-face` with `font-display: block`
- [ ] Test in container: `fc-list | grep -i inter`
- [ ] Generate PDF → `pdffonts output.pdf` → verify embedded

---

## Base64 Embedding (Single-File CSS)

```bash
# Convert to base64
base64 -w 0 assets/fonts/Inter-Variable.woff2 > inter.b64
```

```css
@font-face {
    font-family: 'Inter';
    src: url(data:font/woff2;base64,{{.InterBase64}}) format('woff2-variations');
    font-weight: 100 900;
    font-display: block;
}
```

**Pros:** Single CSS file, no file loading issues.
**Cons:** CSS size +33%. OK for <200KB total fonts.

---

## Font Loading Debugging

```bash
# In container chrome://inspect
# Console:
document.fonts.ready.then(() => console.log('Fonts loaded'));
Array.from(document.fonts).forEach(f => console.log(f.family, f.status));

# Check embedded fonts in PDF
pdffonts output.pdf
# name                                 type              encoding         emb sub uni object ID
# ------------------------------------ ----------------- ---------------- --- --- --- ---------
# Inter                                CID TrueType      Identity-H       yes yes yes      4  0
```

**`emb=yes` = embedded. `sub=yes` = subset. `uni=yes` = Unicode map.**

---

## Free Commercial Font Sources

| Site | License Filter | Notes |
|------|----------------|-------|
| Google Fonts | All SIL OFL / Apache | `display=block` in URL |
| Font Squirrel | "Commercial Use" tag | Verify each |
| GitHub (rsms, IBM, JetBrains, GoogleFonts) | Repo license | Primary sources |
| CTAN (TeX fonts) | LPPL / OFL | High quality serif/math |

---

## What NOT to Use

| Font | Why |
|------|-----|
| Helvetica / Arial | Proprietary, no PDF embedding rights |
| Times New Roman | Proprietary (Monotype) |
| Calibri / Cambria | Microsoft proprietary |
| San Francisco | Apple proprietary (system only) |
| Roboto (from fonts.googleapis.com without `display=block`) | External request = fail in offline container |
| Any "Free for personal use only" | License violation in commercial product |

---

## Container Font Installation (Dockerfile)

```dockerfile
# In builder stage
RUN mkdir -p /usr/share/fonts/truetype/custom
COPY assets/fonts/*.woff2 /usr/share/fonts/truetype/custom/
RUN fc-cache -f -v /usr/share/fonts/truetype/custom/

# In runtime (distroless)
COPY --from=builder /usr/share/fonts/truetype/custom/ /usr/share/fonts/truetype/custom/
COPY --from=builder /etc/fonts/ /etc/fonts/
```

**Verify:** `fc-list | grep -i inter` in running container.