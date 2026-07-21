# Project-Driven Development (PDD) Flow

You are entering PDD mode. This flow is for defining and managing entire programs or large projects. Read `flows/pdd.md` for the complete workflow reference.

## Overview

PDD is used for defining and managing entire programs or large projects. It utilizes a structured, numbered document set for comprehensive planning, from charter to implementation.

## Command: $ARGUMENTS

The PDD command helps manage project definitions.

### `start [name]` — Start new PDD program
1. Create directory `flows/pdd-[name]/`
2. Copy all templates from `flows/.templates/pdd/` into that directory (including numbered docs and `_status.md`)
3. Replace placeholders `[PROJECT_NAME]` in `_status.md` and headers as needed
4. Set `_status.md` current phase to **CHARTER**
5. Begin charter elicitation with the user

### `resume [name]` — Resume existing program
1. Read `flows/pdd-[name]/_status.md` for current phase
2. Read existing artifacts in `flows/pdd-[name]/`
3. Report state and blockers
4. Continue from the current phase

### `fork [existing] [new]` — Fork for pivot or context recovery
1. Copy `flows/pdd-[existing]/` to `flows/pdd-[new]/`
2. Update `_status.md` with fork origin and reason
3. Ask what to change
4. Continue from the same phase unless the user resets an earlier phase

### `status` — List all PDD programs
1. List directories matching `flows/pdd-*/`
2. For each, read `_status.md` and summarize phase, phase status, and blockers

### No arguments or `help`
Show subcommands above and summarize any active `flows/pdd-*/` from `_status.md` files.

---

## Phase Behaviors

### CHARTER (`01-project-charter.md`)
- Vision, scope, MVP, non-goals, metrics, high-level journeys.
- Link journey diagrams under `artifacts/` when provided.
- Wait for explicit: **“project charter approved”** before DOMAIN.

### DOMAIN (`02-domain-specification.md`)
- Glossary, entities, economy, mechanics, balance tables, domain integrity rules.
- Wait for explicit: **“domain specification approved”** before PRODUCT_UX.

### PRODUCT_UX (`03-product-ux-specification.md`)
- IA, screen inventory, global UX laws, gating, critical states.
- Wait for explicit: **“product ux approved”** before VISUAL_MESSAGING.

### VISUAL_MESSAGING (`04-visual-and-messaging.md`)
- Visual principles, prompts for mockup generators, hero and product copy.
- Wait for explicit: **“visual and messaging approved”** before ENGINEERING.

### ENGINEERING (`05-engineering-specifications.md`)
- Backend, frontend, on-chain, cross-cutting programs; NFRs; SDD/VDD delegation table.
- Wait for explicit: **“engineering specifications approved”** before MASTER_PLAN.

### MASTER_PLAN (`06-master-plan.md`)
- Milestones, workstreams, dependencies, risks, environments.
- Wait for explicit: **“master plan approved”** before IMPLEMENTATION.

### IMPLEMENTATION (`07-implementation-log.md` + deliveries)
- Execute the master plan; log program-level changes in `07-implementation-log.md`.
- Spawn or link `flows/sdd-*` / `flows/vdd-*` for feature-sized work when appropriate.

---

## Always

- Update `_status.md` after every significant change.
- Never skip phases or assume approval.
- Prefer asking over guessing on scope or economics.
- Before ending a session, complete handoff notes in `_status.md`.
- Ensure all deliverables are linked or referenced in relevant documents.
- Treat PDD as the single source of truth for program-level decisions.
