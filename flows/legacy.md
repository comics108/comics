# Legacy - Reverse Engineering Flow

You are entering LEGACY mode. This flow is for reverse-engineering existing codebases and generating documentation. Read this file for the complete workflow reference.

## Overview

The LEGACY flow analyzes existing code to build a deep, logical understanding tree. It maps this understanding to existing or new documentation flows (ADR, SDD, PDD, DDD, TDD, VDD). It prioritizes additive updates and immediate conflict resolution.

## Command: $ARGUMENTS

The LEGACY command helps to reverse-engineer code and document it.

### `analyze [path] ["focus-topic"]` - Analyze code recursively

**Arguments**:
- **`path`**: WHERE to look for source code (starting point). Defaults to project root.
- **`"focus-topic"`**: WHAT to focus on (triggers DFS mode for deeper analysis within a specific concept). Optional.

**Modes**:
- **BFS (Breadth-First Search)**: Default when only `path` is provided (or no arguments). Analyzes broadly from the `path`.
- **DFS (Depth-First Search)**: Triggered when `"focus-topic"` is provided. Focuses deeply on the specified topic within the `path`.

**Examples**:
```bash
/legacy                              # BFS from project root
/legacy src/auth                     # BFS from src/auth
/legacy src/auth "JWT validation"    # DFS: focus on "JWT validation" within src/auth
```

## Core Concept: Recursive Understanding Tree

AI builds a **logical understanding tree** that grows DEEP, not wide. Each directory in the `understanding/` folder represents a logical concept discovered during analysis, not necessarily a filesystem path.

```
WRONG (mirror filesystem):
analysis/src/auth/jwt/tokens/_analysis.md  ❌

WRONG (flat structure):
analysis/depth-0.md, depth-1.md, depth-2.md  ❌

RIGHT (logical tree growing deep):
flows/legacy/understanding/
├── _root.md                      # Project overview
└── core-domain/                  # Logical concept (NOT a source path!)
    ├── _node.md                  # Understanding of this level
    └── authentication/           # Deeper concept
        ├── _node.md
        └── token-lifecycle/      # Even deeper
            └── _node.md
```
Each `_node.md` stores the AI's understanding at that depth level. The tree grows as AI discovers deeper concepts to explore.

## State Persistence: `_traverse.md`

AI reads `_traverse.md` to know exactly where it is in the recursion and what to do next. It uses a stack structure to track the current position and phase.

```markdown
## Existing Flows Index
[Table of flows: path, type, topics, key decisions]

## Current Stack
/ (root)                           DONE
└── core-domain                    DONE
    └── authentication             EXPLORING ← current position
        └── token-management       PENDING (child to explore)
```

### Resume Protocol:
1. Read `_traverse.md`.
2. Find the top of the stack (current position).
3. Check the current phase (ENTERING, EXPLORING, SPAWNING, SYNTHESIZING, EXITING).
4. Execute that phase's actions.
5. Update `_traverse.md` with the new state.
6. Continue or pause for the next invocation.

## Workflow Phases & Algorithm

AI performs a **depth-first traversal** of the understanding tree, persisting state to `_traverse.md`.

### Phase Diagram

```
        ┌─────────────────────────────────────────┐
        │                                         │
        ▼                                         │
    ENTERING ──► EXPLORING ──► SPAWNING           │
        │                          │              │
        │                          ▼              │
        │                    [has children?]      │
        │                     /         \         │
        │                   yes          no       │
        │                    │            │       │
        │                    ▼            │       │
        │               RECURSE ──────────┤       │
        │              (for each)         │       │
        │                    │            │       │
        │                    ▼            ▼       │
        │               SYNTHESIZING ◄────┘       │
        │                    │                    │
        │                    ▼                    │
        │                 EXITING                 │
        │                    │                    │
        │                    ▼                    │
        │         [generate ADR/SDD/PDD/DDD/TDD/VDD]  │
        │                    │                    │
        │                    ▼                    │
        └─────────────── [record state] ──────────┘
                            │
                            ▼
                     [pop from stack]
                     [bubble up to parent]
```

### Phase Actions Mapping

| Phase         | Read                                | Write                                       | Next Phase         |
|---------------|-------------------------------------|---------------------------------------------|--------------------|
| ENTERING      | Source paths, existing flows index  | `_node.md` (hypothesis)                     | EXPLORING          |
| EXPLORING     | Source code                         | `_node.md` (validated understanding)        | SPAWNING           |
| SPAWNING      | `_node.md`                          | Pending children                            | RECURSE or SYNTHESIZE |
| SYNTHESIZING  | Children summaries                  | `_node.md` (synthesis)                      | EXITING            |
| EXITING       | `_node.md`, existing flows index    | Match/Update Flow, Generate Docs            | Record State       |
| Record State  | All docs                            | `_traverse.md`, `log.md`, index             | Pop stack, Bubble up |

## Flow Matching & Updates

**CRITICAL**: Before creating any flow, search for existing matching flow. This ensures idempotency and additive updates.

### Flow Matching Algorithm

For each discovered module/decision during EXITING phase:
1.  **EXTRACT keywords** from node understanding (module/domain names, concepts, technologies, decisions).
2.  **SEARCH existing_flows_index**: Compare keywords against existing flow topics and calculate a match score.
3.  **DECIDE**:
    *   IF score >= 2: **UPDATE** existing flow (append-only).
    *   IF score < 2: **CREATE** new flow.

### Update Existing Flow Protocol

When a match is found (score >= 2):
1.  **READ** existing documents for the flow type (e.g., `01-requirements.md`, `02-specifications.md` for SDD; `01`-`07` for PDD).
2.  **COMPARE** analysis with existing content to identify gaps, conflicts, or confirmations.
3.  **HANDLE EACH**:
    *   **Gaps**: APPEND new section:
        ```markdown
        ## [Section Name] - Legacy Additions
        > Added by /legacy on [DATE]
        
        - [new insight discovered]
        ```
    *   **Conflicts**: STOP and ASK USER immediately.
    *   **Confirmations**: No action.
4.  **LOG** update in `log.md`.

### Create New Flow Protocol

When no matching flow is found (score < 2):
1.  **DETERMINE** flow type (ADR, SDD, PDD, DDD, TDD, VDD).
2.  **CREATE** new directory `flows/[type]-[name]/`.
3.  **GENERATE** documents from understanding (copying from `flows/.templates/`).
4.  Set status to DRAFT.
5.  **ADD** to `existing_flows_index` in `_traverse.md`.
6.  **LOG** creation in `log.md`.

## Initialization & Execution Steps

### Step 0: Scan Existing Flows (BEFORE ANYTHING ELSE)
**CRITICAL**: Before any analysis, scan and understand all existing flows.
1.  **SCAN**: All flows in `flows/` directory (ADR, SDD, PDD, DDD, TDD, VDD).
2.  **BUILD Flow Index**: Extract metadata (type, topics, decisions).
3.  **STORE Index**: In `_traverse.md` under `## Existing Flows Index`.

### Step 1: Initialize Traversal
1.  Read `_traverse.md`. If empty, create root node and push to stack.
2.  Determine mode (BFS/DFS) from arguments.
3.  Load existing flows index from `_traverse.md`.

### Step 2: Traverse (Recursive)
Execute current phase, update state, continue or pause.
**Each invocation**: Read `_traverse.md`, execute phase, update `_traverse.md`, update `_node.md`.

### Step 3: Record Iteration Status (After All Documents)
**ONLY AFTER** ADR/SDD/PDD/DDD/TDD/VDD documents are updated or created:
1. Update `_traverse.md` with new state.
2. Update `_node.md` with current understanding.
3. Log iteration in `log.md`.
4. Update `existing_flows_index` if new flows were created.

## When to Ask User

- Existing flow contradicts analysis.
- Multiple valid module boundaries are possible.
- Unclear which flow type is most appropriate.
- Cannot determine if code is deprecated or active.
- Architectural decision is unclear.
- Match score is borderline (exactly 2, ambiguous).

## Always

- **FIRST**: Scan all existing flows before any analysis.
- **MATCH**: Search for existing matching flows before creating new ones.
- **APPEND**: Update existing flows with "Legacy Additions" sections only. NEVER modify existing content.
- **ASK**: Stop immediately on conflicts or ambiguities; do not defer.
- **CREATE**: New flows only when match score < 2.
- **INDEX**: Update `existing_flows_index` when creating new flows.
- **PERSIST**: State after EVERY action in `_traverse.md`.
- **TREE**: Grows DEEP (concepts within concepts), not wide.
- **NAMES**: Logical (concepts), not source paths.
- **ONE** node may reference MANY source files.
- **RESUME**: From `_traverse.md`.
- **DRAFT**: Flows created are in DRAFT status only.
- **NEVER**: Auto-approve or overwrite existing content.

## Directory Structure

```
flows/legacy/
├── _status.md                    # Overall progress for this flow
├── _traverse.md                  # Recursion stack & state for the analysis
├── log.md                        # Iteration history and actions taken
├── understanding/                # The logical understanding tree (grows deep)
│   ├── _root.md                  # Entry point of the tree
│   ├── _node.template.md         # Template for new nodes
│   └── [domain]/                 # First logical domain discovered
│       ├── _node.md
│       └── [subdomain]/          # Deeper concept
│           ├── _node.md
│           └── [concept]/        # Even deeper...
│               └── _node.md
├── mapping.md                    # Maps discovered nodes to generated flows
└── review.md                     # Items flagged for human review (use sparingly; ask directly)
```

## Idempotency

Command is safe to run multiple times. It automatically matches and updates existing flows.
Destroying `_traverse.md` or `log.md` will reset progress for this flow.
Destroying `understanding/` will restart analysis from scratch.
