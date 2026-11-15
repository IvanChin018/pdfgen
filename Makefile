# pdfgen Makefile
# Usage: make <target>
#   make build          - Build binary
#   make test           - Run tests
#   make bench          - Run benchmarks
#   make docker         - Build Docker image
#   make release        - Build release artifacts (goreleaser)
#   make pdf-sample     - Generate sample PDF
#   make dev            - Run in dev mode (hot reload)
#   make lint           - Run linters
#   make clean          - Clean build artifacts

VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT  := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE    := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

BINARY_NAME := pdfgen
BUILD_DIR := ./bin
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)

.PHONY: build test bench docker release pdf-sample dev lint clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  build       - Build binary to ./bin/"
	@echo "  test        - Run unit tests"
	@echo "  bench       - Run benchmarks"
	@echo "  docker      - Build Docker image"
	@echo "  release     - Build release artifacts (requires goreleaser)"
	@echo "  pdf-sample  - Generate sample PDF"
	@echo "  dev         - Run with air (hot reload)"
	@echo "  lint        - Run golangci-lint"
	@echo "  clean       - Remove build artifacts"

build:
	@mkdir -p $(BUILD_DIR)
	@echo "Building $(BINARY_NAME) v$(VERSION)..."
	@CGO_ENABLED=0 go build -ldflags="$(LDFLAGS)" -o $(BUILD_DIR)/$(BINARY_NAME) ./cmd/pdfgen
	@echo "Done: $(BUILD_DIR)/$(BINARY_NAME)"

test:
	@echo "Running tests..."
	@go test -v -race -count=1 ./...

bench:
	@echo "Running benchmarks..."
	@go test -bench=. -benchmem -benchtime=10s ./...

docker:
	@echo "Building Docker image..."
	@docker build \
		--build-arg VERSION=$(VERSION) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg DATE=$(DATE) \
		-t pdfgen:$(VERSION) \
		-t pdfgen:latest .
	@echo "Done: pdfgen:$(VERSION)"

release:
	@which goreleaser > /dev/null || (echo "goreleaser not installed" && exit 1)
	@goreleaser release --clean --snapshot

pdf-sample: build
	@echo "Generating sample PDF..."
	@mkdir -p ./testdata/output
	@$(BUILD_DIR)/$(BINARY_NAME) sample --output ./testdata/output/sample.pdf
	@echo "Sample PDF: ./testdata/output/sample.pdf"

dev:
	@which air > /dev/null || (echo "air not installed: go install github.com/air-verse/air@latest" && exit 1)
	@air -c .air.toml

lint:
	@which golangci-lint > /dev/null || (echo "golangci-lint not installed" && exit 1)
	@golangci-lint run ./...

clean:
	@rm -rf $(BUILD_DIR) ./testdata/output
	@docker rmi pdfgen:latest pdfgen:$(VERSION) 2>/dev/null || true

# Install tools
install-tools:
	@go install github.com/air-verse/air@latest
	@go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@go install github.com/goreleaser/goreleaser@latest