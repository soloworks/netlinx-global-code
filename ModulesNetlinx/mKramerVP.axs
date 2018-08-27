MODULE_NAME='mKramerVP'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the VP-796A
******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uKramerVP{
	(** Comms **)
	INTEGER 	isIP
	CHAR 		IP_HOST[128]
	INTEGER 	IP_PORT
	INTEGER	CONN_STATE
	INTEGER	PEND
	INTEGER 	DEBUG
	CHAR 		Tx[500]
	CHAR 		Rx[500]
	CHAR     LAST_Tx[25]
	
	INTEGER  MAIN_INPUT
}
DEFINE_CONSTANT
LONG TLID_SEND_TIMEOUT	= 1
LONG TLID_POLL				= 2
LONG TLID_COMMS			= 3
LONG TLID_RETRY 			= 4

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

DEFINE_VARIABLE
VOLATILE uKramerVP myKramerVP
LONG TLT_SEND_TIMEOUT[] = {5000}
LONG TLT_POLL[]  = { 15000 }
LONG TLT_COMMS[] = { 90000 }
LONG TLT_RETRY[] = { 10000 }		// 
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myKramerVP.Rx
	myKramerVP.isIP = (!dvDevice.NUMBER)
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	SWITCH(myKramerVP.CONN_STATE){
		CASE CONN_STATE_OFFLINE:{
			fnDebug(DEBUG_DEV,'fnOpenTCPConnection() Connect->KRA',"myKramerVP.IP_HOST,':',ITOA(myKramerVP.IP_PORT)")
			myKramerVP.CONN_STATE = CONN_STATE_CONNECTING
			myKramerVP.PEND = TRUE
			ip_client_open(dvDevice.port, myKramerVP.IP_HOST, myKramerVP.IP_PORT, IP_TCP)
		}
		CASE CONN_STATE_CONNECTING:{
			fnDebug(DEBUG_DEV,'fnOpenTCPConnection()','Already Connecting')
		}
		CASE CONN_STATE_CONNECTED:{
			fnDebug(DEBUG_DEV,'fnOpenTCPConnection()','Already Connected')
		}
	}
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(DEBUG_DEV,'fnCloseTCPConnection()','Closing')
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnDebug(DEBUG_DEV,'TLID_RETRY','Created')
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnDebug(DEBUG_DEV,'TLID_RETRY','Called')
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug(DEBUG_DEV,'TLID_POLL','Called')
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnQueueQuery('main_input')
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnQueueCommand( CHAR pCMD[], CHAR pValue[] ){
	myKramerVP.Tx = "myKramerVP.Tx,'set ',pCMD,' ',pValue,$0D"
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnQueueQuery( CHAR pCMD[] ){
	myKramerVP.Tx = "myKramerVP.Tx,'get ',pCMD,$0D"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myKramerVP.CONN_STATE == CONN_STATE_CONNECTED && !myKramerVP.PEND && FIND_STRING(myKramerVP.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[50]
		toSend = REMOVE_STRING(myKramerVP.Tx,"$0D",1)
		fnDebug(FALSE,'->KRA',toSend)
		SEND_STRING dvDevice, toSend
		myKramerVP.LAST_Tx = toSend
		myKramerVP.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_SEND_TIMEOUT)){ TIMELINE_KILL(TLID_SEND_TIMEOUT) }
		TIMELINE_CREATE(TLID_SEND_TIMEOUT,TLT_SEND_TIMEOUT,LENGTH_ARRAY(TLT_SEND_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_SEND_TIMEOUT]{
	fnDebug(DEBUG_DEV,'TLID_SEND_TIMEOUT','Called')
	myKramerVP.Tx = ''
	myKramerVP.LAST_Tx = ''
	myKramerVP.PEND = FALSE
	IF(myKramerVP.isIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(DEBUG_STD,'KRA->',pData)
	IF(LEFT_STRING(pDATA,5) == 'READY'){
		fnDebug(DEBUG_DEV,'fnProcessFeedback()','"READY" Found')
		myKramerVP.PEND = FALSE
		fnPoll()
		fnInitPoll()
		fnSendFromQueue()
	}
	ELSE IF(LEFT_STRING(pDATA,2) == 'OK'){
		fnDebug(DEBUG_DEV,'fnProcessFeedback()','"OK" Found')
		IF(FIND_STRING(pDATA,',',1)){
			// Response from Query
			GET_BUFFER_STRING(pDATA,3)
			IF(myKramerVP.LAST_tx == 'get main_input'){
				myKramerVP.MAIN_INPUT = ATOI(pDATA)
			}
		}
		ELSE{
			// Response from Action
			IF(LEFT_STRING(myKramerVP.LAST_tx,14) == 'set main_input'){
				REMOVE_STRING(myKramerVP.LAST_tx,' ',1)	// Pull 'set'
				REMOVE_STRING(myKramerVP.LAST_tx,' ',1)	// Pull 'main_input'
				myKramerVP.MAIN_INPUT = ATOI(myKramerVP.LAST_tx)
			}
		}
		myKramerVP.LAST_Tx = ''
		myKramerVP.PEND = FALSE
		fnSendFromQueue()
	}
	
	IF(TIMELINE_ACTIVE(TLID_SEND_TIMEOUT)){ TIMELINE_KILL(TLID_SEND_TIMEOUT) }
	
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnDebug(INTEGER bLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myKramerVP.DEBUG >= bLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myKramerVP.CONN_STATE = CONN_STATE_CONNECTED
		IF(myKramerVP.isIP){
			// Do nothing here as waiting for Ready response
		}
		ELSE{
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 115200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myKramerVP.CONN_STATE = CONN_STATE_OFFLINE
		myKramerVP.PEND = FALSE
		fnTryConnection();
	}
	ONERROR:{		
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(DEBUG_ERR, "'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(DEBUG_ERR, "'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(DEBUG_STD,"'Kramer IP Error:[',myKramerVP.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{
				myKramerVP.CONN_STATE = CONN_STATE_OFFLINE
				fnTryConnection()
			}
		}
	}
	STRING:{
		fnDebug(DEBUG_DEV,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myKramerVP.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myKramerVP.Rx,"$0D,$0A",1),2))
		}
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP': 	  { 
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myKramerVP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myKramerVP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myKramerVP.IP_HOST = DATA.TEXT
							myKramerVP.IP_PORT = 30000 
						}
						fnOpenTCPConnection()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': myKramerVP.DEBUG = DEBUG_STD
							CASE 'DEV':  myKramerVP.DEBUG = DEBUG_DEV
							DEFAULT:     myKramerVP.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice, "DATA.TEXT,$0D"
			}
			CASE 'INPUT':{
				fnQueueCommand('main_input',DATA.TEXT)
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
}
/******************************************************************************
	EoF
******************************************************************************/