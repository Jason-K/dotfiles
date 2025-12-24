# DNSCrypt-Proxy Blocklist Auto-Update

This automation keeps your DNSCrypt-Proxy blocklist up-to-date by running daily updates.

## Files Created

1. **update-blocklist.sh** - The update script that downloads and generates the blocklist
2. **com.user.dnscrypt.blocklist-update.plist** - The launchd job configuration

All files are located in `settIngs/blocklist-generator/`

## Installation

### 1. Copy the launchd plist to LaunchAgents

```bash
cp ~/dotfiles/dnscrypt-proxy/settIngs/blocklist-generator/com.user.dnscrypt.blocklist-update.plist ~/Library/LaunchAgents/
```

### 2. Load the launchd job

```bash
launchctl load ~/Library/LaunchAgents/com.user.dnscrypt.blocklist-update.plist
```

### 3. Verify it's loaded

```bash
launchctl list | grep dnscrypt
```

You should see `com.user.dnscrypt.blocklist-update` in the output.

## Manual Testing

Run the update script manually to test:

```bash
~/dotfiles/dnscrypt-proxy/settIngs/blocklist-generator/update-blocklist.sh
```

Check the log:

```bash
tail -f ~/dotfiles/dnscrypt-proxy/logs/blocklist-update.log
```

## Schedule

By default, the blocklist updates daily at **3:00 AM**.

To change the schedule, edit the `StartCalendarInterval` section in the plist file:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>3</integer>  <!-- Change this for different hour (0-23) -->
    <key>Minute</key>
    <integer>0</integer>  <!-- Change this for different minute (0-59) -->
</dict>
```

After editing, reload the job:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.dnscrypt.blocklist-update.plist
cp ~/dotfiles/dnscrypt-proxy/settIngs/blocklist-generator/com.user.dnscrypt.blocklist-update.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.dnscrypt.blocklist-update.plist
```

## Optional: Auto-Restart DNSCrypt-Proxy

To automatically restart dnscrypt-proxy after the blocklist updates, uncomment these lines in `update-blocklist.sh`:

```bash
# if pgrep -x "dnscrypt-proxy" > /dev/null; then
#     log "Restarting dnscrypt-proxy to apply new blocklist..."
#     brew services restart dnscrypt-proxy 2>&1 | tee -a "$LOG_FILE"
#     log "dnscrypt-proxy restarted"
# fi
```

## Logs

- **Update log**: `~/dotfiles/dnscrypt-proxy/logs/blocklist-update.log`
- **Launchd stdout**: `~/dotfiles/dnscrypt-proxy/logs/blocklist-launchd-stdout.log`
- **Launchd stderr**: `~/dotfiles/dnscrypt-proxy/logs/blocklist-launchd-stderr.log`

## Uninstallation

To stop and remove the automation:

```bash
launchctl unload ~/Library/LaunchAgents/com.user.dnscrypt.blocklist-update.plist
rm ~/Library/LaunchAgents/com.user.dnscrypt.blocklist-update.plist
```

## Troubleshooting

### Check if the job is loaded

```bash
launchctl list | grep dnscrypt
```

### View recent job executions

```bash
log show --predicate 'subsystem == "com.apple.launchd"' --last 1d | grep dnscrypt
```

### Force run the job now (for testing)

```bash
launchctl start com.user.dnscrypt.blocklist-update
```

### Check the logs

```bash
tail -50 ~/dotfiles/dnscrypt-proxy/logs/blocklist-update.log
```

## Features

- **Error handling**: Validates output before replacing the active blocklist
- **Sanity checking**: Ensures the new blocklist has a reasonable number of domains
- **Logging**: Comprehensive logs with timestamps
- **Safe updates**: Uses temporary files to avoid corrupting the active blocklist
- **Progress reporting**: Shows download progress in logs
- **Ignore failures**: Continues if some sources are temporarily unavailable
