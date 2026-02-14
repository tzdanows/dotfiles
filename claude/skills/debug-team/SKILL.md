---
name: debug-team
description: Multi-hypothesis debugging with an agent team. Spawns 3-5 investigators with competing hypotheses plus a devil's advocate skeptic. Agents debate, cross-examine, and converge on the root cause. Requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1.
context: fork
disable-model-invocation: true
argument-hint: "[symptom-description]"
---

# Debug Team

Multi-hypothesis debugging that treats root cause analysis as a structured debate. Instead of a single linear investigation, this skill spawns 3-5 investigator agents -- each pursuing a different hypothesis -- plus a devil's advocate who challenges every conclusion. The competing hypotheses are then evaluated against evidence, cross-examined, and converged to identify the actual root cause.

**Prerequisite**: This skill requires the experimental agent teams feature. Set the environment variable before invoking:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Workflow

### Phase 1: Symptom Analysis and Hypothesis Generation

The main agent performs initial triage before spawning investigators.

1. **Parse the symptom description** from the argument. Extract:
   - What is the observable behavior (error message, incorrect output, crash, hang, performance degradation)?
   - When does it occur (always, intermittently, under load, after a specific event)?
   - What changed recently (recent commits, deployments, config changes, dependency updates)?
   - What is the expected behavior?

2. **Gather initial evidence**:

```bash
# Recent commits that may have introduced the issue
git log --oneline -20

# Recent changes to files likely involved
git diff HEAD~5..HEAD --stat

# Check for recent dependency changes
git diff HEAD~5..HEAD -- go.mod Cargo.toml package.json deno.json pom.xml build.gradle 2>/dev/null

# If error messages are available, search for them in the codebase
rg "<error-message-pattern>" --type-add 'src:*.{go,rs,java,ts,js}' --type src
```

3. **Generate 3-5 competing hypotheses** based on the symptom and initial evidence. Each hypothesis should:
   - State a specific root cause claim
   - Identify the mechanism by which the cause produces the symptom
   - Predict what additional evidence would confirm or refute it
   - Be meaningfully different from the other hypotheses (not variations of the same idea)

**Hypothesis categories to consider:**

| Category       | Examples                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------- |
| Data           | Corrupt input, schema mismatch, encoding issue, missing field, null where non-null expected |
| Logic          | Off-by-one, wrong operator, inverted condition, missing case, incorrect state transition    |
| Concurrency    | Race condition, deadlock, stale cache, missing lock, out-of-order events                    |
| Resource       | Memory leak, connection pool exhaustion, file descriptor limit, disk full, OOM kill         |
| Configuration  | Wrong environment variable, missing config, wrong endpoint, expired credential              |
| Dependency     | Breaking change in upstream library, incompatible version, missing transitive dependency    |
| Infrastructure | DNS resolution, network partition, certificate expiry, clock skew, container restart        |
| External       | Third-party API change, rate limiting, quota exceeded, service degradation                  |

### Phase 2: Parallel Investigation

Spawn one investigator agent per hypothesis, plus one devil's advocate agent. All agents run in parallel.

#### Investigator Agents (3-5 agents)

Each investigator receives:

- The symptom description
- Their assigned hypothesis
- The initial evidence gathered in Phase 1
- Instructions to investigate ONLY their hypothesis

**Investigator instructions:**

For your assigned hypothesis, perform the following investigation:

1. **Evidence gathering**: Search the codebase for code paths relevant to your hypothesis. Read the implementation of functions, types, and modules that your hypothesis implicates.

2. **Trace the failure path**: Starting from the symptom, trace backward through the code to find where your hypothesized cause would produce the observed behavior. Document each step of the trace.

3. **Confirming evidence**: Look for evidence that SUPPORTS your hypothesis:
   - Code that matches the failure pattern you predict
   - Logs or error paths that would produce the observed symptom
   - Recent changes that could have introduced the hypothesized bug
   - Known issues in dependencies that match your hypothesis
   - Configuration that could trigger the failure mode

4. **Refuting evidence**: Actively look for evidence that CONTRADICTS your hypothesis:
   - Guards or checks that would prevent your hypothesized failure
   - Tests that cover the scenario and pass
   - Code paths that bypass the failure you predict
   - Timing or ordering that makes your hypothesis impossible

5. **Produce an investigation report**:

```
## Hypothesis: <one-line statement>

### Mechanism
<How this cause produces the observed symptom, step by step.>

### Evidence For
1. [file:line] <description of supporting evidence>
2. [file:line] <description of supporting evidence>

### Evidence Against
1. [file:line] <description of contradicting evidence>
2. [file:line] <description of contradicting evidence>

### Confidence: <high/medium/low>
### Reasoning: <Why this confidence level, given the evidence balance.>

### Predicted Fix
<If this hypothesis is correct, what specific change would fix it?>

### Verification Test
<How to confirm this is the actual root cause before applying the fix.>
```

#### Devil's Advocate Agent

The devil's advocate receives:

- The symptom description
- ALL hypotheses being investigated
- The initial evidence
- Instructions to find weaknesses in every hypothesis

**Devil's advocate instructions:**

Your role is to be the skeptic. For EACH hypothesis being investigated:

1. **Attack the mechanism**: Is the proposed causal chain plausible? Are there missing steps? Does the mechanism actually produce the observed symptom, or just a similar one?

2. **Challenge assumptions**: What assumptions does this hypothesis make about the system? Are those assumptions verified? Could any of them be wrong?

3. **Identify confounders**: Could the evidence supporting this hypothesis also be explained by a different root cause? Is the evidence truly causal or merely correlated?

4. **Propose alternative explanations**: For each piece of "confirming evidence" an investigator might find, suggest at least one alternative explanation.

5. **Check for red herrings**: Are any of the hypotheses chasing symptoms rather than causes? Could the obvious explanation be masking a deeper issue?

6. **Look for the "unhypothesized"**: Is there a plausible root cause that NONE of the hypotheses cover? Search the codebase with fresh eyes, ignoring the stated hypotheses.

**Produce a challenge report:**

```
## Devil's Advocate Analysis

### Hypothesis 1: <name>
- **Weakness**: <description>
- **Alternative explanation**: <description>
- **Missing evidence needed**: <what would truly confirm this>

### Hypothesis 2: <name>
- **Weakness**: <description>
- **Alternative explanation**: <description>
- **Missing evidence needed**: <what would truly confirm this>

(Repeat for all hypotheses)

### Unconsidered Possibilities
- <Root cause that none of the hypotheses address>
- <Combination of factors that could produce the symptom>

### Overall Assessment
<Which hypothesis has the weakest evidence? Which has the strongest? Are any clearly wrong?>
```

### Phase 3: Cross-Examination and Convergence

After all agents complete, the main agent synthesizes findings.

1. **Evidence matrix**: Build a matrix of hypotheses vs evidence:

```
| Evidence | H1: <name> | H2: <name> | H3: <name> | H4: <name> |
|----------|-----------|-----------|-----------|-----------|
| <evidence 1> | supports | neutral | contradicts | neutral |
| <evidence 2> | neutral | supports | supports | contradicts |
| <evidence 3> | contradicts | supports | neutral | supports |
```

2. **Apply devil's advocate challenges**: For each hypothesis, evaluate whether the devil's advocate's objections hold. Downgrade confidence for hypotheses with valid objections. Upgrade confidence for hypotheses that survive scrutiny.

3. **Check for hypothesis combinations**: Sometimes the root cause is a combination of factors. If two hypotheses both have strong evidence but neither fully explains the symptom alone, consider whether they interact.

4. **Rank hypotheses by evidence weight**:
   - Count confirming evidence minus refuting evidence
   - Weight evidence by specificity (a matching stack trace is stronger than a plausible code path)
   - Factor in the devil's advocate assessment
   - Consider Occam's razor: simpler explanations with equal evidence rank higher

5. **Declare a verdict**: Identify the most likely root cause, or identify that more information is needed.

### Phase 4: Root Cause Report

Produce the final analysis:

```markdown
# Debug Team Report

## Symptom

<Original symptom description>

## Root Cause

<Clear statement of the identified root cause>

**Confidence**: high/medium/low
**Mechanism**: <Step-by-step explanation of how the root cause produces the symptom>

## Evidence Summary

### Confirming Evidence

1. [file:line] <description>
2. [file:line] <description>

### Key Code Path

<Trace through the code showing the failure, with file:line references at each step>

## Hypotheses Evaluated

| Hypothesis | Confidence | Verdict             |
| ---------- | ---------- | ------------------- |
| H1: <name> | high       | **Root cause**      |
| H2: <name> | low        | Ruled out: <reason> |
| H3: <name> | medium     | Contributing factor |
| H4: <name> | low        | Ruled out: <reason> |

## Recommended Fix

### Immediate Fix

<Specific code change to fix the root cause. Include file paths and describe the change.>

### Verification Steps

1. <How to verify the fix resolves the symptom>
2. <How to verify no regression is introduced>
3. <Edge cases to test>

### Preventive Measures

- <Test to add to prevent recurrence>
- <Guard or assertion to add>
- <Monitoring or alerting to add>

## Investigation Log

### Timeline

1. Initial evidence gathered: <what was found>
2. Hypotheses generated: <list>
3. Investigation results: <summary per agent>
4. Cross-examination findings: <key insights from devil's advocate>
5. Convergence: <how the verdict was reached>

## Open Questions

- <Anything that remains uncertain>
- <Follow-up investigation needed>
```

## Guidelines

- **Hypotheses must be falsifiable**: Every hypothesis must predict specific evidence that would disprove it. If a hypothesis cannot be wrong, it is not useful.
- **Evidence must be specific**: "The code looks like it could have a race condition" is weak. "[file:line] This goroutine reads `shared.counter` without holding `mu`, while [file:line] this goroutine writes it under `mu`" is strong.
- **The devil's advocate is not optional**: The skeptic agent is the most important agent in this workflow. Without adversarial challenge, investigators succumb to confirmation bias and declare their hypothesis correct based on thin evidence.
- **Prefer depth over breadth**: Three well-investigated hypotheses with thorough evidence are more valuable than seven hypotheses with superficial investigation.
- **Document the investigation, not just the answer**: The investigation log is valuable even if the root cause turns out to be something else. Future debuggers benefit from knowing what was already ruled out.
- **Do not fix the bug during investigation**: The debug team is a diagnostic tool. It produces a report and recommendation. The actual fix should be implemented deliberately, with proper testing, in a separate step.
- **When evidence is inconclusive**: Say so. A report that honestly says "we narrowed it to two possibilities and need X additional data to distinguish them" is more useful than a report that picks one with false confidence.
- **Consider the environment**: Bugs that only reproduce in production, under load, or on specific hardware may require evidence that cannot be gathered from code alone. Note when runtime data (logs, metrics, traces) would be needed to confirm a hypothesis.
