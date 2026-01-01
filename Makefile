.PHONY: generate generate-protoc clean lint package release

# Generate code from proto files using buf (recommended)
generate:
	@echo "Generating Go code from proto files using buf..."
	@which buf > /dev/null || (echo "buf not found. Install with: brew install bufbuild/buf/buf" && exit 1)
	buf generate proto

# Generate code from proto files using protoc (alternative)
generate-protoc:
	@echo "Generating Go code from proto files using protoc..."
	@export PATH="$$PATH:$$(go env GOPATH)/bin" && \
	mkdir -p gen/go/proto && \
	protoc --go_out=gen/go --go_opt=paths=source_relative \
		--go-grpc_out=gen/go --go-grpc_opt=paths=source_relative \
		proto/course.proto
	@echo "Initializing Go module and downloading dependencies..."
	@cd gen/go && [ ! -f go.mod ] && go mod init edu-course/proto || true
	@cd gen/go && go get google.golang.org/protobuf@latest google.golang.org/grpc@latest
	@cd gen/go && go mod tidy

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	rm -rf gen/

# Lint proto files
lint:
	@echo "Linting proto files..."
	buf lint proto

# Format proto files
format:
	@echo "Formatting proto files..."
	buf format -w proto

# Check breaking changes
breaking:
	@echo "Checking for breaking changes..."
	buf breaking --against '.git#branch=main'

# Package generated code for distribution
package:
	@echo "Packaging generated code..."
	@if [ ! -d "gen/go" ]; then \
		echo "Error: gen/go directory not found. Please run 'make generate-protoc' first."; \
		exit 1; \
	fi
	@VERSION=$${VERSION:-$(shell git describe --tags --always 2>/dev/null || echo "v0.0.0")}; \
	PACKAGE_NAME="edu-course-proto-$${VERSION#v}"; \
	PACKAGE_DIR="dist/$$PACKAGE_NAME"; \
	mkdir -p $$PACKAGE_DIR; \
	cp -r gen/go/* $$PACKAGE_DIR/; \
	cp README.md $$PACKAGE_DIR/ 2>/dev/null || true; \
	cd dist && tar -czf "$$PACKAGE_NAME.tar.gz" "$$PACKAGE_NAME" && \
	echo "Package created: dist/$$PACKAGE_NAME.tar.gz"; \
	cd .. && rm -rf $$PACKAGE_DIR

# Create a release-ready package (includes versioning)
release:
	@echo "Creating release package..."
	@if [ -z "$$VERSION" ]; then \
		echo "Error: VERSION is required. Usage: make release VERSION=v1.0.0"; \
		exit 1; \
	fi
	@$(MAKE) generate-protoc
	@$(MAKE) package VERSION=$$VERSION
	@echo "Release package ready: dist/edu-course-proto-$${VERSION#v}.tar.gz"
