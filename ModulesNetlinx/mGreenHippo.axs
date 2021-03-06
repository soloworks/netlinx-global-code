MODULE_NAME='mGreenHippo'(DEV vdvServer, DEV ipTCP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Green Hippo Hippotizer Control Module

	Requires configuration on the Hippo side:
	Configure SystemStatus pin for reading state
	Control Triggers defined
******************************************************************************/

/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uHippo{
	// Communications
	CHAR 		Rx[2000]						// Receieve Buffer
	CHAR     Tx[2000]						// Send Buffer - Queries
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	CHAR     StatusPinTrigger[50]		// Name of
	INTEGER	DEBUG
	CHAR     SystemStatus[30]
	CHAR     SystemStatusMsg[30]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_TIMEOUT	= 3

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_NEGOTIATE  	= 1
INTEGER IP_STATE_CONNECTING	= 2
INTEGER IP_STATE_CONNECTED		= 3

// Debugggin Levels
INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 			= { 45000}
LONG TLT_POLL[] 			= { 15000}
LONG TLT_TIMEOUT[] 		= {  5000}
VOLATILE uHippo myHippo

/******************************************************************************
	Helper Functions - Comms
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myHippo.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Hippo IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to Hippo on ',"myHippo.IP_HOST,':',ITOA(myHippo.IP_PORT)")
		myHippo.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(ipTCP.port, myHippo.IP_HOST, myHippo.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipTCP.port)
}
DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[]){
	myHippo.Tx = "myHippo.Tx,pDATA,$0D"
	fnInitPoll()
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myHippo.IP_STATE == IP_STATE_OFFLINE && LENGTH_ARRAY(myHippo.Tx)){
		fnOpenTCPConnection()
	}
}
/******************************************************************************
	Helper Functions - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Helper Functions - Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myHippo.DEBUG >= DEBUG_TYPE){
		STACK_VAR CHAR pCOPY[5000]
		pCOPY = MsgData
		WHILE(LENGTH_ARRAY(pCOPY)){
			SEND_STRING 0:0:0, "ITOA(vdvServer.Number),':',Msg, ':', GET_BUFFER_STRING(pCOPY,200)"
		}
	}
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipTCP, myHippo.Rx
	myHippo.StatusPinTrigger = 'SystemStatus'
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipTCP]{
	ONLINE:{
		STACK_VAR CHAR toSend[50]
		myHippo.IP_STATE	= IP_STATE_CONNECTED
		toSend = "myHippo.StatusPinTrigger,',?',$0D"
		IF(LENGTH_ARRAY(myHippo.Tx)){
			toSend = REMOVE_STRING(myHippo.Tx,"$0D",1)
		}
		fnDebug(DEBUG_STD,'->GH',"toSend")
		SEND_STRING DATA.DEVICE,"toSend"
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	OFFLINE:{
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		myHippo.IP_STATE	= IP_STATE_OFFLINE
		fnProcessFeedback()
		fnSendFromQueue()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myHippo.IP_STATE = IP_STATE_OFFLINE
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
					CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
				}
			}
		}
		fnDebug(TRUE,"'GreenHippo IP Error:[',myHippo.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'GH_RAW->',DATA.TEXT)
		IF(FIND_STRING(DATA.TEXT,"$0D",1)){fnCloseTCPConnection()}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(){
	fnDebug(DEBUG_STD,'GH->',"myHippo.Rx")
	IF(LENGTH_ARRAY(myHippo.Rx)){
		STACK_VAR CHAR PinName[100]
		// Remove $0D
		SET_LENGTH_ARRAY(myHippo.Rx,LENGTH_ARRAY(myHippo.Rx)-1)
		// Remove and gather string between [..]
		REMOVE_STRING(myHippo.Rx,'[',1)
		PinName = REMOVE_STRING(myHippo.Rx,']',1)
		SET_LENGTH_ARRAY(PinName,LENGTH_ARRAY(PinName)-1)
		IF(myHippo.StatusPinTrigger == PinName){
			// Remove "_(string)="
			REMOVE_STRING(myHippo.Rx,'=',1)
			// Check for  "System Status="
			SWITCH(REMOVE_STRING(myHippo.Rx,'=',1)){
				CASE 'System Status=':{
					// Extract System Status
					myHippo.SystemStatus = REMOVE_STRING(myHippo.Rx,',',1)
					SET_LENGTH_ARRAY(myHippo.SystemStatus,LENGTH_ARRAY(myHippo.SystemStatus)-1)
					// Extract Message
					REMOVE_STRING(myHippo.Rx,'=',1)
					myHippo.SystemStatusMsg = GET_BUFFER_STRING(myHippo.Rx,100)
				}
			}
			// Set Comms based on value
			SWITCH(myHippo.SystemStatus){
				CASE 'Run':
				CASE 'limited':{
					IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
					TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
		}
	}
	// Clean out the buffer
	myHippo.Rx = ''
}


/******************************************************************************
	Control Events - Server
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvServer]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myHippo.DEBUG = DEBUG_STD
							CASE 'DEV': myHippo.DEBUG = DEBUG_DEV
							DEFAULT:		myHippo.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myHippo.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myHippo.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myHippo.IP_HOST = DATA.TEXT
							myHippo.IP_PORT = 23
						}
						fnInitPoll()
						fnOpenTCPConnection()
					}
					CASE 'STATUSTRIGGER':{
						myHippo.StatusPinTrigger = DATA.TEXT
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(DATA.TEXT)
			}
			CASE 'TRIGGER':{
				fnAddToQueue(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	// Server
	[vdvServer,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvServer,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/
