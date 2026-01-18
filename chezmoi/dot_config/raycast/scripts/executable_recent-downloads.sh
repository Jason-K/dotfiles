#!/usr/bin/env bash
# <Raycast.schemaVersion>1</Raycast.schemaVersion>
# <Raycast.title>Recent Downloads</Raycast.title>
# <Raycast.mode>list</Raycast.mode>
# <Raycast.packageName>Utilities</Raycast.packageName>

DOWNLOADS="$HOME/Downloads"

# If Raycast passes an argument, open that file
if [[ -n "$1" ]]; then
  open "$DOWNLOADS/$1"
  exit
fi

# Otherwise, list the top 10 most recent downloads
ls -1t "$DOWNLOADS" | head -n 10
