---
name: create-pr
description: "Reference skill for creating pull requests. Full workflow: commit changes, push branch, open PR with gh CLI. Includes commit conventions, branch naming, and error recovery."
---

# Create Pull Request

End-to-end workflow for creating a well-structured pull request. This skill covers everything from committing staged changes to opening the PR on GitHub using the `gh` CLI.

## Context

Gather the following before proceeding:

- Current git status: !`git status`
- Staged diff: !`git diff --cached`
- Unstaged diff: !`git diff`
- Current branch: !`git branch --show-current`
- Remote tracking info: !`git remote -v`
- Recent commits on this branch: !`git log --oneline -15`
- Base branch detection: !`git log --oneline main..HEAD 2>/dev/null || git log --oneline master..HEAD 2>/dev/null`
- Existing PRs from this branch: !`gh pr list --head $(git branch --show-current) --json number,title,state 2>/dev/null`

## Prerequisites

Before creating a PR, verify:

1. You are NOT on `main` or `master` (never push directly to these)
2. The `gh` CLI is authenticated (`gh auth status`)
3. There is a remote configured (`git remote -v`)

## Procedure

### STEP 1: Ensure all changes are committed

IF there are unstaged or staged changes:

- Follow the commit skill workflow:
  - Analyze the diff
  - Generate a conventional commit message
  - Stage specific files (never `git add .` without approval)
  - Commit with proper message format
- Handle pre-commit hook failures (fix, re-stage, create NEW commit)

IF there are no changes and no commits ahead of the base branch:

- Inform the user there is nothing to create a PR for
- STOP

### STEP 2: Determine the base branch

Check which base branch to target:

1. If `main` exists: use `main`
2. If only `master` exists: use `master`
3. If a different default is configured: use that
4. If uncertain: ask the user

Compute the full diff against the base:

```bash
git diff main...HEAD
git log --oneline main..HEAD
```

### STEP 3: Validate branch naming

The current branch should follow a naming convention. If it does not, warn but proceed:

Preferred patterns:

- `feat/description` or `feature/description`
- `fix/description` or `bugfix/description`
- `chore/description`
- `refactor/description`
- `docs/description`
- `test/description`
- `release/version`

IF the branch is named poorly (e.g., `temp`, `test`, `my-branch`):

- Suggest a better name
- Offer to rename: `git branch -m new-name`
- Update tracking if renamed

### STEP 4: Push to remote

Check if the branch has an upstream:

```bash
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
```

IF no upstream exists:

- Push with upstream tracking: `git push -u origin <branch-name>`

IF upstream exists but local is ahead:

- Push: `git push`

IF push fails:

- Check for divergence: `git status` and `git log --oneline @{u}..HEAD`
- If behind remote: `git pull --rebase` then push again
- If force push needed: WARN the user and ask for explicit confirmation
- NEVER force push to main/master

### STEP 5: Analyze all commits for PR description

Review ALL commits that will be included (not just the latest):

```bash
git log --oneline main..HEAD
```

For each commit, understand:

- What changed
- Why it changed
- What areas of the codebase are affected

Group changes by theme or concern for the PR description.

### STEP 6: Draft the PR

Generate a PR title and body:

**Title rules:**

- Under 72 characters
- Descriptive of the overall change
- No conventional commit prefix in the title (that is for commits, not PRs)
- Good: "Add health check endpoint for Kubernetes probes"
- Bad: "feat: stuff" or "Update files"

**Body structure:**

```markdown
## Summary

1-3 bullet points explaining what this PR does and why.

## Changes

- Grouped list of specific changes
- Organized by logical area
- Reference specific files when helpful for reviewers

## Test Plan

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Type checking passes (`deno check` / `cargo check` / `go vet`)

## Related Issues

Fixes #123 (if applicable)
Related to #456 (if applicable)
```

### STEP 7: Create the PR

Use `gh pr create` with a HEREDOC for the body:

```bash
gh pr create --title "PR title here" --body "$(cat <<'EOF'
## Summary
- Description of changes

## Changes
- Specific change 1
- Specific change 2

## Test Plan
- [ ] Tests pass
- [ ] Manual verification done

## Related Issues
Fixes #123
EOF
)"
```

IF creating a draft PR is more appropriate (work in progress):

```bash
gh pr create --draft --title "..." --body "..."
```

### STEP 8: Verify and report

After PR creation:

1. Capture the PR URL from the `gh pr create` output
2. Verify the PR was created: `gh pr view --json number,title,state,url`
3. Report the PR URL to the user
4. Optionally show: `gh pr view --json additions,deletions,changedFiles`

## Error Recovery

### Push rejected (non-fast-forward)

```bash
git fetch origin
git rebase origin/main
# Resolve conflicts if any
git push
```

### gh CLI not authenticated

```bash
gh auth status
# If not authenticated, instruct user to run: gh auth login
```

### PR already exists for this branch

- Show the existing PR: `gh pr view`
- Ask user if they want to update the existing PR (just push new commits)
- Or close the old one and create a new one

### Remote not configured

```bash
git remote add origin <url>
git push -u origin <branch-name>
```

### Branch is behind base

```bash
git fetch origin
git rebase origin/main
# Resolve any conflicts
git push
```

## Labels and Reviewers

IF the project has labels configured:

- Suggest appropriate labels based on the change type
- Add with: `gh pr edit <number> --add-label "enhancement"`

IF reviewers should be assigned:

- Ask the user who should review
- Add with: `gh pr edit <number> --add-reviewer username`

## Post-PR Checklist

After the PR is open:

- [ ] PR title is clear and descriptive
- [ ] PR body has Summary, Changes, Test Plan sections
- [ ] All commits follow conventional commit format
- [ ] No sensitive data (API keys, credentials) in the diff
- [ ] CI checks are passing (check with `gh pr checks`)
- [ ] Related issues are linked
- [ ] No emojis in title, body, or commit messages
