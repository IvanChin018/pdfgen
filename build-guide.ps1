<#
.SYNOPSIS
    Build the guide PDF and source ZIP for Windows (PowerShell)
.DESCRIPTION
    Uses pandoc + weasyprint via Python. Requires: pandoc, python3, pip install weasyprint
.PARAMETER Version
    Version string (default: git describe or 'dev')
.EXAMPLE
    .\build-guide.ps1 -Version "v0.1.0"
#>

param(
    [string]$Version = "dev"
)

$ErrorActionPreference = "Stop"

function Log { Write-Host "[BUILD] $args" -ForegroundColor Green }
function Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Err { Write-Host "[ERROR] $args" -ForegroundColor Red; exit 1 }

# Check dependencies
$missing = @()
@("pandoc", "python", "git") | ForEach-Object {
    if (-not (Get-Command $_ -ErrorAction SilentlyContinue)) { $missing += $_ }
}
if ($missing) { Err "Missing dependencies: $($missing -join ', ')`nInstall: choco install pandoc python git`nThen: pip install weasyprint" }

$date = Get-Date -Format "yyyy-MM-dd"
$guideDir = "guide"
$outputDir = "dist"
$guideName = "Bulletproof-PDF-Generation-in-Go"
$outputPdf = "$outputDir\$guideName-v$Version.pdf"
$outputZip = "$outputDir\$guideName-source-code-v$Version.zip"

# Create output dir
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

# Assemble full guide
$fullMd = "$outputDir\guide-full.md"
Log "Assembling guide chapters..."

$header = @"
---
title: "Bulletproof PDF Generation in Go"
subtitle: "Build a production-ready PDF service from HTML/CSS — tiny containers, perfect pagination, zero vendor lock-in"
author: "[Your Name]"
date: "$date"
version: "$Version"
geometry: margin=25mm
fontsize: 11pt
linestretch: 1.5
toc: true
toc-depth: 3
numbersections: true
header-includes:
  - \usepackage{booktabs}
  - \usepackage{longtable}
  - \usepackage{float}
  - \usepackage{xcolor}
  - \definecolor{codebg}{HTML}{F4F4F4}
  - \definecolor{codeborder}{HTML}{E0E0E0}
  - \usepackage{listings}
  - \lstset{
      backgroundcolor=\color{codebg},
      frame=single,
      framerule=0.5pt,
      rulecolor=\color{codeborder},
      basicstyle=\ttfamily\small,
      breaklines=true,
      columns=fullflexible,
      keepspaces=true,
      showstringspaces=false
    }
---

# Bulletproof PDF Generation in Go

**Version:** $Version  |  **Date:** $date

*Build a production-ready PDF service from HTML/CSS — tiny containers, perfect pagination, zero vendor lock-in.*

---

## Preface

This guide is the companion to the **pdfgen** source code (included with your purchase).

**What you'll build:** A complete, production-ready PDF microservice (~200 LOC) that renders HTML/CSS ? PDF with perfect pagination, headers/footers that never drift, Unicode/RTL support, PDF/A-1b compliance, and runs in a 20MB scratch container.

**What you need:** Basic Go knowledge. No ChromeDP experience required — every call is explained.

**Source code:** All code snippets come from \`github.com/pdfgen/pdfgen\` (MIT licensed). The full project is included as a ZIP with this guide.

---

## Table of Contents

"@

$header | Out-File -FilePath $fullMd -Encoding utf8

$chapters = @(
    "chapter-01-landscape.md",
    "chapter-02-stack.md",
    "chapter-03-setup.md",
    "chapter-04-core-service.md",
    "chapter-05-html-css.md",
    "chapter-06-headers-footers.md",
    "chapter-07-advanced.md",
    "chapter-08-testing.md",
    "chapter-09-production.md",
    "chapter-10-recipes.md",
    "appendix-a-cheatsheet.md",
    "appendix-b-fonts.md",
    "appendix-c-troubleshooting.md",
    "appendix-d-links.md"
)

foreach ($chapter in $chapters) {
    $path = "$guideDir\$chapter"
    if (Test-Path $path) {
        "" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        "`newpage" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        Get-Content $path -Raw | Out-File -FilePath $fullMd -Encoding utf8 -Append
        Log "  Added: $chapter"
    } else {
        Warn "  Missing: $chapter (placeholder)"
        "" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        "`newpage" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        "# $($chapter -replace '\.md$','' -replace '-',' ' | ForEach-Object { (Get-Culture).TextInfo.ToTitleCase($_) })" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        "" | Out-File -FilePath $fullMd -Encoding utf8 -Append
        "*[Chapter placeholder — content to be written]*" | Out-File -FilePath $fullMd -Encoding utf8 -Append
    }
}

# Render HTML
$tmpHtml = "$outputDir\guide-full.html"
Log "Rendering HTML via pandoc..."
pandoc $fullMd -o $tmpHtml --standalone --css="$guideDir\style.css" --metadata title="Bulletproof PDF Generation in Go" --metadata subtitle="Build a production-ready PDF service from HTML/CSS" --metadata author="[Your Name]" --metadata date="$date" --metadata version="$Version"

# Render PDF via weasyprint
Log "Rendering PDF via weasyprint..."
python -m weasyprint $tmpHtml $outputPdf

# Create source ZIP
Log "Creating source ZIP..."
git archive --format=zip --prefix="pdfgen-source/" -o $outputZip HEAD 2>$null || {
    Warn "git archive failed, using Compress-Archive"
    Compress-Archive -Path * -DestinationPath $outputZip -CompressionLevel Optimal -Force
}

# Verify
Log "Verifying outputs..."
if (Test-Path $outputPdf) {
    $pdfSize = (Get-Item $outputPdf).Length
    Log "  PDF: $outputPdf ($([math]::Round($pdfSize/1KB,1)) KB)"
}
if (Test-Path $outputZip) {
    $zipSize = (Get-Item $outputZip).Length
    Log "  ZIP: $outputZip ($([math]::Round($zipSize/1KB,1)) KB)"
}

Log "Done! Upload both files to Gumroad:"
Log "  $outputPdf"
Log "  $outputZip"
