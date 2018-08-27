PROGRAM_NAME='WebSockets'
/******************************************************************************
	WebSocket Connection Include

******************************************************************************/
DEFINE_CONSTANT
INTEGER WS_FRAME_TYPE_TEXT  = 129	// first byte indicates FIN, Text-Frame (10000001)
INTEGER WS_FRAME_TYPE_CLOSE = 136	// first byte indicates FIN, Close Frame(10001000)
INTEGER WS_FRAME_TYPE_PING  = 137	// first byte indicates FIN, Ping frame (10001001)
INTEGER WS_FRAME_TYPE_PONG  = 138	// first byte indicates FIN, Pong frame (10001010)

INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_NEGOTIATING	= 2
INTEGER	CONN_STATE_CONNECTED  	= 3

LONG     TLID_PING		= 1001
LONG     TLID_COMMS		= 1002
LONG     TLID_RETRY 		= 1003

INTEGER _MAX_HEADERS = 25

DEFINE_TYPE Structure uHeader{
	CHAR KEY[30]
	CHAR VALUE[100]
}

DEFINE_TYPE STRUCTURE uHTTPResp{
	uHeader  HEADER[_MAX_HEADERS]
	INTEGER	HTTP_CODE
}

DEFINE_TYPE STRUCTURE uWebSocket{
	INTEGER		CONN_STATE
	CHAR 			IP_HOST[255]
	INTEGER		IP_PORT
	CHAR        ORIGIN[255]
	CHAR 			Rx[10000]
	uHTTPResp	RESPONSE
	uDebug      DEBUG
}

DEFINE_VARIABLE
uWebSocket  WS
LONG 			TLT_PING[] 						= {  15000 }
LONG 			TLT_COMMS[]						= {  45000 }
LONG 			TLT_RETRY[]						= {  10000 }

DEFINE_START{
	// Setup Receive Buffer
	CREATE_BUFFER ipWS, WS.Rx
}
/******************************************************************************
	Frame Helpers
******************************************************************************/
DEFINE_FUNCTION CHAR[10000] fnBuildFrame(INTEGER frameType,CHAR payLoad[10000],INTEGER masked){
	STACK_VAR INTEGER x
	STACK_VAR CHAR mask[4]
	STACK_VAR CHAR frame[10000]
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame','Called'")

	// Set the first byte
	SWITCH(frameType){
		CASE WS_FRAME_TYPE_TEXT:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Setting Frame Type Text'")
		CASE WS_FRAME_TYPE_CLOSE:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Setting Frame Type Close'")
		CASE WS_FRAME_TYPE_PING:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Setting Frame Type Ping'")
		CASE WS_FRAME_TYPE_PONG:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Setting Frame Type Pong'")
	}
	frame = "frameType"

	// set mask and payload length (This has additional for over 65535, but AMX won't do an array that size...)

	SWITCH(frameType){
		CASE WS_FRAME_TYPE_TEXT:{
			fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame payLoad len= ',ITOA(LENGTH_ARRAY(payLoad))")
			IF(LENGTH_ARRAY(payLoad) > 125){
				fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Mask and payLoad for > 125 length'")
				// Set indicator that this uses two length bytes
				SWITCH(masked){
					CASE TRUE:  frame = "frame,254"
					CASE FALSE: frame = "frame,126"
				}
				// Set Length Bytes
				frame = "frame, HEXTOI(LEFT_STRING(FORMAT('%04x',LENGTH_ARRAY(payLoad)),2))"
				frame = "frame, HEXTOI(RIGHT_STRING(FORMAT('%04x',LENGTH_ARRAY(payLoad)),2))"
			}
			ELSE{
				fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Mask and payLoad for <= 125 length'")
				SWITCH(masked){
					CASE TRUE:  frame = "frame,LENGTH_ARRAY(payLoad)+128"
					CASE FALSE: frame = "frame,LENGTH_ARRAY(payLoad)"
				}
			}
		}
		// Generate a Mask if required
		IF(masked){
			fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Generating Mask'")
			FOR(x = 1; x <= 4; x++){
				mask = "mask,RANDOM_NUMBER(255)"
			}
			//mask = "$01,$02,$03,$04"
			frame = "frame,mask"
		}

		// Add the Payload and mask if required
		fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Processing Payload'")
		FOR(x = 1; x <= LENGTH_ARRAY(payLoad); x++){
			SWITCH(masked){
				CASE FALSE:frame = "frame,payLoad[x]"
				CASE TRUE:{
					STACK_VAR INTEGER y
					y = ((x-1)%4)+1
					frame = "frame,payLoad[x] BXOR mask[y]"
				}
			}
		}
	}

	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildFrame Returning Data (Length ',ITOA(LENGTH_ARRAY(frame)),')'")
	// Return Frame
	RETURN frame
}
DEFINE_FUNCTION INTEGER fnProcessFrame(){
	STACK_VAR INTEGER masked
	STACK_VAR INTEGER payloadLen
	STACK_VAR INTEGER headLen
	STACK_VAR CHAR    mask[4]
	STACK_VAR CHAR    payLoad[10000]
	STACK_VAR INTEGER x
	STACK_VAR INTEGER FRAME_TYPE

	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnProcessFrame','Called'")

	// Set the first byte
	FRAME_TYPE = WS.Rx[1]
	SWITCH(WS.Rx[1]){
		CASE WS_FRAME_TYPE_TEXT:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnProcessFrame Detected Frame Type Text'")
		CASE WS_FRAME_TYPE_CLOSE:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnProcessFrame Detected Frame Type Close'")
		CASE WS_FRAME_TYPE_PING:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnProcessFrame Detected Frame Type Ping'")
		CASE WS_FRAME_TYPE_PONG:	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnProcessFrame Detected Frame Type Pong'")
	}

	// Check for mask
	masked = (WS.Rx[2] > 128)
	// Work out Length
	SWITCH(WS.Rx[2] - (128*masked)){
		CASE 127:{} // Too long to be handled by AMX
		CASE 126:{
			// Longer than 125
			payloadLen = HEXTOI("FORMAT('%02x',WS.Rx[3]),FORMAT('%02x',WS.Rx[4])")
			headLen    = 4 + (4*masked)
			IF(masked){mask = MID_STRING(WS.Rx,5,4)}
		}
		DEFAULT:{
			// 125 or shorter
			payloadLen = WS.Rx[2] - masked*128
			headLen = 2 + (4*masked)
			IF(masked){mask = MID_STRING(WS.Rx,3,4)}
		}
	}
	SWITCH(FRAME_TYPE){
		CASE WS_FRAME_TYPE_PING:
		CASE WS_FRAME_TYPE_PONG:{
			GET_BUFFER_STRING(WS.Rx,headLen)
			RETURN TRUE
		}
	}
	// If we don't have enough data we should bail for now
	IF(LENGTH_ARRAY(WS.Rx) < headLen+payloadLen){
		RETURN FALSE
	}
	// Remove the header
	GET_BUFFER_STRING(WS.Rx,headLen)

	// Process Payload
	FOR(x = 1; x <= payloadLen; x++){
		SWITCH(masked){
			CASE FALSE:payLoad = "payLoad,GET_BUFFER_CHAR(WS.Rx)"
			CASE TRUE:{
				STACK_VAR INTEGER y
				y = ((x-1)%4)+1
				payLoad = "payLoad,GET_BUFFER_CHAR(WS.Rx) BXOR mask[y]"
			}
		}
	}

	// Debug Out
	fnDebug(WS.DEBUG,DEBUG_STD,"'WS->: ',payLoad")

	// Trigger Event
	SWITCH(FRAME_TYPE){
		CASE WS_FRAME_TYPE_TEXT:{
			eventReceivedText(payLoad)
			RETURN TRUE
		}
		CASE WS_FRAME_TYPE_PONG:{
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		CASE WS_FRAME_TYPE_PING:{
			fnSendFrame(fnBuildFrame(WS_FRAME_TYPE_PONG,'',FALSE))
		}
	}
}

/******************************************************************************
	Connection Helpers
******************************************************************************/
DEFINE_FUNCTION CHAR[10000] HTTPSocketRequest(){
	STACK_VAR CHAR cToReturn[10000]
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildSocketRequest','Called'")

	(** Build Header **)
	cToReturn = "cToReturn,'GET ws://',WS.IP_HOST,':',ITOA(WS.IP_PORT),'/?encoding=text',' HTTP/1.1',$0D,$0A"
	cToReturn = "cToReturn,'Host: ',WS.IP_HOST,':',ITOA(WS.IP_PORT),$0D,$0A"
	cToReturn = "cToReturn,'Upgrade: websocket',$0D,$0A"
	cToReturn = "cToReturn,'Connection: Upgrade',$0D,$0A"
	cToReturn = "cToReturn,'Pragma: no-cache',$0D,$0A"
	cToReturn = "cToReturn,'Cache-Control: no-cache',$0D,$0A"
	// Sec-Websocket-Key required to perform a Challenge/Response
	cToReturn = "cToReturn,'Sec-WebSocket-Key: 5wBC505gIw/x1Lo6MzqaxA==',$0D,$0A"
	// Websocket Version (13 is latest)
	cToReturn = "cToReturn,'Sec-WebSocket-Version: 13',$0D,$0A"
	// Origin Header
	cToReturn = "cToReturn,'Origin: ',WS.ORIGIN,$0D,$0A"
	cToReturn = "cToReturn,$0D,$0A"
	(** Combine **)
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnBuildSocketRequest','Returning'")
	RETURN cToReturn

}

DEFINE_FUNCTION fnConnectWS(){
	IF(WS.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Called'")
	fnDebug(WS.DEBUG,DEBUG_STD,"'Connecting to ',WS.IP_HOST,':',ITOA(WS.IP_PORT)")
	WS.CONN_STATE = CONN_STATE_CONNECTING
	SWITCH(WS.IP_PORT){
		CASE 443:  TLS_CLIENT_OPEN(ipWS.port, "WS.IP_HOST", WS.IP_PORT, 0)
		DEFAULT:    IP_CLIENT_OPEN(ipWS.port, "WS.IP_HOST", WS.IP_PORT, IP_TCP)
	}
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
}

DEFINE_FUNCTION fnCloseWS(){
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	SWITCH(WS.IP_PORT){
		CASE 443:  TLS_CLIENT_CLOSE(ipWS.port)
		DEFAULT:    IP_CLIENT_CLOSE(ipWS.port)
	}
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}

DEFINE_FUNCTION fnRetryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnConnectWS()
}
DEFINE_FUNCTION INTEGER wsOnline(){
	RETURN WS.CONN_STATE == CONN_STATE_CONNECTED
}
/******************************************************************************
	PINGing Helpers
******************************************************************************/
DEFINE_FUNCTION fnPingActive(INTEGER pState){
	IF(TIMELINE_ACTIVE(TLID_PING)){TIMELINE_KILL(TLID_PING)}
	TIMELINE_CREATE(TLID_PING,TLT_PING,1,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_PING]{
	fnDebug(WS.DEBUG,DEBUG_DEV,"'TIMELINE_EVENT','TLID_PING Called'")

	fnSendFrame(fnBuildFrame(WS_FRAME_TYPE_PING,'YouThere?',FALSE))

	fnDebug(WS.DEBUG,DEBUG_DEV,"'TIMELINE_EVENT','TLID_PING Ended'")
}

/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_FUNCTION fnSendTextFrame(CHAR pText[10000]){
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnSendTextFrame Called'")

	IF(WS.CONN_STATE == CONN_STATE_CONNECTED && LENGTH_ARRAY(pText)){
		fnDebug(WS.DEBUG,DEBUG_STD,"'->WS: ',pText")
		fnSendFrame(fnBuildFrame(WS_FRAME_TYPE_TEXT,pText,TRUE))
	}

	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnSendText Ended'")
}

DEFINE_FUNCTION fnSendFrame(CHAR frame[10000]){
	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnSendFrame Called'")

	IF(WS.CONN_STATE == CONN_STATE_CONNECTED){
		SEND_STRING ipWS,frame
		//fnDebug(WS.DEBUG,DEBUG_DEV,"'fnSendFrame Sent: ',frame")
	}

	fnDebug(WS.DEBUG,DEBUG_DEV,"'fnSendTextFrame Ended'")
}

/******************************************************************************
	IP Data Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipWS]{
	STRING:{
		fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT STRING Called'")

		// IF we aren't connected up yet, so handle handshaking
		IF(WS.CONN_STATE != CONN_STATE_CONNECTED){
			// Process the Header
			IF(FIND_STRING(WS.Rx,"$0D,$0A,$0D,$0A",1)){
				STACK_VAR CHAR HEAD_LINE[200]
				fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT STRING Handling HTTP Handshaking'")
				fnDebug(WS.DEBUG,DEBUG_DEV,"'WSHTTP->',WS.Rx")
				
				// Gather HTTP Code
				HEAD_LINE = fnStripCharsRight(REMOVE_STRING(WS.Rx,"$0D,$0A",1),2)
				WS.RESPONSE.HTTP_CODE = ATOI(fnGetSplitStringValue(HEAD_LINE,' ',2))

				// Store rest of Headers
				WHILE(FIND_STRING(WS.Rx,"$0D,$0A",1)){
					HEAD_LINE = fnStripCharsRight(REMOVE_STRING(WS.Rx,"$0D,$0A",1),2)
					IF(HEAD_LINE != ''){
						STACK_VAR INTEGER x
						fnDebug(WS.DEBUG,DEBUG_DEV,"'Header->',HEAD_LINE")
						FOR(x = 1; x <= _MAX_HEADERS; x++){
							IF(WS.RESPONSE.HEADER[x].KEY = ''){
								WS.RESPONSE.HEADER[x].KEY = fnStripCharsRight(REMOVE_STRING(HEAD_LINE,':',1),1)
								WS.RESPONSE.HEADER[x].VALUE = fnRemoveWhiteSpace(HEAD_LINE)
								BREAK
							}
						}
					}
					ELSE{
						BREAK
					}
				}
				
				// Report anything except a good request
				SWITCH(WS.RESPONSE.HTTP_CODE){
					CASE 101:{	// Switching Protocols
						fnDebug(WS.DEBUG,DEBUG_STD,"'CAR->HTTP Response Code ',ITOA(WS.RESPONSE.HTTP_CODE)")
						WS.CONN_STATE = CONN_STATE_CONNECTED
						// Call back to init data
						eventWSOnline()
						//fnPingActive(TRUE)
					}
					DEFAULT:{
						fnDebug(WS.DEBUG,DEBUG_ERR,"'CAR->HTTP Response Code ',ITOA(WS.RESPONSE.HTTP_CODE)")
					}
				}
			}
		}
		
		IF(WS.CONN_STATE == CONN_STATE_CONNECTED){
			// Process Frames
			fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT STRING Handling Socket Data'")
			WHILE(fnProcessFrame()){}
		}

		fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT STRING Ended'")
	}
	OFFLINE:{
		fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT OFFLINE Called'")
		WS.CONN_STATE = CONN_STATE_OFFLINE
		fnResetWS()
		eventWSOffline()
		//fnPingActive(FALSE)
		fnRetryConnection()
		fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT OFFLINE Ended'")
	}
	ONLINE:{
		fnDebug(WS.DEBUG,DEBUG_DEV,"'WS DATA_EVENT ONLINE Called'")
		// Set IP state to Negotitin
		WS.CONN_STATE = CONN_STATE_NEGOTIATING
		// Clear down any values for completion
		fnResetWS()
		// Send the HTTP request through to the server
		fnDebug(WS.DEBUG,DEBUG_DEV,"'->WSHTTP',HTTPSocketRequest()")
		SEND_STRING DATA.DEVICE, HTTPSocketRequest()
		
		fnDebug(WS.DEBUG,DEBUG_DEV,"'DATA_EVENT ONLINE Ended'")
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[20]
		fnDebug(WS.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Called'")

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
				WS.CONN_STATE = CONN_STATE_OFFLINE
				fnResetWS()
				fnRetryConnection()
			}
		}

		fnDebug(WS.DEBUG,DEBUG_STD,"'Carrier Error ',ITOA(DATA.NUMBER),':',_MSG")
		fnDebug(WS.DEBUG,DEBUG_DEV,"'DATA_EVENT ONERROR Ended'")
	}
}

DEFINE_FUNCTION fnResetWS(){
	STACK_VAR uHTTPResp blankRepsonse
	WS.RESPONSE = blankRepsonse
	WS.Rx = ''
}

/******************************************************************************
	EoF
******************************************************************************/