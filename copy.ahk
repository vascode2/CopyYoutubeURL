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
    Sleep(150)
    MouseMove(5, 0,, "R")
    Sleep(50)
    MouseMove(-5, 0,, "R")
    Sleep(300)
    SendInput("!c")
}
