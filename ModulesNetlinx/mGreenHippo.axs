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
DEFINE_TYPE STRUCTURE uServer{
	CHAR     HOST_NAME[30]
	CHAR     VERSION[10]
	CHAR     MAC_ADDRESS[20]
	CHAR     SERIAL_NO[20]
	CHAR     UPTIME[20]
	CHAR     productID[50]
}

DEFINE_TYPE STRUCTURE uHippo{
	// Communications
	CHAR 		Rx[2000]						// Receieve Buffer
	CHAR     Tx[2000]						// Send Buffer - Queries
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	DEBUG
	uServer  SERVER
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2

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
VOLATILE uHippo myHippo

/******************************************************************************
	Helper Functions - Comms
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myHippo.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'ZeeVee IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to ZeeVee on ',"myHippo.IP_HOST,':',ITOA(myHippo.IP_PORT)")
		myHippo.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(ipTCP.port, myHippo.IP_HOST, myHippo.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipTCP.port)
}
DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[]){
	myHippo.Tx = "myHippo.Tx,pDATA,$0D,$0A"
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
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipTCP]{
	ONLINE:{
		myHippo.IP_STATE	= IP_STATE_CONNECTED
		IF(LENGTH_ARRAY(myHippo.Tx)){
			SEND_STRING DATA.DEVICE,"REMOVE_STRING(myHippo.Tx,"$0D,$0A",1)"
		}
		ELSE{
			SEND_STRING DATA.DEVICE,"'SystemStatus ?'"
		}
	}
	OFFLINE:{
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
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(){

	fnDebug(DEBUG_STD,'GH->',"'[',myHippo.Rx,']'")

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
				}
			}
			CASE 'RAW':{
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
