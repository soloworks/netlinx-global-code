MODULE_NAME='mPhoneTouch10UI'(DEV vdvTouch10[], DEV vdvPhone[])
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic Phone Interface Module
******************************************************************************/
/******************************************************************************
	System Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER chnMicMute	= 198
INTEGER chnAudMute	= 199
INTEGER chnRINGING	= 236
INTEGER chnOFFHOOK 	= 238
INTEGER chnACTIVE 	= 240
/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uGUI{
	INTEGER 	ID						// Which Phone Object currently controlled
	CHAR 		DisplayString[50] // String to display in text box on GUI
}
DEFINE_TYPE STRUCTURE uPhone{
	CHAR 		SpeedDialName[10][50]	// Preset Labels
	CHAR 		SpeedDialNumber[10][50]	// Preset Numbers
	CHAR     DialNumber[50]          // Number to dial
	CHAR		LastNumber[50]				// Last Dialed Number
	INTEGER  IsOffHook               // Phone OnHook Status
	INTEGER  IsRinging               // Phone Ringing Status

}
DEFINE_VARIABLE
VOLATILE uGUI 		myT10GUI[5]
VOLATILE uPhone 	myT10Phone[5]
/******************************************************************************
	Button Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER addDisplayString = 51

INTEGER btnKeypad[]  = {
	101,102,103,	// 1, 2, 3
	104,105,106,	// 4, 5, 6
	107,108,109,	// 7, 8, 9
	110,111,112		// 0, *, #
}



INTEGER btnBack			= 113
INTEGER btnClear   		= 114
INTEGER btnDial			= 115
INTEGER btnHangup			= 116
INTEGER btnAnswer			= 117
INTEGER btnRedial			= 118
INTEGER btnDialAnswer	= 119
INTEGER btnCommands[]	={
	btnBack,btnClear,btnDial,btnHangup,btnAnswer,btnRedial,btnDialAnswer
}

INTEGER btnPrivacy	= 201		// Mute Mics into Phone
INTEGER btnRinging	= 202
INTEGER btnOffHook	= 203
INTEGER btnMute		= 204

INTEGER btnLinkGUI[] = {
	501,502,503,504,505
}

// Preset Code to Follow
INTEGER addSpeedDialName[]		= { 901, 902, 903, 904, 905, 906, 907, 908, 909, 910}
INTEGER addSpeedDialNumber[]	= { 921, 922, 923, 924, 925, 926, 927, 928, 929, 920}
INTEGER btnSpeedDialRecall[] 	= { 951, 952, 953, 904, 955, 956, 957, 958, 959, 960}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDialNumber(INTEGER p, CHAR ThisNumber[]){
	myT10Phone[myT10GUI[p].ID].DialNumber = ThisNumber
	SEND_COMMAND vdvPhone[p], "'DIAL-',myT10Phone[myT10GUI[p].ID].DialNumber"
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,Dialing ',myT10Phone[myT10GUI[p].ID].DialNumber"
}

DEFINE_FUNCTION fnHangup(INTEGER p){
	IF(myT10Phone[myT10GUI[P].ID].LastNumber <> myT10Phone[myT10GUI[p].ID].DialNumber && myT10Phone[myT10GUI[p].ID].DialNumber <> ''){
		myT10Phone[myT10GUI[P].ID].LastNumber = myT10Phone[myT10GUI[p].ID].DialNumber
	}
	IF(myT10Phone[myT10GUI[p].ID].IsOffHook){
		myT10GUI[p].DisplayString = 'Hanging Up...'
		SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
	}
	SEND_COMMAND vdvPhone[p], "'DIAL-HANGUP'"
}

DEFINE_FUNCTION fnAddDigit(INTEGER p, CHAR x[]){
	myT10GUI[p].DisplayString = "myT10GUI[p].DisplayString,x"
	IF (LENGTH_ARRAY(myT10GUI[p].DisplayString) > 25) myT10GUI[p].DisplayString = MID_STRING(myT10GUI[p].DisplayString,2,50)
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
}
DEFINE_FUNCTION fnRemoveDigit(INTEGER p){
	myT10GUI[p].DisplayString = LEFT_STRING(myT10GUI[p].DisplayString,LENGTH_ARRAY(myT10GUI[p].DisplayString)-1)
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
}

DEFINE_FUNCTION fnRecallSpeedDial(INTEGER p, INTEGER x){
	myT10GUI[p].DisplayString = myT10Phone[myT10GUI[p].ID].SpeedDialNumber[x];
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
}

DEFINE_FUNCTION fnSendSpeedDialsToGUI(INTEGER p, INTEGER x){
	IF(p == 0){
		STACK_VAR INTEGER pPanel
		FOR(pPanel = 1; pPanel <= LENGTH_ARRAY(vdvTouch10); pPanel++){
			fnSendSpeedDialsToGUI(pPanel,x)
		}
		RETURN
	}
	IF(x == 0){
		STACK_VAR INTEGER pSpeedDial
		FOR(pSpeedDial = 1; pSpeedDial <= LENGTH_ARRAY(btnSpeedDialRecall); pSpeedDial++){
			fnSendSpeedDialsToGUI(p,pSpeedDial)
		}
		RETURN
	}

	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_SpeedDialName[',ITOA(x),'],'  ,myT10Phone[myT10GUI[p].ID].SpeedDialName[x]"
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_SpeedDialNumber[',ITOA(x),'],',myT10Phone[myT10GUI[p].ID].SpeedDialNumber[x]"
	SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_SpeedDialRecall[',ITOA(x),'],',myT10Phone[myT10GUI[p].ID].SpeedDialName[x],$0A,myT10Phone[myT10GUI[p].ID].SpeedDialNumber[x]"
}
/******************************************************************************
	Preset Interface Events
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[vdvTouch10,btnSpeedDialRecall]{
	PUSH:{
		fnRecallSpeedDial(GET_LAST(vdvTouch10),GET_LAST(btnSpeedDialRecall))
	}
}
/******************************************************************************
	Interface Events
******************************************************************************/
DEFINE_START{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(vdvTouch10); p++){
		myT10GUI[p].ID = 1
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT
DATA_EVENT[vdvTouch10]{
	ONLINE:{
		STACK_VAR INTEGER p
		p = GET_LAST(vdvTouch10)
		SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
		fnSendSpeedDialsToGUI(p,0)
	}
	COMMAND:{
		STACK_VAR INTEGER p
		STACK_VAR CHAR pDATA[256]
		p = GET_LAST(vdvTouch10)//eg. 'CONTROL-SET_SpeedDial,1,07776689161,Glyn'
		pDATA = DATA.TEXT
		SEND_STRING 0, "'vdvTouch10[',ITOA(p),'] Command Raw-> ',pDATA"
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'-',1),1)){
			CASE 'SET':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
					CASE 'DisplayString':{
						myT10GUI[p].DisplayString = pDATA
					}
					CASE 'SpeedDial':{
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						myT10Phone[p].SpeedDialNumber[x] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myT10Phone[p].SpeedDialName[x] = pDATA
						fnSendSpeedDialsToGUI(0,x)
					}
					CASE 'LinkGUI':{
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						myT10GUI[x].ID = ATOI(pDATA)
					}
				}
			}
			CASE 'PRESS':{
				STACK_VAR CHAR pACTION[32]
				IF(FIND_STRING(pDATA,',',1)){
					pACTION = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
				}ELSE{
					pACTION = pDATA
				}
				SEND_STRING 0, "'vdvTouch10[',ITOA(p),'] PRESS, pACTION-> ',pACTION"
				SWITCH(pACTION){
					CASE 'Keypad':{
						fnAddDigit(p,pDATA)
						IF([vdvPhone[myT10GUI[p].ID],chnOFFHOOK]){
							myT10Phone[myT10GUI[p].ID].LastNumber = myT10GUI[p].DisplayString
							//fnDialNumber(myT10GUI[p].ID,MID_STRING(myT10GUI[p].DisplayString,LENGTH_ARRAY(myT10GUI[p].DisplayString),1))
							SEND_COMMAND vdvPhone[myT10GUI[p].ID], "'DTMF-',MID_STRING(myT10GUI[p].DisplayString,LENGTH_ARRAY(myT10GUI[p].DisplayString),1)"
						}
					}
					CASE 'Mute':{
						SEND_COMMAND vdvPhone[myT10GUI[p].ID],'MUTE-TOGGLE'
					}
					CASE 'Privacy':{
						SEND_COMMAND vdvPhone[myT10GUI[p].ID],'MICMUTE-TOGGLE'
					}
					CASE 'Clear':{
						myT10GUI[p].DisplayString = '';
						SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
					}
					CASE 'Back':{
						IF(myT10GUI[p].DisplayString <> ''){
							fnRemoveDigit(p)
						}
					}
					CASE 'Green':{
						IF(myT10Phone[myT10GUI[p].ID].IsRinging){
							SEND_COMMAND vdvPhone[myT10GUI[p].ID],'DIAL-ANSWER'
						}
						ELSE IF(myT10Phone[myT10GUI[p].ID].IsOffHook){
							SEND_COMMAND DATA.DEVICE,'Dial'
						}
						ELSE{
							IF(LENGTH_ARRAY(myT10GUI[p].DisplayString)){
								myT10Phone[myT10GUI[p].ID].LastNumber = myT10GUI[p].DisplayString
								fnDialNumber(myT10GUI[p].ID,myT10GUI[p].DisplayString)
							}
						}
					}
					CASE 'Dial':{
						IF(LENGTH_ARRAY(myT10GUI[p].DisplayString)){
							fnDialNumber(myT10GUI[p].ID,myT10GUI[p].DisplayString)
						}
					}
					CASE 'Red':
					CASE 'Hangup':{
						myT10GUI[p].DisplayString = '';
						SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
						fnHangup(myT10GUI[p].ID)
					}
					CASE 'Answer':{
						SEND_COMMAND vdvPhone[myT10GUI[p].ID],'DIAL-ANSWER'
					}
					CASE 'Redial':{
						myT10GUI[p].DisplayString = myT10Phone[myT10GUI[p].ID].LastNumber
						SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
						IF( ![vdvPhone[myT10GUI[p].ID],chnOFFHOOK] AND (LENGTH_ARRAY(myT10GUI[p].DisplayString) > 0) ) fnDialNumber(p,myT10GUI[p].DisplayString);
					}
					CASE 'DialAnswer':{
						IF(myT10Phone[myT10GUI[p].ID].IsOffHook){
							SEND_COMMAND DATA.DEVICE,'Hangup'
						}
						ELSE{
							SEND_COMMAND DATA.DEVICE,'Dial'
						}
					}
				}
			}
		}
	}
}
DATA_EVENT[vdvPhone]{
	STRING:{
		STACK_VAR INTEGER p
		p = GET_LAST(vdvPhone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SET_SpeedDial':{
				STACK_VAR INTEGER x
				x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				myT10Phone[p].SpeedDialNumber[x] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				myT10Phone[p].SpeedDialName[x] = DATA.TEXT
				fnSendSpeedDialsToGUI(0,x)
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvPhone,chnOFFHOOK]{
	OFF:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(vdvTouch10); p++){
			IF(myT10GUI[p].ID == GET_LAST(vdvPhone)){
				myT10GUI[p].DisplayString = ''
				myT10Phone[p].IsOffHook = 0
				SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
				SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_OffHookStatus,',ITOA(myT10Phone[p].IsOffHook)"
			}
		}
	}
	ON:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(vdvTouch10); p++){
			IF(myT10GUI[p].ID == GET_LAST(vdvPhone)){
				myT10Phone[p].IsOffHook = 1
				SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_OffHookStatus,',ITOA(myT10Phone[p].IsOffHook)"
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvPhone,chnRINGING]{
	ON:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(vdvTouch10); p++){
			IF(myT10GUI[p].ID == GET_LAST(vdvPhone)){
				myT10GUI[p].DisplayString = 'Incoming Call...';
				SEND_STRING vdvTouch10[p],"'FEEDBACK-','SET_DisplayString,',myT10GUI[p].DisplayString"
			}
		}
	}
}
/******************************************************************************
	Interface Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(vdvTouch10); p++){
		STACK_VAR INTEGER d
		FOR(d = 1; d <= LENGTH_ARRAY(vdvPhone) ; d++){
			[vdvPhone[d],p] = (myT10GUI[p].ID == d)
		}
		IF(myT10GUI[p].ID){
			[vdvTouch10[p],btnRINGING] 	= [vdvPhone[myT10GUI[p].ID],chnRINGING]
			[vdvTouch10[p],btnOFFHOOK] 	= [vdvPhone[myT10GUI[p].ID],chnOFFHOOK]
			[vdvTouch10[p],btnDialAnswer] = [vdvPhone[myT10GUI[p].ID],chnOFFHOOK]
			[vdvTouch10[p],btnPrivacy]    = [vdvPhone[myT10GUI[p].ID],chnMicMute]
			[vdvTouch10[p],btnMute]   	 	= [vdvPhone[myT10GUI[p].ID],chnAudMute]

			myT10Phone[myT10GUI[p].ID].IsRinging 	= [vdvPhone[myT10GUI[p].ID],chnRINGING]
			myT10Phone[myT10GUI[p].ID].IsOffHook 	= [vdvPhone[myT10GUI[p].ID],chnOFFHOOK]
		}
	}
}

/******************************************************************************
	EoF
******************************************************************************/