# Sub-Agents Reference Guide

## How Agents Work

Sub-agents are specialized Claude instances that receive delegated tasks from the main Claude Code session. They operate with:

- **Isolated context**: Each agent gets its own context window, separate from the main conversation. It does not see prior chat history.
- **Auto-delegation**: When agent teams are enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), Claude automatically routes tasks to the most appropriate agent based on trigger conditions defined in the agent's system prompt.
- **Defined capabilities**: Each agent has a specific role, tool access, and scope. This focus improves output quality compared to a generalist handling every task.
- **Fire-and-forget execution**: The main session delegates a task and receives results when the agent completes. Multiple agents can run in parallel.

Agents are NOT persistent processes. Each invocation creates a fresh instance with no memory of previous runs unless the agent explicitly reads state from files.

## File Format

Each agent is a single Markdown file located at `~/.claude/agents/<agent-name>.md`. The file IS the system prompt -- everything in it becomes the agent's instructions.

### Structure

```markdown
# Agent Name

You are a [role description with expertise domain].

## Expertise

- Knowledge domain 1
- Knowledge domain 2

## Responsibilities

1. Primary responsibility
2. Secondary responsibility

## Trigger Conditions

Delegate to this agent when:

- Condition 1
- Condition 2

## Workflow

### STEP 1: Assessment

[Instructions]

### STEP 2: Analysis

[Instructions]

## Output Format

[What the agent produces]

## Constraints

- What the agent must NOT do
- Scope boundaries
```

### Frontmatter Fields (Optional)

Agent files can include YAML frontmatter for configuration:

```yaml
---
model: sonnet          # Model to use: haiku, sonnet, opus
allowed-tools:         # Tool restrictions (omit for full access)
  - Read
  - Glob
  - Grep
description: One-line description of the agent
---
```

If no frontmatter is provided, the agent inherits the default model and full tool access from the parent session.

## Design Principles

### Model Selection

Choose the model based on the agent's cognitive requirements:

| Model    | When to Use                                            | Examples                                                       |
| -------- | ------------------------------------------------------ | -------------------------------------------------------------- |
| `haiku`  | Simple, repetitive, pattern-matching tasks             | File scanning, format validation, boilerplate detection        |
| `sonnet` | General analysis, code review, most development tasks  | Code review, refactoring suggestions, test analysis            |
| `opus`   | Complex reasoning, architecture, novel problem-solving | System design review, security audit, debugging complex issues |

**Default to `sonnet`** unless you have a specific reason to choose otherwise. It provides the best balance of cost, speed, and capability.

### Tool Restriction

Restrict tools to the minimum set required for the agent's role:

- **Read-only agents** (reviewers, analyzers): `Read, Glob, Grep`
- **Git-aware agents**: Add `Bash(git log:*), Bash(git diff:*), Bash(git blame:*)`
- **Modifying agents** (generators, refactorers): Add `Write, Edit`
- **Shell agents** (builders, deployers): Add `Bash(*)`

Restricting tools is both a safety mechanism and a performance optimization. Agents with fewer available tools stay focused on their domain and produce more relevant output.

### Memory Scopes

Agents do not have built-in memory persistence. "Memory" is achieved through file I/O:

| Strategy       | How                                                       | Best For                                     |
| -------------- | --------------------------------------------------------- | -------------------------------------------- |
| Stateless      | Agent reads only what it needs per invocation             | One-shot analysis, code review               |
| Project-scoped | Agent reads/writes to project's `CLAUDE.md` or `.claude/` | Project conventions, learned patterns        |
| Global-scoped  | Agent reads/writes to `~/.claude/`                        | Personal preferences, cross-project patterns |
| Scratch files  | Agent writes to `/tmp/claude-scratch/`                    | Inter-agent coordination, temporary state    |

### Skill Preloading

Agents can reference skills they should use as part of their workflow. List these in the agent's system prompt under an "Available Skills" section:

```markdown
## Available Skills

- `/commit` - Create conventional commits
- `/create-pr` - Create pull requests with proper descriptions
- `/changelog` - Generate changelogs from git history
```

This is advisory -- it tells the agent what capabilities exist but does not force their use.

### Writing Effective Descriptions

The agent's opening line ("You are a...") is critical. It sets the agent's persona, expertise, and perspective.

**Effective patterns:**

- "You are a security-focused code reviewer who specializes in identifying OWASP Top 10 vulnerabilities in web applications."
- "You are a performance engineer who analyzes code for latency bottlenecks, memory leaks, and unnecessary allocations."
- "You are a test architect who designs comprehensive test strategies covering unit, integration, and end-to-end testing."

**Avoid:**

- Vague roles: "You are a helpful assistant." (too generic)
- Multiple roles: "You are a security reviewer and performance engineer and test writer." (pick one)
- No perspective: "You review code." (does not establish expertise or approach)

## Agent Roster

| Agent                                   | Model | Tools | Triggers On |
| --------------------------------------- | ----- | ----- | ----------- |
| _(add agents here as they are created)_ |       |       |             |

Update this table when creating new agents to maintain an accurate inventory.

## Patterns

### Read-Only Reviewer

A common pattern for code review agents that analyze without modifying:

```markdown
---
model: sonnet
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Security Reviewer

You are a security-focused code reviewer. You identify vulnerabilities but NEVER modify code directly.

## Constraints

- NEVER use Write or Edit tools
- NEVER suggest changes inline -- always report findings
- Focus exclusively on security concerns
```

### Learning Expert

An agent that builds up project knowledge over time:

```markdown
# Go Expert

You are a Go language expert who learns project-specific conventions.

## Workflow

1. Read the project's CLAUDE.md for conventions
2. Scan go.mod for dependency context
3. Analyze the specific code under review
4. Provide feedback aligned with project conventions

## Memory

After each review, note any new conventions discovered in your output
so the user can update CLAUDE.md if appropriate.
```

### Hook-Guarded Agent

An agent that enforces quality gates:

```markdown
# Pre-Commit Guardian

You are a pre-commit quality gate. You run before every commit to catch issues.

## Trigger Conditions

Delegate to this agent when:

- The user is about to create a commit
- The /commit skill is invoked
- Staged changes need validation

## Workflow

1. Run linters: deno lint, deno fmt --check
2. Run type checking: deno check
3. Run relevant tests: deno test --filter
4. Check for secrets or credentials in staged files
5. Report pass/fail with details

## Constraints

- BLOCK the commit if critical issues are found
- WARN but do not block for style issues
- NEVER modify files -- only report
```

## Creating New Agents: Checklist

1. [ ] Choose a descriptive kebab-case name
2. [ ] Write a focused one-sentence role definition
3. [ ] Select the appropriate model (default: sonnet)
4. [ ] Define minimal tool access
5. [ ] Write 3+ trigger conditions for auto-delegation
6. [ ] Define a clear step-by-step workflow
7. [ ] Specify the output format
8. [ ] List constraints (what the agent must NOT do)
9. [ ] Reference any skills the agent should use
10. [ ] Create the file at `~/.claude/agents/<name>.md`
11. [ ] Update the agent roster table above
12. [ ] Test the agent with a representative task

Use the `/new-agent` skill to walk through this checklist interactively.

## Limitations

- **No persistent memory**: Agents start fresh each invocation. They must read state from files if continuity is needed.
- **No inter-agent communication**: Agents cannot directly message each other. Coordination happens through the main session or shared files in `/tmp/claude-scratch/`.
- **Context window limits**: Each agent has its own context window. Very large codebases may require the agent to be selective about what it reads.
- **No streaming feedback**: The main session receives results only after the agent completes. Long-running agents provide no intermediate output.
- **Tool inheritance**: Agents cannot use tools that the parent session does not have access to. Tool restrictions can only narrow access, not expand it.
- **No recursive delegation**: Agents cannot spawn their own sub-agents. Delegation is one level deep.
- **Experimental feature**: Agent teams require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings. Behavior may change as the feature matures.
