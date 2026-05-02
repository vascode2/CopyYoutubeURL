# CLAUDE.md — CopyYoutubeURL handoff

> Living handoff doc. Update at every phase boundary. Future agent sessions should read this first.

## What this project does
Hover a YouTube thumbnail in Brave/Chrome → press **Alt+Z** (only user-facing hotkey) → AutoHotkey activates the YouTube window, sends **F24** inside the tab as the internal extension trigger (F24 chosen to avoid collision with other tools' global hotkeys, e.g. CopyAnkitoChatGPT owns Alt+X), the extension copies the hovered video's URL to the OS clipboard, then AHK switches to the Gemini Chrome app and pastes a "Summarize this YouTube video:" prompt + URL and presses Enter.

## Architecture (3 cooperating processes)
1. **Browser content script** ([content.js](content.js)) — tracks hovered video, listens for Alt+X, writes URL to clipboard via synchronous `document.execCommand("copy")` (with async `navigator.clipboard.writeText` fallback).
2. **AutoHotkey v2 script** ([copy.ahk](copy.ahk)) — global Alt+Z handler. Activates Brave, syncs hover (PostMessage WM_MOUSEMOVE jitter), sends Alt+X, polls `GetClipboardSequenceNumber` until it changes, then drives Gemini paste.
3. **Gemini Chrome PWA** — receives synthetic click + Ctrl+A/Ctrl+V/Enter.

No background script, no native messaging, no host permissions beyond the YouTube content-script match.

## Reported problem
"Copy feature sometimes works but sometimes does not." Logs in [copyurl_log.txt](copyurl_log.txt) show clusters of `Copy attempt N timed out` with no diagnostic about *which* leg failed (extension didn't fire? `hoveredVideoUrl` null? execCommand returned false? OS clipboard never updated?).

## Suspected root causes (ranked)
0. **(FIXED 2026-05-02) Alt+X collision with CopyAnkitoChatGPT**: that app's global Alt+X hook intercepted the synthetic Alt+X before it reached Brave, so the extension never received the keydown. Replaced with **F24** (no global binding).
1. **execCommand → async fallback race**: `execCommand` returns false; code calls `navigator.clipboard.writeText` (async); AHK's per-attempt 1500 ms clipboard-sequence wait can expire before the promise resolves.
2. **Stale `hoveredVideoUrl`**: `mouseout` cleared it; `refreshHoverFromLastPointer()` couldn't re-find from stale coordinates after window activate.
3. **Pre-copy `SendInput("{Escape}")`** ([copy.ahk](copy.ahk)) blurs/cancels page state in unhelpful ways.
4. **MV3 re-injection race**: tab reload / SPA navigation before listener attached.

## Plan (6 phases — see [/memories/session/plan.md](.) in agent memory)
- **Phase 0** *(this commit)*: handoff scaffolding — `CLAUDE.md`, `docs/troubleshooting.md`.
- **Phase 1**: opt-in instrumentation — content.js ring-buffer + `document.title` beacon `[CU:ok|null|err|busy]`; copy.ahk pre/post-title logging + per-stage timing; log rotation.
- **Phase 2**: stress harness — `scripts/stress_copy.ahk` + `scripts/analyze_stress.py`.
- **Phase 3**: targeted fixes A–E (async-clipboard race, stale hover, Escape, MV3 readiness, Alt collision) — each independently revertable, each gated by N=200 stress run.
- **Phase 4**: validation (≥99% success, zero "no-beacon" outcomes).
- **Phase 5**: default flags OFF, instrumentation stays.

## Decision log
| Date | Decision | Rationale |
|---|---|---|
| 2026-05-02 | Cross-process telemetry via `document.title` suffix beacon | Zero new permissions, no native messaging, AHK can read via `WinGetTitle`. |
| 2026-05-02 | All instrumentation behind flags, default OFF after Phase 5 | Keep code paths intact; zero behavior change. |
| 2026-05-02 | Stress target = a fixed YouTube watch page with autoplay off | Reduce environmental variance during A/B testing. |

## Diagnostic flags
- **Extension**: set `localStorage.__copyurlDebug = "1"` on a youtube.com page (persisted). Enables ring buffer at `window.__copyurlLog` (last 200 events) and `console.debug("[CopyURL]", ...)` output. Title beacon is **always on** (cheap, invisible suffix using zero-width char + tag).
- **AutoHotkey**: `kVerboseLog := true` at top of [copy.ahk](copy.ahk) — adds per-stage timing + pre/post title in the log.

## Title beacon protocol (contract)
After every F24 keydown the extension processes, it appends ` ​[CU:STATE]` (zero-width-space + tag) to `document.title` for ~300 ms, then restores. STATE ∈ `ok | null | execfail | asyncok | asyncfail`. AHK reads via `WinGetTitle` immediately after sending F24 and parses the tag with `RegExMatch`.

## Current status
- Phase 0 + Phase 1 implemented (this update).
- Awaiting first stress-harness run.

## Next steps (resume here)
1. Reload extension in Brave/Chrome (`brave://extensions` → reload).
2. Reload [copy.ahk](copy.ahk) (tray → Reload Script).
3. Trigger Alt+Z 3–5×; confirm new log lines (`pre_title`, `post_title`, `beacon`) in [copyurl_log.txt](copyurl_log.txt).
4. Move to Phase 2 (stress harness).

## Files touched per phase
- **Phase 0**: `CLAUDE.md`, `docs/troubleshooting.md`.
- **Phase 1**: `content.js`, `copy.ahk`.
- **Phase 2** (planned): `scripts/stress_copy.ahk`, `scripts/analyze_stress.py`.
- **Phase 3** (planned): `content.js`, `copy.ahk`.

## Out of scope
- macOS port (separate `Mac/` folder, Hammerspoon-based).
- Gemini paste/Enter rewrite (separate test_enter*.ahk experiments).
- Native-messaging / background-script architecture.
