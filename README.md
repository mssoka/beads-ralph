# Beads-Ralphy

![Ralphy](assets/ralphy.jpeg)

Autonomous AI coding loop for beads-tracked projects with dependency-aware task ranking and parallel execution using git worktrees.

---

## ⚓ Arrr, Here Be Dragons! ☠️

**AHOY MATEY!** This here ship be sailed by one lone captain on macOS seas. She runs fine fer me treasure hunts, but I be makin' NO PROMISES fer yer voyages!

🏴‍☠️ **The Code of the Seven Seas:**
- ❌ **No PRs accepted** - Me day job keeps me busy plunderin' corporate gold, no time fer code reviews!
- ❌ **No issues/features** - If ye find bugs, they be yer shipmates now!
- ✅ **Fork away, ye scallywag!** - Take the code, fix it, expand it, make it yer own vessel!
- ✅ **Sail at yer own risk** - Tested only on me Mac ship. Linux? Windows? Uncharted waters!

If this tool sinks yer codebase, don't come cryin' to me. Ye've been warned! 🏴‍☠️

Now hoist the colors and let's write some code! ⚓

---

## How It Works

Beads-Ralphy is a bash orchestrator that connects your beads issue tracker to AI coding agents (Claude Code, OpenCode, Cursor, etc.). It automatically fetches tasks, executes them through AI, and tracks status.

### Execution Modes

**Sequential Mode (Default)**
- Processes one task at a time
- Fetches highest-priority `open` task with your label (default: `ralph`)
- Executes through AI agent
- Marks task `closed` when complete
- Repeats until no tasks remain

**Parallel Mode (`--parallel`)**
- Processes multiple tasks simultaneously using git worktrees
- Groups tasks into "levels" based on dependencies (extracted from task descriptions/design)
- Level 0: Tasks with no dependencies (run in parallel)
- Level 1: Tasks that depend on Level 0 (run after Level 0 completes)
- Level N: Tasks that depend on Level N-1
- Each agent gets isolated workspace: separate worktree + branch
- Auto-merges results or creates PRs (your choice)

### Task Organization

**Labels**: Filter which tasks to process (e.g., `--label critical` only processes tasks tagged `critical`)

**Status Tracking**:
- Tasks start as `open`
- Marked `in_progress` when execution begins (parallel mode only)
- Marked `closed` when AI outputs `<promise>COMPLETE</promise>`
- Failed tasks revert to `open` for retry
- Ctrl+C reverts all `in_progress` tasks to `open`

**Task Priority**: Uses beads priority (P0-P4) and dependency analysis to determine execution order

### brui - Real-Time Kanban Visualization

`brui` is a companion terminal UI that displays your beads tasks in a kanban board (Open | In Progress | Done). It monitors the `.beads/` directory for changes and automatically refreshes the display when tasks update.

**Update mechanism:**
- Uses native file watching (FSEvents on macOS, inotify on Linux) for instant updates
- Falls back to polling every 2 seconds if file watching is unavailable
- Great for monitoring `br` progress in a separate terminal

---

## Quick Start

```bash
git clone https://github.com/mss7082/beads-ralphy.git
cd beads-ralphy && chmod +x br

# Run in any beads project
cd /path/to/your/beads/project
/path/to/br
```

## brui - Real-Time Kanban Board

**brui** is a real-time terminal-based kanban board that visualizes your beads issues:

```bash
# View kanban board (default: ralph label)
./brui

# Show all issues
./brui --all

# Filter by different label
./brui --label critical

# Static snapshot (no auto-refresh)
./brui --no-watch
```

**Features:**
- 📊 Three columns: Open, In Progress, Done
- ⚡ Real-time updates using FSEvents (macOS) or inotify (Linux)
- 🎨 Color-coded by priority (P0=red, P1=yellow, P2=blue, P3=dim)
- 🏷️ Label filtering (default: ralph)
- ⌨️ Keyboard shortcuts: `q` to quit, `r` to refresh

**Watch it work:**
```bash
# Terminal 1: Run brui to watch board
./brui

# Terminal 2: Run br
./br --max-iterations 1

# See issues move from Open → In Progress → Done in real-time!
```

**Installation:**
```bash
# Make executable (already done if you cloned the repo)
chmod +x brui

# Optional: Create symlink for global access
ln -s $(pwd)/brui /usr/local/bin/brui
```

**Requirements:**
- `jq` (JSON parsing)
- `fswatch` (optional, for real-time updates on macOS): `brew install fswatch`
- Falls back to polling if native file watching unavailable

## Prerequisites

**Required:**
- [beads](https://github.com/onbeam/beads) - `bd` and `bv` CLIs installed
- `.beads/` directory in your project (run `bd init`)
- AI CLI: [Claude Code](https://github.com/anthropics/claude-code), [OpenCode](https://opencode.ai/docs/), [Cursor](https://cursor.com), Codex, Qwen-Code, or [Factory Droid](https://docs.factory.ai/cli/getting-started/quickstart)
- `jq` - JSON parsing

**Optional:**
- `gh` - for `--create-pr` support
- `bc` - for cost calculations

## Two Modes

### Beads Mode (Default)
Works on tasks from your beads tracker:

```bash
./br                    # Process tasks with 'ralph' label
./br --label critical   # Process tasks with 'critical' label
./br --parallel         # Run 3 tasks in parallel (respects dependencies)
```

### Single Task Mode
Run a one-off task without beads:

```bash
./br "add dark mode toggle"
./br "fix the login bug" --cursor
```

## Project Config

Optional `.ralphy/config.yaml` for project-specific rules:

```bash
./br --init              # auto-detects project settings
./br --config            # view config
./br --add-rule "use TypeScript strict mode"
```

Example config:
```yaml
project:
  name: "my-app"
  language: "TypeScript"
  framework: "Next.js"

commands:
  test: "npm test"
  lint: "npm run lint"
  build: "npm run build"

rules:
  - "use server actions not API routes"
  - "follow error pattern in src/utils/errors.ts"

boundaries:
  never_touch:
    - "src/legacy/**"
    - "*.lock"
```

## AI Engines

```bash
./br              # Claude Code (default)
./br --opencode   # OpenCode
./br --cursor     # Cursor
./br --codex      # Codex
./br --qwen       # Qwen-Code
./br --droid      # Factory Droid
```

## Parallel Execution

Beads-Ralphy automatically computes execution tracks based on task dependencies:

```bash
./br --parallel                  # 3 agents default
./br --parallel --max-parallel 5 # 5 agents max
```

**How it works:**
- **Track 0**: Tasks with no blockers (run in parallel)
- **Track 1**: Tasks blocked by track 0 (run after track 0 completes)
- **Track N**: Tasks blocked by track N-1

Each agent gets isolated worktree + branch:
```
Agent 1 → /tmp/xxx/agent-1 → ralphy/LarOS-abc-fix-auth
Agent 2 → /tmp/xxx/agent-2 → ralphy/LarOS-def-add-dashboard
Agent 3 → /tmp/xxx/agent-3 → ralphy/LarOS-ghi-build-api
```

Without `--create-pr`: auto-merges back, AI resolves conflicts.
With `--create-pr`: keeps branches, creates PRs.

## Beads Integration

### Task Requirements
For best results, tasks should have:
- `--labels=ralph` (or your custom label)
- `--description` - What needs to be done
- `--design` - Technical approach
- `--acceptance` - Testable requirements

Example:
```bash
bd create --title="Add login endpoint" --type=task --labels=ralph --priority=0 \
  --description="POST /api/auth/login accepting email/password, returns JWT" \
  --design="wisp routing, squirrel SQL, bcrypt hashing, JWT 24h expiry" \
  --acceptance="- Accepts {email, password} JSON
- Returns 200 + {token, user_id} on success
- Returns 401 on invalid credentials
- Passes tests"
```

### Status Tracking
Beads-Ralphy automatically:
- Marks tasks `in_progress` when starting
- Marks tasks `closed` when complete (if AI outputs `<promise>COMPLETE</promise>`)
- Syncs with remote after each execution track

### Task Ranking
Uses multiple factors for task ordering:
- **Dependencies**: Tasks blocking others get higher priority
- **Priority**: P0-P4 weighting from beads
- **Staleness**: Age since creation
- **Urgency**: Label-based (e.g., 'critical')

## Branch Workflow

```bash
./br --branch-per-task                # branch per task
./br --branch-per-task --create-pr    # + create PRs
./br --branch-per-task --draft-pr     # + draft PRs
./br --base-branch develop            # branch from develop
```

Branch naming: `ralphy/<task-id-title-slug>`

## Options

| Flag | What it does |
|------|--------------|
| `--label TAG` | Filter tasks by label (default: ralph) |
| `--parallel` | Run tasks in parallel (respects dependencies) |
| `--max-parallel N` | Max concurrent agents (default: 3) |
| `--branch-per-task` | Create branch per task |
| `--base-branch NAME` | Base branch for task branches |
| `--create-pr` | Create GitHub PRs |
| `--draft-pr` | Create draft PRs |
| `--no-tests` | Skip writing/running tests |
| `--no-lint` | Skip linting |
| `--fast` | Skip tests + lint |
| `--no-commit` | Don't auto-commit |
| `--max-iterations N` | Stop after N tasks |
| `--max-retries N` | Retries per task (default: 3) |
| `--retry-delay N` | Seconds between retries |
| `--dry-run` | Preview without executing |
| `-v, --verbose` | Debug output |
| `--init` | Setup .ralphy/ config |
| `--config` | Show current config |
| `--add-rule "..."` | Add rule to config |

## Examples

```bash
# Basic usage - process top task with 'ralph' label
./br

# Custom label filter
./br --label critical

# Parallel execution (3 agents, dependency-aware)
./br --parallel

# Parallel with more agents
./br --parallel --max-parallel 5

# Different AI engine
./br --opencode --parallel

# Branch workflow with PRs
./br --parallel --branch-per-task --create-pr

# Preview without execution
./br --dry-run

# Single brownfield task
./br "refactor auth module to use new JWT library"
```

## Workflow

1. **Setup**: Initialize beads project with `bd init`
2. **Create tasks**: Use `bd create` with full context (description, design, acceptance)
3. **Run br**: Automatically picks top-ranked task, executes, closes, repeats
4. **Parallel mode**: Runs multiple independent tasks simultaneously
5. **Sync**: Auto-syncs task status after each track

## Engine Details

| Engine | CLI | Permissions | Output |
|--------|-----|-------------|--------|
| Claude | `claude` | `--dangerously-skip-permissions` | tokens + cost |
| OpenCode | `opencode` | `full-auto` | tokens + cost |
| Codex | `codex` | N/A | tokens |
| Cursor | `agent` | `--dangerously-skip-permissions` | duration |
| Qwen | `qwen` | `--approval-mode yolo` | tokens |
| Droid | `droid exec` | `--auto medium` | duration |

## Differences from Original Ralphy

Beads-Ralphy is a simplified, beads-focused fork of [ralphy](https://github.com/michaelshimeles/ralphy):

**Removed:**
- Markdown task lists (`--prd`)
- YAML task files (`--yaml`)
- GitHub Issues integration (`--github`)
- Manual parallel group configuration

**Added:**
- Beads integration with dependency analysis
- Task ranking based on dependencies and priority
- Automatic dependency-respecting execution levels
- Task status auto-sync (`in_progress` → `closed`)
- Label-based filtering
- Real-time kanban UI (brui)

**Kept:**
- All AI engine support
- Parallel execution with worktrees
- Branch-per-task workflow
- Project config (`.ralphy/`)
- Single task (brownfield) mode

## License

MIT

## Credits

Based on [ralphy](https://github.com/michaelshimeles/ralphy) by Michael Shimeles.
Beads integration by Moses.
