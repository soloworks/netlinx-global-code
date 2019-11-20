MODULE_NAME='mDeltaPlayer'(DEV vdvControl, DEV ipDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/08/2013  AT: 12:04:43        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	3Delta Control Module
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/
DEFINE_TYPE STRUCTURE uDelta{
	(** System State **)
	INTEGER VOLUME
	CHAR FILE[128]
	(** Comms **)
	INTEGER PORT
	CHAR IP[128]
	INTEGER TRYING
	INTEGER CONNECTED
	INTEGER DEBUG
	CHAR Rx[1000]
}
DEFINE_VARIABLE
VOLATILE uDelta myDelta

LONG TLT_RETRY[]				= {10000}		//
LONG TLT_POLL[]				= {15000}		// Polling
LONG TLT_COMMS[]				= {60000}		// Polling

DEFINE_CONSTANT
LONG TLID_RETRY 				= 1
LONG TLID_POLL 				= 2
LONG TLID_COMMS 				= 3
INTEGER defPORT				= 23

/******************************************************************************
	Utlity Functions
******************************************************************************/

DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!myDelta.PORT){myDelta.PORT = defPORT}
	fnDebug(FALSE,'Connecting to Delta on ',"myDelta.IP,':',ITOA(myDelta.PORT)")
	myDelta.TRYING = TRUE
	ip_client_open(ipDevice.port, myDelta.IP, myDelta.PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myDelta.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	fnDebug(FALSE,'AMX->DELTA',"pCMD,$0D")
	SEND_STRING ipDevice,"pCMD,$0D"
	fnInitPoll()
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'DELTA->AMX',pDATA)
	SWITCH(pDATA){
		CASE 'READY':{
			myDelta.CONNECTED = TRUE
			myDelta.TRYING = FALSE
			fnPoll()
			fnInitPoll()
		}
		DEFAULT:{
			IF(FIND_STRING(pDATA,':',1)){
				STACK_VAR CHAR PARAM[255]
				PARAM = fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
				PARAM = fnRemoveTrailingWhiteSpace(PARAM)
				SWITCH(PARAM){
					CASE 'AUDIOLEVEL':{ myDelta.VOLUME = ATOI(pDATA) }
					CASE 'FILE':{
						IF(myDelta.FILE != fnRemoveWhiteSpace(pDATA)){
							myDelta.FILE = fnRemoveWhiteSpace(pDATA)
							SEND_STRING vdvControl, "'FILE-',myDelta.FILE"
						}
					}
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnDebug(FALSE,'AMX->DELTA',"'STATUS',$0D")
	SEND_STRING ipDevice,"'STATUS',$0D"

}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_START{
	CREATE_BUFFER ipDevice, myDelta.Rx
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP': 	  { myDelta.IP = DATA.TEXT; fnTryConnection(); }
					CASE 'DEBUG': { myDelta.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY':	fnSendCommand("'PLAY'")
					CASE 'STOP':	fnSendCommand("'STOP'")
					CASE 'PAUSE':	fnSendCommand("'PAUSE'")
				}
			}
			CASE 'SEQUENCE': 	fnSendCommand("'SEQUENCE "', DATA.TEXT, '"'")
			CASE 'LOAD': 		fnSendCommand("'LOAD "', DATA.TEXT, '"'")
			CASE 'HIDE':		fnSendCommand("'VIDEOLEVEL 0'")
			CASE 'SHOW':		fnSendCommand("'VIDEOLEVEL 100'")
			CASE 'RAW':
			CASE 'PASS':		fnSendCommand("DATA.TEXT")
			CASE 'VOLUME':		fnSendCommand("'AUDIOLEVEL ', DATA.TEXT")
		}
	}
}

DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{

	}
	OFFLINE:{
		myDelta.CONNECTED = FALSE;
		myDelta.TRYING = FALSE;
		fnTryConnection();
	}
	ONERROR:{
		myDelta.CONNECTED = FALSE
		myDelta.TRYING = FALSE
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'3Delta IP Error:[',myDelta.IP,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		fnTryConnection()
	}
	STRING:{
		WHILE(FIND_STRING(myDelta.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myDelta.Rx,"$0D,$0A",1),2))
		}
	}
}

/******************************************************************************
	Volume Interface Control
******************************************************************************/
/*
DEFINE_CONSTANT
INTEGER lvlVol = 1

DEFINE_EVENT BUTTON_EVENT[tp,lvlVol]{
	PUSH:		myDeltaTPs[GET_LAST(tp)].HELD = TRUE
	RELEASE:	myDeltaTPs[GET_LAST(tp)].HELD = FALSE
}
DEFINE_EVENT LEVEL_EVENT[tp,lvlVol]{
	IF(myDeltaTPs[GET_LAST(tp)].HELD){
		myDelta.VOLUME = LEVEL.VALUE
		fnSendCommand("'AUDIOLEVEL ',ITOA(myDelta.VOLUME)")
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		IF(!myDeltaTPs[p].HELD){
			SEND_LEVEL tp[p],lvlVol,myDelta.VOLUME
		}
	}
}
*/
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}