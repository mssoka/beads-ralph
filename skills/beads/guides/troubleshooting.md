# Troubleshooting

Common issues and solutions when working with beads tasks.

## Task Not Picked Up by Orchestration

### Symptom
Task exists but `br` doesn't pick it up.

### Causes

**Missing orchestration label**
```bash
# Check labels
bd show <id>

# Add missing label
bd update <id> --labels=ralph,existing,labels
```

**Task is blocked**
```bash
# Check if blocked
bd blocked

# View blockers
bd dep tree <id>
```

**Wrong status**
```bash
# Must be open
bd list --status=all | grep <id>

# Reopen if needed
bd reopen <id>
```

## `bd ready` Returns Nothing

### Causes

**All tasks are blocked**
```bash
bd blocked
bd dep cycles  # Check for cycles
```

**No tasks with orchestration label**
```bash
bd list --labels=ralph --status=open
```

**All tasks are closed**
```bash
bd list --status=open
```

## Circular Dependencies

### Symptom
```
Circular dependency detected:
  Task 10 -> Task 12 -> Task 15 -> Task 10
```

### Solution
Remove one dependency in the chain:
```bash
bd dep rm 15 10
# or
bd dep rm 12 15
# or
bd dep rm 10 12
```

## Task Missing Required Fields

### Symptom
Task created but unclear for execution.

### Solution
Edit to add missing fields:
```bash
bd edit <id>
```

Or update specific fields:
```bash
bd update <id> --description="..."
bd update <id> --design="..."
bd update <id> --acceptance="..."
```

## Dependency Tree Too Deep

### Symptom
Tasks are overly sequential, reducing parallelization.

### Diagnosis
```bash
bd dep tree <id>
# Look for long chains
```

### Solution
Reconsider dependencies:
- Are they all truly required?
- Can some tasks run in parallel?
- Are you using dependencies for organization? (Use labels instead)

## Wrong Priority Order

### Symptom
Less important tasks running before critical ones.

### Solution
Adjust priorities:
```bash
bd update <critical-id> --priority=0
bd update <less-important-id> --priority=2
```

## Can't Find a Task

### Search strategies

```bash
# By keyword in title
bd list | grep -i keyword

# By label
bd list --labels=feature-label

# All open
bd list --status=open

# Check if closed
bd list --status=closed | grep -i keyword
```

## Database Issues

### Reset beads (destructive!)
```bash
# Backup first
cp ~/.beads/beads.db ~/.beads/beads.db.backup

# Reinitialize
bd init --force
```

### Check database location
```bash
bd config  # Shows db path
```

## Performance Issues

### Symptom
Commands are slow.

### Causes

**Large number of tasks**
- Archive old completed tasks
- Use filters to reduce result sets

**Complex dependency graph**
```bash
bd dep cycles  # Simplify if needed
```
