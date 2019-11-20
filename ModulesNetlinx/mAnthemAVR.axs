MODULE_NAME='mAnthemAVR'(DEV vdvZone[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)

	AVR IP or RS232 control
	Multi Zone Control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uZone{
	// Status
	INTEGER  POWER
	INTEGER  CUR_INPUT
	INTEGER  NEW_INPUT
	INTEGER  MUTE
	INTEGER  STEP
	// Status
	SINTEGER CUR_VOL
	SLONG    CUR_VOL_255
	SINTEGER	NEW_VOL
	INTEGER	VOL_PEND
	SINTEGER RANGE[2]
}

DEFINE_TYPE STRUCTURE uAVR{
	// COMMS
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	  	IP_HOST[255]
	CHAR 	  	Tx[1000]
	CHAR 	  	Rx[1000]
	INTEGER 	DEBUG
	INTEGER 	CONN_STATE

	// MetaData
	CHAR 	  	MODEL[20]

	uZone    ZONE[2]
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

LONG TLID_VOL_00		= 10
LONG TLID_VOL_01		= 11
LONG TLID_VOL_02		= 12

LONG TLID_POWER_Z00	= 20
LONG TLID_POWER_Z01	= 21
LONG TLID_POWER_Z02	= 22

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
VOLATILE uAVR myAVR
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
	myAVR.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myAVR.Rx
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myAVR.CONN_STATE = CONN_STATE_CONNECTED
		IF(myAVR.isIP){
			fnSendFromQueue()
		}
		ELSE{
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 115200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myAVR.CONN_STATE 	= CONN_STATE_OFFLINE
		IF(myAVR.isIP){
			myAVR.Tx 		= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(myAVR.isIP){
			STACK_VAR CHAR _MSG[255]
			myAVR.CONN_STATE 	= CONN_STATE_OFFLINE
			myAVR.Tx 				= ''
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
			fnDebug(DEBUG_STD,"'AVR IP Error:[',myAVR.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myAVR.Rx,';',1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myAVR.Rx,';',1),1))
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myAVR.IP_HOST)){
		fnDebug(DEBUG_ERR,'AVR IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to AVR on ',"myAVR.IP_HOST,':',ITOA(myAVR.IP_PORT)")
		myAVR.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myAVR.IP_HOST, myAVR.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
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
	IF(!LENGTH_ARRAY(myAVR.MODEL)){
		fnAddToQueue('IDM?',TRUE)	// Query Unit Model
	}
	fnAddToQueue('Z1POW?',TRUE)	// Query Zone 1 Power
}
/******************************************************************************
	Data Queue and Sending
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], INTEGER isPoll){

	myAVR.Tx = "myAVR.Tx,pCMD,';'"

	fnSendFromQueue()

	IF(!isPoll){
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myAVR.isIP && myAVR.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	ELSE IF(myAVR.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myAVR.Tx,';',1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myAVR.Tx,';',1)
		fnDebug(DEBUG_STD,'->AVR',_ToSend);
		SEND_STRING dvDevice, _ToSend
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
	IF(myAVR.isIP && myAVR.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
	myAVR.Tx = ''
}
/******************************************************************************
	Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myAVR.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvZone[1].Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Process Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_DEV,'fnProcessFeedback()',"'pDATA=',pDATA")

	SWITCH(pDATA[1]){
		CASE 'Z':{
			STACK_VAR INTEGER z
			GET_BUFFER_CHAR(pDATA)
			z = ATOI("GET_BUFFER_CHAR(pDATA)")
			SWITCH(GET_BUFFER_STRING(pDATA,3)){
				CASE 'POW':{
					myAVR.ZONE[z].POWER = ATOI(pDATA)
					IF(myAVR.ZONE[z].POWER){
						fnAddToQueue("'Z',ITOA(z),'VOL?'",TRUE)	// Query Zone 1 Volume
						fnAddToQueue("'Z',ITOA(z),'MUT?'",TRUE)	// Query Zone 1 Mute
					}
				}
				CASE 'MUT':{
					myAVR.ZONE[z].MUTE = ATOI(pDATA)
				}
				CASE 'VOL':{
					myAVR.ZONE[z].CUR_VOL = ATOI(pDATA)
					// Set up 255 range
					myAVR.ZONE[z].CUR_VOL_255 = fnScaleRange(myAVR.ZONE[z].CUR_VOL,myAVR.ZONE[z].RANGE[1],myAVR.ZONE[z].RANGE[2],0,255)
				}
			}
		}
		DEFAULT:{
			SWITCH(GET_BUFFER_STRING(pDATA,3)){
				CASE 'IDM':{
					IF(myAVR.MODEL != pDATA){
						myAVR.MODEL = pDATA
						SEND_STRING vdvZone[1],"'PROPERTY-META,MAKE,ANTHEM'"
						SEND_STRING vdvZone[1],"'PROPERTY-META,MODEL,',myAVR.MODEL"
					}
				}
			}
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
DEFINE_EVENT DATA_EVENT[vdvZone]{
	ONLINE:{
		SWITCH(GET_LAST(vdvZone)){
			CASE 1: SEND_STRING DATA.DEVICE, 'RANGE--90,0'
			CASE 2: SEND_STRING DATA.DEVICE, 'RANGE--90,0'
		}
	}
	COMMAND:{
		STACK_VAR INTEGER z
		z = GET_LAST(vdvZone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myAVR.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myAVR.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myAVR.IP_HOST = DATA.TEXT
							myAVR.IP_PORT = 14999
						}
						fnPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	myAVR.DEBUG = DEBUG_STD
							CASE 'DEV':   	myAVR.DEBUG = DEBUG_DEV
							DEFAULT: 		myAVR.DEBUG = DEBUG_ERR
						}
					}
					CASE 'STEP':{
						myAVR.ZONE[z].STEP = ATOI(DATA.TEXT)
					}
					CASE 'BOUNDS':{
						myAVR.ZONE[z].RANGE[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						myAVR.ZONE[z].RANGE[2] = ATOI(DATA.TEXT)
						SEND_STRING DATA.DEVICE, "'RANGE-',ITOA(myAVR.ZONE[z].RANGE[1]),',',ITOA(myAVR.ZONE[z].RANGE[2])"
					}
				}
			}
			CASE 'INPUT':{
				IF(myAVR.ZONE[z].POWER){
					fnAddToQueue("'Z',ITOA(z),'INP',DATA.TEXT",FALSE)
				}
				ELSE{
					fnAddToQueue("'Z',ITOA(z),'POW1'",FALSE)
					myAVR.ZONE[z].NEW_INPUT = ATOI(DATA.TEXT)
					IF(!TIMELINE_ACTIVE(TLID_POWER_Z00+z)){
						TIMELINE_CREATE(TLID_POWER_Z00+z,TLT_POWER,LENGTH_ARRAY(TLT_POWER),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{ fnAddToQueue("'Z',ITOA(z),'POW1'",FALSE) }
					CASE 'OFF':{fnAddToQueue("'Z',ITOA(z),'POW0'",FALSE) }
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myAVR.ZONE[z].MUTE = TRUE
					CASE 'OFF':		myAVR.ZONE[z].MUTE = FALSE
					CASE 'TOGGLE':	myAVR.ZONE[z].MUTE = !myAVR.ZONE[z].MUTE
				}
				fnAddToQueue("'Z',ITOA(z),'MUT',ITOA(myAVR.ZONE[z].MUTE)",FALSE)
			}
			CASE 'VOLUME':{
				IF(!myAVR.ZONE[z].STEP){myAVR.ZONE[z].STEP = 5}
				SWITCH(DATA.TEXT){
					CASE 'INC':fnAddToQueue("'Z',ITOA(z),'VUP',FORMAT('%02d',myAVR.ZONE[z].STEP)",FALSE)
					CASE 'DEC':fnAddToQueue("'Z',ITOA(z),'VDN',FORMAT('%02d',myAVR.ZONE[z].STEP)",FALSE)
					DEFAULT:{
						myAVR.ZONE[z].NEW_VOL = ATOI(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_VOL_00+z)){
							SELECT{
								ACTIVE(myAVR.ZONE[z].NEW_VOL <  0):fnAddToQueue("'Z',ITOA(z),'VOL',  FORMAT('%02d',ATOI(DATA.TEXT))",FALSE)
								ACTIVE(myAVR.ZONE[z].NEW_VOL >= 0):fnAddToQueue("'Z',ITOA(z),'VOL+', FORMAT('%02d',ATOI(DATA.TEXT))",FALSE)
							}
							TIMELINE_CREATE(TLID_VOL_00+z,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myAVR.ZONE[z].VOL_PEND = TRUE
						}
					}
				}
				myAVR.ZONE[z].MUTE = FALSE
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_POWER_Z01]
TIMELINE_EVENT[TLID_POWER_Z02]{
	STACK_VAR INTEGER z
	z = TIMELINE.ID - TLID_POWER_Z00
	fnAddToQueue("'Z',ITOA(z),'INP',ITOA(myAVR.ZONE[z].NEW_INPUT)",FALSE)
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL_01]
TIMELINE_EVENT[TLID_VOL_02]{
	STACK_VAR INTEGER z
	z = TIMELINE.ID - TLID_VOL_00
	IF(myAVR.ZONE[z].VOL_PEND){
		IF(myAVR.ZONE[z].NEW_VOL < 0){
			fnAddToQueue("'Z',ITOA(z),'VOL',FORMAT('%02d',myAVR.ZONE[z].NEW_VOL)",FALSE)
		}
		ELSE{
			fnAddToQueue("'Z',ITOA(z),'VOL+',FORMAT('%02d',myAVR.ZONE[z].NEW_VOL)",FALSE)
		}
		myAVR.ZONE[z].VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Virtal Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER z
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
		// Zone Feedback
		SEND_LEVEL vdvZone[z],1,myAVR.ZONE[z].CUR_VOL
		SEND_LEVEL vdvZone[z],3,myAVR.ZONE[z].CUR_VOL_255
		[vdvZone[z], 199] = (myAVR.ZONE[z].MUTE)
		[vdvZone[z], 255] = (myAVR.ZONE[z].POWER)
	}

	[vdvZone, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvZone, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/