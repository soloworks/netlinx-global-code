MODULE_NAME='mCasioProjectorV02'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uCasioProj{
	(** Current States **)
	INTEGER 	POWER				// Current Power State
	CHAR 	  	SOURCE[10]		// Current Input State
	(** Desired States **)
	INTEGER 	desPOWER			// Desired Power State
	CHAR 	  	desSOURCE[10]	// Desired Input State
	(** Comms **)
	INTEGER  isIP				// Is this IP or RS232 Controlled
	CHAR 		IP_HOST[128]	// Projector IP Address
	INTEGER 	IP_PORT
	CHAR 		Tx[256]			// Transmit Buffer
	CHAR 		Rx[256]			// Recieve Buffer
	INTEGER 	DEBUG				// Debug ON/OFF
	INTEGER 	CONN_STATE		// IP Connected
	INTEGER 	TxPEND			// Response Pending
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
	(** Timeline Constants **)
LONG TLID_POLL 		= 1
LONG TLID_COMMS		= 2
LONG TLID_TIMEOUT		= 3
	(** Channel Constants **)
INTEGER chnPOWER		= 255
	(** Custom ON / OFF - avoids 0 as FALSE **)
INTEGER desON 			= 1
INTEGER desOFF			= 2

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uCasioProj myCasioProj
	(** Timeline Times **)
LONG 		TLT_POLL[]		= { 15000 }	// Poll every 15 seconds
LONG 		TLT_COMMS[]		= { 90000 }	// Comms is dead if nothing recieved for 60s
LONG 		TLT_TIMEOUT[]	= {  5000 }	// Kill connection after timeout
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myCasioProj.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myCasioProj.Rx
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	IF(myCasioProj.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(FALSE,"'Connecting Casio on'","myCasioProj.IP_HOST,':',ITOA(myCasioProj.IP_PORT)")
		myCasioProj.CONN_STATE = CONN_STATE_CONNECTING;
		ip_client_open(dvDevice.port, myCasioProj.IP_HOST, myCasioProj.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(dvDevice.port);
}
	(** Start up the Polling Function **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnPoll(){
	fnAddQueryToQueue("'pow'")		// Power
	fnAddQueryToQueue("'sour'")	// Source
}
DEFINE_FUNCTION fnAddCommandToQueue(CHAR cmd[], CHAR param[]){
	myCasioProj.Tx = "myCasioProj.Tx,$0D,'*',cmd,'=',param,'#',$0D"
	fnSendFromQueue()
}
	(** Send a command **)
DEFINE_FUNCTION fnAddQueryToQueue(CHAR cmd[]){
	fnAddCommandToQueue(cmd,'?')
}


DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myCasioProj.TxPend && myCasioProj.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myCasioProj.Tx,"'#',$0D",1)){
		STACK_VAR CHAR toSend[255]
		toSend = REMOVE_STRING(myCasioProj.Tx,"'#',$0D",1)
		fnDebug(FALSE,'->Casio',"toSend")
		SEND_STRING dvDevice,toSend
		myCasioProj.TxPend = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(myCasioProj.isIP && FIND_STRING(myCasioProj.Tx,"'#',$0D",1) && myCasioProj.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenConnection()
	}
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR pMsg[], CHAR pMsgData[]){
	IF(myCasioProj.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(dvDevice.PORT),':',ITOA(vdvControl.Number),':',pMsg, ':', pMsgData"
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	
	IF(pDATA[1] == '>'){
		RETURN
	}
	// Eat the initial "'*'"
	GET_BUFFER_CHAR(pDATA)
	
	// Eat the final '#'
	pDATA = fnStripCharsRight(pDATA,1)
	
	SWITCH(UPPER_STRING(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1))){
		CASE 'POW':{
			SWITCH(UPPER_STRING(pDATA)){
				CASE 'ON':  myCasioProj.POWER = TRUE;
				CASE 'OFF': myCasioProj.POWER = FALSE;
			}
			SELECT{
				ACTIVE(myCasioProj.POWER && myCasioProj.desPOWER == desOFF):{ fnAddCommandToQueue('pow','off') }
				ACTIVE(!myCasioProj.POWER && myCasioProj.desPOWER == desON):{  fnAddCommandToQueue('pow','on') }
				ACTIVE(1):{myCasioProj.desPOWER = 0}
			}
		}
		CASE 'SOUR':{
			IF(myCasioProj.SOURCE != pDATA){
				myCasioProj.SOURCE = pDATA
				SEND_STRING vdvControl,"'INPUT-',fnGetSourceName(myCasioProj.SOURCE)"
			}
			IF(LENGTH_ARRAY(myCasioProj.desSOURCE) && myCasioProj.desSOURCE != pDATA){
				fnAddCommandToQueue('sour',myCasioProj.desSOURCE)
			}
			ELSE{
				myCasioProj.desSOURCE = ''
			}
		}
	}
	
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	myCasioProj.TxPend = FALSE
	fnSendFromQueue()
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	OFFLINE:{
		myCasioProj.CONN_STATE = CONN_STATE_OFFLINE
		myCasioProj.Tx = ''
		myCasioProj.TxPend = FALSE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	}
	ONLINE:{
		IF(myCasioProj.isIP){
			fnDebug(FALSE,'Connected to Casio on',"myCasioProj.IP_HOST,':',ITOA(myCasioProj.IP_PORT)")
		}
		ELSE{
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, "'SET BAUD 9600 N 8 1 485 DISABLE'"
			myCasioProj.CONN_STATE = CONN_STATE_CONNECTED
			fnPoll()
			fnInitPoll()
		}
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myCasioProj.CONN_STATE = CONN_STATE_OFFLINE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
		SWITCH(DATA.NUMBER){
			CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
			CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
			CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		fnDebug(TRUE,"'Sayno IP ERR:[',myCasioProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'Casio->AMX',DATA.TEXT);
		WHILE(FIND_STRING(myCasioProj.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myCasioProj.Rx,"$0D,$0A",1),2))
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myCasioProj.IP_HOST 	= DATA.TEXT
						myCasioProj.IP_PORT	= 10000
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{ myCasioProj.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'CONNECT':{
				SWITCH(DATA.TEXT){
					CASE 'CLOSE':	fnCloseConnection()
					CASE 'OPEN':	fnOpenConnection()
				}
			}
			CASE 'RAW':{
				fnAddCommandToQueue(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'=',1),1),DATA.TEXT)
			}
			CASE 'INPUT':{
				IF(myCasioProj.POWER){
					fnAddCommandToQueue('sour',fngetSourceCode(DATA.TEXT))
				}
				ELSE{
					myCasioProj.desSOURCE = fngetSourceCode(DATA.TEXT)
					fnAddCommandToQueue('pow','on')
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  myCasioProj.desPOWER = desON
					CASE 'OFF': myCasioProj.desPOWER = desOFF
				}
				SWITCH(myCasioProj.desPOWER){
					CASE desON:	 fnAddCommandToQueue('pow','on')
					CASE desOFF: fnAddCommandToQueue('pow','off')
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,chnPOWER] 	= ( myCasioProj.POWER)
}

/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}
	(** Close connection after X amount of inactivity **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myCasioProj.TxPend = FALSE
	myCasioProj.Tx = ''
	IF(myCasioProj.isIP){
		fnCloseConnection()
	}
}

/******************************************************************************
	Input Control Code
******************************************************************************/

DEFINE_FUNCTION CHAR[255] fnGetSourceName(CHAR pSRC[]){
	SWITCH(UPPER_STRING(pSRC)){
		CASE 'RGB':			RETURN 'VGA'
		CASE 'HDMI':		RETURN 'HDMI1'
		CASE 'HDMI2':		RETURN 'HDMI2'
		CASE 'HDBASET':	RETURN 'HDBASET'
	}
}
DEFINE_FUNCTION CHAR[255] fnGetSourceCode(CHAR pSRC[]){
	SWITCH(pSRC){
		CASE 'VGA':
		CASE 'VGA1':		RETURN 'RGB'
		CASE 'HDMI1':		RETURN 'HDMI'
		CASE 'HDMI2':		RETURN 'HDMI2'
		CASE 'HDBASET':	RETURN 'HDBASET'
	}
}
/******************************************************************************
	EoF
******************************************************************************/
