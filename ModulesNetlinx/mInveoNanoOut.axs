MODULE_NAME='mInveoNanoOut'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/

DEFINE_CONSTANT
LONG     TLID_POLL		= 1
LONG     TLID_COMMS		= 2
LONG     TLID_TIMEOUT	= 3

/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uResp{
	CHAR 		Rx[12000]
	INTEGER	BUFFER_LENGTH
	INTEGER	HEADER_LENGTH
	INTEGER	BODY_LENGTH
	INTEGER	HEADER_PROCESSED
	INTEGER	HTTP_CODE
}
DEFINE_TYPE STRUCTURE uSystem{
	INTEGER	CONN_STATE
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	DEBUG
	CHAR		Tx[10000]
	uResp		RESPONSE
	CHAR     USERNAME[20]
	CHAR     PASSWORD[20]
	CHAR     Base64EncodedAuth[200]

	CHAR		MODEL[50]		// Device Model
	INTEGER  RELAY_STATE		// Output Status

}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_CONNECTED		= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2
INTEGER DEBUG_LOG = 3

DEFINE_VARIABLE
LONG 		TLT_POLL[] 						= {  20000 }
LONG 		TLT_COMMS[]						= {  90000 }
LONG 		TLT_TIMEOUT[]					= {  10000 }
VOLATILE uSystem myInveo
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	// Setup Receive Buffer
	CREATE_BUFFER ipDevice, myInveo.RESPONSE.Rx
	myInveo.IP_PORT = 80
	myInveo.USERNAME = 'admin'
	myInveo.PASSWORD = 'admin00'
}

/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[]){
	IF(myInveo.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg"
	}
}
DEFINE_FUNCTION fnDebugHTTP(INTEGER pDEBUG, CHAR MsgData[10000]){
	fnDebug(DEBUG_DEV,"'fnDebugHTTP','Called'")
	IF(myInveo.DEBUG >= pDEBUG){

		// Headers
		SEND_STRING 0:1:0,"ITOA(vdvControl.Number),': HTTP Header'"
		WHILE(FIND_STRING(MsgData,"$0D,$0A",1)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',REMOVE_STRING(MsgData,"$0D,$0A",1)"
		}
		SEND_STRING 0:1:0,"ITOA(vdvControl.Number),': HTTP Body'"

		// Body
		WHILE(LENGTH_ARRAY(MsgData)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',GET_BUFFER_STRING(MsgData,100)"
		}
		SEND_STRING 0:1:0,"ITOA(vdvControl.Number),': HTTP End'"

	}
	fnDebug(DEBUG_DEV,"'fnDebugHTTP','Ended'")
}
/******************************************************************************
	Connection Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Called'")
	fnDebug(DEBUG_STD,"'Connecting to ',myInveo.IP_HOST,':',ITOA(myInveo.IP_PORT)")
	myInveo.CONN_STATE = CONN_STATE_CONNECTING
	SWITCH(myInveo.IP_PORT){
		CASE 443:  TLS_CLIENT_OPEN(ipDevice.port, "myInveo.IP_HOST", myInveo.IP_PORT, 0)
		DEFAULT:    IP_CLIENT_OPEN(ipDevice.port, "myInveo.IP_HOST", myInveo.IP_PORT, IP_TCP)
	}
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(myInveo.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	SWITCH(myInveo.IP_PORT){
		CASE 443:  TLS_CLIENT_CLOSE(ipDevice.port)
		DEFAULT:    IP_CLIENT_CLOSE(ipDevice.port)
	}
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}
/******************************************************************************
	Connection Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	fnDebug(DEBUG_DEV,"'fnSendCommand','Called'")
	
	myInveo.Tx = fnBuildHTTP(pCMD)
	
	IF(myInveo.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
	fnInitPoll()
	fnDebug(DEBUG_DEV,"'fnSendCommand','Ended'")
}
DEFINE_FUNCTION CHAR[10000] fnBuildHTTP(CHAR pCMD[]){
	STACK_VAR CHAR cToReturn[10000]
	fnDebug(DEBUG_DEV,"'fnBuildHTTP','Called'")
	(** Build Header **)
	cToReturn = "cToReturn,'GET /stat.php'"
	IF(LENGTH_ARRAY(pCMD)){ cToReturn = "cToReturn,'?',pCMD" }
	cToReturn = "cToReturn,' HTTP/1.1',$0D,$0A"
	cToReturn = "cToReturn,'Host: ',myInveo.IP_HOST,':',ITOA(myInveo.IP_PORT),$0D,$0A"
	cToReturn = "cToReturn,'Authorization: Basic ',myInveo.Base64EncodedAuth,$0D,$0A"
	cToReturn = "cToReturn,'Connection: close',$0D,$0A"
	//cToReturn = "cToReturn,'Content-length: ',ITOA(LENGTH_ARRAY(pBody)),$0D,$0A"
	cToReturn = "cToReturn,$0D,$0A"
	
	fnDebug(DEBUG_DEV,"'fnBuildHTTP','Returning'")
	RETURN cToReturn

}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Called'")
	fnSendCommand('')
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Ended'")
}

/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'TESTPOLL':{
				fnSendCommand('')
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myInveo.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							myInveo.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',1))
						}
						fnSendCommand('')
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myInveo.DEBUG = DEBUG_STD
							CASE 'DEV': myInveo.DEBUG = DEBUG_DEV
							DEFAULT:    myInveo.DEBUG = DEBUG_ERR
						}
					}
					CASE 'USERNAME':myInveo.USERNAME = DATA.TEXT
					CASE 'PASSWORD':myInveo.PASSWORD = DATA.TEXT
					CASE 'BASE64AUTH':myInveo.Base64EncodedAuth = DATA.TEXT
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myInveo.RELAY_STATE = TRUE
					CASE 'OFF':		myInveo.RELAY_STATE = FALSE
					CASE 'TOGGLE':	myInveo.RELAY_STATE = !myInveo.RELAY_STATE
				}
				SWITCH(myInveo.RELAY_STATE){
					CASE FALSE:		fnSendCommand("'on=1'")
					CASE TRUE:		fnSendCommand("'off=1'")
				}
			}
		}
	}
}
/******************************************************************************
	Data Handling
******************************************************************************/
DEFINE_FUNCTION fnProcessHeader(CHAR pDATA[12000]){
	// Process First Line
	STACK_VAR CHAR pHeaderLine[1000]
	fnDebug(DEBUG_DEV,"'fnProcessHeader()','CALLED'")

	// Get Header Length
	myInveo.RESPONSE.HEADER_LENGTH = LENGTH_ARRAY(pDATA)

	// HTTP Code on First Line
	pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
	fnDebug(DEBUG_STD,"'SOL->Header->',pHeaderLine")
	REMOVE_STRING(pHeaderLine,' ',1)
	myInveo.RESPONSE.HTTP_CODE = ATOI(REMOVE_STRING(pHeaderLine,' ',1))

	// Process rest of fields
	WHILE(FIND_STRING(pDATA,"$0D,$0A",1)){
		pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
		IF(pHeaderLine != ''){
			fnDebug(DEBUG_STD,"'SOL->Header->',pHeaderLine")
			SWITCH(fnStripCharsRight(REMOVE_STRING(pHeaderLine,':',1),1)){
				CASE 'Content-Length':myInveo.RESPONSE.BODY_LENGTH = ATOI(pHeaderLine)
			}
		}
	}

	// Flag Header as Processed
	myInveo.RESPONSE.HEADER_PROCESSED = TRUE
}
DEFINE_FUNCTION INTEGER fnProcessBody(CHAR pDATA[12000]){
	STACK_VAR CHAR uOutput[8]
	
	fnDebug(DEBUG_DEV,"'fnProcessBody()','CALLED'")
	// Get Model
	REMOVE_STRING(pDATA,'<prod_name>',1)
	myInveo.MODEL = fnStripCharsRight(REMOVE_STRING(pDATA,'<',1),1)
	// Get Output State
	REMOVE_STRING(pDATA,'<out>',1)
	uOutput = fnStripCharsRight(REMOVE_STRING(pDATA,'<',1),1)
	myInveo.RELAY_STATE = ATOI("uOutput[8]")
	
}
/******************************************************************************
	IP Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	STRING:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','STRING Called'")

		// Process the Header
		IF(!myInveo.RESPONSE.HEADER_PROCESSED && FIND_STRING(myInveo.RESPONSE.Rx,"$0D,$0A,$0D,$0A",1)){
			fnProcessHeader(REMOVE_STRING(myInveo.RESPONSE.Rx,"$0D,$0A,$0D,$0A",1))
		}

		// Report anything except a good request
		SWITCH(myInveo.RESPONSE.HTTP_CODE){
			CASE 200:{
				fnDebug(DEBUG_STD,"'INVEO->HTTP Response Code ',ITOA(myInveo.RESPONSE.HTTP_CODE)")
			}
			DEFAULT:{
				fnDebug(DEBUG_ERR,"'INVEO->HTTP Response Code ',ITOA(myInveo.RESPONSE.HTTP_CODE)")
			}
		}

		myInveo.RESPONSE.BUFFER_LENGTH = LENGTH_ARRAY(myInveo.RESPONSE.Rx)

		// Debug Out
		fnDebug(DEBUG_DEV,"'INVEO->HTTP Buff Size [',ITOA(myInveo.RESPONSE.BUFFER_LENGTH),']'")
		fnDebug(DEBUG_DEV,"'INVEO->HTTP Head Size [',ITOA(myInveo.RESPONSE.HEADER_LENGTH),']'")
		fnDebug(DEBUG_DEV,"'INVEO->HTTP Body Size [',ITOA(myInveo.RESPONSE.BODY_LENGTH),']'")

		// Process Body
		IF(myInveo.RESPONSE.HEADER_PROCESSED && myInveo.RESPONSE.BUFFER_LENGTH == myInveo.RESPONSE.BODY_LENGTH){
			STACK_VAR uResp blankResponse
			fnProcessBody(myInveo.RESPONSE.Rx)
			myInveo.RESPONSE = blankResponse
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}

		fnDebug(DEBUG_DEV,"'DATA_EVENT','STRING Ended'")
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','OFFLINE Called'")
		myInveo.CONN_STATE = CONN_STATE_OFFLINE
		fnDebugHTTP(DEBUG_DEV,"'INVEO->',myInveo.RESPONSE.Rx")
		IF(1){
			STACK_VAR uResp blankRESPONSE
			myInveo.RESPONSE = blankRESPONSE
		}
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		fnDebug(DEBUG_DEV,"'DATA_EVENT','OFFLINE Ended'")
	}
	ONLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONLINE Called'")
		myInveo.CONN_STATE = CONN_STATE_CONNECTED
		SEND_STRING DATA.DEVICE, myInveo.Tx
		fnDebugHTTP(DEBUG_DEV,"'->INVEO',myInveo.Tx")
		myInveo.Tx = ''
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONLINE Ended'")
	}
	ONERROR:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONERROR Called'")
		myInveo.CONN_STATE = CONN_STATE_OFFLINE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		fnDebug(DEBUG_STD,"'Carrier Error ',ITOA(DATA.NUMBER),':',DATA.TEXT")
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONERROR Ended'")
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myInveo.RELAY_STATE)
}
/******************************************************************************
	EoF
******************************************************************************/
