MODULE_NAME='mEncodedMediaEncoder'(DEV vdvControl, DEV ipDevice)
/******************************************************************************
	Control Notes from Richard Poel @ MoneySuperMarket site london


user:  ipcontrol
pass:  IPc0ntr0l

start
http://10.17.180.179/admin/quickrecord.php?op=START&password=ee82953ed3f2a505ac03a9fae84e908a&username=ipcontrol&duration=300&format=csv

output
##############
Camera,1,,0
Slides,1,,0
##############

status command
http://10.17.180.179/admin/quickrecord.php?op=STATUS&password=ee82953ed3f2a505ac03a9fae84e908a&username=ipcontrol&duration=300&format=csv

###################
Camera,1,,79
Slides,1,,79
###################
(last number is number of seconds the recording has been running for, so you can provide "Recording XX:XX" feedback)

stop
http://10.17.180.179/admin/quickrecord.php?op=STOP&password=ee82953ed3f2a505ac03a9fae84e908a&username=ipcontrol&duration=300&format=csv

##################
Camera,0,,
Slides,0,,
##################
no number means no recording


#########
Note the duration=300 means 300 minutes, so if they forget to stop it, it will stop after 5 hrs. This can be increased if they are going to have huge meetings.
******************************************************************************/

INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			  = 1
LONG TLID_ERROR	     = 2
LONG TLID_COMMS		  = 3

INTEGER LEN_REQ_ARRAY = 5
INTEGER LEN_ARG_ARRAY = 10

/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uFeed{
	CHAR    NAME[30]
	INTEGER LIVE
	INTEGER DURATION
}
DEFINE_TYPE STRUCTURE uArg{
	CHAR KEY[20]
	CHAR VAL[100]
}
DEFINE_TYPE STRUCTURE uRequest{
	CHAR     PATH[50]
	CHAR		FILE[25]
	uArg     ARGS[LEN_ARG_ARRAY]
}
DEFINE_TYPE STRUCTURE uSystem{
	INTEGER	CONN_STATE
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	DEBUG
	uRequest	REQ_QUEUE[LEN_REQ_ARRAY]
	CHAR     Tx[12000]
	CHAR		Rx[12000]
	CHAR     USERNAME[20]
	CHAR     PASSWORD[50]

	uFeed	   FEED[5]
}

DEFINE_FUNCTION fnAddArg(uRequest R, CHAR pKey[], CHAR pValue[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LEN_ARG_ARRAY; x++){
		IF(R.ARGS[x].KEY == pKey || R.ARGS[x].KEY = ''){
			R.ARGS[x].KEY = pKey
			R.ARGS[x].VAL = pValue
			RETURN
		}
	}
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
LONG 		TLT_POLL[] 		= { 15000 }
LONG 		TLT_ERROR[] 	= {  2000 }
LONG		TLT_COMMS[]		= { 30000 }

VOLATILE uSystem myEncoder
/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[]){
	IF(myEncoder.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg"
	}
}
DEFINE_FUNCTION fnDebugHTTP(INTEGER pDEBUG,CHAR MsgTitle[100],CHAR MsgData[10000]){
	STACK_VAR pMsgCopy[5000]
	fnDebug(DEBUG_DEV,"'fnDebugHTTP Called',MsgTitle")
	IF(myEncoder.DEBUG >= pDEBUG){
		fnDebug(DEBUG_STD,"'fnDebugHTTP Head STX-----------------------------'")
		// Cope body to prevent issues
		pMsgCopy = MsgData
		// Headers
		WHILE(FIND_STRING(pMsgCopy,"$0D,$0A",1)){
			STACK_VAR CHAR HEADER[200]
			HEADER = REMOVE_STRING(pMsgCopy,"$0D,$0A",1)
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':HEADER:',HEADER"
			IF(HEADER == "$0D,$0A"){ BREAK }
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
	fnDebug(DEBUG_STD,"'Connecting to ',myEncoder.IP_HOST,':',ITOA(myEncoder.IP_PORT)")
	myEncoder.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDevice.port, "myEncoder.IP_HOST", myEncoder.IP_PORT, IP_TCP)
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
	FOR(x = 1; x <= LEN_REQ_ARRAY; x++){
		STACK_VAR uRequest blankREQ
		myEncoder.REQ_QUEUE[x] = blankREQ
	}
	myEncoder.Rx = ''
	myEncoder.Tx = ''
	IF(myEncoder.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT:TLID_ERROR Ended'")
}
/******************************************************************************
	Packaging Functions Functions
******************************************************************************/
DEFINE_FUNCTION fnSendQuickRecord(CHAR pCMD[]){
	STACK_VAR uRequest myRequest
	// Setup API Call
	myRequest.PATH = 'admin'
	myRequest.FILE = 'quickrecord.php'
	// Add Operation Argument
	fnAddArg(myRequest,'op',pCMD)
	// Add Password
	fnAddArg(myRequest,'password',myEncoder.PASSWORD)
	// Add Username
	fnAddArg(myRequest,'username',myEncoder.USERNAME)
	// Add Duration
	fnAddArg(myRequest,'duration','300')
	// Add Format
	fnAddArg(myRequest,'format','csv')
	// Queue Up the Request
	fnQueueRequest(myRequest)
}

DEFINE_FUNCTION fnQueueRequest(uRequest pRequest){
	STACK_VAR INTEGER r
	fnDebug(DEBUG_DEV,"'fnQueueRequest','Called'")
	// Queue Request
	FOR(r = 1; r <= LEN_REQ_ARRAY; r++){
		IF(!LENGTH_ARRAY(myEncoder.REQ_QUEUE[r].FILE)){
			myEncoder.REQ_QUEUE[r] = pRequest
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
	IF(myEncoder.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(DEBUG_DEV,"'fnSendFromQueue','Processing'")
		IF(LENGTH_ARRAY(myEncoder.REQ_QUEUE[1].FILE)){
			myEncoder.Tx = fnWrapHTTP(myEncoder.REQ_QUEUE[1])
			IF(1){
				STACK_VAR INTEGER x
				STACK_VAR uRequest blankReq
				FOR(x = 1; x < LEN_REQ_ARRAY; x++){
					myEncoder.REQ_QUEUE[x] = myEncoder.REQ_QUEUE[x+1]
				}
				myEncoder.REQ_QUEUE[x] = blankReq
			}
			myEncoder.Rx = ''
			fnOpenTCPConnection()
			fnTimeoutConnection(TRUE)
		}
	}
	fnDebug(DEBUG_DEV,"'fnSendFromQueue','Ended'")
}

DEFINE_FUNCTION CHAR[10000] fnWrapHTTP(uRequest pRequest){
	STACK_VAR CHAR HTTPReq[10000]
	fnDebug(DEBUG_DEV,"'fnWrapHTTP','Called'")
	(** Build Header **)
	HTTPReq = "HTTPReq,'GET /',pRequest.PATH,'/',pRequest.FILE"
	IF(LENGTH_ARRAY(pRequest.ARGS[1].KEY)){
		STACK_VAR INTEGER a
		HTTPReq = "HTTPReq,'?'"
		FOR(a = 1; a <= LEN_ARG_ARRAY; a++){
			IF(pRequest.ARGS[a].KEY){
				HTTPReq = "HTTPReq,pRequest.ARGS[a].KEY,'=',pRequest.ARGS[a].VAL"
			}
			IF(a < LEN_ARG_ARRAY){
				IF(LENGTH_ARRAY(pRequest.ARGS[a+1].KEY))
				HTTPReq = "HTTPReq,'&'"
			}
		}

	}
	HTTPReq = "HTTPReq,' HTTP/1.1',$0D,$0A"
	HTTPReq = "HTTPReq,'Host: ',myEncoder.IP_HOST,':',ITOA(myEncoder.IP_PORT),$0D,$0A"
	HTTPReq = "HTTPReq,'Connection: Close',$0D,$0A"
	HTTPReq = "HTTPReq,$0D,$0A"
	(** Combine **)
	fnDebug(DEBUG_DEV,"'fnWrapHTTP','Returning'")
	RETURN( "HTTPReq" )
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
	fnSendQuickRecord('status')
	fnDebug(DEBUG_DEV,"'fnPoll','Ended'")
}
/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'RECORD':{
				SWITCH(DATA.TEXT){
					CASE 'STATUS':	fnSendQuickRecord('STATUS')
					CASE 'STOP':   fnSendQuickRecord('STOP')
					CASE 'START':  fnSendQuickRecord('START')
					CASE 'TOGGLE':{
						SWITCH(myEncoder.FEED[1].LIVE){
							CASE TRUE: fnSendQuickRecord('STOP')
							CASE FALSE:fnSendQuickRecord('START')
						}
					}
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myEncoder.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myEncoder.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myEncoder.IP_HOST = DATA.TEXT
							myEncoder.IP_PORT = 80
						}
						fnPoll()
					}
					CASE 'USERNAME':myEncoder.USERNAME     = DATA.TEXT
					CASE 'PASSWORD':myEncoder.PASSWORD     = DATA.TEXT
					CASE 'STREAM01':myEncoder.FEED[1].NAME = DATA.TEXT
					CASE 'STREAM02':myEncoder.FEED[2].NAME = DATA.TEXT
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myEncoder.DEBUG = DEBUG_STD
							CASE 'DEV': myEncoder.DEBUG = DEBUG_DEV
							DEFAULT:    myEncoder.DEBUG = DEBUG_ERR
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
	fnDebug(DEBUG_STD,"'fnProcessFeedback() Head START---------------------------'")
	// Headers
	WHILE(FIND_STRING(myEncoder.Rx,"$0D,$0A",1)){
		STACK_VAR CHAR HEADER[100]
		HEADER = fnStripCharsRight(REMOVE_STRING(myEncoder.Rx,"$0D,$0A",1),2)
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
	fnDebug(DEBUG_STD,"'fnProcessFeedback() Head END-----------------------------'")

	fnDebug(DEBUG_STD,"'fnProcessFeedback() Body START---------------------------'")
	
	fnProcessBody(myEncoder.Rx)


	fnDebug(DEBUG_STD,"'fnProcessFeedback() Body END-----------------------------'")
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
	CREATE_BUFFER ipDevice, myEncoder.Rx
	myEncoder.FEED[1].NAME = 'Camera'
	myEncoder.FEED[2].NAME = 'Slides'
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

		fnDebugHTTP(DEBUG_DEV,'->TER',myEncoder.Tx)

		myEncoder.CONN_STATE = CONN_STATE_CONNECTED
		SEND_STRING DATA.DEVICE, myEncoder.Tx

		fnDebug(DEBUG_STD,"'->TER','Request Sent'")
		myEncoder.Tx = ''

		fnDebug(DEBUG_DEV,"'DATA_EVENT:OFFLINE Ended'")
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONLINE Called'")
		fnDebug(DEBUG_STD,"'TER->','ConnectionClosed'")
		fnDebugHTTP(DEBUG_DEV,'TER->',myEncoder.Rx)
		IF(1){
			STACK_VAR INTEGER RESPONSE_CODE
			RESPONSE_CODE = fnProcessFeedback()
			myEncoder.CONN_STATE = CONN_STATE_OFFLINE
			myEncoder.Rx = ''
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
		STACK_VAR CHAR _MSG[255]
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONERROR Called'")
		FOR(x = 1; x <= LEN_REQ_ARRAY; x++){
			STACK_VAR uRequest blankREQ
			myEncoder.REQ_QUEUE[x] = blankREQ
		}
		myEncoder.Rx = ''
		myEncoder.CONN_STATE = CONN_STATE_OFFLINE

		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
					CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
					CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
					CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
					CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
					CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
					CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
					CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
					CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
					CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
					CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
				}
			}
		}
		fnDebug(DEBUG_ERR,"'Encoder IP Error ',ITOA(DATA.NUMBER),':',_MSG")
		fnDebug(DEBUG_DEV,"'DATA_EVENT:ONERROR Ended'")
	}
}

/******************************************************************************
	Actual Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessBody(CHAR pDATA[]){
	WHILE(FIND_STRING(pDATA,"$0A",1)){
		STACK_VAR myLine[200]
		STACK_VAR myFeed[200]
		STACK_VAR INTEGER x
		myLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0A",1),1)
		fnDebug(DEBUG_STD,"'BODY:',myLine")
		myFeed = fnStripCharsRight(REMOVE_STRING(myLine,',',1),1)
		FOR(x = 1; x <= 2; x++){
			IF(myFeed == myEncoder.FEED[x].NAME){
				myEncoder.FEED[x].LIVE = ATOI(fnStripCharsRight(REMOVE_STRING(myLine,',',1),1))
				REMOVE_STRING(myLine,',',1)
				myEncoder.FEED[x].DURATION = ATOI(myLine)
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER f
	FOR(f = 1; f <= 5; f++){
		[vdvControl,f] = (myEncoder.FEED[f].LIVE)
		SEND_LEVEL vdvControl,f,myEncoder.FEED[f].DURATION

		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))	
	}
}
/******************************************************************************
	EoF
******************************************************************************/


