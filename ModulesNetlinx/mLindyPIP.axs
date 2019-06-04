MODULE_NAME='mLindyPIP'(DEV vdvControl, DEV dvComms)

INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)
	Lindy PIP 
	IP or RS232 control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uPIP{
	// COMMS
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	  	IP_HOST[255]
	CHAR 	  	Tx[1000]
	CHAR 	  	Rx[1000]
	INTEGER 	DEBUG
	INTEGER 	CONN_STATE
	
	// Status
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
VOLATILE uPIP myPIP
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
	myPIP.isIP = !(dvComms.NUMBER)
	CREATE_BUFFER dvComms, myPIP.Rx
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvComms]{
	ONLINE:{
		myPIP.CONN_STATE = CONN_STATE_CONNECTED
		IF(myPIP.isIP){
			fnSendFromQueue()
		}
		ELSE{
			SEND_COMMAND dvComms, 'SET MODE DATA' 
			SEND_COMMAND dvComms, 'SET BAUD 115200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myPIP.CONN_STATE 	= CONN_STATE_OFFLINE
		IF(myPIP.isIP){
			myPIP.Tx 		= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(myPIP.isIP){
			STACK_VAR CHAR _MSG[255]
			myPIP.CONN_STATE 	= CONN_STATE_OFFLINE
			myPIP.Tx 				= ''	
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
			fnDebug(DEBUG_STD,"'CYP IP Error:[',myPIP.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myPIP.Rx,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPIP.Rx,"$0D",1),2))
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myPIP.IP_HOST)){
		fnDebug(DEBUG_ERR,'CYP IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to CYP on ',"myPIP.IP_HOST,':',ITOA(myPIP.IP_PORT)")
		myPIP.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvComms.port, myPIP.IP_HOST, myPIP.IP_PORT, IP_TCP) 
	}
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvComms.port)
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
	fnAddToQueue('IPCONFIG')	// Query Zone 1 Power
}
/******************************************************************************
	Data Queue and Sending
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[]){
	myPIP.Tx = "myPIP.Tx,pCMD,$0D"
	fnSendFromQueue()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myPIP.isIP && myPIP.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	ELSE IF(myPIP.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myPIP.Tx,"$0D",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myPIP.Tx,"$0D",1)
		fnDebug(DEBUG_STD,'->PIP',_ToSend);
		SEND_STRING dvComms, _ToSend
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
	IF(myPIP.isIP && myPIP.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
	myPIP.Tx = ''
}
/******************************************************************************
	Debug 
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myPIP.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Process Feedback 
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_DEV,'fnProcessFeedback()',"'pDATA=',pDATA")
	
	SWITCH(pDATA){
		CASE 'FAV':{}
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
		SEND_STRING DATA.DEVICE,"'PROPERTY-META,MAKE,Lindy'"
		SEND_STRING DATA.DEVICE,"'PROPERTY-META,MODEL,PIP'"
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myPIP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myPIP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myPIP.IP_HOST = DATA.TEXT
							myPIP.IP_PORT = 23
						}
						fnPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	myPIP.DEBUG = DEBUG_STD
							CASE 'DEV':   	myPIP.DEBUG = DEBUG_DEV
							DEFAULT: 		myPIP.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'PIP':{
				fnAddToQueue("'RFA00',DATA.TEXT")
			}
			CASE 'RAW':{
				fnAddToQueue("DATA.TEXT")
			}
		}
	}
}

/******************************************************************************
	Virtal Device Feedback
******************************************************************************/
DEFINE_PROGRAM{	
	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/