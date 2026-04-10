# CopyURL — YouTube thumbnail → clipboard (and Gemini on Windows)

Hover a YouTube thumbnail and copy a clean `watch?v=` URL. On **Windows**, [AutoHotkey v2](https://www.autohotkey.com/) runs **`copy.ahk`** so **Alt+X** / **Alt+C** / **Alt+Z** work even when Brave is not focused. **Alt+C** copies from Brave, switches to the **Gemini** app in **Google Chrome**, focuses the composer using posted window messages (your physical mouse is not moved), pastes a short prompt plus the URL, presses Enter, then restores the clipboard to the plain link.

| Hotkey | Action |
|--------|--------|
| **Alt+X** | Copy the hovered video URL (Brave must be running; extension loaded) |
| **Alt+C** | Copy from Brave → Gemini (Chrome PWA) → paste and submit |
| **Alt+Z** | Send Ctrl+V |

**Requirements**

- **Brave** with this extension, for YouTube and **Alt+X** / **Alt+C** copy step.
- **Windows** + **AutoHotkey v2** + **`copy.ahk`** for global hotkeys.
- **Google Chrome** with **Gemini installed as an app** (window title contains `Gemini`) for **Alt+C** only.
- On macOS/Linux you can still load the extension and use **Alt+X** inside a focused YouTube tab (no global hotkeys).

---

## 1. Load the extension in Brave or Chrome

1. Download or clone this repository.
2. Open **Brave** (recommended for YouTube) or **Google Chrome**.
3. Go to **`brave://extensions`** or **`chrome://extensions`**.
4. Turn **Developer mode** on (top right).
5. Click **Load unpacked**.
6. Choose this project folder (the one that contains `manifest.json`).
7. Open [YouTube](https://www.youtube.com) in that browser and confirm the extension is allowed on the site if prompted.

The content script runs on YouTube pages only. **Alt+C** in AutoHotkey still expects **Brave** for the copy step (`brave.exe`).

---

## 2. Install AutoHotkey v2 and run `copy.ahk`

1. Download and install **AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com/).
2. In File Explorer, go to this repo folder and **double-click `copy.ahk`**.
3. Confirm a green **H** icon appears in the system tray — the script is running.
4. **Optional — start with Windows:** Press **Win+R**, type **`shell:startup`**, press Enter, then put a **shortcut** to `copy.ahk` in the folder that opens.

Reload the script after editing `copy.ahk` (right‑click the tray icon → **Reload Script**).

---

## 3. Install Gemini as a Chrome app (for Alt+C)

**Alt+C** looks for a normal Chrome top-level window whose title includes **`Gemini`**. A regular Gemini **tab** in Chrome may not match the same way as an installed app; installing the PWA is the reliable approach.

1. Open **Google Chrome** (not Brave for this step).
2. Go to [gemini.google.com](https://gemini.google.com) and sign in.
3. Install the app:
   - If Chrome shows an **install** icon in the address bar, use it; **or**
   - Open the **⋮** menu → **Save and share** → **Install Gemini** (labels vary slightly by Chrome version).
4. Open Gemini from the installed app / shortcut so you get a **standalone window**. Keep that window available when you use **Alt+C**.

---

## Usage

1. Leave **YouTube** open in **Brave** (visible enough that your pointer can sit over a thumbnail).
2. Hover the thumbnail you want.
3. Press **Alt+X** to copy only, or **Alt+C** to copy and send into Gemini as described above.
4. Use **Alt+Z** anywhere for Ctrl+V if you want a spare paste hotkey.

If more than one Gemini window is open, AutoHotkey uses the first match it finds — one Gemini window is simplest.
