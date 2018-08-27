MODULE_NAME='mLuxMate'(DEV vdvControl, DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/27/2013  AT: 14:39:01        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the VP-730

******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uLuxMate{
	(** System MetaData **)
	CHAR	 	VERSION[10]
	(** Comms **)
	INTEGER 	IP_STATE
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[128]
	INTEGER	iSIP
	INTEGER 	DEBUG
	CHAR 		Tx[500]
	CHAR 		Rx[500]
}
DEFINE_CONSTANT
LONG TLID_COMMS			= 1
LONG TLID_POLL				= 2
LONG TLID_RETRY 			= 3

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

DEFINE_VARIABLE
VOLATILE uLuxMate myLuxMate

LONG TLT_POLL[]  = {	 30000 }
LONG TLT_COMMS[] = {	 90000 }
LONG TLT_RETRY[] = {	  5000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myLuxMate.Rx
	myLuxMate.isIP = (!dvDevice.NUMBER)
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'CONN->LUX',"myLuxMate.IP_HOST,':',ITOA(myLuxMate.IP_PORT)")
	myLuxMate.IP_STATE = IP_STATE_CONNECTING
	ip_client_open(dvDevice.port, myLuxMate.IP_HOST, myLuxMate.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnTryConnection()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand('VERSION?')
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	STACK_VAR CHAR toSend[255]
	toSend = "$02,pCMD,$03"
	SEND_STRING dvDevice,toSend
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(FALSE,'LUX->',pData)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myLuxMate.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myLuxMate.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 E 7 1 485 DISABLE'
			fnInitPoll()
		}
		myLuxMate.IP_STATE = IP_STATE_CONNECTED
	}
	OFFLINE:{
		myLuxMate.IP_STATE = IP_STATE_OFFLINE
		fnTryConnection();
	}
	ONERROR:{
		SWITCH(DATA.NUMBER){			//Listening Error
			CASE 14:{
				fnDebug(FALSE,"'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")
			}
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(TRUE,  "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(TRUE,  "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 				//Local Port Already Used
					CASE 15:{fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(FALSE, "'LuxMate IP Error:[',myLuxMate.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myLuxMate.IP_STATE = IP_STATE_OFFLINE
				fnTryConnection()
			}
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myLuxMate.Rx,"$0D,$0A",1) > 0){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLuxMate.Rx,"$0D,$0A",1),2));
		}
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR pCOMMAND[100]
		pCOMMAND = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(pCOMMAND){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myLuxMate.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myLuxMate.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myLuxMate.IP_HOST = DATA.TEXT
							myLuxMate.IP_PORT = 6850
						}
						fnTryConnection()
						fnInitPoll()
					}
					CASE 'DEBUG': myLuxMate.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice, "$02,DATA.TEXT,$03"
			}
			CASE 'SCENE':{
				STACK_VAR CHAR ADD[10]
				ADD = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				fnSendCommand("ADD,'S',DATA.TEXT,'!'")
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
}