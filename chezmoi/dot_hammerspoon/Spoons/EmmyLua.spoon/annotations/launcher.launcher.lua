--# selene: allow(unused_variable)
---@diagnostic disable: unused-local

-- hsLauncher - Lua-first Hammerspoon launcher with hotkeys, menus, and command execution
---@class launcher.launcher
local M = {}
launcher.launcher = M

-- Compute absolute path to the generated config file (default `generated.lua`).
function M.config_merger.generatedPath(configDir, ...) end

-- Normalize a config extension into `{ commands, menus, menuItems, hotkeys, settings }`.
function M.config_merger.normalize(extension, ...) end

-- Deep-copy a value (tables copied recursively).
function M.config_merger.clone(value, ...) end

-- Apply a normalized extension into a base config, merging commands/menus/hotkeys/settings.
function M.config_merger.apply(config, extension, opts, ...) end

-- Load and normalize a generated config file from disk.
function M.config_merger.load(path, ...) end

-- Determine whether a table is a dense array (1..n).
---@return boolean
function M.config_merger.isArray(tbl, ...) end

-- Creates a new Karabiner-style menu overlay renderer.
function M.ui.karabiner_style_overlay.new() end

-- Hides and deletes both the items and indicator canvas elements.
function M.ui.karabiner_style_overlay:hide() end

-- Renders the Karabiner-style menu overlay with items and indicator boxes.
function M.ui.karabiner_style_overlay:render(menu, items, settings, searchState, diagnostics, ...) end

-- Creates an on-screen circular indicator for the virtual modifier.
function M.ui.virtual_indicator.new(opts, ...) end

-- Shows or hides the indicator based on virtual modifier state.
function M.ui.virtual_indicator:update(isActive, ...) end

-- Deletes the indicator canvas and cleans up resources.
function M.ui.virtual_indicator:delete() end

-- Creates a new MenuOverlay for rendering menus via hs.canvas.
function M.ui.menu_overlay.new(opts, ...) end

-- Renders the menu overlay with given items, search, and diagnostics.
function M.ui.menu_overlay:render(menu, items, settings, searchState, diagnostics, ...) end

-- Hides and deletes the menu overlay canvas.
function M.ui.menu_overlay:hide() end

-- Configure window zones definitions used for zone-based actions.
function M.window_manager:configureZones(definitions, ...) end

-- Perform a window action (move/resize/focus/zone operations).
function M.window_manager:perform(action, opts, ...) end

-- Perform a window action using the default singleton instance.
function M.window_manager.perform(action, opts, ...) end

-- Configure window zones definitions using the default singleton instance.
function M.window_manager.configureZones(definitions, ...) end

-- Creates a focus navigator for directional window selection
launcher.Creates a new FocusNavigator instance = nil

-- Calculates center coordinates from frame dimensions
launcher.Computes the center point of a frame = nil

-- Returns axis and sign for directional calculations
launcher.Gets direction info for a given direction name = nil

-- When no directional match found, selects window at opposite edge
launcher.Selects the best wrap-around candidate = nil

-- Finds the closest window in the target direction using three-tier selection
launcher.Selects the best directional candidate = nil

-- High-level API for directional focus selection
launcher.Selects focus target in a given direction = nil

-- Creates a history manager for tracking window frame positions
launcher.Creates a new WindowHistoryManager instance = nil

-- Adds a frame to the window's history, enforcing maximum depth
launcher.Pushes a new frame onto the history stack for a window = nil

-- Pops the last frame from the window's history stack
launcher.Removes and returns the most recent frame from history = nil

-- Removes all stored frames for the given window, or all windows if nil
launcher.Clears history for a specific window or all windows = nil

-- Returns the number of frames stored for the given window
launcher.Gets the current size of the history stack for a window = nil

-- Returns true if the window has at least one frame in history
launcher.Checks if a window has any history = nil

-- Creates a zone sequencer for tracking zone interaction state
launcher.Creates a new ZoneSequencer instance = nil

-- Stores the current zone move interaction for repeat detection
launcher.Records a zone move operation = nil

-- Stores the current zone cycle interaction for repeat detection
launcher.Records a zone cycle operation = nil

-- Stores the current zone focus interaction for repeat detection
launcher.Records a zone focus operation = nil

-- Determines if the given operation matches the last recorded state
launcher.Checks if the current operation is a repeat = nil

-- Returns the current state without modifying it
launcher.Gets the current zone sequence state = nil

-- Clears all recorded zone interaction state
launcher.Resets the zone sequence state = nil

-- Returns true if state is currently tracking a zone interaction
launcher.Checks if there is any active state = nil

-- Creates a layout cycler for managing window cycling state
launcher.Creates a new LayoutCycler instance = nil

-- Advances the window through horizontal size progression
launcher.Cycles horizontal layout for a window = nil

-- Toggles the vertical anchor between top and bottom
launcher.Cycles vertical layout for a window = nil

-- Returns the current horizontal cycling state without modifying it
launcher.Gets the current horizontal layout state = nil

-- Returns the current vertical anchor state without modifying it
launcher.Gets the current vertical layout state = nil

-- Removes all cycling state for the given window
launcher.Clears layout state for a specific window or all windows = nil

-- Returns true if the window has horizontal or vertical state
launcher.Checks if a window has any cycling state = nil

-- Ensures fraction values are within acceptable bounds
---@type table
launcher.Clamps fraction value to valid range  = {}

-- Creates a frame centered within the parent frame with specified dimensions
launcher.Calculates a centered frame with optional ratio or percentage = nil

-- Creates a frame filling half (or fraction) of the parent frame
launcher.Calculates a half-screen frame aligned to edge = nil

-- Creates a frame filling half (or fraction) aligned to right/bottom
launcher.Calculates a half-screen frame aligned to opposite edge = nil

-- Creates a frame positioned in one of four corners
launcher.Calculates a corner-positioned frame = nil

-- Creates a frame anchored to a direction with optional vertical anchor
launcher.Builds an anchored frame for horizontal cycling = nil

-- Creates a new logger instance that proxies to Hammerspoon's `hs.logger` when available.
function M.logger.new(name, ...) end

-- Sets the console log level for this logger.
function M.logger:setConsoleLevel(level, ...) end

-- Sets the file log level for this logger.
function M.logger:setFileLevel(level, ...) end

-- Sets a custom file path for log output.
function M.logger:setLogFile(path, ...) end

-- Logs a debug message using string.format-style interpolation.
function M.logger:d(fmt, ...) end

-- Logs an info message using string.format-style interpolation.
function M.logger:i(fmt, ...) end

-- Logs a warning message using string.format-style interpolation.
function M.logger:w(fmt, ...) end

-- Logs an error message using string.format-style interpolation.
function M.logger:e(fmt, ...) end

-- Creates a new MenuManager responsible for building and presenting menus.
function M.menu_manager.new(logger, commandRunner, menus, commands, activity, settings, dependencies, ...) end

-- Replaces the definitions used by the menu manager.
function M.menu_manager:updateDefinitions(menus, commands, settings, activity, ...) end

-- Installs callbacks that fire when a menu is shown or hidden.
function M.menu_manager:setLifecycleCallbacks(onShow, onHide, ...) end

-- Sets providers that return runtime diagnostics to include in overlays.
function M.menu_manager:setRuntimeDiagnosticsProviders(providers, ...) end

-- Supplies binding metadata for collision analysis and diagnostics.
function M.menu_manager:setBindingMetadata(metadata, ...) end

-- Builds and shows a menu by ID, enabling keyboard-driven interaction.
function M.menu_manager:showMenu(menuId, context, ...) end

-- Hides the currently visible menu, if any.
function M.menu_manager:hideMenu() end

-- Toggles a menu - shows it if hidden, hides it if currently showing.
function M.menu_manager:toggleMenu(menuId, context, ...) end

-- Configure window zones definitions used for zone-based actions.
function M.window_manager.configureZones(definitions, ...) end

-- Perform a window action (move/resize/focus/zone operations).
function M.window_manager.perform(action, opts, ...) end

-- Registers the hslauncher:// URL scheme handler with Hammerspoon.
---@return boolean
function M.url_api:register() end

-- Unregisters the hslauncher:// URL scheme handler.
function M.url_api:unregister() end

-- Updates the dependencies (commandRunner, menuManager, notifier).
function M.url_api:update(opts, ...) end

-- Replace zone definitions used for screens/zones.
function M.window_zones:configure(definitions, ...) end

-- Get a zone definition for a screen by id.
function M.window_zones:getZone(screen, zoneId, ...) end

-- Compute the absolute frame for a zone on a screen.
function M.window_zones:getZoneFrame(screen, zoneId, ...) end

-- List normalized zones for a screen in display order.
function M.window_zones:listZones(screen, ...) end

-- Filter a window list to those centered within a given zone.
function M.window_zones:windowsInZone(screen, zoneId, windows, ...) end

-- Creates a new TextProcessorCatalog for managing the text processor registry.
function M.text_processor_catalog.new(opts, ...) end

-- Sets the bridge used to communicate with the Python text processor CLI.
function M.text_processor_catalog:setBridge(bridge, ...) end

-- Configures cache TTL and force-refresh behavior for registry fetches.
function M.text_processor_catalog:setRefreshPolicy(policy, ...) end

-- Fetches the registry from Python CLI when cache is stale or forced; caches result.
function M.text_processor_catalog:refresh(opts, ...) end

-- Returns the last cached registry table without fetching.
function M.text_processor_catalog:get() end

-- Returns the Unix timestamp of the last successful registry fetch.
function M.text_processor_catalog:getLastFetched() end

-- Creates and initializes a new HotkeyEngine with all required sub-modules.
function M.hotkey_engine.new(opts, ...) end

-- Returns the key signature for a normalized keyboard event (e.g. "cmd-shift-k").
function M.hotkey_engine:keySignature(event, ...) end

-- Returns the key signature for a key and modifier flags (e.g. "alt-1").
function M.hotkey_engine:keySignatureFor(key, flags, ...) end

-- Checks whether a key signature is currently pressed.
---@return boolean
function M.hotkey_engine:isSignatureDown(signature, ...) end

-- Retrieves the internal key state object for a signature.
function M.hotkey_engine:getKeyState(signature, ...) end

-- Returns a snapshot of all currently pressed keys.
function M.hotkey_engine:getKeysDownSnapshot() end

-- Starts the hotkey engine and begins processing events.
function M.hotkey_engine:start() end

-- Stops the hotkey engine and stops processing events.
function M.hotkey_engine:stop() end

-- Suspends event processing without fully stopping the engine.
function M.hotkey_engine:suspend() end

-- Resumes event processing after suspension.
function M.hotkey_engine:resume() end

-- Returns whether the virtual modifier is currently active.
---@return boolean
function M.hotkey_engine:isVirtualModifierActive() end

-- Determines virtual modifier mode from configuration settings.
function M.modifier_resolver.resolveMode(settings, ...) end

-- Transforms configuration by expanding virtual modifiers in-place.
function M.modifier_resolver.transformConfig(config, ...) end

-- Checks if virtual modifier system is enabled for the given mode.
function M.modifier_resolver.isVirtualEnabled(mode, ...) end

-- Expands virtual modifiers in a modifier array.
function M.modifier_resolver.expandMods(mods, mode, ...) end

-- Rewrites a trigger configuration to expand virtual modifiers.
function M.modifier_resolver.rewriteTrigger(trigger, mode, ...) end

-- Creates a new Notifier that shows brief on-screen alerts via `hs.alert`.
function M.notifier.new(opts, ...) end

-- Shows an informational alert message on screen.
function M.notifier:info(message, ...) end

-- Shows an error alert message on screen, prefixed by `errorPrefix`.
function M.notifier:error(message, ...) end

-- Build a lookup of shortcut signature -> menu item and collision summary.
function M.menu_shortcuts.buildShortcutMap(items, keySignature, buildShortcutFlags, diagnostics, ...) end

-- Find selectable items whose shortcut key or normalized title matches prefix.
function M.menu_shortcuts.itemsMatchingPrefix(items, prefix, opts, ...) end

-- Create a simple typeahead state backed by a match source function.
function M.menu_shortcuts.createTypeaheadState(matchSource, matchOptions, diagnostics, ...) end

-- Reset the typeahead buffer and diagnostics on a state.
function M.menu_shortcuts.resetTypeahead(state, ...) end

-- Update the typeahead buffer and compute matching items.
function M.menu_shortcuts.updateTypeaheadBuffer(state, buffer, ...) end

-- Creates a new MenuHandler for processing menu commands.
function M.command_runner.handlers.menu.new(deps, ...) end

-- Updates the menu manager provider dynamically.
function M.command_runner.handlers.menu:setMenuManager(provider, ...) end

-- Updates the menu context provider dynamically.
function M.command_runner.handlers.menu:setContextProvider(provider, ...) end

-- Returns the list of command types this handler processes.
function M.command_runner.handlers.menu:getHandledTypes() end

-- Executes a menu command by displaying the specified menu.
function M.command_runner.handlers.menu:run(command, context, ...) end

-- Creates a new Activity manager for history and pinned commands.
function M.activity.new(opts, ...) end

-- Applies configuration for history and pinned behavior.
function M.activity:configure(config, ...) end

-- Records a command in history and updates last-run context.
function M.activity:recordCommand(commandId, context, ...) end

-- Returns the last recorded args table for a given command ID (if any).
function M.activity:getLastArgsFor(commandId, ...) end

-- Returns a compact string preview of the last args for the command, e.g. "[k=v, a=b]".
function M.activity:getArgsPreview(commandId, maxPairs, ...) end

-- Returns a list of recent command IDs up to the limit.
function M.activity:getHistory(limit, ...) end

-- Returns the configured history limit.
---@return number
function M.activity:getHistoryLimit() end

-- Clears all recorded command history.
function M.activity:clearHistory() end

-- Returns whether a command ID is pinned.
---@return boolean
function M.activity:isPinned(commandId, ...) end

-- Returns a list of pinned command IDs up to the limit.
function M.activity:getPinned(limit, ...) end

-- Sets the pinned state for a command ID.
function M.activity:setPinned(commandId, shouldPin, ...) end

-- Toggles the pinned state for a command ID.
function M.activity:togglePinned(commandId, ...) end

-- Returns the last executed command ID, if any.
function M.activity:getLastCommand() end

-- Returns the context of the last executed command, if any.
function M.activity:getLastContext() end

-- Returns whether pinning is enabled.
---@return boolean
function M.activity:pinningIsEnabled() end

-- Returns whether history is enabled.
---@return boolean
function M.activity:historyIsEnabled() end

-- Creates a new ItemResolver for building menu item lists.
function M.menu.item_resolver.new(logger, commands, menus, activity, settings, ...) end

-- Replaces the definitions used by the item resolver.
function M.menu.item_resolver:updateDefinitions(commands, menus, settings, activity, ...) end

-- Resolves all menu items including dynamic sections and auto-shortcuts.
function M.menu.item_resolver:resolveMenuItems(menu, menuId, ...) end

-- Creates and starts an event tap to handle keyboard input for an active menu.
function M.menu.input_handler.startInputLoop(manager, menu, context, ...) end

-- Creates a new CommandAdapter for executing commands via command runner.
function M.hotkey.command_adapter.new(opts, ...) end

-- Executes a command by ID through the command runner.
function M.hotkey.command_adapter:run(commandId, context, ...) end

-- Creates a new MenuAdapter for managing menu display operations.
function M.hotkey.menu_adapter.new(opts, ...) end

-- Displays a menu immediately or schedules it for deferred display.
function M.hotkey.menu_adapter:show(menuId, context, ...) end

-- Toggles menu visibility (shows if hidden, hides if visible).
function M.hotkey.menu_adapter:toggle(menuId, context, ...) end

-- Cancels any currently pending/scheduled menu display operation.
function M.hotkey.menu_adapter:cancelPending() end

-- Returns a copy of all recorded menu operations for debugging.
function M.hotkey.menu_adapter:getHistory() end

-- Creates a new KeyTracker for monitoring pressed key state.
function M.hotkey.key_tracker.new(opts, ...) end

-- Generates a signature string from a normalized event.
function M.hotkey.key_tracker:keySignature(event, ...) end

-- Generates a signature string from explicit key and flags.
function M.hotkey.key_tracker:keySignatureFor(key, flags, ...) end

-- Checks if a specific key signature is currently pressed.
---@return boolean
function M.hotkey.key_tracker:isSignatureDown(signature, ...) end

-- Gets the state info for a currently pressed key signature.
function M.hotkey.key_tracker:get(signature, ...) end

-- Creates a deep copy of all currently pressed key states.
function M.hotkey.key_tracker:getSnapshot() end

-- Records a key press event in the tracker state.
function M.hotkey.key_tracker:registerKeyDown(event, ...) end

-- Records a key release event, removing it from tracker state.
function M.hotkey.key_tracker:registerKeyUp(event, ...) end

-- Clears all tracked key states.
function M.hotkey.key_tracker:reset() end

-- Creates a new Notifier for batched error notifications.
function M.hotkey.notifier.new(opts, ...) end

-- Queues an error message for later notification.
function M.hotkey.notifier:error(message, context, ...) end

-- Immediately flushes all queued errors to notifications.
function M.hotkey.notifier:flush() end

-- Schedules a deferred flush after the specified delay.
function M.hotkey.notifier:flushDeferred(delay, ...) end

-- Removes all queued errors without displaying them.
function M.hotkey.notifier:drain() end

-- Gets the number of errors currently queued.
function M.hotkey.notifier:pendingCount() end

-- Gets a copy of the complete operation history.
function M.hotkey.notifier:getHistory() end

-- Cancels any pending deferred flush without flushing.
function M.hotkey.notifier:cancelPending() end

-- Gets diagnostic information about notifier state and statistics.
function M.hotkey.notifier:getDiagnostics() end

-- Creates a new Scheduler for asynchronous task execution with cancellation support.
function M.hotkey.scheduler.new(opts, ...) end

-- Schedules a function to run after a specified delay.
function M.hotkey.scheduler:schedule(fn, delay, ...) end

-- Creates a wrapped function that schedules the original function when called.
function M.hotkey.scheduler:wrap(fn, delay, ...) end

-- Cancels a scheduled task using its handle.
function M.hotkey.scheduler:cancel(handle, ...) end

-- Retrieves a snapshot of scheduler execution metrics.
function M.hotkey.scheduler:getStats() end

-- Creates a new ClipboardAdapter for managing clipboard capture workflows.
function M.hotkey.clipboard_adapter.new(opts, ...) end

-- Captures clipboard selection for a binding and injects it into context.
function M.hotkey.clipboard_adapter:capture(binding, context, ...) end

-- Restores original clipboard state if requested by payload.
function M.hotkey.clipboard_adapter:restore(payload, ...) end

-- Creates a new BindingAdapter for dispatching binding activations.
function M.hotkey.binding_adapter.new(opts, ...) end

-- Attempts to fire a binding by checking context filters and dispatching to appropriate handler.
function M.hotkey.binding_adapter:fire(binding, event, meta, ...) end

-- Creates a new EventNormalizer for converting native keyboard events.
function M.hotkey.event_normalizer.new(opts, ...) end

-- Converts a native Hammerspoon keyboard event into normalized format.
function M.hotkey.event_normalizer:normalize(native, ...) end

-- Creates a new LifecycleAdapter for managing keyboard event tap lifecycle.
function M.hotkey.lifecycle_adapter.new(opts, ...) end

-- Starts the keyboard event tap to begin monitoring keyboard events.
function M.hotkey.lifecycle_adapter:start() end

-- Stops and destroys the keyboard event tap completely.
function M.hotkey.lifecycle_adapter:stop() end

-- Temporarily suspends keyboard event processing without destroying the event tap.
function M.hotkey.lifecycle_adapter:suspend() end

-- Resumes keyboard event processing after suspension.
function M.hotkey.lifecycle_adapter:resume() end

-- Creates a new VirtualFallback for routing unhandled virtual modifier key combinations.
function M.hotkey.virtual_fallback.new(opts, ...) end

-- Clears all registered binding signatures.
function M.hotkey.virtual_fallback:resetSignatures() end

-- Clears all active fallback signatures.
function M.hotkey.virtual_fallback:resetActive() end

-- Registers a binding to prevent fallback conflicts.
function M.hotkey.virtual_fallback:registerBinding(binding, ...) end

-- Generates a fallback signature from key+flags or from an event.
function M.hotkey.virtual_fallback:fallbackSignatureFor(keyOrEvent, flags, ...) end

-- Checks if a signature has an explicit binding registered.
---@return boolean
function M.hotkey.virtual_fallback:hasBindingForSignature(signature, ...) end

-- Checks if a signature is currently active (routed via fallback).
---@return boolean
function M.hotkey.virtual_fallback:isSignatureActive(signature, ...) end

-- Attempts to route an unhandled virtual modifier event via Hyper fallback.
---@return boolean
function M.hotkey.virtual_fallback:maybeSend(event, consumed, vm, ...) end

-- Consumes key release events for fallback-routed keys.
---@return boolean
function M.hotkey.virtual_fallback:consumeRelease(event, ...) end

-- Gets the table of currently active fallback signatures.
function M.hotkey.virtual_fallback:getActiveSignatures() end

-- Apply a single binding definition into a config (commands/menus/hotkeys).
function M.config_binding_adapter.applyBinding(into, binding, index, context, ...) end

-- Compile a binding profile into a normalized configuration and metadata.
function M.config_binding_adapter.compile(profile, ...) end

-- Convenience wrapper returning only the compiled configuration.
function M.config_binding_adapter.fromProfile(profile, ...) end

-- Joins path segments into a single normalized path.
function M.utils.pathJoin(...) end

-- Returns the base installation directory of the launcher.
function M.utils.basePath() end

-- Returns true if the value is a Lua table.
---@return boolean
function M.utils.isTable(value, ...) end

-- Creates a shallow copy of a table (one level deep).
function M.utils.shallowCopy(tbl, ...) end

-- Creates a deep recursive copy of a table, including metatables.
function M.utils.deepCopy(value, seen, ...) end

-- Extracts all keys from a table and returns them sorted.
function M.utils.tableKeys(tbl, ...) end

-- Removes leading and trailing whitespace from a string.
function M.utils.trim(value, ...) end

-- Converts a value to an integer, truncating decimals. Rejects NaN and infinity.
function M.utils.toInteger(value, ...) end

-- Expands tilde (~) home directory shortcuts in a path.
function M.utils.expandPath(path, ...) end

-- Normalizes a path by expanding ~ and converting to absolute.
function M.utils.normalizePath(path, ...) end

-- Cleans JSON-like strings by stripping BOM, ANSI codes, and trailing prompts.
function M.utils.sanitizeJsonPayload(s) end

-- Extracts the first balanced JSON object or array from a string.
function M.utils.extractFirstJson(s) end

-- Prompts user to enter values for each parameter with type validation and coercion.
function M.text_processor_prompter.collect(command, parameters, options, ...) end

-- Prompts user to select a preset from a numbered list with history tracking.
function M.text_processor_prompter.selectPreset(command, presets, options, ...) end

-- Prompts for single or multi-field input with flexible composition options.
function M.text_processor_prompter.promptForInput(command, promptSpec, ...) end

-- Generates the hs.settings key for storing preset history for this command.
function M.text_processor_prompter.getPresetHistoryKey(command, ...) end

-- Retrieves the last-used preset identifier from hs.settings.
function M.text_processor_prompter.getLastPresetIdentifier(commandOrKey, ...) end

-- Stores the preset identifier in hs.settings for this command.
function M.text_processor_prompter.rememberPreset(command, identifier, ...) end

-- Clears the preset history for this command from hs.settings.
function M.text_processor_prompter.clearPresetHistory(commandOrKey, ...) end

-- Returns array of stored preset identifiers for this command.
function M.text_processor_prompter.listPresetHistory(commandOrKey, ...) end

-- Manually stores the given application for later restoration.
function M.text_processor_prompter.rememberApplication(app, ...) end

-- Creates a new CommandRunner that dispatches and executes commands.
function M.command_runner.new(logger, notifier, activity, opts, ...) end

-- Updates the internal command definitions.
function M.command_runner:update(commands, ...) end

-- Applies global settings, including text-processor defaults (timeout/retry policy).
function M.command_runner:configure(settings, ...) end

-- Sets or updates the notifier instance.
function M.command_runner:setNotifier(notifier, ...) end

-- Sets or updates the activity manager instance.
function M.command_runner:setActivity(activity, ...) end

-- Returns the text processor bridge instance.
function M.command_runner:getTextProcessor() end

-- Sets or updates the menu manager instance.
function M.command_runner:setMenuManager(menuManager, ...) end

-- Returns the current MenuManager instance.
function M.command_runner:getMenuManager() end

-- Returns the current LayoutManager instance.
function M.command_runner:getLayoutManager() end

-- Retrieves a command definition by ID.
function M.command_runner:get(commandId, ...) end

-- Toggles (or sets) the pinned state for a command and notifies the user.
function M.command_runner:togglePinTarget(commandId, context, opts, ...) end

-- Looks up a command by ID and executes it.
function M.command_runner:runById(commandId, context, ...) end

-- Executes a command: captures selection (if requested), dispatches to handlers, records activity, and restores clipboard.
function M.command_runner:run(command, context, ...) end

-- Resets the frontmost action state in the window handler.
function M.command_runner:resetFrontmostActionState() end

-- Transforms text processor registry into hsLauncher command and menu structures.
function M.text_processor_menu_builder.build(catalog, opts, ...) end

-- Resets any stuck modifier keys by simulating key release events.
function M.keyboard_state_manager.resetModifiers(logger, forceReset, ...) end

-- Safely executes a keystroke with automatic modifier state cleanup.
function M.keyboard_state_manager.safeKeyStroke(mods, key, delay, logger, ...) end

-- Gets the current modifier state for diagnostics.
function M.keyboard_state_manager.getModifierState() end

-- Forces a complete keyboard state reset with event tap cycling.
function M.keyboard_state_manager.forceReset(logger, ...) end

-- Updates internal modifier state tracking.
function M.keyboard_state_manager.updateModifierState(key, isDown, ...) end

-- Initializes the keyboard state manager.
function M.keyboard_state_manager.init() end

-- Validate a merged launcher configuration.
function M.config_validator.validate(config, ...) end

