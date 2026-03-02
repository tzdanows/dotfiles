---
allowed-tools: Read, Bash(git:*), Bash(rg:*), Bash(fd:*), Bash(date:*), Bash(jq:*), Bash(bat:*)
description: Comprehensive automated git repository review with security analysis and quality assessment
---

## Context

- Session ID: !`date +%s%N`
- Current repository status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`
- Staged changes summary: !`git diff --staged --name-only | head -10 || echo "No staged changes"`
- Unstaged changes summary: !`git diff --name-only | head -10 || echo "No unstaged changes"`
- Last commit details: !`git log -1 --stat --pretty=format:"%h %s (%an, %cr)" || echo "No commits found"`
- Modified file types: !`git status --porcelain | awk '{print $2}' | sed 's/.*\.//' | sort | uniq -c | head -5 || echo "No changes detected"`
- Repository size context: !`git log --oneline | wc -l | tr -d ' '` commits, !`fd . -t f | wc -l | tr -d ' '` files

## Your Task

STEP 1: Initialize comprehensive repository review session

- CREATE review session state: `/tmp/git-review-session-$SESSION_ID.json`
- ANALYZE repository context from dynamic git status and change summary
- DETERMINE review scope (staged, unstaged, recent commits, or specific target)
- LOG session initialization with timestamp and repository metadata

TRY:

```json
{
  "sessionId": "$SESSION_ID",
  "timestamp": "$(date -Iseconds 2>/dev/null || date -Iseconds)",
  "repository": "$(basename $(git rev-parse --show-toplevel))",
  "branch": "$(git branch --show-current)",
  "reviewScope": "auto-detect",
  "changesDetected": {
    "staged": "$(git diff --staged --name-only | wc -l | tr -d ' ')",
    "unstaged": "$(git diff --name-only | wc -l | tr -d ' ')",
    "untracked": "$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')"
  }
}
```

CATCH (git_access_failed):

- LOG error details to session state
- PROVIDE guidance for repository access issues
- CONTINUE with available analysis

STEP 2: Comprehensive change analysis with automated context gathering

**Current Changes Deep Analysis:**

FOR EACH change category:

- **Staged Changes Analysis**:
  ```bash
  if [ "$(git diff --staged --name-only | wc -l | tr -d ' ')" -gt 0 ]; then
    echo " Analyzing staged changes..."
    git diff --staged --stat
    echo " Detailed staged diff available for review"
  fi
  ```

- **Unstaged Changes Analysis**:
  ```bash
  if [ "$(git diff --name-only | wc -l | tr -d ' ')" -gt 0 ]; then
    echo "️  Analyzing unstaged changes..."
    git diff --stat
    echo " Detailed unstaged diff available for review"
  fi
  ```

- **Recent Commit Analysis**:
  ```bash
  echo " Recent commit analysis..."
  git log -3 --pretty=format:"%h %s (%an, %cr)" --stat
  echo " Last 3 commits analyzed for patterns and quality"
  ```

STEP 3: Advanced security analysis with automated pattern detection

TRY:

**Automated Security Scanning:**

```bash
echo " Performing automated security analysis..."

# Credential and API key detection
echo "   Scanning for exposed credentials..."
rg -i "(api[_-]?key|secret|password|token|credential)" . --type-not=lock --type-not=log -C 1 || echo "     No obvious credential exposures found"

# Hardcoded sensitive patterns
echo "   Checking for hardcoded sensitive data..."
rg "(BEGIN\s+(?:RSA\s+)?(?:PRIVATE\s+)?KEY|ssh-rsa|ssh-ed25519)" . --type-not=lock -C 1 || echo "     No hardcoded keys detected"

# Database connection strings
echo "  ️  Scanning for exposed database connections..."
rg "(mongodb://|postgres://|mysql://|redis://)" . --type-not=lock -C 1 || echo "     No exposed database URLs found"

# Environment variable leaks
echo "   Checking for environment variable exposures..."
rg "process\.env\.[A-Z_]+" . --type js --type ts -C 1 || echo "    ℹ️  No JavaScript env var usage detected"

# Shell injection vulnerabilities
echo "   Analyzing shell injection risks..."
rg "(\$\{[^}]+\}|\$[A-Z_]+)" . --type sh --type bash -C 1 || echo "     No shell variable substitution risks found"
```

**Project-Specific Security Checks:**

- **Dotfiles Security**: Verify no personal credentials in shell configs
- **Script Security**: Check shell script quoting and escaping patterns
- **Permission Validation**: Ensure executable scripts have appropriate permissions

CATCH (security_scan_failed):

- LOG scan failures to session state
- PROVIDE manual security checklist
- CONTINUE with other review aspects

STEP 4: Automated code quality assessment with CLAUDE.md compliance

**Think hard about code quality implications and architectural decisions in the changes.**

**Modern CLI Tool Usage Validation:**

```bash
echo "️  Validating modern tool preferences..."

# Check for legacy tool usage (per CLAUDE.md requirements)
echo "  ️  Scanning for deprecated tool usage..."
rg "\b(grep|find|cat|ls|df|top)\b" . --type sh --type bash -C 1 || echo "     No legacy tool usage detected"

# Verify modern alternatives are used
echo "   Checking for modern tool adoption..."
rg "\b(rg|fd|bat|eza|jq|yq|delta|zoxide)\b" . --type sh --type bash -C 1 || echo "    ℹ️  Consider adopting modern CLI tools"
```

**Deno Best Practices Validation:**

```bash
echo " Validating Deno project compliance..."

# Check for JSR imports (preferred over deno.land)
if [ -f "deno.json" ] || fd "\.ts$" . >/dev/null; then
  echo "   Analyzing import patterns..."
  rg "from ['\"]https://deno\.land" . --type ts || echo "     No legacy deno.land imports found"
  rg "jsr:@std/" . --type json --type ts || echo "     Consider migrating to JSR imports"
fi

# Validate deno.json task structure
if [ -f "deno.json" ]; then
  echo "   Validating task definitions..."
  jq '.tasks // {} | keys[]' deno.json 2>/dev/null | head -5 || echo "    ️  No tasks defined in deno.json"
fi
```

**Error Handling and Code Structure:**

- ANALYZE exception handling patterns and completeness
- VERIFY proper input validation in changed functions
- CHECK for resource cleanup and memory leak patterns
- EVALUATE naming conventions and code clarity

STEP 5: Test coverage and quality validation

**Automated Test Discovery and Analysis:**

```bash
echo " Analyzing test coverage and quality..."

# Discover test files
echo "   Test file discovery..."
test_files=$(fd "(test|spec)\.ts$|_test\.ts$" . | wc -l | tr -d ' ')
echo "    Found $test_files test files"

# Analyze test patterns
if [ "$test_files" -gt 0 ]; then
  echo "   Test pattern analysis..."
  rg "Deno\.test\(" . --type ts -c || echo "    ℹ️  No Deno.test patterns found"
  rg "describe\(|it\(" . --type ts -c || echo "    ℹ️  No traditional test framework usage"
fi

# Check for test coverage of changed files
changed_files=$(git diff --name-only HEAD~1 2>/dev/null | fd "\.ts$" | wc -l | tr -d ' ')
if [ "$changed_files" -gt 0 ]; then
  echo "   Test coverage for changed files..."
  echo "    Changed TypeScript files: $changed_files"
  echo "    Recommendation: Verify each changed file has corresponding tests"
fi
```

STEP 6: Performance analysis and optimization opportunities

**Automated Performance Pattern Detection:**

```bash
echo " Analyzing performance implications..."

# Identify potential N+1 query patterns
echo "   Checking for N+1 query risks..."
rg "(for|forEach).*\.(query|find|get)" . --type ts --type js -C 1 || echo "     No obvious N+1 patterns detected"

# Check for blocking I/O patterns
echo "   Scanning for blocking operations..."
rg "fs\.readFileSync|fs\.writeFileSync" . --type ts --type js -C 1 || echo "     No blocking file operations found"

# Analyze algorithmic complexity indicators
echo "   Checking for complexity concerns..."
rg "for.*for|while.*while" . --type ts --type js -C 1 || echo "     No obvious nested loop patterns"
```

STEP 7: Documentation and project standards compliance

**Documentation Completeness Assessment:**

```bash
echo " Evaluating documentation coverage..."

# Check for README updates
if git diff --name-only HEAD~1 2>/dev/null | rg -q "README"; then
  echo "   README changes detected - verify completeness"
fi

# Validate CLAUDE.md compliance
if [ -f "CLAUDE.md" ]; then
  echo "   CLAUDE.md project guidelines present"
  if git diff --name-only HEAD~1 2>/dev/null | rg -q "CLAUDE\.md"; then
    echo "    ️  CLAUDE.md modified - review guideline changes"
  fi
fi

# Check for inline documentation
changed_code_files=$(git diff --name-only HEAD~1 2>/dev/null | fd "\.(ts|js|rs|go|java)$" | wc -l | tr -d ' ')
if [ "$changed_code_files" -gt 0 ]; then
  echo "   Code documentation analysis..."
  echo "    Changed code files: $changed_code_files"
  echo "    Verify complex logic includes explanatory comments"
fi
```

STEP 8: Project-specific validation and cross-platform compatibility

**Dotfiles-Specific Checks:**

```bash
echo " Performing dotfiles-specific validation..."

# Shell configuration portability
if fd "\.(sh|bash|zsh)$" . >/dev/null; then
  echo "   Shell script portability check..."
  rg "#!/bin/(bash|sh)" . --type sh -c || echo "    ℹ️  No shell shebangs detected"
fi

# Cross-platform compatibility
echo "   Cross-platform compatibility analysis..."
rg "(date|gsed|gawk)" . --type sh --type ts -C 1 || echo "     No macOS-specific tool usage detected"

# Backup/restore logic validation
if rg -q "(backup|restore)" . --type ts --type sh; then
  echo "   Backup/restore logic detected - verify safety mechanisms"
fi
```

STEP 9: Generate comprehensive structured review report

**Review Summary Generation:**

- COMPILE all findings from automated scans and manual analysis
- CATEGORIZE issues by severity: High, Medium, Low, ℹ️ Info
- PROVIDE specific file references and line numbers where applicable
- GENERATE actionable recommendations with clear next steps
- CREATE review checklist for manual verification

**Final Review Report Format:**

```markdown
# Git Repository Review Report

**Session ID**: $SESSION_ID
**Timestamp**: $(date -Iseconds 2>/dev/null || date -Iseconds)
**Repository**: $(basename $(git rev-parse --show-toplevel))
**Branch**: $(git branch --show-current)

## Summary

- Total files analyzed: [count]
- Security issues found: [count]
- Code quality concerns: [count]
- Performance optimizations: [count]
- Documentation gaps: [count]

## Critical Findings

[High-priority issues requiring immediate attention]

## Recommendations

[Medium-priority improvements for code quality]

## Observations

[Low-priority notes and minor suggestions]

## Checklist for Manual Review

- [ ] Verify all security patterns have been addressed
- [ ] Confirm test coverage for changed functionality
- [ ] Validate documentation updates are complete
- [ ] Ensure CLAUDE.md compliance where applicable
- [ ] Review performance implications of algorithmic changes
```

FINALLY:

- SAVE complete review report to `/tmp/git-review-report-$SESSION_ID.md`
- UPDATE session state with completion status
- PROVIDE clear summary of findings and next steps for developer action
