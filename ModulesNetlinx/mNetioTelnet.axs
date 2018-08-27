MODULE_NAME='mNetioTelnet'(DEV vdvOutput[], DEV ipPDU)
INCLUDE 'CustomFunctions'
/******************************************************************************
	MCE Control module for sending text command strings to a PC
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/
DEFINE_TYPE STRUCTURE uOutput{
	INTEGER POWER
}
DEFINE_TYPE STRUCTURE uNetio{
	CHAR		IP_HOST[255]
	INTEGER	IP_PORT
	CHAR     USERNAME[20]
	CHAR     PASSWORD[20]
	INTEGER	CONN_STATE
	INTEGER	DEBUG
	CHAR     PEND[50]
	CHAR		Rx[500]
	CHAR		Tx[500]
	uOutput  OUTPUT[4]
}

DEFINE_CONSTANT
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

LONG TLID_RETRY 				   = 1
LONG TLID_POLL 				   = 2
LONG TLID_COMMS 				   = 3

DEFINE_VARIABLE
VOLATILE uNetio myNetio

LONG TLT_RETRY[]				= {  5000 }
LONG TLT_POLL[]				= { 15000 }
LONG TLT_COMMS[]				= { 45000 }

/******************************************************************************
	Utlity Functions
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipPDU, myNetio.Rx
	myNetio.USERNAME = 'admin'
	myNetio.PASSWORD = 'passwd'
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,"'Connecting to NETIO '","myNetio.IP_HOST,':',ITOA(myNetio.IP_PORT)")
	myNetio.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipPDU.port, myNetio.IP_HOST, myNetio.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipPDU.port)
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
	IF(myNetio.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvOutput[1].Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[]){
	IF(myNetio.CONN_STATE == CONN_STATE_CONNECTED){
		myNetio.Tx = "myNetio.TX,pDATA,$0D,$0A"
		fnSendFromQueue()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(FIND_STRING(myNetio.TX,"$0D,$0A",1) && !LENGTH_ARRAY(myNetio.PEND)){
		myNetio.PEND = REMOVE_STRING(myNetio.Tx,"$0D,$0A",1)
		fnDebug(FALSE,'->Netio',myNetio.PEND)
		SEND_STRING ipPDU,myNetio.PEND
		myNetio.PEND = fnStripCharsRight(myNetio.PEND,2)
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('port list')
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)

DEFINE_EVENT DATA_EVENT[vdvOutput]{
	COMMAND:{

		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myNetio.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myNetio.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myNetio.IP_HOST = DATA.TEXT
							myNetio.IP_PORT = 1234
						}
						fnOpenTCPConnection()
					}
					CASE 'USERNAME': myNetio.USERNAME = DATA.TEXT
					CASE 'PASSWORD': myNetio.PASSWORD = DATA.TEXT
					CASE 'DEBUG': { myNetio.DEBUG = (DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'RAW':{
				SEND_STRING ipPDU, "DATA.TEXT, $0D"
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnAddToQueue("'port ',ITOA(GET_LAST(vdvOutput)),' 1'")
					CASE 'OFF':fnAddToQueue("'port ',ITOA(GET_LAST(vdvOutput)),' 0'")
				}
			}
		}
	}
}

DATA_EVENT[ipPDU]{
	ONLINE:{
		myNetio.CONN_STATE = CONN_STATE_CONNECTED
	}
	OFFLINE:{
		myNetio.CONN_STATE = CONN_STATE_OFFLINE
		myNetio.PEND = ''
		myNetio.Tx = ''
		fnReTryConnection()
	}
	ONERROR:{
		fnDebug(FALSE,"'PDU IP Error'","'[',ITOA(DATA.NUMBER),':',DATA.TEXT,']'")
		SWITCH(DATA.NUMBER){
			CASE 14:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(TRUE, "'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
					CASE 15:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(FALSE,"'PDU Error:[',myNetio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myNetio.CONN_STATE = CONN_STATE_OFFLINE
				myNetio.PEND = ''
				myNetio.Tx = ''
				fnReTryConnection()
			}
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myNetio.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myNetio.Rx,"$0D,$0A",1),2))
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'NETIO->',pDATA)
	IF(FIND_STRING(pDATA,'FORBIDDEN',1)){
		fnCloseTCPConnection()
	}
	ELSE IF(FIND_STRING(pDATA,'HELLO',1)){
		fnAddToQueue("'login ',myNetio.USERNAME,' ',myNetio.PASSWORD")
	}
	ELSE{
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
			CASE '250':{
				SWITCH(myNetio.PEND){
					CASE 'port list':{
						myNetio.OUTPUT[1].POWER = ATOI("pDATA[1]")
						myNetio.OUTPUT[2].POWER = ATOI("pDATA[2]")
						myNetio.OUTPUT[3].POWER = ATOI("pDATA[3]")
						myNetio.OUTPUT[4].POWER = ATOI("pDATA[4]")
						IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
						TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
			}
		}
	}
	myNetio.PEND = ''
	fnSendFromQueue()
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER o
	FOR(o = 1; o <= LENGTH_ARRAY(vdvOutput); o++){
		[vdvOutput[o],255] = (myNetio.OUTPUT[o].POWER)
	}
	[vdvOutput, 251] = ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvOutput, 252] = ( TIMELINE_ACTIVE(TLID_COMMS) )
}
/******************************************************************************
	EoF
******************************************************************************/

