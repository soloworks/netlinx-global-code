MODULE_NAME='mHitachiProjector'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hitachi Projector Module
	Set to use 19200 Baud by default
******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	INTEGER 	DISABLED
	CHAR 	   Tx[1000]
	CHAR 	   Rx[1000]
	CHAR		PEND_CMD[20]
	INTEGER  DEBUG
	INTEGER	isIP
	INTEGER 	CONN_STATE
	INTEGER 	IP_PORT 
	CHAR 		IP_HOST[255]
}
DEFINE_TYPE STRUCTURE uProj{

	uComms	COMMS

	INTEGER  POWER
	INTEGER	FREEZE
	INTEGER 	AVMUTE
	CHAR		curSOURCE[10]
	CHAR		newSOURCE[10]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_INPUT 	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 3
LONG TLID_TIMEOUT	= 4

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR		= 0
INTEGER DEBUG_STD		= 1
INTEGER DEBUG_DEV		= 2

CHAR CMD_PWR[] = {$19,$D3,$02,$00,$00,$60,$00,$00}	// Query Power
CHAR CMD_SRC[] = {$CD,$D2,$02,$00,$00,$20,$00,$00}	// Query Source
CHAR CMD_FRZ[] = {$B0,$D2,$02,$00,$02,$30,$00,$00}	// Query Freeze
CHAR CMD_AVM[] = {$C0,$93,$02,$00,$05,$24,$00,$00}	// Query Shutter (AV Mute)

DEFINE_VARIABLE
VOLATILE uProj myHitachiProj
LONG TLT_POLL[]		= {30000}
LONG TLT_COMMS[]		= {90000}
LONG TLT_TIMEOUT[]	= {10000}
/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_START{
	myHitachiProj.COMMS.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myHitachiProj.COMMS.Rx
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myHitachiProj.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Hitachi Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'Hitachi ',myHitachiProj.COMMS.IP_HOST,':',ITOA(myHitachiProj.COMMS.IP_PORT)")
		myHitachiProj.COMMS.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myHitachiProj.COMMS.IP_HOST, myHitachiProj.COMMS.IP_PORT, IP_TCP) 
	}
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[]){
	
	myHitachiProj.COMMS.Tx = "myHitachiProj.COMMS.Tx, $BE,$EF,$03,$06,$00,pCMD,$AA,$BB,$CC,$DD"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!LENGTH_ARRAY(myHitachiProj.COMMS.PEND_CMD) && myHitachiProj.COMMS.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myHitachiProj.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(myHitachiProj.COMMS.Tx,"$AA,$BB,$CC,$DD",1),4)
		SEND_STRING dvDevice,toSend
		fnDebugHex(DEBUG_STD,'->HIT',toSend)
		myHitachiProj.COMMS.PEND_CMD = toSend
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(myHitachiProj.COMMS.isIP && myHitachiProj.COMMS.CONN_STATE == CONN_STATE_OFFLINE && FIND_STRING(myHitachiProj.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myHitachiProj.COMMS.PEND_CMD = ''
	myHitachiProj.COMMS.Tx = ''
	IF(myHitachiProj.COMMS.isIP && myHitachiProj.COMMS.CONN_STATE = CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myHitachiProj.COMMS.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnDebugHex(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myHitachiProj.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR pHEX[1000]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
			pHEX = "pHEX,'$',fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2)"
		}
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', pHEX"
	}
}
/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(!myHitachiProj.COMMS.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue(CMD_PWR)	// Query Power
	fnAddToQueue(CMD_SRC)	// Query Source
	fnAddToQueue(CMD_FRZ)	// Query Freeze
	fnAddToQueue(CMD_AVM)	// Query Shutter
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myHitachiProj.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		IF(!myHitachiProj.COMMS.isIP){
			WAIT 50{
				IF(!myHitachiProj.COMMS.DISABLED){
					SEND_COMMAND dvDevice, 'SET MODE DATA'
					SEND_COMMAND dvDevice, 'SET BAUD 19200 N 8 1 485 DISABLE'
					fnPoll()
				}
			}
		}
		ELSE{
			fnSendFromQueue()
		}
	}
	OFFLINE:{
		IF(myHitachiProj.COMMS.isIP){
			myHitachiProj.COMMS.CONN_STATE = CONN_STATE_OFFLINE
		}
	}
	ONERROR:{
		IF(myHitachiProj.COMMS.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myHitachiProj.COMMS.CONN_STATE = CONN_STATE_OFFLINE
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
			fnDebug(TRUE,"'Hitachi IP Error:[',myHitachiProj.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myHitachiProj.COMMS.DISABLED){
			fnDebugHex(DEBUG_DEV,'RAW->', DATA.TEXT)
			SWITCH(GET_BUFFER_CHAR(DATA.TEXT)){
				CASE $06:{
					// ACK
					myHitachiProj.COMMS.PEND_CMD = ''
					fnSendFromQueue()
				}
				CASE $15:{
					// NACK
					myHitachiProj.COMMS.PEND_CMD = ''
					fnSendFromQueue()
				}
				CASE $1C:{
					// ERR
					SWITCH(myHitachiProj.COMMS.PEND_CMD){
						CASE CMD_FRZ:{	// FREEZE
							myHitachiProj.FREEZE = FALSE
						}
						CASE CMD_AVM:{	// AVMUTE
							myHitachiProj.AVMUTE = FALSE
						}
					}
					myHitachiProj.COMMS.PEND_CMD = ''
					fnSendFromQueue()
				}
				CASE $1D:{
					// DATA
					SWITCH(myHitachiProj.COMMS.PEND_CMD){
						CASE CMD_PWR:{	// POWER
							myHitachiProj.POWER = GET_BUFFER_CHAR(DATA.TEXT)
						}
						CASE CMD_SRC:{	// SOURCE
							SWITCH(GET_BUFFER_CHAR(DATA.TEXT)){
								CASE $00: myHitachiProj.curSOURCE = 'PC'
								CASE $03: myHitachiProj.curSOURCE = 'HDMI1'
								CASE $0D: myHitachiProj.curSOURCE = 'HDMI2'
								CASE $09: myHitachiProj.curSOURCE = 'DVI'
							}
							IF(myHitachiProj.curSource != myHitachiProj.newSOURCE && LENGTH_ARRAY(myHitachiProj.newSOURCE)){
								fnAddToQueue(fnGetSourceCmd(myHitachiProj.newSOURCE))
								myHitachiProj.newSOURCE = ''
							}
						}
						CASE CMD_FRZ:{	// FREEZE
							myHitachiProj.FREEZE = GET_BUFFER_CHAR(DATA.TEXT)
						}
						CASE CMD_AVM:{	// AVMUTE
							myHitachiProj.AVMUTE = GET_BUFFER_CHAR(DATA.TEXT)
						}
					}
					myHitachiProj.COMMS.PEND_CMD = ''
					fnSendFromQueue()
					IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
					TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
				}
			}
		}
	} 
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	fnDebugHex(DEBUG_DEV,'HIT->', pDATA)
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
							CASE 'TRUE':myHitachiProj.COMMS.DISABLED = FALSE
							DEFAULT:		myHitachiProj.COMMS.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myHitachiProj.COMMS.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE':myHitachiProj.COMMS.DEBUG = DEBUG_STD
								CASE 'DEV':	myHitachiProj.COMMS.DEBUG = DEBUG_DEV
								DEFAULT:		myHitachiProj.COMMS.DEBUG = DEBUG_ERR
							}
						}
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myHitachiProj.COMMS.IP_HOST 	= fnStripCharsRight( REMOVE_STRING(DATA.TEXT,':',1),1)
								myHitachiProj.COMMS.IP_PORT 	= ATOI(DATA.TEXT)
							}
							ELSE{
								myHitachiProj.COMMS.IP_HOST 	= DATA.TEXT
								myHitachiProj.COMMS.IP_PORT	= 23
							}
							fnPoll()
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'OFF':{  	fnAddToQueue("$2A,$D3,$01,$00,$00,$60,$00,$00") }
						CASE 'ON':{ 	fnAddToQueue("$BA,$D2,$01,$00,$00,$60,$01,$00") }
					}
				}
				CASE 'INPUT':{
					myHitachiProj.newSOURCE = DATA.TEXT
					SWITCH(myHitachiProj.POWER){
						CASE TRUE:	fnAddToQueue(fnGetSourceCmd(myHitachiProj.newSOURCE))
						CASE FALSE:	fnAddToQueue("$BA,$D2,$01,$00,$00,$60,$01,$00")
					}
				}
				CASE 'VMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'OFF':{  	fnAddToQueue("$F3,$93,$01,$00,$05,$24,$00,$00") }
						CASE 'ON':{ 	fnAddToQueue("$63,$92,$01,$00,$05,$24,$01,$00") }
					}
				}
				CASE 'FREEZE':{
					SWITCH(DATA.TEXT){
						CASE 'OFF':{  	fnAddToQueue("$83,$D2,$01,$00,$02,$30,$00,$00") }
						CASE 'ON':{ 	fnAddToQueue("$13,$D3,$01,$00,$02,$30,$01,$00") }
					}
				}
			}
		}
	}
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION CHAR[8] fnGetSourceCmd(CHAR pSource[10]){
	SWITCH(pSource){
		CASE 'PC': 			RETURN "$FE,$D2,$01,$00,$00,$20,$00,$00"
		CASE 'HDMI1': 		RETURN "$0E,$D2,$01,$00,$00,$20,$03,$00"
		CASE 'HDMI2': 		RETURN "$6E,$D6,$01,$00,$00,$20,$0D,$00"
		CASE 'DVI': 		RETURN "$AE,$D4,$01,$00,$00,$20,$09,$00"
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!myHitachiProj.COMMS.DISABLED){
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,255] = (myHitachiProj.POWER)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
