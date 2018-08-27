PROGRAM_NAME='WebSockets'
/******************************************************************************
	WebSocket Connection Include

******************************************************************************/
DEFINE_CONSTANT
INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_CONNECTED  	= 2

INTEGER HTTP_REQ_TYPE_NONE = 0
INTEGER HTTP_REQ_TYPE_GET  = 1
INTEGER HTTP_REQ_TYPE_POST = 2

INTEGER _MAX_HEADERS    = 10
INTEGER _MAX_ARGS       = 10
INTEGER _REQ_QUEUE_SIZE = 10

DEFINE_TYPE Structure uKeyPair{
	CHAR KEY[30]
	CHAR VALUE[100]
}

DEFINE_TYPE STRUCTURE uHTTPReq{
	INTEGER  TYPE
	uKeyPair HEADERS[_MAX_HEADERS]
	uKeyPair ARGS[_MAX_ARGS]
	CHAR 		HOST[255]
	INTEGER	PORT
	CHAR     PATH[500]
	CHAR     BODY[10000]
}

DEFINE_TYPE STRUCTURE uHTTPResp{
	INTEGER	CODE
	uKeyPair HEADERS[_MAX_HEADERS]
	CHAR     BODY[10000]
}
DEFINE_TYPE STRUCTURE uHTTPComms{
	INTEGER		CONN_STATE
	CHAR 			IP_HOST[255]
	INTEGER		IP_PORT
	CHAR 			Rx[10000]
	uHTTPReq    Tx[_REQ_QUEUE_SIZE]
	uHTTPResp	RESPONSE
	INTEGER		RESPONSE_HEADERS_PROCESSED
	uDebug      DEBUG
}

DEFINE_VARIABLE
uHTTPComms  HTTP

DEFINE_START{
	// Setup Receive Buffer
	CREATE_BUFFER ipHTTP, HTTP.Rx
	
	// Setup HTTP Defaults
	HTTP.IP_PORT = 80
}

/******************************************************************************
	Connection Helpers
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	STACK_VAR CHAR    pHOST[255]
	STACK_VAR INTEGER pPORT

	// Get Values
	pHost = HTTP.IP_HOST
	IF(LENGTH_ARRAY(HTTP.Tx[1].HOST)){ pHOST = HTTP.Tx[1].HOST }
	pPORT = HTTP.IP_PORT
	IF(HTTP.Tx[1].PORT){ pPORT = HTTP.Tx[1].PORT }

	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Called'")

	fnDebug(HTTP.DEBUG,DEBUG_STD,"'Connecting to ',pHOST,':',ITOA(pPORT)")
	HTTP.CONN_STATE = CONN_STATE_CONNECTING
	SWITCH(pPORT){
		CASE 443:  TLS_CLIENT_OPEN(ipHTTP.port, "pHOST", pPORT, 0)
		DEFAULT:    IP_CLIENT_OPEN(ipHTTP.port, "pHOST", pPORT, IP_TCP)
	}
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	SWITCH(HTTP.IP_PORT){
		CASE 443:  TLS_CLIENT_CLOSE(ipHTTP.port)
		DEFAULT:    IP_CLIENT_CLOSE(ipHTTP.port)
	}
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}
/******************************************************************************
	Queue Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToHTTPQueue(uHTTPReq r){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= _REQ_QUEUE_SIZE; x++){
		IF(!HTTP.Tx[x].TYPE){
			HTTP.Tx[x] = r
			BREAK
		}
	}
	fnOpenTCPConnection()
}
/******************************************************************************
	HTTP Build Helpers
******************************************************************************/
DEFINE_FUNCTION CHAR[10000] fnBuildHTTPRequest(uHTTPReq r){
	STACK_VAR INTEGER x
	STACK_VAR CHAR c[10000]
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnBuildHTTPRequest','Called'")
	
	// Get Request Type
	SWITCH(r.TYPE){
		CASE HTTP_REQ_TYPE_NONE:{
			fnDebug(HTTP.DEBUG,DEBUG_ERR,"'Missing HTTP Type in Request'")
			RETURN ''
		}
		CASE HTTP_REQ_TYPE_GET:c = 'GET'
		CASE HTTP_REQ_TYPE_POST:c = 'POST'
	}
	// Add Space
	c = "c,' '"
	// Add Path
	SWITCH(r.PATH){
		CASE '':	c = "c,'/'"
		DEFAULT:	c = "c,r.PATH"
	}
	// Add Space
	c = "c,' '"
	// Add Arguments if required
	SWITCH(r.TYPE){
		CASE HTTP_REQ_TYPE_GET:{
			IF(r.ARGS[1].KEY != ''){
				// Add Args Delim
				c = "c,'?'"
				// Add all Args
				FOR(x = 1; x <= _MAX_ARGS; x++){
					// Add Delimiter
					IF(x > 1){c = "c,'&'"}
					c = "c,r.ARGS[x].KEY,'=',r.ARGS[x].VALUE"
				}
			}
		}
	}
	// Add Space and HTTP ver
	c = "c,' HTTP/1.0',$0D,$0A"
	// Add Host Header
	c = "c,'Host: '"
	SWITCH(r.HOST){
		CASE '': c = "c,HTTP.IP_HOST"
		DEFAULT:	c = "c,r.HOST"
	}
	IF(r.PORT){
		c = "c,':',ITOA(r.PORT)"}
	ELSE IF(HTTP.IP_PORT){
		c = "c,':',ITOA(HTTP.IP_PORT)"
	}
	c = "c,$0D,$0A"

	// Add default headers
	c = "c,'Connection: Close',$0D,$0A"
	SWITCH(r.TYPE){
		CASE HTTP_REQ_TYPE_POST:{
			c = "c,'Content-length: ',ITOA(LENGTH_ARRAY(r.body)),$0D,$0A"
		}
	}
	// Add Custom headers
	FOR(x = 1; x <= _MAX_HEADERS; x++){
		IF(r.HEADERS[x].KEY != ''){
			c = "c,r.HEADERS[x].KEY,': ',r.HEADERS[x].VALUE,$0D,$0A"
		}
		ELSE{
			BREAK
		}
	}

	// Terminate Header
	c = "c,$0D,$0A"

	// Add Body
	SWITCH(r.TYPE){
		CASE HTTP_REQ_TYPE_POST:{
			c = "c,r.BODY"
		}
	}
	(** Combine **)
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnBuildSocketRequest','Returning'")
	RETURN c

}

/******************************************************************************
	IP Data Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipHTTP]{
	STRING:{
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT STRING Called'")
		// Process the Header
		IF(!HTTP.RESPONSE_HEADERS_PROCESSED && FIND_STRING(HTTP.Rx,"$0D,$0A,$0D,$0A",1)){
			STACK_VAR CHAR HEAD_LINE[200]
			fnDebugHTTP(HTTP.DEBUG,DEBUG_DEV,"HTTP.Rx")

			// Gather HTTP Code
			HEAD_LINE = fnStripCharsRight(REMOVE_STRING(HTTP.Rx,"$0D,$0A",1),2)
			HTTP.RESPONSE.CODE = ATOI(fnGetSplitStringValue(HEAD_LINE,' ',2))

			// Store rest of Headers
			WHILE(FIND_STRING(HTTP.Rx,"$0D,$0A",1)){
				HEAD_LINE = fnStripCharsRight(REMOVE_STRING(HTTP.Rx,"$0D,$0A",1),2)
				IF(HEAD_LINE != ''){
					STACK_VAR INTEGER x
					fnDebug(HTTP.DEBUG,DEBUG_STD,"'Header->',HEAD_LINE")
					FOR(x = 1; x <= _MAX_HEADERS; x++){
						IF(HTTP.RESPONSE.HEADERS[x].KEY == ''){
							HTTP.RESPONSE.HEADERS[x].KEY = fnStripCharsRight(REMOVE_STRING(HEAD_LINE,':',1),1)
							HTTP.RESPONSE.HEADERS[x].VALUE = fnRemoveWhiteSpace(HEAD_LINE)		
							BREAK
						}
					}
				}
				ELSE{
					HTTP.RESPONSE_HEADERS_PROCESSED = TRUE
				}
			}
		}

		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT STRING Ended'")
	}
	OFFLINE:{
		STACK_VAR uHTTPResp blankRepsonse
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT OFFLINE Called'")
		HTTP.CONN_STATE = CONN_STATE_OFFLINE
		HTTP.RESPONSE.BODY = HTTP.Rx
		HTTP.Rx = ''
		eventHTTPResponse(HTTP.RESPONSE)
		HTTP.RESPONSE = blankRepsonse
		HTTP.RESPONSE_HEADERS_PROCESSED = FALSE
		// Send next in the queue
		IF(HTTP.Tx[1].TYPE){ fnOpenTCPConnection() }
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT OFFLINE Ended'")
	}
	ONLINE:{
		STACK_VAR INTEGER x
		STACK_VAR uHTTPReq blankReq

		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT ONLINE Called'")

		HTTP.CONN_STATE = CONN_STATE_CONNECTED
		fnDebugHTTP(HTTP.DEBUG,DEBUG_DEV,"fnBuildHTTPRequest(HTTP.Tx[1])")
		SEND_STRING DATA.DEVICE, fnBuildHTTPRequest(HTTP.Tx[1])
		FOR(x = 1; x < _REQ_QUEUE_SIZE; x++){
			HTTP.Tx[x] = HTTP.Tx[x+1]
		}
		HTTP.Tx[_REQ_QUEUE_SIZE] = blankReq

		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONLINE Ended'")
	}
	ONERROR:{
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Called'")

		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{
				HTTP.CONN_STATE = CONN_STATE_OFFLINE
			}
		}

		fnDebug(HTTP.DEBUG,DEBUG_STD,"'Carrier Error ',ITOA(DATA.NUMBER),':',DATA.TEXT")
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Ended'")
	}
}


/******************************************************************************
	EoF
******************************************************************************/