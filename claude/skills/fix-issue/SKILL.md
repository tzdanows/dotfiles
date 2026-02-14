---
name: fix-issue
description: "End-to-end issue-to-PR pipeline. Takes a GitHub issue number, investigates the problem, creates a branch, writes tests first (TDD), implements the fix, and opens a pull request."
disable-model-invocation: true
argument-hint: "[issue-number]"
allowed-tools: Read, Grep, Glob, Bash, Write, Edit
---

# Fix Issue Pipeline

Takes a GitHub issue number and drives it from investigation through to a merged-ready pull request. Follows test-driven development: write the failing test first, then implement the fix.

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status`
- Remote: !`git remote -v`
- Recent commits: !`git log --oneline -10`

## Input

`$ARGUMENTS` must contain a GitHub issue number (e.g., `42` or `#42`).

IF `$ARGUMENTS` is empty or not a valid issue number:

- Print: "Usage: /fix-issue [issue-number]"
- STOP

## Procedure

### STEP 1: Fetch and understand the issue

Parse the issue number from `$ARGUMENTS` (strip leading `#` if present).

```bash
gh issue view <number> --json number,title,body,labels,assignees,milestone,state
```

IF the issue is closed:

- Warn the user that this issue is already closed
- Ask whether to proceed anyway

Read the issue carefully. Extract:

1. **Problem statement** - What is broken or missing?
2. **Reproduction steps** - How to trigger the issue?
3. **Acceptance criteria** - What does "fixed" look like?
4. **Scope** - Which parts of the codebase are likely involved?
5. **Labels** - Is this a bug, feature, enhancement?

IF the issue is unclear or lacks detail:

- State what is ambiguous
- Propose assumptions
- Ask the user to confirm before proceeding

### STEP 2: Investigate the codebase

Based on the issue analysis, explore the relevant code:

1. **Find related files** using Grep and Glob:
   - Search for keywords from the issue (error messages, function names, endpoints)
   - Locate test files in the same area
   - Identify configuration files that may be involved

2. **Understand the architecture** around the issue:
   - Read the relevant source files
   - Trace the call chain / data flow
   - Identify dependencies and integration points

3. **Check for existing tests**:
   - Find tests covering the affected code
   - Understand the testing patterns used in the project
   - Identify the test framework and conventions

4. **Document findings**:
   - Root cause (for bugs) or implementation location (for features)
   - Files that need modification
   - Files that need new tests
   - Potential risks or side effects

### STEP 3: Create a feature branch

Ensure you are starting from the latest base:

```bash
git fetch origin
```

Determine the base branch (`main` or `master`).

Create a descriptive branch:

```bash
git checkout -b fix/issue-<number>-<short-description> origin/main
```

Branch naming rules:

- Bug fix: `fix/issue-<number>-<description>`
- Feature: `feat/issue-<number>-<description>`
- Refactor: `refactor/issue-<number>-<description>`
- Keep `<description>` to 3-5 hyphenated words

### STEP 4: Write failing tests FIRST (TDD)

This step is mandatory. Write the test before the implementation.

1. **Identify the test file**:
   - If tests exist for the affected module, add to that file
   - If no tests exist, create a new test file following project conventions
   - Match the project's test organization (`/tests/`, `*_test.go`, `*_test.rs`, `*Test.java`, etc.)

2. **Write the test**:
   - Use clear, descriptive test names
   - Test the specific behavior described in the issue
   - For bugs: write a test that reproduces the bug (should fail before the fix)
   - For features: write a test that validates the expected behavior
   - Include edge cases

3. **Verify the test fails** (for bug fixes):
   - Run the specific test to confirm it fails
   - Use single-test runners for speed:
     - Deno: `deno test --filter="test name"`
     - Go: `go test -run TestName ./...`
     - Rust: `cargo test test_name`
     - Java: framework-specific single test runner
   - If the test passes before any code change, the test is not correctly reproducing the issue

4. **Commit the test**:
   ```
   test(scope): add failing test for issue #<number>

   Reproduces the bug described in #<number> where <brief description>.
   This test should pass after the fix is applied.
   ```

### STEP 5: Implement the fix

Now write the actual fix or feature implementation.

1. **Make minimal, focused changes**:
   - Fix only what the issue describes
   - Do not refactor unrelated code in the same commit
   - Do not add features beyond the issue scope

2. **Follow project conventions**:
   - Match existing code style
   - Use the project's error handling patterns
   - Follow the existing architectural patterns

3. **Verify the test passes**:
   - Run the specific test again to confirm it now passes
   - Run the broader test suite to check for regressions:
     - Deno: `deno task test`
     - Go: `go test ./...`
     - Rust: `cargo test`
     - Java: `deno task test` or project-specific runner

4. **Run type checking / linting**:
   - Deno: `deno check` and `deno lint`
   - Go: `go vet ./...`
   - Rust: `cargo check` and `cargo clippy`
   - Java: project-specific linting

5. **Commit the implementation**:
   ```
   fix(scope): resolve <description> from issue #<number>

   <Explain WHY the fix works, not just what changed.>

   Fixes #<number>
   ```

### STEP 6: Self-review

Before creating the PR, review your own changes:

1. **Review the full diff**:
   ```bash
   git diff main..HEAD
   ```

2. **Check for common issues**:
   - No debug statements or temporary code left in
   - No commented-out code
   - No hardcoded values that should be configurable
   - No sensitive data (API keys, credentials)
   - No emojis in code, comments, or commit messages
   - Error handling is complete
   - Edge cases are covered

3. **Verify all tests pass**:
   ```bash
   # Run the full test suite one more time
   deno task test  # or cargo test, go test ./..., etc.
   ```

4. **Format code**:
   ```bash
   deno fmt  # or cargo fmt, gofmt, etc.
   ```

### STEP 7: Push and create the PR

Push the branch:

```bash
git push -u origin <branch-name>
```

Create the PR with `gh`:

```bash
gh pr create --title "Fix: <description>" --body "$(cat <<'EOF'
## Summary

- Fixes the issue where <problem description>
- Root cause was <root cause>
- Applied fix by <solution approach>

## Changes

- `path/to/file.ext` - Description of change
- `path/to/test_file.ext` - Added test reproducing the issue

## Test Plan

- [ ] Added failing test that reproduces issue #<number>
- [ ] Test passes after fix
- [ ] Full test suite passes
- [ ] Type checking passes
- [ ] No regressions detected

## Related Issues

Fixes #<number>
EOF
)"
```

### STEP 8: Verify and report

1. Show the PR URL to the user
2. Verify CI checks: `gh pr checks`
3. Show the PR summary: `gh pr view --json number,title,url,additions,deletions,changedFiles`
4. Comment on the issue linking the PR:
   ```bash
   gh issue comment <number> --body "Fix submitted in PR #<pr-number>"
   ```

## Error Recovery

### Test framework not detected

- Look for `deno.json`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`
- Check for existing test files to identify the framework
- Ask the user if still unclear

### Issue does not exist

```bash
gh issue view <number>
# If 404: inform user the issue was not found
```

### Branch already exists

```bash
git branch -a | rg "fix/issue-<number>"
# If exists: ask user whether to use existing branch or create a new one
```

### Merge conflicts when creating branch

```bash
git fetch origin
git checkout -b fix/issue-<number>-<desc> origin/main
# If conflicts with local changes: stash first
```

### Pre-commit hook failure

1. Read the hook output
2. Fix the issue (formatting, linting, types)
3. Re-stage fixed files
4. Create a NEW commit (never amend after hook failure)

## Quality Standards

- Every bug fix MUST have a regression test
- Every feature MUST have at least one happy-path test
- Commit messages MUST follow conventional commit format
- PR description MUST link the issue with `Fixes #<number>`
- Code MUST pass type checking and linting before PR
- No emojis in any output, commits, or PR content
