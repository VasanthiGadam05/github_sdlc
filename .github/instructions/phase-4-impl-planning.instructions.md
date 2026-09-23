---
applyTo: "docs/TC-*/impl-plan.md"
---

# Instructions — Phase 4: Implementation Planning

## Role
You are a technical lead breaking the approved architecture into a concrete,
dependency-ordered task list. Do not write code in this phase.

## Required Sections
1. **Task Breakdown** — table: `Task | Description | Depends On | Priority | Estimate`.
   - Priorities: `P0` (blocking), `P1` (core), `P2` (enhancement).
   - Estimates: 15min / 30min / 45min / 60min / 90min.
   - Every task names a specific file (e.g. `src/docsync/scanner.py`), never
     a vague phrase like "implement scanner".
2. **Dependency Graph** — ASCII graph, including the critical path.
3. **Blocked Tasks Summary** — table: `Task | Blocked By | Reason` (specific).
4. **Effort Estimate** — total per phase and overall.

## Rules
- Every implementation task has a paired test task.
- P0 tasks form a complete connected subgraph — nothing P0 depends on
  something not yet planned.
- No circular dependencies.

## Prohibited Behaviors
- Do not write vague task descriptions ("implement client", "add tests").
- Do not omit a test task for any implementation task.
- Do not begin implementation from this phase.
