# CopyURL — YouTube thumbnail → clipboard (and Gemini on Windows)

Hover a YouTube thumbnail in **Brave**, press a key: the extension copies a clean `watch?v=` URL. On **Windows**, [AutoHotkey v2](https://www.autohotkey.com/) `copy.ahk` sends global **Alt+X** / **Alt+C** / **Alt+Z** so it works while another app is focused. **Alt+C** activates **Brave** (copy), then a **Chrome** window whose title contains **Gemini** (installed PWA), posts mouse messages to the composer **without moving your real cursor**, pastes an optional summarize line + URL, presses Enter, and restores the clipboard to the plain URL.

| Hotkey | Action |
|--------|--------|
| **Alt+X** | Copy hovered video URL (via Brave + extension) |
| **Alt+C** | Same copy → Gemini app → paste prefix + URL → Enter |
| **Alt+Z** | Ctrl+V |

**Setup:** Load this folder as an unpacked extension in Brave (`brave://extensions`). Install [Gemini](https://gemini.google.com) as a **Chrome** app (title must include `Gemini`). Install AHK v2, run `copy.ahk` (optional: put it in Startup — `Win+R` → `shell:startup`).

**Tune** (top of `copy.ahk`): `kGeminiInputXFrac` / `kGeminiInputYFrac` if the posted click misses the composer; `kGeminiPastePrefix` (`""` for URL-only paste). Uses `PostMessage` to Chromium’s `Chrome_RenderWidgetHostHWND` — fragile across major Chrome updates.

**Requirements:** Brave + extension; Windows + AHK v2 for globals; Chrome + Gemini PWA for **Alt+C**. Extension-only use on other OSes: focus the YouTube tab and use in-page **Alt+X**.
