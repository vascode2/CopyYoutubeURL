-- CopyURL Mac workflow (Hammerspoon)
-- Hotkey: Option+Z
-- Flow:
-- 1) Activate YouTube window (Brave or Chrome)
-- 2) Send Option+X so content.js copies hovered URL
-- 3) Activate Gemini window
-- 4) Paste "summarize this video: <url>" and press Enter
-- 5) Restore clipboard to plain URL

local hotkey = {"alt"}
local key = "z"

local youtubeApps = { "Brave Browser", "Google Chrome" }
local geminiTitleNeedle = "gemini"
local pastePrefix = "summarize this video: "

local function notify(text)
  hs.alert.show(text, 2)
end

local function lower(s)
  if not s then return "" end
  return string.lower(s)
end

local function findWindowByTitleNeedle(needle)
  local needleLower = lower(needle)
  for _, win in ipairs(hs.window.orderedWindows()) do
    local title = lower(win:title())
    if string.find(title, needleLower, 1, true) then
      return win
    end
  end
  return nil
end

local function findYoutubeWindow()
  for _, appName in ipairs(youtubeApps) do
    local app = hs.appfinder.appFromName(appName)
    if app then
      local wins = app:allWindows()
      for _, win in ipairs(wins) do
        local title = lower(win:title())
        local looksLikeYoutube = string.find(title, "youtube", 1, true)
        if looksLikeYoutube then
          return win
        end
      end
      local front = app:mainWindow() or app:focusedWindow()
      if front then
        return front
      end
    end
  end
  return nil
end

local function sleep(seconds)
  hs.timer.usleep(math.floor(seconds * 1000000))
end

local function runFlow()
  local originalClipboard = hs.pasteboard.getContents() or ""

  local youtubeWin = findYoutubeWindow()
  if not youtubeWin then
    notify("No YouTube window found in Brave or Chrome")
    return
  end

  youtubeWin:focus()
  sleep(0.15)

  -- Remember what was on the clipboard before so we can detect a real change.
  local clipBefore = hs.pasteboard.getContents() or ""

  -- Triggers content.js in-page copy action (Option+X).
  hs.eventtap.keyStroke({ "alt" }, "x", 0)

  -- Wait up to 2 s for the clipboard to actually change.
  local copiedUrl = ""
  local deadline = hs.timer.secondsSinceEpoch() + 2
  while hs.timer.secondsSinceEpoch() < deadline do
    sleep(0.08)
    local cur = hs.pasteboard.getContents() or ""
    if cur ~= clipBefore and cur:find("youtube%.com") then
      copiedUrl = cur
      break
    end
  end

  if copiedUrl == "" then
    notify("URL copy failed. Hover a thumbnail, then try again.")
    return
  end

  local geminiWin = findWindowByTitleNeedle(geminiTitleNeedle)
  if not geminiWin then
    notify("Gemini window not found")
    return
  end

  geminiWin:focus()
  sleep(0.3)

  -- Same approach as Windows copy.ahk: save cursor, click composer, restore cursor.
  local origPos = hs.mouse.absolutePosition()
  local frame = geminiWin:frame()
  local clickPt = hs.geometry.point(frame.x + frame.w * 0.5, frame.y + frame.h - 60)
  hs.eventtap.leftClick(clickPt)
  sleep(0.5)
  hs.mouse.absolutePosition(origPos)

  -- Use AppleScript via System Events for reliable keystrokes.
  -- hs.eventtap.keyStroke with delay 0 fires too fast and Chrome often ignores it.
  local payload = pastePrefix .. copiedUrl
  hs.pasteboard.setContents(payload)

  local script = [[
    tell application "System Events"
      keystroke "a" using command down
      delay 0.1
      keystroke "v" using command down
      delay 0.4
      key code 36
    end tell
  ]]
  hs.osascript.applescript(script)
  sleep(0.3)

  -- Restore clipboard to plain URL (same behavior as Windows flow).
  hs.pasteboard.setContents(copiedUrl)
  notify("Sent URL to Gemini")

  -- Optional: restore original clipboard instead.
  -- hs.pasteboard.setContents(originalClipboard)
end

hs.hotkey.bind(hotkey, key, runFlow)
notify("Option+Z ready")
