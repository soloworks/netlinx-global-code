MODULE_NAME='mSonyDisplayRS232'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Control Ltd (www.solocontrol.co.uk)

	Sony Screen - IP or RS232 control
	Single Screen control

	Inputs:
	HDMI|DVI|RGB|VID1|VID2
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_CONSTANT
//
DEFINE_TYPE STRUCTURE uScreen{
	// COMMS
	INTEGER isIP
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
	INTEGER DISABLED
	INTEGER CONN_STATE
	(** MetaData **)
	INTEGER ID
	CHAR 	  MODEL[20]
	CHAR	  SERIALNO[20]
	(** Status **)
	INTEGER POWER
	INTEGER INPUT
	INTEGER MUTE
	INTEGER VOL
	(** Status **)
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
	(** Desired Values **)
	CHAR 		desINPUT[3]
	INTEGER  desPOWER_ON
	INTEGER  desPOWER_OFF
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
LONG TLID_VOL			= 6

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED		= 2
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uScreen mySonyDisplay
(** Timeline Times **)
LONG TLT_POWER[]		= {20000}
LONG TLT_POLL[]		= {15000}
LONG TLT_COMMS[]		= {120000}
LONG TLT_TIMEOUT[]	= {5000}
LONG TLT_VOL[]			= {150}
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	mySonyDisplay.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, mySonyDisplay.Rx
}
(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!mySonyDisplay.DISABLED){
			IF(mySonyDisplay.isIP){
				mySonyDisplay.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				SEND_COMMAND dvDevice, 'SET MODE DATA'
				SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
				fnPoll();
			}
		}
	}
	OFFLINE:{
		IF(mySonyDisplay.isIP){
			mySonyDisplay.CONN_STATE 	= CONN_STATE_OFFLINE
			mySonyDisplay.Tx 				= ''
			fnInitTimeout(FALSE)
		}
	}
	ONERROR:{
		IF(mySonyDisplay.isIP){
			STACK_VAR CHAR _MSG[255]
			mySonyDisplay.CONN_STATE 	= CONN_STATE_OFFLINE
			mySonyDisplay.Tx 				= ''
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
			fnDebug(DEBUG_STD,"'SONY IP Error:[',mySonyDisplay.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!mySonyDisplay.DISABLED){
			fnDebug(DEBUG_STD,'RAW->',fnBytesToString(DATA.TEXT))
			fnProcessFeedback(DATA.TEXT)
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(mySonyDisplay.IP_HOST)){
		fnDebug(DEBUG_ERR,'SONY IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to SONY on ',"mySonyDisplay.IP_HOST,':',ITOA(mySonyDisplay.IP_PORT)")
		mySonyDisplay.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, mySonyDisplay.IP_HOST, mySonyDisplay.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
/******************************************************************************
	Comms Utility Functions
******************************************************************************/
(** Polling **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue($83,$00,$00,"$FF,$FF");	// Power Status Request
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}

(** Send with Delays between messages **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(mySonyDisplay.isIP && mySonyDisplay.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	IF(FIND_STRING(mySonyDisplay.Tx,"$0A,$0B,$0C",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = fnStripCharsRight( REMOVE_STRING(mySonyDisplay.Tx,"$0A,$0B,$0C",1),3)
		fnDebug(DEBUG_STD,'->SONY',fnBytesToString(_ToSend))
		SEND_STRING dvDevice, _ToSend
		IF(mySonyDisplay.isIP){
			fnInitTimeout(TRUE)
		}
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
	fnCloseTCPConnection()
}
(** Message Building Routine **)
DEFINE_FUNCTION fnAddToQueue(INTEGER pHEADER,INTEGER pCATEGORY,INTEGER pFUNCTION,CHAR pDATA[3]){

	STACK_VAR CHAR 	pToSend[30]
	STACK_VAR CHAR		pChkSum
	STACK_VAR INTEGER x

	pToSend = "pHEADER,pCATEGORY,pFUNCTION,pDATA"
	FOR(x = 1; x <= LENGTH_ARRAY(pToSend); x++){
		pChkSum = pChkSum+pToSend[x]
	}
	pToSend = "pToSend,pChkSum"

	IF(mySonyDisplay.isIP){
		pToSend = "$02,$10,'SONY',$00,$F1,$00,$06,pToSend"
	}

	mySonyDisplay.Tx = "mySonyDisplay.TX,pToSend,$0A,$0B,$0C"

	fnSendFromQueue()
}
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(mySonyDisplay.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
(** Input Translator **)
DEFINE_FUNCTION CHAR[3] fnTextToInput(CHAR pInput[]){
	SWITCH(pINPUT){
		CASE 'HDMI1':  	RETURN "$03,$04,$01"
		CASE 'HDMI2':  	RETURN "$03,$04,$02"
		CASE 'HDMI3':  	RETURN "$03,$04,$03"
		CASE 'HDMI4':  	RETURN "$03,$04,$04"
		CASE 'PC':  		RETURN "$03,$05,$01"
	}
}
DEFINE_FUNCTION CHAR[10] fnInputToText(CHAR pInput[3]){
	SELECT{
		ACTIVE(pInput ==  "$03,$04,$01"):	RETURN 'HDMI1'
		ACTIVE(pInput ==  "$03,$04,$02"):	RETURN 'HDMI2'
		ACTIVE(pInput ==  "$03,$04,$03"):	RETURN 'HDMI3'
		ACTIVE(pInput ==  "$03,$04,$04"):	RETURN 'HDMI4'
		ACTIVE(pInput ==  "$03,$05,$01"):	RETURN 'PC'
	}
}
 
(** Feedback Helper **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_STD,'SONY->',fnBytesToString(pDATA))
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE $70:{
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE $00:{
					SWITCH(GET_BUFFER_CHAR(pDATA)){
						CASE $02:{	// Power
							mySonyDisplay.POWER = GET_BUFFER_CHAR(pDATA)
						}
					}
				}
			}
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}

	fnSendFromQueue()

}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		IF(DATA.TEXT == 'PROPERTY-ENABLED,FALSE'){
			mySonyDisplay.DISABLED = TRUE
		}
		IF(!mySonyDisplay.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								mySonyDisplay.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								mySonyDisplay.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								mySonyDisplay.IP_HOST = DATA.TEXT
								mySonyDisplay.IP_PORT = 20060
							}
							fnPoll()
						}
						CASE 'ID': {	mySonyDisplay.ID = ATOI(DATA.TEXT) }
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE': 	mySonyDisplay.DEBUG = DEBUG_STD
								CASE 'DEV':   	mySonyDisplay.DEBUG = DEBUG_DEV
								DEFAULT: 		mySonyDisplay.DEBUG = DEBUG_ERR
							}
						}
					}
				}
				CASE 'ACTION':{
					SWITCH(DATA.TEXT){
						CASE 'STANDBY,ENABLE':{
							fnAddToQueue($8C,$00,$01,"$02,$01")
						}
					}
				}
				CASE 'INPUT':{
					IF(mySonyDisplay.POWER){
						IF(fnTextToInput(DATA.TEXT) != ''){
							fnAddToQueue($8C,$00,$02,fnTextToInput(DATA.TEXT))
						}
					}
					ELSE{
						mySonyDisplay.POWER = TRUE
						fnAddToQueue($8C,$00,$00,"$02,$01") 	// Power ON
						mySonyDisplay.desINPUT = fnTextToInput(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_POWER)){
							TIMELINE_CREATE(TLID_POWER,TLT_POWER,LENGTH_ARRAY(TLT_POWER),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
				CASE 'POWER':{
					
					SWITCH(DATA.TEXT){
						CASE 'ON':     mySonyDisplay.POWER = TRUE
						CASE 'OFF':    mySonyDisplay.POWER = FALSE
						CASE 'TOGGLE': mySonyDisplay.POWER = !mySonyDisplay.POWER
					}
					
					SWITCH(mySonyDisplay.POWER){
						CASE TRUE:{ fnAddToQueue($8C,$00,$00,"$02,$01") }
						CASE FALSE:{fnAddToQueue($8C,$00,$00,"$02,$00") }
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		mySonyDisplay.MUTE = TRUE
						CASE 'OFF':		mySonyDisplay.MUTE = FALSE
						CASE 'TOGGLE':	mySonyDisplay.MUTE = !mySonyDisplay.MUTE
					}
					SWITCH(mySonyDisplay.MUTE){
						CASE TRUE:	fnAddToQueue($8C,$00,$06,"$03,$01,$01")
						CASE FALSE:	fnAddToQueue($8C,$00,$06,"$03,$01,$00")
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':fnAddToQueue($8C,$00,$05,"$03,$00,$00")
						CASE 'DEC':fnAddToQueue($8C,$00,$05,"$03,$00,$01")
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								mySonyDisplay.VOL = ATOI(DATA.TEXT)
								fnAddToQueue($8C,$00,$05,"$03,$01,mySonyDisplay.VOL")
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								mySonyDisplay.LAST_VOL = ATOI(DATA.TEXT)
								mySonyDisplay.VOL_PEND = TRUE
							}
						}
					}
					mySonyDisplay.MUTE = FALSE
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POWER]{
	fnAddToQueue($8C,$00,$02,mySonyDisplay.desINPUT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(mySonyDisplay.VOL_PEND){
		mySonyDisplay.VOL = mySonyDisplay.LAST_VOL
		fnAddToQueue($8C,$00,$05,"$03,$01,mySonyDisplay.VOL")
		mySonyDisplay.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	IF(!mySonyDisplay.DISABLED){
		SEND_LEVEL vdvControl,1,mySonyDisplay.VOL
		[vdvControl, 199] = (mySonyDisplay.MUTE)
		[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 255] = (mySonyDisplay.POWER)
	}
}