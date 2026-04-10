# CopyURL — YouTube thumbnail → clipboard (and Gemini on Windows)

## Workflow

1. Open **YouTube** in **Google Chrome** (or **Brave**) with this extension enabled.
2. Point at the **thumbnail** of the video you care about — the extension remembers which video that is.
3. Press **Alt+C** (with **AutoHotkey** and `copy.ahk` running on Windows). The script briefly brings the YouTube window forward, copies that video’s **YouTube URL** into the clipboard, switches to the **Gemini** app, drops your message into the chat (a short “summarize” line plus the link), and sends it.
4. **Gemini** replies with a **summary** (and can go deeper if you follow up in the same chat).

**Why this works:** **Gemini** can use a **YouTube URL** as real context — it can lean on the video itself for summaries and Q&A. Many other assistants only see the link as text and cannot watch or ground answers on the actual video the same way, so this shortcut is built around **Gemini** + link paste.

On **Windows**, **Alt+X** / **Alt+C** / **Alt+Z** are global: you do not have to click the YouTube window first. **Alt+C** uses posted window messages to focus Gemini’s composer **without moving your physical mouse**.

| Hotkey | Action |
|--------|--------|
| **Alt+X** | Copy the hovered video’s YouTube URL only |
| **Alt+C** | Copy URL → Gemini app → paste prompt + URL → Enter |
| **Alt+Z** | Send Ctrl+V |

---

## Requirements

- **Brave** — primary choice called out here; **Google Chrome** is a **supported alternative** for installing the extension and using YouTube the same way.
- **Windows** + **[AutoHotkey v2](https://www.autohotkey.com/)** + **`copy.ahk`** for global **Alt+X** / **Alt+C** / **Alt+Z**.
- **Google Chrome** with **Gemini installed as an app** (window title contains `Gemini`) for the **Alt+C** step that opens Gemini.

**Script note:** `copy.ahk` looks for **Brave** (`brave.exe`) when it activates the browser for the copy. If YouTube runs only in **Chrome**, change `FindBraveWindow` in `copy.ahk` to match `chrome.exe` (same window class checks as today).

On **macOS** / **Linux** you can still load the extension and press **Alt+X** on a **focused** YouTube tab; global hotkeys and **Alt+C** are **not** available there.

---

## 1. Load the extension in Google Chrome

1. Download or clone this repository.
2. Open **Google Chrome** (or **Brave** if you use it for YouTube).
3. Go to **`chrome://extensions`** (Brave: **`brave://extensions`**).
4. Turn **Developer mode** on (top right).
5. Click **Load unpacked** and select this folder (the one that contains `manifest.json`).
6. Open [YouTube](https://www.youtube.com) in that browser and allow the extension on the site if asked.

---

## 2. Install AutoHotkey v2 and run `copy.ahk`

1. Install **AutoHotkey v2** from [autohotkey.com](https://www.autohotkey.com/).
2. Double-click **`copy.ahk`** in this repo folder.
3. Confirm the **H** icon appears in the system tray.
4. **Optional — run at sign-in:** **Win+R** → type **`shell:startup`** → Enter → add a **shortcut** to `copy.ahk`.

After editing `copy.ahk`, reload it from the tray icon (**Reload Script**).

---

## 3. Install Gemini as a Chrome app (for Alt+C)

**Alt+C** expects a normal Chrome window whose title includes **`Gemini`**. Installing the **PWA** is more reliable than a loose tab.

1. Open **Google Chrome**.
2. Go to [gemini.google.com](https://gemini.google.com) and sign in.
3. Install: **install** icon in the address bar, or **⋮** → **Save and share** → **Install Gemini** (wording may vary).
4. Use the installed app window when you run **Alt+C**.

---

## Usage

1. Keep **YouTube** open in **Chrome** (or **Brave**) so your pointer can sit over a thumbnail.
2. Hover the thumbnail you want.
3. **Alt+X** — copy only. **Alt+C** — copy and send to Gemini as above. **Alt+Z** — paste hotkey (Ctrl+V).

If several Gemini windows are open, AutoHotkey uses the first one it finds; one window is simplest.
