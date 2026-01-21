# Bug: `--robot-triage-by-track` creates one track per task instead of grouping independent tasks

## Summary

`bv --robot-triage-by-track` is creating **one track per task** with reason "Single actionable item" instead of grouping independent (non-blocked) tasks into the same track for parallel execution. This defeats the purpose of tracks as "parallel work streams."

## Environment

- **BV Version**: 0.13.0
- **Project**: LarOS (624 total issues, 54 open)
- **Label filter**: `ralph` (50 tasks with this label)

## Expected Behavior

According to [AGENTS.md](https://github.com/Dicklesworthstone/beads_viewer/blob/main/AGENTS.md):

> "Tracks represent parallel work streams that can be executed simultaneously"

For tasks with **no dependencies** (`blocked_by: null`), I expect them to be **grouped into the same track** to enable parallel execution:

```json
{
  "track_id": "track-0",
  "reason": "Independent tasks ready for parallel execution",
  "recommendations": [
    {"id": "LarOS-11wa", "blocked_by": null},
    {"id": "LarOS-h09w", "blocked_by": null},
    {"id": "LarOS-oflo", "blocked_by": null},
    {"id": "LarOS-jjjc", "blocked_by": null},
    {"id": "LarOS-5xyu", "blocked_by": null}
  ]
}
```

## Actual Behavior

BV creates **one track per task**, completely preventing parallel execution:

```bash
$ bv --robot-triage-by-track | jq '.triage.recommendations_by_track[] | {track_id, reason, task_count: (.recommendations | length)}'
```

**Output:**
```json
{
  "track_id": "track-A",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-AE",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-AM",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-F",
  "reason": "Independent work stream",
  "task_count": 1
}
{
  "track_id": "track-K",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-M",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-R",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-S",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "track-W",
  "reason": "Single actionable item",
  "task_count": 1
}
{
  "track_id": "ungrouped",
  "reason": "Tasks not fitting above groups",
  "task_count": 1
}
```

## Statistics

```bash
$ bv --robot-triage-by-track | jq '{
  total_tracks: (.triage.recommendations_by_track | length),
  total_tasks: [.triage.recommendations_by_track[].recommendations[]] | length,
  tracks_with_1_task: [.triage.recommendations_by_track[] | select((.recommendations | length) == 1)] | length,
  tracks_with_multiple: [.triage.recommendations_by_track[] | select((.recommendations | length) > 1)] | length
}'
```

**Output:**
```json
{
  "summary": {
    "total_tracks": 10,
    "total_tasks": 10,
    "tracks_with_1_task": 10,
    "tracks_with_multiple": 0
  }
}
```

**Result:** 100% of tracks contain only 1 task, despite having 53 actionable (unblocked) tasks available.

## Impact

This behavior breaks tools that depend on tracks for parallel execution:

1. **[beads-ralphy](https://github.com/your-repo/ralphy)** - Uses tracks to run multiple AI agents in parallel via git worktrees
2. Multi-agent orchestration systems that allocate work based on tracks
3. Team workflows that distribute parallel work streams

### Current Workaround Required

Since tracks don't group tasks, parallel execution tools must:
1. Ignore `--robot-triage-by-track` entirely
2. Manually parse `--robot-triage` recommendations and group by `blocked_by`
3. Implement custom dependency resolution logic

This duplicates BV's graph analysis and defeats the purpose of the `--robot-triage-by-track` flag.

## Reproduction

```bash
# In any beads project with multiple unblocked tasks
bv --robot-triage-by-track | jq '[.triage.recommendations_by_track[] | {
  track_id,
  task_count: (.recommendations | length),
  tasks: [.recommendations[] | {id, blocked_by}]
}]'
```

Expected: Multiple tasks grouped into track(s) with `blocked_by: null`
Actual: Each task in its own track with reason "Single actionable item"

## Questions

1. Is this intended behavior? If so, what is the purpose of tracks if they don't enable parallelization?
2. Is there a flag or configuration to enable task grouping within tracks?
3. Should the documentation be updated to clarify that tracks are sequential execution units rather than parallel work streams?

## Suggested Fix

Group all tasks with `blocked_by: null` (or `blocked_by: []`) into the same initial track (e.g., `track-0`), then create subsequent tracks for tasks that depend on completion of earlier tracks:

```
Track 0: [Task A, Task B, Task C] (all have no blockers, can run in parallel)
Track 1: [Task D, Task E] (depend on Track 0 tasks, run in parallel after Track 0 completes)
Track 2: [Task F] (depends on Track 1 tasks)
```

This would enable true parallel execution while respecting dependencies.
