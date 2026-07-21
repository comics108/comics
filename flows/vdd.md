# Visual-Driven Development (VDD) Flow

You are entering VDD mode. This flow is for UI development where visual mockups are key to alignment and progress. Read `flows/vdd.md` for the complete workflow reference.

## Overview

VDD prioritizes visual alignment through mockups early in the development cycle. It uses simple ASCII representations to confirm layouts and states before proceeding to detailed specifications, ensuring a shared visual understanding.

## Command: $ARGUMENTS

The VDD command helps manage visual-driven development.

### `start [name]` - Start new VDD flow
1. Create directory `flows/vdd-[name]/`
2. Copy templates from `flows/.templates/vdd/`
3. Create `_status.md` with phase = REQUIREMENTS
4. Begin requirements elicitation with user

### `resume [name]` - Resume existing flow
1. Read `flows/vdd-[name]/_status.md` to determine current phase
2. Read all existing artifacts in the document dir
3. Report current state to user
4. Continue from where left off

### `fork [existing] [new]` - Fork for context recovery
1. Copy `flows/vdd-[existing]/` to `flows/vdd-[new]/`
2. Update `_status.md` to note the fork origin
3. Ask user what adjustments to make
4. Continue from current phase with modifications

### `status` - Show all active VDD flows
1. List all `flows/vdd-*/` directories
2. Read each `_status.md` and summarize phase + blockers

### No arguments or `help`
1. Show available commands and current active flows

---

## Phase Behaviors

### REQUIREMENTS Phase
- Elicit what user wants to build and why.
- Ask clarifying questions.
- Document user stories with acceptance criteria.
- Identify constraints and non-goals.
- Update `01-requirements.md` iteratively.
- Wait for explicit "requirements approved" before advancing.

### VISUAL Phase (VDD-specific)
**Critical**: This phase is about **visual alignment**, not artistic perfection. Use simple ASCII for mockups.

**ASCII Mockup Guidelines**:
- Represent screen layouts using basic characters (`-`, `|`, `+`, `#`, `*`, ` `).
- Show all key states: happy path, error, empty, loading.
- Illustrate navigation flows between screens using arrows (`-->`).
- Keep mockups clear and concise.

**Completeness check before approval:**
- [ ] All major screens and states visualized.
- [ ] Navigation flows clearly depicted.
- [ ] Key UI elements represented.

- Update `02-visual.md` iteratively.
- Wait for explicit "visual approved" before advancing.

### SPECIFICATIONS Phase
- Analyze codebase for affected systems based on visual mockups and requirements.
- Design interfaces and data models.
- Document edge cases and error handling.
- Update `03-specifications.md` iteratively.
- Wait for explicit "specs approved" before advancing.

### PLAN Phase
- Break specs into atomic tasks.
- Identify file changes and dependencies.
- Estimate complexity.
- Update `04-plan.md` iteratively.
- Wait for explicit "plan approved" before advancing.

### IMPLEMENTATION Phase
- Execute plan task by task.
- Follow CLAUDE.md testing protocol (one test at a time).
- Log progress in `05-implementation-log.md`.
- Document any deviations from the plan.
- Wait for implementation completion before advancing.

### DOCUMENTATION Phase
- Create client-facing README.md.
- Explain feature in simple, non-technical terms.
- Provide "how it works" explanation using analogies.
- Add practical usage examples.
- Focus on benefits and functionality from client perspective.
- Avoid technical jargon.
- Wait for explicit "docs approved" before marking complete.

---

## Always

- Update `_status.md` after every significant change.
- Never skip phases or assume approval.
- When uncertain, ask rather than assume.
- Before ending session, ensure handoff notes are complete.
- Remember: Visual phase is about alignment through simple ASCII, not perfect art.
- Use mockups to confirm UI structure and flow before detailed specs.
