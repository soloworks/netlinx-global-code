MODULE_NAME='mHTTP'(DEV vdvHTTP, DEV ipClient)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	HTTP Connection Module

	TODO: HTTP/S

******************************************************************************/
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_CONNECTED  	= 2

INTEGER _MAX_HEADERS        = 10
INTEGER _MAX_ARGS           = 10
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE Structure uKeyPair{
	CHAR KEY[30]
	CHAR VAL[100]
}

DEFINE_TYPE STRUCTURE uRequest{
	CHAR     METHOD[15]
	CHAR     PATH[500]
	uKeyPair ARGS[_MAX_ARGS]
	uKeyPair HEADERS[_MAX_HEADERS]
	CHAR     BODY[10000]
}

DEFINE_TYPE STRUCTURE uResponse{
	INTEGER	CODE
	INTEGER  KEEP_ALIVE
	INTEGER  ContentLength
	INTEGER  BodyLength
	INTEGER  HEADERS_PROCESSED
}

DEFINE_TYPE STRUCTURE uHTTP{
	INTEGER		CONN_STATE
	INTEGER     USE_HTTPS
	CHAR 			IP_HOST[255]
	INTEGER		IP_PORT
	CHAR 			Rx[10000]
	uRequest    REQUEST
	uResponse	RESPONSE
	INTEGER     FORCE_CLOSE
	uDebug      DEBUG
}
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
uHTTP HTTP
/******************************************************************************
	Build Up
******************************************************************************/
DEFINE_START{
	// Setup Receive Buffer
	CREATE_BUFFER ipClient, HTTP.Rx
}

/******************************************************************************
	Connection Helpers
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Called'")
	fnDebug(HTTP.DEBUG,DEBUG_STD,"'Connecting to ',HTTP.IP_HOST,':',ITOA(HTTP.IP_PORT)")
	HTTP.CONN_STATE = CONN_STATE_CONNECTING
	SWITCH(HTTP.USE_HTTPS){
		CASE TRUE:  TLS_CLIENT_OPEN(ipClient.port, "HTTP.IP_HOST", HTTP.IP_PORT, 0)
		CASE FALSE:  IP_CLIENT_OPEN(ipClient.port, "HTTP.IP_HOST", HTTP.IP_PORT, IP_TCP)
	}
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	SWITCH(HTTP.USE_HTTPS){
		CASE TRUE:  TLS_CLIENT_CLOSE(ipClient.port)
		CASE FALSE:  IP_CLIENT_CLOSE(ipClient.port)
	}
	fnDebug(HTTP.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}
/******************************************************************************
	Handle Control Device Data
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvHTTP]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':HTTP.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV': HTTP.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:    HTTP.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
					}
				}
			}
			CASE 'HTTP':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'HTTPS':HTTP.USE_HTTPS = (DATA.TEXT == 'TRUE')
					CASE 'HOST':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							HTTP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							HTTP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							HTTP.IP_HOST = DATA.TEXT
							SWITCH(HTTP.USE_HTTPS){
								CASE TRUE:  HTTP.IP_PORT = 443
								CASE FALSE: HTTP.IP_PORT = 80
							}
						}
					}
					CASE 'METHOD':{
						HTTP.REQUEST.METHOD = UPPER_STRING(DATA.TEXT)
					}
					CASE 'PATH':	HTTP.REQUEST.PATH = DATA.TEXT
					CASE 'ARGUMENT':{
						STACK_VAR INTEGER x
						FOR(x = 1; x <= _MAX_ARGS; x++){
							IF(HTTP.REQUEST.ARGS[x].KEY == fnGetCSV(DATA.TEXT,1) || HTTP.REQUEST.ARGS[x].KEY = ''){
								HTTP.REQUEST.ARGS[x].KEY = fnGetCSV(DATA.TEXT,1)
								HTTP.REQUEST.ARGS[x].VAL = fnGetCSV(DATA.TEXT,2)
								BREAK
							}
						}
					}
					CASE 'HEADER':fnAddHeader(fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2))
					CASE 'BODY':{
						SWITCH(HTTP.CONN_STATE){
							CASE CONN_STATE_CONNECTED:{
								SEND_STRING ipClient,DATA.TEXT
								fnDebug(HTTP.DEBUG,DEBUG_DEV,"'->HTTP',DATA.TEXT")
							}
							DEFAULT:{
								HTTP.REQUEST.BODY = "HTTP.REQUEST.BODY,DATA.TEXT"
								fnAddHeader('Content-Length',ITOA(LENGTH_ARRAY(HTTP.REQUEST.BODY)))
							}
						}						
					}
					CASE 'SUBMIT':{
						// Checks and Balances
						IF(HTTP.IP_HOST = ''){
							fnDebug(HTTP.DEBUG,DEBUG_ERR,'HTTP HOST Missing')
							SEND_STRING vdvHTTP,'ERROR-HTTP HOST Missing'
						}						
						ELSE IF(HTTP.IP_PORT = 0){
							fnDebug(HTTP.DEBUG,DEBUG_ERR,'HTTP PORT Missing')
							SEND_STRING vdvHTTP,'ERROR-HTTP PORT Missing'
						}							
						ELSE IF(HTTP.REQUEST.METHOD = ''){
							fnDebug(HTTP.DEBUG,DEBUG_ERR,'HTTP METHOD Missing')
							SEND_STRING vdvHTTP,'ERROR-HTTP METHOD Missing'
						}					
						ELSE{
							IF(HTTP.REQUEST.PATH = ''){HTTP.REQUEST.PATH = '/'}
							fnOpenTCPConnection()
						}
					}
					CASE 'RESET':  fnReset()
				}
			}
		}
	}
}

/******************************************************************************
	HTTP Build Helpers
******************************************************************************/
DEFINE_FUNCTION fnReset(){
	STACK_VAR uRequest  blankRequest
	STACK_VAR uResponse blankResponse
	HTTP.REQUEST  = blankRequest
	HTTP.RESPONSE = blankResponse
	IF(HTTP.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION INTEGER fnAddHeader(CHAR key[], CHAR val[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= _MAX_ARGS; x++){
		IF(HTTP.REQUEST.HEADERS[x].KEY == key || HTTP.REQUEST.HEADERS[x].KEY = ''){
			HTTP.REQUEST.HEADERS[x].KEY = key
			HTTP.REQUEST.HEADERS[x].VAL = val
			RETURN x
		}
	}
	RETURN 0
}

/******************************************************************************
	IP Data Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipClient]{
	ONLINE:{
		STACK_VAR CHAR chunk[2000]
		STACK_VAR INTEGER x
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT ONLINE Called'")
		HTTP.CONN_STATE = CONN_STATE_CONNECTED
		// Set Method
		chunk = HTTP.REQUEST.METHOD
		// Set Path
		chunk = "chunk,' ',HTTP.REQUEST.PATH"
		// Set Arguments if present
		IF(HTTP.REQUEST.ARGS[1].KEY != ''){
			// Add Args Delim
			chunk = "chunk,'?'"
			// Add all Args
			FOR(x = 1; x <= _MAX_ARGS; x++){
				// Add Delimiter
				IF(x > 1){chunk = "chunk,'&'"}
				chunk = "chunk,HTTP.REQUEST.ARGS[x].KEY,'=',HTTP.REQUEST.ARGS[x].VAL"
			}
		}
		// Set HTTP ver
		chunk = "chunk,' HTTP/1.0',$0D,$0A"
		// Send Chunk
		fnDebug(HTTP.DEBUG,DEBUG_STD,"'HTTP->',chunk")
		SEND_STRING ipClient, chunk
		
		// Add Custom headers
		FOR(x = 1; x <= _MAX_HEADERS; x++){
			IF(HTTP.REQUEST.HEADERS[x].KEY != ''){
				chunk = "HTTP.REQUEST.HEADERS[x].KEY,': ',HTTP.REQUEST.HEADERS[x].VAL,$0D,$0A"
				fnDebug(HTTP.DEBUG,DEBUG_STD,"'HTTP->',chunk")
				SEND_STRING ipClient, chunk
			}
		}
		// Finish Head
		chunk = "$0D,$0A"
		fnDebug(HTTP.DEBUG,DEBUG_STD,"'HTTP->',chunk")
		SEND_STRING ipClient, chunk
		
		// Send Body (if present)
		WHILE(LENGTH_ARRAY(HTTP.REQUEST.BODY)){
			chunk = GET_BUFFER_STRING(HTTP.REQUEST.BODY,250)
			fnDebug(HTTP.DEBUG,DEBUG_STD,"'HTTP->',chunk")
			SEND_STRING ipClient, chunk
		}
		
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONLINE Ended'")
	}
	STRING:{
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT STRING Called'")
		fnDebugHTTP(HTTP.DEBUG,DEBUG_DEV,"HTTP.Rx")
		fnProcessResponse()
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT STRING Ended'")
	}
	OFFLINE:{
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT OFFLINE Called'")
		HTTP.CONN_STATE = CONN_STATE_OFFLINE
		fnReset()
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'HTTP DATA_EVENT OFFLINE Ended'")
	}
	ONERROR:{
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Called'")
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{
				HTTP.CONN_STATE = CONN_STATE_OFFLINE
				fnReset()
			}
		}
		fnDebug(HTTP.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Ended'")
	}
}

DEFINE_FUNCTION fnProcessResponse(){
	// Process the Status Line
	IF(!HTTP.RESPONSE.CODE && FIND_STRING(HTTP.Rx,"$0D,$0A",1)){
		SEND_STRING vdvHTTP,"'HTTP_VERSION-',fnStripCharsRight(REMOVE_STRING(HTTP.Rx,' ',1),1)"
		HTTP.RESPONSE.CODE = ATOI(REMOVE_STRING(HTTP.Rx,' ',1))
		SEND_STRING vdvHTTP,"'HTTP_STATUS_CODE-',ITOA(HTTP.RESPONSE.CODE)"
		SEND_STRING vdvHTTP,"'HTTP_STATUS_PHRASE-',fnStripCharsRight(REMOVE_STRING(HTTP.Rx,"$0D,$0A",1),1)"
	}
	
	// Process Header whilst relevant
	WHILE(!HTTP.RESPONSE.HEADERS_PROCESSED && FIND_STRING(HTTP.Rx,"$0D,$0A",1)){
		STACK_VAR CHAR HEAD_LINE[200]

		// Gather HTTP Code
		HEAD_LINE = fnStripCharsRight(REMOVE_STRING(HTTP.Rx,"$0D,$0A",1),2)
		
		IF(HEAD_LINE == ''){
			HTTP.RESPONSE.HEADERS_PROCESSED = TRUE
		}
		ELSE{
			STACK_VAR CHAR key[200]
			STACK_VAR CHAR val[200]
			
			key = fnStripCharsRight(REMOVE_STRING(HEAD_LINE,':',1),1)
			val = fnRemoveWhiteSpace(HEAD_LINE)
			
			SEND_STRING vdvHTTP,"'HTTP_HEADER-',key,',',val"
			
			IF(key == 'Content-Length'){HTTP.RESPONSE.ContentLength = ATOI(val)}
		}
	}
	
	// Process body
	WHILE(LENGTH_ARRAY(HTTP.Rx)){
		STACK_VAR CHAR chunk[250]
		chunk = GET_BUFFER_STRING(HTTP.Rx,250)
		SEND_STRING vdvHTTP,"'HTTP_BODY-',chunk"
		HTTP.RESPONSE.BodyLength = HTTP.RESPONSE.BodyLength + LENGTH_ARRAY(chunk)
		IF(HTTP.FORCE_CLOSE && HTTP.RESPONSE.BodyLength == HTTP.RESPONSE.ContentLength){
			fnReset()
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/