#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <WindowsConstants.au3>
#include <Constants.au3>
#Include <File.au3>
#include <Array.au3>
#include <GuiStatusBar.au3>
#include <GuiEdit.au3>
#include <ScrollBarConstants.au3>
#include <GuiButton.au3>

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
	Local $forever = 1
	Local $fromsession = False

	Local $MainSocket, $serverwindow, $ConnectedSocket, $szIP_Accepted, $recv, $Serverup, $msgsize, $varval
	Local $stepperwindow, $steppercode, $edit, $msg, $lineinput,$varwindow, $varlist, $nestinglabel, $varmoninput, $watchwindow, $varwlist
	Local $button_step, $button_over, $button_run
	Local $codeloaded, $file,$bufferfile, $location, $pauseline, $DebugLevel, $varlistcontents[1], $watchlistcontents[1]
	Local $regarray, $status, $watchidx
	Local $filecontents, $statusandline, $filepath, $linecontents[1]
	Local $KEYWORDS[22], $FUNCTIONS[2], $NESTLEVEL[2], $OPERATORS[13], $CURRENTNESTLEVEL, $LKEYWORD, $BREAKPOINTS[1]
	Local $watchtabs[4] = [3, 200,0,0]
	$NESTLEVEL[1] = 1
	$CURRENTNESTLEVEL = 1
	$varlistcontents[0] = 0
	$watchlistcontents[0] = 0
	$linecontents[0] = 0

	InitializeParserFunctions()
	InitializeWindows()
	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND") 
	Do
		$BREAKPOINTS[0] = 0
		checkcommandarg()
		Controller()
		GUICtrlSetData($edit, GUICtrlRead($edit) & @CRLF& "Client disconnected")
		_GUICtrlEdit_LineScroll($Edit, 0, _GUICtrlEdit_GetLineCount($Edit))
		MsgBox(0,"Program Termination", "Your lua program has ended")
		_GUICtrlListBox_ResetContent($steppercode)
		_GUICtrlListBox_ResetContent($varlist)
		$codeloaded = 0
		
	Until $forever == 0


Func InitializeWindows()
;	Read inifile if it exists, else write a new one with default values.
	If FileExists($inifile) Then
		$szIPADDRESS = IniRead($inifile, "server_config", "ip-address", $szIPADDRESS)
		$nPORT = IniRead($inifile, "server_config", "port", $nPORT)
		$DebugLevel = IniRead($inifile, "server_config", "debuglevel", $DebugLevel)
	Else
		IniWrite($inifile, "server_config", "ip-address", $szIPADDRESS)
		IniWrite($inifile, "server_config", "port", $nPORT)
		IniWrite($inifile, "server_config", "debuglevel", "0")
	EndIf

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
	If $watchwindow < 1 Then
		$watchwindow = GUICreate("Watches", 500, 355,10,600,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		$varwlist = GUICtrlCreateList("", 10, 10, 480, 280,BitOR($LBS_STANDARD, $LBS_USETABSTOPS))
		local $button = GUICtrlCreateButton("Remove selected variable from list", 10, 300, 180, 20)
		GUICtrlSetOnEvent(-1, "removewvar")
		local $button = GUICtrlCreateButton("Clear list", 390, 300, 100, 20)
		GUICtrlSetOnEvent(-1, "removeallvar")
		$lineinput = GUICtrlCreateLabel("Add manual variable:", 10, 330, 110, 20)
		$varmoninput = GUICtrlCreateInput("", 120, 330, 370, 20)
		GUICtrlSetOnEvent(-1, "addmanwvar")
		GUISetState(@SW_HIDE)
		_GUICtrlListBox_SetTabStops($varwlist, $watchtabs)
	EndIf
	If $varwindow < 1 Then
		$varwindow = GUICreate("Found variables", 300, 320,10,300,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME,$WS_EX_TOOLWINDOW))
		$varlist = GUICtrlCreateList("", 10, 10, 280, 280)
		local $button = GUICtrlCreateButton("copy to watchlist", 50, 295, 180, 20)
		GUICtrlSetOnEvent(-1, "copytowatch")
		GUISetState(@SW_HIDE)
	EndIf

	If $stepperwindow < 1 Then
		$stepperwindow = GUICreate("Code step Output frame", 600, 510,-1,-1,BitOR($WS_SYSMENU, $WS_CAPTION,$WS_MAXIMIZEBOX,$WS_MINIMIZEBOX,$WS_THICKFRAME))
		$steppercode = GUICtrlCreateList("", 10, 10, 580, 450,BitOR($WS_BORDER, $WS_VSCROLL, $LBS_NOTIFY, $LBS_DISABLENOSCROLL, $WS_HSCROLL))
		local $label = GUICtrlCreateLabel("Nestinglevel:", 10, 463, 110, 20)
		$nestinglabel = GUICtrlCreateLabel("[1]", 120, 463, 25, 20)
		$button_run = GUICtrlCreateButton("Run", 145, 460, 30, 20)
		GUICtrlSetOnEvent(-1, "steprun")
		$button_step = GUICtrlCreateButton("Step into", 176, 460, 55, 20)
		GUICtrlSetOnEvent(-1, "stepinto")
		$button_over = GUICtrlCreateButton("Step over", 231, 460, 55, 20)
		GUICtrlSetOnEvent(-1, "stepover")
		local $button = GUICtrlCreateButton("Add/del Breakpoint on selected line", 288, 460, 180, 20)
		GUICtrlSetOnEvent(-1, "breakpoint")
		local $button = GUICtrlCreateButton("Remove all breakpoints", 470, 460, 120, 20)
		GUICtrlSetOnEvent(-1, "allbreakpoints")
		$lineinput = GUICtrlCreateLabel("Send direct command:", 10, 488, 110, 20)
		$lineinput = GUICtrlCreateInput("", 120, 485, 280, 20)
		GUICtrlSetOnEvent(-1, "sendcommand")
		local $label = GUICtrlCreateLabel("Show/Hide:", 430, 488, 58, 20)
		local $button = GUICtrlCreateButton("variables", 490, 485, 50, 20)
		GUICtrlSetOnEvent(-1, "togglevariables")
		local $button = GUICtrlCreateButton("watches", 540, 485, 50, 20)
		GUICtrlSetOnEvent(-1, "togglewatches")
		GUISetState()
	EndIf
EndFunc


Func Controller()
	; Start The TCP Services
	;==============================================
	TCPStartup()

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

	$ServerUp = 1

	; Initialize a variable to represent a connection
	;==============================================
	$ConnectedSocket = -1

	GUICtrlSetData($edit,  GUICtrlRead($edit)& @CRLF & "Server listening on port > " & $nPORT)
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
			$recv = TCPRecv($MainSocket, 2048)
		EndIf

		If $fromsession == True Then
			WriteToConsole($szIP_Accepted & " > Started from within session" & @CRLF& $recv)
;			GUICtrlSetData($edit,GUICtrlRead($edit)& @CRLF &  $szIP_Accepted & " > Started from within session" & _
;			@CRLF& $recv)
			Sleep(2000)
			TCPSend($ConnectedSocket, "STEP\n")
			$recv = TCPRecv($MainSocket, 2048)
			$recv = TCPRecv($MainSocket, 2048)
			$fromsession = False
		Else
			TCPSend($ConnectedSocket, "STEP\n")
			$recv = TCPRecv($MainSocket, 2048)
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
;			$recv = StringLeft($recv, StringLen($recv)-1)
			$recv = StringRegExpReplace ( $recv, "\n", @CRLF)
			$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Paused \b(.+\D)(\W[$0-9]{1,3})(\W[$0-9]{1,3})",3)
			If Not IsArray($linecontents) Then
				$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Paused \b(.+\D)(\W[$0-9]{1,3})",3)
			EndIf
			If Not IsArray($linecontents) Then
				$linecontents = StringRegExp ($recv, "([0-9]{2,3}[\w]+)\b Error \b(.+\D)(\W[$0-9]{1,3})",3)
			EndIf
			
			;_ArrayDisplay($linecontents, "Reg expressions found")
			If IsArray($linecontents) Then 
				If UBound($linecontents) > 1 Then
					Switch $linecontents[0]
						Case "200"
							If Ubound($linecontents) > 2 Then
								$msgsize = $linecontents[2]
								$varval = $linecontents[3]
								;ConsoleWrite($varval)
							EndIf
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
			;ConsoleWrite("Status:"&$status&"< line:"&$pauseline&@CRLF)
			;ConsoleWrite("File:"&$file&"<"&@CRLF)
			If $status == "202" Or $status == "203" Then
				processluasource()
				if (Number($pauseline) > 0) & ($codeloaded == 1) then
					_GUICtrlListBox_SetCurSel($steppercode, Number($pauseline)-1)
					GUICtrlSetData($nestinglabel, "["&$NESTLEVEL[$pauseline]&"]")
					fetchvariable()
				endif
				If $status == "203" Then
					TCPSend($ConnectedSocket, "STEP\n")
				EndIf
			EndIf
			If $DebugLevel=="1" Then
				WriteToConsole($recv)
			EndIf
			
		EndIf
	WEnd
	If $ConnectedSocket <> -1 & $usertermination == False Then 
		local $berror = TCPCloseSocket($MainSocket)
		if $berror <> 1 Then
			MsgBox(0,"error"&@error,"failure by closing socket")
		EndIf
	Else
		TCPShutdown()
	EndIf
EndFunc   


Func analyzeokmsg($recmsg)
	Dim $lc[4]
	$lc[0] = StringLeft($recmsg,3)
	$lc[1] = StringMid($recmsg,5)
	local $tvar = $lc[1]
	If StringLen($tvar)> 4 Then
		$lc[1] = "OK"
		$lc[2] = StringMid($tvar,4,StringInStr($tvar, @CRLF)-1)
		$lc[3] = StringMid($tvar,StringInStr($tvar, @CRLF)+2)
	EndIf
	Return $lc
EndFunc

Func togglevariables()
	local $state = WinGetState($varwindow)
	If Not BitAnd($state, 2) Then
		GUISetState(@SW_SHOW, $varwindow)
	Else
		GUISetState(@SW_HIDE, $varwindow)
	EndIf
EndFunc


Func togglewatches()
	local $state = WinGetState($watchwindow)
	If Not BitAnd($state, 2) Then
		GUISetState(@SW_SHOW, $watchwindow)
	Else
		GUISetState(@SW_HIDE, $watchwindow)
	EndIf
EndFunc


Func removeallvar()
	_GUICtrlListBox_ResetContent($varwlist)
EndFunc	


Func sendcommand()
	TCPSend($ConnectedSocket, GUICtrlRead(@GUI_CtrlId)&@LF)
	GUICtrlSetData($edit, GUICtrlRead($edit) & @CRLF& "Sending ->" & GUICtrlRead(@GUI_CtrlId))
	_GUICtrlEdit_LineScroll($Edit, 0, _GUICtrlEdit_GetLineCount($Edit))
EndFunc


Func copytowatch()
	local $iIndex = _GUICtrlListBox_FindString($varwlist, _GUICtrlListBox_GetText($varlist, _GUICtrlListBox_GetCurSel($varlist)))
	If $iIndex < 0 Then
		Local $fetchedvar = _GUICtrlListBox_GetText($varlist, _GUICtrlListBox_GetCurSel($varlist))
		Local $sendvar = "EXEC return ("&StringMid($fetchedvar,2,StringLen($fetchedvar)-2)&")"
		$fetchedvar = $fetchedvar & @TAB&requestremotevariable($sendvar)
		ConsoleWrite($fetchedvar)
		_GUICtrlListBox_AddString($varwlist,$fetchedvar)
	EndIf
EndFunc


Func addmanwvar()
	
	local $iIndex = _GUICtrlListBox_FindString($varwlist, GUICtrlRead(@GUI_CtrlId))
	If 	$iIndex < 0 Then
		Local $sendvar = "EXEC return ("&GUICtrlRead(@GUI_CtrlId)&")"
		Local $fetchedvar = GUICtrlRead(@GUI_CtrlId) & @TAB & requestremotevariable($sendvar)
		_GUICtrlListBox_AddString($varwlist,$fetchedvar)
	EndIf
EndFunc


Func removewvar()
	_GUICtrlListBox_DeleteString($varwlist, _GUICtrlListBox_GetCurSel($varwlist))
EndFunc


Func requestremotevariable($sendvar)
		Local $varvalue = "Nil"
		Local $watchvarcontents
		Local $recbuf
    
		TCPSend($ConnectedSocket, $sendvar)
		Sleep(10)
		$recbuf = TCPRecv($MainSocket, 2048)
		$recbuf = StringRegExpReplace ( $recbuf, "\n", @CRLF)
		If $DebugLevel=="1" Then
			WriteToConsole("Fetchvar>"&$recbuf)
		EndIf
		If StringLeft($recbuf,3) == "200" Then
			$watchvarcontents = analyzeokmsg($recbuf)
		EndIf
		
		If IsArray($watchvarcontents) Then 
			If UBound($watchvarcontents) > 1 Then
				Switch $watchvarcontents[0]
					Case "401"
						;Variable has not been declared, ignore error
					Case "200"
						$varvalue = $watchvarcontents[3]
				EndSwitch
			EndIf
			$status = $watchvarcontents[0]
		EndIf
		Return $varvalue
EndFunc

Func fetchvariable()
	;Disable step buttons to prevent watchlist mess
	_GUICtrlButton_Enable($button_run, False)
	_GUICtrlButton_Enable($button_over, False)
	_GUICtrlButton_Enable($button_step, False)
	For $X = 0 To _GUICtrlListBox_GetCount($varwlist)
		local $watchvar = _GUICtrlListBox_GetText($varwlist, $X)
		local $wvararr = StringRegExp($watchvar, "^(.*)([\W])",3)
		If IsArray($wvararr) Then
			$watchvar = $wvararr[0]
			local $iIndex = _GUICtrlListBox_FindString($varwlist, $watchvar)
			Local $sendvar = "EXEC return ("&$watchvar&")"
			Local $varvalue = "Nil"
			$watchvar = $watchvar & @TAB&requestremotevariable($sendvar)
			If $iIndex < 0 Then
				_GUICtrlListBox_AddString($varwlist,$watchvar)
			Else
				_GUICtrlListBox_ReplaceString($varwlist,$iIndex,$watchvar)
			EndIf
		EndIf
	Next
	_GUICtrlButton_Enable($button_run)
	_GUICtrlButton_Enable($button_over)
	_GUICtrlButton_Enable($button_step)
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
	WriteToConsole($szIP_Accepted & " connected...")
	TCPSend($ConnectedSocket, "STEP\n")

EndFunc


Func handleconnect()
	If $ServerUp <> 0 Then
		local $berror = TCPCloseSocket($MainSocket)
		if $berror <> 1 Then
			MsgBox(0,"error"&@error,"failure by closing socket")
		EndIf
		
		TCPShutdown()
		$ConnectedSocket = -1
		$usertermination = True
		GUICtrlSetData($edit, GUICtrlRead($edit) &@CRLF&  "Server stopped")
		_GUICtrlEdit_LineScroll($Edit, 0, _GUICtrlEdit_GetLineCount($Edit))
		$ServerUp = 0
	Else
		TCPStartup()
		$MainSocket = TCPListen($szIPADDRESS, $nPORT)
		$usertermination = False
		GUICtrlSetData($edit, GUICtrlRead($edit) &@CRLF&  "Server started")
		_GUICtrlEdit_LineScroll($Edit, 0, _GUICtrlEdit_GetLineCount($Edit))
		$ServerUp = 1
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


Func allbreakpoints()
	For $X = 1 To $BREAKPOINTS[0]
			local $message = "DELB " & $bufferfile & " " & $BREAKPOINTS[$X]
			local $curline = _GUICtrlListBox_GetText($steppercode, ($BREAKPOINTS[$X]-1))
			$curline = StringMid($curline, 2)
			_GUICtrlListBox_ReplaceString($steppercode, ($BREAKPOINTS[$X]-1), $curline)
	Next
	ReDim $BREAKPOINTS[1]
	$BREAKPOINTS[0] = 0
EndFunc


Func breakpoint()
	If $ConnectedSocket <> -1 Then
		local $newbreakpoint = _GUICtrlListBox_GetCurSel($steppercode) + 1
		local $foundbreak = 0
		For $X = 1 To $BREAKPOINTS[0]
			ConsoleWrite(">"&$BREAKPOINTS[$X] &"<..>"&$newbreakpoint&"<"&@CRLF)
			If $newbreakpoint == $BREAKPOINTS[$X] Then
				$foundbreak = $X
				ExitLoop
			EndIf
		Next
		If NOT $foundbreak Then
			local $message = "SETB " & $bufferfile & " " & $newbreakpoint
			$BREAKPOINTS[0] = $BREAKPOINTS[0] + 1
			ReDim $BREAKPOINTS[($BREAKPOINTS[0]+1)]
;			ConsoleWrite("BOUND:"&Ubound($BREAKPOINTS)&@CRLF&"Set:"&$BREAKPOINTS[0]&@CRLF)
			$BREAKPOINTS[$BREAKPOINTS[0]] = $newbreakpoint
			local $curline = _GUICtrlListBox_GetText($steppercode, ($newbreakpoint-1))
			$curline = ">" & $curline
			_GUICtrlListBox_ReplaceString($steppercode, ($newbreakpoint-1), $curline)
			
		Else
			local $message = "DELB " & $bufferfile & " " & $newbreakpoint
			local $curline = _GUICtrlListBox_GetText($steppercode, ($newbreakpoint-1))
			$curline = StringMid($curline, 2)
			_GUICtrlListBox_ReplaceString($steppercode, ($newbreakpoint-1), $curline)
			If $BREAKPOINTS[0] == 1 Then
				ReDim $BREAKPOINTS[2]
			Else
				ReDim $BREAKPOINTS[$BREAKPOINTS[0]]
			EndIf
			$BREAKPOINTS[0] = $BREAKPOINTS[0] - 1
		EndIf
		If $DebugLevel == "1" Then
			WriteToConsole($message)
		EndIf
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
;		ConsoleWrite("file:"&$file&"<")
		If FileExists($file) Then
			If Not _FileReadToArray($file,$filecontents) Then
				local $message = "Error while reading file " & $file & @CRLF & "error:" & @error
				GUICtrlSetData($edit, $message & @CRLF & GUICtrlRead($edit))
				Return
			Else
				;Determine nestlevels. Ofcourse, the source-code will not be scanned for nesting errors
				;But ofcourse the Lua compiler should detect this before this debugger sees the code ;)
				ReDim $NESTLEVEL[$filecontents[0]+1]
				Local $NestDetection = 0
				_GUICtrlListBox_BeginUpdate($varlist)
				For $T = 1 To $filecontents[0]
;					ConsoleWrite($filecontents[0])
					$linecontents = $filecontents[$T]
					local $keywordext = StringRegExp($linecontents, "(\w{1,6})",3)
					If IsArray($keywordext) Then
						$LKEYWORD = $keywordext[0]
						$NestDetection = 0
						If $LKEYWORD == $KEYWORDS[19] Then
							local $variablestring = StringRegExp($linecontents, "\blocal\b(.*)(?:=)",3)
							If IsArray($variablestring) Then
;								ConsoleWrite($variablestring[0]&@CRLF)
								local $iIndex = _GUICtrlListBox_FindString($varlist, $variablestring[0])
								;ConsoleWrite($iIndex)
								If $iIndex < 0 Then
									_GUICtrlListBox_AddString($varlist,$variablestring[0] )								
								EndIf
							EndIf
						EndIf
						FOR $S = 1 To 6
;							ConsoleWrite (">"&$LKEYWORD&"< == >"& $KEYWORDS[$S]&"<?"&@CRLF)
							Switch $S
								Case 1 to 4
									If  $LKEYWORD == $KEYWORDS[$S] Then
;										_ArrayDisplay($keywordext, "Reg expressions found")
										If $T == 1 Then
											$NESTLEVEL[$T] = 2
										Else
											$NESTLEVEL[$T] = $CURRENTNESTLEVEL +1
										EndIf
										$NestDetection = 1
									EndIf
								Case 5,6
									If $LKEYWORD == $KEYWORDS[$S]  Then
;										_ArrayDisplay($keywordext, "Reg expressions found")
										If $T == 1 Then
											$NESTLEVEL[$T] = 2
										Else
											If $CURRENTNESTLEVEL > 1 Then ;Make sure "End" is not for a "Function" closer
												$NESTLEVEL[$T] = $CURRENTNESTLEVEL - 1
											EndIf
										EndIf
										$NestDetection = 1
									EndIf
							EndSwitch
							If $NestDetection Then
								$CURRENTNESTLEVEL = $NESTLEVEL[$T]
							Else
								$NESTLEVEL[$T] = $CURRENTNESTLEVEL
							EndIf
							;ConsoleWrite ("Current nestlevel>"&$CURRENTNESTLEVEL&@CRLF)
						Next
					EndIf
				Next
				_GUICtrlListBox_UpdateHScroll($varlist)
				_GUICtrlListBox_EndUpdate($varlist)
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

; Function to initialize parser functions.
;----------------------------------------------------------------------
Func InitializeParserFunctions()
	$KEYWORDS[0] = 21
	$KEYWORDS[1] = "if"
	$KEYWORDS[2] = "while"
	$KEYWORDS[3] = "repeat"
	$KEYWORDS[4] = "for"
	$KEYWORDS[5] = "until"
	$KEYWORDS[6] = "end"
	$KEYWORDS[7] = "function"
	$KEYWORDS[8] = "elseif"
	$KEYWORDS[9] = "else"
	$KEYWORDS[10] = "do"
	$KEYWORDS[11] = "then"
	$KEYWORDS[12] = "and"
	$KEYWORDS[13] = "nil"
	$KEYWORDS[14] = "false"
	$KEYWORDS[15] = "true"
	$KEYWORDS[16] = "in"
	$KEYWORDS[17] = "not"
	$KEYWORDS[18] = "or"
	$KEYWORDS[19] = "local"
	$KEYWORDS[20] = "return"
	$KEYWORDS[21] = "break"
	
	$OPERATORS[0] =12
	$OPERATORS[1] = "+"
	$OPERATORS[2] = "-"
	$OPERATORS[3] = "*"
	$OPERATORS[4] = "/"
	$OPERATORS[5] = "%"
	$OPERATORS[6] = "^"
	$OPERATORS[7] = "=="
	$OPERATORS[8] = "~="
	$OPERATORS[9] = "<"
	$OPERATORS[10] = "<="
	$OPERATORS[11] = ">"
	$OPERATORS[12] = ">="
EndFunc

;Catch the return key in the variable window to copy found locals to 
;the watchmonitor
Func WM_COMMAND($hWnd, $Msg, $wParam, $lParam)     
	Switch $hWnd
		Case $varwindow	
			If $wParam = 1 Then 
				copytowatch()
				Return $GUI_RUNDEFMSG 
			EndIf
	EndSwitch
EndFunc