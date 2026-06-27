---
name: critique-panel
description: OPTIONAL agent team — a panel that reviews several candidate prompt-packages in parallel. NOT recommended for single-song craft; included so the primitive is available if scope grows.
---

# critique-panel (optional, experimental)

> **Not recommended for the core single-song workflow.** Agent teams are experimental, cost
> significantly more tokens than subagents, and the multi-agent literature found orchestrator/peer
> configurations *dominated* on the cost–quality frontier for this kind of work (MAST; the
> coordination-layer study). For one song, stay with subagents + the gate hooks. Reach for this only
> when you genuinely have several independent candidates to weigh at once.

## Enable
Agent teams require an env flag:
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

## Intended shape
- **Lead (you):** holds the brief; assembles candidate prompt-packages.
- **Teammates** (each a `adversarial-critic`-flavored peer): independently run **Gate 1** against one
  candidate package, write its `gate1.json`, and report.
- The lead collects the PASS/FAIL verdicts and picks the strongest package to take into generation.

The contract is unchanged: teammates write gate JSON; the lead trusts the files, not the prose. The
PreToolUse `gate-check` hook still gates generation regardless of how Gate 1 was produced.
