# brui - Real-Time Beads Kanban Board

**brui** (pronounced "brew-ee") is a real-time terminal-based kanban board for visualizing beads issues. It provides instant visual feedback as issues move through your workflow.

## Quick Start

```bash
# From any beads project directory
/path/to/ralphy/brui

# Or create a symlink for global access
ln -s /path/to/ralphy/brui /usr/local/bin/brui
cd ~/code/your-beads-project
brui
```

## Features

- **Real-Time Updates**: Instant refresh when issues change using FSEvents (macOS) or inotify (Linux)
- **Three-Column Kanban**: Open, In Progress, Done
- **Priority Color Coding**: P0=red, P1=yellow, P2=blue, P3=dim
- **Label Filtering**: Focus on specific issue labels
- **Bash 3.2 Compatible**: Works with macOS default shell
- **Zero Dependencies**: Falls back to polling if native file watching unavailable

## Usage

### Basic Commands

```bash
# Show ralph-labeled issues (default)
brui

# Show all issues
brui --all

# Filter by specific label
brui --label critical

# Static snapshot (no auto-refresh)
brui --no-watch

# Force polling mode (disable native file watching)
brui --poll

# Custom polling interval
brui --poll --refresh 0.5

# Debug mode
brui --debug

# Show version
brui --version
```

### Keyboard Shortcuts

When running in interactive mode:
- `q` - Quit
- `r` - Manual refresh

## How It Works

### Data Source

brui reads directly from `.beads/issues.jsonl` in your project:

```
/your-project/
  .beads/
    issues.jsonl  <-- One JSON object per line
```

Each issue has fields including:
- `id` - Issue ID (e.g., "LarOS-abc")
- `title` - Issue title
- `status` - One of: "open", "in_progress", "closed"
- `labels` - Array of labels
- `priority` - 0-3 (0=critical, 3=low)
- `owner` - Who owns the issue

### Status Mapping

```
Kanban Column    →  Beads Status
───────────────────────────────────
OPEN             →  "open"
IN PROGRESS      →  "in_progress"
DONE             →  "closed"
```

### File Watching

brui automatically detects the best file watching method:

**macOS (FSEvents):**
```bash
# Uses fswatch if available
brew install fswatch
```

**Linux (inotify):**
```bash
# Uses inotifywait if available
apt-get install inotify-tools
```

**Fallback (polling):**
- If no native tools available, polls every 200ms
- Adjustable with `--refresh` flag

## Real-Time Integration with br

Watch issues move through the kanban board as br works:

```bash
# Terminal 1: Run brui
cd ~/code/your-project
brui

# Terminal 2: Run br
br --max-iterations 3

# Watch in real-time:
# - Issues move to "IN PROGRESS" when ralphy starts
# - Issues move to "DONE" when ralphy completes
```

## Display Format

### Simple Layout

```
════════════════════════════════════════════════════════════════
  brui - Beads Kanban Board  [label: ralph]  [↻ Real-time: fswatch]
════════════════════════════════════════════════════════════════

OPEN (3)              IN PROGRESS (1)       DONE (15)
──────────────────────── ──────────────────────── ────────────────────────
LarOS-abc Fix bug     LarOS-xyz Add feat   LarOS-123 Update...
LarOS-def New feat
LarOS-ghi Refactor

════════════════════════════════════════════════════════════════
[q]uit  [r]efresh
```

### Color Coding

Issues are color-coded by priority:
- **P0 (Critical)**: Bold red
- **P1 (High)**: Bold yellow
- **P2 (Medium)**: Bold blue
- **P3 (Low)**: Dim white

Column headers are also color-coded:
- **OPEN**: Cyan
- **IN PROGRESS**: Yellow
- **DONE**: Green

## Directory Discovery

brui automatically searches for `.beads/` directory:

```bash
# Works from project root
cd ~/code/your-project
brui

# Works from subdirectories
cd ~/code/your-project/src/components
brui  # Still finds ~/code/your-project/.beads/

# Error if not in beads project
cd /tmp
brui  # Error: Not in a beads project (no .beads directory found)
```

## Requirements

**Required:**
- `jq` - JSON parsing (install: `brew install jq`)
- `tput` - Terminal control (standard on macOS/Linux)

**Optional:**
- `fswatch` - For real-time updates on macOS (`brew install fswatch`)
- `inotifywait` - For real-time updates on Linux (`apt-get install inotify-tools`)

**Fallback:**
- Pure bash polling if native tools unavailable

## Edge Cases

### No Issues Found

```bash
$ brui --label nonexistent
# Shows: "No issues found with label 'nonexistent'"
```

### Not in Beads Project

```bash
$ cd /tmp && brui
# Error: Not in a beads project (no .beads directory found)
```

### Terminal Too Small

Minimum size: 80x24
```bash
# If terminal is smaller, shows:
# Terminal too small!
# Minimum size: 80x24
# Current size: 60x20
# Please resize your terminal.
```

### File Permissions

```bash
# If .beads/issues.jsonl is not readable:
# Error: Cannot read issues.jsonl (permission denied): /path/to/.beads/issues.jsonl
```

### Many Issues

If more than 10 issues per column:
```
OPEN (25)             IN PROGRESS (2)       DONE (500)
─────────────         ───────────────       ──────────
[Shows first 10]      [Shows all 2]         [Shows first 10]

(+15 more)                                  (+490 more)
```

## Performance

- **File size**: Handles large issues.jsonl files (tested with 1.2MB, 658 issues)
- **Parsing**: Efficient jq-based JSON parsing per column
- **Updates**: Debounced to max 1 refresh per 100ms (prevents refresh spam)
- **Memory**: Minimal - loads only filtered issues into memory

## Troubleshooting

### Issue: "mapfile: command not found"

This means you're using Bash < 4.0. brui v1.0.0+ is compatible with Bash 3.2 (macOS default).

**Fix:** Update to latest brui version.

### Issue: No real-time updates

**Check file watching tool:**
```bash
# macOS
command -v fswatch || brew install fswatch

# Linux
command -v inotifywait || apt-get install inotify-tools
```

**Fallback to polling:**
```bash
brui --poll
```

### Issue: Colors not showing

Your terminal may not support ANSI escape codes. Try a modern terminal:
- macOS: Terminal.app, iTerm2, Warp
- Linux: gnome-terminal, konsole, alacritty

### Issue: "Permission denied" on issues.jsonl

```bash
# Check permissions
ls -l .beads/issues.jsonl

# Fix permissions (if you own the file)
chmod 644 .beads/issues.jsonl
```

## Examples

### Watch br work

```bash
# Terminal 1
brui

# Terminal 2
br --parallel --max-parallel 3

# See all 3 parallel tasks move to "IN PROGRESS" simultaneously
# Then watch them complete and move to "DONE"
```

### Monitor specific labels

```bash
# Watch critical issues only
brui --label critical

# Watch P0 issues (assuming you label them 'urgent')
brui --label urgent
```

### Compare all vs. filtered

```bash
# Terminal 1: All issues
brui --all

# Terminal 2: Ralph issues only
brui --label ralph

# Compare counts and see the difference
```

### Static snapshot for reporting

```bash
# One-time snapshot (no auto-refresh)
brui --no-watch > kanban-snapshot.txt

# Take periodic snapshots
while true; do
  date >> kanban-log.txt
  brui --no-watch >> kanban-log.txt
  sleep 60
done
```

## Architecture

### Script Structure

- **Single file**: `/path/to/ralphy/brui` (24KB)
- **Pure bash**: No external dependencies beyond `jq` and `tput`
- **Bash 3.2 compatible**: Works on macOS default shell

### Core Functions

```bash
load_issues()              # Parse issues.jsonl, filter by label
render_kanban_simple()     # Draw 3-column board
watch_and_refresh()        # File watching loop
format_issue_card()        # Render issue details
detect_watch_tool()        # Auto-detect fswatch/inotify/poll
handle_input()             # Keyboard input handler
find_beads_directory()     # Walk up tree to find .beads/
```

### File Watching Logic

```bash
# Detect best method
detect_watch_tool() → "fswatch" | "inotifywait" | "poll"

# FSEvents (macOS)
fswatch -0 .beads/issues.jsonl | while read; do refresh; done

# inotify (Linux)
inotifywait -m -e modify .beads/issues.jsonl | while read; do refresh; done

# Polling (fallback)
while true; do
  if [[ $(stat mtime) != $last_mtime ]]; then refresh; fi
  sleep 0.2
done
```

## Future Enhancements

Potential improvements (not yet implemented):

- **Column focus**: `1/2/3` keys to focus specific columns
- **Scrolling**: `↑/↓` or `j/k` for vim-style navigation
- **Multi-label filter**: `--label ralph,critical` for OR filtering
- **Custom columns**: `--columns N` to adjust column widths
- **Issue limit**: `--limit 5` to show top 5 per column
- **Sort options**: `--sort priority|age|title`
- **Card expansion**: Click/select issue to see full details
- **Export**: `--export json|csv` for reporting

## Credits

Created by Moses as a companion tool for beads-ralphy.

Part of the beads-ralphy project: https://github.com/mss7082/beads-ralphy

## License

MIT
