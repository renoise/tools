#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#Include <File.au3>
#include <Array.au3>
#include <GuiStatusBar.au3>
#include <GuiEdit.au3>
#include <ScrollBarConstants.au3>

Opt('MustDeclareVars', 1)
Opt("GUIOnEventMode", 1)
Opt("GUIResizeMode", 1)
;==============================================
;==============================================
;controller_gui for Kepler's remote lua debugger
;Requires adapted version that accepts spaces
;in folder and file structures.
;
;Written by Vincent Voois, May 2010
;( http://tinyurl.com/vvrns )
;Copyright using Lua MIT license
;==============================================
;==============================================

;==============================================
;SERVER!! Start Me First !!!!!!!!!!!!!!!
;==============================================
	Local $szIPADDRESS = "0.0.0.0"
	Local $nPORT = 8171
	Local $usertermination = False
	Local $inifile = "controller_gui.ini"
	Local $MainSocket, $serverwindow, $ConnectedSocket, $szIP_Accepted, $recv
	Local $stepperwindow, $steppercode, $edit, $msg, $lineinput,$varwindow, $varlist
	Local $codeloaded, $file,$bufferfile, $location, $pauseline
	Local $regarray, $status, $watchidx
	Dim $filecontents, $statusandline, $filepath, $linecontents
	Local $forever = 1
	Local $fromsession = False

	InitializeWindows()
	Do
		$codeloaded = 0
		checkcommandarg()
		Controller()
		GUICtrlSetData($edit, "Client disconnected" & @CRLF & GUICtrlRead($edit))
		MsgBox(0,"Program Termination", "Your lua program has ended")

	Until $forever == 0

Func InitializeWindows()
;	Read inifile if it exists, else write a new one with default values.
	If FileExists($inifile) Then
		$szIPADDRESS = IniRead($inifile, "server_config", "ip-address", $szIPADDRESS)
		$nPORT = IniRead($inifile, "server_config", "port", $nPORT)
	Else
		IniWrite($inifile, "server_config", "ip-address", $szIPADDRESS)
		IniWrite($inifile, "server_config", "port", $nPORT)
	EndIf
	; Start The TCP Services
	;==============================================
	TCPStartup()

	; Create a GUI for messages
	;==============================================
	If $serverwindow < 1 Then
		local $inADDR = "ANY"
		If $szIPADDRESS <> "0.0.0.0" Then
			$inADDR = $szIPADDRESS
		EndIf
		$serverwindow = GUICreate("Lua Debug server (IP: " & $inADDR & " / port:" &$nPORT& ")", 450, 220,10,10,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		GUISetOnEvent($GUI_EVENT_CLOSE, "closeprogram")
		$edit = GUICtrlCreateEdit("", 10, 10, 430, 180)
		local $button_clear_log = GUICtrlCreateButton("Clear logwindow", 20, 195, 94, 20)
		GUICtrlSetOnEvent(-1, "clearlog")
		local $button_handle_connect = GUICtrlCreateButton("Start/stop server", 178, 195, 94, 20)
		GUICtrlSetOnEvent(-1, "handleconnect")
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
		$lineinput = GUICtrlCreateLabel("Send direct command:", 10, 460, 110, 20)
		$lineinput = GUICtrlCreateInput("", 120, 460, 280, 20)
		GUICtrlSetOnEvent(-1, "sendcommand")
		local $button_step = GUICtrlCreateButton("Run", 120, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "steprun")
		local $button_step = GUICtrlCreateButton("Step into", 214, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "stepinto")
		local $button_step = GUICtrlCreateButton("Step over", 308, 480, 94, 20)
		GUICtrlSetOnEvent(-1, "stepover")
		local $button_step = GUICtrlCreateButton("Set Breakpoint on selected line", 402, 480, 188, 20)
		GUICtrlSetOnEvent(-1, "breakpoint")
		GUISetState()
	EndIf
EndFunc
Func Controller()

	; Create a Listening "SOCKET".
	;   Using your IP Address and Port 33891.
	;==============================================
	$MainSocket = TCPListen($szIPADDRESS, $nPORT)

	; If the Socket creation fails, exit.
	If $MainSocket = -1 Then 
		MsgBox(0,"Network Error", "Error creating socket on port " & $nPORT & _
		@CRLF & "Please check your network configuration"&@CRLF& _
		@CRLF&"This application will now be closed")
		Exit
	EndIf

	; Initialize a variable to represent a connection
	;==============================================
	$ConnectedSocket = -1

	GUICtrlSetData($edit, "Server listening on port > " & $nPORT & @CRLF & GUICtrlRead($edit))
	listen()

	; GUI Message Loop
	;==============================================
	While 1
		$msg = GUIGetMsg()

		; GUI Closed
		;--------------------
		If $msg = $GUI_EVENT_CLOSE Then ExitLoop
		If 	$ConnectedSocket <> -1 Then
			; Try to receive (up to) 2048 bytes
			;----------------------------------------------------------------
			$recv = TCPRecv($ConnectedSocket, 2048)
		EndIf

		If $fromsession == True Then
			GUICtrlSetData($edit, $szIP_Accepted & " > Started from within session" & _
			@CRLF& $recv & @CRLF & GUICtrlRead($edit))
			Sleep(2000)
			TCPSend($ConnectedSocket, "STEP\n")
			$recv = TCPRecv($ConnectedSocket, 2048)
			$recv = TCPRecv($ConnectedSocket, 2048)
			$fromsession = False
		EndIf
		; If the receive failed with @error then the socket has disconnected
		;----------------------------------------------------------------
		If @error Then 
			SetError(0)
			ExitLoop
		EndIf

		; Update the edit control with what we have received
		;----------------------------------------------------------------
		If $recv <> "" Then 
			$recv = StringLeft($recv, StringLen($recv)-1)
			$recv = StringRegExpReplace ( $recv, "\n", @CRLF)
			$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Paused \b(.+\D)(\W[$0-9]{1,3})(\W[$0-9]{1,3})",3)
			If Not IsArray($linecontents) Then
				$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Paused \b(.+\D)(\W[$0-9]{1,3})",3)
			EndIf
			If Not IsArray($linecontents) Then
				$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Error \b(.+\D)(\W[$0-9]{1,3})",3)
			EndIf
			
;			_ArrayDisplay($linecontents, "Reg expressions found")
			If IsArray($linecontents) Then 
				If UBound($linecontents) > 1 Then
					Switch $linecontents[0]
						Case "202"
							$file = $linecontents[1]
							$pauseline = $linecontents[2]
						Case "203"
							$file = $linecontents[1]
							$pauseline = $linecontents[2]
							$watchidx = $linecontents[3]
					EndSwitch
				EndIf
				$status = $linecontents[0]
			EndIf
			ConsoleWrite("Status:"&$status&"< line:"&$pauseline&@CRLF)
			ConsoleWrite("File:"&$file&"<"&@CRLF)
			If $status == "202" Then
				processluasource()
				if (Number($pauseline) > 0) & ($codeloaded == 1) then
					_GUICtrlListBox_SetCurSel($steppercode, Number($pauseline)-1)
				endif
			EndIf
			WriteToConsole($recv)
			
		EndIf
	WEnd


	If $ConnectedSocket <> -1 & $usertermination == False Then TCPCloseSocket($ConnectedSocket)

	TCPShutdown()
EndFunc   

Func sendcommand()
	TCPSend($ConnectedSocket, GUICtrlRead(@GUI_CtrlId))
	GUICtrlSetData(3, "Sending ->" & GUICtrlRead(@GUI_CtrlId) & @CRLF & GUICtrlRead(3))

EndFunc
Func WriteToConsole($contents)
; Write to our own console window and automatically scroll down.
	GUICtrlSetData($edit, GUICtrlRead($edit) &@CRLF&  $szIP_Accepted & " > " & $contents)
	_GUICtrlEdit_LineScroll($Edit, 0, _GUICtrlEdit_GetLineCount($Edit))
EndFunc
Func Listen()
	;Wait for and Accept a connection
	;==============================================
	Do
		$ConnectedSocket = TCPAccept($MainSocket)
	Until $ConnectedSocket <> -1


	; Get IP of client connecting
	$szIP_Accepted = SocketToIP($ConnectedSocket)
	WriteToConsole($szIP_Accepted)
	TCPSend($ConnectedSocket, "STEP\n")

EndFunc
Func handleconnect()
	If $ConnectedSocket <> -1 Then
		TCPCloseSocket($ConnectedSocket)
		TCPShutdown()
		$ConnectedSocket = -1
		$usertermination = True
	Else
		TCPStartup()
		$MainSocket = TCPListen($szIPADDRESS, $nPORT)
		$usertermination = False
	EndIf	
EndFunc

Func clearlog()
	GUICtrlSetData(3, "")
EndFunc
Func stepinto()
	If $ConnectedSocket <> -1 Then
		TCPSend($ConnectedSocket, "STEP\n")
	Else
		noconnecterror()
	EndIf	
EndFunc
Func stepover()
	If $ConnectedSocket <> -1 Then
		TCPSend($ConnectedSocket, "OVER\n")
	Else
		noconnecterror()
	EndIf	
EndFunc
Func steprun()
	If $ConnectedSocket <> -1 Then
		TCPSend($ConnectedSocket, "RUN\n")
	Else
		noconnecterror()
	EndIf	
EndFunc
Func breakpoint()
	If $ConnectedSocket <> -1 Then
		local $newbreakpoint = _GUICtrlListBox_GetCurSel($steppercode) + 1
		local $message = "SETB " & $bufferfile & " " & $newbreakpoint
		WriteToConsole($message)
		TCPSend($ConnectedSocket, $message)
	Else
		noconnecterror()
	EndIf	
EndFunc
Func noconnecterror()
	local $message = "No clients connected!"& @CRLF & "Please insert a ' require "&Chr(34)&"remdebug.engine"&Chr(34) _
	&" ' line in your Lua routine"&@CRLF&"and add a ' remdebug.engine.start() ' line into" & _
	" your code where you want to break first."&@CRLF& "The run your Lua application until it hits the break."
	WriteToConsole($message)
EndFunc
Func closeprogram()
	exit
EndFunc
Func processluasource()
	if $codeloaded <> 1 Then
		local $linenum = 1
		ConsoleWrite("file:"&$file&"<")
		If FileExists($file) Then
			If Not _FileReadToArray($file,$filecontents) Then
				local $message = "Error while reading file " & $file & @CRLF & "error:" & @error
				GUICtrlSetData($edit, $message & @CRLF & GUICtrlRead($edit))
				Return
			Else
				$bufferfile = $file
			EndIf

			local $buffer = ""
			_GUICtrlListBox_BeginUpdate($steppercode)
			for $x = 1 To $filecontents[0]
				local $line = $filecontents[$x]
				$buffer = $linenum &"   " &$line ;& @CRLF
				_GUICtrlListBox_AddString($steppercode, $buffer)								
				$linenum = $linenum + 1
			Next
			_GUICtrlListBox_UpdateHScroll($steppercode)
			_GUICtrlListBox_EndUpdate($steppercode)
			$codeloaded = 1
		EndIf
	EndIf
EndFunc
Func grabvariables()
	for $x = 1 To $filecontents[0]
		local $line = $filecontents[$x]
		
		$buffer = $linenum &"   " &$line ;& @CRLF
;		_GUICtrlListBox_AddString($steppercode, $buffer)								
	Next	
EndFunc
Func checkcommandarg()
	For $x = 1 To $CmdLine[0]
		If $CmdLine[$x] == "--from-session" Then
			$fromsession = True
		EndIf
	Next
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