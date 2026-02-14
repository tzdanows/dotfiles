---
name: review-changes
description: Multi-agent pre-PR code review. Spawns 4 parallel sub-agents to analyze code quality, silent failures, performance, and type design before opening a PR.
context: fork
disable-model-invocation: true
---

# Review Changes

Multi-agent pre-PR code review that spawns 4 parallel sub-agents to provide comprehensive analysis before a pull request is submitted. Each agent focuses on a distinct concern, and their findings are synthesized into a unified review summary.

## Workflow

### Phase 1: Context Gathering

Before spawning sub-agents, gather all necessary context from the current branch.

1. Identify the base branch (usually `main` or `master`):

```bash
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
```

2. Collect the full diff against the base branch:

```bash
git diff "${BASE_BRANCH}...HEAD"
```

3. Collect the commit log for this branch:

```bash
git log "${BASE_BRANCH}..HEAD" --oneline --no-decorate
```

4. Identify all changed files:

```bash
git diff "${BASE_BRANCH}...HEAD" --name-only
```

5. If a PR already exists for this branch, fetch its description and linked issues:

```bash
gh pr view --json title,body,number,labels 2>/dev/null
```

6. If issues are linked in the PR body or commit messages, fetch their content:

```bash
gh issue view <ISSUE_NUMBER> --json title,body,state 2>/dev/null
```

7. For each changed file, read the full current version to understand broader context beyond the diff hunks.

### Phase 2: Parallel Sub-Agent Analysis

Spawn 4 sub-agents in parallel. Each agent receives:

- The full diff
- The list of changed files
- The commit log
- The PR description and linked issue context (if available)
- The full content of each changed file

#### Agent 1: Code Reviewer

Focus areas:

- Correctness of logic and control flow
- Error handling completeness (missing error cases, swallowed errors, unhelpful error messages)
- Edge cases not covered by the implementation
- API contract violations or breaking changes
- Resource management (file handles, connections, locks, memory)
- Concurrency issues (race conditions, deadlocks, missing synchronization)
- Security concerns (injection, auth bypass, data exposure, unsafe deserialization)
- Code clarity and maintainability (naming, complexity, duplication)
- Adherence to project conventions found in CLAUDE.md, linter configs, or existing patterns

Output format:

```
## Code Review Findings

### Critical
- [file:line] Description of critical issue

### Warnings
- [file:line] Description of warning

### Suggestions
- [file:line] Description of suggestion

### Positive Notes
- [file:line] Description of well-done aspect
```

#### Agent 2: Silent Failure Hunter

Focus areas:

- Functions that return nil/null/zero values without error indication
- Ignored return values (especially error returns in Go, Result in Rust, exceptions in Java)
- Missing null checks or optional unwrapping without guards
- Try/catch blocks that swallow exceptions silently
- Logging statements that do not include enough context for debugging
- Off-by-one errors in loops and slices
- Integer overflow or underflow possibilities
- String encoding assumptions (UTF-8 vs ASCII vs locale-dependent)
- Time zone and locale assumptions
- Default branch handling in switch/match statements
- Implicit type conversions that may lose data
- Goroutine/thread leaks (started but never joined or cancelled)
- Channel/queue operations that may block indefinitely
- Database transactions that may not be committed or rolled back

Output format:

```
## Silent Failure Analysis

### High Risk
- [file:line] Failure mode description | Impact: what breaks | Fix: recommended approach

### Medium Risk
- [file:line] Failure mode description | Impact: what breaks | Fix: recommended approach

### Low Risk
- [file:line] Failure mode description | Impact: what breaks | Fix: recommended approach
```

#### Agent 3: Performance Analyst

Focus areas:

- N+1 query patterns in database access
- Unbounded collection growth (lists, maps, channels without size limits)
- Missing pagination for list/query endpoints
- Unnecessary allocations in hot paths (especially in loops)
- Blocking I/O on async/event-loop threads
- Missing indexes suggested by query patterns
- Cache invalidation gaps or missing caching opportunities
- Serialization/deserialization overhead (unnecessary marshaling)
- Network call patterns (chatty protocols, missing batching, no connection pooling)
- Large object copying where references/pointers would suffice
- Regex compilation inside loops instead of precompilation
- String concatenation in loops instead of builder patterns
- Missing timeouts on network calls, database queries, or external service requests
- Resource pool exhaustion (connection pools, thread pools)

Output format:

```
## Performance Analysis

### Bottlenecks
- [file:line] Issue description | Severity: high/medium/low | Recommendation

### Optimization Opportunities
- [file:line] Description | Expected impact

### Resource Concerns
- [file:line] Description | Risk level
```

#### Agent 4: Type Design Analyzer

Focus areas:

- Type safety of public API boundaries (function signatures, struct fields, interface definitions)
- Appropriate use of generics vs concrete types
- Enum/sum type exhaustiveness in pattern matching
- Nullable types that should be non-nullable (or vice versa)
- Stringly-typed values that should be dedicated types (IDs, URLs, paths, currencies)
- Primitive obsession (using int/string where a domain type adds safety)
- Interface segregation (interfaces that are too broad or too narrow)
- Struct/class field visibility (public fields that should be private)
- Builder pattern opportunities for complex construction
- Type aliases that add clarity vs those that add confusion
- DTO vs domain model separation
- Consistency of error types across the codebase
- Correct use of ownership and borrowing (Rust), pointer vs value receivers (Go), or immutability (Java records)

Output format:

```
## Type Design Analysis

### Type Safety Issues
- [file:line] Description | Current type | Recommended type | Rationale

### Design Improvements
- [file:line] Description | Pattern to apply

### Consistency Issues
- [file:line] Description | How it diverges from codebase conventions
```

### Phase 3: Cross-Reference and Intent Validation

After all sub-agents complete, the main agent performs:

1. **Intent Cross-Reference**: Compare the PR description and linked issue requirements against the actual changes. Identify:
   - Requirements mentioned in issues but not addressed in the diff
   - Changes in the diff that are not explained by the PR description or issues
   - Scope creep (unrelated changes bundled in)

2. **Broader Codebase Impact**: For each changed file, check:
   - Who imports or depends on the changed modules
   - Whether callers of modified functions are updated accordingly
   - Whether test files cover the modified code paths
   - Whether configuration or migration files need updates

3. **Finding Deduplication**: Merge overlapping findings from the 4 sub-agents into a single deduplicated list.

4. **Severity Calibration**: Re-evaluate severity ratings with full context. A "low risk" silent failure in a payment path becomes "critical."

### Phase 4: Review Summary

Produce a single structured review document:

```markdown
# Pre-PR Review Summary

## Branch: <branch-name>

## Commits: <count> commits against <base-branch>

## Files Changed: <count>

## Intent Alignment

- [ ] All linked issue requirements are addressed
- [ ] No unexplained changes outside stated scope
- [ ] PR description accurately reflects the diff

## Critical Findings (must fix before merge)

1. [Category] [file:line] Description

## Warnings (should fix, may defer with justification)

1. [Category] [file:line] Description

## Suggestions (optional improvements)

1. [Category] [file:line] Description

## Broader Impact

- List of downstream files/modules affected
- Missing test coverage for changed paths
- Configuration or migration needs

## Positive Observations

- Well-done aspects worth noting

## Recommendation

- [ ] Ready for PR
- [ ] Address critical findings first
- [ ] Needs architectural discussion
```

## Notes

- This skill is designed to run BEFORE creating a PR, not as a replacement for human review.
- Sub-agents are read-only. They analyze code but do not modify files.
- The review is opinionated and may flag false positives. Use judgment when interpreting findings.
- For large diffs (>2000 lines), consider splitting the review into multiple runs by directory or module.
- Each sub-agent operates in its own context window, which allows analysis of large codebases without hitting token limits in a single agent.
