# Mackup Timestamped Backups

This setup allows you to backup system settings with timestamped directories, circumventing mackup's limitation of hard-coded paths in `.mackup.cfg`.

## How It Works

The `mackup-backup.sh` wrapper script:

1. Generates a timestamp in `YYYY.MM.DD_HH.MM.SS` format
2. Creates a temporary `.mackup.cfg` with the full timestamped path
3. Runs mackup with this temporary config
4. Cleans up the temporary config afterward

## Usage

### Basic backup


```bash
cd ~/dotfiles/mackup
./mackup-backup.sh
```

Or from anywhere:
```bash
~/dotfiles/mackup/mackup-backup.sh
```

### Pass arguments to mackup
```bash
# Dry run
./mackup-backup.sh --dry-run

# Verbose output
./mackup-backup.sh --verbose

# Force yes to all prompts
./mackup-backup.sh --force
```

### Add to shell alias (optional)
Add to your `~/.zshrc` or `~/.bashrc`:
```bash
alias mackup-backup='~/dotfiles/mackup/mackup-backup.sh'
```

Then you can simply run:
```bash
mackup-backup --verbose
```

## Backup Structure

Backups will be stored in:
```
~/dotfiles/mackup/backups/
├── 2025.12.24_10.30.45/
│   ├── .app1/
│   ├── .app2/
│   └── ...
├── 2025.12.24_14.22.10/
│   └── ...
```

## Current .mackup.cfg

Your main `.mackup.cfg` is kept minimal:
```properties
[storage]
engine = file_system
path = dotfiles/mackup
directory = backup
```

This is used as a fallback and by the `mackup restore` command.

## Tips

- **Scheduling**: Use cron or launchd to automate backups:
  ```bash
  0 9 * * * ~/dotfiles/mackup/mackup-backup.sh >> ~/dotfiles/mackup/logs/backup.log 2>&1
  ```

- **Logging**: Redirect output to a log file:
  ```bash
  ./mackup-backup.sh --verbose >> logs/backup.log 2>&1
  ```

- **List backups**: See all timestamped backups:
  ```bash
  ls -la ~/dotfiles/mackup/backups/
  ```

- **Restore from specific backup**: Use mackup with a custom config pointing to the backup date you want
