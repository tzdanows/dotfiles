---
name: diff-explain
description: "Explain a git diff in plain English. Summarizes what changed, why it likely changed, potential risks, and impact on the codebase."
context: fork
agent: Explore
disable-model-invocation: true
argument-hint: "[ref]"
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

# Explain a Diff

Take a git ref (commit SHA, branch name, tag, or range) and produce a clear, plain-English explanation of what changed, why it likely changed, what the risks are, and what areas of the codebase are affected.

## Input

`$ARGUMENTS` should contain a git reference. Supported formats:

| Input                  | Interpretation                     |
| ---------------------- | ---------------------------------- |
| `abc1234`              | Single commit                      |
| `HEAD`                 | Latest commit                      |
| `HEAD~3`               | Three commits ago                  |
| `v1.0.0..v1.1.0`       | Range between tags                 |
| `main..feature-branch` | Branch diff                        |
| `--staged`             | Currently staged changes           |
| (empty)                | Unstaged working directory changes |

## Procedure

### STEP 1: Resolve the ref and obtain the diff

Based on `$ARGUMENTS`:

IF `$ARGUMENTS` is empty:

- Explain unstaged changes: `git diff`
- Also check staged: `git diff --cached`
- If both exist, explain both sections separately

IF `$ARGUMENTS` is `--staged`:

- `git diff --cached`

IF `$ARGUMENTS` contains `..` (a range):

- `git diff <from>..<to>`
- `git log --oneline <from>..<to>`

IF `$ARGUMENTS` is a single ref (commit, tag, branch):

- Show that specific commit: `git show <ref> --stat` and `git show <ref>`
- Also get the commit message and metadata: `git log -1 --format="%H%n%s%n%b%n%an%n%aI" <ref>`

Verify the ref is valid:

```bash
git rev-parse --verify <ref>
```

IF invalid:

- Report the error
- Suggest alternatives: recent commits (`git log --oneline -10`), tags (`git tag --sort=-version:refname | head -10`)
- STOP

### STEP 2: Gather the diff content

Get the full diff:

```bash
git diff <resolved-range> -- . ':!*.lock' ':!package-lock.json' ':!*.min.js' ':!*.min.css'
```

Exclude noisy generated files from the explanation (lock files, minified assets) but note their presence.

Get the stat summary:

```bash
git diff --stat <resolved-range>
git diff --shortstat <resolved-range>
```

IF this is a range with multiple commits, also gather:

```bash
git log --oneline <range>
```

### STEP 3: Check for associated PR/issue context

IF the ref is a single commit:

```bash
gh pr list --state merged --search "<commit-sha>" --json number,title,body --limit 1
```

IF the commit message references an issue:

```bash
gh issue view <issue-number> --json title,body,labels --limit 1
```

This context helps explain the WHY behind the changes.

### STEP 4: Analyze the diff

Read the diff carefully and identify:

1. **Files changed** - Group by directory/module/package
2. **Nature of changes per file**:
   - New file added
   - File deleted
   - File renamed/moved
   - Logic change (behavioral impact)
   - Configuration change
   - Test change
   - Documentation change
   - Dependency change
   - Formatting/style only
3. **Patterns across files** - Are multiple files changing in a coordinated way?
4. **Data flow impact** - Do the changes affect how data moves through the system?

### STEP 5: Assess risk

For each significant change, evaluate:

- **Behavioral risk** - Could this change existing behavior in unexpected ways?
- **Security risk** - Does this touch authentication, authorization, input validation, or data handling?
- **Performance risk** - Could this affect latency, memory, or throughput?
- **Dependency risk** - Are new dependencies added? Are existing ones removed or updated?
- **Compatibility risk** - Does this break APIs, configs, or data formats?
- **Test coverage** - Are the changed code paths covered by tests? Were tests updated?

### STEP 6: Generate the explanation

Produce a structured explanation in the following format:

```markdown
# Diff Explanation: <ref or range>

## Overview

<2-3 sentence high-level summary of what this change does and why.>

**Scope:** <N> files changed, <insertions> insertions, <deletions> deletions

## What Changed

### <Module/Area 1>

- `path/to/file.ext` - <Plain English description of what changed in this file and why>
- `path/to/other.ext` - <Description>

### <Module/Area 2>

- `path/to/file.ext` - <Description>

## Why

<Explain the likely motivation for this change. Use the commit message, PR description,
or issue context if available. If not available, infer from the code changes.>

## Impact Analysis

### Behavioral Changes

- <Description of how the system behavior changes, if at all>

### API Changes

- <Any changes to public APIs, endpoints, function signatures>
- <Note if this is a breaking change>

### Configuration Changes

- <Any changes to config files, environment variables, feature flags>

### Dependency Changes

- <Added, removed, or updated dependencies>

## Risk Assessment

| Area          | Risk Level      | Notes |
| ------------- | --------------- | ----- |
| Correctness   | Low/Medium/High | <Why> |
| Security      | Low/Medium/High | <Why> |
| Performance   | Low/Medium/High | <Why> |
| Compatibility | Low/Medium/High | <Why> |

## Test Coverage

- <Were tests added or updated?>
- <Are the changed code paths covered?>
- <Are there gaps in test coverage?>

## Recommendations

- <Any suggestions for the author or reviewer>
- <Additional tests that should be written>
- <Edge cases to consider>
```

## Output Rules

- Write in plain English, not code jargon when possible
- Explain what the code DOES, not just what lines changed
- Focus on behavioral impact over mechanical description
- No emojis anywhere in the output
- Use concrete specifics, not vague generalities
- If the diff is trivial (formatting only, typo fix), say so concisely without the full template
- If the diff is large (> 1000 lines), summarize by module/area rather than file-by-file

## Edge Cases

### Empty diff

- Report that there are no changes between the given refs
- STOP

### Binary files changed

- Note which binary files changed
- Report their size change if possible
- Do not attempt to explain binary content

### Very large diff (> 50 files or > 2000 lines)

- Provide a high-level summary organized by module/package
- Highlight the most significant changes
- List all changed files in a compact format
- Focus the detailed explanation on the highest-risk changes

### Merge commit

- Explain what was merged and from which branch
- Focus on the net effect of the merge, not individual commits
- Note any conflict resolutions visible in the diff

### Generated / vendored files

- Note their presence but do not explain them in detail
- Flag if generated files appear to have been manually edited (this is a risk)

### Rename detection

```bash
git diff -M --diff-filter=R <range>
```

- Report renames separately from content changes
- Note the similarity percentage if relevant
