# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Core PDF generation service with ChromeDP pooling
- HTTP API with `/pdf`, `/healthz`, `/metrics` endpoints
- Multi-stage Dockerfile with headless-shell (20MB scratch image)
- GitHub Actions CI/CD (test, build, docker, goreleaser release)
- Sample PDF generation (`make pdf-sample`)
- Invoice, certificate, report, shipping label templates
- Prometheus metrics, structured logging, graceful shutdown
- Comprehensive README and landing page copy

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- Non-root user in Docker image
- Read-only filesystem
- Resource limits (memory, CPU)
- Seccomp profile ready

---

## [0.1.0] - 2024-XX-XX

### Added
- First public release
- PDF generation from HTML/CSS via ChromeDP
- Context pooling for concurrent requests
- Header/footer injection via CSS `position: running()`
- Page size, margins, scale, landscape options
- Health check and Prometheus metrics endpoints
- Multi-arch Docker images (amd64, arm64)
- Goreleaser configuration for automated releases
- MIT license

---

## Release Checklist

For each release:

- [ ] Update version in `cmd/pdfgen/main.go` (via goreleaser)
- [ ] Update CHANGELOG.md with release notes
- [ ] Run `make test` and `make bench`
- [ ] Create and push tag: `git tag v0.x.x && git push origin v0.x.x`
- [ ] GitHub Actions builds and publishes Docker images
- [ ] Goreleaser creates GitHub Release with artifacts
- [ ] Update Gumroad product files (PDF guide + source ZIP)
- [ ] Email buyers with changelog link
- [ ] Tweet/LinkedIn announcement

---

## Versioning Scheme

- **Major** (1.0.0): Breaking API changes, major architecture shifts
- **Minor** (0.2.0): New features, new recipes, backward compatible
- **Patch** (0.1.1): Bug fixes, security updates, doc improvements

Pre-releases: `v0.2.0-rc.1`, `v0.2.0-beta.2`

---

## Links

- [GitHub Releases](https://github.com/pdfgen/pdfgen/releases)
- [Docker Images](https://github.com/pdfgen/pdfgen/pkgs/container/pdfgen)
- [Guide & Source Code (Gumroad)](https://gumroad.com/l/pdfgen-go)