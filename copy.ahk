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

; Per-attempt clipboard-update timeout (ms) and number of Alt+X retries before giving up.
kCopyAttemptTimeoutMs := 1500
kCopyMaxAttempts := 3

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
            return true
        }
        if (A_TickCount >= deadline) {
            ; Last-chance beacon read after timeout (in case it appeared late).
            if (hwnd && beaconSeen = "") {
                b := ReadTitleBeacon(hwnd)
                if (b != "")
                    beaconSeen := b
            }
            VerboseLog("clip_timeout elapsed=" . (A_TickCount - tStart) . " beacon=" . (beaconSeen = "" ? "none" : beaconSeen))
            return false
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

    hwnd := FindBraveWindow()
    if !hwnd {
        DebugLog("No Brave window found.")
        TrayTip("Brave window not found.", "CopyURL")
        return
    }
    WinActivate(hwnd)
    if !WinWaitActive(hwnd,, 2) {
        VerboseLog("pre_attempt " . attempt . " title=" . SubStr(WinGetTitle(hwnd), 1, 160))
        DebugLog("Copy attempt " . attempt)
        if TryCopyOnce(kCopyAttemptTimeoutMs, hwnd "CopyURL")
        return
    }
    if !ActiveTabIsYouTube(hwnd) {
        DebugLog("Active Brave tab is not YouTube. Title=" . WinGetTitle(hwnd))
        TrayTip("Active Brave tab is not YouTube. Switch to the YouTube tab and retry.", "CopyURL")
        return
    }
    SendInput("{Escape}")
    Sleep(120)

    ; Retry the copy a few times: hover-resync + Alt+X. Most intermittent
    ; failures come from a single missed mousemove or the page still settling
    ; right after WinActivate.
    success := false
    Loop kCopyMaxAttempts {
        attempt := A_Index
        SyncChromiumHoverThorough(hwnd)
        Sleep(120)
        DebugLog("Copy attempt " . attempt)
        if TryCopyOnce(kCopyAttemptTimeoutMs) {
            success := true
            DebugLog("Copy attempt " . attempt . " succeeded.")
            break
        }
        DebugLog("Copy attempt " . attempt . " timed out.")
        Sleep(120)
    }
    if !success {
        TrayTip("YouTube copy timed out — make sure cursor is over a thumbnail and try again.", "CopyURL")
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
    ; Now the input is focused — select all within it, paste, submit
    SendInput("^a")
    Sleep(50)
    SendInput("^v")
    Sleep(300)
    SendInput("{Enter}")
    A_Clipboard := clipUrl
    DebugLog("Sent to Gemini.")
}
