#!/usr/bin/env bash
# setup-repo.sh — Initialize git repo and push to GitHub
# Run this locally after cloning/downloading the project

set -euo pipefail

REPO_NAME="${1:-pdfgen}"
GITHUB_USER="${2:-pdfgen}"
VISIBILITY="${3:-private}"  # private or public

log() { echo -e "\033[0;32m[SETUP]\033[0m $*"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $*" >&2; }

# Check prerequisites
for cmd in git gh; do
    if ! command -v "$cmd" >/dev/null; then
        err "Missing: $cmd — install it first"
        exit 1
    fi
done

# Check gh auth
if ! gh auth status >/dev/null 2>&1; then
    err "Not authenticated with gh — run: gh auth login"
    exit 1
fi

log "Initializing git repository..."
git init
git add .
git commit -m "Initial commit: pdfgen service + guide

- Core PDF service (cmd/pdfgen, internal/pdfgen)
- Dockerfile (multi-stage, distroless, headless-shell)
- Makefile (build, test, bench, docker, release)
- GitHub Actions CI/CD (test, build, docker, goreleaser)
- Goreleaser config for multi-arch releases
- 10-chapter guide + 4 appendices (Markdown)
- 4 production templates (invoice, certificate, report, label)
- Build script for guide PDF + source ZIP
"

log "Creating GitHub repository: $GITHUB_USER/$REPO_NAME ($VISIBILITY)..."
gh repo create "$GITHUB_USER/$REPO_NAME" --"$VISIBILITY" --source=. --push --description "Bulletproof PDF Generation in Go — Production-ready PDF service from HTML/CSS"

log "Setting up repository secrets/variables..."
gh variable set CHROME_VERSION --body "126.0.6478.0" --repo "$GITHUB_USER/$REPO_NAME"
gh secret set GORELEASER_GITHUB_TOKEN --body "$(gh auth token)" --repo "$GITHUB_USER/$REPO_NAME"

log "Enabling GitHub Actions..."
gh api -X PUT "repos/$GITHUB_USER/$REPO_NAME/actions/permissions" -f enabled=true -f allowed_actions=all

log "Creating initial release (v0.1.0)..."
git tag v0.1.0
git push origin v0.1.0

log "Done! Repository: https://github.com/$GITHUB_USER/$REPO_NAME"
log ""
log "Next steps:"
log "  1. Check Actions tab — CI should run on tag push"
log "  2. Verify Docker image on ghcr.io/$GITHUB_USER/$REPO_NAME"
log "  3. Run './build-guide.sh v0.1.0' to generate guide PDF + source ZIP"
log "  4. Upload both to Gumroad"
log "  5. Update README.md with your actual GitHub username"