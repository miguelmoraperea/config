-- Hammerspoon configuration for Alacritty
-- This configuration launches applications and manages their windows

-- Function to resize window to almost full screen
local function resizeWindow(win)
    if win then
        local screen = win:screen()
        local screenFrame = screen:frame()

        -- Calculate new frame (95% of screen size)
        local newFrame = {
            x = screenFrame.x + (screenFrame.w * 0.025),
            y = screenFrame.y + (screenFrame.h * 0.025),
            w = screenFrame.w * 0.95,
            h = screenFrame.h * 0.95
        }

        win:setFrame(newFrame)
    end
end

-- Generic function to launch and manage applications
local function launchApp(appName)
    -- Launch the application
    local app = hs.application.open(appName)

    if app then
        -- Wait a bit for the window to appear
        hs.timer.doAfter(0.2, function()
            local win = app:mainWindow()
            if win then
                -- Resize the window
                resizeWindow(win)

                -- Focus the window
                win:focus()
            end
        end)
    end
end

-- Set up window filters and hotkeys for each application
local apps = {
    { name = "Alacritty", key = "1" },
    { name = "Google Chrome", key = "2" },
    { name = "Slack", key = "3" },
    { name = "Cursor", key = "4" },
    { name = "IntelliJ IDEA", key = "5" },
    { name = "Google Calendar", key = "6" },
    { name = "Gmail", key = "7" },
    { name = "Google Meet", key = "8" },
}

-- Open Google Calendar if it's not running
if not hs.application.get("Google Calendar") then
    hs.application.open("Google Calendar")
end

-- Create a watcher to reopen Google Calendar when it's terminated
local calendarWatcher = hs.application.watcher.new(function(appName, eventType, app)
    if appName == "Google Calendar" and eventType == hs.application.watcher.terminated then
        hs.application.open("Google Calendar")
    end
end)
calendarWatcher:start()

-- Create window filters and hotkeys for each application
for _, app in ipairs(apps) do
    -- Create window filter
    local watcher = hs.window.filter.new(app.name)
    watcher:subscribe(hs.window.filter.windowsChanged, function(win, appName, event)
        -- Only resize when a new window is created
        if event == hs.window.filter.windowsCreated then
            resizeWindow(win)
        end
    end)

    -- Bind hotkey
    hs.hotkey.bind({"alt"}, app.key, function()
        launchApp(app.name)
    end)
end

-- Function to reposition all windows for configured apps
local function repositionAllWindows()
    for _, app in ipairs(apps) do
        local application = hs.application.get(app.name)
        if application then
            local windows = application:allWindows()
            for _, win in ipairs(windows) do
                resizeWindow(win)
            end
        end
    end
end

-- Add hotkey to reposition all windows
hs.hotkey.bind({"alt", "shift"}, "R", function()
    repositionAllWindows()
    hs.alert.show("All windows repositioned")
end)

-- Reload Hammerspoon configuration
hs.hotkey.bind({"alt"}, "R", function()
    hs.reload()
end)

-- Alert when the configuration is loaded
hs.alert.show("Hammerspoon config loaded")

-- Add hotkey to close active window and focus next window
hs.hotkey.bind({"alt"}, "C", function()
    local win = hs.window.focusedWindow()
    if win then
        -- Get all windows on the current screen
        local screen = win:screen()
        local windows = hs.window.orderedWindows()
        local currentIndex = nil

        -- Find the current window's index
        for i, w in ipairs(windows) do
            if w:id() == win:id() then
                currentIndex = i
                break
            end
        end

        -- Close current window
        win:close()

        -- Focus next window if available
        if currentIndex and windows[currentIndex + 1] then
            windows[currentIndex + 1]:focus()
        end
    end
end)

-- Add hotkey to open Raycast emoji search
hs.hotkey.bind({"alt"}, "E", function()
    -- Use Raycast's URL scheme to open emoji search
    hs.urlevent.openURL("raycast://search-emoji")
end)
