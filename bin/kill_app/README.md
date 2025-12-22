## KILL APP

Fast process termination tool using CoreGraphics detection and POSIX signals.

## USAGE

Kill the foreground application:

```bash
execute-kill.sh --foreground
```

Kill unresponsive applications:

```bash
execute-kill.sh
```

## FLAGS

- `--foreground`: Kill the frontmost app instead of unresponsive apps
- `--dry-run`: Parse and filter targets without sending signals (safe test)
- `--fast`: Use aggressive timeouts (default; TERM≈0.8s, KILL≈0.5s)
- `--no-fast`: Use relaxed timeouts from config or defaults
- `--full`: Emit complete process details (name/bundle/pid); default is PID-only for speed
- `--instant`: Skip SIGTERM, send SIGKILL immediately
- `--exclude REGEX`: Skip processes matching pattern
- `--only REGEX`: Only target processes matching pattern

## EXAMPLES

```bash
# Quick kill frontmost app (default: fast + pid-only)
execute-kill.sh --foreground

# Kill with full details for logging/debugging
execute-kill.sh --foreground --full

# Instant kill without grace period
execute-kill.sh --foreground --instant

# Kill unresponsive apps, excluding Safari
execute-kill.sh --exclude Safari

# Safe test run
execute-kill.sh --foreground --dry-run
```

## PERFORMANCE

- **Detection**: CoreGraphics window list (no Accessibility permission required)
- **Default mode**: PID-only JSON for minimal overhead
- **Signaling**: Batch SIGTERM/SIGKILL to avoid per-process waits
- **Typical latency**: <100ms for foreground kills

## CONFIGURATION

Optional config at `~/.config/unfreeze.json`:

```json
{
  "denylist": ["^Finder$", "^loginwindow$"],
  "gracePeriodSec": 0.5,
  "termWaitSec": 0.8,
  "killWaitSec": 0.5
}
```
