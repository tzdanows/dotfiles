---
name: changelog
description: "Generate a structured changelog from git history between two refs. Groups commits by type (features, fixes, refactors, etc.) and includes PR/issue links."
context: fork
agent: Explore
disable-model-invocation: true
argument-hint: "[from-ref] [to-ref]"
allowed-tools: Read, Grep, Glob, Bash(git *), Bash(gh *)
---

# Generate Changelog

Produce a clean, structured changelog from the git history between two references. Commits are grouped by conventional commit type and enriched with PR and issue links from GitHub.

## Input

`$ARGUMENTS` should contain two git refs separated by a space:

```
<from-ref> <to-ref>
```

Examples:

- `v1.0.0 v1.1.0` - Between two tags
- `v2.0.0 HEAD` - From a tag to current HEAD
- `abc1234 def5678` - Between two commit SHAs
- `main feature-branch` - Between two branches

IF only one ref is provided:

- Use it as `from-ref`
- Default `to-ref` to `HEAD`

IF no refs are provided:

- Find the most recent tag: `git describe --tags --abbrev=0`
- Use that tag as `from-ref` and `HEAD` as `to-ref`
- If no tags exist, use the initial commit as `from-ref`

## Procedure

### STEP 1: Validate refs

```bash
git rev-parse --verify <from-ref>
git rev-parse --verify <to-ref>
```

IF either ref is invalid:

- Report which ref could not be resolved
- List available tags: `git tag --sort=-version:refname | head -20`
- STOP

### STEP 2: Gather commits

Fetch the commit log between the two refs:

```bash
git log <from-ref>..<to-ref> --pretty=format:"%H|%s|%an|%ae|%aI" --no-merges
```

Also fetch merge commits separately for PR detection:

```bash
git log <from-ref>..<to-ref> --pretty=format:"%H|%s|%an|%ae|%aI" --merges
```

Count total commits:

```bash
git rev-list --count <from-ref>..<to-ref>
```

### STEP 3: Gather PR and issue metadata

For each commit, check if it is associated with a PR:

```bash
gh pr list --state merged --search "<commit-sha>" --json number,title,labels,author --limit 5
```

Alternatively, extract PR numbers from merge commit messages (e.g., "Merge pull request #42") or from commit messages containing `(#42)`.

For referenced issues, extract issue numbers from commit messages (e.g., `Fixes #123`, `Closes #456`, `Resolves #789`).

### STEP 4: Parse and classify commits

Parse each commit subject line according to the conventional commit format:

```
type(scope): description
```

Group into categories:

1. **Features** (`feat`) - New capabilities
2. **Bug Fixes** (`fix`) - Corrections to existing behavior
3. **Performance** (`perf`) - Performance improvements
4. **Refactoring** (`refactor`) - Code restructuring
5. **Documentation** (`docs`) - Documentation changes
6. **Tests** (`test`) - Test additions or modifications
7. **Build & CI** (`build`, `ci`) - Build system and CI changes
8. **Chores** (`chore`) - Maintenance and tooling
9. **Style** (`style`) - Code formatting changes
10. **Breaking Changes** - Any commit with `!` or `BREAKING CHANGE` footer

Commits that do not follow conventional commit format go into an **Other** category.

### STEP 5: Detect breaking changes

Scan for breaking changes in two ways:

1. Commits with `!` after the type/scope: `feat(api)!: ...`
2. Commits with `BREAKING CHANGE:` in the body:
   ```bash
   git log <from-ref>..<to-ref> --grep="BREAKING CHANGE" --pretty=format:"%H|%s"
   ```

### STEP 6: Compute statistics

```bash
git diff --stat <from-ref>..<to-ref>
git diff --shortstat <from-ref>..<to-ref>
```

Count:

- Total commits
- Number of contributors: `git log <from-ref>..<to-ref> --format="%an" | sort -u | wc -l`
- Files changed, insertions, deletions

### STEP 7: Generate the changelog

Output the changelog in the following format:

```markdown
# Changelog: <from-ref> .. <to-ref>

> <total-commits> commits by <contributor-count> contributors.
> <files-changed> files changed, <insertions> insertions, <deletions> deletions.

## Breaking Changes

- **scope**: description ([commit-hash-short](commit-url)) - @author

## Features

- **scope**: description (#PR-number) ([commit-hash-short](commit-url)) - @author
- **scope**: description ([commit-hash-short](commit-url)) - @author

## Bug Fixes

- **scope**: description (Fixes #issue) ([commit-hash-short](commit-url)) - @author

## Performance

- **scope**: description ([commit-hash-short](commit-url)) - @author

## Refactoring

- description ([commit-hash-short](commit-url)) - @author

## Documentation

- description ([commit-hash-short](commit-url)) - @author

## Tests

- description ([commit-hash-short](commit-url)) - @author

## Build & CI

- description ([commit-hash-short](commit-url)) - @author

## Chores

- description ([commit-hash-short](commit-url)) - @author

## Other

- description ([commit-hash-short](commit-url)) - @author

---

## Contributors

- @contributor1 (N commits)
- @contributor2 (N commits)
```

### STEP 8: Output

Print the changelog to stdout. The user can redirect or copy as needed.

IF the changelog is very long (> 100 commits):

- Consider summarizing the "Other" and "Chores" categories
- Keep all features, fixes, and breaking changes fully listed

## Formatting Rules

- No emojis anywhere in the output
- Use short commit hashes (7 characters)
- Link commits to GitHub when the remote URL is available
- Link PR numbers as `#N`
- Link issue numbers as `#N`
- Omit empty categories (do not show "## Performance" if there are no perf commits)
- Sort entries within each category by scope, then alphabetically by description
- Use `**scope**:` prefix when scope is present, plain text when it is not

## Edge Cases

### No conventional commits found

- Fall back to listing all commits chronologically
- Note that the project does not appear to use conventional commits

### Single commit between refs

- Still produce the full changelog format (just with one entry)

### No tags in the repository

- Use the first commit: `git rev-list --max-parents=0 HEAD`
- Inform the user that no tags were found

### Monorepo with many commits

- If > 500 commits, warn the user and ask whether to proceed or narrow the range
- Consider grouping by scope as a primary axis instead of type
