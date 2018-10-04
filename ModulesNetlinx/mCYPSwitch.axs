MODULE_NAME='mCYPSwitch'(DEV vdvControl, DEV ipDevice)

INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)
	
	IP or RS232 control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uSwitch{
	// COMMS
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	  	IP_HOST[255]
	CHAR 	  	Tx[1000]
	CHAR 	  	Rx[1000]
	INTEGER 	DEBUG
	INTEGER 	CONN_STATE
	CHAR     BAUD[10]
	
	INTEGER  SOURCE
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
VOLATILE uSwitch mySwitch
(** Timeline Times **)
LONG TLT_POWER[]		= {  12000 }
LONG TLT_POLL[]		= {  15000 }
LONG TLT_COMMS[]		= { 120000 }
LONG TLT_TIMEOUT[]	= {   1000 }
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
DEFINE_START{
	mySwitch.isIP = !(ipDevice.NUMBER)
	CREATE_BUFFER ipDevice, mySwitch.Rx
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		mySwitch.CONN_STATE = CONN_STATE_CONNECTED
		IF(mySwitch.isIP){
			fnSendFromQueue()
		}
		ELSE{
			WAIT 20{
				SEND_COMMAND ipDevice, 'SET MODE DATA' 
				IF(mySwitch.BAUD == ''){mySwitch.BAUD = '9600'}
				SEND_COMMAND ipDevice, "'SET BAUD ',mySwitch.BAUD,' N 8 1 485 DISABLE'"
				fnPoll()
				fnInitPoll()
			}
		}
	}
	OFFLINE:{
		mySwitch.CONN_STATE 	= CONN_STATE_OFFLINE
		IF(mySwitch.isIP){
			mySwitch.Tx 		= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(mySwitch.isIP){
			STACK_VAR CHAR _MSG[255]
			mySwitch.CONN_STATE 	= CONN_STATE_OFFLINE
			mySwitch.Tx 				= ''	
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
			fnDebug(DEBUG_STD,"'CYP IP Error:[',mySwitch.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(mySwitch.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySwitch.Rx,"$0D,$0A",1),2))
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(mySwitch.IP_HOST)){
		fnDebug(DEBUG_ERR,'CYP IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to CYP on ',"mySwitch.IP_HOST,':',ITOA(mySwitch.IP_PORT)")
		mySwitch.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(ipDevice.port, mySwitch.IP_HOST, mySwitch.IP_PORT, IP_TCP) 
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
	fnAddToQueue('R SOURCE',TRUE)	// Query Zone 1 Power
}
/******************************************************************************
	Data Queue and Sending
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], INTEGER isPoll){
	
	mySwitch.Tx = "mySwitch.Tx,pCMD,$0D,$0A"
	
	fnSendFromQueue()
	
	IF(!isPoll){
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(mySwitch.isIP && mySwitch.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	ELSE IF(mySwitch.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(mySwitch.Tx,"$0D,$0A",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(mySwitch.Tx,"$0D,$0A",1)
		fnDebug(DEBUG_STD,'->CYP',_ToSend);
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
	IF(mySwitch.isIP && mySwitch.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
	mySwitch.Tx = ''
}
/******************************************************************************
	Debug 
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(mySwitch.DEBUG >= pLEVEL)	{
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
			mySwitch.SOURCE = ATOI(pDATA)
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
							mySwitch.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							mySwitch.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							mySwitch.IP_HOST = DATA.TEXT
							mySwitch.IP_PORT = 23
						}
						fnPoll()
					}
					CASE 'BAUD':{
						mySwitch.BAUD = DATA.TEXT
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	mySwitch.DEBUG = DEBUG_STD
							CASE 'DEV':   	mySwitch.DEBUG = DEBUG_DEV
							DEFAULT: 		mySwitch.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'INPUT':{
				fnAddToQueue("'S SOURCE ',DATA.TEXT",FALSE)
			}
		}
	}
}

/******************************************************************************
	Virtal Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	// Zone Feedback	
	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/