MODULE_NAME='mAnalogWayMidra'(DEV vdvControl, DEV dvIP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hushbutton Control Module
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uMidra{
	// Communications
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	DEBUG
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
	INTEGER  MODEL_ID
	CHAR     MODEL[20]
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
VOLATILE uMidra myMidra
/******************************************************************************
	Helper Functions
******************************************************************************/

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myMidra.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Midra IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to Midra on ',"myMidra.IP_HOST,':',ITOA(myMidra.IP_PORT)")
		myMidra.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myMidra.IP_HOST, myMidra.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIP.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myMidra.DEBUG >= DEBUG_TYPE){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	LOCAL_VAR CHAR syVAL
	SWITCH(myMidra.IP_STATE){
		CASE IP_STATE_NEGOTIATE: fnSendCommand('*')
		DEFAULT:{
			fnSendCommand("ITOA(syVAL),'SYpig'")
			syVAL++
		}
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	fnDebug(DEBUG_STD,'->MIDRA', "pDATA");
	SEND_STRING dvIP, "pDATA"
	fnInitPoll()
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvIP, myMidra.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myMidra.IP_STATE	= IP_STATE_NEGOTIATE
		fnPoll()
	}
	OFFLINE:{
		myMidra.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myMidra.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'Midra IP Error:[',myMidra.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'MIDRA_RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myMidra.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMidra.Rx,"$0D,$0A",1),2))
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_STD,'MIDRA->',pDATA)

	IF(pDATA == '*1'){
		fnSendCommand('?')	// Send Device Check
	}
	ELSE IF(LEFT_STRING(pDATA,3) == 'DEV'){
		GET_BUFFER_STRING(pDATA,3)
		myMidra.MODEL_ID = ATOI(pDATA)
		SWITCH (myMidra.MODEL_ID){
			CASE 257:myMidra.MODEL = 'Eikos2'
			CASE 258:myMidra.MODEL = 'Saphyr'
			CASE 259:myMidra.MODEL = 'Pulse2'
			CASE 260:myMidra.MODEL = 'SmartMatriX2'
			CASE 261:myMidra.MODEL = 'QuickMatriX'
			CASE 262:myMidra.MODEL = 'QuickVu'
			CASE 282:myMidra.MODEL = 'Saphyr - H'
			CASE 283:myMidra.MODEL = 'Pulse2 - H'
			CASE 284:myMidra.MODEL = 'SmartMatriX2 - H'
			CASE 285:myMidra.MODEL = 'QuickMatriX – H'
		}
		SEND_STRING vdvControl, "'PROPERTY-META,MAKE,AnalogWay'"
		SEND_STRING vdvControl, "'PROPERTY-META,MODEL,',myMidra.MODEL"
		fnSendCommand('VEvar')
	}
	ELSE IF(pDATA == 'VEvar11'){
		myMidra.IP_STATE = IP_STATE_CONNECTED
		fnPoll()
	}
	ELSE{

		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myMidra.DEBUG = DEBUG_STD
							CASE 'DEV': myMidra.DEBUG = DEBUG_DEV
							DEFAULT:		myMidra.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myMidra.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myMidra.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myMidra.IP_HOST = DATA.TEXT
							myMidra.IP_PORT = 10500
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'PRESET':{
				fnSendCommand("'0,',DATA.TEXT,',0,0,2,1GClrq'")
			}
			CASE 'LAYER':{
				fnSendCommand("'0,1,',DATA.TEXT,'PRinp'")
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/

