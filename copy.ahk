#Requires AutoHotkey v2.0

; Gemini composer target (fractions of top-level Chrome PWA client size). Tune if posted click misses "Ask Gemini".
kGeminiInputXFrac := 0.5
kGeminiInputYFrac := 0.92

; Text before the URL in Gemini (Alt+Z). "" = URL only. Clipboard is restored to the plain URL after send.
kGeminiPastePrefix := "Summarize this YouTube video:`n"

; Set true to append diagnostic lines to copyurl_log.txt next to this script.
kDebugLog := true
; Set true for extra per-stage timing and title-beacon lines (Phase 1 instrumentation).
kVerboseLog := true
; Rotate copyurl_log.txt when it exceeds this size (bytes). Set 0 to disable.
kLogMaxBytes := 524288

; Per-attempt clipboard-update timeout (ms) and number of F24 retries per candidate.
; A successful copy returns in ~30 ms (see logs). 800 ms is plenty for a real
; round-trip; if we hit timeout it almost certainly means the extension isn't
; listening on this browser, in which case more retries don't help.
kCopyAttemptTimeoutMs := 800
kCopyMaxAttempts := 2
; If the first attempt on a candidate returns beacon=none (extension didn't
; even fire), skip the remaining retries on that candidate and fall through
; to the next browser immediately. This is the main speed-up when one
; browser doesn't have the extension installed.
kFastFailOnNoBeacon := true

; File where we cache the exe of the most recent successful copy. Tried first
; on subsequent invocations so a working browser doesn't get stuck behind a
; non-working one in Z-order.
LastWinnerPath() {
    return A_ScriptDir "\copyurl_last_winner.txt"
}
ReadLastWinner() {
    p := LastWinnerPath()
    if !FileExist(p)
        return ""
    try {
        s := Trim(FileRead(p))
        return s
    }
    return ""
}
WriteLastWinner(exe) {
    p := LastWinnerPath()
    try {
        try FileDelete(p)
        FileAppend(exe, p)
    }
}

LogPath() {
    return A_ScriptDir "\copyurl_log.txt"
}

RotateLogIfNeeded() {
    global kLogMaxBytes
    if (kLogMaxBytes <= 0)
        return
    p := LogPath()
    if !FileExist(p)
        return
    try {
        sz := FileGetSize(p)
        if (sz > kLogMaxBytes) {
            old := p . ".1"
            try FileDelete(old)
            try FileMove(p, old)
        }
    }
}

DebugLog(msg) {
    global kDebugLog
    if !kDebugLog
        return
    RotateLogIfNeeded()
    try FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") . " t=" . A_TickCount . " | " . msg . "`n", LogPath())
}

VerboseLog(msg) {
    global kVerboseLog
    if !kVerboseLog
        return
    DebugLog("[v] " . msg)
}

/**
 * Parse the title-beacon suffix written by content.js (zero-width-space + "[CU:STATE]").
 * Returns the STATE string (e.g. "ok", "null", "execfail", "asyncok", "asyncfail")
 * or "" if no beacon present.
 */
ReadTitleBeacon(hwnd) {
    title := WinGetTitle(hwnd)
    if (title = "")
        return ""
    if RegExMatch(title, "\[CU:([A-Za-z]+)\]", &m)
        return m[1]
    return ""
}

WM_MOUSEMOVE := 0x200
WM_LBUTTONDOWN := 0x201
WM_LBUTTONUP := 0x202
MK_LBUTTON := 0x1

; Browsers we'll search for the YouTube tab, in priority order. Brave first so
; existing setups keep behaving identically; Chrome added so the same script
; works when the extension is installed in Chrome instead.
kYouTubeBrowsers := ["brave.exe", "chrome.exe"]

/**
 * Return an ordered list of candidate browser windows (most-likely first).
 * Replaces the old FindYouTubeWindow which returned only one. The Alt+Z
 * handler walks this list and tries each in turn, so e.g. if Brave is more
 * recently active but the extension isn't installed there, we automatically
 * fall through to Chrome's YouTube tab.
 *
 * Order:
 *   1. Foreground window if it's a YouTube browser tab.
 *   2. All matching windows across both browsers in WinGetList order
 *      (per-exe Z-order; "YouTube" titles before others).
 *
 * Chrome's Gemini PWA window is excluded.
 */
FindYouTubeCandidates() {
    global kYouTubeBrowsers
    list := []
    seen := Map()

    ; 0. Sticky preference: if a browser worked last time, try it first.
    lastExe := ReadLastWinner()

    ; 1. Foreground first.
    fg := WinExist("A")
    if (fg) {
        try {
            fgExe := WinGetProcessName(fg)
            fgTitle := WinGetTitle(fg)
            fgCls := WinGetClass(fg)
            for _i, exe in kYouTubeBrowsers {
                if (fgExe = exe && fgCls = "Chrome_WidgetWin_1"
                    && fgTitle != "" && InStr(fgTitle, "YouTube")
                    && !(exe = "chrome.exe" && InStr(fgTitle, "Gemini"))) {
                    seen[fg] := true
                    list.Push({ hwnd: fg, title: fgTitle, exe: exe })
                    break
                }
            }
        }
    }

    ; 2. Collect all YouTube-titled windows from each browser, then non-YouTube fallbacks.
    youtubeOnly := []
    others := []
    for _i, exe in kYouTubeBrowsers {
        for _j, hwnd in WinGetList("ahk_exe " . exe) {
            try {
                cls := WinGetClass(hwnd)
                title := WinGetTitle(hwnd)
                visible := DllCall("IsWindowVisible", "Ptr", hwnd)
                if !(visible && cls = "Chrome_WidgetWin_1" && title != "")
                    continue
                if (exe = "chrome.exe" && InStr(title, "Gemini"))
                    continue
                if InStr(title, "YouTube")
                    youtubeOnly.Push({ hwnd: hwnd, title: title, exe: exe })
                else
                    others.Push({ hwnd: hwnd, title: title, exe: exe })
            }
        }
    }

    ; Within YouTube-titled candidates, push lastExe-matching ones first.
    if (lastExe != "") {
        priority := []
        rest := []
        for _i, c in youtubeOnly
            (c.exe = lastExe ? priority : rest).Push(c)
        for _i, c in priority
            if !seen.Has(c.hwnd) {
                seen[c.hwnd] := true
                list.Push(c)
            }
        for _i, c in rest
            if !seen.Has(c.hwnd) {
                seen[c.hwnd] := true
                list.Push(c)
            }
    } else {
        for _i, c in youtubeOnly
            if !seen.Has(c.hwnd) {
                seen[c.hwnd] := true
                list.Push(c)
            }
    }
    for _i, c in others {
        if !seen.Has(c.hwnd) {
            seen[c.hwnd] := true
            list.Push(c)
        }
    }
    return list
}

; Backwards-compatible single-pick wrapper (kept in case anything else calls it).
FindYouTubeWindow() {
    cands := FindYouTubeCandidates()
    return cands.Length ? cands[1].hwnd : 0
}

FindBraveWindow() {
    allWins := WinGetList("ahk_exe brave.exe")
    for index, hwnd in allWins {
        title := WinGetTitle(hwnd)
        cls := WinGetClass(hwnd)
        visible := DllCall("IsWindowVisible", "Ptr", hwnd)
        if (visible && cls = "Chrome_WidgetWin_1" && title != "") {
            return hwnd
        }
    }
    return 0
}

FindGeminiWindow() {
    allWins := WinGetList("ahk_exe chrome.exe")
    for index, hwnd in allWins {
        title := WinGetTitle(hwnd)
        cls := WinGetClass(hwnd)
        visible := DllCall("IsWindowVisible", "Ptr", hwnd)
        if (visible && cls = "Chrome_WidgetWin_1" && title != "" && InStr(title, "Gemini")) {
            return hwnd
        }
    }
    return 0
}

/**
 * Recursively find the largest Chrome_RenderWidgetHostHWND under a top-level Chromium window.
 */
ChromeScanForRender(h, &best, &bestArea) {
    if (WinGetClass(h) = "Chrome_RenderWidgetHostHWND") {
        WinGetClientPos(, , &cw, &ch, h)
        area := cw * ch
        if (area > bestArea) {
            bestArea := area
            best := h
        }
    }
    child := 0
    Loop 256 {
        child := DllCall("FindWindowEx", "Ptr", h, "Ptr", child, "Ptr", 0, "Ptr", 0, "Ptr")
        if !child
            break
        ChromeScanForRender(child, &best, &bestArea)
    }
}

ChromeLargestRenderHwnd(rootHwnd) {
    best := 0
    bestArea := -1
    ChromeScanForRender(rootHwnd, &best, &bestArea)
    return best
}

MakeLParam(x, y) {
    return (y << 16) | (x & 0xFFFF)
}

PostMouseMove(renderHwnd, cx, cy) {
    lParam := MakeLParam(cx, cy)
    PostMessage(WM_MOUSEMOVE, 0, lParam, , "ahk_id " renderHwnd)
}

PostLClick(renderHwnd, cx, cy) {
    lParam := MakeLParam(cx, cy)
    PostMessage(WM_LBUTTONDOWN, MK_LBUTTON, lParam, , "ahk_id " renderHwnd)
    PostMessage(WM_LBUTTONUP, 0, lParam, , "ahk_id " renderHwnd)
}

/**
 * Map a point from top-level Chromium client coords to Chrome_RenderWidgetHostHWND client coords.
 */
ParentClientToRenderClient(parentHwnd, renderHwnd, pcx, pcy) {
    pt := Buffer(8, 0)
    NumPut("Int", pcx, pt, 0)
    NumPut("Int", pcy, pt, 4)
    if !DllCall("ClientToScreen", "Ptr", parentHwnd, "Ptr", pt)
        return 0
    if !DllCall("ScreenToClient", "Ptr", renderHwnd, "Ptr", pt)
        return 0
    return { x: NumGet(pt, 0, "Int"), y: NumGet(pt, 4, "Int") }
}

/**
 * Post WM_MOUSEMOVE at the physical cursor, in render-widget client space (no system cursor move).
 */
PostMouseMoveAtCursor(renderHwnd) {
    pt := Buffer(8, 0)
    if !DllCall("GetCursorPos", "Ptr", pt)
        return false
    if !DllCall("ScreenToClient", "Ptr", renderHwnd, "Ptr", pt)
        return false
    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")
    PostMouseMove(renderHwnd, cx, cy)
    PostMouseMove(renderHwnd, cx + 1, cy)
    PostMouseMove(renderHwnd, cx, cy)
    return true
}

SyncChromiumHoverAtCursor(topHwnd) {
    render := ChromeLargestRenderHwnd(topHwnd)
    if !render
        return false
    return PostMouseMoveAtCursor(render)
}

ClipboardSequence() {
    return DllCall("GetClipboardSequenceNumber", "UInt")
}

/**
 * Wait until the OS clipboard changes (extension finished writing). Avoids reading a stale URL
 * while navigator.clipboard.writeText is still pending, or general race with Sleep(300).
 */
WaitForClipboardUpdate(seqBefore, timeoutMs := 4000) {
    deadline := A_TickCount + timeoutMs
    Loop {
        if (ClipboardSequence() != seqBefore)
            return true
        if (A_TickCount >= deadline)
            return false
        Sleep(30)
    }
}

ClipboardTextLooksLikeYouTubeUrl(s) {
    return InStr(s, "youtube.com") && (InStr(s, "watch?v=") || InStr(s, "youtu.be/"))
}

FocusGeminiComposer(topHwnd, xFrac, yFrac) {
    render := ChromeLargestRenderHwnd(topHwnd)
    if !render
        return false
    WinGetClientPos(, , &cw, &ch, topHwnd)
    pcx := Round(cw * xFrac)
    pcy := Round(ch * yFrac)
    mapped := ParentClientToRenderClient(topHwnd, render, pcx, pcy)
    if !mapped
        return false
    cx := mapped.x
    cy := mapped.y
    PostMouseMove(render, cx, cy)
    Sleep(30)
    PostLClick(render, cx, cy)
    return true
}

/**
 * Resync hover at multiple jitter points so YouTube's mousemove handler updates
 * hoveredVideoUrl even if the cursor sits exactly on an overlay seam.
 */
SyncChromiumHoverThorough(topHwnd) {
    render := ChromeLargestRenderHwnd(topHwnd)
    if !render
        return false
    pt := Buffer(8, 0)
    if !DllCall("GetCursorPos", "Ptr", pt)
        return false
    if !DllCall("ScreenToClient", "Ptr", render, "Ptr", pt)
        return false
    cx := NumGet(pt, 0, "Int")
    cy := NumGet(pt, 4, "Int")
    ; Several small moves around the cursor; YouTube's pointermove fires on each.
    for delta in [[0,0],[2,0],[0,2],[-2,0],[0,-2],[1,1],[0,0]] {
        PostMouseMove(render, cx + delta[1], cy + delta[2])
        Sleep(15)
    }
    return true
}

/**
 * Active Brave tab title check — only the top-level window's title reflects the
 * active tab. If "YouTube" isn't in it, content.js is on a different page and
 * Alt+X will silently miss.
 */
ActiveTabIsYouTube(hwnd) {
    title := WinGetTitle(hwnd)
    return InStr(title, "YouTube") > 0
}

/**
 * One trigger attempt with its own clipboard-sequence wait. Returns true if the
 * extension wrote a fresh clipboard value within timeoutMs.
 *
 * Uses F24 as the in-tab signal (no global binding, no collision with other apps'
 * Alt+X hooks like CopyAnkitoChatGPT). Beacon-aware: caller passes hwnd so we can
 * capture the title beacon (set by content.js for ~300 ms after every trigger).
 */
TryCopyOnce(timeoutMs, hwnd := 0) {
    seqBefore := ClipboardSequence()
    tStart := A_TickCount
    SendInput("{F24}")
    deadline := tStart + timeoutMs
    beaconSeen := ""
    Loop {
        if (hwnd && beaconSeen = "") {
            b := ReadTitleBeacon(hwnd)
            if (b != "")
                beaconSeen := b
        }
        if (ClipboardSequence() != seqBefore) {
            VerboseLog("clip_changed elapsed=" . (A_TickCount - tStart) . " beacon=" . beaconSeen)
            return { ok: true, beacon: beaconSeen }
        }
        if (A_TickCount >= deadline) {
            if (hwnd && beaconSeen = "") {
                b := ReadTitleBeacon(hwnd)
                if (b != "")
                    beaconSeen := b
            }
            VerboseLog("clip_timeout elapsed=" . (A_TickCount - tStart) . " beacon=" . (beaconSeen = "" ? "none" : beaconSeen))
            return { ok: false, beacon: beaconSeen }
        }
        Sleep(25)
    }
}

$!z:: {
    DebugLog("--- Alt+Z pressed ---")
    ; Brief wait for the user to release Alt before we activate Brave and send F24.
    ; F24 itself doesn't fight a held Alt, but a still-pressed Alt can interfere
    ; with WinActivate focus. Cap the wait so a stuck-down case still proceeds.
    KeyWait("LAlt", "T0.4")
    KeyWait("RAlt", "T0.4")

    candidates := FindYouTubeCandidates()
    if (candidates.Length = 0) {
        DebugLog("No YouTube-capable browser window found (Brave/Chrome).")
        TrayTip("YouTube window not found in Brave or Chrome.", "CopyURL")
        return
    }
    DebugLog("Candidates: " . candidates.Length)

    success := false
    pickedHwnd := 0
    pickedExe := ""
    for _ci, cand in candidates {
        hwnd := cand.hwnd
        pickedExe := cand.exe
        DebugLog("Trying candidate #" . _ci . " exe=" . pickedExe . " title=" . SubStr(cand.title, 1, 160))
        WinActivate(hwnd)
        if !WinWaitActive(hwnd,, 2) {
            DebugLog("WinWaitActive timed out for hwnd=" . hwnd)
            continue
        }
        if !ActiveTabIsYouTube(hwnd) {
            DebugLog("Active tab is not YouTube. Title=" . WinGetTitle(hwnd))
            continue
        }
        SendInput("{Escape}")
        Sleep(120)

        ; Retry the copy a few times for this candidate.
        candFailedFast := false
        Loop kCopyMaxAttempts {
            attempt := A_Index
            SyncChromiumHoverThorough(hwnd)
            Sleep(120)
            DebugLog("Copy attempt " . attempt . " on " . pickedExe)
            res := TryCopyOnce(kCopyAttemptTimeoutMs, hwnd)
            if (res.ok) {
                success := true
                DebugLog("Copy attempt " . attempt . " on " . pickedExe . " succeeded.")
                break
            }
            DebugLog("Copy attempt " . attempt . " on " . pickedExe . " timed out (beacon=" . (res.beacon = "" ? "none" : res.beacon) . ").")
            ; Fast-fail: if extension didn't fire at all (beacon=none),
            ; further retries on the same browser won't help.
            if (kFastFailOnNoBeacon && res.beacon = "") {
                candFailedFast := true
                break
            }
            Sleep(120)
        }
        if (success) {
            pickedHwnd := hwnd
            WriteLastWinner(pickedExe)
            break
        }
        DebugLog("Candidate " . pickedExe . " " . (candFailedFast ? "fast-failed (beacon=none)" : "gave up after " . kCopyMaxAttempts . " attempts") . " — falling through to next candidate.")
    }
    if !success {
        TrayTip("YouTube copy timed out across all browsers — hover a thumbnail and try again.", "CopyURL")
        return
    }

    Sleep(60)
    clipUrl := A_Clipboard
    if !ClipboardTextLooksLikeYouTubeUrl(clipUrl) {
        DebugLog("Clipboard not a YouTube URL: " . SubStr(clipUrl, 1, 120))
        TrayTip("Clipboard does not look like a YouTube URL — copy may have failed.", "CopyURL")
        return
    }
    DebugLog("Got URL: " . clipUrl)
    if (kGeminiPastePrefix != "")
        A_Clipboard := kGeminiPastePrefix . clipUrl
    gemHwnd := FindGeminiWindow()
    if !gemHwnd {
        DebugLog("Gemini window not found; left URL on clipboard.")
        A_Clipboard := clipUrl
        return
    }
    WinActivate(gemHwnd)
    if !WinWaitActive(gemHwnd,, 2) {
        DebugLog("WinWaitActive(Gemini) timed out.")
        A_Clipboard := clipUrl
        return
    }
    ; Real click on the "Ask Gemini" input field at bottom-center of window.
    ; PostMessage fake clicks don't trigger Chrome JS event handlers — real Click does.
    Sleep(200)
    WinGetPos(&wx, &wy, &ww, &wh, gemHwnd)
    clickX := wx + Round(ww * 0.5)
    clickY := wy + wh - 60
    CoordMode("Mouse", "Screen")
    MouseGetPos(&origX, &origY)
    Click(clickX, clickY)
    Sleep(300)
    MouseMove(origX, origY, 0)
    ; Now the input is focused — select all within it, paste, submit.
    ; Gemini's composer is React-driven: pasted text needs a moment to be
    ; reflected in component state before Enter is treated as "submit".
    ; Too short a gap and Enter just inserts a newline (or is ignored).
    SendInput("^a")
    Sleep(80)
    SendInput("^v")
    Sleep(700)  ; let React commit the paste + enable the send button
    SendEvent("{Enter}")
    Sleep(200)
    ; Belt-and-suspenders: a second Enter via SendInput in case the first
    ; landed before the composer was ready. If the prompt was already sent,
    ; a stray Enter in an empty composer is a no-op.
    SendInput("{Enter}")
    A_Clipboard := clipUrl
    DebugLog("Sent to Gemini.")
}
