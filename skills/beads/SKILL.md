# Beads Task Creation

> Create well-formed tasks that orchestration tools can pick up and execute

## Overview

This skill teaches how to create tasks using the `bd` (beads) CLI that can be automatically picked up by orchestration tools like `br` (ralphy). Focus is on:

- Creating tasks with required fields
- Using labels for orchestration pickup
- Setting up dependencies for parallelization
- Finding unblocked work

## Creating Tasks

**Required fields for automation:**

```bash
bd create --title="Add login endpoint" --type=task \
  --labels=ralph,auth,backend --priority=1 \
  --description="What needs to be done and why" \
  --design="Technical approach, files to modify" \
  --acceptance="- Testable requirement 1
- Testable requirement 2"
```

### Field Reference

| Field | Purpose | Example |
|-------|---------|---------|
| `--title` | Short, action-oriented title | "Add login endpoint" |
| `--type` | Issue type (task, bug, epic) | `task` |
| `--labels` | Orchestration + feature labels | `ralph,auth,backend` |
| `--priority` | Execution order hint | `1` (high) |
| `--description` | What and why | "Users need to authenticate..." |
| `--design` | Technical approach | "Modify auth.ts, add /login route" |
| `--acceptance` | Testable requirements | "- Returns JWT on success" |

### Labels

- **Orchestration label** (required): `ralph` or custom - tells `br` to pick up this task
- **Feature labels**: `auth`, `backend`, `frontend` - for grouping related work

### Priority Scale

| Value | Meaning |
|-------|---------|
| 0 | Critical |
| 1 | High |
| 2 | Medium |
| 3 | Low |
| 4 | Backlog |

## Finding Work

```bash
bd ready                    # Unblocked tasks (USE THIS)
bd list --status=open       # All open (including blocked)
bd blocked                  # Show blocked tasks
bd show <id>                # Task details
```

**Always use `bd ready`** - returns only tasks with no open blockers, ready for immediate work.

### Why `bd ready` matters

- `bd list` shows ALL tasks including blocked ones
- `bd ready` filters to actionable tasks only
- Orchestration tools use `bd ready` to find work

## Dependencies

Create dependencies when tasks MUST run in sequence:

```bash
bd dep add <child> <parent>  # child depends on parent
bd dep tree <id>             # View dependency chain
bd dep cycles                # Check for circular deps
```

### When to Add Dependencies

**Add dependencies for:**
- Backend API needed before frontend can integrate
- Database migration needed before code change
- Core component needed before feature using it

**Don't add dependencies for:**
- Tasks that are related but can run independently
- Tasks where shared labels provide enough grouping
- "Nice to have" ordering preferences

### Keep Dependencies Minimal

Tasks without dependencies can run in parallel. Over-constraining reduces parallelization.

```bash
# BAD: Unnecessary dependency chain
Task A -> Task B -> Task C -> Task D  # Forces sequential execution

# GOOD: Only required dependencies
Task A (no deps)     # Can run immediately
Task B (no deps)     # Can run immediately
Task C -> Task A     # Waits only for Task A
Task D -> Task B     # Waits only for Task B
```

## Organizing with Labels

Use labels instead of complex hierarchies:

```bash
# GOOD: Shared labels for related work
bd create --title="Auth API" --labels=ralph,auth,backend ...
bd create --title="Login UI" --labels=ralph,auth,frontend ...
bd create --title="Auth tests" --labels=ralph,auth,testing ...

# Filter by label
bd list --labels=auth --status=open

# Multiple labels
bd list --labels=auth,backend --status=open
```

### Label Strategy

| Label Type | Purpose | Examples |
|------------|---------|----------|
| Orchestration | Pickup by br | `ralph` |
| Feature | Group related work | `auth`, `payments`, `search` |
| Layer | Technical grouping | `backend`, `frontend`, `infra` |
| Type | Work classification | `bugfix`, `refactor`, `feature` |

## Quick Reference

### Create a task
```bash
bd create --title="..." --type=task --labels=ralph,feature \
  --description="..." --design="..." --acceptance="..."
```

### Find work
```bash
bd ready                    # What can be worked on now
```

### Add dependency
```bash
bd dep add <child> <parent> # child waits for parent
```

### Check status
```bash
bd show <id>                # Full task details
bd list --labels=feature    # Filter by label
```

## Related

- [Creating Tasks Guide](guides/creating-tasks.md) - Detailed task creation
- [Dependency Tracking](guides/dependency-tracking.md) - Managing dependencies
- [Common Workflows](guides/common-workflows.md) - Practical examples
- [Troubleshooting](guides/troubleshooting.md) - Common issues
