# Troubleshooting CopyYoutubeURL

## Quick repro
1. Open YouTube in Brave; hover a thumbnail; press **Alt+Z**.
2. Watch [../copyurl_log.txt](../copyurl_log.txt) tail and the extension's DevTools console (Inspect on the youtube.com tab).

## Enable extension diagnostics
In the YouTube tab DevTools console:
```js
localStorage.__copyurlDebug = "1";
location.reload();
```
Then inspect after each Alt+Z:
```js
window.__copyurlLog   // ring buffer of last 200 events
```
Disable with `localStorage.removeItem("__copyurlDebug")`.

## Enable AHK verbose log
Edit top of [../copy.ahk](../copy.ahk): `kVerboseLog := true`. Tray → Reload Script.

## Title beacon (always on)
After every F24 the extension processes (F24 is AHK's internal trigger — Alt+Z is the user-facing hotkey), the page title gets a transient zero-width-space + tag suffix:

| Beacon | Meaning |
|---|---|
| `[CU:ok]` | execCommand wrote the URL synchronously. |
| `[CU:null]` | Extension fired but `hoveredVideoUrl` was null (stale hover). |
| `[CU:execfail]` | execCommand returned false; falling back to async API. |
| `[CU:asyncok]` | Async `navigator.clipboard.writeText` resolved. |
| `[CU:asyncfail]` | Async clipboard write rejected. |
| *(no beacon)* | Content script didn't process the keydown. Causes: extension not loaded, listener detached, JS error, page navigated, modifier mismatch. |

AHK reads the title right after Alt+X and logs it.

## Failure-signature → cause map
| Log signature | Likely cause | Fix |
|---|---|---|
| `beacon=null` | Hover state cleared before Alt+X arrived | Phase 3 Fix B (stale-hover retry) |
| `beacon=execfail` then timeout | execCommand denied; async didn't resolve in 1500 ms | Phase 3 Fix A (await async + raise timeout) |
| `beacon=asyncfail` | Browser clipboard API rejected | Check focus/permissions; consider falling back to ClipboardItem |
| no beacon at all, repeated | Content script not running | Reload extension; check `chrome://extensions` for errors |
| beacon=ok but `clipboard not a YouTube URL` | Clipboard sequence saw an unrelated update | Rare; investigate other clipboard writers |
| All 3 attempts time out, no beacon, then recovers minutes later | Tab crashed / reloaded mid-session | Phase 3 Fix D (readiness gate) |

## Health checks
- Extension loaded? In DevTools console on youtube.com: `typeof window.__copyurlReady` should be `"boolean"` and `true`.
- AHK running? Tray icon **H** present.
- Gemini PWA window? `WinGetTitle` of any chrome.exe window must contain `Gemini`.

## Reset checklist
1. Reload extension (`brave://extensions` → reload).
2. Reload AHK (tray → Reload Script).
3. Refresh YouTube tab.
4. Hover thumbnail, retry Alt+Z.

## Gemini composer focus (cursorless click)
The Gemini click is sent via `PostClickAtScreen` — it converts the screen coord to render-widget client coords with `ScreenToClient` and posts `WM_MOUSEMOVE` + `WM_LBUTTONDOWN/UP` to the largest `Chrome_RenderWidgetHostHWND`. The OS cursor doesn't move.

| Symptom | Likely cause | Fix |
|---|---|---|
| Paste lands in the wrong app / nothing focused | Render widget not found, or Gemini window changed class | Check log for `gemini_scan_pixelsearch_miss`; verify `WinGetClass` of Gemini still resolves a `Chrome_RenderWidgetHostHWND` child. |
| `Gemini pass1 layout=active(fallback)` on a new chat | Composer color not in candidate list `[0x2A2B2D, 0x1F2022, 0x303134, 0x252628]` | Add the actual `gemini_bottom_pixel=0x...` value from the log to `composerColors` in `FindGeminiComposerScreenY`. |
| Click registers but composer never focuses | Heavy JS frame intercepting posted-message clicks | Last-resort fallback: revert that one section to `Click()` + immediate `MouseMove` restore. |
