# Regression Testing Loop [TEST]

an attempt to automate my regression testing process for claude-code

## Quick Start

```bash
# Set up regression testing for your project
/regression-testing-loop-setup

# With options
/regression-testing-loop-setup --auto-fix           # Auto-fix mode for CI
/regression-testing-loop-setup --strict             # No tolerance for failures
/regression-testing-loop-setup --framework <framework-name>   # Specify framework
```

## The Loop

1. **Baseline** - Existing tests define expected behavior
2. **Implement** - Add new feature (may break tests)
3. **Fix** - Repair broken tests BEFORE adding new ones
4. **Extend** - Add tests for new feature
5. **Verify** - All tests pass

## When Tests Fail

You'll see this menu:

```
[1] Fix implementation
[2] Analyze failures  
[3] Update tests (if intentional)
[4] Revert changes
[5] Save report
[6] Exit
```

**Choose [1]** - Most common, fixes your code to pass existing tests
**Choose [3]** - Only if the behavior change was intentional

## Commands After Setup

```bash
# Run regression tests
.claude/scripts/regression-test-runner.sh

# Generate report
.claude/scripts/regression-report.sh

# Check last run
cat .claude/last-test-run.log
```

## Modes

- **Interactive** (default) - Prompts for decisions
- **Auto-fix** (`--auto-fix`) - Attempts fixes automatically
- **Strict** (`--strict`) - Fails immediately, no recovery

## Example Flow

```bash
# 1. Setup
/regression-testing-loop-setup

# 2. Implement wishlist feature
# (tests fail automatically via hook)

# 3. Choose [1] to fix implementation
# (preserves existing behavior)

# 4. Tests pass, add new wishlist tests

# 5. Run final verification
.claude/scripts/regression-test-runner.sh
```

## Key Rule

**Never add new tests until existing tests pass** - This ensures no regressions.