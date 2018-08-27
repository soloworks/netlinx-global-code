MODULE_NAME='mVaddioCamera'(DEV vdvControl, DEV dvIP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hushbutton Control Module
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uVaddioCam{
	// Communications
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//	
	INTEGER 	IP_STATE						// 
	INTEGER	DEBUG	
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
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
INTEGER IP_STATE_NEGOTIATE		= 2
INTEGER IP_STATE_SECURITY		= 3
INTEGER IP_STATE_CONNECTED		= 4

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
LONG TLT_RETRY[]			= {  5000 }
VOLATILE uVaddioCam myVaddioCam
/******************************************************************************
	Helper Functions
******************************************************************************/

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myVaddioCam.IP_HOST == ''){
		fnDebug(TRUE,'Vaddio IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Vaddio on ',"myVaddioCam.IP_HOST,':',ITOA(myVaddioCam.IP_PORT)")
		myVaddioCam.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myVaddioCam.IP_HOST, myVaddioCam.IP_PORT, IP_TCP) 
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
	 IF(myVaddioCam.DEBUG >= DEBUG_TYPE){
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
	fnSendCommand('camera standby get')
}

DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	fnDebug(FALSE,'AMX->CAM', "pDATA,$0D");
	SEND_STRING dvIP, "pDATA,$0D"
	fnInitPoll()
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvIP, myVaddioCam.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myVaddioCam.IP_STATE	= IP_STATE_NEGOTIATE
	}
	OFFLINE:{
		myVaddioCam.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myVaddioCam.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'Vaddio IP Error:[',myVaddioCam.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		// Telnet Negotiation
		WHILE(myVaddioCam.Rx[1] == $FF && LENGTH_ARRAY(myVaddioCam.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myVaddioCam.Rx,3)
			fnDebug(DEBUG_DEV,'CAM.Telnet->',NEG_PACKET)
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(DEBUG_DEV,'->CAM.Telnet',NEG_PACKET)
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}
		
		// Security Negotiation
		IF(myVaddioCam.IP_STATE != IP_STATE_CONNECTED){
			fnDebug(DEBUG_DEV,'CAM.Login->',myVaddioCam.Rx)
			IF(RIGHT_STRING(myVaddioCam.Rx,7) == 'login: '){
				myVaddioCam.IP_STATE = IP_STATE_SECURITY
				IF(myVaddioCam.Username == ''){myVaddioCam.Username = 'admin'}
				fnDebug(DEBUG_DEV,'->CAM.Login',"myVaddioCam.Username,$0D")
				SEND_STRING dvIP, "myVaddioCam.Username,$0D"
			}
			ELSE IF(FIND_STRING(myVaddioCam.Rx,'Password:',1)){
				IF(myVaddioCam.PASSWORD == ''){myVaddioCam.PASSWORD = 'password'}
				fnDebug(DEBUG_DEV,'->CAM.Login',"myVaddioCam.PASSWORD,$0D")
				SEND_STRING dvIP, "myVaddioCam.PASSWORD,$0D"
			}
			ELSE IF(FIND_STRING(myVaddioCam.Rx,"'Welcome ',myVaddioCam.USERNAME",1)){
				myVaddioCam.IP_STATE = IP_STATE_CONNECTED
				fnPoll()
			}
			myVaddioCam.Rx = ''
		}
		ELSE{
			WHILE(FIND_STRING(myVaddioCam.Rx,"$0D,$0A",1)){
				fnProcessFeedback(REMOVE_STRING(myVaddioCam.Rx,"$0D,$0A",1))
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_DEV,'CAM->',pDATA)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
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
							CASE 'TRUE':myVaddioCam.DEBUG = DEBUG_STD
							CASE 'DEV': myVaddioCam.DEBUG = DEBUG_DEV
							DEFAULT:		myVaddioCam.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myVaddioCam.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myVaddioCam.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myVaddioCam.IP_HOST = DATA.TEXT
							myVaddioCam.IP_PORT = 23 
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'CAMERA':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'PAN':{
						SWITCH(DATA.TEXT){
							CASE 'LEFT':	fnSendCommand('camera pan left')
							CASE 'RIGHT':	fnSendCommand('camera pan right')
							CASE 'STOP':	fnSendCommand('camera pan stop')
						}
					}
					CASE 'TILT':{
						SWITCH(DATA.TEXT){
							CASE 'UP':		fnSendCommand('camera tilt up')
							CASE 'DOWN':	fnSendCommand('camera tilt down')
							CASE 'STOP':	fnSendCommand('camera tilt stop')
						}
					}
					CASE 'ZOOM':{
						SWITCH(DATA.TEXT){
							CASE 'IN':		fnSendCommand('camera zoom in')
							CASE 'OUT':		fnSendCommand('camera zoom out')
							CASE 'STOP':	fnSendCommand('camera zoom stop')
						}
					}
				}
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
