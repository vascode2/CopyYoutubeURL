# CopyURL — YouTube Thumbnail URL Copier

**Platform:** The browser extension works wherever you run Brave or Chrome. **Global hotkeys (Alt+X / Alt+C / Alt+Z)** are **Windows-only** — they require [AutoHotkey v2](https://www.autohotkey.com/) and `copy.ahk`.

Copy any YouTube video URL just by hovering over its thumbnail — even when the browser isn't focused (on Windows, with the script running). Three shortcuts for different workflows:

- **Alt+X** — Copy URL only
- **Alt+C** — Copy URL, focus the Google Gemini Chrome app window, click the composer, paste a short **summarize** line plus the URL (configurable), press Enter, then restore the clipboard to the plain URL
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

**Alt+C** (copy + Gemini + paste + enter):
1. Does everything Alt+X does, then:
2. Saves the plain URL from the clipboard. If **`kGeminiPastePrefix`** is non-empty (default: `Summarize this YouTube video:` + newline), replaces the clipboard with **prefix + URL** for the paste. Use `kGeminiPastePrefix := ""` for URL only, or change the string (e.g. another language).
3. Finds a visible **Google Chrome** window whose title contains **Gemini** (the installed Gemini PWA). If it cannot activate Gemini, the clipboard is restored to the plain URL.
4. Activates it, clicks the composer area (fractions of the window client size — see `kGeminiInputXFrac` / `kGeminiInputYFrac` at the top of `copy.ahk`; adjust if the click lands on **Tools** / **+** instead of the text field)
5. Pastes (Ctrl+V), presses **Enter**, then restores the clipboard to the **plain URL** (so **Alt+Z** still pastes just the link)

You can rely on this prefix instead of a permanent “always summarize” custom instruction in the Gemini chat, or use both.

If more than one Gemini window is open, the first match AutoHotkey finds is used — keep a single Gemini window open or results may be unpredictable.

**Alt+Z** (paste): Sends Ctrl+V — a convenient paste shortcut from anywhere.

This all happens in under a second — it feels instant.

## Workflow

1. Have YouTube open in Brave
2. Work in any other app (Gemini, VS Code, etc.)
3. Hover your mouse over a YouTube thumbnail in Brave
4. Press **Alt+C** — Brave briefly activates and copies the URL, then Chrome’s Gemini window is focused, the composer is clicked, your prompt (prefix + URL) is pasted, and Enter is sent
   - Or press **Alt+X** to just copy the URL without pasting
5. Press **Alt+Z** (or Ctrl+V) to paste anytime

## Setup (Windows)

Do this on a **Windows** PC. macOS/Linux can use the extension with the browser focused (**Alt+X** in-page); **Alt+C** / global **Alt+X** need AutoHotkey and are not supported there.

### 1. YouTube extension (Brave)

1. Clone or download this repository.
2. Open **Brave** and go to `brave://extensions`.
3. Turn on **Developer mode** (top right).
4. Click **Load unpacked** and choose this project folder.
5. Keep YouTube open in Brave for hover + copy.

### 2. Gemini as a Chrome app (for Alt+C)

**Alt+C** looks for a normal **Google Chrome** window whose title contains **`Gemini`** (not a Brave tab).

1. Open **Google Chrome** (install from [google.com/chrome](https://www.google.com/chrome/) if needed).
2. Go to [gemini.google.com](https://gemini.google.com) and sign in.
3. Install the app: use the **install** icon in the address bar if Chrome offers it, or the **⋮** menu → **Save and share** → **Install Gemini** (wording varies slightly by Chrome version). Pin the window if you like.
4. Leave that **installed Gemini** window available while you use **Alt+C**. The window title should include `Gemini` (e.g. `Gemini - … - Google Gemini`).

### 3. AutoHotkey v2 and `copy.ahk`

1. Install [AutoHotkey v2](https://www.autohotkey.com/).
2. Double-click **`copy.ahk`** to start the script (system tray icon). You should get global **Alt+X**, **Alt+C**, and **Alt+Z**.
3. **Run at sign-in:** copy **`copy.ahk`** (or a shortcut) into your Startup folder:
   ```
   C:\Users\<YourUsername>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
   ```
   Or press **Win+R**, type `shell:startup`, **Enter**, and place the file there.

### Configuring `copy.ahk`

At the top of **`copy.ahk`**:

- **`kGeminiInputXFrac` / `kGeminiInputYFrac`** — click position in the Gemini window (tune if the click misses the “Ask Gemini” box).
- **`kGeminiPastePrefix`** — text **before** the URL on **Alt+C**. Example default: `Summarize this YouTube video:` then a new line, then the URL. Use `kGeminiPastePrefix := ""` to paste **only** the URL.

The script saves the plain URL, optionally replaces the clipboard with **`kGeminiPastePrefix . clipUrl`**, then looks for Gemini. If no window is found or **`WinWaitActive`** fails, it restores **`A_Clipboard`** to the plain URL before returning. After a successful **Enter**, it restores the clipboard the same way.

## Files

| File | Description |
|------|-------------|
| `manifest.json` | Extension config (Manifest V3) |
| `content.js` | Hover detection, Alt+X handler, clipboard copy, toast UI |
| `copy.ahk` | AHK v2 — global hotkeys; Alt+C focuses Gemini, optional `kGeminiPastePrefix`, paste + Enter |
| `icon*.png` | Extension icons |

## Requirements

- **OS:** **Windows** for global hotkeys (`copy.ahk`). The unpacked extension alone works on other OSes if the browser tab is focused.
- **Browsers:** **Brave** (recommended) for YouTube + extension; **Google Chrome** with **Gemini installed as an app** for **Alt+C** (window title must contain `Gemini`).
- **AutoHotkey v2** (Windows) for `copy.ahk`.
