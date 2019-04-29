MODULE_NAME='mLGDisplayWOL'(DEV vdvControl, DEV vdvWOL, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	LG Screen Control Module to handle disabling of Ethernet port on Standby
******************************************************************************/
DEFINE_TYPE STRUCTURE uLGDisplayWOL{
	INTEGER 	DISABLED			// Is module Disabled
	INTEGER 	ID					// Device ID
	INTEGER 	CONN_STATE		// Current Connection State
	INTEGER 	IP_PORT			// Current IP Port
	CHAR 		IP_HOST[255]	// Current IP Host
	CHAR 		MAC_ADD[255]	// Current IP Host
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
	INTEGER	AUDMUTE			// Current Audio Mute State
	INTEGER	VIDMUTE			// Current Video Mute State
	// Meta
	CHAR		META_SN[20]		// Serial Number of Unit
}

DEFINE_CONSTANT
	(** Timeline IDs **)
LONG TLID_POLL 			= 1
LONG TLID_TIMEOUT			= 2
LONG TLID_COMMS 			= 3
LONG TLID_VOL				= 4
LONG TLID_BOOT				= 5
LONG TLID_POWERED_OFF	= 6
	(**  **)
LONG TLT_POLL[]        = {10000}
LONG TLT_TIMEOUT[]     = { 2500}
LONG TLT_COMMS[]       = {90000}
LONG TLT_VOL[]         = {  250}
LONG TLT_BOOT[]        = { 5000}
LONG TLT_POWERED_OFF[] = { 86400000 }	// 1 Day

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

DEFINE_VARIABLE
VOLATILE uLGDisplayWOL myLGDisplayWOL

/******************************************************************************
	System Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice,myLGDisplayWOL.Rx
}
/******************************************************************************
	Communication Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bDebugType, CHAR Msg[], CHAR MsgData[]){
	IF(myLGDisplayWOL.DEBUG >= bDebugType)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myLGDisplayWOL.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'LG Display Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'LG Display ',myLGDisplayWOL.IP_HOST,':',ITOA(myLGDisplayWOL.IP_PORT)")
		myLGDisplayWOL.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(ipDevice.port, myLGDisplayWOL.IP_HOST, myLGDisplayWOL.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD_1,CHAR pCMD_2,CHAR pPARAM[]){
	IF(myLGDisplayWOL.ID == 0){myLGDisplayWOL.ID = 01}
	myLGDisplayWOL.Tx = "myLGDisplayWOL.Tx,pCMD_1,pCMD_2,' ',fnPadLeadingChars(ITOA(myLGDisplayWOL.ID),'0',2),' ',pPARAM,$0D"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
   IF(myLGDisplayWOL.CONN_STATE == CONN_STATE_CONNECTED && !myLGDisplayWOL.PEND && FIND_STRING(myLGDisplayWOL.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[200]
		toSend = REMOVE_STRING(myLGDisplayWOL.Tx,"$0D",1)
		fnDebug(DEBUG_STD,'->LG',toSend)
		SEND_STRING ipDevice,toSend
		myLGDisplayWOL.PEND = TRUE
		myLGDisplayWOL.LAST_SENT = LEFT_STRING(toSend,2)
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnInitPoll()
	}
	ELSE IF(myLGDisplayWOL.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myLGDisplayWOL.Tx = ''
	myLGDisplayWOL.PEND = FALSE
	IF(myLGDisplayWOL.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}
/******************************************************************************
	Boot and Poll Delays
******************************************************************************/
DEFINE_FUNCTION fnSetPoweredOff(INTEGER pSTATE){
	IF(TIMELINE_ACTIVE(TLID_POWERED_OFF)){TIMELINE_KILL(TLID_POWERED_OFF)}
	SWITCH(pSTATE){
		CASE TRUE:{
			TIMELINE_CREATE(TLID_POWERED_OFF,TLT_POWERED_OFF,LENGTH_ARRAY(TLT_POWERED_OFF),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myLGDisplayWOL.DISABLED){
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,LG'
		SEND_STRING vdvControl,'PROPERTY-META,MODEL,Unknown'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2|HDMI3|DPORT|DVI|PC'
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(!myLGDisplayWOL.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
		TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('k','a','FF')	// Power Query
	IF(!LENGTH_ARRAY(myLGDisplayWOL.META_SN)){
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

	IF(pID == myLGDisplayWOL.ID){
		SWITCH(myLGDisplayWOL.LAST_SENT){
			CASE 'ka':{	// POWER
				myLGDisplayWOL.POWER = ATOI(pDATA)
				SWITCH(myLGDisplayWOL.POWER){
					CASE FALSE:{
						myLGDisplayWOL.AUDMUTE = FALSE
					}
					CASE TRUE:{
						fnSetPoweredOff(FALSE)
						WAIT 50{
							fnAddToQueue('x','b','FF')
							fnAddToQueue('k','e','FF')
							fnAddToQueue('k','d','FF')
						}
					}
				}
			}
			CASE 'ke':{	// AUDMUTE
				myLGDisplayWOL.AUDMUTE = !ATOI(pDATA)
				fnAddToQueue('k','f','FF')
			}
			CASE 'kf':{	// VOLUME
				myLGDisplayWOL.VOL = HEXTOI(pDATA)
			}
			CASE 'fy':{	// Serial#
				IF(myLGDisplayWOL.META_SN != pDATA){
					myLGDisplayWOL.META_SN = pDATA
					SEND_STRING vdvControl,"'PROPERTY-META,SN,',myLGDisplayWOL.META_SN"
				}
			}
			CASE 'xb':{	// Input
				myLGDisplayWOL.INPUT = pDATA
				IF(LENGTH_ARRAY(myLGDisplayWOL.DES_INPUT)){
					fnAddToQueue('x','b',myLGDisplayWOL.DES_INPUT)
					myLGDisplayWOL.DES_INPUT = ''
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
		myLGDisplayWOL.PEND = FALSE
		myLGDisplayWOL.LAST_SENT = ''
		fnSendFromQueue()
	}
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		IF(!myLGDisplayWOL.DISABLED){
			myLGDisplayWOL.CONN_STATE = CONN_STATE_CONNECTED
			fnSendFromQueue()
		}
	}
	OFFLINE:{
		IF(!myLGDisplayWOL.DISABLED){
			myLGDisplayWOL.CONN_STATE 	= CONN_STATE_OFFLINE;
			myLGDisplayWOL.Tx 			= ''
		}
	}
	ONERROR:{
		IF(!myLGDisplayWOL.DISABLED){
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
					myLGDisplayWOL.CONN_STATE 	= CONN_STATE_OFFLINE
					myLGDisplayWOL.Tx 			= ''
				}
			}
			fnDebug(DEBUG_ERR,"'LG Display Error:[',myLGDisplayWOL.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myLGDisplayWOL.DISABLED){
			fnDebug(DEBUG_DEV,'->RAW',DATA.TEXT)
			WHILE(FIND_STRING(myLGDisplayWOL.Rx,'x',1) || FIND_STRING(myLGDisplayWOL.Rx,"$0D,$0D,$0A",1)){
				IF(FIND_STRING(myLGDisplayWOL.Rx,'x',1)){
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGDisplayWOL.Rx,'x',1),1))
				}
				ELSE{
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGDisplayWOL.Rx,"$0D,$0D,$0A",1),3))
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
							CASE 'LG_WOL':
							CASE 'TRUE':myLGDisplayWOL.DISABLED = FALSE
							DEFAULT:		myLGDisplayWOL.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myLGDisplayWOL.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							fnSetPoweredOff(TRUE)
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myLGDisplayWOL.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myLGDisplayWOL.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myLGDisplayWOL.IP_HOST = DATA.TEXT
								myLGDisplayWOL.IP_PORT = 9761
							}
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						CASE 'MAC':{
							myLGDisplayWOL.MAC_ADD = DATA.TEXT
						}
						CASE 'DEBUG': {
							SWITCH(DATA.TEXT){
								CASE 'TRUE':	myLGDisplayWOL.DEBUG = DEBUG_STD
								CASE 'DEV':		myLGDisplayWOL.DEBUG = DEBUG_DEV
								DEFAULT:			myLGDisplayWOL.DEBUG = DEBUG_ERR
							}
						}
						CASE 'ID':		myLGDisplayWOL.ID = ATOI(DATA.TEXT)
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplayWOL.POWER = TRUE
						CASE 'OFF':		myLGDisplayWOL.POWER = FALSE
						CASE 'TOGGLE':	myLGDisplayWOL.POWER = !myLGDisplayWOL.POWER
					}
					SWITCH(myLGDisplayWOL.POWER){
						CASE TRUE:{
							//fnAddToQueue('k','a','01')
							SEND_COMMAND vdvWOL,"'WOL-ASCII,',myLGDisplayWOL.MAC_ADD"
							fnDebug(DEBUG_DEV,'Power Control:','POWER-ON-via-WOL')
						}
						CASE FALSE:{
							fnAddToQueue('k','a','00')
							myLGDisplayWOL.AUDMUTE = FALSE
							fnDebug(DEBUG_DEV,'Power Control:','POWER-OFF')
						}
					}
					fnSetPoweredOff(myLGDisplayWOL.POWER)
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
					SWITCH(myLGDisplayWOL.POWER){
						CASE TRUE:	fnAddToQueue('x','b',pInputCode)
						CASE FALSE:{
							fnAddToQueue('k','a','01')
							myLGDisplayWOL.DES_INPUT = pInputCode
						}
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplayWOL.AUDMUTE = TRUE
						CASE 'OFF':		myLGDisplayWOL.AUDMUTE = FALSE
						CASE 'TOGGLE':	myLGDisplayWOL.AUDMUTE = !myLGDisplayWOL.AUDMUTE
					}
					IF(myLGDisplayWOL.POWER){
						SWITCH(myLGDisplayWOL.AUDMUTE){
							CASE TRUE:	fnAddToQueue('k','e','00')
							CASE FALSE: fnAddToQueue('k','e','01')
						}
					}
				}
				CASE 'VIDMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myLGDisplayWOL.VIDMUTE = TRUE
						CASE 'OFF':		myLGDisplayWOL.VIDMUTE = FALSE
						CASE 'TOGGLE':	myLGDisplayWOL.VIDMUTE = !myLGDisplayWOL.VIDMUTE
					}
					IF(myLGDisplayWOL.POWER){
						SWITCH(myLGDisplayWOL.VIDMUTE){
							CASE TRUE:	fnAddToQueue('k','d','00')
							CASE FALSE: fnAddToQueue('k','d','01')
						}
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':{
							IF(myLGDisplayWOL.VOL <= 98){
								fnAddToQueue('k','f',ITOHEX(myLGDisplayWOL.VOL+2))
							}
							ELSE{
								fnAddToQueue('k','f',ITOHEX(100))
							}
						}
						CASE 'DEC':{
							IF(myLGDisplayWOL.VOL >= 2){
								fnAddToQueue('k','f',ITOHEX(myLGDisplayWOL.VOL-2))
							}
							ELSE{
								fnAddToQueue('k','f',ITOHEX(0))
							}
						}
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								myLGDisplayWOL.VOL = ATOI(DATA.TEXT)
								fnAddToQueue('k','f',ITOHEX(myLGDisplayWOL.VOL))
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myLGDisplayWOL.LAST_VOL = ATOI(DATA.TEXT)
								myLGDisplayWOL.VOL_PEND = TRUE
							}
						}
					}
					//myLGDisplayWOL.MUTE = FALSE
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
					IF(myLGDisplayWOL.POWER){
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
	IF(!myLGDisplayWOL.DISABLED){
		[vdvControl,198] = (myLGDisplayWOL.VIDMUTE)
		[vdvControl,199] = (myLGDisplayWOL.AUDMUTE)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS) || TIMELINE_ACTIVE(TLID_POWERED_OFF))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS) || TIMELINE_ACTIVE(TLID_POWERED_OFF))
		[vdvControl,255] = (myLGDisplayWOL.POWER)
		SEND_LEVEL vdvControl,1,myLGDisplayWOL.VOL
	}
}
/******************************************************************************
	EoF
******************************************************************************/
