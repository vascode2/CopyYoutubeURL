#Requires AutoHotkey v2.0

; Gemini "Ask Gemini" composer click (fractions of Chrome PWA client size). Nudge if the click hits Tools/+ instead of the text field.
kGeminiInputXFrac := 0.5
kGeminiInputYFrac := 0.92

; Text before the URL in Gemini (Alt+C). "" = URL only. Clipboard is restored to the plain URL after send.
kGeminiPastePrefix := "Summarize this YouTube video:`n"

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

$!x:: {
    hwnd := FindBraveWindow()
    if !hwnd
        return
    WinActivate(hwnd)
    if !WinWaitActive(hwnd,, 2)
        return
    SendInput("{Escape}")
    Sleep(150)
    MouseMove(5, 0,, "R")
    Sleep(100)
    MouseMove(-5, 0,, "R")
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
    ; Escape defocuses the URL bar so keystrokes reach the page content script
    SendInput("{Escape}")
    Sleep(150)
    ; Nudge mouse to trigger mousemove/mouseover, then wait for extension to process
    MouseMove(5, 0,, "R")
    Sleep(100)
    MouseMove(-5, 0,, "R")
    Sleep(200)
    ; Send Alt+X to trigger the content script copy
    SendEvent("{Alt down}x{Alt up}")
    ; Wait for clipboard to be updated
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
    CoordMode "Mouse", "Client"
    WinGetClientPos(&cx, &cy, &cw, &ch, gemHwnd)
    Click(Round(cw * kGeminiInputXFrac), Round(ch * kGeminiInputYFrac))
    Sleep(150)
    if (kGeminiPastePrefix != "")
        Sleep(50)
    SendInput("^v")
    Sleep(100)
    SendInput("{Enter}")
    A_Clipboard := clipUrl
    CoordMode "Mouse", "Screen"
}

!z::Send("^v")
