MODULE_NAME='mJVCProjector'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic Epson Control Module over IP using ESC/VP.net
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uJVCProj{
	// Comms
	INTEGER	DEBUG
	INTEGER	isIP
	INTEGER 	IP_PORT
	INTEGER 	IP_STATE
	CHAR 		IP_HOST[255]
	CHAR		Tx[200]
	CHAR 		Rx[200]
	// State
	INTEGER	POWER
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
	(** Timeline Constants **)
LONG TLID_POLL 		= 1
LONG TLID_COMMS		= 2

INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_ESTABLISHED	= 2
INTEGER IP_STATE_NEGOTIATE		= 3
INTEGER IP_STATE_CONNECTED		= 4

CHAR CMD_POWER[] = "$50,$57"
CHAR CMD_INPUT[] = "$49,$50"
CHAR CMD_MODEL[] = "$4D,$44"
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
	(** Comms Variables **)
VOLATILE uJVCProj myJVCProj

	(** Timeline Times **)
LONG 		TLT_POLL[]		= {30000};	// Poll every 15 seconds
LONG 		TLT_COMMS[]		= {90000};	// Comms is dead if nothing recieved for 60s
LONG 		TLT_TIMEOUT[]	= {45000};	// Delay by 2 seconds, then start polling
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myJVCProj.Rx
	myJVCProj.isIP = !dvDevice.NUMBER
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	fnDebug('Connecting to JVC on',"myJVCProj.IP_HOST,':',ITOA(myJVCProj.IP_PORT)")
	myJVCProj.IP_STATE = IP_STATE_CONNECTING
	ip_client_open(dvDevice.port, myJVCProj.IP_HOST, myJVCProj.IP_PORT, IP_TCP)
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
	fnDebug('fnPoll','Called')
	fnAddToQueue($3F,$50,$57,$00)	// Power Query
	fnInitPoll()
}

DEFINE_FUNCTION fnAddToQueue(INTEGER pType, INTEGER pCMD1, INTEGER pCMD2, INTEGER pData){
	myJVCProj.Tx = "myJVCProj.Tx,pType,$89,$01,pCMD1,pCMD2"
	IF(pDATA != $00){
		myJVCProj.Tx = "myJVCProj.Tx,pData"
	}
	myJVCProj.Tx = "myJVCProj.Tx,$0A"
	fnSendFromQueue()
}
	(** Send a command **)
DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug('fnSendFromQueue','Called')
	IF(myJVCProj.IP_STATE == IP_STATE_CONNECTED && FIND_STRING(myJVCProj.Tx,"$0A",1)){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myJVCProj.Tx,"$0A",1)
		fnDebug('->JVC',"_ToSend")
		SEND_STRING dvDevice, _ToSend
	}
	ELSE IF(myJVCProj.isIP && myJVCProj.IP_STATE == IP_STATE_OFFLINE){
		fnOpenConnection()
	}
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myJVCProj.DEBUG)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR CHAR pResponseType
	STACK_VAR CHAR pUnitID[2]
	STACK_VAR INTEGER pCMD1
	STACK_VAR INTEGER pCMD2
	(** Do Data **)
	IF(RIGHT_STRING(pDATA,1) == "$0D"){
		pDATA = fnStripCharsRight(pDATA,1);
	}
	pResponseType 	= GET_BUFFER_CHAR(pDATA)
	pUnitID 			= GET_BUFFER_STRING(pDATA,2)
	pCMD1				= GET_BUFFER_CHAR(pDATA)
	pCMD2				= GET_BUFFER_CHAR(pDATA)

	SWITCH(pResponseType){
		CASE $06:{	// Ack Response
			fnDebug('JVC->','ACK')
			fnSendFromQueue()
		}
		CASE $40:{	// Detailed Response
			SELECT{
				ACTIVE(pCMD1 == $50 && pCMD2 == $57):{	// Power Status
					SWITCH(pDATA[1]){
						CASE $30:
						CASE $32:myJVCProj.POWER = FALSE
						CASE $31:myJVCProj.POWER = TRUE
					}
				}
				/*ACTIVE(pCMD1 == $49 && pCMD2 == $50):{	// Input Status
					IF(myJVCProj.INPUT_NO != pDATA[1]){
						SWITCH(myJVCProj.INPUT_NO){
							CASE $30:myJVCProj.INPUT_NAME = 'S-Video'
							CASE $31:myJVCProj.INPUT_NAME = 'Video'
							CASE $32:myJVCProj.INPUT_NAME = 'Component'
							CASE $33:myJVCProj.INPUT_NAME = 'PC'
							CASE $36:myJVCProj.INPUT_NAME = 'HDMI1'
							CASE $37:myJVCProj.INPUT_NAME = 'HDMI2'
						}
					}
					myJVCProj.INPUT_NO = pDATA[1]
					IF((myJVCProj.INPUT_NO != myJVCProj.DES_INPUT) && myJVCProj.DES_INPUT != $00){
						fnAddToQueue($21,$49,$50,myJVCProj.DES_INPUT)
					}
					IF(myJVCProj.INPUT_NO == myJVCProj.DES_INPUT){
						myJVCProj.DES_INPUT = 0
					}
				}
				ACTIVE(pCMD1 == $4D && pCMD2 == $44):{	// Model Info
					myJVCProj.META_MODEL = pDATA
					fnPoll()
				}*/
			}
		}
	}
		(** COMMS **)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)

}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	OFFLINE:{
		myJVCProj.IP_STATE = IP_STATE_OFFLINE
		myJVCProj.Tx = ''
		myJVCProj.Rx = ''
	}
	ONLINE:{
		IF(myJVCProj.isIP){
			// IP Control
			myJVCProj.IP_STATE = IP_STATE_ESTABLISHED
		}
		ELSE{
			// RS232 Control
			myJVCProj.IP_STATE = IP_STATE_CONNECTED
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 19200 N 8 1 485 DISABLE'
			fnInitPoll()
		}
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
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
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT: myJVCProj.IP_STATE = IP_STATE_OFFLINE
		}
		fnDebug("'JVC IP Error:[',myJVCProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		myJVCProj.Tx = ''
		myJVCProj.Rx = ''
	}
	STRING:{
		fnDebug('JVC->',DATA.TEXT);
		IF(DATA.TEXT == "'PJ_OK'"){
			myJVCProj.IP_STATE 	= IP_STATE_NEGOTIATE;
			myJVCProj.Rx = ''
			fnDebug('PJREQ','->JVC');
			SEND_STRING DATA.DEVICE,'PJREQ'
		}
		ELSE IF(DATA.TEXT == "'PJACK'"){
			myJVCProj.IP_STATE 	= IP_STATE_CONNECTED;
			myJVCProj.Rx = ''
			fnSendFromQueue()
		}
		ELSE{
			WHILE(FIND_STRING(myJVCProj.Rx,"$0A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myJVCProj.Rx,"$0A",1),1))
			}
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
						myJVCProj.IP_HOST = DATA.TEXT;
						myJVCProj.IP_PORT	= 20554
						fnPoll()
					}
					CASE 'DEBUG':{
						myJVCProj.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnAddToQueue($21,$50,$57,$31)
					CASE 'OFF':	fnAddToQueue($21,$50,$57,$30)
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) );
	[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) );
	[vdvControl,255] 	= ( myJVCProj.POWER);
}

/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug('TIMELINE_EVENT','TLID_POLL')
	fnPoll();
}
DEFINE_FUNCTION fnResetModule(){
	myJVCProj.Tx = ''
	myJVCProj.Rx = ''
}
	(** Comms Timeout **)
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	fnDebug('TIMELINE_EVENT','TLID_COMMS')
	fnResetModule()
}
/******************************************************************************
	Input Control Code
******************************************************************************/

