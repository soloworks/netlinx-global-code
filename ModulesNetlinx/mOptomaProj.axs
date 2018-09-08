MODULE_NAME='mOptomaProj'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Optoma Projector Module for RS232 & IP Control
******************************************************************************/
DEFINE_TYPE STRUCTURE uOptomaProj{
	INTEGER	ID						// Projector ID
	CHAR		Tx[500]				// Transmit Buffer
	CHAR 		Rx[500]				// Recieve Buffer
	CHAR	 	PENDING_MSG[3]		// Last message send
	INTEGER	isIP
	INTEGER 	IP_PORT				// IP Port
	CHAR		IP_HOST[255]		// IP Host
	INTEGER 	CONN_STATE			// Current Connection State

	INTEGER  DEBUG					// Debuging ON/OFF

	INTEGER  MODEL_NAME
	INTEGER  DISPLAY_MODE
	INTEGER	POWER
	INTEGER 	SOURCE_ACTUAL
	INTEGER 	SOURCE_REQUESTED
}

DEFINE_CONSTANT
LONG TLID_COMMS	= 1
LONG TLID_POLL		= 2
LONG TLID_SEND		= 3
LONG TLID_RETRY	= 4

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

// Connection States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER MODEL_X605			= 1
INTEGER MODEL_W505			= 2
INTEGER MODEL_EH505			= 3

INTEGER DISPLAY_MODE_NONE  = 0
INTEGER DISPLAY_MODE_3D    = 12

DEFINE_VARIABLE
LONG TLT_COMMS[] 	= { 90000 }
LONG TLT_POLL[]	= { 15000 }
LONG TLT_SEND[]	= {  5000 }
LONG TLT_RETRY[]	= {  5000 }
VOLATILE uOptomaProj myOptomaProj
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myOptomaProj.ID = 0
	myOptomaProj.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myOptomaProj.RX
}
/******************************************************************************
	Debug Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bDebug, CHAR Msg[], CHAR MsgData[]){
	IF(myOptomaProj.DEBUG >= bDebug)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	IP Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myOptomaProj.IP_HOST == ''){
		fnDebug(TRUE,'Optoma IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Optoma on ',"myOptomaProj.IP_HOST,':',ITOA(myOptomaProj.IP_PORT)")
		myOptomaProj.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myOptomaProj.IP_HOST, myOptomaProj.IP_PORT, IP_TCP)
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
	Communication Flow Helpers
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCODE[], CHAR pPARAM[]){
	myOptomaProj.Tx = "myOptomaProj.Tx,'~',FORMAT('%02d',myOptomaProj.ID),pCODE,' ',pPARAM,$0D"
	fnSendFromQueue()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && LENGTH_ARRAY(myOptomaProj.Tx)){
		STACK_VAR CHAR toSend[20]
		toSend = REMOVE_STRING(myOptomaProj.Tx,"$0D",1)
		myOptomaProj.PENDING_MSG = fnStripCharsRight(toSend,1)
		fnDebug(DEBUG_STD,'->OPT',toSend)
		SEND_STRING dvDevice,toSend
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	fnResetModule()
}

DEFINE_FUNCTION fnResetModule(){
	myOptomaProj.Tx = ''
	myOptomaProj.Rx = ''
	myOptomaProj.PENDING_MSG = ''
	IF(myOptomaProj.isIP && myOptomaProj.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}
/******************************************************************************
	Polling Flow Helpers
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_FUNCTION fnPoll(){
	// Request Infomation
	fnAddToQueue('150','1')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	// Request Infomation
	fnPoll()
}

/******************************************************************************
	Physical Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myOptomaProj.CONN_STATE	= CONN_STATE_CONNECTED
		IF(!myOptomaProj.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		IF(myOptomaProj.isIP){
			myOptomaProj.CONN_STATE	= CONN_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myOptomaProj.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myOptomaProj.CONN_STATE = CONN_STATE_OFFLINE
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
					fnResetModule()
				}
			}
			fnDebug(DEBUG_ERR,"'Optoma IP Error:[',myOptomaProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(FIND_STRING(UPPER_STRING(myOptomaProj.Rx),'ERROR',1)){
			fnResetModule()
		}
		ELSE{
			WHILE(FIND_STRING(myOptomaProj.Rx,"$0D",1)){
				IF(
			}
		}
		STACK_VAR INTEGER pIsResponse
		fnDebug(DEBUG_STD,'OPT->',DATA.TEXT)
		IF(FIND_STRING(DATA.TEXT,'OK',1)){
			GET_BUFFER_STRING(DATA.TEXT,2)	// Strip 'OK'
			myOptomaProj.POWER 			= ATOI("GET_BUFFER_CHAR(DATA.TEXT)")
			//myOptomaProj.LAMP_HOURS 	= GET_BUFFER_STRING(DATA.TEXT,5)
			//myOptomaProj.SOURCE_NO 		= ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
			//myOptomaProj.META_FIRMWARE = GET_BUFFER_STRING(DATA.TEXT,4)
			//pIsResponse = TRUE

			IF(myOptomaProj.SOURCE_REQUESTED != 0 && myOptomaProj.POWER){
				fnAddToQueue('12',ITOA(myOptomaProj.SOURCE_REQUESTED))
				myOptomaProj.SOURCE_REQUESTED = 0
			}
		}
		ELSE IF(DATA.TEXT[1] == 'P' || DATA.TEXT[1] == 'F'){
			pIsResponse = TRUE
		}

		IF(pIsResponse){
			// Clear the Pending Message
			myOptomaProj.PENDING_MSG = ''
			// Clear the Pending Timeline
			IF(TIMELINE_ACTIVE(TLID_SEND)){TIMELINE_KILL(TLID_SEND)}
			// Restart the Connectivity Timeline
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			// Send next message from Queue
			fnSendFromQueue()
		}
	}
}
/******************************************************************************
	Virtual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': 		myOptomaProj.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myOptomaProj.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myOptomaProj.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myOptomaProj.IP_HOST = DATA.TEXT
							myOptomaProj.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'ADJUST':{
				SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnAddToQueue('01','1')
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'VGA1':myOptomaProj.SOURCE_REQUESTED = 5
					CASE 'VGA2':myOptomaProj.SOURCE_REQUESTED = 6
					CASE 'VIDEO':myOptomaProj.SOURCE_REQUESTED = 10
					CASE 'HDMI1':myOptomaProj.SOURCE_REQUESTED = 1
					CASE 'HDMI2':myOptomaProj.SOURCE_REQUESTED = 15
				}
				SWITCH(myOptomaProj.POWER){
					CASE TRUE: fnAddToQueue('12',ITOA(myOptomaProj.SOURCE_REQUESTED))
					CASE FALSE:fnAddToQueue('00','1')
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnAddToQueue('00','1')
					CASE 'OFF':	fnAddToQueue('00','0')
				}
			}
		}
	}
}


DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))

	[vdvControl,255] = (myOptomaProj.POWER)
}