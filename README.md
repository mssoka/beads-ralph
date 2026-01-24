# Beads-Ralphy

![Ralphy](assets/ralphy.jpeg)

Autonomous AI coding loop for [beads-tracked](https://github.com/steveyegge/beads/tree/main) projects with dependency-aware task ranking and parallel execution using git worktrees.

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
- Marked `in_progress` when execution begins
- Marked `closed` when AI outputs `<promise>COMPLETE</promise>` AND working directory is clean
- Failed tasks revert to `open` for retry
- Orphaned tasks (from crashes) auto-revert to `open` on startup
- Tasks without COMPLETE flag revert to `open` for retry
- Ctrl+C reverts all `in_progress` tasks to `open`

**Task Priority**: Uses beads priority (P0-P4) and dependency analysis to determine execution order

### Task Retry Mechanism

Beads-Ralphy uses an aggressive retry strategy to ensure **tasks never get stuck** and always eventually complete:

#### Two-Level Retry System

**Level 1: Within-Task Retries (Transient Errors)**
- API failures (rate limits, network errors, 500s)
- Empty responses
- **Strategy**: Fixed delay retry (default: 3 attempts, 5s between)
- **Total time**: ~10 seconds before giving up

**Level 2: Between-Iteration Retries (Task Completion)**
- Missing `<promise>COMPLETE</promise>` flag
- Uncommitted changes when COMPLETE flag present
- Exhausted within-task retries
- **Strategy**: Task reverts to `open`, retried on next iteration
- **Total retries**: Unlimited (until task completes properly)

#### Task Execution Flow

```
┌─────────────────────┐
│ Task: status="open" │
└──────────┬──────────┘
           │
           ↓
    mark_in_progress()
           │
           ↓
┌──────────────────────────────┐
│ Task: status="in_progress"   │
│                              │
│  AI Processing Loop          │
│  (up to MAX_RETRIES=3)       │
└──────────┬───────────────────┘
           │
           ├─ Empty Response? ──────→ mark_failed() → status="open" → Retry next iteration
           │
           ├─ API Error? ───────────→ mark_failed() → status="open" → Retry next iteration
           │
           ├─ Retries Exhausted? ───→ mark_failed() → status="open" → Retry next iteration
           │
           └─ Success ↓
                 │
                 ├─ Has COMPLETE flag?
                 │   │
                 │   ├─ YES → Uncommitted changes?
                 │   │         │
                 │   │         ├─ YES → mark_failed() → status="open" → Retry
                 │   │         │
                 │   │         └─ NO → mark_complete() → status="closed" ✅ DONE
                 │   │
                 │   └─ NO → mark_failed() → status="open" → Retry next iteration
```

#### State Machine

Tasks cycle between states until successful completion:

```
"open" ←──────→ "in_progress" ────→ "closed"
  ↑                  │                  (terminal)
  │                  │
  └──────────────────┘
    mark_task_failed()
```

**Key guarantee**: Tasks NEVER get stuck in `in_progress`. They either complete (`closed`) or revert for retry (`open`).

#### Startup Recovery

On every `br` startup:
```bash
1. check_requirements()
2. validate_config()
3. revert_in_progress_tasks()  ← Auto-cleanup orphaned tasks
4. Start main loop
```

Any tasks left `in_progress` from crashes, kills, or hung processes are automatically recovered and made available for retry.

#### Retry Scenarios

**Scenario: Agent forgets COMPLETE flag**
```
Iteration 1: Task processed, commits made, no COMPLETE → status="open"
Iteration 2: Agent sees existing work, sends COMPLETE → status="closed" ✅
```

**Scenario: Agent forgets to commit**
```
Iteration 1: COMPLETE sent, uncommitted changes detected → status="open"
Iteration 2: Agent commits changes, COMPLETE + clean dir → status="closed" ✅
```

**Scenario: Crash during execution**
```
Before crash: Task status="in_progress"
After restart: revert_in_progress_tasks() → status="open"
Next iteration: Task picked up and processed → status="closed" ✅
```

**Scenario: API rate limit**
```
Try 1: 429 error, wait 5s
Try 2: 429 error, wait 5s
Try 3: 429 error → mark_failed() → status="open"
Next iteration: Rate limit cleared, task succeeds → status="closed" ✅
```

#### Configuration

Adjust retry behavior:
```bash
./br --max-retries 5      # More attempts per task (default: 3)
./br --retry-delay 10     # Longer wait between retries (default: 5s)
```

**Total retry time** = `(MAX_RETRIES - 1) × RETRY_DELAY`
- Default: `(3 - 1) × 5s = 10s`
- With `--max-retries 5 --retry-delay 10`: `(5 - 1) × 10s = 40s`

---

## Quick Start

```bash
git clone https://github.com/mss7082/beads-ralphy.git
cd beads-ralphy && chmod +x br

# Run in any beads project
cd /path/to/your/beads/project
/path/to/br
```

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

merge_resolution:
  enabled: true       # AI merge conflict resolution (default: true)
  timeout: 900        # Resolution timeout in seconds (default: 900)
  log_attempts: true  # Save logs to .ralphy/logs/merge-resolution/
```

See `.ralphy/config.yaml.example` for a complete configuration template.

## Supported Languages

Ralphy auto-detects projects in these languages during `br --init`:

| Language | Detection File | Test Command | Lint Command | Build Command |
|----------|---------------|--------------|--------------|---------------|
| JavaScript/TypeScript | `package.json` | `npm test` or `bun test` | `npm run lint` | `npm run build` |
| Python | `pyproject.toml`, `requirements.txt`, `setup.py` | `pytest` | `ruff check .` | - |
| Go | `go.mod` | `go test ./...` | `golangci-lint run` | - |
| Rust | `Cargo.toml` | `cargo test` | `cargo clippy` | `cargo build` |
| Gleam | `gleam.toml` | `gleam test` | `gleam format .` | `gleam build` |

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

### Merge Conflict Resolution

When parallel agents modify the same files, ralphy uses **comprehensive AI-powered conflict resolution**:

**How it works:**
1. **Rich Context Gathering**: Collects branch diffs, file history, dependencies, task descriptions
2. **Single Comprehensive Resolution**: AI gets full context in one shot (like opening a fresh Claude Code instance)
3. **Detailed Diagnostics**: If resolution fails, provides clear manual resolution steps

**Configuration** (`.ralphy/config.yaml`):
```yaml
merge_resolution:
  enabled: true          # Enable AI resolution (default: true)
  timeout: 900           # Timeout in seconds (default: 900 = 15 min)
  log_attempts: true     # Save detailed logs (default: true)
```

**CLI Options:**
```bash
./br --parallel --no-merge-ai        # Disable AI resolution
./br --parallel --merge-timeout 600  # Set 10 min timeout
```

**What AI sees when resolving conflicts:**
- All worktree branches and their tasks
- Full diffs from both branches
- File history (recent commits)
- Dependencies (imports/requires)
- Project rules from config
- Related files modified in both branches

**Logs**: Saved to `.ralphy/logs/merge-resolution/<branch-name>.log`

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

**Kept:**
- All AI engine support
- Parallel execution with worktrees
- Branch-per-task workflow
- Project config (`.ralphy/`)
- Single task (brownfield) mode

## License

MIT
