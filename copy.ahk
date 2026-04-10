#Requires AutoHotkey v2.0

; Gemini composer target (fractions of top-level Chrome PWA client size). Tune if posted click misses "Ask Gemini".
kGeminiInputXFrac := 0.5
kGeminiInputYFrac := 0.92

; Text before the URL in Gemini (Alt+C). "" = URL only. Clipboard is restored to the plain URL after send.
kGeminiPastePrefix := "Summarize this YouTube video:`n"

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

$!x:: {
    hwnd := FindBraveWindow()
    if !hwnd
        return
    WinActivate(hwnd)
    if !WinWaitActive(hwnd,, 2)
        return
    SendInput("{Escape}")
    Sleep(150)
    SyncChromiumHoverAtCursor(hwnd)
    Sleep(200)
    SendEvent("{Alt down}x{Alt up}")
}

$!c:: {
    hwnd := FindBraveWindow()
    if !hwnd
        return
    WinActivate(hwnd)
    if !WinWaitActive(hwnd,, 2)
        return
    SendInput("{Escape}")
    Sleep(150)
    SyncChromiumHoverAtCursor(hwnd)
    Sleep(200)
    SendEvent("{Alt down}x{Alt up}")
    Sleep(300)
    clipUrl := A_Clipboard
    if (kGeminiPastePrefix != "")
        A_Clipboard := kGeminiPastePrefix . clipUrl
    gemHwnd := FindGeminiWindow()
    if !gemHwnd {
        A_Clipboard := clipUrl
        return
    }
    WinActivate(gemHwnd)
    if !WinWaitActive(gemHwnd,, 2) {
        A_Clipboard := clipUrl
        return
    }
    Sleep(300)
    FocusGeminiComposer(gemHwnd, kGeminiInputXFrac, kGeminiInputYFrac)
    Sleep(150)
    if (kGeminiPastePrefix != "")
        Sleep(50)
    SendInput("^v")
    Sleep(100)
    SendInput("{Enter}")
    A_Clipboard := clipUrl
}

!z::Send("^v")
