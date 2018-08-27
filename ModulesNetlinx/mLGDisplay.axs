MODULE_NAME='mLGDisplay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	LG Screen Control Module
	With Basic Volume Control
******************************************************************************/
DEFINE_TYPE STRUCTURE uLGDisplay{
	INTEGER 	DISABLED			// Is module Disabled
	INTEGER 	ID					// Device ID
	INTEGER	isIP				// Is IP controlled
	INTEGER 	CONN_STATE		// Current Connection State
	INTEGER 	IP_PORT			// Current IP Port
	CHAR 		IP_HOST[255]	// Current IP Host
	INTEGER	DEBUG				// Current Debug Level
	CHAR		Tx[1000]			// Current Tx Queue
	CHAR		Rx[1000]			// Current Rx Queue
	CHAR		LAST_SENT[2]	// Last send command (for Polling reference)
	INTEGER	PEND				// True if command is pending
	// State
	INTEGER	POWER				// Current Power State
	CHAR		INPUT[2]			// Current Input State
	CHAR		DES_INPUT[2]	// Desired Input State
	INTEGER 	VOL				// Current Volume Level
	INTEGER	VOL_PEND			// True if Volume Send is Pending
	INTEGER	LAST_VOL			// Value for a pending Volume
	INTEGER	MUTE				// Current Audio Mute State
	INTEGER	VIDMUTE
	// Meta
	CHAR		META_SN[20]		// Serial Number of Unit
}

DEFINE_CONSTANT
	(** Timeline IDs **)
LONG TLID_POLL 		= 1
LONG TLID_TIMEOUT		= 2
LONG TLID_COMMS 		= 3
LONG TLID_VOL			= 4
LONG TLID_BOOT			= 5
	(**  **)
LONG TLT_POLL[] 		= {10000}
LONG TLT_TIMEOUT[] 	= { 2500}
LONG TLT_COMMS[] 		= {90000}
LONG TLT_VOL[]			= {  250}
LONG TLT_BOOT[]		= { 5000}

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

DEFINE_VARIABLE
VOLATILE uLGDisplay myLGDisplay

/******************************************************************************
	System Startup Code
******************************************************************************/
DEFINE_START{
	myLGDisplay.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice,myLGDisplay.Rx
}
/******************************************************************************
	Communication Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bDebugType, CHAR Msg[], CHAR MsgData[]){
	IF(myLGDisplay.DEBUG >= bDebugType)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myLGDisplay.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'LG Display Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'LG Display ',myLGDisplay.IP_HOST,':',ITOA(myLGDisplay.IP_PORT)")
		myLGDisplay.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myLGDisplay.IP_HOST, myLGDisplay.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD_1,CHAR pCMD_2,CHAR pPARAM[]){
	IF(myLGDisplay.ID == 0){myLGDisplay.ID = 01}
	myLGDisplay.Tx = "myLGDisplay.Tx,pCMD_1,pCMD_2,' ',fnPadLeadingChars(ITOA(myLGDisplay.ID),'0',2),' ',pPARAM,$0D"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
   IF(myLGDisplay.CONN_STATE == CONN_STATE_CONNECTED && !myLGDisplay.PEND && FIND_STRING(myLGDisplay.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[200]
		toSend = REMOVE_STRING(myLGDisplay.Tx,"$0D",1)
		fnDebug(DEBUG_STD,'->LG',toSend)
		SEND_STRING dvDevice,toSend
		myLGDisplay.PEND = TRUE
		myLGDisplay.LAST_SENT = LEFT_STRING(toSend,2)
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnInitPoll()
	}
	ELSE IF(myLGDisplay.isIP && myLGDisplay.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myLGDisplay.Tx = ''
	myLGDisplay.PEND = FALSE
	IF(myLGDisplay.isIP){
		fnCloseTCPConnection()
	}
}
/******************************************************************************
	Boot and Poll Delays
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myLGDisplay.DISABLED){
		IF(!myLGDisplay.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, "'SET BAUD 9600 N 8 1 485 DISABLE'"
			myLGDisplay.CONN_STATE = CONN_STATE_CONNECTED
		}
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(!myLGDisplay.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
		TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('k','a','FF')	// Power Query
	IF(!LENGTH_ARRAY(myLGDisplay.META_SN)){
		//fnAddToQueue('f','y','FF')	// Serial#
	}
}
/******************************************************************************
	Boot and Poll Delays
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER pID
	STACK_VAR CHAR pCMD[1]
	STACK_VAR CHAR pACK[2]

	pCMD = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
	pID  = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
	pACK = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

	fnDebug(DEBUG_STD,'LG->',"ITOA(pID),'-',pCMD,'-',pACK,'-',pDATA")

	IF(pID == myLGDisplay.ID){
		SWITCH(myLGDisplay.LAST_SENT){
			CASE 'ka':{	// POWER
				myLGDisplay.POWER = ATOI(pDATA)
				SWITCH(myLGDisplay.POWER){
					CASE FALSE:{
						myLGDisplay.MUTE = FALSE
					}
					CASE TRUE:{
						WAIT 50{
							fnAddToQueue('x','b','FF')
							fnAddToQueue('k','e','FF')
							fnAddToQueue('k','d','FF')
						}
					}
				}
			}
			CASE 'ke':{	// MUTE
				myLGDisplay.MUTE = !ATOI(pDATA)
				fnAddToQueue('k','f','FF')
			}
			CASE 'kf':{	// VOLUME
				myLGDisplay.VOL = HEXTOI(pDATA)
			}
			CASE 'fy':{	// Serial#
				IF(myLGDisplay.META_SN != pDATA){
					myLGDisplay.META_SN = pDATA
					SEND_STRING vdvControl,"'PROPERTY-META,SN,',myLGDisplay.META_SN"
				}
			}
			CASE 'xb':{	// Input
				myLGDisplay.INPUT = pDATA
				IF(LENGTH_ARRAY(myLGDisplay.DES_INPUT)){
					fnAddToQueue('x','b',myLGDisplay.DES_INPUT)
					myLGDisplay.DES_INPUT = ''
				}
			}
			CASE 'mc':{
				SWITCH(pDATA){
					CASE 'ea':{
						fnAddToQueue('x','b','FF')
						fnAddToQueue('k','e','FF')
					}
				}
			}
		}
		myLGDisplay.PEND = FALSE
		myLGDisplay.LAST_SENT = ''
		fnSendFromQueue()
	}
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myLGDisplay.isIP){
			IF(!myLGDisplay.DISABLED){
				myLGDisplay.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
		}
		ELSE{
			TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	OFFLINE:{
		IF(myLGDisplay.isIP && !myLGDisplay.DISABLED){
			myLGDisplay.CONN_STATE 	= CONN_STATE_OFFLINE;
			myLGDisplay.Tx 			= ''
		}
	}
	ONERROR:{
		IF(myLGDisplay.isIP && !myLGDisplay.DISABLED){
			STACK_VAR CHAR _MSG[255]
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
					myLGDisplay.CONN_STATE 	= CONN_STATE_OFFLINE
					myLGDisplay.Tx 			= ''
				}
			}
			fnDebug(DEBUG_ERR,"'LG Display Error:[',myLGDisplay.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myLGDisplay.DISABLED){
			fnDebug(DEBUG_DEV,'->RAW',DATA.TEXT)
			WHILE(FIND_STRING(myLGDisplay.Rx,'x',1) || FIND_STRING(myLGDisplay.Rx,"$0D,$0D,$0A",1)){
				IF(FIND_STRING(myLGDisplay.Rx,'x',1)){
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGDisplay.Rx,'x',1),1))
				}
				ELSE{
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGDisplay.Rx,"$0D,$0D,$0A",1),3))
				}

				IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}

/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'LG':
							CASE 'TRUE':myLGDisplay.DISABLED = FALSE
							DEFAULT:		myLGDisplay.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myLGDisplay.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myLGDisplay.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myLGDisplay.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myLGDisplay.IP_HOST = DATA.TEXT
								myLGDisplay.IP_PORT = 9761
							}
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						CASE 'DEBUG': {
							SWITCH(DATA.TEXT){
								CASE 'TRUE':	myLGDisplay.DEBUG = DEBUG_STD
								CASE 'DEV':		myLGDisplay.DEBUG = DEBUG_DEV
								DEFAULT:			myLGDisplay.DEBUG = DEBUG_ERR
							}
						}
						CASE 'ID':		myLGDisplay.ID = ATOI(DATA.TEXT)
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplay.POWER = TRUE
						CASE 'OFF':		myLGDisplay.POWER = FALSE
						CASE 'TOGGLE':	myLGDisplay.POWER = !myLGDisplay.POWER
					}
					SWITCH(myLGDisplay.POWER){
						CASE TRUE:	fnAddToQueue('k','a','01')
						CASE FALSE:{
							fnAddToQueue('k','a','00')
							myLGDisplay.MUTE = FALSE
						}
					}
				}
				CASE 'INPUT':{
					STACK_VAR CHAR pInputCode[2]
					SWITCH(DATA.TEXT){
						CASE 'HDMI':
						CASE 'HDMI1':	pInputCode = '90'	// HDMI 1
						CASE 'HDMI2':	pInputCode = '91'	// HDMI 2
						CASE 'HDMI3': 	pInputCode = '92'	// HDMI 3
						CASE 'DTV':		pInputCode = '00'	// DTV
						CASE 'ATV':		pInputCode = '10'	// ANALOGUE TV
						CASE 'AV1':		pInputCode = '20'	// AV 1
						CASE 'AV2':		pInputCode = '21'	// AV 2
						CASE 'AV3':		pInputCode = '22'	// AV 3
						CASE 'COMP':	pInputCode = '40'	// COMP
						CASE 'PC':		pInputCode = '60'	// RGB
						CASE 'DPORT':	pInputCode = 'C0'	// Display Port
						CASE 'DVI':		pInputCode = '80'	// Display Port
					}
					SWITCH(myLGDisplay.POWER){
						CASE TRUE:	fnAddToQueue('x','b',pInputCode)
						CASE FALSE:{
							fnAddToQueue('k','a','01')
							myLGDisplay.DES_INPUT = pInputCode
						}
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplay.MUTE = TRUE
						CASE 'OFF':		myLGDisplay.MUTE = FALSE
						CASE 'TOGGLE':	myLGDisplay.MUTE = !myLGDisplay.MUTE
					}
					IF(myLGDisplay.POWER){
						SWITCH(myLGDisplay.MUTE){
							CASE TRUE:	fnAddToQueue('k','e','00')
							CASE FALSE: fnAddToQueue('k','e','01')
						}
					}
				}
				CASE 'VIDMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplay.VIDMUTE = TRUE
						CASE 'OFF':		myLGDisplay.VIDMUTE = FALSE
						CASE 'TOGGLE':	myLGDisplay.VIDMUTE = !myLGDisplay.VIDMUTE
					}
					IF(myLGDisplay.POWER){
						SWITCH(myLGDisplay.VIDMUTE){
							CASE TRUE:	fnAddToQueue('k','d','00')
							CASE FALSE: fnAddToQueue('k','d','01')
						}
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':{
							IF(myLGDisplay.VOL <= 98){
								fnAddToQueue('k','f',ITOHEX(myLGDisplay.VOL+2))
							}
							ELSE{
								fnAddToQueue('k','f',ITOHEX(100))
							}
						}
						CASE 'DEC':{
							IF(myLGDisplay.VOL >= 2){
								fnAddToQueue('k','f',ITOHEX(myLGDisplay.VOL-2))
							}
							ELSE{
								fnAddToQueue('k','f',ITOHEX(0))
							}
						}
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								myLGDisplay.VOL = ATOI(DATA.TEXT)
								fnAddToQueue('k','f',ITOHEX(myLGDisplay.VOL))
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myLGDisplay.LAST_VOL = ATOI(DATA.TEXT)
								myLGDisplay.VOL_PEND = TRUE
							}
						}
					}
					//myLGDisplay.MUTE = FALSE
				}
				CASE 'CHAN':{
					STACK_VAR CHAR DEST[2]
					STACK_VAR CHAR CHAN[4]
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'TV':		DEST = '00'
						CASE 'DTV': 	DEST = '10'
						CASE 'RADIO': 	DEST = '20'
					}
					CHAN = fnPadLeadingChars(ITOHEX(ATOI(DATA.TEXT)),'0',4)
					IF(myLGDisplay.POWER){
						fnAddToQueue('m','a',"CHAN[1],CHAN[2],' ',CHAN[3],CHAN[4],' ',DEST")
					}
				}
			}
		}
	}
}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!myLGDisplay.DISABLED){
		[vdvControl,199] = (myLGDisplay.MUTE)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,255] = (myLGDisplay.POWER)
		SEND_LEVEL vdvControl,1,myLGDisplay.VOL
	}
}
/******************************************************************************
	EoF
******************************************************************************/