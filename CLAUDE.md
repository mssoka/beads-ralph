# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Beads-Ralphy is an autonomous AI coding loop that integrates with the beads issue tracker. It uses BV (beads viewer) for dependency-aware task ranking via PageRank and executes tasks through various AI CLI tools (Claude Code, OpenCode, Cursor, Codex, Qwen-Code, Factory Droid).

**Key Architecture:**
- Single bash script (`br`) that orchestrates everything
- Beads integration via `bd` (beads CLI) and `bv` (beads viewer)
- Two execution modes: sequential and parallel (with git worktrees)
- Configurable via `.ralphy/config.yaml` for project-specific rules

## Development Commands

### Testing the Script
```bash
# Single task mode (brownfield, no beads required)
./br "fix the login bug"

# Dry run to preview task execution
./br --dry-run

# Preview first task from beads tracker
./br --dry-run --max-iterations 1
```

### Running with Different AI Engines
```bash
./br --claude        # Claude Code (default)
./br --opencode      # OpenCode
./br --cursor        # Cursor agent
./br --codex         # Codex
./br --qwen          # Qwen-Code
./br --droid         # Factory Droid
```

### Testing Beads Integration
Requires a beads project with `.beads/` directory:
```bash
# Process tasks with 'ralph' label
./br

# Filter by different label
./br --label critical

# Parallel execution (respects dependencies)
./br --parallel --max-parallel 3
```

## Architecture Details

### Two Execution Modes

**1. Single Task (Brownfield) Mode**
- Triggered when a positional argument is provided
- Does NOT require beads/BV
- Runs one task directly and exits
- Uses `.ralphy/config.yaml` if available for project context

**2. Beads Mode (Default)**
- Requires `.beads/` directory and beads installation
- Uses `bv --robot-triage` to get PageRank-ordered tasks
- Filters tasks by label (default: `ralph`)
- Automatically marks tasks `in_progress` → `closed`
- Supports parallel execution via tracks from `bv --robot-triage-by-track`

### Parallel Execution Architecture

When `--parallel` is used:
1. **Track Discovery**: Calls `get_beads_parallel_tracks()` which uses BV to compute dependency-based execution tracks (0, 1, 2, ...)
2. **Worktree Creation**: Each parallel agent gets isolated git worktree in `/tmp/beads-ralphy-{random}/agent-{n}`
3. **Branch Per Agent**: Each agent works on `ralphy/{task-id-slug}` branch
4. **Sequential Track Execution**: Track 0 tasks run in parallel, then track 1 (after track 0 completes), etc.
5. **Conflict Resolution**: Without `--create-pr`, auto-merges back to base branch; AI resolves conflicts if needed

Key functions for parallel execution:
- `run_parallel_tasks()` - Main orchestrator (line ~1950)
- `run_parallel_agent()` - Individual agent runner (line ~1760)
- `get_beads_parallel_tracks()` - Get track numbers from BV (line ~1035)
- `get_tasks_in_track_beads()` - Get tasks in specific track (line ~1055)

### Prompt Construction

The `build_beads_prompt()` function (line 420) constructs prompts with:
1. **Project Context** - From `.ralphy/config.yaml` (language, framework, commands)
2. **Rules** - From `.ralphy/config.yaml` rules array
3. **Boundaries** - From `.ralphy/config.yaml` never_touch patterns
4. **Task Details** - From beads: title, description, design, acceptance criteria
5. **Completion Signal** - AI must output `<promise>COMPLETE</promise>` when done

### AI Engine Abstraction

Each engine has specific invocation patterns:
- **Claude Code**: `claude --dangerously-skip-permissions --output-format stream-json`
- **OpenCode**: `opencode --output-format stream-json --approval-mode full-auto`
- **Cursor**: `agent --dangerously-skip-permissions -p`
- **Codex**: `codex exec --full-auto --json --output-last-message`
- **Qwen**: `qwen --output-format stream-json --approval-mode yolo`
- **Droid**: `droid exec --output-format stream-json --auto medium`

All engines return JSON output parsed by `parse_ai_result()` (line ~1343) to extract tokens/cost/response.

### Task Status Tracking

Status transitions handled by:
- `mark_task_in_progress_beads()` - Calls `bd update {task-id} --status=in_progress`
- `mark_task_complete_beads()` - Calls `bd close {task-id}`
- Auto-detects completion by searching AI output for `<promise>COMPLETE</promise>`

### Config System (.ralphy/)

Created via `./br --init`. Auto-detects:
- **Language**: From tsconfig.json, package.json, pyproject.toml, etc.
- **Framework**: From package.json dependencies (Next.js, React, Express, NestJS, etc.)
- **Commands**: From package.json scripts (test, lint, build)

Config structure:
```yaml
project:
  name: "project-name"
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

## Important Implementation Notes

### When Modifying br

1. **Preserve AI Engine Compatibility**: All 6 engines must continue working. Test changes with at least Claude and one other engine.

2. **BV JSON Output**: The script expects specific JSON structure from `bv --robot-triage` and `bv --robot-triage-by-track`. Changes to BV may break task fetching.

3. **Worktree Cleanup**: The `cleanup()` function (triggered by trap) must properly clean up worktrees, branches, and temp files. Missing cleanup causes orphaned worktrees.

4. **Stream-JSON Parsing**: OpenCode, Cursor, Qwen, Droid use line-by-line JSON streaming. Each line is a JSON object. Parse with `grep` + `jq` not `jq -s`.

5. **Completion Detection**: The `<promise>COMPLETE</promise>` signal is critical. Changing this breaks task completion detection.

6. **Track Dependencies**: The parallel execution assumes BV provides dependency-aware tracks. Track 0 has no blockers, track N is blocked by track N-1.

### Testing Strategy

Since this is a bash orchestration script:
1. **Dry run testing**: Use `--dry-run` to verify prompt construction without executing AI
2. **Single task testing**: Test with brownfield mode before beads mode
3. **Parallel testing**: Create test beads project with labeled tasks in different tracks
4. **Engine testing**: Each AI engine has different output format - verify parsing works

### Common Modification Patterns

**Adding a new AI engine:**
1. Add case in `parse_args()` for `--engine-name` flag
2. Add case in `run_ai_command()` with engine invocation
3. Add case in `parse_ai_result()` for output parsing
4. Add case in `check_requirements()` for CLI detection
5. Update help text and banner display

**Adding to prompt context:**
Modify `build_beads_prompt()` to include additional sections. Always place before "## Instructions" section.

**Changing task filtering:**
Modify `get_next_task_beads()` which uses `bv --robot-triage` + jq to filter by status, label, etc.

## Dependencies

**Required:**
- `bd` and `bv` - Beads CLI tools (for beads mode)
- `jq` - JSON parsing throughout script
- One AI CLI: `claude`, `opencode`, `agent`, `codex`, `qwen`, or `droid`
- `git` - For version control and worktrees

**Optional:**
- `gh` - GitHub CLI for `--create-pr`
- `bc` - For cost calculations (accurate decimal math)

## File Structure

```
.
├── br       # Main executable (2712 lines)
├── README.md             # User documentation
└── .ralphy/              # Project-specific config (created by --init)
    └── config.yaml
```

The script is intentionally a single file for portability. All functionality is contained in bash functions within `br`.
