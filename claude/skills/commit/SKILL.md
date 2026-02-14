---
name: commit
description: Analyze staged changes and generate a conventional commit message. Handles pre-commit hook failures, large commit split detection, and message overrides.
disable-model-invocation: true
argument-hint: "[optional message override]"
---

# Smart Conventional Commit

Generate a well-crafted conventional commit from the current staged changes. If no changes are staged, offer to stage relevant files. If an optional message is provided via `$ARGUMENTS`, use it as the commit message (still validated against conventional commit format).

## Context

Gather the following before proceeding:

- Current git status: !`git status`
- Staged changes: !`git diff --cached`
- Unstaged changes: !`git diff`
- Current branch: !`git branch --show-current`
- Recent commits for style reference: !`git log --oneline -15`

## Procedure

### STEP 1: Assess staging area

IF there are no staged changes:

- Show the user what files are modified/untracked
- Suggest which files to stage based on logical grouping
- Ask for confirmation before staging
- NEVER run `git add .` or `git add -A` without explicit approval
- Prefer staging specific files by name

IF there are staged changes:

- Proceed to STEP 2

### STEP 2: Analyze the diff

Read the staged diff carefully. Identify:

1. **Change type** - What kind of change is this?
   - `feat` - A new feature or capability
   - `fix` - A bug fix
   - `docs` - Documentation only
   - `refactor` - Code restructuring without behavior change
   - `test` - Adding or updating tests
   - `chore` - Build, CI, deps, tooling
   - `perf` - Performance improvement
   - `style` - Formatting, whitespace, naming (no logic change)
   - `ci` - CI/CD configuration changes
   - `build` - Build system or dependency changes

2. **Scope** - What module, package, or area is affected? Use the most specific reasonable scope.
   Examples: `auth`, `api`, `db`, `config`, `cli`, `k8s`, `docker`

3. **Summary** - A concise imperative description of WHAT changed and WHY.
   - Use imperative mood: "add", "fix", "update", "remove" (not "added", "fixes")
   - Keep under 72 characters
   - Focus on the intent, not the mechanism

4. **Breaking changes** - Does this change break existing APIs, configs, or behavior?
   - If yes, add `!` after the type/scope and include a `BREAKING CHANGE:` footer

### STEP 3: Detect split candidates

IF the staged changes touch more than 3 unrelated areas (different packages, different concerns):

- Warn the user that the commit may be too broad
- Suggest splitting into multiple focused commits
- Propose logical groupings
- Ask for confirmation before proceeding

IF the staged diff exceeds ~500 lines:

- Flag the commit as large
- Suggest whether it should be split
- Proceed only if the user confirms

### STEP 4: Generate the commit message

IF `$ARGUMENTS` is provided and non-empty:

- Use the provided message as-is if it follows conventional commit format
- If it does not follow the format, wrap it: infer the type and scope, use the argument as the description
- Example: `$ARGUMENTS` = "fix the login bug" becomes `fix(auth): fix the login bug`

IF `$ARGUMENTS` is empty:

- Generate the message from the analysis in STEP 2

Format:

```
type(scope): concise imperative description

Optional body explaining WHY, not WHAT. The diff shows what changed.
Focus on motivation, context, and trade-offs.

BREAKING CHANGE: description (only if applicable)
Fixes #123 (only if a related issue is identifiable from branch name or context)
```

### STEP 5: Create the commit

Use a HEREDOC to pass the commit message:

```bash
git commit -m "$(cat <<'EOF'
type(scope): description

Optional body.
EOF
)"
```

### STEP 6: Handle pre-commit hook failures

IF the commit fails due to a pre-commit hook:

1. Read the hook output carefully
2. Identify what failed (formatting, linting, type checking, tests)
3. Fix the issue:
   - Formatting: run the project formatter (`deno fmt`, `cargo fmt`, `go fmt`, `gofmt`)
   - Linting: fix the specific lint error
   - Type errors: fix the type issue
   - Tests: investigate and fix the failing test
4. Re-stage the fixed files with `git add <specific-files>`
5. Create a NEW commit (NEVER use `--amend` after hook failure since the commit did not happen)
6. If the hook fails again, report the issue to the user

### STEP 7: Verify

After successful commit:

- Run `git status` to confirm clean state
- Run `git log --oneline -3` to show the new commit in context

## Commit Message Quality Checklist

- [ ] Type accurately reflects the nature of the change
- [ ] Scope is specific and meaningful (not overly broad)
- [ ] Description is imperative mood, under 72 characters
- [ ] Body explains WHY if the change is non-obvious
- [ ] No emojis anywhere in the message
- [ ] Breaking changes are clearly marked
- [ ] Related issue numbers are referenced when applicable

## Examples

Single-line commits:

```
feat(api): add health check endpoint for k8s probes
fix(auth): prevent token refresh race condition
refactor(db): extract connection pooling into separate module
chore(deps): update axum to 0.8.1
test(grpc): add integration tests for ConnectRPC handlers
docs(readme): add quick start section
ci(actions): add Deno type checking step to CI pipeline
```

Multi-line commit:

```
feat(streaming): add RedPanda consumer group rebalancing

Implement cooperative sticky partition assignment to reduce
rebalance latency during rolling deployments on the Talos cluster.

The previous eager rebalancing strategy caused message processing
gaps of 30-60 seconds during pod restarts.

Fixes #247
```

Breaking change:

```
feat(api)!: migrate from REST to ConnectRPC

BREAKING CHANGE: All HTTP endpoints under /api/v1/ are removed.
Clients must use the ConnectRPC protocol at /grpc/ instead.
See the migration guide in docs/migration-v2.md.
```
