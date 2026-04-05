# CopyURL — YouTube Thumbnail URL Copier

Copy any YouTube video URL just by hovering over its thumbnail and pressing **Alt+C** — even when the browser isn't focused.

## Why This Exists

I paste YouTube URLs into Gemini to get video summaries. Opening every video just to grab the URL was tedious. I wanted to hover over a thumbnail, press a shortcut, and paste the URL straight into Gemini — without switching windows manually.

## How It Works

The project has two parts that work together:

### 1. Browser Extension (Brave/Chrome)

A content script (`content.js`) runs on every YouTube page. It tracks which video thumbnail your mouse is hovering over. When you press **Alt+C** while hovering, it copies the clean URL to your clipboard and shows a small "Copied!" toast.

The copied URL is always clean: `https://www.youtube.com/watch?v=VIDEO_ID` — no tracking parameters, no clutter. YouTube Shorts are normalized to the same format.

### 2. AutoHotkey Script — Global Copy (`copy.ahk`)

The browser extension only receives keyboard events when the browser is focused. If you're in another app (e.g., Gemini, VS Code) with your mouse hovering over a YouTube thumbnail in Brave, Alt+C wouldn't reach the extension.

`copy.ahk` solves this. It intercepts **Alt+C globally** at the system level, then:

1. Finds the actual Brave browser window (skipping background renderer processes)
2. Activates/focuses Brave
3. Nudges the mouse by a few pixels to trigger hover detection in the extension
4. Sends Alt+C to the now-focused browser
5. The extension picks it up and copies the URL

This all happens in under 500ms — it feels instant.

### 3. AutoHotkey Script — Global Paste (`paste.ahk`)

A simple remap: **Alt+V** sends **Ctrl+V**. This lets you paste the copied URL with Alt+V from anywhere, matching the Alt+C copy shortcut.

## Workflow

1. Have YouTube open in Brave
2. Work in any other app (Gemini, VS Code, etc.)
3. Hover your mouse over a YouTube thumbnail in Brave
4. Press **Alt+C** — Brave briefly activates, copies the URL, shows "Copied!"
5. Press **Alt+V** (or Ctrl+V) to paste the clean URL wherever you need it

## Installation

### Browser Extension

1. Clone or download this repository
2. Open Brave: go to `brave://extensions` (or `chrome://extensions` for Chrome)
3. Enable **Developer mode** (toggle in the top-right corner)
4. Click **Load unpacked** and select this folder
5. The extension is now active on all YouTube pages

### AutoHotkey Scripts (Windows)

1. Install [AutoHotkey v2](https://www.autohotkey.com/) if you don't have it
2. Double-click `copy.ahk` to run the global copy hotkey
3. Double-click `paste.ahk` to run the global paste hotkey
4. (Optional) Add both `.ahk` files to your Startup folder so they run automatically:
   - Press `Win+R`, type `shell:startup`, press Enter
   - Create shortcuts to `copy.ahk` and `paste.ahk` in that folder

## Files

| File | Description |
|------|-------------|
| `manifest.json` | Extension config (Manifest V3) |
| `content.js` | Hover detection, Alt+C handler, clipboard copy, toast UI |
| `copy.ahk` | AHK v2 — global Alt+C: focus Brave, nudge mouse, forward keystroke |
| `paste.ahk` | AHK v1 — global Alt+V → Ctrl+V paste remap |
| `icon*.png` | Extension icons |

## Requirements

- **Browser:** Brave or Chrome
- **OS:** Windows (for AutoHotkey scripts)
- **AutoHotkey v2** (for `copy.ahk`)
