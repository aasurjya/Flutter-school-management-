# Agent Coordination Guide

Defines two coordination modes for multi-agent workflows. Both produce identical work products; only the dispatch mechanism changes.

---

## 1. Mode Detection

At the start of any orchestration workflow, check your available tools:

- **If `TeamCreate` and `SendMessage` are available** → Use Team Mode
- **Otherwise** → Use Task Mode (fire-and-forget `Task()` subagents)

```text
Workflow starts
      |
      v
  TeamCreate and SendMessage available?
      |
   +--+--+
   | YES |  --> Team Mode (persistent teammates, direct messaging)
   +--+--+
      |
   +--+--+
   | NO  |  --> Task Mode (existing workflow, zero overhead)
   +-----+

In EITHER mode:
  - Adversarial reviewers = ALWAYS fresh Task()
  - Quality gates = blocking
  - Human checkpoints = mandatory
```

---

## 2. Task Mode (Default)

Task Mode is always available. Uses fire-and-forget `Task()` subagents.

### How It Works

1. Orchestrator spawns subagent via `Task()` with full context in the prompt
2. Subagent executes independently — no cross-agent communication
3. Subagent returns result to the orchestrator upon completion
4. Orchestrator proceeds to the next step

### When Task Mode Is Sufficient

Task Mode works well for most Flutter workflows:
- Single-file changes or screen implementations
- Design reviews (5 parallel tasks)
- Code/UX review agents
- Security audits

---

## 3. Team Mode (Enhanced)

Available when `TeamCreate` and `SendMessage` are present. Provides persistent teammates with context retention.

### Key Benefits Over Task Mode

| Benefit | Description |
| --- | --- |
| **No cold starts** | Coder retains context between work units |
| **Direct handoffs** | Researcher sends findings directly to architect |
| **Persistent shepherd** | Stays alive through entire PR lifecycle |
| **Efficient review cycles** | Design reviewers retain context across iterations |

### Design Review as Review Team

1. `TeamCreate("review-{design-doc-name}")`
2. Spawn reviewers: `pm`, `architect`, `designer`, `security`, `cto`
3. Collect verdicts via `SendMessage`
4. On revision: message reviewers — they retain context from previous round
5. After approval: `shutdown_request` to all reviewers, then `TeamDelete`

---

## 4. Adversarial Reviewer Isolation Rule

**Adversarial reviewers MUST be fresh `Task()` instances on EVERY review pass — even in Team Mode.**

### The Rule

- ALWAYS a fresh `Task()` instance
- NEVER a teammate
- NEVER resumed from a previous agent
- NEVER given previous review findings or prior context
- A new reviewer sees ONLY: spec, DoD items, and git diff

### Why

Prevents **anchoring bias** — after a FAIL → fix → re-validate cycle, the next reviewer must be completely new with zero memory of prior reviews.

---

## 5. Preserved Invariants (Mode-Agnostic)

| Invariant | Description |
| --- | --- |
| **Orchestrator-run validation** | Validation always run by orchestrator, never delegated |
| **4-phase execution loop** | IMPLEMENT → VALIDATE → ADVERSARIAL REVIEW → COMMIT |
| **Knowledge priming** | `/prime` runs before all agent work in both modes |
| **Human checkpoints** | Planned pauses require explicit human approval |
| **Quality gates** | `flutter analyze`, `flutter test --coverage` — blocking state transitions |
| **Pipeline pattern** | Push + PR + shepherd immediately after each agent completes, don't batch |
| **Max retry + escalation** | 3 retries per gate, then escalate to human with full failure history |
| **File scope verification** | `git diff --name-only` check after every implementation |

### Invariant Rationale

- **Orchestrator-run validation**: Prevents subagents from self-certifying their own work
- **4-phase loop**: Prevents the "implement and hope" anti-pattern
- **Knowledge priming**: Prevents agents from ignoring tenantId!, pagination, mounted check patterns
- **Quality gates as blocking**: Prevents tech debt accumulation in a project with no existing tests

---

## Quick Reference: Mode Comparison

```text
+---------------------------+----------------------------+----------------------------+
|                           |       TASK MODE            |       TEAM MODE            |
+---------------------------+----------------------------+----------------------------+
| Availability              | Always                     | TeamCreate + SendMessage   |
| Agent lifecycle           | Fire-and-forget            | Persistent teammates       |
| Context retention         | None (cold start each)     | Retained across work items |
| Communication             | Via orchestrator only      | Direct SendMessage         |
| Adversarial reviewer      | Fresh Task() (natural)     | Fresh Task() (enforced)    |
| Overhead                  | Zero (existing behavior)   | Team setup/teardown        |
| Best for                  | Single-screen work         | Multi-screen features      |
+---------------------------+----------------------------+----------------------------+
```
