# Skills and Agents Usage Guide

Quick reference for the skills and agents system. See `skills/CLAUDE.md` and `agents/CLAUDE.md` for full documentation.

## Quick Start

### Invoking Skills

Type `/` followed by the skill name in any Claude Code session:

```
/commit                      # No arguments
/fix-issue 42                # With argument
/new-global-skill my-skill   # With named argument
/brainstorm-skills           # No arguments needed
```

Skills with `disable-model-invocation: true` only run when you explicitly invoke them. Others may auto-trigger when Claude determines they are relevant.

### How Agents Work

With agent teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json), Claude automatically delegates tasks to specialized agents based on trigger conditions defined in each agent's system prompt. You do not invoke agents directly -- Claude routes work to them.

Agents run as isolated sub-agents with their own context window. They do not see your conversation history. Results are returned to the main session when the agent completes.

## Available Skills

| Skill                | Description                                    | Example                                  |
| -------------------- | ---------------------------------------------- | ---------------------------------------- |
| `/brainstorm-skills` | Suggest new skills based on project analysis   | `/brainstorm-skills`                     |
| `/changelog`         | Generate changelog from git history            | `/changelog v1.0..HEAD`                  |
| `/commit`            | Create conventional commit from staged changes | `/commit`                                |
| `/create-pr`         | Create PR with structured description          | `/create-pr`                             |
| `/debug-team`        | Multi-agent parallel debugging                 | `/debug-team "auth timeout"`             |
| `/diff-explain`      | Explain current diff in plain language         | `/diff-explain`                          |
| `/fix-issue`         | Investigate and fix a GitHub issue             | `/fix-issue 123`                         |
| `/new-agent`         | Wizard: create a new sub-agent                 | `/new-agent security-reviewer`           |
| `/new-global-skill`  | Wizard: create a new global skill              | `/new-global-skill generate-tests`       |
| `/onboard`           | Understand a new codebase quickly              | `/onboard`                               |
| `/review-changes`    | Review staged and unstaged changes             | `/review-changes`                        |
| `/spike`             | Time-boxed technical investigation             | `/spike "evaluate DragonflyDB vs Redis"` |

## Available Agents

| Agent                                   | Model | Triggers When |
| --------------------------------------- | ----- | ------------- |
| _(add agents here as they are created)_ |       |               |

Agents are defined in `~/.claude/agents/<name>.md`. Use `/new-agent` to create new ones.

## Skills vs Commands vs Agents

| Concept     | What It Is                                | When to Use                                                                |
| ----------- | ----------------------------------------- | -------------------------------------------------------------------------- |
| **Skill**   | Reusable workflow with config (SKILL.md)  | Structured, repeatable tasks with tool restrictions and invocation control |
| **Command** | Legacy prompt template (commands/*.md)    | Simple prompt injection without execution control (being phased out)       |
| **Agent**   | Specialized Claude instance (agents/*.md) | Delegated tasks requiring focused expertise or parallel execution          |

**Migration path:** Commands in `~/.claude/commands/` still work but skills are the preferred mechanism. New automation should be created as skills.

## Creating Your Own

### New Skill

```
/new-global-skill my-skill-name
```

Walks through: naming, description, invocation control, tool restrictions, context mode, and writes the SKILL.md file.

### New Agent

```
/new-agent my-agent-name
```

Walks through: naming, role definition, model selection, tool restrictions, memory scope, skill preloading, trigger conditions, and writes the agent file.

### Brainstorm Ideas

```
/brainstorm-skills
```

Analyzes your current project and existing skills to suggest gaps worth filling.

## Settings That Matter

In `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" // Enable agent auto-delegation
  },
  "alwaysThinkingEnabled": true, // Extended thinking by default
  "model": "sonnet", // Default model for main session
  "enabledPlugins": {
    "pr-review-toolkit@claude-plugins-official": true,
    "security-guidance@claude-plugins-official": true,
    "feature-dev@claude-plugins-official": true
  }
}
```

Key settings:

- **Agent teams**: Must be enabled for agents to auto-delegate. Without this, agents are inert.
- **Always thinking**: Improves quality for complex skills that benefit from extended reasoning.
- **Model**: The main session model. Agents can override this per-agent in their frontmatter.
- **Plugins**: Extend Claude Code with additional capabilities that skills and agents can leverage.

## Tips

### Inline vs Forked Execution

- **Inline** (default): Skill runs in your current conversation. It sees prior messages and shares your context window. Best for quick, interactive tasks.
- **Forked**: Skill runs as a sub-agent with its own context window. Best for long-running analysis, parallel execution, or tasks that would consume too much context.

### Memory Scopes for Agents

- **Stateless** (default): Agent starts fresh every time. Simplest and most predictable.
- **Project-scoped**: Agent reads project CLAUDE.md for conventions. Good for agents that need project context.
- **Global-scoped**: Agent reads `~/.claude/` for user preferences. Good for agents that enforce personal standards.

Agents do not have built-in memory. "Memory" means reading/writing files.

### Model Cost Tradeoffs

| Model  | Relative Cost | Best For                                                  |
| ------ | ------------- | --------------------------------------------------------- |
| haiku  | 1x            | File scanning, format checking, simple lookups            |
| sonnet | ~3x           | Code review, analysis, most development tasks             |
| opus   | ~15x          | Architecture decisions, complex debugging, novel problems |

Default agents to sonnet. Use haiku for high-volume simple tasks. Reserve opus for tasks where reasoning quality matters more than cost.

### Reducing Token Usage

- Use `allowed-tools` to prevent skills from exploring irrelevant paths
- Keep dynamic context injection (`!` commands) focused -- pipe through `head -20` or `tail -20`
- Prefer skills over free-form conversation for repetitive workflows
- Use forked execution for large analysis tasks to preserve main context window

### Naming Conventions

- Skills: kebab-case directories (`generate-tests`, `analyze-deps`)
- Agents: kebab-case files (`security-reviewer.md`, `test-writer.md`)
- Descriptions: start with a verb, under 80 characters
- Arguments: use square brackets in hints (`[file]`, `[issue-number]`)
