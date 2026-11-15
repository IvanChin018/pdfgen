# Chapter 10: Real-World Recipes — Copy-Paste Production Code

> **TL;DR** — Four complete templates you'll actually use. Invoice, Certificate, Report, Shipping Label.

---

## Recipe 1: Invoice (assets/templates/invoice.html)

**Features:** Line items, tax calc, QR code payment, dynamic totals, bill-to/ship-to, payment terms.

**Data structure:**
```go
type InvoiceData struct {
    Company  CompanyInfo
    Client   ClientInfo
    Invoice  InvoiceDetails
    Items    []LineItem
    QRCodeBase64 string  // Generated via go-qrcode
}

type InvoiceDetails struct {
    Number    string
    Date      string
    DueDate   string
    Terms     string
    Subtotal  float64
    Tax       float64
    TaxRate   float64
    Discount  float64
    Total     float64
    Notes     string
}
```

**Generate:**
```go
func GenerateInvoice(svc *pdfgen.Service, data InvoiceData) ([]byte, error) {
    tmpl := template.Must(template.ParseFiles("assets/templates/invoice.html"))
    var htmlBuf bytes.Buffer
    tmpl.Execute(&htmlBuf, data)

    return svc.Generate(context.Background(), pdfgen.GenerateRequest{
        HTML: htmlBuf.String(),
        Options: pdfgen.Options{
            PageSize:   "A4",
            Margins:    pdfgen.Margins{Top: "25mm", Right: "20mm", Bottom: "30mm", Left: "20mm"},
            HeaderHTML: `<header>{{.Company.Name}} • Invoice {{.Invoice.Number}}</header>`,
            FooterHTML: `<footer>Page <span class="pageNumber"></span> | {{.Company.Name}}</footer>`,
        },
    })
}
```

**QR Code:**
```go
import "github.com/skip2/go-qrcode"

func GeneratePaymentQR(iban, amount, ref string) (string, error) {
    // EPC QR code format for SEPA payments
    payload := fmt.Sprintf("BCD\n002\n1\nSCT\n%s\n%s\nEUR%.2f\n\n%s\n\n\n\n\n\n\n",
        iban, "Acme Corp", amount, ref)
    png, err := qrcode.Encode(payload, qrcode.Medium, 256)
    if err != nil { return "", err }
    return base64.StdEncoding.EncodeToString(png), nil
}
```

---

## Recipe 2: Certificate (assets/templates/certificate.html)

**Features:** Dynamic name, decorative border, signature image, watermark, landscape A4.

```html
<!DOCTYPE html>
<html>
<head>
<style>
@page { size: A4 landscape; margin: 0; background: #fafafa; }
@media print {
    .certificate { width: 100%; height: 100vh; position: relative; }
    .border { position: absolute; top: 20mm; left: 20mm; right: 20mm; bottom: 20mm;
              border: 4px double #1a1a2e; border-radius: 8px; }
    .content { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
               text-align: center; width: 80%; }
    h1 { font-family: 'Georgia', serif; font-size: 36pt; color: #1a1a2e; margin: 0 0 24pt; }
    .recipient { font-size: 28pt; color: #333; margin: 24pt 0; text-transform: uppercase; letter-spacing: 2pt; }
    .signature { margin-top: 48pt; display: flex; justify-content: center; gap: 60pt; }
    .sig-line { width: 200px; border-bottom: 1px solid #333; padding-top: 8pt; font-size: 11pt; }
    .watermark { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%) rotate(-30deg);
                 font-size: 120pt; color: rgba(0,0,0,0.03); white-space: nowrap; pointer-events: none; }
}
</style>
</head>
<body>
<div class="certificate">
    <div class="border"></div>
    <div class="watermark">CERTIFIED</div>
    <div class="content">
        <h1>Certificate of Completion</h1>
        <p>This certifies that</p>
        <p class="recipient">{{.RecipientName}}</p>
        <p>has successfully completed</p>
        <p style="font-size: 18pt; font-style: italic; color: #555;">{{.CourseName}}</p>
        <p>on {{.Date}} with a score of {{.Score}}%</p>
        <div class="signature">
            <div class="sig-line">{{.InstructorName}}<br>Instructor</div>
            <div class="sig-line">{{.DirectorName}}<br>Director</div>
        </div>
    </div>
</div>
</body>
</html>
```

---

## Recipe 3: Multi-Page Report (assets/templates/report.html)

**Features:** Cover page, TOC (roman numerals), chapters (arabic), appendix, page refs.

```html
<!DOCTYPE html>
<html>
<head>
<style>
@page cover { margin: 0; @top-center {}; @bottom-center {}; }
@page toc { margin: 25mm; @bottom-center { content: "Page " counter(page, lower-roman); } }
@page content { margin: 25mm; @bottom-center { content: "Page " counter(page); } }

.cover-page { page: cover; height: 100vh; display: flex; flex-direction: column; justify-content: center; align-items: center; background: #1a1a2e; color: white; }
.toc-page { page: toc; page-break-after: always; }
.content-page { page: content; }

.chapter { page-break-before: always; }
.chapter:first-of-type { page-break-before: avoid; }

.toc a::after { content: leader(".") target-counter(attr(href), page); }
.ref::after { content: " (page " target-counter(attr(href), page) ")"; font-size: 0.9em; color: #666; }

h1 { border-bottom: 2px solid #1a1a2e; padding-bottom: 8px; }
h2 { color: #333; }
</style>
</head>
<body>
<!-- Cover -->
<div class="cover-page">
    <h1>{{.Title}}</h1>
    <p style="font-size: 18pt;">{{.Subtitle}}</p>
    <p>{{.Date}} | {{.Author}}</p>
</div>

<!-- TOC -->
<div class="toc-page">
    <h1>Table of Contents</h1>
    <nav id="toc">
        <ul>
            {{range .Chapters}}
            <li><a href="#chapter-{{.Index}}">{{.Title}}</a></li>
            {{end}}
            <li><a href="#appendix">Appendix</a></li>
        </ul>
    </nav>
</div>

<!-- Chapters -->
{{range $i, $ch := .Chapters}}
<div class="chapter content-page" id="chapter-{{$i}}">
    <h1>{{$ch.Title}}</h1>
    {{$ch.Content}}
</div>
{{end}}

<!-- Appendix -->
<div class="chapter content-page" id="appendix">
    <h1>Appendix</h1>
    <p>Additional data, references, methodology.</p>
</div>
</body>
</html>
```

---

## Recipe 4: Shipping Label (4×6 Thermal) (assets/templates/label.html)

**Features:** Exact 4×6 inch, no margins, barcode, address blocks, carrier compliant.

```html
<!DOCTYPE html>
<html>
<head>
<style>
@page { size: 4in 6in; margin: 0; }
@media print {
    * { box-sizing: border-box; }
    body { margin: 0; padding: 4mm; font-family: 'DejaVu Sans Mono', monospace; font-size: 10pt; }
    .label { width: 100%; height: 100%; display: flex; flex-direction: column; }
    .header { display: flex; justify-content: space-between; margin-bottom: 4mm; }
    .barcode { text-align: center; margin: 4mm 0; }
    .barcode img { height: 24mm; }
    .address { line-height: 1.3; }
    .address strong { font-size: 12pt; }
    .footer { margin-top: auto; display: flex; justify-content: space-between; font-size: 8pt; }
    .tracking { font-family: 'Libre Barcode 128', monospace; font-size: 18pt; letter-spacing: 2pt; }
}
</style>
<link href="https://fonts.googleapis.com/css2?family=Libre+Barcode+128&display=block" rel="stylesheet">
</head>
<body>
<div class="label">
    <div class="header">
        <div><strong>{{.Carrier}}</strong><br>{{.ServiceLevel}}</div>
        <div class="tracking">{{.TrackingNumber}}</div>
    </div>
    <div class="barcode">
        <img src="data:image/png;base64,{{.BarcodeBase64}}" alt="{{.TrackingNumber}}">
    </div>
    <div class="address">
        <strong>SHIP TO:</strong><br>
        {{.To.Name}}<br>
        {{.To.Street}}<br>
        {{.To.City}}, {{.To.State}} {{.To.Zip}}<br>
        {{.To.Country}}
    </div>
    <div class="address" style="margin-top: 4mm;">
        <strong>SHIP FROM:</strong><br>
        {{.From.Name}}<br>
        {{.From.Street}}<br>
        {{.From.City}}, {{.From.State}} {{.From.Zip}}
    </div>
    <div class="footer">
        <span>WT: {{.Weight}} lbs</span>
        <span>DIM: {{.Dimensions}}</span>
        <span>{{.Date}}</span>
    </div>
</div>
</body>
</html>
```

**Barcode (Code 128):**
```go
import "github.com/boombuler/barcode/code128"

func GenerateCode128(data string) (string, error) {
    bc, err := code128.Encode(data)
    if err != nil { return "", err }
    bc, _ = barcode.Scale(bc, 400, 120)
    var buf bytes.Buffer
    png.Encode(&buf, bc)
    return base64.StdEncoding.EncodeToString(buf.Bytes()), nil
}
```

**Print:** `lp -d thermal_printer -o media=Custom.4x6in label.pdf`

---

## Next Steps

1. **Copy** `assets/templates/*.html` to your project
2. **Adapt** data structures to your domain
3. **Test** each with `make pdf-sample` (modify main.go sample generator)
4. **Deploy** — they're production-ready

---

> **Action item:** Pick one recipe. Generate 10 PDFs with real data. Verify print output. That's your first customer-ready document.