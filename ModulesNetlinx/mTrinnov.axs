MODULE_NAME='mTrinnov'(DEV vdvPreAmp, DEV dvDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	Trinnov AVR Control Module
	Tested against Altitude 16
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uTrinnov{
	INTEGER POWER
	INTEGER MUTE
	INTEGER VOL
	(** Comms Data **)
	CHAR 	  RX[250]
	INTEGER isIP
	INTEGER CONN_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	uDebug  DEBUG
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2
LONG TLID_RETRY		= 3
LONG TLID_VOL			= 4

// Connection State Constants
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED		= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uTrinnov	myTrinnov	

LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myTrinnov.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice,myTrinnov.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR CMD[]){
	IF(myTrinnov.CONN_STATE == CONN_STATE_CONNECTED){
		fnDebug(myTrinnov.DEBUG,DEBUG_STD,"'->TRN ',CMD,$0D")
		SEND_STRING dvDEVICE,"CMD,$0D"
		fnInitPoll()
	}
}

(** Polling Code **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('send_volume')
}

(** IP Helpers **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myTrinnov.CONN_STATE == CONN_STATE_OFFLINE){
		myTrinnov.CONN_STATE = CONN_STATE_CONNECTING
		fnDebug(myTrinnov.DEBUG,DEBUG_STD,"'Connecting to AVR on ',myTrinnov.IP_HOST,':',ITOA(myTrinnov.IP_PORT)")
		ip_client_open(dvDevice.port, myTrinnov.IP_HOST, myTrinnov.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){	TIMELINE_KILL(TLID_RETRY) }
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY), TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Feedback Processing **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(myTrinnov.DEBUG,DEBUG_STD,"'TRN-> ',pDATA")
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'VOLUME':myTrinnov.VOL = ATOI(pDATA)
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Comms Functions - Grouped ready for Abstraction
******************************************************************************/
(** Device Events **)
DEFINE_EVENT DATA_EVENT[dvDEVICE]{
	ONLINE:{
		IF(!myTrinnov.isIP){
			SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
			SEND_COMMAND DATA.DEVICE, 'SET BAUD 19200 N 8 1 485 DISABLE'
		}
		myTrinnov.CONN_STATE = CONN_STATE_CONNECTED
	}
	OFFLINE:{
		IF(myTrinnov.isIP){
			myTrinnov.CONN_STATE = CONN_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myTrinnov.isIP){
			STACK_VAR CHAR _MSG[255]
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
			fnDebug(myTrinnov.DEBUG,DEBUG_ERR,"'Onkyo Error:[',myTrinnov.IP_HOST,'][',ITOA(DATA.NUMBER),'][',_MSG,']'")
			
			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myTrinnov.CONN_STATE = CONN_STATE_OFFLINE
					fnRetryConnection()
				}
			}
		}
	}
	STRING:{
		fnDebug(myTrinnov.DEBUG,DEBUG_DEV,"'RAW->',DATA.TEXT")
		WHILE(FIND_STRING(myTrinnov.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myTrinnov.RX,"$0D",1),1))
		}
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvPreAmp]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'PROPERTY-RANGE,0,100'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){	
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': myTrinnov.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV':  myTrinnov.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:     myTrinnov.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myTrinnov.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myTrinnov.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myTrinnov.IP_HOST = DATA.TEXT
							myTrinnov.IP_PORT = 44100
						}
						fnRetryConnection()
					}
				}
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	SEND_LEVEL vdvPreAmp,1,myTrinnov.VOL
	[vdvPreAmp,199] = myTrinnov.MUTE
	[vdvPreAmp,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvPreAmp,252] = TIMELINE_ACTIVE(TLID_COMMS)
}
