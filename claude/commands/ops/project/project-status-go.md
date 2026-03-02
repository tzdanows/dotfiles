---
allowed-tools: Bash(go:*), Bash(fd:*), Bash(rg:*), Bash(jq:*), Bash(date:*), Bash(echo:*), Bash(which:*), Bash(eza:*), Bash(bat:*)
description: Comprehensive Go project health check with build, test, vet, and dependency analysis
---

## Context

- Session ID: !`date +%s%N 2>/dev/null || date +%s%N 2>/dev/null || echo "$(date +%s)$(jot -r 1 100000 999999 2>/dev/null || shuf -i 100000-999999 -n 1 2>/dev/null || echo $RANDOM$RANDOM)"`
- Check mode: $ARGUMENTS (optional - quick or detailed, default: quick)
- Current directory: !`pwd`
- Go version: !`go version 2>/dev/null || echo "Go not installed"`
- Project detected: !`[ -f go.mod ] && echo " Go module found" || echo " No go.mod found"`
- Module name: !`go list -m 2>/dev/null || echo "Not in a Go module"`
- Go workspace: !`[ -f go.work ] && echo "Go workspace detected" || echo "Single module project"`

## Your Task

STEP 1: Initialize Go project health check session

- CREATE session state file: `/tmp/go-status-$SESSION_ID.json`
- VALIDATE Go project presence (go.mod)
- DETERMINE check mode from $ARGUMENTS (quick vs detailed)
- GATHER initial project metadata

```bash
# Initialize session state
echo '{
  "sessionId": "'$SESSION_ID'",
  "timestamp": "'$(date -Iseconds 2>/dev/null || date -Iseconds)'",
  "checkMode": "'${ARGUMENTS:-quick}'",
  "projectPath": "'$(pwd)'",
  "healthStatus": {
    "build": "pending",
    "tests": "pending",
    "vet": "pending",
    "format": "pending",
    "modules": "pending",
    "staticcheck": "pending"
  },
  "issues": []
}' > /tmp/go-status-$SESSION_ID.json
```

STEP 2: Build and compilation health check

TRY:

```bash
echo " BUILD STATUS"
echo "═══════════════"

# Check if project builds
if go build ./... 2>/dev/null; then
    echo " Project builds successfully"
    jq '.healthStatus.build = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    
    # Count packages
    pkg_count=$(go list ./... 2>/dev/null | wc -l)
    echo "   Found $pkg_count packages"
else
    echo " Build errors detected"
    jq '.healthStatus.build = "fail"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    echo "Run 'go build ./...' for details"
fi

# Check for compilation with race detector
if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    echo ""
    echo " Race detector check..."
    if go build -race ./... 2>/dev/null; then
        echo " No race conditions in build"
    else
        echo "️  Race condition build failed"
    fi
fi
```

CATCH (build_check_failed):

```bash
echo "️  Build check failed - checking for common issues:"
echo "  - Missing dependencies: go mod download"
echo "  - Syntax errors: go build -v ./..."
echo "  - Module issues: go mod tidy"
```

STEP 3: Test suite health analysis

```bash
echo ""
echo " TEST STATUS"
echo "═══════════════"

# Run tests based on mode
if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    # Detailed mode: run all tests with coverage
    test_output=$(go test -race -coverprofile=/tmp/coverage-$SESSION_ID.out ./... 2>&1)
    test_exit_code=$?
    
    if [ $test_exit_code -eq 0 ]; then
        echo " All tests pass"
        jq '.healthStatus.tests = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
        
        # Coverage analysis
        if [ -f /tmp/coverage-$SESSION_ID.out ]; then
            coverage=$(go tool cover -func=/tmp/coverage-$SESSION_ID.out | tail -1 | rg -o "[0-9]+\.[0-9]+%" || echo "0%")
            echo " Test coverage: $coverage"
            rm -f /tmp/coverage-$SESSION_ID.out
        fi
    else
        echo " Test failures detected"
        jq '.healthStatus.tests = "fail"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
        echo "Run 'go test ./...' for details"
    fi
else
    # Quick mode: just check if tests compile and run basic tests
    if go test -short ./... >/dev/null 2>&1; then
        echo " Tests pass (short mode)"
        jq '.healthStatus.tests = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    else
        echo " Test failures detected"
        jq '.healthStatus.tests = "fail"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    fi
fi

# Count tests
test_count=$(go test -list=. ./... 2>/dev/null | rg "^Test" | wc -l || echo "0")
echo "   Found $test_count tests"

# Check for test files
test_file_count=$(fd "_test\.go$" . | wc -l)
echo "   Test files: $test_file_count"
```

STEP 4: Code quality and static analysis

```bash
echo ""
echo " CODE QUALITY"
echo "═══════════════"

# Go vet analysis
vet_output=$(go vet ./... 2>&1)
if [ -z "$vet_output" ]; then
    echo " No vet issues"
    jq '.healthStatus.vet = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
else
    issue_count=$(echo "$vet_output" | wc -l)
    echo "️  $issue_count vet issues found"
    jq '.healthStatus.vet = "warn"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    echo "Run 'go vet ./...' for details"
fi

# Format check
unformatted=$(gofmt -l . 2>/dev/null | wc -l)
if [ "$unformatted" -eq 0 ]; then
    echo " Code properly formatted"
    jq '.healthStatus.format = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
else
    echo "️  $unformatted files need formatting"
    jq '.healthStatus.format = "warn"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    echo "Run 'go fmt ./...' to fix"
fi

# Static analysis with staticcheck (if installed)
if which staticcheck >/dev/null 2>&1; then
    if staticcheck ./... >/dev/null 2>&1; then
        echo " No staticcheck issues"
        jq '.healthStatus.staticcheck = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    else
        echo "️  Staticcheck found issues"
        jq '.healthStatus.staticcheck = "warn"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
        echo "Run 'staticcheck ./...' for details"
    fi
else
    echo "ℹ️  staticcheck not installed"
    echo "   Install with: go install honnef.co/go/tools/cmd/staticcheck@latest"
fi
```

STEP 5: Module and dependency health

```bash
echo ""
echo " MODULE & DEPENDENCIES"
echo "══════════════════════"

# Check module tidiness
go_mod_backup=$(mktemp)
cp go.mod "$go_mod_backup"
if go mod tidy 2>/dev/null && ! diff -q go.mod "$go_mod_backup" >/dev/null; then
    echo "️  go.mod needs tidying"
    jq '.healthStatus.modules = "warn"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
    mv "$go_mod_backup" go.mod  # Restore original
    echo "Run 'go mod tidy' to fix"
else
    echo " Module dependencies tidy"
    jq '.healthStatus.modules = "pass"' /tmp/go-status-$SESSION_ID.json > /tmp/go-status-$SESSION_ID.tmp && mv /tmp/go-status-$SESSION_ID.tmp /tmp/go-status-$SESSION_ID.json
fi
rm -f "$go_mod_backup"

# Check for module verification
if go mod verify >/dev/null 2>&1; then
    echo " All modules verified"
else
    echo " Module verification failed"
    echo "Run 'go mod verify' for details"
fi

# Dependency analysis
direct_deps=$(go list -m -f '{{if not .Indirect}}{{.}}{{end}}' all 2>/dev/null | wc -l)
indirect_deps=$(go list -m -f '{{if .Indirect}}{{.}}{{end}}' all 2>/dev/null | wc -l)
echo " Dependencies: $direct_deps direct, $indirect_deps indirect"

# Check for available updates
if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    echo ""
    echo " Checking for updates..."
    updates=$(go list -u -m all 2>/dev/null | rg "\[" | wc -l || echo "0")
    if [ "$updates" -gt 0 ]; then
        echo "️  $updates dependencies have updates available"
        echo "Run 'go list -u -m all' for details"
    else
        echo " All dependencies up to date"
    fi
fi

# Security vulnerability check with govulncheck (if installed)
if which govulncheck >/dev/null 2>&1; then
    echo ""
    echo " Security vulnerability scan..."
    if govulncheck ./... >/dev/null 2>&1; then
        echo " No known vulnerabilities"
    else
        echo " Security vulnerabilities found!"
        echo "Run 'govulncheck ./...' for details"
    fi
else
    echo ""
    echo "ℹ️  govulncheck not installed"
    echo "   Install with: go install golang.org/x/vuln/cmd/govulncheck@latest"
fi
```

STEP 6: Project structure and best practices

IF check_mode is "detailed":

```bash
echo ""
echo " PROJECT STRUCTURE"
echo "══════════════════"

# Check for important files
[ -f README.md ] && echo " README.md present" || echo "️  Missing README.md"
[ -f LICENSE ] && echo " LICENSE present" || echo "️  Missing LICENSE file"
[ -f .gitignore ] && echo " .gitignore present" || echo "️  Missing .gitignore"
[ -f Makefile ] && echo " Makefile present" || echo "ℹ️  No Makefile found"
[ -d .github/workflows ] && echo " CI/CD workflows present" || echo "ℹ️  No GitHub Actions workflows"

# Check for common Go project patterns
[ -d cmd ] && echo " cmd/ directory present (good structure)" || echo "ℹ️  No cmd/ directory"
[ -d internal ] && echo " internal/ directory present" || echo "ℹ️  No internal/ directory"
[ -d pkg ] && echo " pkg/ directory present" || echo "ℹ️  No pkg/ directory"
[ -d api ] && echo " api/ directory present" || echo "ℹ️  No api/ directory"

# Analyze package structure
echo ""
echo " PACKAGE ANALYSIS"
main_pkgs=$(fd "main\.go$" . | wc -l)
echo "   Main packages: $main_pkgs"
internal_pkgs=$(go list ./internal/... 2>/dev/null | wc -l || echo "0")
echo "   Internal packages: $internal_pkgs"

# Check for generated code
gen_files=$(rg -l "Code generated .* DO NOT EDIT" . 2>/dev/null | wc -l || echo "0")
[ "$gen_files" -gt 0 ] && echo "   Generated files: $gen_files"

# ConnectRPC detection (user preference)
if rg -q "connectrpc" go.mod 2>/dev/null; then
    echo ""
    echo " ConnectRPC detected"
    proto_count=$(fd "\.proto$" . | wc -l)
    echo "   Proto files: $proto_count"
fi
```

STEP 7: Performance and efficiency checks (detailed mode only)

IF check_mode is "detailed":

```bash
echo ""
echo " PERFORMANCE ANALYSIS"
echo "═════════════════════"

# Benchmark detection
bench_count=$(rg -c "^func Benchmark" . --type go 2>/dev/null | wc -l || echo "0")
if [ "$bench_count" -gt 0 ]; then
    echo " Benchmarks available: $bench_count"
    echo "   Run with: go test -bench=. ./..."
fi

# Check for concurrent code patterns
goroutine_usage=$(rg -c "go\s+func" . --type go 2>/dev/null | wc -l || echo "0")
if [ "$goroutine_usage" -gt 0 ]; then
    echo " Concurrent code detected"
    echo "   Goroutine usage in $goroutine_usage files"
    sync_usage=$(rg -c "sync\." . --type go 2>/dev/null | wc -l || echo "0")
    echo "   Sync package usage in $sync_usage files"
fi

# Binary size analysis (if built)
if [ -f "$(go env GOPATH)/bin/$(basename $(pwd))" ]; then
    binary_size=$(du -h "$(go env GOPATH)/bin/$(basename $(pwd))" | cut -f1)
    echo " Binary size: $binary_size"
fi
```

FINALLY: Generate executive summary and recommendations

```bash
echo ""
echo "═══════════════════════════════════════════"
echo " GO PROJECT HEALTH SUMMARY"
echo "═══════════════════════════════════════════"
echo "Session: $SESSION_ID"
echo "Module: $(go list -m 2>/dev/null || basename $(pwd))"
echo "Go Version: $(go version | rg -o "go[0-9]+\.[0-9]+" || echo "unknown")"
echo ""

# Overall health score
health_data=$(cat /tmp/go-status-$SESSION_ID.json)
pass_count=$(echo "$health_data" | jq -r '[.healthStatus[] | select(. == "pass")] | length')
total_checks=$(echo "$health_data" | jq -r '[.healthStatus[] | select(. != "pending")] | length')
health_percentage=$((pass_count * 100 / total_checks))

echo " Overall Health Score: $health_percentage%"
echo ""

# Quick status overview
echo "Status Overview:"
echo "$health_data" | jq -r '.healthStatus | to_entries[] | select(.value != "pending") | "  \(.key): \(.value)"' | sed 's/pass//g; s/fail//g; s/warn/️/g'

# Recommendations
echo ""
echo " RECOMMENDATIONS"
echo "═════════════════"

if [ "$health_percentage" -eq 100 ]; then
    echo " Excellent! Your Go project is in great health."
else
    echo "$health_data" | jq -r '.healthStatus | to_entries[] | select(.value != "pass" and .value != "pending") | .key' | while read -r failing_check; do
        case "$failing_check" in
            "build")
                echo " Fix build errors: go build -v ./..."
                ;;
            "tests")
                echo " Fix failing tests: go test -v ./..."
                ;;
            "vet")
                echo " Address vet issues: go vet ./..."
                ;;
            "format")
                echo " Format code: go fmt ./..."
                ;;
            "modules")
                echo " Tidy modules: go mod tidy"
                ;;
            "staticcheck")
                echo " Fix static analysis issues: staticcheck ./..."
                ;;
        esac
    done
fi

# Additional recommendations
[ "$updates" -gt 0 ] && echo " Update dependencies: go get -u ./..."
[ ! -f README.md ] && echo " Add a README.md file"
[ ! -f LICENSE ] && echo "️  Add a LICENSE file"
[ "$bench_count" -eq 0 ] && echo " Consider adding benchmarks"

echo ""
echo " Full report saved to: /tmp/go-status-$SESSION_ID.json"
```

## Quick Reference

### Usage Examples

```bash
# Quick health check (default)
/project-status-go

# Detailed analysis with all checks
/project-status-go detailed

# From a specific project directory
cd my-go-project && /project-status-go
```

### Health Checks Performed

1. **Build Health**: Compilation and race condition detection
2. **Test Suite**: Test execution, coverage analysis
3. **Code Quality**: go vet, gofmt, staticcheck
4. **Module Health**: Tidiness, verification, updates
5. **Security**: Vulnerability scanning with govulncheck
6. **Project Structure**: Best practices and organization
7. **Performance**: Benchmarks and concurrency analysis (detailed mode)

This command provides comprehensive Go project health monitoring with a focus on best practices and security.
