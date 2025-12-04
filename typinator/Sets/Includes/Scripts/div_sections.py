#!/usr/bin/env python3
import sys, re, os

# Accept digits as argv (e.g., "12") or embedded in a token (e.g., "div12")
token = "".join(sys.argv[1:]) if len(sys.argv) > 1 else ""
m = re.search(r'([1-9])([1-9])?', token.replace(" ", ""))  # tolerate spaces like "13"

if not m:
    # No digits found; emit nothing (Typinator will just insert empty string)
    print("", end="")
    sys.exit(0)

a = int(m.group(1))
b = int(m.group(2)) if m.group(2) else None

# Default: cascade for single digits (e.g., "div3" -> 3,2,1).
# Set DIV_CASCADE_SINGLE=0 in Typinator if you want only level 3 (no cascade).
cascade_single = os.getenv("DIV_CASCADE_SINGLE", "1") != "0"

if b is None:
    levels = list(range(a, 0, -1)) if cascade_single else [a]
else:
    hi, lo = (a, b) if a > b else (b, a)
    levels = list(range(hi, lo - 1, -1))

lines = [("\t" * (lvl - 1)) + "--" for lvl in levels]
print("\n".join(lines), end="")