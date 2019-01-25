MODULE_NAME='mPhoneUI'(DEV tp[], DEV vdvPhone[])
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
INTEGER chnOFFHOOK 	= 238
INTEGER chnRINGING	= 240
/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uGUI{
	CHAR 		DIALSTRING[50]
	INTEGER 	ID						// Which Phone Object currently controlled
}
DEFINE_TYPE STRUCTURE uPhone{
	CHAR 		SpeedDialName[10][50]	// Preset Labels
	CHAR 		SpeedDialNumber[10][50]	// Preset Numbers
	CHAR		LastNumber[50]				// Last Dialed Number

}
DEFINE_VARIABLE
VOLATILE uGUI 		myGUI[5]
VOLATILE uPhone 	myPhone[5]
/******************************************************************************
	Button Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER addDialString = 51

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
	SEND_COMMAND vdvPhone[p], "'DIAL-',ThisNumber"
}

DEFINE_FUNCTION fnHangup(INTEGER p){
	SEND_COMMAND vdvPhone[p], "'DIAL-HANGUP'"
}

DEFINE_FUNCTION fnAddDigit(INTEGER p, CHAR x[]){
	myGUI[p].DIALSTRING = "myGUI[p].DIALSTRING,x"
	IF (LENGTH_ARRAY(myGUI[p].DIALSTRING) > 25) myGUI[p].DIALSTRING = MID_STRING(myGUI[p].DIALSTRING,2,50)
	SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
}
DEFINE_FUNCTION fnRemoveDigit(INTEGER p){
	myGUI[p].DIALSTRING = LEFT_STRING(myGUI[p].DIALSTRING,LENGTH_ARRAY(myGUI[p].DIALSTRING)-1)
	SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
}

DEFINE_FUNCTION fnRecallSpeedDial(INTEGER p, INTEGER x){
	myGUI[p].DIALSTRING = myPhone[myGUI[p].ID].SpeedDialNumber[x];
	SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
}

DEFINE_FUNCTION fnSendSpeedDialsToGUI(INTEGER p, INTEGER x){
	IF(p == 0){
		STACK_VAR INTEGER pPanel
		FOR(pPanel = 1; pPanel <= LENGTH_ARRAY(tp); pPanel++){
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

	SEND_COMMAND tp[p],"'^TXT-',ITOA(addSpeedDialName[x]),   ',0, ',myPhone[myGUI[p].ID].SpeedDialName[x]"
	SEND_COMMAND tp[p],"'^TXT-',ITOA(addSpeedDialNumber[x]), ',0, ',myPhone[myGUI[p].ID].SpeedDialNumber[x]"
	SEND_COMMAND tp[p],"'^TXT-',ITOA(btnSpeedDialRecall[x]), ',0, ',myPhone[myGUI[p].ID].SpeedDialName[x],$0A,myPhone[myGUI[p].ID].SpeedDialNumber[x]"
}
/******************************************************************************
	Preset Interface Events
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnSpeedDialRecall]{
	PUSH:{
		fnRecallSpeedDial(GET_LAST(tp),GET_LAST(btnSpeedDialRecall))
	}
}
/******************************************************************************
	Interface Events
******************************************************************************/
DEFINE_START{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		myGUI[p].ID = 1
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnLinkGUI]{
	PUSH:{
		myGUI[GET_LAST(tp)].ID = GET_LAST(btnLinkGUI)
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnKeypad]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SWITCH(GET_LAST(btnKeypad)){
			CASE 10:		fnAddDigit(p,'0');	//0
			CASE 11:		fnAddDigit(p,'*');	//Asterix
			CASE 12: 	fnAddDigit(p,'#');	//Hash
			DEFAULT: 	fnAddDigit(p,ITOA(GET_LAST(btnKeypad)))
		}
		IF([vdvPhone[myGUI[p].ID],chnOFFHOOK]){
			myPhone[myGUI[p].ID].LastNumber = myGUI[p].DIALSTRING
			//fnDialNumber(myGUI[p].ID,MID_STRING(myGUI[p].DIALSTRING,LENGTH_ARRAY(myGUI[p].DIALSTRING),1))
			SEND_COMMAND vdvPhone[myGUI[p].ID], "'DTMF-',MID_STRING(myGUI[p].DIALSTRING,LENGTH_ARRAY(myGUI[p].DIALSTRING),1)"
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnMute]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SEND_COMMAND vdvPhone[myGUI[p].ID],'MUTE-TOGGLE'
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCommands]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE btnClear:{
				myGUI[p].DIALSTRING = '';
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
			}
			CASE btnBack:{fnRemoveDigit(p)}
			CASE btnDial:{
				IF(LENGTH_ARRAY(myGUI[p].DIALSTRING)){
					myPhone[myGUI[p].ID].LastNumber = myGUI[p].DIALSTRING
					fnDialNumber(myGUI[p].ID,myGUI[p].DIALSTRING)
				}
			}
			CASE btnHangup:{
				myGUI[p].DIALSTRING = '';
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
				fnHangup(myGUI[p].ID)
			}
			CASE btnAnswer:{
				SEND_COMMAND vdvPhone[myGUI[p].ID],'DIAL-ANSWER'
			}
			CASE btnRedial:{
				myPhone[myGUI[p].ID].LastNumber = myGUI[p].DIALSTRING
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
				IF( ![vdvPhone[myGUI[p].ID],chnOFFHOOK] AND (LENGTH_ARRAY(myGUI[p].DIALSTRING) > 0) ) fnDialNumber(p,myGUI[p].DIALSTRING);
			}
			CASE btnDialAnswer:{
				IF([vdvPhone[myGUI[p].ID],chnOFFHOOK]){
					DO_PUSH(BUTTON.INPUT.DEVICE,btnHangup)
				}
				ELSE{
					DO_PUSH(BUTTON.INPUT.DEVICE,btnDial)
				}
			}
		}
	}
	HOLD[10]:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE btnBack:{
				myGUI[p].DIALSTRING = '';
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
			}
		}
	}
}
DATA_EVENT[tp]{
	ONLINE:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
		fnSendSpeedDialsToGUI(p,0)
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DATA_EVENT[vdvPhone]{
	STRING:{
		STACK_VAR INTEGER p
		p = GET_LAST(vdvPhone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SET_SPEEDDIAL':{
				STACK_VAR INTEGER x
				x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				myPhone[p].SpeedDialNumber[x] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				myPhone[p].SpeedDialName[x] = DATA.TEXT
				fnSendSpeedDialsToGUI(0,x)
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvPhone,chnOFFHOOK]{
	OFF:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			IF(myGUI[p].ID == GET_LAST(vdvPhone)){
				myGUI[p].DIALSTRING = '';
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvPhone,chnRINGING]{
	ON:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			IF(myGUI[p].ID == GET_LAST(vdvPhone)){
				myGUI[p].DIALSTRING = '';
				SEND_COMMAND tp[p],"'^TXT-',ITOA(addDialString),',0,',myGUI[p].DIALSTRING"
			}
		}
	}
}
/******************************************************************************
	Interface Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		STACK_VAR INTEGER d
		FOR(d = 1; d <= LENGTH_ARRAY(vdvPhone) ; d++){
			[vdvPhone[d],p] = (myGUI[p].ID == d)
		}
		IF(myGUI[p].ID){
			[tp[p],btnRINGING] 	 = [vdvPhone[myGUI[p].ID],chnRINGING]
			[tp[p],btnOFFHOOK] 	 = [vdvPhone[myGUI[p].ID],chnOFFHOOK]
			[tp[p],btnDialAnswer] = [vdvPhone[myGUI[p].ID],chnOFFHOOK]
			[tp[p],btnPrivacy]    = [vdvPhone[myGUI[p].ID],chnMicMute]
			[tp[p],btnMute]   	 = [vdvPhone[myGUI[p].ID],chnAudMute]
		}

	}
}


