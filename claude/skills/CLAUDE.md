# Skills Reference Guide

## What Skills Are

Skills replaced the older "custom commands" system in Claude Code. They are reusable, composable automation units that define a specific workflow Claude should follow when invoked. Think of them as parameterized prompts with tool access controls and execution modes.

Key differences from the old commands system:

- Skills live in `skills/<name>/SKILL.md` instead of `commands/<namespace>/<name>.md`
- Skills support frontmatter for configuration (invocation control, tool restrictions, arguments)
- Skills can run inline or as forked sub-agents
- Skills can be auto-invoked by Claude or restricted to manual invocation only

## File Structure

Each skill is a directory containing at minimum a `SKILL.md` file:

```
~/.claude/skills/
  commit/
    SKILL.md              # Required: skill definition
  create-pr/
    SKILL.md
    pr-template.md        # Optional: supporting files
  debug-team/
    SKILL.md
    prompts/              # Optional: supporting directory
      analyze.md
      reproduce.md
```

The `SKILL.md` file is the skill definition. Supporting files (templates, prompts, configuration) can live alongside it in the same directory. These files can be referenced from the skill body using relative paths.

## Where Skills Live

Skills can be defined at two levels:

| Location                         | Scope                                     | Installed By                                 |
| -------------------------------- | ----------------------------------------- | -------------------------------------------- |
| `~/.claude/skills/`              | Global -- available in all projects       | Dotfiles installation or `/new-global-skill` |
| `.claude/skills/` (project root) | Project -- available only in that project | Created manually in the repo                 |

Global skills take precedence if names conflict with project skills.

## Frontmatter Reference

The YAML frontmatter block at the top of `SKILL.md` configures the skill's behavior:

```yaml
---
description: One-line description of what the skill does
disable-model-invocation: true    # Prevent auto-invocation (default: false)
argument-hint: "[file-or-module]" # Hint shown in autocomplete for expected args
allowed-tools:                    # Restrict available tools (omit for full access)
  - Read
  - Glob
  - Grep
  - Bash(git *)
---
```

### Field Reference

| Field                      | Type     | Default  | Description                                                                      |
| -------------------------- | -------- | -------- | -------------------------------------------------------------------------------- |
| `description`              | string   | required | Short description shown in skill list and used for auto-invocation matching      |
| `disable-model-invocation` | boolean  | `false`  | When `true`, skill only runs on explicit user invocation (`/skill-name`)         |
| `argument-hint`            | string   | none     | Placeholder text shown after skill name in autocomplete (e.g., `[issue-number]`) |
| `allowed-tools`            | string[] | all      | List of tools the skill can use. Restricts to subset of parent session's tools   |

## Invocation Control Matrix

| `disable-model-invocation` | User types `/skill-name` | Claude decides skill is relevant | Result         |
| -------------------------- | ------------------------ | -------------------------------- | -------------- |
| `false` (default)          | Runs                     | Runs                             | Auto-invocable |
| `true`                     | Runs                     | Does NOT run                     | Manual only    |

**When to use `disable-model-invocation: true`:**

- Destructive operations (commits, deployments, file deletions)
- Expensive operations (full codebase analysis, external API calls)
- Opinionated operations (code generation with specific style choices)
- Interactive wizards (multi-step user input required)

**When to leave it `false`:**

- Advisory analysis (code review suggestions, pattern detection)
- Information gathering (dependency analysis, structure mapping)
- Read-only operations that provide context

## Skill Patterns

### Pattern 1: Reference / Inline

The skill runs in the current conversation context. It can see prior messages and shares the context window with the main session.

**Best for:** Quick operations, interactive workflows, operations that need conversation context.

```yaml
---
description: Explain the current git diff in plain language
disable-model-invocation: false
allowed-tools:
  - Bash(git diff:*)
  - Bash(git log:*)
  - Read
---

# Diff Explain

You are a code change narrator. Explain what changed and why.

## Context
- Current diff: !`git diff HEAD`
- Recent commits: !`git log --oneline -5`

## Your task
Summarize the changes in plain language, grouped by concern.
```

**Characteristics:**

- Runs in the main conversation thread
- Has access to conversation history
- Shares context window budget with the main session
- Output appears inline in the conversation

### Pattern 2: Task / User-Invoked

A more complex skill that performs a multi-step workflow, typically with `disable-model-invocation: true` because it involves side effects or requires user intent.

**Best for:** Git operations, code generation, project scaffolding, anything with side effects.

```yaml
---
description: Create a conventional commit from staged changes
disable-model-invocation: true
allowed-tools:
  - Bash(git *)
  - Read
  - Glob
  - Grep
---

# Commit

You are a commit craftsman. Create well-structured conventional commits.

## Context
- Staged changes: !`git diff --cached`
- Recent commit style: !`git log --oneline -10`

## Workflow
### STEP 1: Analyze changes
[...]

### STEP 2: Generate commit message
[...]

### STEP 3: Execute commit
[...]
```

**Characteristics:**

- Only runs when explicitly invoked
- Typically has side effects (file writes, git operations)
- Often includes a multi-step workflow
- May accept arguments via `$ARGUMENTS`

### Pattern 3: Forked / Sub-Agent

The skill runs as an isolated sub-agent with its own context window. It does NOT see the current conversation.

**Best for:** Long-running analysis, parallel execution, large codebase exploration, tasks that would consume too much of the main context window.

Note: Forking behavior is determined by how Claude Code dispatches the task, not by a frontmatter field. Skills that are designed for sub-agent execution should document this in their body and be structured for standalone operation (no dependency on conversation context).

```yaml
---
description: Comprehensive security audit of the codebase
disable-model-invocation: true
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(rg:*)
  - Bash(fd:*)
---

# Security Audit

You are a security auditor. Perform a thorough analysis independently.

## Workflow
### STEP 1: Discover attack surface
[Scan for endpoints, inputs, auth boundaries]

### STEP 2: Analyze vulnerabilities
[Check for injection, XSS, auth bypass, secrets]

### STEP 3: Generate report
[Produce structured findings with severity ratings]
```

**Characteristics:**

- Operates independently of the main conversation
- Gets its own full context window
- Can be run in parallel with other forked skills
- Results are returned to the main session upon completion

## Dynamic Context Injection

Skills can inject runtime context using the `!` backtick syntax. Commands prefixed with `!` are executed at skill invocation time and their stdout is embedded in the prompt.

```markdown
## Context

- Current branch: !`git branch --show-current`
- Staged files: !`git diff --cached --name-only`
- Project type: !`jq -r '.type // "unknown"' package.json 2>/dev/null || echo "not-npm"`
- Test results: !`deno task test 2>&1 | tail -20`
```

**Guidelines for dynamic context:**

- Use read-only commands that complete quickly
- Avoid commands with large output -- pipe through `head` or `tail`
- Commands that fail will show error output, which can be informative
- Context commands run BEFORE the skill body is processed

## String Substitutions

The following placeholders are replaced at invocation time:

| Placeholder  | Replaced With                                  |
| ------------ | ---------------------------------------------- |
| `$ARGUMENTS` | Everything the user typed after the skill name |

Example: If the user types `/fix-issue 42`, then `$ARGUMENTS` becomes `42`.

## Tool Restrictions

The `allowed-tools` field restricts which tools the skill can use. This is a whitelist -- only listed tools are available.

### Tool Name Format

```yaml
allowed-tools:
  # Built-in tools (exact names)
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(git *) # Bash with command prefix filter
  - Bash(deno task *) # Only deno task subcommands
  - WebFetch
  - WebSearch

  # MCP tools (namespaced)
  - mcp__git__git_status
  - mcp__git__git_log
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
```

### Bash Command Filtering

`Bash(pattern)` restricts which shell commands can be executed:

- `Bash(git *)` -- any git command
- `Bash(git log:*)` -- only git log with any arguments
- `Bash(deno task *)` -- only deno task subcommands
- `Bash(rg:*)` -- only ripgrep
- `Bash(*)` -- any bash command (effectively unrestricted)

If `allowed-tools` is omitted entirely, the skill inherits full tool access from the parent session.

## Skills Roster

| Skill                | Description                            | Invocation | Mode   |
| -------------------- | -------------------------------------- | ---------- | ------ |
| `/brainstorm-skills` | Analyze codebase to suggest new skills | Manual     | Inline |
| `/changelog`         | Generate changelog from git history    | Manual     | Inline |
| `/commit`            | Create conventional commit             | Manual     | Inline |
| `/create-pr`         | Create pull request with description   | Manual     | Inline |
| `/debug-team`        | Multi-agent debugging workflow         | Manual     | Forked |
| `/diff-explain`      | Explain current diff in plain language | Auto       | Inline |
| `/fix-issue`         | Fix a GitHub issue                     | Manual     | Inline |
| `/new-agent`         | Wizard to create a new sub-agent       | Manual     | Inline |
| `/new-global-skill`  | Wizard to create a new global skill    | Manual     | Inline |
| `/onboard`           | Onboard to a new codebase              | Manual     | Inline |
| `/review-changes`    | Review staged/unstaged changes         | Auto       | Inline |
| `/spike`             | Time-boxed technical investigation     | Manual     | Inline |

Update this table when creating new skills to maintain an accurate inventory.

## Creating New Skills

### Quick Method

Use the `/new-global-skill` meta-skill:

```
/new-global-skill analyze-deps
```

This walks you through an interactive wizard that handles naming, configuration, and file creation.

### Manual Method

1. Create the directory: `mkdir -p ~/.claude/skills/<skill-name>`
2. Create `SKILL.md` with frontmatter and body
3. Test with `/skill-name` in any project

### Conventions

- Directory names are kebab-case: `generate-tests`, not `generateTests`
- Descriptions start with a verb: "Generate...", "Analyze...", "Create..."
- Descriptions are under 80 characters
- Workflows use numbered `### STEP N:` headings
- Role definitions use "You are a..." preamble
- Output format is always specified
- Guidelines/constraints are always included

## Troubleshooting

### Skill does not appear in autocomplete

- Verify the file is at `~/.claude/skills/<name>/SKILL.md` (not `SKILL.md` at the root)
- Check that the `description` field exists in frontmatter
- Restart Claude Code to pick up new skills

### Skill runs but produces poor results

- Check that dynamic context commands (`!` backtick) are completing successfully
- Verify `allowed-tools` includes all tools the skill needs
- Ensure the workflow steps are specific enough -- vague instructions produce vague output
- Add more context injection to give the skill better grounding

### Skill auto-invokes when it should not

- Set `disable-model-invocation: true` in frontmatter
- Make the `description` more specific to reduce false matches

### Skill cannot use a tool it needs

- Check `allowed-tools` in frontmatter -- add the missing tool
- Check that the parent session has access to the tool in `settings.json`
- For Bash commands, ensure the filter pattern matches: `Bash(git *)` allows `git status` but not `rg`

### Dynamic context command fails

- Test the command manually in your terminal first
- Ensure the command is available on the system (e.g., `jq`, `rg`, `fd`)
- Add error handling: `command 2>/dev/null || echo "not available"`
- Commands that fail still inject their stderr, which may confuse the skill

### Skill conflicts with a slash command

- Skills and commands share the same `/name` namespace
- Skills take precedence over commands with the same name
- Rename one or the other to avoid conflicts
- Check both `~/.claude/skills/` and `~/.claude/commands/` for duplicates
