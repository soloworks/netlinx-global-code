MODULE_NAME='mMCEControl'(DEV vdvControl, DEV vdvWOL, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	MCE Control module for sending text command strings to a PC
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/
DEFINE_TYPE STRUCTURE uMCE{
	CHAR		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	CONN_STATE
	INTEGER	DEBUG
	CHAR		MAC[12]
}

DEFINE_CONSTANT
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

LONG TLID_RETRY 				= 1

DEFINE_VARIABLE
VOLATILE uMCE myMCE

LONG TLT_RETRY[]				= {10000}

/******************************************************************************
	Utlity Functions
******************************************************************************/

DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,"'Connecting to MCE '","myMCE.IP_HOST,':',ITOA(myMCE.IP_PORT)")
	myMCE.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDevice.port, myMCE.IP_HOST, myMCE.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
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
	IF(myMCE.DEBUG || bForce)	{
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
							myMCE.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myMCE.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myMCE.IP_HOST = DATA.TEXT
							myMCE.IP_PORT = 5150
						}
						fnOpenTCPConnection()
					}
					CASE 'MAC':{
						myMCE.MAC = DATA.TEXT
					}
					CASE 'DEBUG': { myMCE.DEBUG = (DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						SEND_COMMAND vdvWOL,"'WOL-ASCII,',myMCE.MAC"
					}
					CASE 'OFF':{
						IF(myMCE.CONN_STATE == CONN_STATE_CONNECTED){
							SEND_STRING ipDevice, "'shutdown', $0D"
						}
					}
				}
			}
			CASE 'ACTION':{
				IF(myMCE.CONN_STATE == CONN_STATE_CONNECTED){
					SWITCH(CMD){
						CASE 'KEY': 		SEND_STRING ipDevice, "'key:', DATA.TEXT, $0D"
						CASE 'SHUTDOWN':	SEND_STRING ipDevice, "'shutdown', $0D"
						CASE 'RESTART':	SEND_STRING ipDevice, "'restart', $0D"
						CASE 'STANDBY':	SEND_STRING ipDevice, "'standby', $0D"
						CASE 'HIBERNATE':	SEND_STRING ipDevice, "'hibernate', $0D"
					}
				}
			}
			CASE 'PASS':{
				SEND_STRING ipDevice, "DATA.TEXT, $0D"
			}
		}
	}
}

DATA_EVENT[ipDevice]{
	ONLINE:{
		myMCE.CONN_STATE = CONN_STATE_CONNECTED
	}
	OFFLINE:{
		myMCE.CONN_STATE = CONN_STATE_OFFLINE
		fnReTryConnection()
	}
	ONERROR:{
		fnDebug(FALSE,"'MCE IP Error'","'[',ITOA(DATA.NUMBER),':',DATA.TEXT,']'")
		SWITCH(DATA.NUMBER){
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(FALSE, "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(TRUE,  "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(FALSE, "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(FALSE,  "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(FALSE, "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(FALSE, "'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
					CASE 15:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(FALSE,"'IP Error:[',myMCE.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myMCE.CONN_STATE = CONN_STATE_OFFLINE
				fnReTryConnection()
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl, 251] = (myMCE.CONN_STATE == CONN_STATE_CONNECTED)
	[vdvControl, 252] = (myMCE.CONN_STATE == CONN_STATE_CONNECTED)
}
/******************************************************************************
	EoF
******************************************************************************/