---
description: Analyze current codebase and project context to suggest new skills worth creating
disable-model-invocation: true
---

# Brainstorm Skills

You are a skill architect. Your job is to analyze the current project and the user's existing skills/agents to identify gaps, repetitive workflows, and opportunities for new automation.

## Workflow

### STEP 1: Scan Project Structure

Examine the current project to understand what kind of work happens here.

- Read `deno.json`, `package.json`, `Cargo.toml`, `go.mod`, or equivalent to identify the tech stack
- Scan the directory structure: `fd . -t d -d 3`
- Identify the primary language(s) and framework(s)
- Note any CI/CD configuration, Dockerfiles, or deployment manifests

### STEP 2: Inventory Existing Skills

Read the existing skills to understand what is already covered.

- List all skill directories: `ls ~/.claude/skills/`
- For each skill, read its `SKILL.md` to understand its purpose
- Build a mental map of covered workflows vs uncovered gaps

### STEP 3: Inventory Existing Agents

Read the existing agents to understand what delegation is already available.

- List all agent files: `ls ~/.claude/agents/`
- For each agent, read its `.md` file to understand its role and trigger conditions
- Note which agents overlap with skills and which are unique

### STEP 4: Identify Repetitive Workflows

Look for patterns in the project that suggest automation opportunities.

- Check git log for common commit patterns: `git log --oneline -50`
- Look for repeated file patterns (e.g., many similar components, routes, tests)
- Identify manual processes documented in README or CLAUDE.md
- Check for TODO comments or repeated code patterns: `rg "TODO|FIXME|HACK" --type-add 'code:*.{ts,js,go,rs,java}' --type code`

### STEP 5: Identify Gaps in the Skill Roster

Compare what exists against common development workflows:

- **Code generation**: scaffolding, boilerplate, templates
- **Code quality**: linting, formatting, complexity analysis
- **Testing**: test generation, coverage analysis, mutation testing
- **Documentation**: API docs, changelogs, architecture diagrams
- **Git workflows**: branching strategies, release management, conflict resolution
- **Deployment**: build, deploy, rollback, environment management
- **Debugging**: log analysis, error tracing, performance profiling
- **Dependency management**: updates, audits, license checks
- **Security**: vulnerability scanning, secret detection, SBOM generation
- **Project management**: issue triage, sprint planning, status reporting

### STEP 6: Propose New Skills

For each proposed skill, provide:

1. **Name**: kebab-case directory name (e.g., `generate-tests`)
2. **Description**: One-line summary of what it does
3. **Invocation**: How the user would trigger it (e.g., `/generate-tests AuthService`)
4. **Rationale**: Why this skill is worth creating -- what pain it solves
5. **Complexity**: Low / Medium / High -- effort to implement
6. **Invocation control**: Whether it needs `disable-model-invocation` or should auto-trigger
7. **Context mode**: Whether it should run inline or forked as a sub-agent
8. **Dependencies**: Any tools, CLIs, or MCP servers it would need

### Output Format

Present proposals as a ranked list, ordered by impact (highest first). Group them into three tiers:

- **High Impact**: Skills that would save significant time on frequent workflows
- **Medium Impact**: Skills that address real but less frequent needs
- **Nice to Have**: Skills that would be convenient but are not essential

For each proposal, use this format:

```
### [rank]. skill-name
- Description: ...
- Invocation: /skill-name [args]
- Rationale: ...
- Complexity: Low | Medium | High
- Mode: inline | forked
- Tier: High | Medium | Nice to Have
```

### Guidelines

- Prefer skills that compose well with existing skills and agents
- Prefer skills that are project-agnostic (global) over project-specific ones
- Avoid proposing skills that duplicate existing slash commands in `~/.claude/commands/`
- Consider the user's stated preferences from CLAUDE.md (Deno, backend focus, Kubernetes, etc.)
- Be concrete -- vague proposals like "improve code quality" are not actionable
- Limit proposals to 10-15 maximum to keep the list actionable
