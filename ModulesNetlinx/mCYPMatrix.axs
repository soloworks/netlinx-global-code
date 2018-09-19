MODULE_NAME='mCYPMatrix'(DEV vdvControl, DEV ipDevice)

INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)
	
	IP or RS232 control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uMatrix{
	// COMMS
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	  	IP_HOST[255]
	CHAR 	  	Tx[1000]
	CHAR 	  	Rx[1000]
	INTEGER 	DEBUG
	INTEGER 	CONN_STATE
	
	// Status
	SINTEGER CUR_VOL
	SLONG    CUR_VOL_255
	SINTEGER	NEW_VOL
	INTEGER	VOL_PEND
	SINTEGER RANGE[2]
	INTEGER  STEP
	INTEGER  MUTE
	INTEGER  SOURCE
	INTEGER  BYPASS
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timelines **)
LONG TLID_POLL			= 1
LONG TLID_POWER		= 2
LONG TLID_COMMS		= 3
LONG TLID_TIMEOUT		= 4
LONG TLID_VOL			= 5

INTEGER DEBUG_ERR 	= 0
INTEGER DEBUG_STD 	= 1
INTEGER DEBUG_DEV 	= 2

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uMatrix myMatrix
(** Timeline Times **)
LONG TLT_POWER[]		= {  12000 }
LONG TLT_POLL[]		= {  15000 }
LONG TLT_COMMS[]		= { 120000 }
LONG TLT_TIMEOUT[]	= {   1000 }
LONG TLT_VOL[]			= {    150 }
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
DEFINE_START{
	myMatrix.isIP = !(ipDevice.NUMBER)
	CREATE_BUFFER ipDevice, myMatrix.Rx
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		myMatrix.CONN_STATE = CONN_STATE_CONNECTED
		IF(myMatrix.isIP){
			fnSendFromQueue()
		}
		ELSE{
			SEND_COMMAND ipDevice, 'SET MODE DATA' 
			SEND_COMMAND ipDevice, 'SET BAUD 19200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myMatrix.CONN_STATE 	= CONN_STATE_OFFLINE
		IF(myMatrix.isIP){
			myMatrix.Tx 		= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(myMatrix.isIP){
			STACK_VAR CHAR _MSG[255]
			myMatrix.CONN_STATE 	= CONN_STATE_OFFLINE
			myMatrix.Tx 				= ''	
			SWITCH(DATA.NUMBER){
				CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
				DEFAULT:{
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
				}
			}
			fnDebug(DEBUG_STD,"'CYP IP Error:[',myMatrix.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myMatrix.Rx,';',1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMatrix.Rx,';',1),1))
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myMatrix.IP_HOST)){
		fnDebug(DEBUG_ERR,'AMP IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to CYP on ',"myMatrix.IP_HOST,':',ITOA(myMatrix.IP_PORT)")
		myMatrix.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(ipDevice.port, myMatrix.IP_HOST, myMatrix.IP_PORT, IP_TCP) 
	}
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}
/******************************************************************************
	Polling Control
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('ST',TRUE)	// Query Zone 1 Power
	fnAddToQueue('R AUDIO MUTE',TRUE)	// Query Zone 1 Power
	fnAddToQueue('R VOLUME',TRUE)	// Query Zone 1 Power
	fnAddToQueue('R SOURCE',TRUE)	// Query Zone 1 Power
	fnAddToQueue('R BYPASS',TRUE)	// Query Zone 1 Power
}
/******************************************************************************
	Data Queue and Sending
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], INTEGER isPoll){
	
	myMatrix.Tx = "myMatrix.Tx,pCMD,$0D"
	
	fnSendFromQueue()
	
	IF(!isPoll){
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myMatrix.isIP && myMatrix.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	ELSE IF(myMatrix.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myMatrix.Tx,"$0D",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myMatrix.Tx,"$0D",1)
		fnDebug(DEBUG_STD,'->AMP',_ToSend);
		SEND_STRING ipDevice, _ToSend
		fnInitTimeout(TRUE)
	}
	fnInitPoll()
}

DEFINE_FUNCTION fnInitTimeout(INTEGER pSTATE){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(pSTATE){
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(myMatrix.isIP && myMatrix.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
	myMatrix.Tx = ''
}
/******************************************************************************
	Debug 
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myMatrix.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Process Feedback 
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_DEV,'fnProcessFeedback()',"'pDATA=',pDATA")
	
	SWITCH(pDATA){
		CASE 'SOURCE':{
			myMatrix.SOURCE = ATOI(pDATA)
		}
		CASE 'BYPASS':{
			myMatrix.BYPASS = ATOI(pDATA)
		}
		CASE 'VOLUME':{
			myMatrix.CUR_VOL = ATOI(pDATA)
			// Set up 255 range
			myMatrix.CUR_VOL_255 = fnScaleRange(myMatrix.CUR_VOL,myMatrix.RANGE[1],myMatrix.RANGE[2],0,255)
		}
		CASE 'AUDIO MUTE':{
			myMatrix.MUTE = ATOI(pDATA)
		}
	}
	
	fnSendFromQueue()
	
	fnInitTimeout(FALSE)
	
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,"'PROPERTY-META,MAKE,CYP'"
		SEND_STRING DATA.DEVICE,"'PROPERTY-META,MODEL,Matrix'"
		SEND_STRING DATA.DEVICE, 'PROPERTIES-0,100'
		SEND_STRING DATA.DEVICE, 'RANGE-0,100'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myMatrix.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myMatrix.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myMatrix.IP_HOST = DATA.TEXT
							myMatrix.IP_PORT = 23
						}
						fnPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	myMatrix.DEBUG = DEBUG_STD
							CASE 'DEV':   	myMatrix.DEBUG = DEBUG_DEV
							DEFAULT: 		myMatrix.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'MATRIX':{
				STACK_VAR INTEGER MTX_I
				MTX_I = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				SWITCH(ATOI(DATA.TEXT)){
					CASE 2:fnAddToQueue("'S SOURCE ',ITOA(MTX_I)",FALSE)
					CASE 1:fnAddToQueue("'S BYPASS ',ITOA(MTX_I)",FALSE)
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myMatrix.MUTE = TRUE
					CASE 'OFF':		myMatrix.MUTE = FALSE
					CASE 'TOGGLE':	myMatrix.MUTE = !myMatrix.MUTE
				}
				fnAddToQueue("'S AUDIO MUTE',ITOA(myMatrix.MUTE)",FALSE)
			}
			CASE 'VOLUME':{
				IF(!myMatrix.STEP){myMatrix.STEP = 5}
				SWITCH(DATA.TEXT){
					//CASE 'INC':fnAddToQueue("'S VOLUME '",FALSE)
					//CASE 'DEC':fnAddToQueue("'VOL --'",FALSE)
					DEFAULT:{
						myMatrix.NEW_VOL = ATOI(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_VOL)){
							fnAddToQueue("'S VOLUME ',  FORMAT('%02d',ATOI(DATA.TEXT))",FALSE)
							TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myMatrix.VOL_PEND = TRUE
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL]{
	IF(myMatrix.VOL_PEND){
		fnAddToQueue("'S VOLUME ',FORMAT('%02d',myMatrix.NEW_VOL)",FALSE)
		myMatrix.VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Virtal Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	// Zone Feedback
	SEND_LEVEL vdvControl,1,myMatrix.CUR_VOL
	SEND_LEVEL vdvControl,3,myMatrix.CUR_VOL_255
	[vdvControl, 199] = (myMatrix.MUTE)
	
	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/