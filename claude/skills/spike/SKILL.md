---
name: spike
description: Worktree-based prototyping and investigation. Creates an isolated git worktree, prototypes an approach, verifies findings, documents results in SPIKE.md, commits, pushes, and opens a draft PR with detailed findings as a PR comment.
context: fork
disable-model-invocation: true
argument-hint: "[description-of-what-to-explore]"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
  - Write
  - Edit
---

# Spike

Time-boxed technical investigation and prototyping in an isolated git worktree. A spike answers a specific technical question, validates a design approach, or determines feasibility -- without polluting the main development branch. The outcome is always a documented finding, even if the answer is "this approach does not work."

## Workflow

### Phase 1: Spike Setup

1. **Parse the spike description** from the argument. Determine:
   - The technical question being answered
   - The scope of investigation
   - Success criteria (what would a "yes" answer look like?)
   - Failure criteria (what would a "no" answer look like?)

2. **Generate a branch name** from the description:

```bash
SPIKE_BRANCH="spike/$(echo '<description>' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 50)"
SPIKE_DIR="../$(basename $(pwd))-${SPIKE_BRANCH##spike/}"
```

3. **Create the worktree**:

```bash
git worktree add -b "${SPIKE_BRANCH}" "${SPIKE_DIR}" HEAD
```

4. **Switch to the worktree** and verify it is clean:

```bash
cd "${SPIKE_DIR}"
git status
```

5. **If the project has dependencies**, install them:

```bash
# Detect project type and install accordingly
# Deno: deno cache --reload or deno install
# Go: go mod download
# Rust: cargo fetch
# Java: ./gradlew dependencies or mvn dependency:resolve
# Node: npm install
```

### Phase 2: Investigation and Prototyping

This is the core of the spike. The approach depends on the question being investigated.

**General investigation strategy:**

1. **Research phase** (read-only):
   - Search the codebase for relevant patterns, types, and interfaces
   - Read documentation, comments, and test files related to the area
   - Identify the integration points where the spike connects to existing code
   - Check dependency documentation for relevant APIs or features

2. **Prototype phase** (write code):
   - Write the minimum code necessary to answer the technical question
   - Prefer throwaway proof-of-concept code over production quality
   - Focus on the hard/unknown parts, stub out the easy/known parts
   - Add inline comments explaining what is being tested and why

3. **Verification phase**:
   - Run the prototype and capture output
   - Test edge cases that are specifically relevant to the spike question
   - Measure performance if the spike is about performance characteristics
   - Verify compatibility if the spike is about integration feasibility

4. **Record findings as you go**:
   - Note what worked and what did not
   - Capture error messages, stack traces, or unexpected behavior
   - Save benchmark results or timing data
   - Screenshot or log relevant output

**Common spike patterns:**

- **Library evaluation**: Install the library, write a minimal usage example, verify it works with existing project constraints (versions, build system, runtime).
- **Architecture validation**: Implement a thin vertical slice of the proposed architecture to verify the abstraction boundaries hold.
- **Performance investigation**: Write a benchmark or load test for the specific operation in question. Compare approaches quantitatively.
- **Integration feasibility**: Connect to the external system/API and verify the interaction model works as expected.
- **Migration assessment**: Attempt the migration on a subset of the codebase to identify blockers and estimate effort.

### Phase 3: Document Findings in SPIKE.md

Create a `SPIKE.md` file in the worktree root:

````markdown
# Spike: <title>

## Question

<The specific technical question this spike set out to answer.>

## Context

<Why this question matters. What decision depends on the answer. Link to related issues or discussions if applicable.>

## Approach

<What was tried, in chronological order. Include code snippets for key experiments.>

### Attempt 1: <approach name>

<Description of what was tried.>

```<lang>
<Relevant code snippet>
```
````

**Result**: <What happened. Success, failure, or partial success.>

### Attempt 2: <approach name> (if applicable)

<Same structure as above.>

## Findings

### Answer

<Direct, unambiguous answer to the spike question. Start with YES/NO/PARTIALLY if the question is binary.>

### Key Discoveries

- <Important thing learned #1>
- <Important thing learned #2>
- <Important thing learned #3>

### Limitations and Risks

- <Limitation or risk #1>
- <Limitation or risk #2>

### Performance Data (if applicable)

| Metric | Value | Notes |
| ------ | ----- | ----- |
| ...    | ...   | ...   |

## Recommendation

<Based on findings, what should the team do next? Be specific and actionable.>

- [ ] Proceed with approach X because ...
- [ ] Investigate alternative Y because ...
- [ ] Abandon this direction because ...

## Effort Estimate (if applicable)

<Based on the spike, how long would the full implementation take?>

| Task | Estimate | Confidence      |
| ---- | -------- | --------------- |
| ...  | ...      | high/medium/low |

## Files Modified

<List of files created or modified during the spike, with brief descriptions of each.>

## References

- <Link to relevant documentation>
- <Link to related issues>

````
### Phase 4: Commit and Push

1. **Stage all spike files**:

```bash
git add -A
````

2. **Commit with a descriptive message**:

```bash
git commit -m "$(cat <<'EOF'
spike: <short description>

Investigated <topic>. Key finding: <one sentence summary>.
See SPIKE.md for full analysis.
EOF
)"
```

3. **Push the branch**:

```bash
git push -u origin "${SPIKE_BRANCH}"
```

### Phase 5: Open Draft PR with Findings

1. **Create a draft PR**:

```bash
gh pr create --draft \
  --title "spike: <short description>" \
  --body "$(cat <<'EOF'
## Spike Investigation

This is a time-boxed technical spike. It is NOT intended for merge -- the code is prototype quality.

**Question**: <the question>

**Answer**: <the answer>

See `SPIKE.md` in this branch for the full investigation report.

## Status
- [x] Investigation complete
- [x] Findings documented
- [ ] Team review of findings
- [ ] Decision on next steps
EOF
)"
```

2. **Post the full SPIKE.md content as a PR comment** for visibility without requiring checkout:

```bash
gh pr comment --body "$(cat <<'COMMENT_EOF'
## Spike Findings

<Paste the key sections from SPIKE.md here: Question, Answer, Key Discoveries, Recommendation>
COMMENT_EOF
)"
```

### Phase 6: Cleanup Instructions

After the spike PR has been reviewed, provide instructions to clean up:

```bash
# Return to main worktree
cd ../<original-directory>

# Remove the worktree
git worktree remove "${SPIKE_DIR}"

# Optionally delete the remote branch after PR is closed
git push origin --delete "${SPIKE_BRANCH}"
```

## Guidelines

- **Time-box your investigation**: A spike should take minutes to hours, not days. If you are spending too long, document what you have found so far and note what remains unresolved.
- **Prototype code is throwaway**: Do not spend time on code quality, tests, or documentation for the prototype itself. The value is in the findings, not the code.
- **Always produce a written finding**: Even if the spike is inconclusive, document what was tried, what was learned, and what questions remain. A spike that says "we tried X, Y, Z and none worked because of constraint C" is a successful spike.
- **Be specific in recommendations**: "We should use library X" is weak. "We should use library X v2.3+ because it supports feature F which we need for requirement R, and it integrates with our existing G setup via method M" is strong.
- **Commit early, commit often**: If the investigation has multiple phases, commit at each phase boundary. This creates a readable history of the investigation.
- **Do not merge spike branches**: Spikes are for learning. If the approach is validated, create a new branch with production-quality implementation based on what was learned.
- **Keep the worktree isolated**: Do not modify files in the main worktree from the spike worktree. The spike should be entirely self-contained.
