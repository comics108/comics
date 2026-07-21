# Roadmap - DFS Flow Orchestration

You are entering ROADMAP mode. Read `flows/roadmap.md` for the complete flow reference.

## Overview

The ROADMAP flow orchestrates development using a Depth-First Search (DFS) approach. Its goal is to reach a specific target (MVP or user-defined goal) by fully completing the minimum necessary flows in sequence (REQ → SPEC → PLAN → IMPL), before moving to the next. It relies on dependency analysis and status synchronization across multiple files.

## Command: $ARGUMENTS

The ROADMAP command helps orchestrate development using a DFS approach.

### `start [goal]` - Start new DFS to achieve a goal
1. Analyze dependencies to identify critical path to `[goal]`.
2. If MVP mode (no goal): determine MVP flows and critical path.
3. Present critical path and scope for user approval.
4. Begin executing flows in DFS order.

### `status` - Show current roadmap state
1. Read `flows/roadmap/_status.md` for current state.
2. Display critical path, current focus, progress, and blockers.
3. Show flows skipped because they are not on the critical path.

### `plan [goal]` - Show DFS plan without execution
1. Analyze dependencies to identify critical path to `[goal]`.
2. Present critical path and scope for user approval.
3. DO NOT execute any flows.

### No arguments or `help`
1. Show available commands.
2. Summarize current active roadmap state and blockers.

---

## Core Principle: DFS (Depth-First)

Implement the MINIMUM path to reach the goal, completing each item FULLY before moving to the next.

**Example Goal:** "user can login"
**Dependency Analysis Found:**
`sdd-database` ──blocks──> `sdd-auth` ──blocks──> `[GOAL]`

**Execution Order (depth-first, complete each):**
1.  **`sdd-database`**: REQ → SPEC → PLAN → IMPLEMENT ✓ (Complete)
2.  **`sdd-auth`**: REQ → SPEC → PLAN → IMPLEMENT ✓ (Current focus)
3.  **Goal Achieved!**

**Not touched (not on critical path):**
- `ddd-dashboard`
- `sdd-reporting`

## Dependency Analysis

1.  **Scan all flows**: Analyze `flows/sdd-*/`, `flows/ddd-*/`, `flows/tdd-*/`, `flows/vdd-*/`, and their respective `_status.md` and documents.
2.  **Read ADRs**: For context (constraining/enabling decisions).
3.  **Build Dependency Graph**: Map explicit and implicit dependencies between flows.
4.  **Store Graph**: In `flows/roadmap/dependencies.md`.

## MVP Mode (no goal specified)

When no goal is provided, the system finds the MVP (Minimum Viable Product):
1.  Identify core flows (those with the most dependents or enabling critical functionality).
2.  Build the minimal working path to complete MVP functionality.
3.  Present the MVP scope for user approval.

## Phase Behaviors & Synchronization

Each flow on the critical path undergoes its full lifecycle (REQ → SPEC → PLAN → IMPLEMENT). Status is synchronized across the roadmap and the individual flow.

### Sync Protocol

**CRITICAL**: Every status change updates TWO places:

```
┌────────────────────┐        ┌────────────────────┐
│ flows/roadmap/     │  sync  │ flows/[type]-[x]/  │
│   _status.md       │◄──────►│   _status.md       │
└────────────────────┘        └────────────────────┘
```

**Example**: When `sdd-auth` plan is approved:
1.  Update `flows/sdd-auth/_status.md`: Set phase to `IMPLEMENTATION`, status to `APPROVED`.
2.  Update `flows/roadmap/_status.md`: Update `sdd-auth` status to `IMPLEMENTING`, update path progress.

### Status Tracking (`flows/roadmap/_status.md`)

```markdown
# Roadmap Status

## Mode: DFS

## Goal
"user can login" | MVP (auto-detected)

## Critical Path
| Order | Flow        | Status      | Phase          | Progress |
|-------|-------------|-------------|----------------|----------|
| 1     | sdd-database| COMPLETE    | -              | 100%     |
| 2     | sdd-auth    | IN_PROGRESS | PLAN           | 60%      |

## Current Focus
- **Flow**: sdd-auth
- **Phase**: PLAN
- **Status**: DRAFTING
- **Blockers**: none

## Path Progress
- Flows complete: 1/2
- Current flow progress: 60%
- Overall: 80%

## Skipped Flows (not on path)
- ddd-dashboard (depends on sdd-auth, not needed for goal)
- sdd-reporting (independent, not in goal)

## Last Action
[timestamp] Approved specifications for sdd-auth

## Next Action
1. Complete plan for sdd-auth
2. Get plan approval
3. Begin implementation
```

## ADR Handling

ADRs are **read-only** in roadmap:
- Read for context (constraining/enabling decisions).
- Do NOT create new ADRs.
- Reference in dependency analysis.
- Note if ADR affects critical path.

## Always

- **Show DFS path** before execution.
- **Complete each flow FULLY** before moving to the next.
- **SYNC status** to BOTH roadmap and individual flow.
- **Skip flows** not on critical path.
- **Ask approval** at phase transitions.
- **Log everything** to `log.md`.
- **Never skip phases** within a flow.

## Directory Structure

```
flows/roadmap/
├── _status.md              # DFS state + critical path tracker
├── dependencies.md         # Dependency graph (full, not just path)
├── plan.md                 # Current path execution plan (for this flow)
└── log.md                  # All status changes and actions
```

## Idempotency

Command is safe to run multiple times. It automatically matches and updates status.
Destroying `_status.md`, `dependencies.md`, `plan.md`, or `log.md` will reset progress for this roadmap.
