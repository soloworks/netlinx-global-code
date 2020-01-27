MODULE_NAME='mDataVideoRecorder'(DEV vdvControl,DEV dvDevice)
/******************************************************************************
	Set up for basic control - tested on Hard Disk Reecorder HDR-200
******************************************************************************/
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	INTEGER 	DISABLED
	CHAR 	   Tx[200]
	CHAR 	   Rx[200]
	INTEGER	PEND
	INTEGER 	CONN_STATE
	INTEGER 	IP_PORT						// IP Address
	CHAR		IP_HOST[255]				//	IP Port
	INTEGER 	IP_STATE						// Connection State
	INTEGER	isIP							// Device is IP driven
	CHAR     BAUD_RATE[255]          // Serial Baud rate
	INTEGER 	DEBUG							// Debugging
}

DEFINE_TYPE STRUCTURE uHDR{
	uComms   COMMS
	// State
	INTEGER  POWER
	CHAR     desCOMMAND

	// Feedback
	CHAR     STATUS_CODE[32]
	CHAR     PLAY_MODE[16]
	CHAR     TIME_MODE[16]
	CHAR     TIME_FB[12][16]
	// RMS
	CHAR 		META_SN[14]
	CHAR		META_MODEL[50]
	CHAR     META_MAKE[50]
}

DEFINE_CONSTANT
// Timelines
LONG TLID_COMMS 	= 1
LONG TLID_RETRY	= 2
LONG TLID_POLL		= 3
LONG TLID_TIMEOUT	= 4
LONG TLID_BOOT		= 5

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

// POWER States
INTEGER P_ON  = 1
INTEGER P_OFF = 2

// DEBUG States
INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= { 120000 }
LONG TLT_RETRY[]		= {   5000 }
LONG TLT_POLL[]  		= {  25000 }
LONG TLT_TIMEOUT[]	= {   1500 }
LONG TLT_BOOT[]		= {   5000 }

VOLATILE uHDR myHDR

/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myHDR.COMMS.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myHDR.COMMS.Rx
}
/******************************************************************************
	Helper Functions
******************************************************************************/
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myHDR.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Bluray IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to Bluray on ',"myHDR.COMMS.IP_HOST,':',ITOA(myHDR.COMMS.IP_PORT)")
		myHDR.COMMS.IP_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myHDR.COMMS.IP_HOST, myHDR.COMMS.IP_PORT, IP_TCP)
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

DEFINE_FUNCTION CHAR[25] fnBuildCommand(CHAR pCMD[], CHAR pDATA[]){

	STACK_VAR CHAR 	myPacket[25]
	STACK_VAR INTEGER CHK_SUM
	STACK_VAR INTEGER x

	myPacket = "pCMD,pDATA"
	FOR (x = 1; x <=LENGTH_ARRAY(myPacket); x++){
		CHK_SUM = CHK_SUM + myPacket[x];
	}

	RETURN "myPacket,CHK_SUM"
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], CHAR pDATA[]){

	STACK_VAR CHAR myMessage[255]

	myMessage = fnBuildCommand(pCMD,pDATA)

	myHDR.COMMS.Tx = "myHDR.COMMS.Tx,myMessage,'||'"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myHDR.COMMS.PEND && myHDR.COMMS.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myHDR.COMMS.Tx,'||',1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(myHDR.COMMS.Tx,'||',1),2)
		fnDebugHex(DEBUG_STD,'->HDR ',toSend)
		SEND_STRING dvDevice,toSend
		myHDR.COMMS.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(myHDR.COMMS.isIP && myHDR.COMMS.CONN_STATE == CONN_STATE_OFFLINE && FIND_STRING(myHDR.COMMS.Tx,'||',1)){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myHDR.COMMS.PEND = FALSE
	myHDR.COMMS.Tx = ''
	IF(myHDR.COMMS.isIP && myHDR.COMMS.CONN_STATE = CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myHDR.COMMS.DISABLED){
		IF(!myHDR.COMMS.isIP){
			IF(myHDR.COMMS.BAUD_RATE = ''){
				myHDR.COMMS.BAUD_RATE = '38400 O 8 1 422 DISABLE'
			}
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice,"'SET BAUD ',myHDR.COMMS.BAUD_RATE"
			SEND_COMMAND dvDevice, 'GET BAUD'
			myHDR.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		}
		myHDR.META_MAKE  = 'DataVideo'
		myHDR.META_MODEL = 'HDR-200'
		myHDR.META_SN    = 'N/A'
		SEND_STRING vdvControl, 'PROPERTY-META,TYPE,HD-Recorder'
		SEND_STRING vdvControl,"'PROPERTY-META,MAKE,', myHDR.META_MAKE"
		SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myHDR.META_MODEL"
		SEND_STRING vdvControl,"'PROPERTY-META,SN,',   myHDR.META_SN"
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR Msg[], CHAR MsgData[]){
	IF(myHDR.COMMS.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg,' [', MsgData,']'"
	}
}
DEFINE_FUNCTION fnDebugHex(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myHDR.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR pHEX[1000]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
			pHEX = "pHEX,'$',fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2)"
		}
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg,' [', pHEX,']'"
	}
}

/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	SEND_COMMAND vdvControl,'QUERY-STATUS'
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myHDR.COMMS.DISABLED){
			IF(myHDR.COMMS.isIP){
				myHDR.COMMS.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		IF(myHDR.COMMS.isIP && !myHDR.COMMS.DISABLED){
			myHDR.COMMS.CONN_STATE = CONN_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myHDR.COMMS.isIP && !myHDR.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myHDR.COMMS.IP_STATE = CONN_STATE_OFFLINE
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
			fnDebug(TRUE,"'HDR IP Error:[',myHDR.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		STACK_VAR CHAR pDATA[16]
		pDATA = DATA.TEXT
		fnDebug(DEBUG_STD,'RAW->',pDATA)
		// Strip any Garbage (ACK/NACKs)
		IF(pDATA == "$12,$11,$B0,$01,$D4"){// in Hex
			REMOVE_STRING(pDATA,"$D4",1)
			SEND_STRING vdvControl,'HDR Online'
		}
		IF(pDATA == "$15"){// Nack in Hex
			REMOVE_STRING(pDATA,"$15",1)
		}
		IF(FIND_STRING(myHDR.COMMS.RX,"$10,$01",1)){
			fnProcessFeedback(REMOVE_STRING(myHDR.COMMS.RX,pDATA,1))
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER pPOWER
	STACK_VAR INTEGER pTIME
	REMOVE_STRING(pDATA,'485 DISABLED',1)
	fnDebug(DEBUG_STD,'HDR-> ',pDATA)
	SWITCH(fnRemoveWhiteSpace(pDATA)){
		CASE 'DBP2010':{
			pPOWER = P_ON
		}
		CASE '!':{
			pPOWER = P_OFF
		}
		DEFAULT:{
		}
		IF(myHDR.POWER <> pPOWER){
			SWITCH(pPOWER){
				CASE P_ON:{
					TLT_POLL[1] = 5000
					TIMELINE_RELOAD(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_COMMS))
				}
				DEFAULT:{
					TLT_POLL[1] = 25000
					TIMELINE_RELOAD(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_COMMS))
				}
			}
			myHDR.POWER = pPOWER
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'FALSE': { myHDR.COMMS.DEBUG = DEBUG_ERR }
							CASE 'TRUE':  { myHDR.COMMS.DEBUG = DEBUG_STD }
							CASE 'DEV':   { myHDR.COMMS.DEBUG = DEBUG_DEV }
							DEFAULT:      { myHDR.COMMS.DEBUG = ATOI(DATA.TEXT) }
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myHDR.COMMS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myHDR.COMMS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myHDR.COMMS.IP_HOST = DATA.TEXT
							myHDR.COMMS.IP_PORT = 9030
						}
						fnRetryConnection()
					}
					CASE 'BAUD':{
						IF(FIND_STRING(DATA.TEXT,' ',1)){
							myHDR.COMMS.BAUD_RATE = DATA.TEXT
						}
						ELSE{
							myHDR.COMMS.BAUD_RATE = "DATA.TEXT,' O 8 1 422 DISABLE'"
						}
						//SEND_COMMAND dvDevice, 'SET MODE DATA'
						SEND_COMMAND dvDevice,"'SET BAUD ',myHDR.COMMS.BAUD_RATE"
						SEND_COMMAND dvDevice, 'GET BAUD'
						fnPoll()
						fnInitPoll()
					}
				}
			}
			CASE 'RAW':{
				myHDR.COMMS.Tx = "myHDR.COMMS.Tx,DATA.TEXT,'||'"
				fnSendFromQueue()
			}
			CASE 'SEND':{
				fnAddToQueue(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),DATA.TEXT)
			}
//			CASE 'POWER':{
//				SWITCH(DATA.TEXT){
//					CASE 'ON'			:fnAddToQueue(' ',"$00")
//					CASE 'OFF'			:fnAddToQueue('!',"$00")
//				}
//			}
			CASE 'QUERY':{
				SWITCH(DATA.TEXT){
					CASE 'STATUS'		:fnAddToQueue("$00","$11")
				}
			}
			CASE 'CONTROL':
			CASE 'CTRL':
			CASE 'PUSH':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY'			:fnAddToQueue("$20","$01")
					CASE 'STOP'			:fnAddToQueue("$20","$00")
					CASE 'PAUSE'		:fnAddToQueue("$21","$13,$00")
					CASE 'SKIP+'		:fnAddToQueue("$40","$50")
					CASE 'SKIP-'		:fnAddToQueue("$40","$51")
					CASE 'FASTFORWARD':fnAddToQueue("$20","$10")
					CASE 'REWIND'		:fnAddToQueue("$20","$20")
					CASE 'RECORD'		:fnAddToQueue("$20","$02")
					CASE 'INPUT'		:fnAddToQueue("$41","$53,$01")
					CASE 'SDI_IN'		:fnAddToQueue("$41","$53,$01")
				}
				fnPoll()
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myHDR.POWER)
}
/******************************************************************************
	EoF
******************************************************************************/