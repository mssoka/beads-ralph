# Creating Tasks

This guide covers creating well-formed tasks that orchestration tools can pick up.

## Basic Task Creation

```bash
bd create --title="Add login endpoint" --type=task \
  --labels=ralph,auth,backend --priority=1 \
  --description="What needs to be done and why" \
  --design="Technical approach, files to modify" \
  --acceptance="- Testable requirement 1
- Testable requirement 2"
```

## Required Fields

### Title

Short, action-oriented description of the work.

```bash
# Good titles
--title="Add user authentication endpoint"
--title="Fix race condition in queue processor"
--title="Refactor payment module to use new API"

# Bad titles
--title="Auth"                    # Too vague
--title="Work on the thing"       # Not descriptive
--title="Fix bug"                 # Which bug?
```

### Type

The issue type determines how beads categorizes and displays the task.

```bash
--type=task    # Standard work item
--type=bug     # Bug fix
--type=epic    # Parent for grouping (not for orchestration)
```

### Labels

Labels control orchestration pickup and organization.

```bash
--labels=ralph,auth,backend
```

**Required label**: `ralph` (or your configured orchestration label)
- Without this label, `br` won't pick up the task

**Feature labels**: Group related work
- `auth`, `payments`, `search`, etc.

**Layer labels**: Technical grouping
- `backend`, `frontend`, `infra`, `testing`

### Priority

Controls execution order when multiple tasks are ready.

```bash
--priority=0   # Critical - do first
--priority=1   # High
--priority=2   # Medium (default)
--priority=3   # Low
--priority=4   # Backlog
```

### Description

What needs to be done and why. Context for the implementer.

```bash
--description="Users cannot currently authenticate to the API.
This blocks all protected resource access. We need a login
endpoint that validates credentials and returns a JWT."
```

### Design

Technical approach and implementation hints.

```bash
--design="1. Add POST /api/login route in src/routes/auth.ts
2. Create validateCredentials() in src/services/auth.ts
3. Use existing JWT utils from src/utils/jwt.ts
4. Add rate limiting middleware"
```

### Acceptance Criteria

Testable requirements for completion. Use markdown list format.

```bash
--acceptance="- POST /api/login returns 200 with JWT on valid credentials
- Returns 401 with error message on invalid credentials
- Rate limits to 5 attempts per minute per IP
- JWT expires after 24 hours
- Logs authentication attempts"
```

## Complete Example

```bash
bd create --title="Add user registration endpoint" --type=task \
  --labels=ralph,auth,backend --priority=1 \
  --description="New users need to create accounts. This endpoint handles
registration with email/password, validates input, and creates the user
record." \
  --design="- Add POST /api/register in src/routes/auth.ts
- Validate email format and password strength
- Hash password with bcrypt before storing
- Send welcome email via existing email service
- Return user object (without password)" \
  --acceptance="- Returns 201 with user object on success
- Returns 400 if email already exists
- Returns 400 if password doesn't meet requirements
- Password is hashed in database
- Welcome email is sent
- User can login immediately after registration"
```

## Viewing Created Tasks

```bash
# Show task details
bd show <id>

# List all open tasks
bd list --status=open

# Find ready tasks (no blockers)
bd ready
```

## Editing Tasks

```bash
# Edit in editor
bd edit <id>

# Update specific field
bd update <id> --priority=0
bd update <id> --labels=ralph,auth,urgent
```
