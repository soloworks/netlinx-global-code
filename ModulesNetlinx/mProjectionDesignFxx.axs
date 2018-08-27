MODULE_NAME='mProjectionDesignFxx'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/*******************************************************************
	Projection Design Control Module
********************************************************************/

DEFINE_TYPE STRUCTURE uFxx{
	(** Comms **)
	INTEGER isIP
	INTEGER IP_PORT
	CHAR 	  IP_HOST[128]
	INTEGER DEBUG
	INTEGER CONN_STATE
	CHAR    Tx[1000]
	CHAR    Rx[1000]
	INTEGER PEND
	(** State **)
	INTEGER POWER
	INTEGER SHUTTER
}
DEFINE_CONSTANT
LONG TLID_POLL 	= 1
LONG TLID_COMMS	= 2
LONG TLID_RETRY	= 3

INTEGER CONN_STATE_OFFLINE    = 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED  = 2

DEFINE_VARIABLE
LONG TLT_POLL[] 	= { 45000 }
LONG TLT_SEND[] 	= {   100 }
LONG TLT_COMMS[]	= { 60000 }
LONG TLT_RETRY[] 	= { 10000 }
uFxx myFxx

DEFINE_START{
	myFxx.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myFxx.Rx
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myFxx.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 19200 N,8,1 485 DISABLE'
		}
		myFxx.CONN_STATE = CONN_STATE_CONNECTED
		fnPoll()
	}
	OFFLINE:{
		myFxx.CONN_STATE = CONN_STATE_OFFLINE
		myFxx.Tx = ''
		myFxx.PEND = FALSE
		IF(myFxx.isIP){ fnTryConnection() }
	}
	ONERROR:{
		myFxx.Tx = ''
		myFxx.PEND = FALSE
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{
				myFxx.CONN_STATE = CONN_STATE_OFFLINE
				fnTryConnection()
			}
		}
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE, "'Fxx Error IP Error:[',myFxx.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		// Proven for IP control
		WHILE(FIND_STRING(myFxx.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myFxx.Rx,"$0D,$0A",1),3))
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	// Debug Out
	fnDebug(FALSE,'Fxx->',pData)
	// Check is response
	SWITCH(GET_BUFFER_CHAR(pData)){
		CASE '%':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pData,' ',1),1)){
				CASE '001':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pData,' ',1),1)){
						CASE 'SHUT':{
							myFxx.SHUTTER = ATOI(pData)
						}
						CASE 'POWR':{
							myFxx.POWER = ATOI(pData)
						}
					}
				}
			}
		}
	}
	myFxx.PEND = FALSE
	fnSendFromQueue()
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('POWR','?')
	fnAddToQueue('SHUT','?')
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						myFxx.DEBUG = (DATA.TEXT == 'TRUE')
					}
					CASE 'IP':{
						myFxx.IP_HOST = DATA.TEXT
						myFxx.IP_PORT = 1025
						fnOpenTCPConnection()
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2))
			}
			CASE 'VMUTE':{
				IF(myFxx.POWER){
					SWITCH(DATA.TEXT){
						CASE 'ON': 		myFxx.SHUTTER = TRUE
						CASE 'OFF':		myFxx.SHUTTER = FALSE
						CASE 'TOGGLE':	myFxx.SHUTTER = !myFxx.SHUTTER
					}
					fnAddToQueue('SHUT',ITOA(myFxx.SHUTTER))
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myFxx.POWER = TRUE
					CASE 'OFF':		myFxx.POWER = FALSE
					CASE 'TOGGLE':	myFxx.POWER = !myFxx.POWER
				}
				fnAddToQueue('POWR',ITOA(myFxx.POWER))
			}
		}
	}
}


DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], CHAR pMOD[]){
	myFxx.Tx = "myFxx.TX,':',pCMD,pMOD,$0D"
	fnSendFromQueue()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(FIND_STRING(myFxx.TX,"$0D",1) && !myFxx.PEND && myFxx.CONN_STATE == CONN_STATE_CONNECTED){
		STACK_VAR CHAR toSend[20]
		toSend = REMOVE_STRING(myFxx.Tx,"$0D",1)
		fnDebug(FALSE,'->Fxx',toSend)
		SEND_STRING dvDevice,toSend
		myFxx.PEND = TRUE
	}
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myFxx.DEBUG || bForce){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'Connecting to Fxx on ',"myFxx.IP_HOST,':',ITOA(myFxx.IP_PORT)")
	myFxx.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myFxx.IP_HOST, myFxx.IP_PORT, IP_TCP)
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
	fnOpenTCPConnection()
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/