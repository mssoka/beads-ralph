# Common Workflows

Practical examples of creating and organizing tasks.

## New Feature Workflow

### 1. Plan the feature

Break down into independent pieces where possible.

### 2. Create tasks

```bash
# Backend task
bd create --title="Add user preferences API" --type=task \
  --labels=ralph,preferences,backend --priority=1 \
  --description="API endpoints for user preferences CRUD" \
  --design="- GET/PUT /api/preferences in src/routes/preferences.ts
- PreferencesService in src/services/preferences.ts
- Use existing user auth middleware" \
  --acceptance="- GET returns current preferences
- PUT updates preferences
- Returns 401 if not authenticated"

# Frontend task (depends on backend)
bd create --title="Add preferences UI" --type=task \
  --labels=ralph,preferences,frontend --priority=1 \
  --description="Settings page for user preferences" \
  --design="- PreferencesPage component
- Use existing form components
- Call preferences API" \
  --acceptance="- Displays current preferences
- Saves changes on submit
- Shows loading/error states"

# Add dependency
bd dep add <frontend-id> <backend-id>

# Independent testing task (no dependency)
bd create --title="Add preferences E2E tests" --type=task \
  --labels=ralph,preferences,testing --priority=2 \
  --description="End-to-end tests for preferences feature" \
  --design="- Test file in tests/e2e/preferences.spec.ts
- Cover happy path and error cases" \
  --acceptance="- Tests pass in CI
- Cover GET/PUT operations
- Cover auth errors"
```

### 3. Check ready tasks

```bash
bd ready
# Shows: backend task, testing task (frontend is blocked)
```

## Bug Fix Workflow

```bash
bd create --title="Fix login timeout on slow connections" --type=bug \
  --labels=ralph,auth,bugfix --priority=0 \
  --description="Users on slow connections get timeout errors during login.
Reported in issue #234. Affects ~5% of login attempts." \
  --design="- Increase timeout in src/services/auth.ts from 5s to 30s
- Add retry logic with exponential backoff
- Show loading indicator during retry" \
  --acceptance="- Login succeeds on 3G connection
- User sees loading state during slow auth
- Timeout error only after 3 retries"
```

## Refactoring Workflow

When refactoring affects multiple areas, create separate tasks:

```bash
# Core refactor
bd create --title="Extract payment processing to service" --type=task \
  --labels=ralph,payments,refactor --priority=2 \
  --description="Payment logic is scattered across controllers.
Extract to dedicated service for maintainability." \
  --design="- Create PaymentService class
- Move validation, processing, and receipt logic
- Keep controllers thin" \
  --acceptance="- All payment logic in PaymentService
- Controllers only handle HTTP concerns
- Existing tests pass"

# Dependent cleanup
bd create --title="Remove deprecated payment helpers" --type=task \
  --labels=ralph,payments,refactor --priority=3 \
  --description="Clean up old payment helper functions after refactor" \
  --design="- Delete src/helpers/payment.ts
- Update imports in affected files" \
  --acceptance="- No references to old helpers
- Build succeeds"

bd dep add <cleanup-id> <refactor-id>
```

## Filtering Tasks

### By label

```bash
bd list --labels=auth --status=open
bd list --labels=backend,auth --status=open
```

### By status

```bash
bd list --status=open      # All open
bd list --status=closed    # Completed
bd ready                   # Open and unblocked
```

### Combining filters

```bash
bd list --labels=auth --status=open --priority=0
```

## Daily Workflow

```bash
# Start of day - what's ready?
bd ready

# Pick a task
bd show <id>

# Work on it...

# When done, close it
bd close <id>

# Check what unblocked
bd ready
```
