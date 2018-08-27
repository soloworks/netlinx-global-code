MODULE_NAME='mRakoIP'(DEV vdvControl, DEV ipBridge)
INCLUDE 'CustomFunctions'
/******************************************************************************
	MCE Control module for sending text command strings to a PC
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/
DEFINE_TYPE STRUCTURE uRako{
	CHAR		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	CONN_STATE
	INTEGER	DEBUG
	CHAR		Rx[500]
}

DEFINE_CONSTANT
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

LONG TLID_RETRY 				   = 1

DEFINE_VARIABLE
VOLATILE uRako myRako

LONG TLT_RETRY[]				= {10000}

/******************************************************************************
	Utlity Functions
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipBridge, myRako.Rx
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,"'Connecting to Rako '","myRako.IP_HOST,':',ITOA(myRako.IP_PORT)")
	myRako.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipBridge.port, myRako.IP_HOST, myRako.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipBridge.port)
}

DEFINE_FUNCTION fnReTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myRako.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR CMD[50]
		CMD = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(CMD){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myRako.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myRako.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myRako.IP_HOST = DATA.TEXT
							myRako.IP_PORT = 9761
						}
						fnOpenTCPConnection()
					}
					CASE 'DEBUG': { myRako.DEBUG = (DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'SCENE':{
				STACK_VAR CHAR pMSG[100]
				pMSG = "'ro:',fnGetCSV(DATA.TEXT,1)"
				pMSG = "pMSG,'&ch:',fnGetCSV(DATA.TEXT,2)"
				pMSG = "pMSG,'&sc:',fnGetCSV(DATA.TEXT,3),$0D,$0A"
				fnDebug(TRUE,'->RAKO',pMSG)
				SEND_STRING ipBridge,pMSG
			}
			CASE 'RAW':{
				SEND_STRING ipBridge, "DATA.TEXT, $0D,$0A"
			}
		}
	}
}

DATA_EVENT[ipBridge]{
	ONLINE:{
		myRako.CONN_STATE = CONN_STATE_CONNECTED
	}
	OFFLINE:{
		myRako.CONN_STATE = CONN_STATE_OFFLINE
		fnReTryConnection()
	}
	ONERROR:{
		fnDebug(FALSE,"'MCE IP Error'","'[',ITOA(DATA.NUMBER),':',DATA.TEXT,']'")
		SWITCH(DATA.NUMBER){
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(TRUE, "'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
					CASE 15:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(FALSE,"'IP Error:[',myRako.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myRako.CONN_STATE = CONN_STATE_OFFLINE
				fnReTryConnection()
			}
		}
	}
	STRING:{
		fnDebug(TRUE,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myRako.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myRako.Rx,"$0D,$0A",1),2))
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(TRUE,'RAKO->',pDATA)
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE '>':{
			// Ready for Command
		}
		CASE '<':{
			// BiDir Interface Recieve
			STACK_VAR CHAR pMSG[50]
			STACK_VAR CHAR pCMD[50]
			// Add Room
			pMSG = "fnGetSplitStringValue(pDATA,':',1),','"
			// Add Channel
			pMSG = "pMsg,fnGetSplitStringValue(pDATA,':',2)"
			// Build Command type
			SWITCH(fnGetSplitStringValue(pDATA,':',3)){
				CASE '049':pCMD = 'SCENE'
				CASE '052':pCMD = 'LEVEL'
			}
			IF(fnGetSplitStringValue(pDATA,':',4) != ''){
				pMSG = "pMsg,',',fnGetSplitStringValue(pDATA,':',4)"
			}			
			
			fnDebug(TRUE,pCMD,pMSG)
			SEND_STRING vdvControl,"pCMD,'-',pMSG"
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl, 251] = (myRako.CONN_STATE == CONN_STATE_CONNECTED)
	[vdvControl, 252] = (myRako.CONN_STATE == CONN_STATE_CONNECTED)
}
/******************************************************************************
	EoF
******************************************************************************/
