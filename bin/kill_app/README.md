## KILL APP

Fast process termination tool using CoreGraphics detection and POSIX signals, compiled as a single Swift binary.

## USAGE

Kill the foreground application:

```bash
kill-app --foreground
```

Kill unresponsive applications:

```bash
kill-app
```

## FLAGS

- `--foreground`: Kill the frontmost app instead of unresponsive apps
- `--dry-run`: Parse and filter targets without sending signals (safe test)
- `--fast`: Use aggressive timeouts (default; TERM≈0.8s, KILL≈0.5s)
- `--instant`: Skip SIGTERM, send SIGKILL immediately
- `--exclude REGEX`: Skip processes matching pattern
- `--only REGEX`: Only target processes matching pattern
- `--graceful`: Add a brief pre-TERM grace wait

## EXAMPLES

```bash
# Quick kill frontmost app
kill-app --foreground

# Instant kill without grace period
kill-app --foreground --instant

# Kill unresponsive apps, excluding Safari
kill-app --exclude Safari

# Safe test run
kill-app --foreground --dry-run
```

## PERFORMANCE

- **Detection**: CoreGraphics window list (no Accessibility permission required for foreground)
- **Signaling**: Batch SIGTERM/SIGKILL to avoid per-process waits
- **Single Binary**: No overhead from shell script or `osascript` parsing

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
