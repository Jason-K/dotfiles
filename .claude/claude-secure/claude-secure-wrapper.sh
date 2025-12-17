#!/bin/zsh
set -euo pipefail

# ---------------------------------------
# claude-secure-wrapper.sh (drop-in)
# ---------------------------------------
# Usage examples:
#   claude-secure-wrapper.sh --config /path/projects.toml --preset hsLauncher -- --dangerously-skip-permissions
#   claude-secure-wrapper.sh --config /path/projects.toml --preset hsLauncher --dry-run --save-profile "$TMPDIR/test.sb" -- --dangerously-skip-permissions
#
# Preset TOML supports either:
#   [hsLauncher]
# or
#   [projects.hsLauncher]
#
# Keys supported:
#   project_root (string, required)
#   mode         (string: "rw" or "readonly"/"ro", default "readonly")
#   network      (bool, default true)
#   no_home      (bool, default false)
#   strict_temp  (bool, default true)
#   audit_log    (string, optional)
#   allow_rw     (array[string], optional)
#   allow_ro     (array[string], optional)
#   claude_bin   (string, optional; default "$HOME/.claude/local/claude")
#
# Notes:
# - no_home=true denies file reads/writes under $HOME by default, BUT:
#   - allows file metadata on /Users and /Users/$USER (prevents Node realpath EPERM)
#   - re-allows project_root + allow_rw/allow_ro
#   - re-allows executing claude_bin path if it's under HOME
# - rw mode denies writes everywhere first, then re-allows temp/project/allow_rw.

note() { print -ru2 -- "$*"; }

die() { note "ERROR: $*"; exit 2; }

usage() {
  cat <<'EOF' >&2
Usage:
  claude-secure-wrapper.sh --config <toml> --preset <name> [--dry-run] [--save-profile <path>] [--] <claude args...>

Examples:
  claude-secure-wrapper.sh --config ~/dotfiles/.claude/claude-secure/projects.toml --preset hsLauncher -- --dangerously-skip-permissions
  claude-secure-wrapper.sh --config ... --preset hsLauncher --dry-run --save-profile "$TMPDIR/test.sb" -- --dangerously-skip-permissions
EOF
}

# -------------------------
# arg parsing
# -------------------------
config_file=""
preset=""
dry_run=0
save_profile=""

claude_args=()

while (( $# )); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --config) shift; config_file="${1:-}";;
    --preset) shift; preset="${1:-}";;
    --dry-run) dry_run=1 ;;
    --save-profile) shift; save_profile="${1:-}";;
    --) shift; claude_args=("$@"); break ;;
    *)
      # allow calling like: wrapper ... --dangerously-skip-permissions (no explicit --)
      claude_args+=("$1")
      ;;
  esac
  shift || true
done

[[ -n "$config_file" ]] || die "--config is required"
[[ -n "$preset" ]] || die "--preset is required"
[[ -r "$config_file" ]] || die "Config not readable: $config_file"

# -------------------------
# TOML preset parsing (Python)
# -------------------------
# Emits JSON to stdout for a preset block (either [name] or [projects.name])
toml_to_json() {
  local cfg="$1"
  local name="$2"
  python3 - "$cfg" "$name" <<'PY'
import sys, json
path, name = sys.argv[1], sys.argv[2]

try:
    import tomllib as toml  # py>=3.11
except Exception:
    import tomli as toml    # fallback

with open(path, "rb") as f:
    data = toml.load(f)

block = None
if name in data and isinstance(data[name], dict):
    block = data[name]
elif isinstance(data.get("projects"), dict) and isinstance(data["projects"].get(name), dict):
    block = data["projects"][name]

if block is None:
    raise SystemExit(f"PRESET_NOT_FOUND:{name}")

# normalize allow lists
def to_list(x):
    if x is None: return []
    if isinstance(x, list): return [str(v) for v in x]
    return [str(x)]

out = {
    "project_root": str(block.get("project_root") or block.get("project") or ""),
    "mode": str(block.get("mode") or "readonly"),
    "network": bool(block.get("network", True)),
    "no_home": bool(block.get("no_home", False)),
    "strict_temp": bool(block.get("strict_temp", True)),
    "audit_log": str(block.get("audit_log") or ""),
    "claude_bin": str(block.get("claude_bin") or ""),
    "allow_rw": to_list(block.get("allow_rw")),
    "allow_ro": to_list(block.get("allow_ro")),
}
print(json.dumps(out))
PY
}

json=""
if ! json="$(toml_to_json "$config_file" "$preset" 2>/dev/null)"; then
  # try to surface the sentinel
  err="$(toml_to_json "$config_file" "$preset" 2>&1 || true)"
  if [[ "$err" == PRESET_NOT_FOUND:* ]]; then
    die "Preset '$preset' not found in $config_file"
  fi
  die "Failed reading preset '$preset' from $config_file"
fi

# -------------------------
# read JSON into vars (Python again, avoids jq dependency)
# -------------------------
read -r PROJECT_ROOT MODE ALLOW_NETWORK NO_HOME STRICT_TEMP AUDIT_LOG CLAUDE_BIN <<EOF
$(python3 - <<'PY' "$json"
import sys, json
d=json.loads(sys.argv[1])
print(
  d["project_root"],
  d["mode"],
  "1" if d["network"] else "0",
  "1" if d["no_home"] else "0",
  "1" if d["strict_temp"] else "0",
  d["audit_log"],
  d["claude_bin"],
)
PY
)
EOF

[[ -n "$PROJECT_ROOT" ]] || die "Preset '$preset' missing required key: project_root"

# default claude bin
if [[ -z "$CLAUDE_BIN" ]]; then
  CLAUDE_BIN="$HOME/.claude/local/claude"
fi

# expand to real paths where possible
PROJECT_ROOT_REAL="$(/usr/bin/python3 - <<'PY' "$PROJECT_ROOT"
import os, sys
p=sys.argv[1]
print(os.path.realpath(os.path.expanduser(p)))
PY
)"
[[ -d "$PROJECT_ROOT_REAL" ]] || die "project_root is not a directory: $PROJECT_ROOT_REAL"

CLAUDE_BIN_REAL="$(/usr/bin/python3 - <<'PY' "$CLAUDE_BIN"
import os, sys
p=sys.argv[1]
print(os.path.realpath(os.path.expanduser(p)))
PY
)"
[[ -x "$CLAUDE_BIN_REAL" ]] || die "claude_bin not executable: $CLAUDE_BIN_REAL"

HOME_REAL="$(/usr/bin/python3 - <<'PY'
import os
print(os.path.realpath(os.path.expanduser("~")))
PY
)"
TMPDIR_REAL="$(/usr/bin/python3 - <<'PY'
import os
print(os.path.realpath(os.environ.get("TMPDIR","/tmp")))
PY
)"

# allow lists from TOML
ALLOW_RW_LIST=()
ALLOW_RO_LIST=()
python3 - <<'PY' "$json" >"$TMPDIR_REAL/claude-secure.allow.$$"
import json, sys
d=json.loads(sys.argv[1])
for p in d.get("allow_rw", []):
    print("RW\t"+p)
for p in d.get("allow_ro", []):
    print("RO\t"+p)
PY
while IFS=$'\t' read -r kind p; do
  [[ -n "${p:-}" ]] || continue
  case "$kind" in
    RW) ALLOW_RW_LIST+=("$p") ;;
    RO) ALLOW_RO_LIST+=("$p") ;;
  esac
done <"$TMPDIR_REAL/claude-secure.allow.$$"
rm -f -- "$TMPDIR_REAL/claude-secure.allow.$$" 2>/dev/null || true

# resolve allow paths to real
resolve_real() {
  /usr/bin/python3 - <<'PY' "$1"
import os, sys
print(os.path.realpath(os.path.expanduser(sys.argv[1])))
PY
}

ALLOW_RW_REAL=()
for p in "${ALLOW_RW_LIST[@]}"; do
  r="$(resolve_real "$p")"
  [[ -e "$r" ]] || continue
  ALLOW_RW_REAL+=("$r")
done

ALLOW_RO_REAL=()
for p in "${ALLOW_RO_LIST[@]}"; do
  r="$(resolve_real "$p")"
  [[ -e "$r" ]] || continue
  ALLOW_RO_REAL+=("$r")
done

# -------------------------
# sandbox profile generation
# -------------------------
esc_scheme() {
  # escape for sandbox scheme string literal
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  print -r -- "$s"
}

# mktemp on macOS: XXXXXX must be at end
profile_base="$(/usr/bin/mktemp "${TMPDIR%/}/claude-secure-project.XXXXXX")"
profile_path="${profile_base}.sb"
/bin/mv -f -- "$profile_base" "$profile_path"

# Optionally write a copy to user-specified path later
SANDBOX_PROFILE="$profile_path"

NETWORK_RULES='(allow network*)'
if (( ! ALLOW_NETWORK )); then NETWORK_RULES='(deny network*)'; fi

# Temp rules
if (( STRICT_TEMP )); then
  TMP_ESCAPED="$(esc_scheme "$TMPDIR_REAL")"
  TEMP_RULES=$'(allow file-read* file-write*\n  (subpath "'"$TMP_ESCAPED"'")\n  (subpath "/tmp")\n  (subpath "/private/tmp")\n)'
else
  TEMP_RULES=$'(allow file-read* file-write*\n  (subpath "/private/var")\n  (subpath "/tmp")\n  (subpath "/private/tmp")\n)'
fi

# no_home rules:
# - allow *metadata* on key ancestors so Node realpath/lstat doesn't EPERM
# - deny reads/writes under $HOME (project/allowlists will re-allow specific subpaths)
NO_HOME_RULES=""
if (( NO_HOME )); then
  USER_HOME_ESCAPED="$(esc_scheme "$HOME_REAL")"

  # Metadata-only allows for path resolution
  CLAUDE_HOME_ESCAPED="$(esc_scheme "$HOME_REAL/.claude")"
  CLAUDE_LOCAL_ESCAPED="$(esc_scheme "$HOME_REAL/.claude/local")"

  # Project path chain metadata (Node realpath commonly touches these)
  SCRIPTS_ESCAPED="$(esc_scheme "$HOME_REAL/Scripts")"
  METASCRIPTS_ESCAPED="$(esc_scheme "$HOME_REAL/Scripts/Metascripts")"
  PROJECT_ESCAPED="$(esc_scheme "$PROJECT_ROOT_REAL")"

  NO_HOME_RULES=$'(allow file-read-metadata\n'\
$'  (literal "/Users")\n'\
$'  (literal "'"$USER_HOME_ESCAPED"'")\n'\
$'  (literal "'"$CLAUDE_HOME_ESCAPED"'")\n'\
$'  (literal "'"$CLAUDE_LOCAL_ESCAPED"'")\n'\
$'  (literal "'"$SCRIPTS_ESCAPED"'")\n'\
$'  (literal "'"$METASCRIPTS_ESCAPED"'")\n'\
$'  (literal "'"$PROJECT_ESCAPED"'")\n'\
$')\n'\
$'(deny file-read* file-write* (subpath "'"$USER_HOME_ESCAPED"'"))'
fi

# If claude_bin is under HOME and no_home is on, we must re-allow executable mapping there
CLAUDE_BIN_DIR="$(/usr/bin/dirname "$CLAUDE_BIN_REAL")"
CLAUDE_BIN_DIR_ESC="$(esc_scheme "$CLAUDE_BIN_DIR")"
CLAUDE_BIN_ALLOW=$'(allow file-read* file-map-executable\n  (subpath "'"$CLAUDE_BIN_DIR_ESC"'")\n)'

# Allow access to Claude config files when no_home is enabled
CLAUDE_CONFIG_ALLOW=""
if (( NO_HOME )); then
  # Resolve the actual config file location and its directory
  CLAUDE_CONFIG_JSON="$(/usr/bin/python3 - <<'PY'
import os, sys
config_path = os.path.expanduser("~/.claude.json")
if os.path.islink(config_path):
    real_path = os.path.realpath(config_path)
else:
    real_path = config_path
print(real_path)
PY
)"
  CLAUDE_CONFIG_DIR="$(/usr/bin/dirname "$CLAUDE_CONFIG_JSON")"
  CLAUDE_CONFIG_JSON_ESC="$(esc_scheme "$CLAUDE_CONFIG_JSON")"
  CLAUDE_CONFIG_LINK_ESC="$(esc_scheme "$HOME_REAL/.claude.json")"
  CLAUDE_CONFIG_BACKUP_ESC="$(esc_scheme "$HOME_REAL/.claude.json.backup")"
  CLAUDE_CONFIG_ALLOW=$'(allow file-read*\n  (literal "'"$CLAUDE_CONFIG_LINK_ESC"'")\n  (literal "'"$CLAUDE_CONFIG_JSON_ESC"'")\n  (literal "'"$CLAUDE_CONFIG_BACKUP_ESC"'")\n)\n'
fi

# Allow rules for project + allowlists
PROJECT_ESC="$(esc_scheme "$PROJECT_ROOT_REAL")"
ALLOW_LINES=()
ALLOW_LINES+=('(allow file-read* file-write* (subpath "'"$PROJECT_ESC"'"))')

for p in "${ALLOW_RW_REAL[@]}"; do
  pe="$(esc_scheme "$p")"
  ALLOW_LINES+=('(allow file-read* file-write* (subpath "'"$pe"'"))')
done
for p in "${ALLOW_RO_REAL[@]}"; do
  pe="$(esc_scheme "$p")"
  ALLOW_LINES+=('(allow file-read* (subpath "'"$pe"'"))')
done

# Mode handling: rw denies writes globally first, then allow temp + allow_rw etc.
# readonly mode simply doesn't deny writes globally; but still only allows what sandbox permits.
MODE_LC="${MODE:l}"
RW_MODE=0
if [[ "$MODE_LC" == "rw" || "$MODE_LC" == "write" ]]; then
  RW_MODE=1
fi

WRITE_CLAMP=""
if (( RW_MODE )); then
  WRITE_CLAMP='(deny file-write*)'
fi

# Write profile
{
  print "(version 1)"
  print ""
  print "; baseline: allow, then clamp down"
  print "(allow default)"
  print ""
  print "; allow subprocesses"
  print "(allow process*)"
  print ""
  print "; network policy"
  print "$NETWORK_RULES"
  print ""
  if (( RW_MODE )); then
    print "; rw mode: deny writes by default, then re-allow temp/project/allow_rw"
    print "$WRITE_CLAMP"
    print ""
  fi
  print "; temp access"
  print "$TEMP_RULES"
  print ""
  if (( NO_HOME )); then
    print "; no_home: deny reading/writing under HOME; keep metadata on /Users + /Users/$USER"
    print "$NO_HOME_RULES"
    print ""
    print "; allow executing claude_bin even when HOME is denied"
    print "$CLAUDE_BIN_ALLOW"
    print ""
  fi

  # always allow reading Claude config files (placed after deny rules to override)
  if (( NO_HOME )); then
    print "; allow reading Claude config files"
    print "$CLAUDE_CONFIG_ALLOW"
    print ""
  fi
  print "; project + allowlists"
  for l in "${ALLOW_LINES[@]}"; do print "$l"; done
} >"$SANDBOX_PROFILE"

# If user wants to save a copy somewhere, do it now (so dry-run still produces it)
if [[ -n "$save_profile" ]]; then
  /bin/mkdir -p -- "$(/usr/bin/dirname "$save_profile")" 2>/dev/null || true
  /bin/cp -f -- "$SANDBOX_PROFILE" "$save_profile"
fi

# -------------------------
# command assembly
# -------------------------
# Claude Code CLI behavior:
# - Interactive session by default (no subcommand required)
# - `code` is NOT a universal subcommand; only use it if the user explicitly typed it.
# - If the user passes flags like --help/--version, they should go to top-level `claude`.

FINAL_ARGS=()
if (( ${#claude_args[@]} > 0 )); then
  FINAL_ARGS=("${claude_args[@]}")
fi

cmd=(/usr/bin/sandbox-exec -f "$SANDBOX_PROFILE" "$CLAUDE_BIN_REAL" "${FINAL_ARGS[@]}")

# audit log (best-effort)
if [[ -n "$AUDIT_LOG" ]]; then
  /bin/mkdir -p -- "$(/usr/bin/dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '%s\tpreset=%s\tproject=%s\tmode=%s\tnetwork=%s\tcmd=%q\n' \
    "$(/bin/date '+%Y-%m-%dT%H:%M:%S%z')" "$preset" "$PROJECT_ROOT_REAL" "$MODE" "$ALLOW_NETWORK" "$cmd[@]" \
    >>| "$AUDIT_LOG" 2>/dev/null || true
fi

# Avoid getcwd weirdness if current dir is denied by sandbox
builtin cd "$PROJECT_ROOT_REAL" 2>/dev/null || true

# -------------------------
# output / exec
# -------------------------
note "Resolved config:"
note "  project_root: $PROJECT_ROOT_REAL"
note "  preset: $preset"
note "  mode: $MODE"
note "  network: $([[ $ALLOW_NETWORK -eq 1 ]] && echo allow || echo deny)"
note "  no_home: $NO_HOME"
note "  strict_temp: $STRICT_TEMP"
note "  audit_log: ${AUDIT_LOG:-<none>}"
note "  claude_bin: $CLAUDE_BIN_REAL"
note "  config_file: $config_file"
note "  allow_rw:"
if [[ ${#ALLOW_RW_REAL[@]} -gt 0 ]]; then for p in "${ALLOW_RW_REAL[@]}"; do note "    - $p"; done; else note "    (none)"; fi
note "  allow_ro:"
if [[ ${#ALLOW_RO_REAL[@]} -gt 0 ]]; then for p in "${ALLOW_RO_REAL[@]}"; do note "    - $p"; done; else note "    (none)"; fi
note "  sandbox_profile: $SANDBOX_PROFILE"
note "----- sandbox profile -----"
cat "$SANDBOX_PROFILE" >&2
note "----- command -----"
note "${(q)cmd}"

if (( dry_run )); then
  exit 0
fi

exec "${cmd[@]}"
