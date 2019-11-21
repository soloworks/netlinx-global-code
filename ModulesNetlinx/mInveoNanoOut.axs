MODULE_NAME='mInveoNanoOut'(DEV vdvControl, DEV ipHTTP)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'
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
DEFINE_TYPE STRUCTURE uSystem{
	uDebug   DEBUG
	CHAR     USERNAME[20]
	CHAR     PASSWORD[20]
	CHAR     Base64EncodedAuth[200]

	CHAR		MODEL[50]		// Device Model
	LONG     RELAY_STATE		// Output Status
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_CONNECTED		= 2

DEFINE_VARIABLE
LONG 		TLT_POLL[] 						= {  20000 }
LONG 		TLT_COMMS[]						= {  90000 }
LONG 		TLT_TIMEOUT[]					= {  10000 }
VOLATILE uSystem myInveo
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myInveo.DEBUG.UID = 'Inveo'
	myInveo.USERNAME  = 'admin'
	myInveo.PASSWORD  = 'admin00'
}
/******************************************************************************
	Callback Functions
******************************************************************************/
DEFINE_FUNCTION eventHTTPResponse(uHTTPResponse r){
	STACK_VAR CHAR uOutput[8]

	fnDebug(myInveo.DEBUG,DEBUG_DEV,"'eventHTTPResponse(r) CALLED'")
	fnDebug(myInveo.DEBUG,DEBUG_DEV,"'Response Code: ',ITOA(r.code)")
	fnDebug(myInveo.DEBUG,DEBUG_DEV,"'Body: ',r.body")
	fnDebug(myInveo.DEBUG,DEBUG_STD,"'FB: ',r.body")
	// Get Model
	REMOVE_STRING(r.body,'<prod_name>',1)
	myInveo.MODEL = fnStripCharsRight(REMOVE_STRING(r.body,'<',1),1)
	// Get Output State
	REMOVE_STRING(r.body,'<on>',1)
	uOutput = fnStripCharsRight(REMOVE_STRING(r.body,'<',1),1)
	fnDebug(myInveo.DEBUG,DEBUG_STD,"'on: ',uOutput")
	myInveo.RELAY_STATE = ATOI("uOutput[8]")
	// Reset Communication Timeout
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Send Command
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(uKeyPair Args[]){
	STACK_VAR uHTTPRequest r
	// Setup Request
	r.METHOD = HTTP_METHOD_GET
	r.PATH   = '/stat.php'
	// Setup Additional Headers
	r.HEADERS[1].KEY   =  'Authorization'
	r.HEADERS[1].VALUE = "'Basic ',myInveo.Base64EncodedAuth"
	// Setup Supplied Arguments
	r.args = Args
	// Send Request
	fnAddToHTTPQueue(r)
	fnInitPoll()
}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR uHTTPRequest r
	// Setup Request
	r.METHOD = HTTP_METHOD_GET
	r.PATH   = '/stat.php'
	// Setup Additional Headers
	r.HEADERS[1].KEY   =  'Authorization'
	r.HEADERS[1].VALUE = "'Basic ',myInveo.Base64EncodedAuth"
	// Submit
	fnAddToHTTPQueue(r)
	fnInitPoll()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'TESTPOLL':{
				fnPoll()
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						HTTP.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							HTTP.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',1))
						}
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myInveo.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV': myInveo.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:    myInveo.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
						HTTP.DEBUG = myInveo.DEBUG
					}
					CASE 'USERNAME':   myInveo.USERNAME = DATA.TEXT
					CASE 'PASSWORD':   myInveo.PASSWORD = DATA.TEXT
					CASE 'BASE64AUTH': myInveo.Base64EncodedAuth = DATA.TEXT
				}
			}
			CASE 'STATE':{
				STACK_VAR uKeyPair a[1]

				// Get Power State
				SWITCH(DATA.TEXT){
					CASE 'ON':		myInveo.RELAY_STATE = TRUE
					CASE 'OFF':		myInveo.RELAY_STATE = FALSE
					CASE 'TOGGLE':	myInveo.RELAY_STATE = !myInveo.RELAY_STATE
				}
				// Set Argument
				SWITCH(myInveo.RELAY_STATE){
					CASE FALSE:		a[1].key = 'off'
					CASE TRUE:		a[1].key = 'on'
				}
				a[1].value = '1'
				// Send Request
				fnSendCommand(a)
			}
		}
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
