MODULE_NAME='mSonyDisplaySimpleIP'(DEV vdvControl, DEV dvDevice)
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
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
//
DEFINE_TYPE STRUCTURE uScreen{
	// COMMS
	INTEGER isIP
	INTEGER IP_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
	INTEGER DISABLED
	(** MetaData **)
	INTEGER ID
	CHAR 	  MODEL[20]
	CHAR	  SERIALNO[20]
	(** Status **)
	INTEGER POWER
	CHAR 	  INPUT_RAW[16]
	CHAR 	  INPUT[16]
	INTEGER MUTE
	INTEGER VOL
	(** Status **)
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
	(** Desired Values **)
	CHAR 		desINPUT[20]
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
LONG TLID_AUTOADJ 	= 5
LONG TLID_VOL			= 6
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uScreen mySonyDisplay
(** Timeline Times **)
LONG TLT_POWER[]		= {20000}
LONG TLT_POLL[]		= {45000}
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
				mySonyDisplay.IP_STATE = IP_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				SEND_COMMAND dvDevice, 'SET MODE DATA'
				SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
				fnPoll()
			}
		}
	}
	OFFLINE:{
		IF(mySonyDisplay.isIP){
			mySonyDisplay.IP_STATE 	= IP_STATE_OFFLINE
			mySonyDisplay.Tx 				= ''
		}
	}
	ONERROR:{
		IF(mySonyDisplay.isIP){
			STACK_VAR CHAR _MSG[255]
			mySonyDisplay.IP_STATE 	= IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'SONY IP Error:[',mySonyDisplay.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!mySonyDisplay.DISABLED){
			WHILE(FIND_STRING(mySonyDisplay.Rx,"$0A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySonyDisplay.Rx,"$0A",1),1))
			}
			IF(mySonyDisplay.isIP){
				IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(mySonyDisplay.IP_HOST)){
		fnDebug(TRUE,'SONY IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to SONY on ',"mySonyDisplay.IP_HOST,':',ITOA(mySonyDisplay.IP_PORT)")
		mySonyDisplay.IP_STATE = IP_STATE_CONNECTING
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
	fnSendQuery('POWR');	// Power Status Request
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}

(** Send with Delays between messages **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(mySonyDisplay.isIP && mySonyDisplay.IP_STATE == IP_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	IF(FIND_STRING(mySonyDisplay.Tx,"$0A",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(mySonyDisplay.Tx,"$0A",1)
		fnDebug(FALSE,'->SONY',_ToSend)
		SEND_STRING dvDevice, _ToSend
		IF(mySonyDisplay.isIP){
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	fnInitPoll()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
(** Message Building Routine **)

DEFINE_FUNCTION fnSendCommand(CHAR pFUNCTION[4],CHAR pPARAM[16]){
	fnAddToQueue(FALSE,pFUNCTION,pPARAM)
}

DEFINE_FUNCTION fnSendQuery(CHAR pFUNCTION[4]){
	fnAddToQueue(TRUE,pFUNCTION,'')
}

DEFINE_FUNCTION fnAddToQueue(INTEGER isQUERY,CHAR pFUNCTION[4],CHAR pPARAM[16]){

	STACK_VAR CHAR pToSend[30]
	SWITCH(isQUERY){
		CASE TRUE:  pToSend = "pToSend,'E',pFUNCTION,fnPadLeadingChars(pPARAM,'#',16)"
		CASE FALSE: pToSend = "pToSend,'C',pFUNCTION,fnPadLeadingChars(pPARAM,'0',16)"
	}
	pToSend = "'*S',pToSend,$0A"

	mySonyDisplay.Tx = "mySonyDisplay.TX,pToSend"

	fnSendFromQueue()
}
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(mySonyDisplay.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
(** Input Translator **)
DEFINE_FUNCTION CHAR[16] fnTextToInput(CHAR pInput[16]){
	SWITCH(pINPUT){
		CASE 'HDMI1':  	RETURN "'0000000100000001'"
		CASE 'HDMI2':  	RETURN "'0000000100000002'"
		CASE 'HDMI3':  	RETURN "'0000000100000003'"
		CASE 'HDMI4':  	RETURN "'0000000100000004'"
	}
}

DEFINE_FUNCTION CHAR[16] fnInputToText(CHAR pInput[16]){
	SELECT{
		ACTIVE(pInput ==  "'0000000100000001'"):	RETURN 'HDMI1'
		ACTIVE(pInput ==  "'0000000100000002'"):	RETURN 'HDMI2'
		ACTIVE(pInput ==  "'0000000100000003'"):	RETURN 'HDMI3'
		ACTIVE(pInput ==  "'0000000100000004'"):	RETURN 'HDMI4'
	}
}

(** Feedback Helper **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

	fnDebug(FALSE,'SONY->',pDATA)

	IF(GET_BUFFER_STRING(pDATA,2) == '*S'){
		STACK_VAR CHAR pRESPONSE
		pRESPONSE = GET_BUFFER_CHAR(pDATA)
		SWITCH(GET_BUFFER_STRING(pDATA,4)){
			CASE 'POWR':{
				IF(pRESPONSE == 'A' || pRESPONSE == 'N'){
					mySonyDisplay.POWER = ATOI(pDATA)
					fnSendQuery('INPT')
				}
			}
			CASE 'INPT':{
				IF((pRESPONSE == 'A' || pRESPONSE == 'N') && pDATA != '0000000000000000'){
					IF(mySonyDisplay.INPUT_RAW != pDATA){
						mySonyDisplay.INPUT_RAW = pDATA
						mySonyDisplay.INPUT = fnInputToText(mySonyDisplay.INPUT_RAW)
						SEND_STRING vdvControl,"'INPUT-',mySonyDisplay.INPUT"
					}
				}
			}
		}

		fnSendFromQueue()

		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}

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
						CASE 'DEBUG':{ mySonyDisplay.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')}
					}
				}
				CASE 'TEST':{

				}
				CASE 'INPUT':{
					IF(mySonyDisplay.POWER){
						IF(fnTextToInput(DATA.TEXT) != ''){
							fnSendCommand('INPT',fnTextToInput(DATA.TEXT))
						}
					}
					ELSE{
						fnSendCommand('POWR',"'1'") 	// Power ON
						mySonyDisplay.desINPUT = fnTextToInput(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_POWER)){
							TIMELINE_CREATE(TLID_POWER,TLT_POWER,LENGTH_ARRAY(TLT_POWER),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':{ 		fnSendCommand('POWR',"'1'") }
						CASE 'OFF':{		fnSendCommand('POWR',"'0'") }
						CASE 'TOGGLE':{
							SWITCH(mySonyDisplay.POWER){
								CASE FALSE:{ fnSendCommand('POWR',"'0'") }
								CASE TRUE:{  fnSendCommand('POWR',"'1'") }
							}
						}
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		mySonyDisplay.MUTE = TRUE
						CASE 'OFF':		mySonyDisplay.MUTE = FALSE
						CASE 'TOGGLE':	mySonyDisplay.MUTE = !mySonyDisplay.MUTE
					}
					SWITCH(mySonyDisplay.MUTE){
						CASE TRUE:	fnSendCommand('AMUT',"'1'")
						CASE FALSE:	fnSendCommand('AMUT',"'0'")
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':fnSendCommand('IRCC',"'30'")
						CASE 'DEC':fnSendCommand('IRCC',"'31'")
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								mySonyDisplay.VOL = ATOI(DATA.TEXT)
								fnSendCommand('VOLU',"DATA.TEXT")
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
	fnSendCommand('INPT',mySonyDisplay.desINPUT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(mySonyDisplay.VOL_PEND){
		mySonyDisplay.VOL = mySonyDisplay.LAST_VOL
		fnSendCommand('VOLU',"ITOA(mySonyDisplay.VOL)")
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