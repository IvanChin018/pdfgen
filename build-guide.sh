#!/usr/bin/env bash
# build-guide.sh — Render Markdown chapters → PDF guide
# Usage: ./build-guide.sh [version]
# Requires: pandoc, weasyprint (or typst), python3

set -euo pipefail

VERSION="${1:-$(git describe --tags --always --dirty 2>/dev/null || echo 'dev')}"
DATE="$(date -u +"%Y-%m-%d")"
GUIDE_DIR="guide"
OUTPUT_DIR="dist"
GUIDE_NAME="Bulletproof-PDF-Generation-in-Go"
OUTPUT_PDF="${OUTPUT_DIR}/${GUIDE_NAME}-v${VERSION}.pdf"
OUTPUT_ZIP="${OUTPUT_DIR}/${GUIDE_NAME}-source-code-v${VERSION}.zip"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Check dependencies
check_deps() {
    local missing=()
    command -v pandoc >/dev/null || missing+=("pandoc")
    command -v weasyprint >/dev/null || missing+=("weasyprint")
    command -v git >/dev/null || missing+=("git")
    command -v python3 >/dev/null || missing+=("python3")

    if [ ${#missing[@]} -gt 0 ]; then
        err "Missing dependencies: ${missing[*]}"
        echo "Install:"
        echo "  macOS: brew install pandoc weasyprint"
        echo "  Ubuntu: apt-get install pandoc && pip3 install weasyprint"
        echo "  Windows: choco install pandoc && pip install weasyprint"
        exit 1
    fi
}

# Assemble full guide from chapters
assemble_guide() {
    local tmp_md="${OUTPUT_DIR}/guide-full.md"
    mkdir -p "${OUTPUT_DIR}"

    log "Assembling guide from chapters..."

    cat > "${tmp_md}" <<'EOF'
---
title: "Bulletproof PDF Generation in Go"
subtitle: "Build a production-ready PDF service from HTML/CSS — tiny containers, perfect pagination, zero vendor lock-in"
author: "[Your Name]"
date: "${DATE}"
version: "${VERSION}"
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

**Version:** ${VERSION}  |  **Date:** ${DATE}

*Build a production-ready PDF service from HTML/CSS — tiny containers, perfect pagination, zero vendor lock-in.*

---

## Preface

This guide is the companion to the **pdfgen** source code (included with your purchase).

**What you'll build:** A complete, production-ready PDF microservice (~200 LOC) that renders HTML/CSS → PDF with perfect pagination, headers/footers that never drift, Unicode/RTL support, PDF/A-1b compliance, and runs in a 20MB scratch container.

**What you need:** Basic Go knowledge. No ChromeDP experience required — every call is explained.

**Source code:** All code snippets come from `github.com/pdfgen/pdfgen` (MIT licensed). The full project is included as a ZIP with this guide.

---

## Table of Contents

EOF

    # Append chapters in order
    for chapter in \
        "chapter-01-landscape.md" \
        "chapter-02-stack.md" \
        "chapter-03-setup.md" \
        "chapter-04-core-service.md" \
        "chapter-05-html-css.md" \
        "chapter-06-headers-footers.md" \
        "chapter-07-advanced.md" \
        "chapter-08-testing.md" \
        "chapter-09-production.md" \
        "chapter-10-recipes.md" \
        "appendix-a-cheatsheet.md" \
        "appendix-b-fonts.md" \
        "appendix-c-troubleshooting.md" \
        "appendix-d-links.md"; do

        if [ -f "${GUIDE_DIR}/${chapter}" ]; then
            echo "" >> "${tmp_md}"
            echo "\\newpage" >> "${tmp_md}"
            cat "${GUIDE_DIR}/${chapter}" >> "${tmp_md}"
            log "  Added: ${chapter}"
        else
            warn "  Missing (will create placeholder): ${chapter}"
            echo "" >> "${tmp_md}"
            echo "\\newpage" >> "${tmp_md}"
            echo "# $(basename "${chapter}" .md | sed 's/-/ /g' | sed 's/\b\w/\U&/g')" >> "${tmp_md}"
            echo "" >> "${tmp_md}"
            echo "*[Chapter placeholder — content to be written]*" >> "${tmp_md}"
        fi
    done

    echo "${tmp_md}"
}

# Render PDF via pandoc + weasyprint
render_pdf() {
    local input_md="$1"
    local output_pdf="$2"

    log "Rendering PDF via pandoc + weasyprint..."

    # We need HTML intermediate for weasyprint (better CSS @page support)
    local tmp_html="${OUTPUT_DIR}/guide-full.html"

    pandoc "${input_md}" \
        -o "${tmp_html}" \
        --standalone \
        --css="${GUIDE_DIR}/style.css" \
        --metadata-file=<(cat <<EOF
title: "Bulletproof PDF Generation in Go"
subtitle: "Build a production-ready PDF service from HTML/CSS"
author: "[Your Name]"
date: "${DATE}"
version: "${VERSION}"
EOF
) || { err "pandoc HTML generation failed"; exit 1; }

    # weasyprint handles @page, running headers/footers, counters perfectly
    weasyprint "${tmp_html}" "${output_pdf}" || { err "weasyprint failed"; exit 1; }

    log "PDF generated: ${output_pdf}"
    ls -lh "${output_pdf}"
}

# Create source code ZIP
create_source_zip() {
    local output_zip="$1"

    log "Creating source code ZIP..."

    git archive --format=zip --prefix="pdfgen-source/" -o "${output_zip}" HEAD || {
        warn "git archive failed (not a git repo?), falling back to zip"
        zip -r "${output_zip}" . -x "dist/*" "guide/*" "*.pdf" ".git/*" "node_modules/*" "tmp/*" ".air.toml" || {
            err "zip failed"; exit 1;
        }
    }

    log "Source ZIP: ${output_zip}"
    ls -lh "${output_zip}"
}

# Verify outputs
verify() {
    local pdf="$1"
    local zip="$2"

    log "Verifying outputs..."

    # PDF: check page count
    if command -v pdfinfo >/dev/null; then
        pages=$(pdfinfo "${pdf}" | grep Pages | awk '{print $2}')
        log "  PDF pages: ${pages}"
        if [ "${pages}" -lt 50 ]; then
            warn "  PDF seems short (<50 pages). Check chapter content."
        fi
    fi

    # ZIP: check key files
    if command -v unzip >/dev/null; then
        log "  ZIP contents:"
        unzip -l "${zip}" | grep -E "(main\.go|service\.go|Dockerfile|Makefile|\.goreleaser\.yml|README\.md)" | head -20
    fi
}

# Main
main() {
    log "Building guide v${VERSION}"

    check_deps
    mkdir -p "${OUTPUT_DIR}"

    FULL_MD=$(assemble_guide)
    render_pdf "${FULL_MD}" "${OUTPUT_PDF}"
    create_source_zip "${OUTPUT_ZIP}"
    verify "${OUTPUT_PDF}" "${OUTPUT_ZIP}"

    log "Done! Outputs in ${OUTPUT_DIR}/"
    echo ""
    echo "  PDF:  ${OUTPUT_PDF}"
    echo "  ZIP:  ${OUTPUT_ZIP}"
    echo ""
    echo "Upload both to Gumroad → Product → Files"
}

main "$@"