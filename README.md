# CopyURL — YouTube Thumbnail URL Copier

Copy any YouTube video URL just by hovering over its thumbnail — even when the browser isn't focused. Three shortcuts for different workflows:

- **Alt+X** — Copy URL only
- **Alt+C** — Copy URL, switch back to previous window, paste, and press Enter
- **Alt+Z** — Paste (Ctrl+V)

## Why This Exists

I paste YouTube URLs into Gemini to get video summaries. Opening every video just to grab the URL was tedious. I wanted to hover over a thumbnail, press a shortcut, and paste the URL straight into Gemini — without switching windows manually.

## How It Works

The project has two parts that work together:

### 1. Browser Extension (Brave/Chrome)

A content script (`content.js`) runs on every YouTube page. It tracks which video thumbnail your mouse is hovering over. When you press **Alt+X** while hovering, it copies the clean URL to your clipboard and shows a small "Copied!" toast.

The copied URL is always clean: `https://www.youtube.com/watch?v=VIDEO_ID` — no tracking parameters, no clutter. YouTube Shorts are normalized to the same format.

### 2. AutoHotkey Script — Global Copy (`copy.ahk`)

The browser extension only receives keyboard events when the browser is focused. If you're in another app (e.g., Gemini, VS Code) with your mouse hovering over a YouTube thumbnail in Brave, the shortcut wouldn't reach the extension.

`copy.ahk` provides three global hotkeys:

**Alt+X** (copy only):
1. Finds the actual Brave browser window (skipping background renderer processes)
2. Activates/focuses Brave
3. Nudges the mouse by a few pixels to trigger hover detection in the extension
4. Sends Alt+X to the now-focused browser
5. The extension picks it up and copies the URL

**Alt+C** (copy + switch back + paste + enter):
1. Does everything Alt+X does, then:
2. Alt+Tabs back to the previously focused window
3. Pastes the URL (Ctrl+V)
4. Presses Enter

**Alt+Z** (paste): Sends Ctrl+V — a convenient paste shortcut from anywhere.

This all happens in under a second — it feels instant.

## Workflow

1. Have YouTube open in Brave
2. Work in any other app (Gemini, VS Code, etc.)
3. Hover your mouse over a YouTube thumbnail in Brave
4. Press **Alt+C** — Brave briefly activates, copies the URL, switches back, pastes, and hits Enter
   - Or press **Alt+X** to just copy the URL without pasting
5. Press **Alt+Z** (or Ctrl+V) to paste anytime

## Installation

### Browser Extension

1. Clone or download this repository
2. Open Brave: go to `brave://extensions` (or `chrome://extensions` for Chrome)
3. Enable **Developer mode** (toggle in the top-right corner)
4. Click **Load unpacked** and select this folder
5. The extension is now active on all YouTube pages

### AutoHotkey Scripts (Windows)

1. Install [AutoHotkey v2](https://www.autohotkey.com/) if you don't have it
2. Double-click `copy.ahk` to run the global hotkeys (Alt+X, Alt+C, Alt+Z)
3. **Auto-start on boot:** Copy `copy.ahk` (or a shortcut to it) into:
   ```
   C:\Users\<YourUsername>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
   ```
   Or press `Win+R`, type `shell:startup`, press Enter, and place it there. The script will now launch automatically when Windows starts.

## Files

| File | Description |
|------|-------------|
| `manifest.json` | Extension config (Manifest V3) |
| `content.js` | Hover detection, Alt+X handler, clipboard copy, toast UI |
| `copy.ahk` | AHK v2 — global hotkeys: Alt+X (copy), Alt+C (copy+paste+enter), Alt+Z (paste) |
| `paste.ahk` | AHK v1 — legacy Alt+Z → Ctrl+V paste remap (functionality now in copy.ahk) |
| `icon*.png` | Extension icons |

## Requirements

- **Browser:** Brave or Chrome
- **OS:** Windows (for AutoHotkey scripts)
- **AutoHotkey v2** (for `copy.ahk`)
