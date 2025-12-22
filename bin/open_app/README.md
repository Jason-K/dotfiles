# open_app / launch-or-activate

Fast helper to activate a running app by bundle ID or launch it if not running.

## Usage

```bash
launch-or-activate -b com.example.App      # bundle id
launch-or-activate -a "App Name"           # by display name
launch-or-activate /Applications/App.app    # by path
```

## Behavior

- If the app is already running (bundle ID), it is activated.
- Otherwise, it is launched via NSWorkspace using a synchronous open (10s timeout).

## Flags

- `-b <bundle_id>`: Identify by bundle identifier (fast path).
- `-a <app name>`: Identify by display name; searches /Applications, /System/Applications, and ~/Applications.
- `<path>`: Direct path to an .app bundle; if no slash and no .app suffix is given, common app dirs are searched.

## Notes

- Supports LaunchServices fast bundle lookup for bundle IDs.
- No extra dependencies; built with `swiftc -O -parse-as-library src/launch-or-activate.swift -o launch-or-activate`.
