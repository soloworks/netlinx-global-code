MODULE_NAME='mPlanarVidWall'(DEV vdvControl, DEV dvDevice)
#INCLUDE 'CustomFunctions'
DEFINE_CONSTANT
// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2
//
DEFINE_TYPE STRUCTURE uScreen{
	// COMMS
	INTEGER isIP
	INTEGER CONN_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	CHAR 	  Rx[256]
	INTEGER DEBUG
	INTEGER ID
	(** MetaData **)
	CHAR 	  MODEL[20]
	CHAR	  SERIALNO[20]
	(** Status **)
	INTEGER POWER
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timelines **)
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2
LONG TLID_TIMEOUT		= 3
LONG TLID_RETRY      = 4
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uScreen myPlanar
(** Timeline Times **)
LONG TLT_POLL[]		= { 30000 }
LONG TLT_COMMS[]		= { 90000 }
LONG TLT_TIMEOUT[]	= {  5000 }
LONG TLT_RETRY[]     = { 10000 }
/******************************************************************************
	Comms Setup
******************************************************************************/
DEFINE_START{
	myPlanar.isIP = !(dvDEVICE.NUMBER)
	myPlanar.ID = 1
	//CREATE_BUFFER dvDevice, myPlanar.Rx
}
/******************************************************************************
	Comms Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myPlanar.IP_HOST)){
		fnDebug(TRUE,'Planar IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Planar on ',"myPlanar.IP_HOST,':',ITOA(myPlanar.IP_PORT)")
		myPlanar.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myPlanar.IP_HOST, myPlanar.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
/******************************************************************************
	Comms IP Device Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2'
		IF(!myPlanar.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		myPlanar.CONN_STATE = CONN_STATE_CONNECTED
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		IF(myPlanar.isIP){
			myPlanar.CONN_STATE 	= CONN_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myPlanar.isIP){
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
					myPlanar.CONN_STATE 	= CONN_STATE_OFFLINE
					fnRetryConnection()
				}
			}
			fnDebug(TRUE,"'Planar IP Error:[',myPlanar.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(FALSE,'Planar->',fnBytesToString(DATA.TEXT))
		SWITCH(GET_BUFFER_CHAR(DATA.TEXT)){
			CASE $21:{	// Command Accepted
				IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
		IF(GET_BUFFER_CHAR(DATA.TEXT) == myPlanar.ID){
			STACK_VAR INTEGER len
			STACK_VAR INTEGER cmd
			STACK_VAR CHAR val[20]
			GET_BUFFER_STRING(DATA.TEXT,2)	// Remove $00,$00
			// Get Length
			len = GET_BUFFER_CHAR(DATA.TEXT)
			// Get Data Control
			GET_BUFFER_CHAR(DATA.TEXT)
			// Get cmd
			cmd = GET_BUFFER_CHAR(DATA.TEXT)
			// Get data
			val = DATA.TEXT
			SET_LENGTH_ARRAY(val,LENGTH_ARRAY(val)-1)
			// Act
			SWITCH(cmd){
				CASE $19:{
					SWITCH(val[1]){
						CASE $01:myPlanar.Power = FALSE
						CASE $02:myPlanar.Power = TRUE
					}
				}
			}
		}
	}
}
/******************************************************************************
	Comms Polling Utility Functions
******************************************************************************/
(** Polling **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	//fnSendCommand("$A6,$01,$00,$00,$00,$03,$01,$19,$BC")	// Power Status Request
	fnSendCommand("$19")
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}

/******************************************************************************
	Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myPlanar.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Comms TxRx Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR cmdData[]){
	IF(myPlanar.CONN_STATE == CONN_STATE_CONNECTED){
		STACK_VAR CHAR cmd[256]
		STACK_VAR INTEGER chk
		INTEGER x
		// Build Command
		cmd = "$A6,myPlanar.ID,$00,$00,$00,LENGTH_ARRAY(cmdData)+2,$01,cmdData"
		// Calculate ChkSum
		FOR(x = 1; x <= LENGTH_ARRAY(cmd); x++){
			chk = chk BXOR cmd[x]
		}
		// Append ChkSum
		cmd = "cmd,chk"
		// Debug Out
		fnDebug(FALSE,'->Planar',fnBytesToString(cmd))
		// Send Command
		SEND_STRING dvDevice, cmd
		// Start Timeout
		IF(myPlanar.isIP){
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	fnInitPoll()
}
(** Drop connection after X **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}

(** Feedback Helper **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myPlanar.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myPlanar.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myPlanar.IP_HOST = DATA.TEXT
							myPlanar.IP_PORT = 5000
						}
						fnOpenTCPConnection()
					}
					CASE 'ID': {	myPlanar.ID = ATOI(DATA.TEXT) }
					CASE 'DEBUG':{ myPlanar.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':     myPlanar.Power = True
					CASE 'OFF':    myPlanar.Power = False
					CASE 'TOGGLE': myPlanar.Power = !myPlanar.Power
				}
				SWITCH(myPlanar.POWER){
					CASE FALSE: fnSendCommand("$18,$01")
					CASE TRUE:  fnSendCommand("$18,$02")
				}
			}
		}
	}
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl, 255] = (myPlanar.POWER)
}

/******************************************************************************
	EoF
******************************************************************************/