<!-- /Users/jason/.hammerspoon/.github/copilot-instructions.md -->
# Project Copilot Instructions

## Lua / Hammerspoon
- Prefer single-line tables for hotkey/action definitions when ≤ 100 chars and no nested tables.
- Use idioms: `hs.hotkey.bind(mods, key, fn)`, `hs.chooser.new`.
- Treat `hs` and `spoon` as globals.
- Avoid third-party Lua deps unless already present.
- **CRITICAL**: For symlinked configs, coroutines, or LuaRocks, see `hsLauncher/docs/HAMMERSPOON_CONSTRAINTS.md` in the workspace.

## Python
- Format with Black; lint with Ruff. Add type hints for new/edited functions.
- Prefer small, pure helpers and standard library where feasible.

## AppleScript
- Use `on handlerName(...) ... end handlerName`; explicit `return` when returning values.
- Prefer `System Events` for UI scripting; keep handlers short and composable.

## Change discipline
- Preserve public function names/signatures unless change is explicitly requested.
- When refactoring, include brief inline comments for non-obvious decisions.
