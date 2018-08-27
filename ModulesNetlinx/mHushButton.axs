MODULE_NAME='mHushButton'(DEV vdvControl, DEV dvIP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hushbutton Control Module
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uHush{
	// Communications
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						// 
	CHAR		IP_HOST[255]				//	
	INTEGER 	IP_STATE						// 
	INTEGER	isIP
	INTEGER	DEBUG
	INTEGER	PRESSED[8]
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
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

INTEGER LED_STATE_OFF	= 0
INTEGER LED_STATE_RED	= 1
INTEGER LED_STATE_GREEN	= 2
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 			= { 90000}
LONG TLT_POLL[] 			= { 25000}
LONG TLT_RETRY[]			= {  5000 }
VOLATILE uHush myHush
/******************************************************************************
	Helper Functions
******************************************************************************/

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myHush.IP_HOST == ''){
		fnDebug(TRUE,'Hush IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Hush on ',"myHush.IP_HOST,':',ITOA(myHush.IP_PORT)")
		myHush.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myHush.IP_HOST, myHush.IP_PORT, IP_TCP) 
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

DEFINE_FUNCTION fnDebug(INTEGER FORCE,CHAR Msg[], CHAR MsgData[]){
	 IF(myHush.DEBUG || FORCE){
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
	fnSendCommand('?a')
}
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	fnDebug(FALSE,'AMX->Hush', "'{',pDATA,'}'");
	SEND_STRING dvIP, "'{',pDATA,'}'"
	fnInitPoll()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myHush.IP_STATE	= IP_STATE_CONNECTED
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		myHush.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myHush.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'Hush IP Error:[',myHush.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'Hush->AMX', DATA.TEXT);
		SWITCH(GET_BUFFER_STRING(DATA.TEXT,3)){
			CASE '{=s':{
				STACK_VAR INTEGER pTEST
				pTEST = HEXTOI(GET_BUFFER_STRING(DATA.TEXT,2))
				// Bit check and set
				myHush.PRESSED[1] = (pTEST BAND $01 != FALSE)
				myHush.PRESSED[2] = (pTEST BAND $02 != FALSE)
				myHush.PRESSED[3] = (pTEST BAND $04 != FALSE)
				myHush.PRESSED[4] = (pTEST BAND $08 != FALSE)
				myHush.PRESSED[5] = (pTEST BAND $10 != FALSE)
				myHush.PRESSED[6] = (pTEST BAND $20 != FALSE)
				myHush.PRESSED[7] = (pTEST BAND $40 != FALSE)
				myHush.PRESSED[8] = (pTEST BAND $80 != FALSE)
			}
		}
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
					CASE 'DEBUG': 		myHush.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myHush.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myHush.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myHush.IP_HOST = DATA.TEXT
							myHush.IP_PORT = 23 
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'SET_LED':{
				SWITCH(DATA.TEXT){
					CASE 'RED':		fnSendCommand('=aFF0000FF')
					CASE 'GREEN':	fnSendCommand('=a00FFFFFF')
					CASE 'OFF':		fnSendCommand('=a000000FF')
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 8; x++){
		[vdvControl,x] = myHush.PRESSED[x]
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/