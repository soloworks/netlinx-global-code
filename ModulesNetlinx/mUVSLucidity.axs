MODULE_NAME='mUVSLucidity'(DEV vdvServer, DEV ipTCP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	UVC Lucidity Control Module

	Requires configuration on the Lucidity side:
	Control Presets defined
******************************************************************************/

/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uLucidity{
	// Communications
	CHAR 		Rx[2000]						// Receieve Buffer
	CHAR     Tx[2000]						// Send Buffer
	INTEGER  TxPEND
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	DEBUG
	CHAR     LAST_SENT[30]
	CHAR     VERSION[30]
	CHAR     SYSNAME[30]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_TIMEOUT	= 3
LONG TLID_RETRY 	= 4

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
LONG TLT_COMMS[] 			= { 90000}
LONG TLT_POLL[] 			= { 45000}
LONG TLT_TIMEOUT[] 		= {  5000}
LONG TLT_RETRY[]			= { 10000}
VOLATILE uLucidity myLucidity

/******************************************************************************
	Helper Functions - Comms
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myLucidity.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'UVC IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to UVC on ',"myLucidity.IP_HOST,':',ITOA(myLucidity.IP_PORT)")
		myLucidity.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(ipTCP.port, myLucidity.IP_HOST, myLucidity.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipTCP.port)
}
(** Delay and try a new connection **)
DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnAddToQueue(CHAR pFunc[],CHAR pArg1[],CHAR pArg2[],CHAR pArg3[]){
	IF(myLucidity.IP_STATE == IP_STATE_CONNECTED){

		myLucidity.Tx = "myLucidity.Tx,pFunc,'('"
		IF(pArg1 != ''){
			myLucidity.Tx = "myLucidity.Tx,pArg1"
			IF(pArg2 != ''){
				myLucidity.Tx = "myLucidity.Tx,',',pArg2"
				IF(pArg3 != ''){
					myLucidity.Tx = "myLucidity.Tx,',',pArg3"
				}
			}
		}
		myLucidity.Tx = "myLucidity.Tx,')',$0D,$0A"
		fnInitPoll()
		fnSendFromQueue()
	}
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myLucidity.IP_STATE == IP_STATE_CONNECTED && FIND_STRING(myLucidity.Tx,"$0D,$0A",1)){
		STACK_VAR CHAR toSend[50]
		IF(FIND_STRING(myLucidity.Tx,"$0D,$0A",1) && !myLucidity.TxPEND){
			toSend = REMOVE_STRING(myLucidity.Tx,"$0D,$0A",1)
			// Send the commands to the unit
			SEND_STRING ipTCP,"toSend"
			// Debug Out
			SET_LENGTH_ARRAY(toSend,LENGTH_ARRAY(toSend)-2)
			fnDebug(DEBUG_STD,'->UVC',"toSend")
			// Store last sent
			myLucidity.LAST_SENT = REMOVE_STRING(toSend,'(',1)
			SET_LENGTH_ARRAY(myLucidity.LAST_SENT,LENGTH_ARRAY(myLucidity.LAST_SENT)-1)
			// Start a timeout timeline
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
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
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('version','','','')
}
/******************************************************************************
	Helper Functions - Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myLucidity.DEBUG >= DEBUG_TYPE){
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
	CREATE_BUFFER ipTCP, myLucidity.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipTCP]{
	ONLINE:{
		// Online when welcome message has been processed
	}
	OFFLINE:{
		myLucidity.IP_STATE	= IP_STATE_OFFLINE
		myLucidity.Tx = ''
		fnTryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myLucidity.IP_STATE = IP_STATE_OFFLINE
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
				fnTryConnection()
			}
		}
		fnDebug(TRUE,"'UVC IP Error:[',myLucidity.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'UVC_RAW->',DATA.TEXT)
		IF(FIND_STRING(myLucidity.Rx,'CONNECTED',1) && FIND_STRING(myLucidity.Rx,'> ',1)){
			// Gather System Name
			REMOVE_STRING(myLucidity.Rx,' ',1) // Removed CONNECTED
			REMOVE_STRING(myLucidity.Rx,' ',1) // Removed TO
			myLucidity.SYSNAME = REMOVE_STRING(myLucidity.Rx,'> ',1)	// Get System Name
			SET_LENGTH_ARRAY(myLucidity.SYSNAME,LENGTH_ARRAY(myLucidity.SYSNAME)-2)
			//
			myLucidity.TxPend = FALSE
			myLucidity.IP_STATE = IP_STATE_CONNECTED
			fnSendFromQueue()
		}
		WHILE(FIND_STRING(myLucidity.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLucidity.Rx,"$0D,$0A",1),1))
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(DEBUG_STD,'UVC->',pData)
	SWITCH(myLucidity.LAST_SENT){
		CASE 'version':{
			myLucidity.VERSION = pData
			REMOVE_STRING(myLucidity.VERSION,'API ',1)
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
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
							CASE 'TRUE':myLucidity.DEBUG = DEBUG_STD
							CASE 'DEV': myLucidity.DEBUG = DEBUG_DEV
							DEFAULT:		myLucidity.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myLucidity.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myLucidity.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myLucidity.IP_HOST = DATA.TEXT
							myLucidity.IP_PORT = 6003
						}
						fnInitPoll()
						fnOpenTCPConnection()
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2),fnGetCSV(DATA.TEXT,3),fnGetCSV(DATA.TEXT,4))
			}
			CASE 'CLEAN':{
				SWITCH(DATA.TEXT){
					CASE 'ALL':	fnAddToQueue('CleanAllWalls','','','')
					DEFAULT:		fnAddToQueue('CleanWall',DATA.TEXT,'','')
				}
			}
			CASE 'PRESET':{
				fnAddToQueue('PlayPreset',fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2),'')
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

