MODULE_NAME='mSolsticeAPI'(DEV vdvDevice,DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module for monitoring Solstice Pod on API
******************************************************************************/

/******************************************************************************
	Control Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uResp{
	INTEGER 	TYPE
	CHAR 		Rx[12000]
	INTEGER	BUFFER_LENGTH
	INTEGER	HEADER_LENGTH
	INTEGER	BODY_LENGTH
	INTEGER	HEADER_PROCESSED
	INTEGER	HTTP_CODE
}
DEFINE_TYPE STRUCTURE uSolstice{
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER 	DEBUG
	INTEGER	CONN_STATE
	CHAR 		Tx[10][1000]
	uResp		RESPONSE

	CHAR		DEVICE_NAME[100]
	CHAR		SESSION_KEY[100]
	CHAR		PASSWORD[50]
	INTEGER	TOTAL_CONNECTION
	INTEGER	TOTAL_CONNECTING
}
/******************************************************************************
	System Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER CONN_STATE_OFFLINE 	= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

LONG TLID_POLL_LONG  = 1
LONG TLID_POLL_SHORT = 2
LONG TLID_COMM       = 3

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

INTEGER RESPONSE_TYPE_STATS  = 1
INTEGER RESPONSE_TYPE_CONFIG = 2

/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uSolstice mySolstice
LONG TLT_POLL_LONG[]  = { 60000 }
LONG TLT_POLL_SHORT[] = {  5000 }
LONG TLT_COMM[]       = { 90000 }
/******************************************************************************
	Helper Functions - IP Connection
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_STD,"'Connecting to '","mySolstice.IP_HOST,':',ITOA(mySolstice.IP_PORT)")
	mySolstice.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDevice.port, "mySolstice.IP_HOST", mySolstice.IP_PORT, IP_TCP)
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}
DEFINE_FUNCTION fnDebug(INTEGER bDebugType, CHAR Msg[], CHAR MsgData[]){
	IF(mySolstice.DEBUG >= bDebugType){
		SEND_STRING 0:1:0, "ITOA(vdvDevice.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Helper Functions - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	fnDebug(DEBUG_DEV,'fnInitPoll','Called')
	// Setup Long Poll
	IF(TIMELINE_ACTIVE(TLID_POLL_LONG)){TIMELINE_KILL(TLID_POLL_LONG)}
	TIMELINE_CREATE(TLID_POLL_LONG,TLT_POLL_LONG,LENGTH_ARRAY(TLT_POLL_LONG),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	// Setup Short Poll
	IF(TIMELINE_ACTIVE(TLID_POLL_SHORT)){TIMELINE_KILL(TLID_POLL_SHORT)}
	TIMELINE_CREATE(TLID_POLL_SHORT,TLT_POLL_SHORT,LENGTH_ARRAY(TLT_POLL_SHORT),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL_SHORT]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT[TLID_POLL_SHORT]','TRIGGERED')
	fnAddQueryToQueue('/api/stats')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL_LONG]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT[TLID_POLL_LONG]','TRIGGERED')
	fnAddQueryToQueue('/api/config')
}
/******************************************************************************
	Helper Functions - Data Handling - HTTP Request
******************************************************************************/
DEFINE_FUNCTION fnAddQueryToQueue(CHAR pCMD[]){
	// Build GET Request

	fnDebug(DEBUG_DEV,'fnAddQueryToQueue','Called')
	// Add it to an empty slot
	IF(1){
		STACK_VAR INTEGER x
		FOR(x = 1; x <= 10; x++){
			IF(!LENGTH_ARRAY(mySolstice.Tx[x])){
				mySolstice.Tx[x] = pCMD
				BREAK
			}
		}
	}
	// Connect if not in process already
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(LENGTH_ARRAY(mySolstice.Tx[1]) && mySolstice.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvDevice]{
	COMMAND:{
		// Handle Incoming Command
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			// Control Commands
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					// Used to trigger a query for testing
					CASE 'STATS':fnAddQueryToQueue('/api/stats')
					CASE 'CONFIG':fnAddQueryToQueue('/api/config')
				}
			}
			// Property Set Commands
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					// Set IP Details
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							// Store IP address and Port
							mySolstice.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							mySolstice.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							// Default to port 80 if not specified
							mySolstice.IP_HOST = DATA.TEXT
							mySolstice.IP_PORT = 80
						}
						// Initial Query on start
						fnAddQueryToQueue('/api/stats')
						fnAddQueryToQueue('/api/config')
						// Start Polling
						fnInitPoll()
					}
					CASE 'PASSWORD':{
						mySolstice.PASSWORD = DATA.TEXT
					}
					// Set Debugging State
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	mySolstice.DEBUG = DEBUG_STD
							CASE 'DEV':		mySolstice.DEBUG = DEBUG_DEV
							DEFAULT:			mySolstice.DEBUG = DEBUG_ERR
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Ethernet Device - Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, mySolstice.RESPONSE.Rx
}
/******************************************************************************
	Helper Functions - Data Handling - Headers
******************************************************************************/
DEFINE_FUNCTION fnProcessHeader(CHAR pDATA[12000]){
	// Process First Line
	STACK_VAR CHAR pHeaderLine[1000]
	fnDebug(DEBUG_DEV,'fnProcessHeader()','CALLED')

	// Get Header Length
	mySolstice.RESPONSE.HEADER_LENGTH = LENGTH_ARRAY(pDATA)

	// HTTP Code
	pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
	fnDebug(DEBUG_STD,'SOL->Header->',pHeaderLine)
	REMOVE_STRING(pHeaderLine,' ',1)
	mySolstice.RESPONSE.HTTP_CODE = ATOI(REMOVE_STRING(pHeaderLine,' ',1))

	// Process rest of fields
	WHILE(FIND_STRING(pDATA,"$0D,$0A",1)){
		pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
		IF(pHeaderLine != ''){
			fnDebug(DEBUG_STD,'SOL->Header->',pHeaderLine)
			SWITCH(fnStripCharsRight(REMOVE_STRING(pHeaderLine,':',1),1)){
				CASE 'Content-Length':mySolstice.RESPONSE.BODY_LENGTH = ATOI(pHeaderLine)
			}
		}
	}

	// Flag Header as Processed
	mySolstice.RESPONSE.HEADER_PROCESSED = TRUE
}
DEFINE_FUNCTION INTEGER fnProcessBody(CHAR pDATA[12000]){
	fnDebug(DEBUG_DEV,'fnProcessBody()','CALLED')
	//fnDebug(DEBUG_STD,'SOL->Body->',pDATA)
	SWITCH(mySolstice.RESPONSE.TYPE){
		CASE RESPONSE_TYPE_CONFIG:{
			STACK_VAR pValue[255]
			// Device Name
			pValue = fnGetValueFromKey(pDATA,'m_displayName')
			IF(mySolstice.DEVICE_NAME != pValue){
				mySolstice.DEVICE_NAME = pValue
				SEND_STRING vdvDevice, "'PROPERTY-META,SYSTEM,',mySolstice.DEVICE_NAME"
			}
			// Session Key
			pValue = fnGetValueFromKey(pDATA,'sessionKey')
			IF(mySolstice.SESSION_KEY != pValue){
				mySolstice.SESSION_KEY = pValue
				SEND_STRING vdvDevice, "'PROPERTY-META,SESSIONKEY,',mySolstice.SESSION_KEY"
			}
		}
		CASE RESPONSE_TYPE_STATS:{
			mySolstice.TOTAL_CONNECTION = ATOI(fnGetValueFromKey(pDATA,'m_connectedUsers'))
			mySolstice.TOTAL_CONNECTING = ATOI(fnGetValueFromKey(pDATA,'m_connectingUsers'))
		}
	}
}

DEFINE_FUNCTION CHAR[100] fnGetValueFromKey(CHAR pDATA[12000], CHAR pKey[]){
	STACK_VAR INTEGER x
	STACK_VAR CHAR pSearch[100]
	STACK_VAR CHAR pVALUE[100]
	fnDebug(DEBUG_DEV,'fnGetValueFromKey()',pKey)
	pSearch = "'"',pKey,'":'"
	x = FIND_STRING(pDATA,pSearch,1)

	IF(x){
		fnDebug(DEBUG_DEV,'Key Start at ',ITOA(x))
		fnDebug(DEBUG_DEV,'Key String Char',pDATA[x])
		x = x+LENGTH_ARRAY(pSearch)
		fnDebug(DEBUG_DEV,'Value Start at ',ITOA(x))
		fnDebug(DEBUG_DEV,'Value String Start',pDATA[x])

		IF(pDATA[x] == '"'){
			x = x+1
			fnDebug(DEBUG_DEV,'fnGetValueFromKey()','Getting Quoted Value')
			pVALUE = MID_STRING(pDATA,x,FIND_STRING(pDATA,'"',x)-x)
		}
		ELSE{
			fnDebug(DEBUG_DEV,'fnGetValueFromKey()','Getting Raw Value')
			//fnDebug(DEBUG_DEV,'Value End at ',ITOA(FIND_STRING(pDATA,',',x)))
			pVALUE = MID_STRING(pDATA,x,FIND_STRING(pDATA,',',x)-x)
		}
		fnDebug(DEBUG_DEV,'Key Value',pVALUE)
	}

	RETURN pVALUE
}
/******************************************************************************
	Ethernet Device - Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	STRING:{
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipDevice]','STRING')

		// Process the Header
		IF(!mySolstice.RESPONSE.HEADER_PROCESSED && FIND_STRING(mySolstice.RESPONSE.Rx,"$0D,$0A,$0D,$0A",1)){
			fnProcessHeader(REMOVE_STRING(mySolstice.RESPONSE.Rx,"$0D,$0A,$0D,$0A",1))
		}

		// Report anything except a good request
		SWITCH(mySolstice.RESPONSE.HTTP_CODE){
			CASE 200:{
				fnDebug(DEBUG_STD,'SOL->',"'HTTP Response Code ',ITOA(mySolstice.RESPONSE.HTTP_CODE)")
			}
			DEFAULT:{
				fnDebug(DEBUG_ERR,'SOL->',"'HTTP Response Code ',ITOA(mySolstice.RESPONSE.HTTP_CODE)")
			}
		}

		mySolstice.RESPONSE.BUFFER_LENGTH = LENGTH_ARRAY(mySolstice.RESPONSE.Rx)

		// Debug Out
		fnDebug(DEBUG_DEV,'SOL->',"'HTTP Buff Size [',ITOA(mySolstice.RESPONSE.BUFFER_LENGTH),']'")
		fnDebug(DEBUG_DEV,'SOL->',"'HTTP Head Size [',ITOA(mySolstice.RESPONSE.HEADER_LENGTH),']'")
		fnDebug(DEBUG_DEV,'SOL->',"'HTTP Body Size [',ITOA(mySolstice.RESPONSE.BODY_LENGTH),']'")

		// Process Body
		IF(mySolstice.RESPONSE.HEADER_PROCESSED && mySolstice.RESPONSE.BUFFER_LENGTH == mySolstice.RESPONSE.BODY_LENGTH){
			STACK_VAR uResp blankResponse
			fnProcessBody(mySolstice.RESPONSE.Rx)
			mySolstice.RESPONSE = blankResponse
			IF(TIMELINE_ACTIVE(TLID_COMM)){TIMELINE_KILL(TLID_COMM)}
			TIMELINE_CREATE(TLID_COMM,TLT_COMM,LENGTH_ARRAY(TLT_COMM),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}

	}
	OFFLINE:{
		STACK_VAR uResp blankResponse
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipDevice]','OFFLINE')
		// Clear settings on connection close
		mySolstice.RESPONSE = blankResponse
		mySolstice.CONN_STATE = CONN_STATE_OFFLINE
		fnSendFromQueue()
	}
	ONLINE:{
		CHAR toSend[1000]
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipDevice]','ONLINE')
		// Send the HTTP request
		mySolstice.CONN_STATE = CONN_STATE_CONNECTED
		toSend = "toSend,'GET ',mySolstice.Tx[1]"
		IF(LENGTH_ARRAY(mySolstice.PASSWORD)){
			toSend = "toSend,'?password=',mySolstice.PASSWORD"
		}
		toSend = "toSend,' HTTP/1.0',$0D,$0A"
		toSend = "toSend,'Host: ',mySolstice.IP_HOST,':',ITOA(mySolstice.IP_PORT),$0D,$0A"
		toSend = "toSend,$0D,$0A"

		SWITCH(mySolstice.Tx[1]){
			CASE '/api/stats': mySolstice.RESPONSE.TYPE = RESPONSE_TYPE_STATS
			CASE '/api/config':mySolstice.RESPONSE.TYPE = RESPONSE_TYPE_CONFIG
		}

		fnDebug(DEBUG_STD,'->SOL',toSend)
		SEND_STRING ipDevice,toSend

		IF(1){
			STACK_VAR INTEGER x
			FOR(x = 1; x < 10; x++){
				mySolstice.Tx[x] = mySolstice.Tx[x+1]
				mySolstice.Tx[x+1] = ''
			}
		}

	}
	ONERROR:{
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipDevice]','ONERROR')
		SWITCH(DATA.NUMBER){
			CASE 2:{fnDebug(DEBUG_ERR, "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{fnDebug(DEBUG_ERR,  "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{fnDebug(DEBUG_ERR,  "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{fnDebug(DEBUG_ERR,  "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{fnDebug(DEBUG_ERR, "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{fnDebug(DEBUG_ERR, "'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(DEBUG_ERR,"'IP Error:[',mySolstice.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:mySolstice.CONN_STATE = CONN_STATE_OFFLINE
		}
	}
}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	// Device Feedback
	SEND_LEVEL vdvDevice, 1, mySolstice.TOTAL_CONNECTION
	SEND_LEVEL vdvDevice, 2, mySolstice.TOTAL_CONNECTING

	// Comms Feedback
	[vdvDevice,251] = (TIMELINE_ACTIVE(TLID_COMM))
	[vdvDevice,252] = (TIMELINE_ACTIVE(TLID_COMM))
}
/******************************************************************************
	EoF
******************************************************************************/