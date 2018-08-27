MODULE_NAME='mIiyamaDisplayV02'(DEV vdvControl,DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the VP-730

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
	CHAR 		Tx[10][30]
	CHAR 		Rx[500]
	INTEGER 	DEBUG

}
DEFINE_TYPE STRUCTURE uIiyamaDisplay{
	(** System MetaData **)
	CHAR   	MODEL[50]
	CHAR	 	SERIAL_NO[20]

	SINTEGER GAIN_VALUE			// Current Volume Level
	INTEGER	GAIN_PEND_STATE	// True if Volume Send is Pending
	SINTEGER	GAIN_PEND_VALUE	// Value for a pending Volume
	INTEGER	MUTE					// Current Audio Mute State

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
VOLATILE uIiyamaDisplay myIiyamaDisplayV02

LONG TLT_POLL[]    = {	 30000 }
LONG TLT_COMMS[]   = {	 90000 }
LONG TLT_RETRY[]   = {	  5000 }
LONG TLT_VOL[]   	 = {    250  }
LONG TLT_TIMEOUT[] = {    3000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myIiyamaDisplayV02.CONN.Rx
	myIiyamaDisplayV02.CONN.isIP = (!dvDevice.NUMBER)
	myIiyamaDisplayV02.CONN.ID = 1
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_STD,'CONN->KRA',"myIiyamaDisplayV02.CONN.IP_HOST,':',ITOA(myIiyamaDisplayV02.CONN.IP_PORT)")
	myIiyamaDisplayV02.CONN.STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myIiyamaDisplayV02.CONN.IP_HOST, myIiyamaDisplayV02.CONN.IP_PORT, IP_TCP)
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
	fnAddToQueue($01,"$A2,$00")
	fnAddToQueue($01,"$19")
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pDataCtrl, CHAR pData[]){
	STACK_VAR INTEGER x
	STACK_VAR CHAR chkSum
	STACK_VAR CHAR toSend[30]
	// Build Data Control
	toSend = "pDataCtrl,pData"
	// Add Length with space for checksum
	toSend = "LENGTH_ARRAY(toSend)+1,toSend"
	// Add Headers
	toSend = "$A6,myIiyamaDisplayV02.CONN.ID,$00,$00,$00,toSend"
	// Calculate ChkSum
	chkSum = toSend[1]
	FOR(x = 2; x <= LENGTH_ARRAY(toSend); x++){
		chkSum = chkSum BXOR toSend[x]
	}
	// Add the checksum
	toSend = "toSend,chkSum"
	// Add to Queue
	FOR(x = 1; x <= 10; x++){
		IF(!LENGTH_ARRAY(myIiyamaDisplayV02.CONN.Tx[x])){
			myIiyamaDisplayV02.CONN.Tx[x] = toSend
			BREAK
		}
	}

	// Send command
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myIiyamaDisplayV02.CONN.PEND && myIiyamaDisplayV02.CONN.STATE == CONN_STATE_CONNECTED && LENGTH_ARRAY(myIiyamaDisplayV02.CONN.Tx[1])){
		STACK_VAR INTEGER x
		STACK_VAR CHAR toSend[255]
		toSend = myIiyamaDisplayV02.CONN.Tx[1]
		fnDebug(DEBUG_STD,'->Iiyama',fnBytesToString(toSend))
		SEND_STRING dvDevice,toSend
		myIiyamaDisplayV02.CONN.PEND = TRUE
		FOR(x = 1; x < 10; x++){
			myIiyamaDisplayV02.CONN.Tx[x] = myIiyamaDisplayV02.CONN.Tx[x+1]
		}
		myIiyamaDisplayV02.CONN.Tx[10] = ''
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 10; x++){
		myIiyamaDisplayV02.CONN.Tx[x] = ''
	}
	myIiyamaDisplayV02.CONN.Rx = ''
	myIiyamaDisplayV02.CONN.PEND = FALSE
	IF(myIiyamaDisplayV02.CONN.isIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(DEBUG_STD,'Iiyama->',fnBytesToString(pData))


	// Reset
	myIiyamaDisplayV02.CONN.PEND = FALSE
	fnSendFromQueue()

	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnDebug(INTEGER bDebug, CHAR Msg[], CHAR MsgData[]){
	IF(myIiyamaDisplayV02.CONN.DEBUG >= bDebug)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myIiyamaDisplayV02.CONN.STATE = CONN_STATE_CONNECTED
		IF(!myIiyamaDisplayV02.CONN.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		myIiyamaDisplayV02.CONN.STATE = CONN_STATE_OFFLINE
		fnReTryConnection()
	}
	ONERROR:{
		SWITCH(DATA.NUMBER){			//Listening Error
			CASE 14:{
				fnDebug(DEBUG_ERR,"'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")
			}
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(DEBUG_ERR,  "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(DEBUG_ERR,  "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 				//Local Port Already Used
					CASE 15:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(DEBUG_ERR, "'Iiyama IP Error:[',myIiyamaDisplayV02.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myIiyamaDisplayV02.CONN.STATE = CONN_STATE_OFFLINE
				fnRetryConnection()
			}
		}
	}
	STRING:{
		fnProcessFeedback(DATA.TEXT)
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
							myIiyamaDisplayV02.CONN.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myIiyamaDisplayV02.CONN.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myIiyamaDisplayV02.CONN.IP_HOST = DATA.TEXT
							myIiyamaDisplayV02.CONN.IP_PORT = 5000
						}
						fnOpenTCPConnection()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':  myIiyamaDisplayV02.CONN.DEBUG = DEBUG_DEV
							CASE 'TRUE': myIiyamaDisplayV02.CONN.DEBUG = DEBUG_STD
							DEFAULT:     myIiyamaDisplayV02.CONN.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice, "DATA.TEXT,$0D"
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnAddToQueue($01,"$18,$02")
					CASE 'OFF':fnAddToQueue($01,"$18,$01")
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myIiyamaDisplayV02.GAIN_PEND_STATE){
		//fnAddToQueue('AUD-LVL',"'1,1,',ITOA(myIiyamaDisplayV02.GAIN_PEND_VALUE)")
		myIiyamaDisplayV02.GAIN_VALUE = myIiyamaDisplayV02.GAIN_PEND_VALUE
		myIiyamaDisplayV02.GAIN_PEND_STATE = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myIiyamaDisplayV02.GAIN_VALUE
	[vdvControl,199] = myIiyamaDisplayV02.MUTE
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
}
/******************************************************************************
	EoF
******************************************************************************/