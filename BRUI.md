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

**brui v2.0+ queries the SQLite database** (`beads.db`) directly, the same source of truth used by all `bd` commands. This ensures consistent views across all beads tools:

```
/your-project/
  .beads/
    beads.db         <-- Source of truth (SQLite database)
    beads.db-wal     <-- Write-ahead log (SQLite WAL mode)
    issues.jsonl     <-- Git-syncable format only
```

**Architecture:**
- **Database** (`beads.db`): Source of truth for all operations
- **JSONL** (`issues.jsonl`): Git-syncable serialization format only
- Both `bd` and `brui` read from database for consistency

**Data Flow:**
```
bd commands ──> Database (beads.db) <── brui (direct sqlite3 queries)
                    │
                    └─> bd export ─> issues.jsonl ─> git push
```

brui queries these fields from the `issues` table:
- `id` - Issue ID (e.g., "LarOS-abc")
- `title` - Issue title
- `status` - One of: "open", "in_progress", "closed"
- `labels` - Array of labels (from separate `labels` table)
- `priority` - 0-4 (0=critical, 4=low)
- `owner` - Who owns the issue

### Status Mapping

```
Kanban Column    →  Beads Status
───────────────────────────────────
OPEN             →  "open"
IN PROGRESS      →  "in_progress"
DONE             →  "closed"
```

## Architecture Benefits (v2.0+)

**Why Database Instead of JSONL?**

brui v2.0 switched from reading `issues.jsonl` to querying `beads.db` directly. This brings several benefits:

1. **Consistency**: brui and bd always show identical data (same source of truth)
2. **Correctness**: No more confusion when JSONL gets out of sync with database
3. **Performance**: SQLite queries are fast (~5ms) and scale well to 10k+ issues
4. **Simplicity**: JSONL becomes what it should be - just a git sync format

**Breaking Change in v2.0:**

If you're upgrading from brui v1.x, run `bd export` in your project to ensure JSONL is current:

```bash
cd /path/to/your/project
bd export  # Sync database → JSONL
brui       # Now uses database directly
```

**Version Check:**

```bash
brui --version  # Should show 2.0.0 or higher
```

### File Watching

brui watches the database files (`beads.db` and `beads.db-wal`) for changes and automatically refreshes when issues are updated. It detects the best file watching method:

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
- If no native tools available, polls database modification time every 200ms
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
- `sqlite3` - Database queries (pre-installed on macOS/most Linux distros)
- `jq` - JSON parsing (install: `brew install jq`)
- `tput` - Terminal control (standard on macOS/Linux)

**Optional:**
- `fswatch` - For real-time updates on macOS (`brew install fswatch`)
- `inotifywait` - For real-time updates on Linux (`apt-get install inotify-tools`)

**Fallback:**
- Pure bash polling if native file watching tools unavailable

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
# If .beads/beads.db is not readable:
# Error: Cannot read beads.db (permission denied): /path/to/.beads/beads.db

# Check permissions
ls -l .beads/beads.db

# Fix permissions (if you own the file)
chmod 644 .beads/beads.db
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

- **Query Speed**: Direct SQLite queries are very fast (~4-5ms per query)
- **Total Load Time**: ~0.26s for 697 issues (tested in LarOS repo)
- **Scalability**: Scales well to 10,000+ issues (<20ms per query with indexes)
- **Updates**: Debounced to max 1 refresh per 100ms (prevents refresh spam)
- **Memory**: Minimal - SQLite handles large datasets efficiently

**Performance Comparison:**
- Direct sqlite3 queries: ~5ms (current approach)
- Calling `bd list`: ~200ms (40x slower due to Go startup overhead)
- JSONL parsing: ~15ms for small repos, slower at scale

**Why SQLite is fast:**
- Indexed queries on status, priority, and labels
- No process startup overhead (unlike calling `bd`)
- Efficient filtering at database level

## Troubleshooting

### Issue: "sqlite3 command not found"

brui v2.0+ requires sqlite3 for database queries.

**Check:**
```bash
command -v sqlite3
```

**Fix:**
```bash
# macOS (usually pre-installed)
brew install sqlite3

# Linux
apt-get install sqlite3  # Debian/Ubuntu
yum install sqlite       # RHEL/CentOS
```

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
load_issues()                    # Load issues from database via sqlite3
load_issues_from_database()      # Query database for specific status
render_kanban_simple()           # Draw 3-column board
watch_and_refresh()              # File watching loop
format_issue_card()              # Render issue details
detect_watch_tool()              # Auto-detect fswatch/inotify/poll
handle_input()                   # Keyboard input handler
find_beads_directory()           # Walk up tree to find .beads/
```

### Database Query Logic

```bash
# Query issues from database
load_issues_from_database() {
  local status="$1"  # "open", "in_progress", or "closed"

  # Build SQL query with label filtering and JSON aggregation
  sqlite3 beads.db "
    SELECT json_group_array(
      json_object(
        'id', i.id,
        'title', i.title,
        'status', i.status,
        'priority', COALESCE(i.priority, 2),
        'labels', (SELECT json_group_array(l.label)
                   FROM labels l WHERE l.issue_id = i.id)
      )
    )
    FROM issues i
    WHERE i.status = '$status' AND i.deleted_at IS NULL
    ORDER BY i.priority ASC, i.updated_at DESC
  "
}
```

### File Watching Logic

```bash
# Detect best method
detect_watch_tool() → "fswatch" | "inotifywait" | "poll"

# FSEvents (macOS) - watch database files
fswatch -0 -i '\.db$' -i '\.db-wal$' .beads/ | while read; do refresh; done

# inotify (Linux) - watch database and WAL
inotifywait -m -e modify beads.db beads.db-wal | while read; do refresh; done

# Polling (fallback) - check database modification time
while true; do
  if [[ $(stat -f %m beads.db) != $last_mtime ]]; then refresh; fi
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
