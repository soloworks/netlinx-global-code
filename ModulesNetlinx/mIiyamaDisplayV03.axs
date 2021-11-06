MODULE_NAME='mIiyamaDisplayV03'(DEV vdvControl,DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module for:
	- TExx03
	- TExx04

	- Power Status & Control implemented only
	- LAN Control powers off on standby, requires RS232

******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uConn{
	(** Comms **)
	INTEGER  ID
	INTEGER 	STATE
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[128]
	INTEGER	iSIP
	INTEGER  PEND
	CHAR 		Tx[500]
	CHAR 		Rx[500]
	INTEGER 	DEBUG

}
DEFINE_TYPE STRUCTURE uIiyamaDisplay{
	(** System MetaData **)
	INTEGER  POWER
	uConn    CONN
}
DEFINE_CONSTANT
LONG TLID_COMMS			= 1
LONG TLID_POLL				= 2
LONG TLID_RETRY 			= 3
LONG TLID_VOL				= 4
LONG TLID_TIMEOUT			= 5

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

INTEGER MODEL_IN1604	= 1

DEFINE_VARIABLE
VOLATILE uIiyamaDisplay myIiyamaDisplayV03

LONG TLT_POLL[]    = {	 30000 }
LONG TLT_COMMS[]   = {	 90000 }
LONG TLT_RETRY[]   = {	  5000 }
LONG TLT_VOL[]   	 = {    250  }
LONG TLT_TIMEOUT[] = {    3000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myIiyamaDisplayV03.CONN.Rx
	myIiyamaDisplayV03.CONN.isIP = (!dvDevice.NUMBER)
	myIiyamaDisplayV03.CONN.ID = 1
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_STD,'CONN->Iiyama',"myIiyamaDisplayV03.CONN.IP_HOST,':',ITOA(myIiyamaDisplayV03.CONN.IP_PORT)")
	myIiyamaDisplayV03.CONN.STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myIiyamaDisplayV03.CONN.IP_HOST, myIiyamaDisplayV03.CONN.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnRetryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnAddToQueue($30,'000',FALSE)	// Power Status
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pDataCtrl, CHAR pData[3], INTEGER SET){
	STACK_VAR INTEGER x
	STACK_VAR CHAR chkSum
	STACK_VAR CHAR toSend[30]
	// Build header - Default ID = 1
	toSend = ':01'
	// Add command type
	SWITCH (SET){
		CASE TRUE:  toSend = "toSend,'S'"
		CASE FALSE:	toSend = "toSend,'G'"
	}
	// Add Command & Value & Term
	toSend = "toSend,pDataCtrl,pData,$0D"

	// Add to Queue
	myIiyamaDisplayV03.CONN.Tx = "myIiyamaDisplayV03.CONN.Tx,toSend"

	// Send command
	fnSendFromQueue()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myIiyamaDisplayV03.CONN.PEND && myIiyamaDisplayV03.CONN.STATE == CONN_STATE_CONNECTED && FIND_STRING(myIiyamaDisplayV03.CONN.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[255]
		toSend = REMOVE_STRING(myIiyamaDisplayV03.CONN.Tx,"$0D",1)
		fnDebug(DEBUG_STD,'->Iiyama',toSend)
		SEND_STRING dvDevice,toSend
		myIiyamaDisplayV03.CONN.PEND = TRUE
		// Start Connection Timeout
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{

	myIiyamaDisplayV03.CONN.Rx = ''
	myIiyamaDisplayV03.CONN.Tx = ''
	myIiyamaDisplayV03.CONN.PEND = FALSE
	IF(myIiyamaDisplayV03.CONN.isIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	CHAR    MsgType
	INTEGER ID
	CHAR    MsgCode
	
	fnDebug(DEBUG_STD,'Iiyama->',fnBytesToString(pData))
	
	// Populate Values
	MsgType = GET_BUFFER_CHAR(pData)
	ID      = ATOI(GET_BUFFER_STRING(pData,2))
	MsgCode = GET_BUFFER_CHAR(pData)
	
	SWITCH(MsgType){
		CASE '4':{ // Set Response
			SWITCH(MsgCode){
				CASE '+':{} // OK
				CASE '-':{ // Error
					fnDebug(DEBUG_ERR,'Set Error','')
				}
			}
		}
		CASE ':':{ // Get Response
			GET_BUFFER_CHAR(pData) // Consume $72 (H)
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE '0':{	// Power Response
					myIiyamaDisplayV03.POWER = ATOI(pDATA)
				}
			}
		}
	}
	// Clear pending block
	myIiyamaDisplayV03.CONN.PEND = FALSE
	// Send next in Queue
	fnSendFromQueue()
	// Start Timeouts
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnDebug(INTEGER bDebug, CHAR Msg[], CHAR MsgData[]){
	IF(myIiyamaDisplayV03.CONN.DEBUG >= bDebug)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myIiyamaDisplayV03.CONN.STATE = CONN_STATE_CONNECTED
		IF(!myIiyamaDisplayV03.CONN.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		myIiyamaDisplayV03.CONN.STATE = CONN_STATE_OFFLINE
		fnReTryConnection()
	}
	ONERROR:{
		SWITCH(DATA.NUMBER){			//Listening Error
			CASE 14:{
				fnDebug(DEBUG_ERR,"'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")
			}
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(DEBUG_ERR,  "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(DEBUG_ERR,  "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 				//Local Port Already Used
					CASE 15:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV03.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myIiyamaDisplayV03.CONN.STATE = CONN_STATE_OFFLINE
				fnRetryConnection()
			}
		}
	}
	STRING:{
		WHILE(FIND_STRING(DATA.TEXT,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,"$0D",1),1))
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
							myIiyamaDisplayV03.CONN.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myIiyamaDisplayV03.CONN.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myIiyamaDisplayV03.CONN.IP_HOST = DATA.TEXT
							myIiyamaDisplayV03.CONN.IP_PORT = 4664
						}
						fnOpenTCPConnection()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':  myIiyamaDisplayV03.CONN.DEBUG = DEBUG_DEV
							CASE 'TRUE': myIiyamaDisplayV03.CONN.DEBUG = DEBUG_STD
							DEFAULT:     myIiyamaDisplayV03.CONN.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice, "DATA.TEXT,$0D"
			}
			CASE 'BACKLIGHT':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnAddToQueue('0','001',TRUE)
					CASE 'OFF':fnAddToQueue('0','000',TRUE)
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnAddToQueue('0','003',TRUE)
					CASE 'OFF':fnAddToQueue('0','002',TRUE)
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/

DEFINE_PROGRAM{
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,255] = (myIiyamaDisplayV03.POWER == 1)
}
/******************************************************************************
	EoF
******************************************************************************/















