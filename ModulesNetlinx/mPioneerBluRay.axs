MODULE_NAME='mPioneerBluRay'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	Pioneer DVD/BluRay Control Module for IP control
	Created By Solo Control Ltd (https://soloworks.co.uk)
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uPlayer{
	// Comms
	CHAR 		Rx[1000]						// Receieve Buffer
	CHAR     Tx[1000]						// Transmix Buffer
	INTEGER 	IP_PORT						//	IP Port (Default: 8102
	CHAR		IP_HOST[255]				//	IP Address
	INTEGER 	CONN_STATE					// Connection State
	CHAR     LAST_SENT[20]				// Last sent
	uDebug 	DEBUG							// Debugging Mode

	// Meta Data
	CHAR     MODEL[20]
	CHAR     FIRMWARE[20]

	// State
	INTEGER  POWER
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
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
	CREATE_BUFFER ipDevice, myPlayer.Rx
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
		ip_client_open(ipDevice.port, myPlayer.IP_HOST, myPlayer.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
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
	fnAddToQueue('?L')
	fnAddToQueue('?Z')
}
DEFINE_FUNCTION fnAddToQueue(CHAR pMSG[]){
	IF(myPlayer.CONN_STATE == CONN_STATE_CONNECTED){
		fnDebug(myPlayer.DEBUG,DEBUG_DEV,"'Queuing::',pMSG,$0D")
		myPlayer.Tx = "myPlayer.Tx,pMSG,$0D"
		fnSendFromQueue()
		fnInitPoll()
	}
}
DEFINE_FUNCTIOn fnSendFromQueue(){
	IF(myPlayer.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myPlayer.Tx,"$0D",1)){
		IF(FIND_STRING(myPlayer.Tx,"$0D",1)){
			myPlayer.LAST_SENT = REMOVE_STRING(myPlayer.Tx,"$0D",1)
			fnDebug(myPlayer.DEBUG,DEBUG_DEV,"'->DVD',myPlayer.LAST_SENT")
			SEND_STRING ipDevice, myPlayer.LAST_SENT
			SET_LENGTH_ARRAY(myPlayer.LAST_SENT,LENGTH_ARRAY(myPlayer.LAST_SENT)-1)
		}
	}
}
/******************************************************************************
	Module Control - Data Processing
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	// Strip Terminators
	SET_LENGTH_ARRAY(pDATA,LENGTH_ARRAY(pDATA)-2)
	fnDebug(myPlayer.DEBUG,DEBUG_STD,"'DVD->',pDATA")
	SWITCH(myPlayer.LAST_SENT){
		CASE '?L':myPlayer.MODEL = pDATA
		CASE '?Z':myPlayer.FIRMWARE = pDATA
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	fnSendFromQueue()
}
/******************************************************************************
	Module Control - Actual Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		myPlayer.CONN_STATE	= CONN_STATE_CONNECTED
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
		fnDebug(myPlayer.DEBUG,DEBUG_DEV,"'RAW->',DATA.TEXT")
		WHILE(FIND_STRING(myPlayer.RX,"$0D,$0A",1)){
			fnProcessFeedback(REMOVE_STRING(myPlayer.RX,"$0D,$0A",1))
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
					CASE 'IP':{
						myPlayer.IP_HOST = DATA.TEXT
						myPlayer.IP_PORT = 8102
						fnRetryConnection()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': myPlayer.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV':  myPlayer.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:     myPlayer.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':			fnAddToQueue('/A181AFBA/RU')
					CASE 'OFF':			fnAddToQueue('/A181AFBB/RU')
				}
			}
			CASE 'MENU':{
				SWITCH(DATA.TEXT){
					CASE 'UP':			fnAddToQueue('/A184FFFF/RU')
					CASE 'RIGHT':		fnAddToQueue('/A186FFFF/RU')
					CASE 'LEFT':		fnAddToQueue('/A187FFFF/RU')
					CASE 'DOWN':		fnAddToQueue('/A185FFFF/RU')
					CASE 'ENTER':		fnAddToQueue('/A181AFEF/RU')
					CASE 'MENU':		fnAddToQueue('/A181AFB9/RU')
					CASE 'TOP':			fnAddToQueue('/A181AFB4/RU')
					CASE 'HOME':		fnAddToQueue('/A181AFB0/RU')
					CASE 'SUBTITLE':	fnAddToQueue('/A181AF36/RU')
					CASE 'RETURN':		fnAddToQueue('/A181AFF4/RU')
					CASE 'RED':			fnAddToQueue('/A181AF64/RU')
					CASE 'GREEN':		fnAddToQueue('/A181AF65/RU')
					CASE 'YELLOW':		fnAddToQueue('/A181AF67/RU')
					CASE 'BLUE':		fnAddToQueue('/A181AF66/RU')
					CASE 'DISPLAY':	fnAddToQueue('/A181AFE3/RU')
				}
			}
			CASE 'TRANSPORT':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY':		fnAddToQueue('/A181AF39/RU')
					CASE 'PAUSE':		fnAddToQueue('/A181AF3A/RU')
					CASE 'STOP':		fnAddToQueue('/A181AF38/RU')
					CASE 'SKIP+':		fnAddToQueue('/A181AF3D/RU')
					CASE 'SKIP-':		fnAddToQueue('/A181AF3E/RU')
					CASE 'SCAN+': 		fnAddToQueue('/A181AFE9/RU')
					CASE 'SCAN-': 		fnAddToQueue('/A181AFEA/RU')
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
