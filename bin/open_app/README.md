# open-app

Fast helper to activate a running app by bundle ID or launch it if not running.

## Usage

```bash
open-app -b com.example.App      # bundle id
open-app -a "App Name"           # by display name
open-app /Applications/App.app    # by path
```

## Behavior

- Always uses `NSWorkspace.openApplication` to ensure the app is activated and a window is visible (mimics Dock behavior).
- If the app is not running, it launches.
- If running but no windows, it opens a new window.

## Flags

- `-b <bundle_id>`: Identify by bundle identifier (fast path).
- `-a <app name>`: Identify by display name; searches /Applications, /System/Applications, and ~/Applications.
- `<path>`: Direct path to an .app bundle; if no slash and no .app suffix is given, common app dirs are searched.

## Notes

- Supports LaunchServices fast bundle lookup for bundle IDs.
- No extra dependencies; built with `swiftc -O -parse-as-library src/open-app.swift -o open-app`.
