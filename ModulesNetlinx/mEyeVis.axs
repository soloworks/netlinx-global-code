MODULE_NAME='mEyeVis'(DEV vdvControl, DEV tp[], DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/05/2013  AT: 00:06:28        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	MCE Control module for sending text command strings to a PC
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/

DEFINE_CONSTANT
LONG TLID_RETRY 				= 1
LONG TLID_INIT					= 2
LONG TLID_TIMEOUT				= 3
LONG TLT_RETRY[]				= {5000}		// 2.5 Mins between polls
LONG TLT_INIT[]				= {10000}
LONG TLT_TIMEOUT[]			= {5000}

INTEGER PRESET_COUNT = 10
INTEGER WINDOW_COUNT = 5

INTEGER COMMS_STATE_OFFLINE	= 0
INTEGER COMMS_STATE_TRYING		= 1
INTEGER COMMS_STATE_CONNECTED	= 2

DEFINE_TYPE STRUCTURE uEyeVis{
	// COMMS
	INTEGER 	IP_STATE
	INTEGER 	IP_PORT
	CHAR	 	IP_ADDRESS[15]
	INTEGER 	DEBUG
	CHAR 		RX[1000]
	CHAR		TX[1000]
	// 
	CHAR		WALL_NAME[20]
	CHAR		ACTIVE_PRESET[20]
	// STATE
	CHAR 		PRESET[PRESET_COUNT][25]
	INTEGER	TxPend
	CHAR		LastTxCmd[100]
	CHAR		LastTxParam[100]
}
DEFINE_TYPE STRUCTURE uWindow{
	CHAR ID[10]
	INTEGER TOP
	INTEGER LEFT
}

DEFINE_VARIABLE
VOLATILE uEyeVis myEyeVis
VOLATILE uWindow myWindows[WINDOW_COUNT]


/******************************************************************************
	Utlity Functions
******************************************************************************/

DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myEyeVis.IP_STATE == COMMS_STATE_OFFLINE){
		fnDebug(FALSE,"'Connecting on ',myEyeVis.IP_ADDRESS,':'",ITOA(myEyeVis.IP_PORT))
		myEyeVis.IP_STATE = COMMS_STATE_TRYING
		ip_client_open(dvDevice.port, myEyeVis.IP_ADDRESS, myEyeVis.IP_PORT, IP_TCP) 
	}
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnInit(){
	IF(!TIMELINE_ACTIVE(TLID_INIT)){
		TIMELINE_CREATE(TLID_INIT,TLT_INIT,LENGTH_ARRAY(TLT_INIT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_INIT]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myEyeVis.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnQueueCommand(CHAR pCMD[], CHAR pPARAM[]){
	STACK_VAR CHAR toSend[100]
	fnDebug(FALSE,'fnQueueCommand',pCMD)
	toSend = pCMD
	IF(LENGTH_ARRAY(pPARAM)){
		toSend = "toSend,'(',pPARAM,')'"
	}
	myEyeVis.Tx = "myEyeVis.Tx,toSend,$0D,$0A"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug(FALSE,'fnSendFromQueue','1')
	IF(FIND_STRING(myEyeVis.Tx,"$0D,$0A",1) && !myEyeVis.TxPend){
		STACK_VAR CHAR toSend[100]
		fnDebug(FALSE,'fnSendFromQueue','2')
		toSend = "REMOVE_STRING(myEyeVis.Tx,"$0D,$0A",1)"
		fnDebug(FALSE,'->EYE',toSend)
		SEND_STRING dvDevice,toSend
		IF(FIND_STRING(toSend,'(',1)){
			myEyeVis.LastTxCmd 	= fnStripCharsRight(REMOVE_STRING(toSend,'(',1),1)
			myEyeVis.LastTxParam = fnStripCharsRight(toSend,3)
		}
		ELSE{
			myEyeVis.LastTxCmd 	= fnStripCharsRight(toSend,2)
			myEyeVis.LastTxParam = ''
		}
		myEyeVis.TxPend = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
			TIMELINE_KILL(TLID_TIMEOUT)
		}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'EYE->',pDATA)
	fnDebug(FALSE,'fnProcessFeedback',myEyeVis.LastTxCmd)
	SWITCH(myEyeVis.LastTxCmd){
		CASE 'GetPresetList':{
			STACK_VAR INTEGER x
			FOR(x = 1; x <= PRESET_COUNT; x++){
				IF(myEyeVis.PRESET[x] = ''){
					myEyeVis.PRESET[x] = pDATA
					BREAK
				}
			}
		}
		CASE 'PlayPreset':{
			fnQueueCommand('GetActivePreset',myEyeVis.WALL_NAME)
		}
		CASE 'GetActivePreset':{
			STACK_VAR INTEGER x
			myEyeVis.ACTIVE_PRESET = pDATA
			FOR(x = 1; x <= WINDOW_COUNT; x++){
				myWindows[x].ID 	= ''
				myWindows[x].LEFT = 0
				myWindows[x].TOP 	= 0
			}
			SEND_STRING vdvControl, "'PRESET-',myEyeVis.ACTIVE_PRESET"
			fnQueueCommand('GetWindowList',"myEyeVis.WALL_NAME,',extend'")
		}
		CASE 'GetWindowList':{
			STACK_VAR INTEGER x
			FOR(x = 1; x <= WINDOW_COUNT; x++){
				IF(myWindows[x].ID == ''){
					myWindows[x].ID = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
					REMOVE_STRING(pDATA,',',1)	// sourceName
					REMOVE_STRING(pDATA,',',1)	// sourceType
					REMOVE_STRING(pDATA,',',1)	// SourceListID
					myWindows[x].LEFT = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
					myWindows[x].TOP  = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
					BREAK
				}
			}
		}
	}
}

DEFINE_FUNCTION fnLoadPresets(){
	STACK_VAR INTEGER x
	fnDebug(FALSE,'fnLoadPresets','')
	FOR(x = 1; x <= PRESET_COUNT; x++){
		myEyeVis.PRESET[x] = ''
	}
	fnQueueCommand('GetPresetList','')
	fnQueueCommand('GetActivePreset',myEyeVis.WALL_NAME)
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_START{
	CREATE_BUFFER dvDevice,myEyeVis.Rx
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR CMD[50]
		CMD = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(CMD){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':myEyeVis.WALL_NAME = DATA.TEXT
					CASE 'IP': 	  { 
						myEyeVis.IP_ADDRESS = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
						myEyeVis.IP_PORT = ATOI(DATA.TEXT)
						fnInit()
					}
					CASE 'DEBUG': { myEyeVis.DEBUG = (DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'PRESET':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':	fnQueueCommand('PlayPreset',DATA.TEXT)
					CASE 'INDEX':	fnQueueCommand('PlayPreset',myEyeVis.PRESET[ATOI(DATA.TEXT)])
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':fnLoadPresets()
				}
			}
			CASE 'RAW':{
				fnQueueCommand(DATA.TEXT,'')
			}
			CASE 'SOURCE':{
				
			}
		}
	}
}

DATA_EVENT[dvDevice]{
	ONLINE:{
		myEyeVis.IP_STATE = COMMS_STATE_CONNECTED
		myEyeVis.TxPend = TRUE	// Wait for prompt
		fnLoadPresets()
	}
	OFFLINE:{
		myEyeVis.IP_STATE = COMMS_STATE_OFFLINE
		myEyeVis.TX = ''
		myEyeVis.LastTxCmd = ''
		myEyeVis.LastTxParam = ''
		myEyeVis.TxPend = FALSE
		fnTryConnection();
	}
	ONERROR:{
		myEyeVis.IP_STATE = COMMS_STATE_OFFLINE
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(FALSE,  "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'IP Error:[',myEyeVis.IP_ADDRESS,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		IF(DATA.NUMBER != 14){
			fnTryConnection()
		}
	}
	STRING:{
		WHILE(FIND_STRING(myEyeVis.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myEyeVis.Rx,"$0D,$0A",1),2))
		}
		IF(RIGHT_STRING(myEyeVis.Rx,1) == '>'){
			fnDebug(FALSE,'EYE->',myEyeVis.Rx)
			myEyeVis.Rx = ''
			myEyeVis.TxPend = FALSE
			IF(myEyeVis.LastTxCmd == 'GetPresetList'){
				fnSetupPanel(0)
			}
			myEyeVis.LastTxCmd = ''
			myEyeVis.LastTxParam = ''
			fnSendFromQueue()
		}
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
			TIMELINE_KILL(TLID_TIMEOUT)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}


(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	[vdvControl, 251] = myEyeVis.IP_STATE = COMMS_STATE_CONNECTED
	[vdvControl, 252] = myEyeVis.IP_STATE = COMMS_STATE_CONNECTED
	[vdvControl, 255] = myEyeVis.IP_STATE = COMMS_STATE_CONNECTED
}

DEFINE_CONSTANT
INTEGER btnPreset[] = {
	101,102,103,104,105,
	106,107,108,109,110,
	111,112,113,114,115,
	116,117,118,119,120,
	121,122,123,124,125
}

DEFINE_FUNCTION fnSetupPanel(INTEGER pPanel){
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSetupPanel(p)
		}
		RETURN
	}
	ELSE{
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(btnPreset); x++){
			IF(LENGTH_ARRAY(myEyeVis.PRESET[x])){
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnPreset[x]),',0,',myEyeVis.PRESET[x]"
			}
			ELSE{
				BREAK
			}
		}
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnPreset[1]),'.',ITOA(btnPreset[x-1]),',1'"
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnPreset[x]),'.',ITOA(btnPreset[PRESET_COUNT]),',0'"
	}
}

DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		fnSetupPanel(GET_LAST(tp))
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnPreset]{
	PUSH:{
		fnQueueCommand('PlayPreset',myEyeVis.PRESET[GET_LAST(btnPreset)])
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER b
	FOR(b = 1; b <= LENGTH_ARRAY(btnPreset); b++){
		IF(LENGTH_ARRAY(myEyeVis.ACTIVE_PRESET)){
			[tp,btnPreset[b]] = (myEyeVis.ACTIVE_PRESET == myEyeVis.PRESET[b])
		}
	}
}

