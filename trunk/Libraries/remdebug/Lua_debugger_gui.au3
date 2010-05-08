#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>

Opt('MustDeclareVars', 1)
Opt("GUIOnEventMode", 1)
;Opt("GUICoordMode", 2)
Opt("GUIResizeMode", 1)

;==============================================
;==============================================
;SERVER!! Start Me First !!!!!!!!!!!!!!!
;==============================================
;==============================================
	Local $szIPADDRESS = "127.0.0.1"
	Local $nPORT = 8171
	Local $MainSocket, $serverwindow, $stepperwindow, $steppercode, $edit, $ConnectedSocket, $szIP_Accepted
	Local $msg, $recv, $lineinput,$varwindow, $varlist
	local $codeloaded, $file,$bufferfile, $location, $pauseline
	local $forever = 1
Do
	$codeloaded = 0
	Example()
	MsgBox(0,"Program Termination", "Your lua program has ended")

Until $forever == 0

Func Example()
	; Set Some reusable info
	; Set your Public IP address (@IPAddress1) here.
;	Local $szServerPC = @ComputerName
;	Local $szIPADDRESS = TCPNameToIP($szServerPC)
;	Local $szIPADDRESS = @IPAddress1


	; Start The TCP Services
	;==============================================
	TCPStartup()

	; Create a Listening "SOCKET".
	;   Using your IP Address and Port 33891.
	;==============================================
	$MainSocket = TCPListen($szIPADDRESS, $nPORT)

	; If the Socket creation fails, exit.
	If $MainSocket = -1 Then Exit


	; Create a GUI for messages
	;==============================================
	If $serverwindow < 1 Then
		$serverwindow = GUICreate("Lua Debug server (IP: " & $szIPADDRESS & ")", 400, 200,10,10,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		GUISetOnEvent($GUI_EVENT_CLOSE, "closeprogram")
		$edit = GUICtrlCreateEdit("", 10, 10, 380, 180)
		GUISetState()
	EndIf
	If $varwindow < 1 Then
		$varwindow = GUICreate("Varwindow", 500, 300,10,300,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		$varlist = GUICtrlCreateEdit("", 10, 10, 480, 280)
		GUISetState()
	EndIf

	If $stepperwindow < 1 Then
		$stepperwindow = GUICreate("Code step Output frame", 600, 500,-1,-1,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		$steppercode = GUICtrlCreateList("", 10, 10, 580, 450,BitOR($WS_BORDER, $WS_VSCROLL, $LBS_NOTIFY, $LBS_DISABLENOSCROLL, $WS_HSCROLL))
		$lineinput = GUICtrlCreateLabel("Send direct command:", 10, 460, 280, 20)
		$lineinput = GUICtrlCreateInput("", 120, 460, 280, 20)
		GUICtrlSetOnEvent(-1, "sendcommand")
		local $button_step = GUICtrlCreateButton("Run", 120, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "steprun")
		local $button_step = GUICtrlCreateButton("Step into", 214, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "stepinto")
		local $button_step = GUICtrlCreateButton("Step over", 308, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "stepover")
		local $button_step = GUICtrlCreateButton("Set Breakpoint on current line", 402, 480, 188, 20)
		GUICtrlSetOnEvent(-1, "breakpoint")
		GUISetState()
	EndIf

	; Initialize a variable to represent a connection
	;==============================================
	$ConnectedSocket = -1


	;Wait for and Accept a connection
	;==============================================
	Do
		$ConnectedSocket = TCPAccept($MainSocket)
	Until $ConnectedSocket <> -1


	; Get IP of client connecting
	$szIP_Accepted = SocketToIP($ConnectedSocket)
	TCPSend($ConnectedSocket, "STEP\n")

	; GUI Message Loop
	;==============================================
	While 1
		$msg = GUIGetMsg()

		; GUI Closed
		;--------------------
		If $msg = $GUI_EVENT_CLOSE Then ExitLoop
		; Try to receive (up to) 2048 bytes
		;----------------------------------------------------------------
		$recv = TCPRecv($ConnectedSocket, 2048)

		; If the receive failed with @error then the socket has disconnected
		;----------------------------------------------------------------
		If @error Then 
			SetError(0)
			ExitLoop
		EndIf

		; Update the edit control with what we have received
		;----------------------------------------------------------------
		If $recv <> "" Then 
			$location = StringInStr($recv, "202 paused", 0)
			$file = StringMid($recv,$location+11)
			processluasource()
			if (Number($pauseline) > 0) & ($codeloaded == 1) then
				_GUICtrlListBox_SetCurSel($steppercode, Number($pauseline)-1)
			endif
			GUICtrlSetData($edit, _
				$szIP_Accepted & " > " & $recv & @CRLF & GUICtrlRead($edit))
		EndIf
	WEnd


	If $ConnectedSocket <> -1 Then TCPCloseSocket($ConnectedSocket)

	TCPShutdown()
EndFunc   

Func sendcommand()
	TCPSend($ConnectedSocket, GUICtrlRead(@GUI_CtrlId))
	GUICtrlSetData(3, "Sending ->" & GUICtrlRead(@GUI_CtrlId) & @CRLF & GUICtrlRead(3))

EndFunc
Func stepinto()
	TCPSend($ConnectedSocket, "STEP\n")
EndFunc
Func stepover()
	TCPSend($ConnectedSocket, "OVER\n")
EndFunc
Func steprun()
	TCPSend($ConnectedSocket, "RUN\n")
EndFunc
Func breakpoint()
	local $array = StringSplit($bufferfile, '/', 1)	
	local $breakpointfile = $array[UBound($array)-1]
	local $newbreakpoint = _GUICtrlListBox_GetCurSel($steppercode) + 1
	local $message = "SETB " &Chr(34)& $breakpointfile & CHR(34)&" " & $newbreakpoint
;	local $message = "SETB " & $bufferfile &" " & String($newbreakpoint)
	GUICtrlSetData($edit, _
	$szIP_Accepted & " > " & $message & @CRLF & GUICtrlRead($edit))
	TCPSend($ConnectedSocket, $message)
EndFunc
Func closeprogram()
	exit
EndFunc
Func processluasource()
	local $pauselocation = StringInStr($file, ".lua", 0) +5
	$pauseline = StringMid($file,$pauselocation)
	$pauseline = StringMid($pauseline, 1, StringLen($pauseline)-1)
	if $codeloaded <> 1 Then
		local $lualocation = StringInStr($file, ".lua", 0)
		local $tend = ($lualocation+3)
		local $linenum = 1
		if $location > 0 Then
			$file = StringMid($file,1,$tend)
			local $fileh = FileOpen($file, 0)

			; Check if file opened for reading OK
			If $fileh = -1 Then
				MsgBox(0, "Error", "Unable to open file.")
				return 
			Else
				$bufferfile = $file
			EndIf

			local $buffer = ""
			_GUICtrlListBox_BeginUpdate($steppercode)
			While 1
				local $line = FileReadLine($fileh)
				If @error = -1 Then ExitLoop
				$buffer = $linenum &"   " &$line ;& @CRLF
				_GUICtrlListBox_AddString($steppercode, $buffer)								
				$linenum = $linenum + 1
			Wend
			_GUICtrlListBox_UpdateHScroll($steppercode)
			_GUICtrlListBox_EndUpdate($steppercode)
			FileClose($fileh)
			$codeloaded = 1
		EndIf
	EndIf
EndFunc
; Function to return IP Address from a connected socket.
;----------------------------------------------------------------------
Func SocketToIP($SHOCKET)
	Local $sockaddr, $aRet
	
	$sockaddr = DllStructCreate("short;ushort;uint;char[8]")

	$aRet = DllCall("Ws2_32.dll", "int", "getpeername", "int", $SHOCKET, _
			"ptr", DllStructGetPtr($sockaddr), "int*", DllStructGetSize($sockaddr))
	If Not @error And $aRet[0] = 0 Then
		$aRet = DllCall("Ws2_32.dll", "str", "inet_ntoa", "int", DllStructGetData($sockaddr, 3))
		If Not @error Then $aRet = $aRet[0]
	Else
		$aRet = 0
	EndIf

	$sockaddr = 0

	Return $aRet
EndFunc   ;==>SocketToIP