MODULE_NAME='mCYPAmp'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)

	IP or RS232 control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uZone{
	// Status
	INTEGER  POWER
	INTEGER  CUR_INPUT
	INTEGER  NEW_INPUT
	INTEGER  MICMUTE
	INTEGER  MUTE
	INTEGER  STEP
	// Status
	SINTEGER CUR_VOL
	SLONG    CUR_VOL_255
	SINTEGER	NEW_VOL
	INTEGER	VOL_PEND
	SINTEGER RANGE[2]
}

DEFINE_TYPE STRUCTURE uAMP{
	// COMMS
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	  	IP_HOST[255]
	CHAR 	  	Tx[1000]
	CHAR 	  	Rx[1000]
	INTEGER 	DEBUG
	INTEGER 	CONN_STATE

	uZone    Zone
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
VOLATILE uAMP myAMP
(** Timeline Times **)
LONG TLT_POWER[]		= {  12000 }
LONG TLT_POLL[]		= {  15000 }
LONG TLT_COMMS[]		= { 120000 }
LONG TLT_TIMEOUT[]	= {   3000 }
LONG TLT_VOL[]			= {    150 }
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
DEFINE_START{
	myAMP.isIP = !(ipDevice.NUMBER)
	CREATE_BUFFER ipDevice, myAMP.Rx
	myAMP.Zone.RANGE[1] = -80
	myAMP.Zone.RANGE[2] = 0
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		myAMP.CONN_STATE = CONN_STATE_CONNECTED
		IF(!myAMP.isIP){
			SEND_COMMAND ipDevice, 'SET MODE DATA'
			SEND_COMMAND ipDevice, 'SET BAUD 115200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myAMP.CONN_STATE 	= CONN_STATE_OFFLINE
		IF(myAMP.isIP){
			myAMP.Tx 		= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(myAMP.isIP){
			STACK_VAR CHAR _MSG[255]
			myAMP.CONN_STATE 	= CONN_STATE_OFFLINE
			myAMP.Tx 				= ''
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
			fnDebug(DEBUG_STD,"'AMP IP Error:[',myAMP.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',fnBytesToString(DATA.TEXT))
		WHILE(FIND_STRING(myAMP.Rx,"$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myAMP.Rx,"$0A",1),1))
		}
		IF(FIND_STRING(myAMP.Rx,'telnet->',1)){
			myAMP.CONN_STATE = CONN_STATE_CONNECTED
			myAMP.Rx = ''
			fnSendFromQueue()
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myAMP.IP_HOST)){
		fnDebug(DEBUG_ERR,'AMP IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to AMP on ',"myAMP.IP_HOST,':',ITOA(myAMP.IP_PORT)")
		myAMP.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(ipDevice.port, myAMP.IP_HOST, myAMP.IP_PORT, IP_TCP)
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
	fnAddToQueue('PWR S',TRUE)	// Query Zone 1 Power
}
/******************************************************************************
	Data Queue and Sending
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], INTEGER isPoll){

	myAMP.Tx = "myAMP.Tx,pCMD,$0D"

	fnSendFromQueue()

	IF(!isPoll){
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myAMP.isIP && myAMP.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	ELSE IF(myAMP.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myAMP.Tx,"$0D",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myAMP.Tx,"$0D",1)
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
	IF(myAMP.isIP && myAMP.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
	myAMP.Tx = ''
}
/******************************************************************************
	Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myAMP.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Process Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	pDATA = fnRemoveWhiteSpace(pDATA)
	IF(LENGTH_ARRAY(pDATA)){
		IF(pDATA[LENGTH_ARRAY(pDATA)] == $0D){
			pDATA = fnStripCharsRight(pDATA,1)
		}
	}
	IF(!LENGTH_ARRAY(pDATA)){
		RETURN
	}

	fnDebug(DEBUG_DEV,'fnProcessFeedback()',"'pDATA(str)=',pDATA")
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'POWER':{
			SWITCH(pDATA){
				CASE 'ON':  myAMP.ZONE.POWER = TRUE
				CASE 'OFF': myAMP.ZONE.POWER = FALSE
			}
			IF(myAMP.ZONE.POWER){
				fnAddToQueue("'VOL S'",TRUE)	// Query Zone 1 Volume
			}
		}
		CASE 'VOLUME':{
			REMOVE_STRING(pDATA,' ',1)	// Remove 'Is'
			pDATA = fnStripCharsRight(pDATA,2)	// Remove dB
			myAMP.ZONE.CUR_VOL = ATOI(pDATA)
			// Set up 255 range
			myAMP.ZONE.CUR_VOL_255 = fnScaleRange(myAMP.ZONE.CUR_VOL,myAMP.ZONE.RANGE[1],myAMP.ZONE.RANGE[2],0,255)

			fnAddToQueue("'MUTE S'",TRUE)	// Query Zone 1 Mute
		}
		CASE 'MUTE':{
			REMOVE_STRING(pDATA,' ',1)	// Remove 'Is'
			myAMP.ZONE.MUTE = ATOI(pDATA)
			fnAddToQueue("'SOURCE S'",TRUE)	// Query Zone 1 Source
		}
		CASE 'SOURCE':{
			myAMP.Zone.CUR_INPUT = ATOI(pDATA)
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
		SEND_STRING DATA.DEVICE,"'PROPERTY-META,MODEL,AU-A300'"
		SEND_STRING DATA.DEVICE, 'PROPERTY-RANGE,-80,0'
		SEND_STRING DATA.DEVICE, 'RANGE--80,0'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myAMP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myAMP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myAMP.IP_HOST = DATA.TEXT
							myAMP.IP_PORT = 23
						}
						fnPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	myAMP.DEBUG = DEBUG_STD
							CASE 'DEV':   	myAMP.DEBUG = DEBUG_DEV
							DEFAULT: 		myAMP.DEBUG = DEBUG_ERR
						}
					}
					CASE 'STEP':{
						myAMP.ZONE.STEP = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'INPUT':{
				IF(myAMP.ZONE.POWER){
					fnAddToQueue("'SOURCE ',DATA.TEXT",FALSE)
				}
				ELSE{
					fnAddToQueue("'PWR 1'",FALSE)
					myAMP.ZONE.NEW_INPUT = ATOI(DATA.TEXT)
					IF(!TIMELINE_ACTIVE(TLID_POWER)){
						TIMELINE_CREATE(TLID_POWER,TLT_POWER,LENGTH_ARRAY(TLT_POWER),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{ fnAddToQueue("'PWR 1'",FALSE) }
					CASE 'OFF':{fnAddToQueue("'PWR 0'",FALSE) }
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myAMP.ZONE.MUTE = TRUE
					CASE 'OFF':		myAMP.ZONE.MUTE = FALSE
					CASE 'TOGGLE':	myAMP.ZONE.MUTE = !myAMP.ZONE.MUTE
				}
				fnAddToQueue("'MUTE ',ITOA(myAMP.ZONE.MUTE)",FALSE)
			}
			CASE 'VOLUME':{
				IF(!myAMP.ZONE.STEP){myAMP.ZONE.STEP = 5}
				SWITCH(DATA.TEXT){
					CASE 'INC':fnAddToQueue("'VOL ++'",FALSE)
					CASE 'DEC':fnAddToQueue("'VOL --'",FALSE)
					DEFAULT:{
						myAMP.ZONE.NEW_VOL = ATOI(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_VOL)){
							fnAddToQueue("'VOL ',  FORMAT('%02d',ATOI(DATA.TEXT))",FALSE)
							TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myAMP.ZONE.VOL_PEND = TRUE
						}
					}
				}
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_POWER]{
	fnAddToQueue("'SOURCE ',ITOA(myAMP.ZONE.NEW_INPUT)",FALSE)
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL]{
	IF(myAMP.ZONE.VOL_PEND){
		fnAddToQueue("'VOL ',FORMAT('%02d',myAMP.ZONE.NEW_VOL)",FALSE)
		myAMP.ZONE.VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Virtal Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	// Zone Feedback
	SEND_LEVEL vdvControl,1,myAMP.ZONE.CUR_VOL
	SEND_LEVEL vdvControl,3,myAMP.ZONE.CUR_VOL_255
	[vdvControl, 198] = (myAMP.ZONE.MICMUTE)
	[vdvControl, 199] = (myAMP.ZONE.MUTE)
	[vdvControl, 255] = (myAMP.ZONE.POWER)

	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/