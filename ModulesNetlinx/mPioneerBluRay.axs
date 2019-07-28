MODULE_NAME='mPioneerBluRay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	Pioneer DVD/BluRay Control Module
	Created By Solo Control Ltd (https://soloworks.co.uk)
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uPlayer{	
	// Comms
	CHAR 		RX[1000]						// Receieve Buffer
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	CONN_STATE					//
	uDebug 	DEBUG							// Debugging Mode
	
	// Meta Data
	INTEGER DEVICE_MODEL
	
	// State
	INTEGER POWER
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
// Device Models
INTEGER DEVICE_MODEL_LX52 = 0
INTEGER DEVICE_MODEL_LX54 = 1
// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2
// Timeline IDs
LONG TLID_POLL		= 1
LONG TLID_RETRY	= 2
LONG TLID_COMMS   = 3
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uPlayer myPlayer
LONG 		TLT_POLL[]  = { 15000 }
LONG 		TLT_RETRY[]	= {  5000 }
LONG 		TLT_COMMS[] = { 45000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myPlayer.Rx
	myPlayer.DEBUG.UID = 'Pioneer'
}
/******************************************************************************
	Module Control - Connection
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myPlayer.IP_HOST == ''){
		fnDebug(myPlayer.DEBUG,DEBUG_ERR,'Pioneer IP Host Not Set')
	}
	ELSE{
		fnDebug(myPlayer.DEBUG,DEBUG_STD,"'Connecting to Pioneer on ',myPlayer.IP_HOST,':',ITOA(myPlayer.IP_PORT)")
		myPlayer.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myPlayer.IP_HOST, myPlayer.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Module Control - Data Sending
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('?L')
}
DEFINE_FUNCTION fnSendCommand(CHAR cmd[]){
	IF(myPlayer.CONN_STATE == CONN_STATE_CONNECTED){
		SEND_STRING dvDevice, "cmd, $0D"
		fnInitPoll()
	}
}
/******************************************************************************
	Module Control - Data Processing
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

	STACK_VAR INTEGER x

	fnDebug(myPlayer.DEBUG,DEBUG_STD,"'QSYS->',pDATA")
}
/******************************************************************************
	Module Control - Actual Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myPlayer.CONN_STATE	= CONN_STATE_CONNECTED
		IF(dvDevice.NUMBER){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SWITCH(myPlayer.DEVICE_MODEL){
				CASE DEVICE_MODEL_LX52:SEND_COMMAND dvDevice, 'SET BAUD 115200 N 8 1 485 DISABLE'
				CASE DEVICE_MODEL_LX54:SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			}
		}
		fnPoll()
	}
	OFFLINE:{
		myPlayer.CONN_STATE	= CONN_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myPlayer.CONN_STATE = CONN_STATE_OFFLINE
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
		fnDebug(myPlayer.DEBUG,DEBUG_ERR,"'DVD IP Error:[',myPlayer.IP_HOST,'][',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		WHILE(FIND_STRING(myPlayer.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPlayer.RX,"$0D",1),1))
		}
	}
}
/******************************************************************************
	Module Control - Virtual Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	 COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'MODEL':{
						SWITCH(DATA.TEXT){
							CASE 'LX52':myPlayer.DEVICE_MODEL = DEVICE_MODEL_LX52
							CASE 'LX54':myPlayer.DEVICE_MODEL = DEVICE_MODEL_LX54
						}
						SWITCH(myPlayer.DEVICE_MODEL){
							CASE DEVICE_MODEL_LX52:SEND_COMMAND dvDevice, 'SET BAUD 115200 N 8 1 485 DISABLE'
							CASE DEVICE_MODEL_LX54:SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
						}
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':			fnSendCommand('/A181AFBA/RU')
					CASE 'OFF':			fnSendCommand('/A181AFBB/RU')
				}
			}
			CASE 'MENU':{
				SWITCH(DATA.TEXT){
					CASE 'UP':			fnSendCommand('/A184FFFF/RU')
					CASE 'RIGHT':		fnSendCommand('/A186FFFF/RU')
					CASE 'LEFT':		fnSendCommand('/A187FFFF/RU')
					CASE 'DOWN':		fnSendCommand('/A185FFFF/RU')
					CASE 'ENTER':		fnSendCommand('/A181AFEF/RU')
					CASE 'MENU':		fnSendCommand('/A181AFB9/RU')
					CASE 'TOP':			fnSendCommand('/A181AFB4/RU')
					CASE 'HOME':		fnSendCommand('/A181AFB0/RU')
					CASE 'SUBTITLE':	fnSendCommand('/A181AF36/RU')
					CASE 'RETURN':		fnSendCommand('/A181AFF4/RU')
					CASE 'RED':			fnSendCommand('/A181AF64/RU')
					CASE 'GREEN':		fnSendCommand('/A181AF65/RU')
					CASE 'YELLOW':		fnSendCommand('/A181AF67/RU')
					CASE 'BLUE':		fnSendCommand('/A181AF66/RU')
					CASE 'DISPLAY':	fnSendCommand('/A181AFE3/RU')
				}
			}
			CASE 'TRANSPORT':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY':		fnSendCommand('/A181AF39/RU')
					CASE 'PAUSE':		fnSendCommand('/A181AF3A/RU')
					CASE 'STOP':		fnSendCommand('/A181AF38/RU')
					CASE 'SKIP+':		fnSendCommand('/A181AF3D/RU')
					CASE 'SKIP-':		fnSendCommand('/A181AF3E/RU')
					CASE 'SCAN+': 		fnSendCommand('/A181AFE9/RU')
					CASE 'SCAN-': 		fnSendCommand('/A181AFEA/RU')
				}
			}
		}
	}
}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myPlayer.POWER)
}
/******************************************************************************
	EoF
******************************************************************************/
