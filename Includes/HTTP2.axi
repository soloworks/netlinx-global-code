PROGRAM_NAME='HTTP2'
/******************************************************************************
	HTTP/2 Implementation Include for Netlinx

   Initial version without TLS

	Reference: https://httpwg.org/specs/rfc7540.html
******************************************************************************/
/******************************************************************************
   HTTP/2 Protocol Constants
******************************************************************************/
DEFINE_CONSTANT

INTEGER HTTP2_FLAG_ACK         = $01
INTEGER HTTP2_FLAG_END_STREAM  = $01
INTEGER HTTP2_FLAG_END_HEADERS = $04
INTEGER HTTP2_FLAG_PADDED      = $08
INTEGER HTTP2_FLAG_PRIORITY    = $20

INTEGER HTTP2_FRAME_TYPE_DATA          = $00
INTEGER HTTP2_FRAME_TYPE_HEADERS       = $01
INTEGER HTTP2_FRAME_TYPE_PRIORITY      = $02
INTEGER HTTP2_FRAME_TYPE_RST_STREAM    = $03
INTEGER HTTP2_FRAME_TYPE_SETTINGS      = $04
INTEGER HTTP2_FRAME_TYPE_PUSH_PROMISE  = $05
INTEGER HTTP2_FRAME_TYPE_PING          = $06
INTEGER HTTP2_FRAME_TYPE_GOAWAY        = $07
INTEGER HTTP2_FRAME_TYPE_WINDOW_UPDATE = $08
INTEGER HTTP2_FRAME_TYPE_CONTINUATION  = $09

INTEGER HTTP2_ERROR_NONE                = $00
INTEGER HTTP2_ERROR_PROTOCOL            = $01
INTEGER HTTP2_ERROR_INTERNAL            = $02
INTEGER HTTP2_ERROR_FLOW_CONTROL        = $03
INTEGER HTTP2_ERROR_SETTINGS_TIMEOUT    = $04
INTEGER HTTP2_ERROR_STREAM_CLOSED       = $05
INTEGER HTTP2_ERROR_FRAME_SIZE          = $06
INTEGER HTTP2_ERROR_REFUSED_STREAM      = $07
INTEGER HTTP2_ERROR_CANCEL              = $08
INTEGER HTTP2_ERROR_COMPRESSION         = $09
INTEGER HTTP2_ERROR_CONNECT             = $0A
INTEGER HTTP2_ERROR_ENHANCE_YOUR_CALM   = $0B
INTEGER HTTP2_ERROR_INADEQUATE_SECURITY = $0C
INTEGER HTTP2_ERROR_HTTP_1_1_REQUIRED   = $0D

CHAR HTTP2ConnPreface[] = 'PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n'
/******************************************************************************
   HTTP/2 Local Constants
******************************************************************************/

LONG     TLID_COMMS		= 1002
LONG     TLID_RETRY 		= 1003

INTEGER HTTP2_MAX_STREAMS  = 5
INTEGER HTTP2_MAX_HEADERS  = 10

INTEGER HTTP2_CONN_STATE_OFFLINE		 = 0
INTEGER HTTP2_CONN_STATE_CONNECTING	 = 1
INTEGER HTTP2_CONN_STATE_NEGOTIATING = 2
INTEGER HTTP2_CONN_STATE_CONNECTED   = 3

INTEGER HTTP2_METHOD_PING  = 00
INTEGER HTTP2_METHOD_GET   = 01
INTEGER HTTP2_METHOD_PUT   = 02
INTEGER HTTP2_METHOD_POST  = 04
/******************************************************************************
   HTTP/2 Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uHTTP2Header{
	CHAR KEY[20]
	CHAR VALUE[50]
}
DEFINE_TYPE STRUCTURE uHTTP2Request{
	uHTTP2Header HEADERS[HTTP2_MAX_HEADERS]
	INTEGER      METHOD
	CHAR         PATH
	CHAR         DATA[1000]
}
DEFINE_TYPE STRUCTURE uHTTP2Frame{
	INTEGER     TYPE
   INTEGER     FLAGS
   INTEGER     IDENTIFIER
   CHAR		   PAYLOAD[8000]
}

DEFINE_TYPE STRUCTURE uHTTP2Stream{
	INTEGER ID
	CHAR    DATA[2000]
}
DEFINE_TYPE STRUCTURE uHTTP2{
	INTEGER		 CONN_STATE
	CHAR 			 IP_HOST[255]
	INTEGER		 IP_PORT
	CHAR 			 Rx[2000]
	CHAR         Tx[8000]
	INTEGER      CURRENT_ID
	uHTTP2Stream STREAM[HTTP2_MAX_STREAMS]
	uDebug       DEBUG
}

/******************************************************************************
   HTTP/2 Variables
******************************************************************************/
DEFINE_VARIABLE
uHTTP2 HTTP2
LONG 			TLT_COMMS[]						= {  45000 }
LONG 			TLT_RETRY[]						= {  10000 }
/******************************************************************************
   HTTP/2 Setup Functions
******************************************************************************/
DEFINE_FUNCTION fnHTTP2SetDebug(uDebug d){
	HTTP2.DEBUG = d
}
/******************************************************************************
	Frame Helper Function
	Converts a Frame structure into an array of bytes

 +-----------------------------------------------+
 |                 Length (24)                   |
 +---------------+---------------+---------------+
 |   Type (8)    |   Flags (8)   |
 +-+-------------+---------------+-------------------------------+
 |R|                 Stream Identifier (31)                      |
 +=+=============================================================+
 |                   Frame Payload (0...)                      ...
 +---------------------------------------------------------------+

******************************************************************************/
DEFINE_FUNCTION CHAR[10000] fnHTTP2BuildFramePacket(uHTTP2Frame f){
	// Set Return Variable
	STACK_VAR CHAR pRETURN[10000]
	// Set Length
	pRETURN = fnLongToByte(LENGTH_ARRAY(f.payload),3)
	// Add Type
	pRETURN = "pRETURN,f.type"
	// Add Flags
	pRETURN = "pRETURN,f.flags"
	// Add payload
	pRETURN = "pRETURN,f.payload"
	// Return
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'fnHTTP2BuildFramePacket','Made Frame'")
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'FRAME: ',fnBytesToString(pRETURN)")
	RETURN pRETURN
}

DEFINE_FUNCTION INTEGER fnHTTP2AddHeader(uHTTP2Header pHeaders[], CHAR pKey[], CHAR pValue[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= HTTP2_MAX_HEADERS; x++){
		IF(pHeaders[x].KEY == '' || pHeaders[x].KEY == pKey){
			pHeaders[x].KEY   = LOWER_STRING(pKey)
			pHeaders[x].VALUE = LOWER_STRING(pValue)
			RETURN x
		}
	}
}

/******************************************************************************
   HTTP/2 Connection Functions
******************************************************************************/
DEFINE_FUNCTION fnHTTP2Connect(){
	IF(HTTP2.CONN_STATE == HTTP2_CONN_STATE_OFFLINE){
		fnHTTP2OpenTCPConnection()
	}
}
DEFINE_FUNCTION fnHTTP2OpenTCPConnection(){
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'fnHTTP2OpenTCPConnection','Called'")
	fnDebug(HTTP2.DEBUG,DEBUG_STD,"'Requesting HTTP/2 to ',HTTP2.IP_HOST,':',ITOA(HTTP2.IP_PORT)")
	HTTP2.CONN_STATE = HTTP2_CONN_STATE_CONNECTING
	SWITCH(HTTP2.IP_PORT){
		CASE 443:  TLS_CLIENT_OPEN(ipHTTP2.port, "HTTP2.IP_HOST", HTTP2.IP_PORT, 0)
		DEFAULT:    IP_CLIENT_OPEN(ipHTTP2.port, "HTTP2.IP_HOST", HTTP2.IP_PORT, IP_TCP)
	}
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'fnHTTP2OpenTCPConnection','Ended'")
}

DEFINE_FUNCTION fnHTTP2Reset(){
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'fnHTTP2Reset','Called'")
	HTTP2.Rx = ''
	IF(HTTP2.CONN_STATE != HTTP2_CONN_STATE_OFFLINE){
		SWITCH(HTTP2.IP_PORT){
			CASE 443:  TLS_CLIENT_CLOSE(ipHTTP2.port)
			DEFAULT:    IP_CLIENT_CLOSE(ipHTTP2.port)
		}
	}
	fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'fnHTTP2Reset','Ended'")

}

DEFINE_FUNCTION fnRetryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnHTTP2Connect()
}
DEFINE_FUNCTION INTEGER IsHTTP2Online(){
	RETURN HTTP2.CONN_STATE == HTTP2_CONN_STATE_CONNECTED
}

/******************************************************************************
	Data Handling
******************************************************************************/
DEFINE_FUNCTION fnHTTP2SendRequest(
	INTEGER METHOD,
	CHAR    PATH[],
	CHAR    DATA[]
){
	// Setup a new Request
	STACK_VAR uHTTP2Request r
	// Add in new headers for Method, Schema and Path
	fnHTTP2AddHeader(r.headers,'method',

	// Setup a new Frame
	STACK_VAR uHTTP2Frame f
	f.identifier = HTTP2.CURRENT_ID
	f.type = HTTP2_FRAME_TYPE_HEADERS


	fnAddToQueue(fnHTTP2BuildFramePacket(f))
}
/******************************************************************************
	IP Socket Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipHTTP2]{
	STRING:{
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'ipHTTP2 DATA_EVENT STRING Called'")
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'DATA: ',fnBytesToString(DATA.TEXT)")
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'ipHTTP2 DATA_EVENT STRING Ended'")
	}
	OFFLINE:{
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'WS DATA_EVENT OFFLINE Called'")
		HTTP2.CONN_STATE = HTTP2_CONN_STATE_OFFLINE
		fnHTTP2Reset()
		//fnPingActive(FALSE)
		fnRetryConnection()
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'WS DATA_EVENT OFFLINE Ended'")
	}
	ONLINE:{
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'WS DATA_EVENT ONLINE Called'")
		// Set IP state to Negotitin
		HTTP2.CONN_STATE = HTTP2_CONN_STATE_NEGOTIATING
		// Send the HTTP request through to the server
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'->HTTP2: ',HTTP2ConnPreface")
		SEND_STRING DATA.DEVICE, HTTP2ConnPreface

		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'DATA_EVENT ONLINE Ended'")
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[20]
		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Called'")

		SWITCH(DATA.NUMBER){
			CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
			CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
			CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{
				HTTP2.CONN_STATE = HTTP2_CONN_STATE_OFFLINE
				//fnResetWS()
				fnRetryConnection()
			}
		}

		fnDebug(HTTP2.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Ended'")
	}
}

/******************************************************************************
   EoF
******************************************************************************/
