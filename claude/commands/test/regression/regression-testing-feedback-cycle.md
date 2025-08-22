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

I'll automatically set up the regression testing feedback cycle for your project. Just tell me your test commands!

## Your Task

Please provide your test commands, or let me detect them automatically:

**Option 1: Tell me your test commands**
- QUICK tests command: (e.g., `npm run test:unit`)
- FULL tests command: (e.g., `npm run test`)

**Option 2: Let me auto-detect**
- Just say "auto-detect" and I'll find your test commands

Once you provide the commands (or I detect them), I will automatically:

1. **Create test runner scripts** (`scripts/quick-test.sh` and `scripts/full-test.sh`)
2. **Set up Claude hooks** in `.claude/settings.json`
3. **Install hook scripts** in `.claude/hooks/`
4. **Create control script** for enabling/disabling the cycle
5. **Enable regression mode** to start the feedback cycle

The setup will be completely automated - no manual file creation needed!

## Manual Setup Guide (if preferred)

### 1. Prerequisites

Your project needs:
- A QUICK test suite (basic functionality, <30s runtime)
- A FULL test suite (comprehensive coverage + E2E, <5min runtime)
- Test runner scripts or commands

## Usage Workflow

### Starting a Feature Implementation

```bash
# 1. Ensure you're in a stable state
./scripts/full-test.sh  # All tests should pass

# 2. Enable regression testing mode
./.claude/hooks/regression-control.sh enable

# 3. Start implementing with Claude
# Claude will now:
#   - Run quick tests after each code change
#   - Run full tests when stopping
#   - Ensure continuous stability
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