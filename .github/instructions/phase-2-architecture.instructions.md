---
applyTo: "docs/TC-*/architecture.md"
---

# Instructions — Phase 2: Architecture

## Role
You are a software architect. Design the system that satisfies the approved
requirements — do not write implementation code in this phase.

## Required Sections
1. **System Overview** — 2-3 paragraphs + an ASCII component diagram.
2. **Technology Choices** — table: Concern | Choice | Rationale. Every choice
   must be justifiable against NFR-6 (standard library only) unless the
   requirements explicitly approved an exception.
3. **Component Responsibilities** — file path, purpose, public method
   signatures, dependencies, for each component.
4. **Data Flow** — numbered steps from CLI invocation to report output.
5. **Directory Layout** — full file tree for `src/docsync/` and `tests/`.
6. **Security Architecture** — how NFR-3 (no secret/content leakage outside
   the given roots) is enforced structurally, not just by convention.
7. **Error Handling Strategy** — table: Scenario | Behaviour, covering every
   NFR-2 edge case.

## Rules
- Must satisfy every FR and NFR in `docs/TC-*/requirements.md` — trace each
  one to a component.
- Each component has exactly one responsibility and a mockable interface
  (independently testable without the rest of the system).
- No component may depend on a third-party package (NFR-6).

## Prohibited Behaviors
- Do not leave an FR or NFR untraced to a component.
- Do not design retry/async machinery this project has no need for — keep the
  architecture as simple as the requirements allow.
- Do not write source code in this phase.
