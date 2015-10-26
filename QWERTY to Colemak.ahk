#Persistent
#NoEnv
#Warn
#SingleInstance force
#HotkeyInterval 1000
#MaxHotkeysPerInterval 100
#UseHook
Process, Priority,, Realtime
SetWorkingDir %A_ScriptDir%
OnExit, DoCleanup

; Custom Init
IsColemak := true
DisabledApps := {"dosbox.exe": true}
hHookMouse := 0
hHookMouseWin := 0

; Toggle between Native and Colemak
ToggleColemak() {
	global IsColemak
	IsColemak := NOT IsColemak
	SetCapsLockState, Off
	If (IsColemak) {
		SetScrollLockState, Off
		; Menu, tray, Icon, %A_IconFile%, 3
	} Else {
		SetScrollLockState, On
		; Menu, tray, Icon, %A_IconFile%, 8
	}
}

; Per-app disabling
DisableCurrentApp() {
	global DisabledApps
	WinGet, app, ProcessName, A
	DisabledApps[app] := true
}
EnableCurrentApp() {
	global DisabledApps, DisabledAppsStr
	WinGet, app, ProcessName, A
	DisabledApps.Remove(app)
}
IsActiveAppEnabled() {
	global DisabledApps
    For app in DisabledApps
		If (WinActive("ahk_exe " . app))
			Return False
	return True
}
RunTaskMgr() {
	Run, "C:\Windows\System32\taskmgr.exe"
	Process, Priority, taskmgr.exe, Realtime
}

; Ctrl+Alt+Num+/- Enable/Disable current app
#If
^!NumpadSub::DisableCurrentApp()
^!NumpadAdd::EnableCurrentApp()

; CapsLock globally toggles between colemak and native mode in non-disabled apps
#If IsActiveAppEnabled()
*Capslock::ToggleColemak()

; Colemak Key Mappings
#If IsColemak AND IsActiveAppEnabled()
-::-
=::=
q::q
w::w
e::f
r::p
t::g
y::j
u::l
i::u
o::y
p::`;
[::[
]::]
a::a
s::r
d::s
f::t
g::d
h::h
j::n
k::e
l::i
`;::o
'::'
z::z
x::x
c::c
v::v
b::b
n::k
m::m
,::,
.::.
/::/
Enter::Enter
;Space::Space

^+Esc::RunTaskMgr()
;^!NumpadDiv::SetFullscreenWindowedA()
;^!NumpadMult::SetFullscreenWindowedB()

#If

; Borderless Windowed Fullscreen - AutoHotkey Script
SetFullscreenWindowedA()
{
	WinGetTitle, currentWindow, A
	IfWinExist %currentWindow%
	{
		WinSet, Style, ^0x00C00000 ; toggle title bar
		WinMove, , , 1920, 0, 1920, 1080
	}
}
SetFullscreenWindowedB()
{
	WinGetTitle, currentWindow, A
	IfWinExist %currentWindow%
	{
		; See Style reference at http://www.autohotkey.com/docs/misc/Styles.htm
		WinGet, Style, Style
		if (Style & 0x00800000)
		{
			WinSet, Style, -0x00C40000 ; hide title bar, border, etc
			WinSet, ExStyle, -0x00000200 ; hide sunken edge
			WinMove, , , 1920, 0, 1920, 1080
		} else {
			WinSet, Style, +0x00C40000 ; show title bar
			WinSet, ExStyle, +0x00000200 ; show sunken edge
		}
	}  
}


; http://www.autohotkey.com/board/topic/85313-capturing-the-screen-mouse-keyboard-at-the-same-time/
^!NumpadDiv::DisableMouseCapture()
^!NumpadMult::EnableMouseCapture()

EnableMouseCapture()
{
	global hHookMouse, hHookMouseWin
	WinGet, hHookMouseWin, ID, A
	If hHookMouse = 0
	{
		hHookMouse := SetWindowsHookEx(WH_MOUSE_LL	:= 14, RegisterCallback("OnMouseMove", "Fast"))
		ClipCursor(1)
	}
}
DisableMouseCapture()
{
	global hHookMouse
	If hHookMouse
	{
		UnhookWindowsHookEx(hHookMouse)
		hHookMouse := 0
		ClipCursor(0)
	}
}
OnMouseMove(nCode, wParam, lParam)
{
	Critical
	SetFormat, Integer, D
	If !nCode && (wParam = 0x201)
	{
		ClipCursor(1)
	}
	Return CallNextHookEx(nCode, wParam, lParam)
}

SetWindowsHookEx(idHook, pfn)
{
	Return DllCall("SetWindowsHookEx", "int", idHook, "Uint", pfn, "Uint", DllCall("GetModuleHandle", "Uint", 0), "Uint", 0)
}

ClipCursor(on)
{
	global left, top, right, bottom, hHookMouseWin
	if (on) {
		VarSetCapacity(rect, 16)
		
		DllCall("GetWindowRect", Ptr, hHookMouseWin, Ptr, &rect)
		left := NumGet(rect, 0, "Int")
		top := NumGet(rect, 4, "Int")
		right := NumGet(rect, 8, "Int")
		bottom := NumGet(rect, 12, "Int")
		Return DllCall("ClipCursor", Ptr, &rect)
		
	} else {
		Return DllCall("ClipCursor", Ptr, 0)
	}
}

UnhookWindowsHookEx(hHook)
{
	Return DllCall("UnhookWindowsHookEx", "Uint", hHook)
}

CallNextHookEx(nCode, wParam, lParam, hHook = 0)
{
	Return DllCall("CallNextHookEx", "Uint", hHook, "int", nCode, "Uint", wParam, "Uint", lParam)
}

Return
DoCleanup:
	DisableMouseCapture()
	ExitApp
