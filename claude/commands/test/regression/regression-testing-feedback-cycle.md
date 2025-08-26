---
allowed-tools: Bash(echo:*), Bash(touch:*), Bash(rm:*), Bash(chmod:*), Bash(mkdir:*), Write, Read, MultiEdit
description: Set up regression testing feedback cycle with Claude hooks for continuous validation
---

# Regression Testing Feedback Cycle

Automatically set up a continuous feedback loop that maintains project stability while implementing new features. This system uses Claude Code hooks to automatically run tests at strategic points during development.

## Overview

The regression testing feedback cycle ensures code quality through three phases:

1. **STABLE STATE** - All tests pass (QUICK & FULL)
2. **IMPLEMENTATION** - Active development with continuous validation
3. **VERIFICATION** - Full test suite confirms new stable state

## The Feedback Cycle Flow

```
STABLE STATE (all tests pass)
    ↓
START IMPLEMENTING 
    → PreToolUse: Confirm implementation approach
    ↓
DURING IMPLEMENTATION (iterative)
    → PostToolUse: Run QUICK tests after each change
    → Fix issues immediately if tests fail
    ↓
IMPLEMENTATION COMPLETE
    → Stop hook: Run FULL test suite
    ↓
NEW STABLE STATE (if all tests pass)
    OR
CONTINUE FIXING (if tests fail)
```

## Automatic Setup

I'll detect your test setup and configure the regression testing feedback cycle automatically.

## Setup Process

### Phase 1: Detection

I'll detect your test configuration:

```bash
# Check for Node.js project
if [ -f "package.json" ]; then
    QUICK_TEST=$(jq -r '.scripts | keys[] | select(. | test("test:unit|test:fast|test:quick"))' package.json 2>/dev/null | head -1)
    FULL_TEST=$(jq -r '.scripts | keys[] | select(. | test("test:all|test$|test:full"))' package.json 2>/dev/null | head -1)
fi

# Check for Deno project
if [ -f "deno.json" ]; then
    QUICK_TEST=$(jq -r '.tasks | keys[] | select(. | test("test:unit|test:fast"))' deno.json 2>/dev/null | head -1)
    FULL_TEST=$(jq -r '.tasks | keys[] | select(. | test("test$|test:all"))' deno.json 2>/dev/null | head -1)
fi

# Check for Go project
if [ -f "go.mod" ]; then
    QUICK_TEST="go test ./... -short"
    FULL_TEST="go test ./... -race"
fi

# Check for Rust project
if [ -f "Cargo.toml" ]; then
    QUICK_TEST="cargo test --lib"
    FULL_TEST="cargo test --all"
fi

# Check for Python project
if [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    QUICK_TEST="pytest tests/unit -x"
    FULL_TEST="pytest"
fi
```

### Phase 2: Performance Measurement

```bash
echo "Measuring test performance..."
START=$(date +%s%N)
$QUICK_TEST > /dev/null 2>&1
END=$(date +%s%N)
DURATION=$((($END - $START) / 1000000))
echo "Quick tests: ${DURATION}ms"
```

### Phase 3: Smart Test Runners

Creating optimized test runners with three modes:

**Smart Mode** - Only test changed files:

```bash
#!/bin/bash
# Smart test runner - only test affected files
CHANGED=$(git diff --name-only HEAD 2>/dev/null)
if [ -z "$CHANGED" ]; then
    echo "No changes detected, skipping tests"
    exit 0
fi

# Map changed files to test patterns
if echo "$CHANGED" | grep -q "src/"; then
    npm test -- --testPathPattern="$(echo "$CHANGED" | grep -E '\.(js|ts)$' | sed 's/src/tests/' | paste -sd '|')"
else
    echo "No testable changes"
fi
```

**Cached Mode** - Skip unchanged tests:

```bash
#!/bin/bash
# Generate hash of source files
HASH=$(find src tests -type f -name "*.js" -o -name "*.ts" | xargs md5sum | md5sum | cut -d' ' -f1)
CACHE_FILE=".claude/test-cache/$HASH"

if [ -f "$CACHE_FILE" ]; then
    echo "Tests cached - no changes detected"
    exit 0
fi

# Run tests and cache results
if npm test; then
    mkdir -p .claude/test-cache
    touch "$CACHE_FILE"
    exit 0
else
    exit 1
fi
```

### Phase 4: Installation

Installing enhanced control script with multiple modes:

```bash
#!/bin/bash
# Enhanced regression control with multiple modes

MODE_FILE="$CLAUDE_PROJECT_DIR/.claude/regression-mode"
SMART_FILE="$CLAUDE_PROJECT_DIR/.claude/smart-mode"
CACHE_FILE="$CLAUDE_PROJECT_DIR/.claude/cache-mode"

case "$1" in
    on|enable)
        touch "$MODE_FILE"
        rm -f "$SMART_FILE" "$CACHE_FILE"
        echo "Regression testing ENABLED (full mode)"
        ;;
    smart)
        touch "$MODE_FILE" "$SMART_FILE"
        rm -f "$CACHE_FILE"
        echo "Regression testing ENABLED (smart mode - only changed files)"
        ;;
    cached)
        touch "$MODE_FILE" "$CACHE_FILE"
        rm -f "$SMART_FILE"
        echo "Regression testing ENABLED (cached mode - skip unchanged)"
        ;;
    off|disable)
        rm -f "$MODE_FILE" "$SMART_FILE" "$CACHE_FILE"
        echo "Regression testing DISABLED"
        ;;
    status)
        if [ -f "$MODE_FILE" ]; then
            MODE="ACTIVE"
            if [ -f "$SMART_FILE" ]; then
                MODE="$MODE (smart)"
            elif [ -f "$CACHE_FILE" ]; then
                MODE="$MODE (cached)"
            else
                MODE="$MODE (full)"
            fi
            echo "Status: $MODE"
        else
            echo "Status: INACTIVE"
        fi
        ;;
    *)
        echo "Usage: $0 {on|smart|cached|off|status}"
        echo "  on     - Run all tests always"
        echo "  smart  - Only test changed files"
        echo "  cached - Skip unchanged tests"
        echo "  off    - Disable testing"
        exit 1
        ;;
esac
```

## Manual Setup Guide (if preferred)

### 1. Prerequisites

Your project needs:

- A QUICK test suite (basic functionality, <30s runtime)
- A FULL test suite (comprehensive coverage + E2E, <5min runtime)
- Test runner scripts or commands

## Usage Workflow

### Starting a Feature Implementation

```bash
# Check current state
./scripts/full-test.sh

# Choose your mode based on needs
./.claude/hooks/regression-control.sh smart   # Recommended: Only test changed files
./.claude/hooks/regression-control.sh cached  # Fastest: Skip unchanged tests
./.claude/hooks/regression-control.sh on      # Thorough: Run all tests

# Start implementing - tests run automatically
```

### During Implementation

- **After each code change**: Quick tests run automatically
- **If quick tests fail**: Claude will be prompted to fix immediately
- **Continuous validation**: No broken state accumulates

### Completing Implementation

- **On Stop event**: Full test suite runs
- **If all tests pass**: New STABLE STATE achieved
- **If tests fail**: Claude continues to fix issues

### Disabling for Exploration

```bash
# When you need to explore without constraints
./.claude/hooks/regression-control.sh disable

# Re-enable when ready for disciplined development
./.claude/hooks/regression-control.sh enable
```

## Adapting to Your Project

### Test Command Examples by Language

**JavaScript/TypeScript (Node.js)**:

```bash
# Quick: npm run test:unit
# Full: npm run test:all
```

**Deno**:

```bash
# Quick: deno task test:unit
# Full: deno task test
```

**Python**:

```bash
# Quick: pytest tests/unit -x --tb=short
# Full: pytest --cov
```

**Go**:

```bash
# Quick: go test ./... -short
# Full: go test ./... -race -cover
```

**Rust**:

```bash
# Quick: cargo test --lib
# Full: cargo test --all-features
```

**Java (Spring Boot)**:

```bash
# Quick: ./mvnw test -Dtest="*UnitTest"
# Full: ./mvnw verify
```

### Customizing Test Thresholds

Adjust timeouts in `.claude/settings.json`:

- Quick tests: 30-60 seconds max
- Full tests: 300-600 seconds max

### Adding Context Awareness

Enhance hooks to be context-aware:

```bash
# Check if working on critical paths
if git diff --name-only | grep -q "auth\|payment\|security"; then
    # Run more thorough tests for critical code
    RUN_SECURITY_TESTS=true
fi
```

## Best Practices

1. **Keep QUICK tests fast** (<8-30s) for rapid feedback
2. **FULL tests comprehensive** but reasonable (<5min)
3. **Fix immediately** when quick tests fail
4. **Disable for exploration**, enable for implementation
5. **Adapt test commands** to your project's framework
6. **Version control hooks** in `.claude/hooks/`
7. **Document test categories** for team clarity

## Troubleshooting

### Tests Not Running

```bash
# Check if mode is enabled
./.claude/hooks/regression-control.sh status

# Verify hook scripts are executable
chmod +x .claude/hooks/*.sh
chmod +x scripts/*-test.sh

# Test scripts manually
./scripts/quick-test.sh
./scripts/full-test.sh
```

### Claude Not Responding to Failures

- Ensure exit code 2 is used for blocking
- Check `claude --debug` for hook execution details
- Verify JSON output format if using advanced mode

### Performance Issues

- Optimize quick test selection
- Use test parallelization
- Consider test caching strategies
- Adjust timeouts appropriately

## Advanced Features

### Progressive Test Levels

Add intermediate test levels:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "[ -f .claude/critical-mode ] && ./scripts/integration-test.sh || ./scripts/quick-test.sh"
          }
        ]
      }
    ]
  }
}
```

### Smart Test Selection

Run only affected tests:

```bash
#!/bin/bash
# Determine which tests to run based on changed files
CHANGED_FILES=$(git diff --name-only HEAD)

if echo "$CHANGED_FILES" | grep -q "src/api"; then
    npm run test:api
elif echo "$CHANGED_FILES" | grep -q "src/ui"; then
    npm run test:ui
else
    npm run test:unit
fi
```

### Test Results Caching

Cache test results to avoid redundant runs:

```bash
#!/bin/bash
# Generate hash of relevant files
TEST_HASH=$(find src tests -type f -exec md5sum {} \; | md5sum | cut -d' ' -f1)
CACHE_FILE=".claude/test-cache/$TEST_HASH"

if [ -f "$CACHE_FILE" ]; then
    echo "✅ Tests already passed for this code state (cached)"
    exit 0
fi

# Run tests
if npm run test:quick; then
    mkdir -p .claude/test-cache
    touch "$CACHE_FILE"
    exit 0
else
    exit 2
fi
```

## Summary

The regression testing feedback cycle creates a safety net that:

- **Maintains stability** while implementing features
- **Provides immediate feedback** on breaking changes
- **Ensures quality** through continuous validation
- **Adapts to context** as requirements evolve

Enable it when you need disciplined development with safety guarantees. Disable it when exploring or prototyping. The cycle ensures your project moves from stable state to stable state, never accumulating technical debt during implementation.
