MODULE_NAME='mZeeVee'(DEV vdvServer, DEV vdvEndPoint[], DEV dvIP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hushbutton Control Module
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uEndPoint{
	CHAR     NAME[100]
	CHAR     MAC[17]
	CHAR     MODEL[25]
	CHAR     TYPE[25]
	CHAR     STATE[10]
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
}
DEFINE_TYPE STRUCTURE uZeeVee{
	// Communications
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	DEBUG
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
	CHAR     MODEL[20]
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
	
	uEndPoint ENDPOINT[250]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_RETRY	= 3

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
LONG TLT_POLL[] 			= { 10000}
LONG TLT_RETRY[]			= {  5000 }
VOLATILE uZeeVee myZeeVee
/******************************************************************************
	Helper Functions - Comms
******************************************************************************/
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myZeeVee.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'ZeeVee IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to ZeeVee on ',"myZeeVee.IP_HOST,':',ITOA(myZeeVee.IP_PORT)")
		myZeeVee.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myZeeVee.IP_HOST, myZeeVee.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIP.port)
}
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	fnDebug(DEBUG_STD,'->ZV', "pDATA");
	SEND_STRING dvIP, "pDATA"
	fnInitPoll()
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
	LOCAL_VAR CHAR syVAL
	SWITCH(myZeeVee.IP_STATE){
		CASE IP_STATE_NEGOTIATE: fnSendCommand('*')
		DEFAULT:{
			fnSendCommand("ITOA(syVAL),'SYpig'")
			syVAL++
		}
	}
}
/******************************************************************************
	Helper Functions - Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myZeeVee.DEBUG >= DEBUG_TYPE){
		SEND_STRING 0:0:0, "ITOA(vdvServer.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvIP, myZeeVee.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myZeeVee.IP_STATE	= IP_STATE_NEGOTIATE
		fnPoll()
	}
	OFFLINE:{
		myZeeVee.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myZeeVee.IP_STATE = IP_STATE_OFFLINE
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
				fnRetryConnection()
			}
		}
		fnDebug(TRUE,"'Midra IP Error:[',myZeeVee.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'MIDRA_RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myZeeVee.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myZeeVee.Rx,"$0D,$0A",1),2))
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_STD,'ZV->',pDATA)

	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
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
							CASE 'TRUE':myZeeVee.DEBUG = DEBUG_STD
							CASE 'DEV': myZeeVee.DEBUG = DEBUG_DEV
							DEFAULT:		myZeeVee.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myZeeVee.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myZeeVee.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myZeeVee.IP_HOST = DATA.TEXT
							myZeeVee.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	Control Events - Endpoints
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvEndpoint]{
	COMMAND:{
		STACK_VAR INTEGER e
		STACK_VAR CHAR name[25]
		e = GET_LAST(vdvEndPoint)
		name = myZeeVee.ENDPOINT[e].NAME
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':{
						myZeeVee.ENDPOINT[e].NAME = DATA.TEXT
					}
				}
			}
			CASE 'CHAN':{
				SWITCH(DATA.TEXT){
					CASE 'INC': fnSendCommand("'channel up ',name")
					CASE 'DEC': fnSendCommand("'channel down ',name")
					DEFAULT:    fnSendCommand("'join ',DATA.TEXT,' ',name,' fast-switched'")
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	// Endpoints
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		FOR(x = 1; x <= LENGTH_ARRAY(vdvEndPoint); x++){
			[vdvEndPoint,251] = myZeeVee.ENDPOINT[x].STATE == 'Up'
			[vdvEndPoint,252] = [vdvEndPoint,251]
		}
	}
	ELSE{
		[vdvEndPoint,251] = FALSE
		[vdvEndPoint,252] = FALSE
	}
	
	// Server
	[vdvServer,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvServer,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/

