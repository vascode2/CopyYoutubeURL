#Requires AutoHotkey v2.0

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

$!c:: {
    hwnd := FindBraveWindow()
    if !hwnd
        return
    WinActivate(hwnd)
    if !WinWaitActive(hwnd,, 2)
        return
    ; Escape defocuses the URL bar so keystrokes reach the page content script
    SendInput("{Escape}")
    Sleep(150)
    ; Nudge mouse to trigger mousemove/mouseover, then wait for extension to process
    MouseMove(5, 0,, "R")
    Sleep(100)
    MouseMove(-5, 0,, "R")
    Sleep(200)
    ; Send Alt+C with explicit key events to ensure the browser receives it
    SendEvent("{Alt down}c{Alt up}")
}
