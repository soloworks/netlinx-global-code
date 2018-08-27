MODULE_NAME='mTeradek'(DEV vdvControl, DEV ipDevice)
/******************************************************************************
	
	Most of the device operation is done via HTTP requests to the system.cgi API. It's mostly self-documented, and you can see that by doing the following (I think):

	http://ip.address/cgi-bin/system.cgi?command=help

	Note that you need to be logged in to the web UI first, there's a command to do that also, but I don't recall it at the moment.

	Also, all of the device settings can be modified through calls to api.cgi, there are set, save, and apply commands, and an update command that does all three at once. you can also get settings as follows:

	http://ip.address/cgi-bin/api.cgi?command=get

	Updates look like the following:

	http://ip.address/cgi-bin/api.cgi?command=update&Network.Interfaces.Eth0.ipmode=dhcp
	
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_ERROR	   = 2
LONG TLID_COMMS		= 3
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uRequest{
	CHAR		FILE[50]
	CHAR     ARGS[250]
}
DEFINE_TYPE STRUCTURE uSystem{
	INTEGER	CONN_STATE
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	DEBUG
	uRequest	REQ_QUEUE[5]
	CHAR     Tx[1000]
	CHAR		Rx[1000]
	LONG     SESSIONID
	
	CHAR		BROADCAST_STATE[30]
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

DEFINE_VARIABLE
LONG 		TLT_POLL[] 		= {  5000 }
LONG 		TLT_ERROR[] 	= {  2000 }
LONG		TLT_COMMS[]		= { 30000 }
VOLATILE uSystem myTeradek

/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[]){
	IF(myTeradek.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg"
	}
}
DEFINE_FUNCTION fnDebugHTTP(INTEGER pDEBUG,CHAR MsgTitle[100],CHAR MsgData[5000]){
	STACK_VAR pMsgCopy[5000]
	fnDebug(DEBUG_DEV,"'fnDebugHTTP Called'")
	IF(myTeradek.DEBUG >= pDEBUG){
		fnDebug(DEBUG_STD,"'fnDebugHTTP Head STX-----------------------------'")
		// Cope body to prevent issues
		pMsgCopy = MsgData
		// Headers
		WHILE(FIND_STRING(pMsgCopy,"$0D,$0A",1)){
			STACK_VAR CHAR HEADER[100]
			HEADER = REMOVE_STRING(pMsgCopy,"$0D,$0A",1)
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':HEADER:',HEADER"
			IF(HEADER == "$0D,$0A"){
				BREAK
			}
		}
		fnDebug(DEBUG_STD,"'fnDebugHTTP Body STX-----------------------------'")
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMsgCopy"
		fnDebug(DEBUG_STD,"'fnDebugHTTP HTTP ETX-----------------------------'")
	}
	fnDebug(DEBUG_DEV,"'fnDebugHTTP Ended'")
}
/******************************************************************************
	Connection Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Called'")
	fnDebug(DEBUG_STD,"'Connecting to ',myTeradek.IP_HOST,':',ITOA(myTeradek.IP_PORT)")
	myTeradek.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDevice.port, "myTeradek.IP_HOST", myTeradek.IP_PORT, IP_TCP) 
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	IP_CLIENT_CLOSE(ipDevice.port)
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}
DEFINE_FUNCTION fnTimeoutConnection(INTEGER pSTATE){
	IF(TIMELINE_ACTIVE(TLID_ERROR)){TIMELINE_KILL(TLID_ERROR)}
	SWITCH(pSTATE){
		CASE TRUE:{
			TIMELINE_CREATE(TLID_ERROR,TLT_ERROR,LENGTH_ARRAY(TLT_ERROR),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_ERROR]{
	STACK_VAR INTEGER x
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT:TLID_ERROR Called'")
	FOR(x = 1; x <= 5; x++){
		myTeradek.REQ_QUEUE[x].FILE = ''
		myTeradek.REQ_QUEUE[x].ARGS = ''
	}
	myTeradek.Rx = ''
	myTeradek.Tx = ''
	IF(myTeradek.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT:TLID_ERROR Ended'")
}
/******************************************************************************
	Packaging Functions Functions
******************************************************************************/
DEFINE_FUNCTION fnSendAuthRequest(){
	fnQueueRequest('api.cgi','command=login&user=admin&passwd=admin')
}
DEFINE_FUNCTION fnSendRequest(CHAR pParams[]){
	fnQueueRequest('system.cgi',"pParams,'&session=',ITOA(myTeradek.SESSIONID)")
}

DEFINE_FUNCTION fnQueueRequest(CHAR pFILE[],CHAR pARGS[]){
	STACK_VAR INTEGER x
	fnDebug(DEBUG_DEV,"'fnQueueRequest','Called'")
	// Queue Request
	FOR(x = 1; x <= 5; x++){
		IF(!LENGTH_ARRAY(myTeradek.REQ_QUEUE[x].FILE)){
			myTeradek.REQ_QUEUE[x].FILE = pFILE
			myTeradek.REQ_QUEUE[x].ARGS = pARGS
			BREAK
		}
	}
	// Try and Send
	fnSendFromQueue()
	fnInitPoll()
	fnDebug(DEBUG_DEV,"'fnQueueRequest','Ended'")
}
DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug(DEBUG_DEV,"'fnSendFromQueue','Called'")
	IF(myTeradek.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(DEBUG_DEV,"'fnSendFromQueue','Processing'")
		IF(LENGTH_ARRAY(myTeradek.REQ_QUEUE[1].FILE)){
			myTeradek.Tx = fnWrapHTTP(myTeradek.REQ_QUEUE[1].FILE,myTeradek.REQ_QUEUE[1].ARGS)
			IF(1){
				STACK_VAR INTEGER x
				FOR(x = 1; x <= 4; x++){
					myTeradek.REQ_QUEUE[x] = myTeradek.REQ_QUEUE[x+1]
				}
				myTeradek.REQ_QUEUE[5].FILE = ''
				myTeradek.REQ_QUEUE[5].ARGS = ''
			}
			myTeradek.Rx = ''
			fnOpenTCPConnection()
			fnTimeoutConnection(TRUE)
		}
	}
	fnDebug(DEBUG_DEV,"'fnSendFromQueue','Ended'")
}

DEFINE_FUNCTION CHAR[1000] fnWrapHTTP(CHAR pFILE[50],CHAR pARGS[500]){
	STACK_VAR CHAR cToReturn[1000]
	fnDebug(DEBUG_DEV,"'fnWrapHTTP','Called'")
	(** Build Header **)
	cToReturn = "cToReturn,'GET /cgi-bin/',pFILE,'?',pARGS,' HTTP/1.1',$0D,$0A"
	cToReturn = "cToReturn,'Host: ',myTeradek.IP_HOST,':',ITOA(myTeradek.IP_PORT),$0D,$0A"
	cToReturn = "cToReturn,'Connection: Close',$0D,$0A"
	cToReturn = "cToReturn,$0D,$0A"
	(** Combine **)
	fnDebug(DEBUG_DEV,"'fnWrapHTTP','Returning'")
	RETURN( "cToReturn" )
}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	fnDebug(DEBUG_DEV,"'fnInitPoll','Called'")
	// Reset Polling Timer
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	fnDebug(DEBUG_DEV,"'fnInitPoll','Ended'")
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Called'")
	fnPoll()
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Ended'")
}
DEFINE_FUNCTION fnPoll(){
	fnDebug(DEBUG_DEV,"'fnPoll','Ended'")
	fnSendAuthRequest()
	fnDebug(DEBUG_DEV,"'fnPoll','Ended'")
}
/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'POLL':	fnPoll()
					CASE 'QUERY':	fnSendRequest('command=status')
					CASE 'STOP':{
						fnSendRequest('command=broadcast&action=stop')
						WAIT 10{
							fnSendRequest('command=status')
						}
					}
					CASE 'START':{
						fnSendRequest('command=broadcast&action=start')
						WAIT 10{
							fnSendRequest('command=status')
						}
					}
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myTeradek.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myTeradek.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myTeradek.IP_HOST = DATA.TEXT
							myTeradek.IP_PORT = 80 
						}
						fnPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myTeradek.DEBUG = DEBUG_STD
							CASE 'DEV': myTeradek.DEBUG = DEBUG_DEV
							DEFAULT:    myTeradek.DEBUG = DEBUG_ERR
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessFeedback(){
	STACK_VAR INTEGER RESPONSE_CODE
	
	// Process Headers
	fnDebug(DEBUG_STD,"'fnProcessFeedback() Head STX-----------------------------'")
	// Headers
	WHILE(FIND_STRING(myTeradek.Rx,"$0D,$0A",1)){
		STACK_VAR CHAR HEADER[100]
		HEADER = fnStripCharsRight(REMOVE_STRING(myTeradek.Rx,"$0D,$0A",1),2)
		IF(LEFT_STRING(HEADER,4) == 'HTTP'){
			REMOVE_STRING(HEADER,' ',1)
			RESPONSE_CODE = ATOI(REMOVE_STRING(HEADER,' ',1))
			IF(RESPONSE_CODE == 400){
				RETURN 400
			}
		}
		IF(HEADER == ''){
			BREAK
		}
	}
	fnDebug(DEBUG_STD,"'fnProcessFeedback() RESPONSE_CODE=',ITOA(RESPONSE_CODE)")
	
	fnDebug(DEBUG_STD,"'fnProcessFeedback() Body STX-----------------------------'")
	fnDebug(DEBUG_STD,"'fnProcessFeedback() myTeradek.Rx:'")
	fnDebug(DEBUG_STD,"myTeradek.Rx")
	// Check for Session Update
	IF(FIND_STRING(myTeradek.Rx,'Session=',1)){
		fnDebug(DEBUG_STD,"'fnProcessFeedback() Session Response'")
		REMOVE_STRING(myTeradek.Rx,'Session=',1)
		myTeradek.SESSIONID = ATOI(myTeradek.Rx)
		fnSendRequest('command=status')
	}
	ELSE{
		fnDebug(DEBUG_STD,"'fnProcessFeedback() Status Response'")
		IF(FIND_STRING(myTeradek.Rx,'"Broadcast-State":"',1)){
			STACK_VAR CHAR pSTATUS[30]
			REMOVE_STRING(myTeradek.Rx,'"Broadcast-State":"',1)
			pSTATUS = fnStripCharsRight(REMOVE_STRING(myTeradek.Rx,'"',1),1)
			IF(pSTATUS != myTeradek.BROADCAST_STATE){
				myTeradek.BROADCAST_STATE = pSTATUS
				SEND_STRING vdvControl,"'STREAMSTATE-',UPPER_STRING(myTeradek.BROADCAST_STATE)"
			}
		}
	}
	
	fnDebug(DEBUG_STD,"'fnProcessFeedback() HTTP ETX-----------------------------'")
	
	IF(RESPONSE_CODE == 200){
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnTimeoutConnection(FALSE)
	}
	
	RETURN RESPONSE_CODE
}
/******************************************************************************
	IP Device Processing
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, myTeradek.Rx
}
DEFINE_EVENT DATA_EVENT[ipDevice]{ 
	STRING:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT:STRING Called'")
		fnDebug(DEBUG_STD,"'TER->','Partial Response Recieved'")
		fnDebug(DEBUG_DEV,"'DATA_EVENT:STRING Ended'")
	}  
	ONLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT:OFFLINE Called'")
		
		fnDebug(DEBUG_STD,"'TER->','ConnectionOpen'")
		
		fnDebugHTTP(DEBUG_DEV,'->TER',myTeradek.Tx)
		
		myTeradek.CONN_STATE = CONN_STATE_CONNECTED
		SEND_STRING DATA.DEVICE, myTeradek.Tx
		
		fnDebug(DEBUG_STD,"'->TER','Request Sent'")
		myTeradek.Tx = ''
		
		fnDebug(DEBUG_DEV,"'DATA_EVENT:OFFLINE Ended'")
	} 
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONLINE Called'")
		fnDebug(DEBUG_STD,"'TER->','ConnectionClosed'")
		fnDebugHTTP(DEBUG_DEV,'TER->',myTeradek.Rx)
		IF(1){
			STACK_VAR INTEGER RESPONSE_CODE
			RESPONSE_CODE = fnProcessFeedback()
			myTeradek.CONN_STATE = CONN_STATE_OFFLINE
			myTeradek.Rx = ''
			IF(RESPONSE_CODE != 200){
				fnDebug(DEBUG_STD,"'TER->','HTTP Response Error: ',ITOA(RESPONSE_CODE)")
			}
			ELSE{
				fnSendFromQueue()
			}
		}
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONLINE Ended'")
	} 
	ONERROR:{
		STACK_VAR INTEGER x
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONERROR Called'")
		FOR(x = 1; x <= 5; x++){
			myTeradek.REQ_QUEUE[x].FILE = ''
			myTeradek.REQ_QUEUE[x].ARGS = ''
		}
		myTeradek.Rx = ''
		myTeradek.CONN_STATE = CONN_STATE_OFFLINE
		fnDebug(DEBUG_ERR,"'Teradek IP Error ',ITOA(DATA.NUMBER),':',DATA.TEXT")
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONERROR Ended'")
	}
}

/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,1] = (myTeradek.BROADCAST_STATE == 'Ready')
	[vdvControl,2] = (myTeradek.BROADCAST_STATE == 'Starting')
	[vdvControl,3] = (myTeradek.BROADCAST_STATE == 'Live')
	[vdvControl,4] = (myTeradek.BROADCAST_STATE == 'Stopping')
	
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/


