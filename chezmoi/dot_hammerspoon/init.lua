--- @diagnostic disable-next-line: undefined-global
local hs = hs

pcall(hs.console.clearConsole)

SpoonTable = SpoonTable or {}

local hsLauncherRoot = os.getenv("HOME") .. "/Scripts/Metascripts/hsLauncher"
local hsStringEvalRoot = os.getenv("HOME") .. "/Scripts/Metascripts/hsStringEval"

-- Add project roots to package.path for require()
package.path = package.path .. ";" .. hsLauncherRoot .. "/?.lua"
package.path = package.path .. ";" .. hsLauncherRoot .. "/?/init.lua"
package.path = package.path .. ";" .. hsStringEvalRoot .. "/?.lua"
package.path = package.path .. ";" .. hsStringEvalRoot .. "/?/init.lua"

-- Initialize Hammerspoon modules
require("hs.ipc")         -- Enable IPC support
require("hs.application") -- Enable application support
require("hs.urlevent")    -- Enable URL event support
pcall(function()
    if hs.allowAppleScript then
        hs.allowAppleScript(true)
    end
end)

-- Initialize EmmyLua for LSP support
local emmyLua = hs.loadSpoon("EmmyLua")
if emmyLua then
    SpoonTable.EmmyLua = emmyLua
    if emmyLua.start then
        emmyLua:start()
    elseif emmyLua.init then
        emmyLua:init()
    end
end

-- Initialize ClipboardFormatter (hsStringEval)
local ok, formatter = pcall(require, "src.init")
if ok and formatter then
    formatter.spoonPath = hsStringEvalRoot .. "/src"
    local instance = formatter:init({
        config = {
            loggerLevel = "debug",
            hotkeys = { installHelpers = true },
            selection = {
                copySelection = true,
                copyDelayMs = 500, -- Generous delay to ensure copy completes
                pasteDelayMs = 100,
            }
        }
    })
    if instance then
        SpoonTable.ClipboardFormatter = instance
        if instance.installHotkeyHelpers then
            instance:installHotkeyHelpers()
        end
    end
end

-- Fallback stubs if hsStringEval formatter didn't load
if not FormatClip then
    FormatClip = function()
        hs.alert.show("ClipboardFormatter unavailable")
        return false
    end
end

if not FormatSelected then
    FormatSelected = function()
        hs.alert.show("ClipboardFormatter unavailable")
        return false
    end
end

FormatSelection = FormatSelection or FormatSelected

if not FormatClipSeed then
    FormatClipSeed = function()
        hs.alert.show("ClipboardFormatter unavailable")
        return false
    end
end

-- Initialize hsLauncher
dofile(hsLauncherRoot .. "/init.lua")

-- Initialize Karabiner Layer Indicator URL handler
-- This registers the hammerspoon://layer_indicator URL scheme
-- for Karabiner integration without needing the hs CLI helper
pcall(function()
    local indicator_path = os.getenv("HOME") .. "/.hammerspoon/karabiner_layer_indicator_url.lua"
    if hs.fs.attributes(indicator_path) then
        dofile(indicator_path)
        hs.printf("[LayerIndicator] Loaded from: %s", indicator_path)
    else
        hs.printf("[LayerIndicator ERROR] Script not found at: %s", indicator_path)
    end
end)

-- Confirm Hammerspoon has loaded
hs.alert.show("Hammerspoon loaded")

-- Mitigation: noisy hs.ipc error when client disconnects early.w
-- Sometimes the `hs` CLI (or other IPC clients) disconnects before
-- Hammerspoon replies, leading to "ipc port is no longer valid (early)".
-- Wrap the default handler to suppress that specific error.
do
    local okIpc, ipc = pcall(require, "hs.ipc")
    if okIpc and ipc and type(ipc.__defaultHandler) == "function" then
        local rawHandler = ipc.__defaultHandler
        ipc.__defaultHandler = function(...)
            local ok, err = pcall(rawHandler, ...)
            if not ok then
                local msg = tostring(err or "")
                if msg:match("ipc port is no longer valid") then
                    -- Suppress benign early-disconnect noise
                    return
                end
                -- Downgrade unexpected handler errors to info to avoid console spam
                local logger = hs and hs.logger and hs.logger.new("hs.ipc")
                if logger and logger.i then
                    logger:i("Suppressed hs.ipc handler error: %s", msg)
                end
            end
        end
    end
end
