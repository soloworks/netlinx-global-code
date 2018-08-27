MODULE_NAME='mLGVideoWall'(DEV vdvDisplay[], DEV dvLink)
INCLUDE 'CustomFunctions'
/******************************************************************************
	LG Screen Control Module
	With Basic Volume Control
******************************************************************************/
DEFINE_TYPE STRUCTURE uLGDisplay{
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

DEFINE_TYPE STRUCTURE uLGVideoWall{
	INTEGER	  isIP				// Is IP controlled
	INTEGER 	  CONN_STATE		// Current Connection State
	INTEGER 	  IP_PORT			// Current IP Port
	CHAR 		  IP_HOST[255]		// Current IP Host
	INTEGER	  DEBUG				// Current Debug Level
	CHAR		  Tx_Poll[1000]	// Current Tx Queue
	CHAR		  Tx_Cmd[1000]		// Current Tx Queue
	CHAR		  Rx[1000]			// Current Rx Queue
	CHAR		  LAST_SENT[2]		// Last send command (for Polling reference)
	INTEGER	  PEND				// True if command is pending
	
	uLGDisplay DISPLAY[16]	
}

DEFINE_CONSTANT
	(** Timeline IDs **)
LONG TLID_POLL 		= 1
LONG TLID_TIMEOUT		= 2
LONG TLID_BOOT			= 4

LONG TLID_COMMS_00	= 100
LONG TLID_COMMS_01	= 101
LONG TLID_COMMS_02	= 102
LONG TLID_COMMS_03	= 103
LONG TLID_COMMS_04	= 104
LONG TLID_COMMS_05	= 105
LONG TLID_COMMS_06	= 106
LONG TLID_COMMS_07	= 107
LONG TLID_COMMS_08	= 108
LONG TLID_COMMS_09	= 109
LONG TLID_COMMS_10	= 110
LONG TLID_COMMS_11	= 111
LONG TLID_COMMS_12	= 112
LONG TLID_COMMS_13	= 113
LONG TLID_COMMS_14	= 114
LONG TLID_COMMS_15	= 115
LONG TLID_COMMS_16	= 116

LONG TLID_VOL_00		= 200
LONG TLID_VOL_01		= 201
LONG TLID_VOL_02		= 202
LONG TLID_VOL_03		= 203
LONG TLID_VOL_04		= 204
LONG TLID_VOL_05		= 205
LONG TLID_VOL_06		= 206
LONG TLID_VOL_07		= 207
LONG TLID_VOL_08		= 208
LONG TLID_VOL_09		= 209
LONG TLID_VOL_10		= 210
LONG TLID_VOL_11		= 211
LONG TLID_VOL_12		= 212
LONG TLID_VOL_13		= 213
LONG TLID_VOL_14		= 214
LONG TLID_VOL_15		= 215
LONG TLID_VOL_16		= 216
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

CHAR QUERY_VAL[] = 'FF'

DEFINE_VARIABLE
VOLATILE uLGVideoWall myLGVideoWall

/******************************************************************************
	System Startup Code
******************************************************************************/
DEFINE_START{
	myLGVideoWall.isIP = !(dvLink.NUMBER)
	CREATE_BUFFER dvLink,myLGVideoWall.Rx
}
/******************************************************************************
	Communication Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bDebugType, CHAR Msg[], CHAR MsgData[]){
	IF(myLGVideoWall.DEBUG >= bDebugType)	{
		SEND_STRING 0:1:0, "ITOA(vdvDisplay[1].Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myLGVideoWall.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'LG Display Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'LG Display ',myLGVideoWall.IP_HOST,':',ITOA(myLGVideoWall.IP_PORT)")
		myLGVideoWall.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvLink.port, myLGVideoWall.IP_HOST, myLGVideoWall.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvLink.port)
}

DEFINE_FUNCTION fnAddToQueue(INTEGER pID,CHAR pCMD_1,CHAR pCMD_2,CHAR pPARAM[]){
	SWITCH(pPARAM){
		CASE QUERY_VAL:myLGVideoWall.Tx_Poll = "myLGVideoWall.Tx_Poll,pCMD_1,pCMD_2,' ',fnPadLeadingChars(ITOA(pID),'0',2),' ',pPARAM,$0D"
		DEFAULT:			myLGVideoWall.Tx_Cmd  = "myLGVideoWall.Tx_Cmd,pCMD_1,pCMD_2,' ',fnPadLeadingChars(ITOA(pID),'0',2),' ',pPARAM,$0D"
	}
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
   IF(myLGVideoWall.CONN_STATE == CONN_STATE_CONNECTED && !myLGVideoWall.PEND && (FIND_STRING(myLGVideoWall.Tx_Poll,"$0D",1) || FIND_STRING(myLGVideoWall.Tx_Cmd,"$0D",1))){
		STACK_VAR CHAR toSend[200]
		IF(FIND_STRING(myLGVideoWall.Tx_Cmd,"$0D",1)){
			toSend = REMOVE_STRING(myLGVideoWall.Tx_Cmd,"$0D",1)
		}
		ELSE{
			toSend = REMOVE_STRING(myLGVideoWall.Tx_Poll,"$0D",1)
		}
		fnDebug(DEBUG_STD,'->LG',toSend)
		SEND_STRING dvLink,toSend
		myLGVideoWall.PEND = TRUE
		myLGVideoWall.LAST_SENT = LEFT_STRING(toSend,2)
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnInitPoll()
	}
	ELSE IF(myLGVideoWall.isIP && myLGVideoWall.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myLGVideoWall.Tx_Poll = ''
	myLGVideoWall.Tx_Cmd  = ''
	myLGVideoWall.PEND    = FALSE
	IF(myLGVideoWall.isIP){
		fnCloseTCPConnection()
	}
}
/******************************************************************************
	Boot and Poll Delays
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myLGVideoWall.isIP){
		SEND_COMMAND dvLink, 'SET MODE DATA'
		SEND_COMMAND dvLink, "'SET BAUD 9600 N 8 1 485 DISABLE'"
		myLGVideoWall.CONN_STATE = CONN_STATE_CONNECTED
	}
	fnPoll()
	fnInitPoll()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR INTEGER d
	FOR(d = 1; d <= LENGTH_ARRAY(vdvDisplay); d++){
		fnAddToQueue(d,'k','a',QUERY_VAL)	// Power Query
		IF(!LENGTH_ARRAY(myLGVideoWall.DISPLAY[d].META_SN)){
			//fnAddToQueue('f','y','FF')	// Serial#
		}
	}
}
/******************************************************************************
	Boot and Poll Delays
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER pID
	STACK_VAR CHAR pCMD[1]
	STACK_VAR CHAR pACK[2]

	pCMD = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
	pID  = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
	pACK = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

	fnDebug(DEBUG_STD,'LG->',"ITOA(pID),'-',pCMD,'-',pACK,'-',pDATA")

	SWITCH(myLGVideoWall.LAST_SENT){
		CASE 'ka':{	// POWER
			myLGVideoWall.DISPLAY[pID].POWER = ATOI(pDATA)
			SWITCH(myLGVideoWall.DISPLAY[pID].POWER){
				CASE FALSE:{
					myLGVideoWall.DISPLAY[pID].MUTE = FALSE
				}
				CASE TRUE:{
					fnAddToQueue(pID,'x','b',QUERY_VAL)
					fnAddToQueue(pID,'k','e',QUERY_VAL)
					fnAddToQueue(pID,'k','d',QUERY_VAL)
				}
			}
		}
		CASE 'ke':{	// MUTE
			myLGVideoWall.DISPLAY[pID].MUTE = !ATOI(pDATA)
			fnAddToQueue(pID,'k','f',QUERY_VAL)
		}
		CASE 'kf':{	// VOLUME
			myLGVideoWall.DISPLAY[pID].VOL = HEXTOI(pDATA)
		}
		CASE 'fy':{	// Serial#
			IF(myLGVideoWall.DISPLAY[pID].META_SN != pDATA){
				myLGVideoWall.DISPLAY[pID].META_SN = pDATA
				SEND_STRING vdvDisplay,"'PROPERTY-META,SN,',myLGVideoWall.DISPLAY[pID].META_SN"
			}
		}
		CASE 'xb':{	// Input
			myLGVideoWall.DISPLAY[pID].INPUT = pDATA
			IF(LENGTH_ARRAY(myLGVideoWall.DISPLAY[pID].DES_INPUT)){
				fnAddToQueue(pID,'x','b',myLGVideoWall.DISPLAY[pID].DES_INPUT)
				myLGVideoWall.DISPLAY[pID].DES_INPUT = ''
			}
		}
		CASE 'mc':{
			SWITCH(pDATA){
				CASE 'ea':{
					fnAddToQueue(pID,'x','b',QUERY_VAL)
					fnAddToQueue(pID,'k','e',QUERY_VAL)
				}
			}
		}
	}
	myLGVideoWall.PEND = FALSE
	myLGVideoWall.LAST_SENT = ''
	fnSendFromQueue()
	RETURN pID
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvLink]{
	ONLINE:{
		IF(myLGVideoWall.isIP){
			myLGVideoWall.CONN_STATE = CONN_STATE_CONNECTED
			fnSendFromQueue()
		}
		ELSE{
			TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	OFFLINE:{
		IF(myLGVideoWall.isIP){
			myLGVideoWall.CONN_STATE 	= CONN_STATE_OFFLINE
			myLGVideoWall.Tx_Poll 		= ''
			myLGVideoWall.Tx_Cmd 		= ''
		}
	}
	ONERROR:{
		IF(myLGVideoWall.isIP){
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
					myLGVideoWall.CONN_STATE 	= CONN_STATE_OFFLINE
					myLGVideoWall.Tx_Poll 		= ''
					myLGVideoWall.Tx_Cmd 		= ''
				}
			}
			fnDebug(DEBUG_ERR,"'LG Display Error:[',myLGVideoWall.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_DEV,'->RAW',DATA.TEXT)
		WHILE(FIND_STRING(myLGVideoWall.Rx,'x',1) || FIND_STRING(myLGVideoWall.Rx,"$0D,$0D,$0A",1)){
			
			STACK_VAR INTEGER pID
			
			IF(FIND_STRING(myLGVideoWall.Rx,'x',1)){
				pID = fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGVideoWall.Rx,'x',1),1))
			}
			ELSE{
				pID = fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLGVideoWall.Rx,"$0D,$0D,$0A",1),3))
			}

			IF(TIMELINE_ACTIVE(TLID_COMMS_00+pID)){ TIMELINE_KILL(TLID_COMMS_00+pID) }
			TIMELINE_CREATE(TLID_COMMS_00+pID,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvDisplay]{
	COMMAND:{
		STACK_VAR INTEGER pID
		pID = GET_LAST(vdvDisplay)

		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myLGVideoWall.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myLGVideoWall.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myLGVideoWall.IP_HOST = DATA.TEXT
							myLGVideoWall.IP_PORT = 9761
						}
						IF(myLGVideoWall.isIP){
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
					CASE 'DEBUG': {
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	myLGVideoWall.DEBUG = DEBUG_STD
							CASE 'DEV':		myLGVideoWall.DEBUG = DEBUG_DEV
							DEFAULT:			myLGVideoWall.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myLGVideoWall.DISPLAY[pID].POWER = TRUE
					CASE 'OFF':		myLGVideoWall.DISPLAY[pID].POWER = FALSE
					CASE 'TOGGLE':	myLGVideoWall.DISPLAY[pID].POWER = !myLGVideoWall.DISPLAY[pID].POWER
				}
				SWITCH(myLGVideoWall.DISPLAY[pID].POWER){
					CASE TRUE:	fnAddToQueue(pID,'k','a','01')
					CASE FALSE:{
						fnAddToQueue(pID,'k','a','00')
						myLGVideoWall.DISPLAY[pID].MUTE = FALSE
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
				SWITCH(myLGVideoWall.DISPLAY[pID].POWER){
					CASE TRUE:{
						IF(myLGVideoWall.DISPLAY[pID].INPUT != pInputCode){
							fnAddToQueue(pID,'x','b',pInputCode)
						}
					}
					CASE FALSE:{
						fnAddToQueue(pID,'k','a','01')
						myLGVideoWall.DISPLAY[pID].DES_INPUT = pInputCode
					}
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myLGVideoWall.DISPLAY[pID].MUTE = TRUE
					CASE 'OFF':		myLGVideoWall.DISPLAY[pID].MUTE = FALSE
					CASE 'TOGGLE':	myLGVideoWall.DISPLAY[pID].MUTE = !myLGVideoWall.DISPLAY[pID].MUTE
				}
				IF(myLGVideoWall.DISPLAY[pID].POWER){
					SWITCH(myLGVideoWall.DISPLAY[pID].MUTE){
						CASE TRUE:	fnAddToQueue(pID,'k','e','00')
						CASE FALSE: fnAddToQueue(pID,'k','e','01')
					}
				}
			}
			CASE 'VIDMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myLGVideoWall.DISPLAY[pID].VIDMUTE = TRUE
					CASE 'OFF':		myLGVideoWall.DISPLAY[pID].VIDMUTE = FALSE
					CASE 'TOGGLE':	myLGVideoWall.DISPLAY[pID].VIDMUTE = !myLGVideoWall.DISPLAY[pID].VIDMUTE
				}
				IF(myLGVideoWall.DISPLAY[pID].POWER){
					SWITCH(myLGVideoWall.DISPLAY[pID].VIDMUTE){
						CASE TRUE:	fnAddToQueue(pID,'k','d','00')
						CASE FALSE: fnAddToQueue(pID,'k','d','01')
					}
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':{
						IF(myLGVideoWall.DISPLAY[pID].VOL <= 98){
							fnAddToQueue(pID,'k','f',ITOHEX(myLGVideoWall.DISPLAY[pID].VOL+2))
						}
						ELSE{
							fnAddToQueue(pID,'k','f',ITOHEX(100))
						}
					}
					CASE 'DEC':{
						IF(myLGVideoWall.DISPLAY[pID].VOL >= 2){
							fnAddToQueue(pID,'k','f',ITOHEX(myLGVideoWall.DISPLAY[pID].VOL-2))
						}
						ELSE{
							fnAddToQueue(pID,'k','f',ITOHEX(0))
						}
					}
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_VOL_00+pID)){
							myLGVideoWall.DISPLAY[pID].VOL = ATOI(DATA.TEXT)
							fnAddToQueue(pID,'k','f',ITOHEX(myLGVideoWall.DISPLAY[pID].VOL))
							TIMELINE_CREATE(TLID_VOL_00+pID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myLGVideoWall.DISPLAY[pID].LAST_VOL = ATOI(DATA.TEXT)
							myLGVideoWall.DISPLAY[pID].VOL_PEND = TRUE
						}
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
	STACK_VAR INTEGER d
	FOR(d = 1; d <= LENGTH_ARRAY(vdvDisplay); d++){
		[vdvDisplay[d],199] = (myLGVideoWall.DISPLAY[d].MUTE)
		[vdvDisplay[d],251] = (TIMELINE_ACTIVE(TLID_COMMS_00+d))
		[vdvDisplay[d],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+d))
		[vdvDisplay[d],255] = (myLGVideoWall.DISPLAY[d].POWER)
		SEND_LEVEL vdvDisplay[d],1,myLGVideoWall.DISPLAY[d].VOL
	}
}
/******************************************************************************
	EoF
******************************************************************************/