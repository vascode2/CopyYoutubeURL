# CopyURL — YouTube thumbnail → Gemini (Windows)

## Workflow

1. Open **YouTube** in **Google Chrome** (or **Brave**) with this extension enabled.
2. Point at the **thumbnail** of the video you care about — the extension remembers which video that is.
3. Press **Alt+Z** (with **AutoHotkey v2** and **`copy.ahk`** on Windows). The script briefly brings the YouTube window forward, copies that video’s **YouTube URL**, switches to the **Gemini** app, pastes a short “summarize” line plus the link, and sends it. Afterward the **clipboard is set back to the plain URL**. Your **physical mouse is not moved** (posted window messages to Chromium).
4. **Gemini** replies with a **summary** (and you can follow up in the same chat).

**Why this works:** **Gemini** can use a **YouTube URL** as real video context for summaries and Q&A. Many other assistants only treat links as plain text.

**Implementation note:** `copy.ahk` sends **Alt+X** *inside* the YouTube tab so the extension can copy the URL; you do not use **Alt+X** as a separate global shortcut anymore.

| Hotkey | Action |
|--------|--------|
| **Alt+Z** | Copy hovered URL from YouTube (Brave) → Gemini (Chrome app) → paste prompt + URL → Enter |

---

## Requirements

- **Brave** (default in `copy.ahk`) or **Google Chrome** as an alternative for YouTube and this extension.
- **Windows** + **[AutoHotkey v2](https://www.autohotkey.com/)** + **`copy.ahk`** for global **Alt+Z**.
- **Google Chrome** with **Gemini installed as an app** (window title contains `Gemini`).

**Script notes:** `copy.ahk` activates **Brave** (`brave.exe`) for the YouTube step; switch to **`chrome.exe`** in `FindBraveWindow` if YouTube lives only in Chrome. Edit **`kGeminiPastePrefix`** at the top of `copy.ahk` to change or clear the text before the URL (`""` = URL only).

This flow is **Windows-only**. There is no global hotkey on **macOS** / **Linux** in this repo.

---

## 1. Load the extension in Google Chrome

1. Download or clone this repository.
2. Open **Google Chrome** (or **Brave**).
3. Go to **`chrome://extensions`** (Brave: **`brave://extensions`**).
4. Turn **Developer mode** on (top right).
5. Click **Load unpacked** and select this folder (`manifest.json` lives here).
6. Open [YouTube](https://www.youtube.com) and allow the extension if prompted.

---

## 2. Install AutoHotkey v2 and run `copy.ahk`

1. Install **AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com/).
2. Double-click **`copy.ahk`** in this repo.
3. Confirm the **H** tray icon appears.
4. **Optional — run at sign-in:** **Win+R** → **`shell:startup`** → Enter → shortcut to `copy.ahk`.

Reload the script after editing `copy.ahk` (tray → **Reload Script**).

---

## 3. Install Gemini as a Chrome app

**Alt+Z** expects a Chrome window whose title includes **`Gemini`**. The installed **PWA** is most reliable.

1. Open **Google Chrome**.
2. Go to [gemini.google.com](https://gemini.google.com) and sign in.
3. Install via the address bar **install** icon, or **⋮** → **Save and share** → **Install Gemini** (labels vary).
4. Keep that app window available when you use **Alt+Z**.

---

## Usage

1. **YouTube** open in **Chrome** or **Brave**; pointer over a thumbnail.
2. **Alt+Z** — full flow above.

If several Gemini windows are open, AutoHotkey uses the first match; one window is simplest.
