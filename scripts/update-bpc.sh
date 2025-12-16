#!/usr/bin/env bash
# Update Bypass Paywalls Clean (BPC) only when on home network.
# Features: home-network gating (BSSID & gateway MAC), backup + fast rollback, diagnostics, multi-browser reload.

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

set -euo pipefail

# -----------------------
# Config (edit as needed)
# -----------------------
ZIP_URL="https://gitflic.ru/project/magnolia1234/bpc_uploads/blob/raw?file=bypass-paywalls-chrome-clean-master.zip"
DEST_DIR="$HOME/Gits/bypass-paywalls-chrome-clean-master"
BACKUP_ROOT="$HOME/Gits/.backups"
STATE_FILE="$BACKUP_ROOT/bpc_last_backup.txt"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

# Home network fingerprints (authoritative)
ALLOWED_SSIDS=("JM" "JM_IoT")                         # optional; not used for Ethernet
ALLOWED_BSSIDS=("2a:70:4e:84:ed:54")                  # Wi-Fi BSSID (AP MAC)
ALLOWED_GATEWAY_MACS=("2a:70:4e:84:ed:54")            # Router MAC (LAN side)
ALLOWED_HOME_HOSTS=("3dprinter.local")                # optional presence checks; may be empty

# Browsers to reload (name or full app path) + target URLs
declare -a BROWSER_TARGETS=(
  $'app::Brave Browser\nurls::brave://extensions/'
  $'app::Microsoft Edge\nurls::edge://extensions/'
  $'app::Orion\nurls::orion://extensions'
  $'app::/Applications/Dia.app\nurls::chrome://extensions/\nurls::chrome-extension://lkbebcjgcmobigpeffafkodonchffocl/'
)

# --------------
# Helper funcs
# --------------
say() { printf ">> %s\n" "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 1; }; }

wifi_device() {
  networksetup -listallhardwareports | awk '
    $0 ~ /Hardware Port: Wi-Fi/ {wifi=1}
    wifi && $1=="Device:" {print $2; exit}
  '
}
current_ssid() {
  local dev; dev="$(wifi_device || true)"
  [[ -z "$dev" ]] && return 1
  networksetup -getairportnetwork "$dev" 2>/dev/null | sed 's/^Current Wi-Fi Network: //'
}
airport_bssid() {
  local airport="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  [[ -x "$airport" ]] || return 1
  "$airport" -I 2>/dev/null | awk '/ BSSID/ {print $2}'
}

normalize_mac() { tr '[:upper:]' '[:lower:]' | sed 's/[^0-9a-f:]//g'; }
mac_in_list() {
  local mac; mac="$(echo "$1" | normalize_mac)"
  shift
  local m
  for m in "$@"; do
    if [[ "$mac" == "$(echo "$m" | normalize_mac)" ]]; then return 0; fi
  done
  return 1
}

# All non-tunnel, non-loopback IPv4s (for diagnostics & gateway candidates)
all_local_ipv4s() {
  ifconfig -a | awk '
    /^[a-z0-9]+:/ {sub(":", "", $1); ifname=$1}
    /inet / {
      ip=$2
      if (ifname !~ /^(lo|utun|llw|awdl|ap|ppp|gif|stf)/) { print ifname, ip }
    }'
}

default_gateway() { /sbin/route -n get default 2>/dev/null | awk '/gateway:/{print $2; exit}'; }

# Light gateway discovery for MAC checks
discover_candidate_gateways() {
  local gw ifname ip gw_ip
  gw="$(default_gateway || true)"; [[ -n "$gw" ]] && echo "$gw"
  while read -r ifname ip ; do
    gw_ip="$(echo "$ip" | awk -F. '{printf "%d.%d.%d.1", $1,$2,$3}')"
    echo "$gw_ip"
  done < <(all_local_ipv4s)
}

gateway_mac_for_ip() {
  local ip="$1"
  ping -c1 -t1 "$ip" >/dev/null 2>&1 || true   # prime ARP
  /usr/sbin/arp -n "$ip" 2>/dev/null | awk 'NF{print $4}'
}

# ARP table contains any allowed router MAC?
arp_has_allowed_mac() {
  local table
  table="$(/usr/sbin/arp -an 2>/dev/null | tr '[:upper:]' '[:lower:]')" || table=""
  [[ -z "$table" ]] && return 1
  local m
  for m in "${ALLOWED_GATEWAY_MACS[@]}"; do
    [[ -z "$m" ]] && continue
    if echo "$table" | grep -q "$(echo "$m" | tr '[:upper:]' '[:lower:]')" ; then
      return 0
    fi
  done
  return 1
}

is_allowed_network() {
  local ssid="$1"; local s
  for s in "${ALLOWED_SSIDS[@]}"; do [[ "$ssid" == "$s" ]] && return 0; done
  return 1
}

latest_backup() {
  ls -1t "$BACKUP_ROOT"/bypass-paywalls-chrome-clean-master.*.tar.gz 2>/dev/null | head -n1 || true
}

extract_version() {
  local dir="$1"
  python3 - "$dir" <<'PY' 2>/dev/null
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
mf = root / "manifest.json"
if not mf.exists():
    for p in root.rglob("manifest.json"):
        mf = p
        break
ver = "unknown"
try:
    if mf.exists():
        d = json.loads(mf.read_text(encoding="utf-8"))
        ver = d.get("version") or d.get("version_name") or "unknown"
except Exception:
    pass
print(ver)
PY
}

open_in_browser() {
  local app="$1"; shift
  for u in "$@"; do /usr/bin/open -a "$app" "$u" >/dev/null 2>&1 || true; sleep 0.4; done
}
reload_extensions_ui() {
  [[ "${NO_RELOAD:-}" == "1" ]] && { say "Skipping browser reload (NO_RELOAD=1)."; return 0; }
  local entry app urls
  for entry in "${BROWSER_TARGETS[@]}"; do
    app=""; urls=()
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      case "$line" in
        app::*)  app="${line#app::}";;
        urls::*) urls+=("${line#urls::}");;
      esac
    done < <(printf '%s\n' "$entry")
    [[ -z "$app" ]] || open_in_browser "$app" "${urls[@]}"
  done

  /usr/bin/osascript <<'APPLESCRIPT' 2>/dev/null
on tapUpdateButton(appName)
  tell application "System Events"
    if not (exists process appName) then return
    tell process appName
      set didClick to false
      try
        repeat with w in windows
          try
            repeat with b in (buttons of w)
              try
                set t to name of b
                if t is "Update" or t is "Reload" then
                  click b
                  set didClick to true
                end if
              end try
            end repeat
          end try
        end repeat
      end try
      if didClick is false then keystroke "r" using {command down}
    end tell
  end tell
end tapUpdateButton

set appsToTap to {"Brave Browser", "Microsoft Edge", "Orion", "Dia"}
repeat with appName in appsToTap
  my tapUpdateButton(appName as text)
end repeat
APPLESCRIPT
}

backup_current() {
  mkdir -p "$BACKUP_ROOT"
  local ts bak; ts="$(date +"%Y%m%d-%H%M%S")"
  bak="$BACKUP_ROOT/bypass-paywalls-chrome-clean-master.$ts.tar.gz"
  say "Backing up current install -> $bak"
  tar -C "$(dirname "$DEST_DIR")" -czf "$bak" "$(basename "$DEST_DIR")"
  echo "$bak" > "$STATE_FILE"
  echo "$bak"
}
rollback_last() {
  local bak="${1:-$(latest_backup)}"
  [[ -z "$bak" ]] && { echo "No backup found to rollback." >&2; exit 2; }
  say "Rolling back from $bak"
  local aside="${DEST_DIR}.broken.$(date +%s)"
  [[ -d "$DEST_DIR" ]] && mv "$DEST_DIR" "$aside"
  mkdir -p "$(dirname "$DEST_DIR")"
  tar -C "$(dirname "$DEST_DIR")" -xzf "$bak"
  say "Rollback complete. Previous install moved to: $aside"
}

dump_signals() {
  echo "== Diagnostics =="
  echo "SSID: $(current_ssid || true)"
  echo "BSSID: $(airport_bssid || true)"
  echo "Local IPs:"; all_local_ipv4s | sed 's/^/  /'
  echo "Default gateway IP: $(default_gateway || true)"
  echo "Candidate gateways:"; discover_candidate_gateways | sort -u | sed 's/^/  /'
  echo "ARP table (top 10):"; /usr/sbin/arp -an | head -n 10 | sed 's/^/  /'
  echo "Allowed BSSIDs: ${ALLOWED_BSSIDS[*]:-}"
  echo "Allowed GW MACs: ${ALLOWED_GATEWAY_MACS[*]:-}"
  echo "Home hosts: ${ALLOWED_HOME_HOSTS[*]:-}"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--rollback [PATH]] [--no-reload] [--force] [--why]

  --rollback [PATH]   Restore from last (or given) backup and exit.
  --no-reload         Do not attempt to reload browsers.
  --force             Ignore network gate (run anywhere).
  --why               Print diagnostics and exit.
EOF
}

# --------------
# Argument parse
# --------------
WHY="0"; ROLLBACK=""; FORCE="0"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --rollback) shift; ROLLBACK="${1:-}"; [[ -n "${ROLLBACK}" && "${ROLLBACK:0:1}" != "-" ]] && shift || ROLLBACK="__LAST__" ;;
    --no-reload) export NO_RELOAD=1; shift ;;
    --force) FORCE="1"; shift ;;
    --why) WHY="1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [[ "$WHY" == "1" ]]; then dump_signals; exit 0; fi

need curl; need unzip; need rsync; need python3
mkdir -p "$BACKUP_ROOT"

if [[ -n "$ROLLBACK" ]]; then
  bak="$([[ "$ROLLBACK" == "__LAST__" ]] && latest_backup || echo "$ROLLBACK")"
  rollback_last "$bak"
  reload_extensions_ui
  exit 0
fi

# -------------------------
# Strong home-network gate
# -------------------------
allowed="0"; reason=""

# A) SSID match (if on Wi-Fi)
SSID="$(current_ssid || true)"
if [[ -n "$SSID" ]] && is_allowed_network "$SSID"; then
  allowed="1"; reason="SSID match ($SSID)"
fi

# B) BSSID match (precise Wi-Fi fingerprint)
if [[ "$allowed" != "1" ]]; then
  BSSID="$(airport_bssid || true)"
  if [[ -n "$BSSID" ]] && mac_in_list "$BSSID" "${ALLOWED_BSSIDS[@]}"; then
    allowed="1"; reason="BSSID match ($BSSID)"
  fi
fi

# C) Router MAC present in ARP table (works on Ethernet/Wi-Fi; robust under VPN)
if [[ "$allowed" != "1" && ${#ALLOWED_GATEWAY_MACS[@]} -gt 0 ]] && arp_has_allowed_mac; then
  allowed="1"; reason="Gateway MAC present in ARP table"
fi

# D) Presence check for home-only hosts (optional)
if [[ "$allowed" != "1" && ${#ALLOWED_HOME_HOSTS[@]} -gt 0 ]]; then
  for h in "${ALLOWED_HOME_HOSTS[@]}"; do
    if ping -c1 -t1 "$h" >/dev/null 2>&1; then
      allowed="1"; reason="Home host reachable ($h)"; break
    fi
  done
fi

if [[ "$FORCE" != "1" && "$allowed" != "1" ]]; then
  say "Not definitively at home. Skipping."
  exit 0
fi
say "Network check OK: $reason. Proceeding."

# ------------------------
# Download / verify / unzip
# ------------------------
TMPDIR="$(mktemp -d -t bpc_upd.XXXXXX)"
ZIP_PATH="$TMPDIR/bpc.zip"
trap 'rm -rf "$TMPDIR"' EXIT

say "Downloading latest zip..."
curl -fL --retry 3 --retry-delay 2 -A "$UA" -o "$ZIP_PATH" "$ZIP_URL"

say "Verifying zip..."
unzip -tq "$ZIP_PATH" >/dev/null

say "Extracting..."
unzip -q "$ZIP_PATH" -d "$TMPDIR"

# Find source dir
SRC_DIR=""
if [[ -d "$TMPDIR/bypass-paywalls-chrome-clean-master" ]]; then
  SRC_DIR="$TMPDIR/bypass-paywalls-chrome-clean-master"
else
  SRC_DIR="$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1 || true)"
fi
[[ -z "$SRC_DIR" ]] && { echo "Could not locate extracted source directory." >&2; exit 1; }

EXTRACTED_VER="$(extract_version "$SRC_DIR")"

# ------------------------
# Backup + update
# ------------------------
if [[ -d "$DEST_DIR" ]]; then
  LAST_BAK="$(backup_current)"
else
  mkdir -p "$DEST_DIR"
fi

say "Syncing into $DEST_DIR (rsync --delete, excluding .git/)..."
rsync -a --delete --exclude=".git/" "$SRC_DIR"/ "$DEST_DIR"/

INSTALLED_VER="$(extract_version "$DEST_DIR")"

say "Done."
say "Extracted version: $EXTRACTED_VER"
say "Installed version:  $INSTALLED_VER"

reload_extensions_ui