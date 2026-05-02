# Mac setup (separate from Windows AHK)

This folder is a Mac-only workflow. It does not change any Windows AutoHotkey files.

## What it does

Press **Option+Z** while your mouse is over a YouTube thumbnail:

1. Focuses YouTube (Brave or Chrome)
2. Sends **Option+X** to trigger extension copy in `content.js`
3. Focuses a window with `Gemini` in the title
4. Pastes `summarize this video: <youtube_url>`
5. Presses Enter
6. Leaves clipboard as plain YouTube URL

## Install

1. Install [Hammerspoon](https://www.hammerspoon.org/).
2. Open Hammerspoon once.
3. Copy `Mac/hammerspoon/init.lua` to `~/.hammerspoon/init.lua`.
4. In Hammerspoon, click **Reload Config**.
5. Keep Hammerspoon running.

## Notes

- The Chrome extension must be loaded and active on YouTube.
- Keep the pointer over a YouTube thumbnail before pressing Option+Z.
- If Gemini does not paste, click the Gemini composer once, then try again.
- You can edit these variables in `Mac/hammerspoon/init.lua`:
  - `youtubeApps`
  - `geminiTitleNeedle`
  - `pastePrefix`
