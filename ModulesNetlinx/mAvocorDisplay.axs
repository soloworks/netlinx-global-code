MODULE_NAME='mAvocorDisplay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
Samsung Screen Module
Note: Defaults to ID 1, set to ID 254 for broadcast control with no FB

******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	INTEGER 	DISABLED
	CHAR 	   Tx[1000]
	CHAR 	   Rx[1000]
	INTEGER	PEND
	INTEGER  DEBUG
	INTEGER  ID
	INTEGER	isIP
	INTEGER 	CONN_STATE
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[255]
}
DEFINE_TYPE STRUCTURE uDisplay{

	uComms	COMMS

	INTEGER  POWER
	INTEGER  ECOMODE
	INTEGER  SOURCE
	CHAR 		SOURCE_NAME[40]
	INTEGER  desSOURCE
	INTEGER  LOCKED
	INTEGER  OSD
	INTEGER 	VOL
	INTEGER  MUTE

	INTEGER	VOL_PEND
	INTEGER	LAST_VOL

	INTEGER	HDMI_AUD_NATIVE[2]
	INTEGER	HDMI_AUD_EXT[2]

	CHAR 		META_SN[14]
	CHAR		META_MODEL[50]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_INPUT 	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 3
LONG TLID_VOL		= 4
LONG TLID_TIMEOUT	= 5
LONG TLID_BOOT		= 6

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

//HEX COMMANDS
INTEGER STX   = $07
INTEGER IDT   = $01
INTEGER GET   = $01
INTEGER SET   = $02
INTEGER ETX   = $08
INTEGER CR    = $0D
CHAR POWER[]  = { $50, $4F, $57 }
CHAR INPUT[]  = { $4D, $49, $4E }
CHAR SERIAL[] = { $53, $45, $52 }
CHAR MODEL[]  = { $4D, $4E, $41 }
CHAR VOLUME[] = { $56, $4F, $4C }
CHAR MUTE[]   = { $4D, $55, $54 }
CHAR REMOTE[] = { $52, $43, $55 }
CHAR ECOMODE[]= { $57, $46, $53 }

DEFINE_VARIABLE
VOLATILE uDisplay myAvocorDisplay
LONG TLT_POLL[]		= { 30000}
LONG TLT_COMMS[]		= { 90000}
LONG TLT_INPUT[]		= { 2000,12000}
LONG TLT_VOL[]			= {  150}
LONG TLT_TIMEOUT[]	= { 1500}
LONG TLT_BOOT[]		= { 5000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	myAvocorDisplay.COMMS.ID = IDT
	myAvocorDisplay.COMMS.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myAvocorDisplay.COMMS.Rx
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myAvocorDisplay.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Samsung Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'Avocor ',myAvocorDisplay.COMMS.IP_HOST,':',ITOA(myAvocorDisplay.COMMS.IP_PORT)")
		myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myAvocorDisplay.COMMS.IP_HOST, myAvocorDisplay.COMMS.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}


DEFINE_FUNCTION fnAddToQueue(INTEGER pTYPE, CHAR pCMD[], CHAR pDATA[]){

	STACK_VAR CHAR myMessage[25]

	myMessage = "STX,myAvocorDisplay.COMMS.ID,pTYPE,pCMD,pDATA,ETX"

	myAvocorDisplay.COMMS.Tx = "myAvocorDisplay.COMMS.Tx,myMessage,$AA,$BB,$CC,$DD"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myAvocorDisplay.COMMS.PEND && myAvocorDisplay.COMMS.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myAvocorDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(myAvocorDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1),4)
		SEND_STRING dvDevice,"toSend,CR"
		fnDebugHex(DEBUG_STD,'-> Avocor ',toSend)
		myAvocorDisplay.COMMS.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(myAvocorDisplay.COMMS.isIP && myAvocorDisplay.COMMS.CONN_STATE == CONN_STATE_OFFLINE && FIND_STRING(myAvocorDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myAvocorDisplay.COMMS.PEND = FALSE
	myAvocorDisplay.COMMS.Tx = ''
	IF(myAvocorDisplay.COMMS.isIP && myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myAvocorDisplay.COMMS.DISABLED){
		IF(!myAvocorDisplay.COMMS.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		}
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Samsung'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2|DPORT|DVI|PC'
		SEND_STRING vdvControl,'RANGE-0,100'
		fnInit()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myAvocorDisplay.COMMS.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnDebugHex(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myAvocorDisplay.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR pHEX[1000]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
			pHEX = "pHEX,'$',fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2)"
		}
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', pHEX"
	}
}

/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(!myAvocorDisplay.COMMS.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	IF(myAvocorDisplay.COMMS.ID != $FE){ fnPoll() }
}
DEFINE_FUNCTION fnInit(){
	IF(myAvocorDisplay.COMMS.ID != $FE){
		fnAddToQueue(SET,ECOMODE,"$01")
	}
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue(GET,POWER,"")
}

/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myAvocorDisplay.COMMS.DISABLED){
			IF(myAvocorDisplay.COMMS.isIP){
				myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(myAvocorDisplay.COMMS.isIP && !myAvocorDisplay.COMMS.DISABLED){
			myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_OFFLINE
		}
	}
	ONERROR:{
		IF(myAvocorDisplay.COMMS.isIP && !myAvocorDisplay.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myAvocorDisplay.COMMS.CONN_STATE = CONN_STATE_OFFLINE
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
			fnDebug(TRUE,"'Samsung IP Error:[',myAvocorDisplay.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myAvocorDisplay.COMMS.DISABLED){
			fnDebugHex(DEBUG_DEV,'Avocor RAW -> ', DATA.TEXT)
			IF(LENGTH_ARRAY(myAvocorDisplay.COMMS.Rx)){
				// Clean off possible Garbage until STX Found
				WHILE(FIND_STRING(myAvocorDisplay.COMMS.Rx,"STX",1) && myAvocorDisplay.COMMS.Rx[1] != STX){
					fnDebug(DEBUG_DEV,'WHILE 1', "'EAT GARBAGE:',ITOHEX(GET_BUFFER_CHAR(myAvocorDisplay.COMMS.Rx))")
				}
				// While there is enough data in the buffer to be a command
				WHILE(LENGTH_ARRAY(myAvocorDisplay.COMMS.Rx)){
					STACK_VAR INTEGER pDataLength
					STACK_VAR CHAR pRX[255]
					pDataLength = LENGTH_ARRAY(myAvocorDisplay.COMMS.Rx)
					fnDebug(DEBUG_DEV,'DATA.TEXT|WHILE', "'pDataLength = ',ITOA(pDataLength)")

					IF(myAvocorDisplay.COMMS.Rx[1] == STX){
						SELECT{
							ACTIVE(FIND_STRING(myAvocorDisplay.COMMS.Rx,"CR",1)):{
								pRX = REMOVE_STRING(myAvocorDisplay.COMMS.Rx,"CR",1)
								fnDebugHex(DEBUG_DEV,'Rx: CR found. COMMS.Rx = ',pRX)
								fnStripCharsRight(pRX,1)
								IF(pRX[LENGTH_ARRAY(pRX)] == ETX){
									fnProcessFeedback(pRX)
									myAvocorDisplay.COMMS.PEND = FALSE
									fnSendFromQueue()
								}
							}
							ACTIVE(FIND_STRING(myAvocorDisplay.COMMS.Rx,"ETX",1)):{
								pRX = REMOVE_STRING(myAvocorDisplay.COMMS.Rx,"ETX",1)
								fnDebugHex(DEBUG_DEV,'Rx: No CR found. COMMS.Rx = ',pRX)
								fnProcessFeedback(pRX)
								myAvocorDisplay.COMMS.PEND = FALSE
								fnSendFromQueue()
							}
							ACTIVE(1):{
								fnDebug(DEBUG_DEV,'DATA.TEXT', "'More Packet Expected'")
								BREAK
							}
						}
					}
					ELSE{
						fnDebug(DEBUG_DEV,'WHILE 2', "'EAT MORE GARBAGE:',ITOHEX(GET_BUFFER_CHAR(myAvocorDisplay.COMMS.Rx))")
					}
				}
			}
		}
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	STACK_VAR INTEGER pID
	fnDebugHex(DEBUG_STD,'Avocor Fb -> ', pDATA)
	GET_BUFFER_CHAR(pDATA)	// Remove STX
	pID = GET_BUFFER_CHAR(pDATA)// Remove IDT
	pDATA = fnStripCharsRight(pDATA,1)	// Remove ETX
	IF(pID == myAvocorDisplay.COMMS.ID){	// Get ID
		STACK_VAR INTEGER pTYPE
		STACK_VAR CHAR    pCMD[3]
		STACK_VAR INTEGER pVALUE
		pTYPE  = GET_BUFFER_CHAR(pDATA) // Remove Command Type
		pCMD   = REMOVE_STRING(pDATA,LEFT_STRING(pDATA,3),1) // Remove Command
		SWITCH(pCMD){
			CASE ECOMODE:{ // Wake from Sleep Mode Status
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Eco Mode Status = ',pDATA)
				pVALUE = GET_BUFFER_CHAR(pDATA)
				myAvocorDisplay.ECOMODE = pVALUE
				IF(myAvocorDisplay.META_MODEL == ''){
					fnAddToQueue(GET,MODEL,"")
				}
			}
			CASE POWER:{ // Power Status
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Power Status = ',pDATA)
				pVALUE =GET_BUFFER_CHAR(pDATA)
				myAvocorDisplay.POWER = pVALUE
				IF(!myAvocorDisplay.ECOMODE){
					fnInit()
				}
			}
			CASE INPUT:{ // Input Status
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Input Status = ',pDATA)
				pVALUE = GET_BUFFER_CHAR(pDATA)
				IF(myAvocorDisplay.SOURCE != pVALUE){
					myAvocorDisplay.SOURCE  = pVALUE
					myAvocorDisplay.SOURCE_NAME = fnGetSourceName(myAvocorDisplay.SOURCE)
				}
			}
			CASE VOLUME:{	// Volume Status
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Volume Status = ',pDATA)
				myAvocorDisplay.VOL = HEXTOI(pDATA)
			}
			CASE MUTE:{	// Mute Status
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Mute Status = ',pDATA)
				pVALUE = GET_BUFFER_CHAR(pDATA)
				myAvocorDisplay.MUTE = pVALUE
			}
			CASE MODEL:{ // Model Name
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Model Name = ',pDATA)
				IF(myAvocorDisplay.META_MODEL != pDATA){
					myAvocorDisplay.META_MODEL  = pDATA
					SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myAvocorDisplay.META_MODEL"
				}
				fnAddToQueue(GET,SERIAL,"")	// Get Serial Number
			}
			CASE SERIAL:{	// Serial Number
				fnDebugHex(DEBUG_STD,'Avocor Parse -> Serial Number = ',pDATA)
				IF(myAvocorDisplay.META_SN != pDATA){
					myAvocorDisplay.META_SN  = pDATA
					SEND_STRING vdvControl,"'PROPERTY-META,SERIALNO,',myAvocorDisplay.META_SN"
				}
			}
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
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
							CASE 'AVOCOR':
							CASE 'TRUE':myAvocorDisplay.COMMS.DISABLED = FALSE
							DEFAULT:		myAvocorDisplay.COMMS.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myAvocorDisplay.COMMS.DISABLED){
			STACK_VAR CHAR pCMD[3]
			STACK_VAR CHAR pSTRING[12]
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'ALL':{
					SWITCH(DATA.TEXT){
						CASE 'ON': {pSTRING = "STX,IDT,SET,POWER,$01,ETX,CR"}
						CASE 'OFF':{pSTRING = "STX,IDT,SET,POWER,$00,ETX,CR"}
					}
					SEND_STRING dvDevice,pSTRING
				}
				CASE 'ACTION':{
					SWITCH(DATA.TEXT){
						CASE 'INIT':fnInit()
					}
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE':myAvocorDisplay.COMMS.DEBUG = DEBUG_STD
								CASE 'DEV':	myAvocorDisplay.COMMS.DEBUG = DEBUG_DEV
								DEFAULT:		myAvocorDisplay.COMMS.DEBUG = DEBUG_ERR
							}
						}
						CASE 'IP':{
							myAvocorDisplay.COMMS.IP_HOST = DATA.TEXT
							myAvocorDisplay.COMMS.IP_PORT	= 23
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
				CASE 'RAW':{
					fnAddToQueue(HEXTOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),
					             HEXTOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),
									 "HEXTOI(DATA.TEXT)")
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'TOGGLE':{ myAvocorDisplay.POWER = !myAvocorDisplay.POWER }
						CASE 'ON':{  myAvocorDisplay.POWER = TRUE  }
						CASE 'OFF':{ myAvocorDisplay.POWER = FALSE }
					}
					SWITCH(myAvocorDisplay.POWER){
						CASE TRUE:{  fnAddToQueue(SET,POWER,"$01") }
						CASE FALSE:{ fnAddToQueue(SET,POWER,"$00") }
					}
				}
				CASE 'LOCK':{
					pCMD = "$4B,$4C,$43"
					SWITCH(DATA.TEXT){
						CASE 'ON': { fnAddToQueue(SET,pCMD,"$01");myAvocorDisplay.LOCKED = TRUE  }
						CASE 'OFF':{ fnAddToQueue(SET,pCMD,"$00");myAvocorDisplay.LOCKED = FALSE }
					}
				}
				CASE 'OSD':{
					pCMD = "$4F,$53,$54"
					SWITCH(DATA.TEXT){
						CASE 'ON':{  fnAddToQueue(SET,PCMD,"$04");myAvocorDisplay.OSD = TRUE  }
						CASE 'OFF':{ fnAddToQueue(SET,pCMD,"$00");myAvocorDisplay.OSD = FALSE }
					}
				}
				CASE 'INPUT':{
					myAvocorDisplay.desSOURCE = fnGetSourceCode(DATA.TEXT)
					IF(myAvocorDisplay.desSOURCE){
						fnAddToQueue(SET,INPUT,"myAvocorDisplay.desSOURCE")
						IF(TIMELINE_ACTIVE(TLID_INPUT))TIMELINE_KILL(TLID_INPUT)
						TIMELINE_CREATE(TLID_INPUT,TLT_Input,LENGTH_ARRAY(TLT_Input),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
				CASE 'ADJUST':{
					fnAddToQueue(SET,REMOTE,"$1C")
				}
				CASE 'REMOTE':{
					SWITCH(DATA.TEXT){
						CASE 'MENU':	fnAddToQueue(SET,REMOTE,"$00")
						CASE 'INFO':	fnAddToQueue(SET,REMOTE,"$01")
						CASE 'CUR_UP':	fnAddToQueue(SET,REMOTE,"$02")
						CASE 'CUR_DN':	fnAddToQueue(SET,REMOTE,"$03")
						CASE 'CUR_LT':	fnAddToQueue(SET,REMOTE,"$04")
						CASE 'CUR_RT':	fnAddToQueue(SET,REMOTE,"$05")
						CASE 'ENTER':	fnAddToQueue(SET,REMOTE,"$06")
						CASE 'EXIT':	fnAddToQueue(SET,REMOTE,"$07")
						CASE 'RETURN': fnAddToQueue(SET,REMOTE,"$08")
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	myAvocorDisplay.MUTE = 1
						CASE 'OFF':	myAvocorDisplay.MUTE = 0
						CASE 'TOGGLE':myAvocorDisplay.MUTE = !myAvocorDisplay.MUTE
					}
					fnAddToQueue(SET,MUTE,"myAvocorDisplay.MUTE")
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':fnAddToQueue(SET,REMOTE,"$1D")
						CASE 'DEC':fnAddToQueue(SET,REMOTE,"$1E")
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								fnAddToQueue(SET,VOLUME,"ATOI(DATA.TEXT)")
								myAvocorDisplay.VOL = ATOI(DATA.TEXT)
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myAvocorDisplay.LAST_VOL = ATOI(DATA.TEXT)
								myAvocorDisplay.VOL_PEND = TRUE
							}
						}
					}
					myAvocorDisplay.MUTE = FALSE
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myAvocorDisplay.VOL_PEND){
		fnAddToQueue(SET,VOLUME,"myAvocorDisplay.LAST_VOL")
		myAvocorDisplay.VOL = myAvocorDisplay.LAST_VOL
		myAvocorDisplay.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_INPUT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1:{ fnAddToQueue(SET,POWER,"$01");myAvocorDisplay.POWER = TRUE }
		CASE 2:{ fnAddToQueue(SET,INPUT,"myAvocorDisplay.desSOURCE") }
	}
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION CHAR[255] fnGetSourceName(INTEGER pINPUT){
	SWITCH(pINPUT){
		CASE $00: RETURN 'VGA'
		CASE $09: RETURN 'HDMI1'
		CASE $0A: RETURN 'HDMI2'
		CASE $0B: RETURN 'HDMI3'
		CASE $0C: RETURN 'HDMI4'
		CASE $0D: RETURN 'DPORT'
		CASE $0E: RETURN 'IPC/OPS'
		CASE $13: RETURN 'WPS'
	}
}
DEFINE_FUNCTION INTEGER fnGetSourceCode(CHAR pINPUT[255]){
	SWITCH(pINPUT){
		CASE 'VGA':				RETURN $00
		CASE 'HDMI1': 			RETURN $09
		CASE 'HDMI2': 			RETURN $0A
		CASE 'HDMI3': 			RETURN $0B
		CASE 'HDMI4': 			RETURN $0C
		CASE 'DPORT': 			RETURN $0D
		CASE 'IPC/OPS':
		CASE 'IPC':
		CASE 'OPS': 			RETURN $0E
		CASE 'WPC':          RETURN $13
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!myAvocorDisplay.COMMS.DISABLED){
		SEND_LEVEL vdvControl,1,myAvocorDisplay.VOL
		[vdvControl,199] = (myAvocorDisplay.MUTE)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,255] = (myAvocorDisplay.POWER)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
