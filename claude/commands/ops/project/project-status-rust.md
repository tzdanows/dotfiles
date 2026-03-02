---
allowed-tools: Bash(cargo:*), Bash(rustc:*), Bash(fd:*), Bash(rg:*), Bash(jq:*), Bash(date:*), Bash(echo:*), Bash(which:*), Bash(eza:*), Bash(bat:*)
description: Comprehensive Rust project health check with build, test, lint, and security analysis
---

## Context

- Session ID: !`date +%s%N 2>/dev/null || date +%s%N 2>/dev/null || echo "$(date +%s)$(jot -r 1 100000 999999 2>/dev/null || shuf -i 100000-999999 -n 1 2>/dev/null || echo $RANDOM$RANDOM)"`
- Check mode: $ARGUMENTS (optional - quick or detailed, default: quick)
- Current directory: !`pwd`
- Rust version: !`rustc --version 2>/dev/null || echo "Rust not installed"`
- Cargo version: !`cargo --version 2>/dev/null || echo "Cargo not available"`
- Project detected: !`[ -f Cargo.toml ] && echo " Rust project found" || echo " No Cargo.toml found"`
- Workspace info: !`cargo metadata --format-version 1 2>/dev/null | jq -r '.workspace_root // "Not a cargo workspace"' || echo "Unable to read metadata"`

## Your Task

STEP 1: Initialize Rust project health check session

- CREATE session state file: `/tmp/rust-status-$SESSION_ID.json`
- VALIDATE Rust project presence (Cargo.toml)
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
    "clippy": "pending",
    "format": "pending",
    "security": "pending"
  },
  "issues": []
}' > /tmp/rust-status-$SESSION_ID.json
```

STEP 2: Build and compilation health check

TRY:

```bash
echo " BUILD STATUS"
echo "═══════════════"

# Check if project builds
if cargo check --quiet 2>/dev/null; then
    echo " Project builds successfully"
    jq '.healthStatus.build = "pass"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
else
    echo " Build errors detected"
    jq '.healthStatus.build = "fail"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
    echo "Run 'cargo check' for details"
fi

# Check for outdated dependencies
echo ""
echo " DEPENDENCY STATUS"
outdated_count=$(cargo outdated --format json 2>/dev/null | jq -r '.dependencies | length' || echo "0")
if [ "$outdated_count" -gt 0 ]; then
    echo "️  $outdated_count outdated dependencies found"
    echo "Run 'cargo outdated' for details"
else
    echo " All dependencies up to date"
fi
```

CATCH (build_check_failed):

```bash
echo "️  Build check failed - checking for common issues:"
echo "  - Missing dependencies: cargo fetch"
echo "  - Syntax errors: cargo check --message-format=short"
echo "  - Feature flags: check Cargo.toml features"
```

STEP 3: Test suite health analysis

```bash
echo ""
echo " TEST STATUS"
echo "═══════════════"

# Run tests and capture results
if [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    # Detailed mode: run all tests
    test_output=$(cargo test --quiet 2>&1)
    test_exit_code=$?
else
    # Quick mode: just check if tests compile
    test_output=$(cargo test --no-run --quiet 2>&1)
    test_exit_code=$?
fi

if [ $test_exit_code -eq 0 ]; then
    echo " Tests pass"
    jq '.healthStatus.tests = "pass"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
    
    # Count tests
    test_count=$(cargo test -- --list 2>/dev/null | rg "test$" | wc -l || echo "0")
    echo "   Found $test_count tests"
else
    echo " Test failures detected"
    jq '.healthStatus.tests = "fail"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
fi

# Check test coverage (if tarpaulin is installed)
if which cargo-tarpaulin >/dev/null 2>&1 && [ "${ARGUMENTS:-quick}" = "detailed" ]; then
    echo " Running coverage analysis..."
    coverage=$(cargo tarpaulin --print-summary 2>/dev/null | rg "Coverage" | rg -o "[0-9]+\.[0-9]+%" || echo "N/A")
    echo "   Coverage: $coverage"
fi
```

STEP 4: Code quality and linting

```bash
echo ""
echo " CODE QUALITY"
echo "═══════════════"

# Clippy analysis
if cargo clippy --version >/dev/null 2>&1; then
    clippy_output=$(cargo clippy --quiet -- -W clippy::all 2>&1)
    if [ -z "$clippy_output" ]; then
        echo " No clippy warnings"
        jq '.healthStatus.clippy = "pass"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
    else
        warning_count=$(echo "$clippy_output" | rg -c "warning:" || echo "0")
        echo "️  $warning_count clippy warnings found"
        jq '.healthStatus.clippy = "warn"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
        echo "Run 'cargo clippy' for details"
    fi
else
    echo "ℹ️  Clippy not installed (install with: rustup component add clippy)"
fi

# Format check
if cargo fmt --version >/dev/null 2>&1; then
    if cargo fmt --check --quiet 2>/dev/null; then
        echo " Code properly formatted"
        jq '.healthStatus.format = "pass"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
    else
        echo "️  Code formatting issues found"
        jq '.healthStatus.format = "warn"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
        echo "Run 'cargo fmt' to fix"
    fi
else
    echo "ℹ️  rustfmt not installed (install with: rustup component add rustfmt)"
fi
```

STEP 5: Security audit

```bash
echo ""
echo " SECURITY AUDIT"
echo "═════════════════"

# Security audit
if cargo audit --version >/dev/null 2>&1; then
    audit_output=$(cargo audit --json 2>/dev/null)
    vulnerabilities=$(echo "$audit_output" | jq -r '.vulnerabilities.count // 0' || echo "0")
    
    if [ "$vulnerabilities" -eq 0 ]; then
        echo " No known vulnerabilities"
        jq '.healthStatus.security = "pass"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
    else
        echo " $vulnerabilities security vulnerabilities found!"
        jq '.healthStatus.security = "fail"' /tmp/rust-status-$SESSION_ID.json > /tmp/rust-status-$SESSION_ID.tmp && mv /tmp/rust-status-$SESSION_ID.tmp /tmp/rust-status-$SESSION_ID.json
        echo "Run 'cargo audit' for details"
    fi
else
    echo "ℹ️  cargo-audit not installed"
    echo "   Install with: cargo install cargo-audit"
fi

# Check for yanked dependencies
yanked_count=$(cargo metadata --format-version 1 2>/dev/null | jq -r '[.packages[].source // "" | select(contains("registry"))] | length' || echo "0")
if [ "$yanked_count" -gt 0 ]; then
    echo "️  Check for yanked crates with: cargo update --dry-run"
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
[ -d tests ] && echo " tests/ directory present" || echo "ℹ️  No separate tests directory"
[ -d benches ] && echo " benches/ directory present" || echo "ℹ️  No benchmarks directory"
[ -f .github/workflows ] && echo " CI/CD workflows present" || echo "ℹ️  No GitHub Actions workflows"

# Workspace structure
if [ -f Cargo.toml ] && rg "workspace" Cargo.toml >/dev/null 2>&1; then
    echo ""
    echo " WORKSPACE MEMBERS"
    cargo metadata --format-version 1 2>/dev/null | jq -r '.workspace_members[]' | while read -r member; do
        echo "   - $member"
    done
fi

# Binary and library targets
echo ""
echo " BUILD TARGETS"
cargo metadata --format-version 1 2>/dev/null | jq -r '.packages[0].targets[] | "   - \(.name) (\(.kind[0]))"' || echo "Unable to read targets"
```

STEP 7: Performance metrics (detailed mode only)

IF check_mode is "detailed" AND benchmarks exist:

```bash
echo ""
echo " PERFORMANCE"
echo "═══════════════"

if [ -d benches ] && fd "\.rs$" benches/ >/dev/null 2>&1; then
    echo "Benchmarks available. Run with: cargo bench"
    bench_count=$(fd "\.rs$" benches/ | wc -l)
    echo "   Found $bench_count benchmark files"
fi

# Check binary size
if [ -f target/release/$(cargo metadata --format-version 1 2>/dev/null | jq -r '.packages[0].targets[] | select(.kind[0] == "bin") | .name' | head -1) ]; then
    binary_size=$(du -h target/release/$(cargo metadata --format-version 1 2>/dev/null | jq -r '.packages[0].targets[] | select(.kind[0] == "bin") | .name' | head -1) | cut -f1)
    echo " Release binary size: $binary_size"
fi
```

FINALLY: Generate executive summary and recommendations

```bash
echo ""
echo "═══════════════════════════════════════════"
echo " RUST PROJECT HEALTH SUMMARY"
echo "═══════════════════════════════════════════"
echo "Session: $SESSION_ID"
echo "Project: $(cargo metadata --format-version 1 2>/dev/null | jq -r '.packages[0].name' || basename $(pwd))"
echo "Version: $(cargo metadata --format-version 1 2>/dev/null | jq -r '.packages[0].version' || echo "unknown")"
echo ""

# Overall health score
health_data=$(cat /tmp/rust-status-$SESSION_ID.json)
pass_count=$(echo "$health_data" | jq -r '[.healthStatus[] | select(. == "pass")] | length')
total_checks=$(echo "$health_data" | jq -r '[.healthStatus[]] | length')
health_percentage=$((pass_count * 100 / total_checks))

echo " Overall Health Score: $health_percentage%"
echo ""

# Quick status overview
echo "Status Overview:"
echo "$health_data" | jq -r '.healthStatus | to_entries[] | "  \(.key): \(.value)"' | sed 's/pass//g; s/fail//g; s/warn/️/g; s/pending/⏳/g'

# Recommendations
echo ""
echo " RECOMMENDATIONS"
echo "═════════════════"

if [ "$health_percentage" -eq 100 ]; then
    echo " Excellent! Your Rust project is in great health."
else
    echo "$health_data" | jq -r '.healthStatus | to_entries[] | select(.value != "pass") | .key' | while read -r failing_check; do
        case "$failing_check" in
            "build")
                echo " Fix build errors: cargo check --message-format=short"
                ;;
            "tests")
                echo " Fix failing tests: cargo test"
                ;;
            "clippy")
                echo " Address clippy warnings: cargo clippy --fix"
                ;;
            "format")
                echo " Format code: cargo fmt"
                ;;
            "security")
                echo " Fix security issues: cargo audit fix"
                ;;
        esac
    done
fi

# Additional recommendations based on findings
[ "$outdated_count" -gt 0 ] && echo " Update dependencies: cargo update"
[ ! -f README.md ] && echo " Add a README.md file"
[ ! -f LICENSE ] && echo "️  Add a LICENSE file"

echo ""
echo " Full report saved to: /tmp/rust-status-$SESSION_ID.json"
```

## Quick Reference

### Usage Examples

```bash
# Quick health check (default)
/project-status-rust

# Detailed analysis with all checks
/project-status-rust detailed

# From a specific project directory
cd my-rust-project && /project-status-rust
```

### Health Checks Performed

1. **Build Health**: Compilation and dependency status
2. **Test Suite**: Test compilation/execution and coverage
3. **Code Quality**: Clippy lints and formatting
4. **Security**: Vulnerability audit and yanked crates
5. **Project Structure**: Best practices and organization
6. **Performance**: Benchmarks and binary metrics (detailed mode)

This command provides comprehensive Rust project health monitoring with actionable recommendations for maintaining code quality and security.
