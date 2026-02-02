# Beads Skill

Create well-formed tasks that orchestration tools can pick up and execute.

## Purpose

This skill teaches Claude how to create tasks using the `bd` CLI that can be automatically picked up by `br` (ralphy) for orchestration. Focus is on writing tasks that are:

- **Complete**: All required fields for automation
- **Parallelizable**: Minimal dependencies for maximum concurrency
- **Discoverable**: Proper labels for orchestration pickup

## Quick Start

```bash
# Create a task
bd create --title="Add login endpoint" --type=task \
  --labels=ralph,auth,backend --priority=1 \
  --description="Users need to authenticate to access protected resources" \
  --design="Add POST /login route in auth.ts, validate credentials, return JWT" \
  --acceptance="- Returns 200 with JWT on valid credentials
- Returns 401 on invalid credentials
- Rate limits login attempts"

# Find ready work
bd ready

# Add dependency (child waits for parent)
bd dep add <child-id> <parent-id>
```

## What's Covered

| Topic | Description |
|-------|-------------|
| Task Creation | Required fields, labels, priorities |
| Finding Work | Using `bd ready` for unblocked tasks |
| Dependencies | When and how to create dependencies |
| Organization | Labels for grouping related work |

## What's NOT Covered

- `br` internals and orchestration mechanics
- Task completion signals
- Code review workflows

## Files

```
beads/
├── SKILL.md                      # Main skill definition
├── README.md                     # This file
└── guides/
    ├── creating-tasks.md         # Task creation details
    ├── dependency-tracking.md    # Managing dependencies
    ├── common-workflows.md       # Practical examples
    └── troubleshooting.md        # Common issues
```

## Installation

Automatically installed when running `br --init` in a project with Claude Code (`.claude/` directory).

Manual installation:
```bash
cp -r /path/to/ralphy/skills/beads .claude/skills/
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `bd create` | Create a new task |
| `bd ready` | List unblocked tasks |
| `bd show <id>` | View task details |
| `bd dep add <child> <parent>` | Add dependency |
| `bd list --labels=X` | Filter by label |

## Labels

- `ralph` - Required for orchestration pickup
- Feature labels (`auth`, `payments`) - Group related work
- Layer labels (`backend`, `frontend`) - Technical grouping
