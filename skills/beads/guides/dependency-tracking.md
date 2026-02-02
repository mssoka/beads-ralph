# Dependency Tracking

Dependencies define execution order. Use them sparingly to maximize parallelization.

## Basic Commands

```bash
bd dep add <child> <parent>  # child depends on parent
bd dep rm <child> <parent>   # Remove dependency
bd dep tree <id>             # View dependency chain
bd dep cycles                # Check for circular dependencies
```

## When to Add Dependencies

### Add dependencies when:

**Backend before frontend**
```bash
# API must exist before UI can call it
bd dep add login-ui-task login-api-task
```

**Migration before code**
```bash
# Schema change must be deployed first
bd dep add user-model-update user-table-migration
```

**Core before feature**
```bash
# Base component needed by feature
bd dep add checkout-flow payment-service
```

### Don't add dependencies when:

**Tasks are related but independent**
```bash
# These can run in parallel - use labels instead
bd create --title="Auth API" --labels=ralph,auth ...
bd create --title="Auth docs" --labels=ralph,auth ...
# No dependency needed - one doesn't block the other
```

**You just want ordering preference**
```bash
# "Nice to have" order isn't a real dependency
# If task B can technically run without task A, no dependency
```

**Shared data that exists already**
```bash
# Both use the same table but don't change it
# No dependency needed
```

## Dependency Trees

View the full dependency chain:

```bash
bd dep tree 42
```

Output:
```
Task 42: Add checkout flow
├── Task 38: Payment service (completed)
│   └── Task 35: Database schema (completed)
└── Task 40: Cart API (in progress)
```

## Checking for Cycles

Circular dependencies prevent execution:

```bash
bd dep cycles
```

If cycles exist:
```
Circular dependency detected:
  Task 10 -> Task 12 -> Task 15 -> Task 10
```

Fix by removing one dependency in the chain.

## Parallelization Impact

**Over-constrained (bad)**
```
A -> B -> C -> D -> E
```
All 5 tasks run sequentially. Total time = sum of all tasks.

**Well-constrained (good)**
```
A (no deps)
B (no deps)
C -> A
D -> B
E -> C, D
```
A and B run in parallel. C and D run in parallel after their deps. E runs last.

## Best Practices

1. **Start with no dependencies** - Add only when you hit an actual blocker

2. **Dependencies are technical, not organizational** - Use labels for grouping

3. **Check cycles before execution**
   ```bash
   bd dep cycles
   ```

4. **Review dependency tree** - If it's very deep, reconsider structure
   ```bash
   bd dep tree <id>
   ```

5. **Remove completed task dependencies** - They're automatically satisfied but cleaning up is good hygiene
