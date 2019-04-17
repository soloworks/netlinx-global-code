MODULE_NAME='mChristieMSeries'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uChristieProj{
	(** Current State **)
	INTEGER 	POWER
	INTEGER 	VMUTE
	INTEGER 	FREEZE
	CHAR 		INPUT[10]
	(** Desired State **)
	INTEGER 	desPOWER
	INTEGER 	desVMUTE
	INTEGER 	desFREEZE
	CHAR 	  	desINPUT[10]
	(** Comms **)
	INTEGER	isIP
	INTEGER	IP_PORT
	CHAR 		IP_HOST[255]
	INTEGER	CONN_STATE
	INTEGER	DEBUG
	CHAR		Rx[500]
}
DEFINE_CONSTANT
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2
LONG TLID_RETRY 			= 3

DEFINE_VARIABLE
VOLATILE uChristieProj myChristieProj

LONG TLT_POLL[] 		= {20000}	// Poll Time
LONG TLT_COMMS[]		= {90000}	// Comms Timeout

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER chnFreeze		= 211		// Picture Freeze Feedback
INTEGER chnVMUTE	   = 214		// Picture Mute Feedback
INTEGER chnPOWER	 	= 255		// Proj Power Feedback
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myChristieProj.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myChristieProj.Rx
}
/******************************************************************************
	Communication Helper Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	IF(myChristieProj.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(FALSE,"'Connecting Christie on'","myChristieProj.IP_HOST,':',ITOA(myChristieProj.IP_PORT)")
		myChristieProj.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myChristieProj.IP_HOST, myChristieProj.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(dvDevice.port);
}

/******************************************************************************
	Polling Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand("'PWR?'")
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{	// Poll Device
	fnPoll()
}
/******************************************************************************
	Communication Sending Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[255]){
	SEND_STRING dvDevice,"'(',pCMD,')'"
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myChristieProj.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION CHAR[20] fnGetInputString(CHAR pInp[]){
	SWITCH(pInp){
		CASE 'VGA1':	RETURN'A-RGB1'
		CASE 'VGA2':	RETURN'A-RGB2'
		CASE 'DVI':		RETURN'D-RGB'
		CASE 'HDMI':	RETURN'HDMI'
		CASE 'VIDEO':	RETURN'COMP'
	}
}
/******************************************************************************
	Feedback Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'->Christie',pDATA)

	// Process the feedback
	REMOVE_STRING(pDATA,'(',1)	// Get rid of any leading data
	
	SWITCH(GET_BUFFER_STRING(pDATA,4)){
		CASE 'PWR!':{
			myChristieProj.Power   = ATOI(GET_BUFFER_STRING(pDATA,3))
			fnSendCommand('SHU?')
		}
		CASE 'SHU!':{
			myChristieProj.VMUTE = ATOI(GET_BUFFER_STRING(pDATA,3))
			IF(myChristieProj.VMUTE != myChristieProj.DesVMUTE){
				SWITCH(myChristieProj.desVMute){
					CASE TRUE:  fnSendCommand("'SHU 1'")
					CASE FALSE: fnSendCommand("'SHU 0'")
				}
			}
		}
	}

	// Set Timeout
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myChristieProj.CONN_STATE = CONN_STATE_CONNECTED
		IF(myChristieProj.isIP){
			fnDebug(FALSE,'Connected to Christie on',"myChristieProj.IP_HOST,':',ITOA(myChristieProj.IP_PORT)")
		}
		ELSE{
			SEND_COMMAND DATA.DEVICE,'SET MODE DATA'
			SEND_COMMAND DATA.DEVICE,'SET BAUD 115200 N,8,1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		myChristieProj.CONN_STATE = CONN_STATE_OFFLINE
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myChristieProj.CONN_STATE = CONN_STATE_OFFLINE
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
		fnDebug(TRUE,"'Christie IP ERR:[',myChristieProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'->RAW',DATA.TEXT);
		WHILE(FIND_STRING(myChristieProj.Rx,"')'",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myChristieProj.Rx,"')'",1),1))
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{	// Control Events
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myChristieProj.IP_HOST 	= DATA.TEXT
						myChristieProj.IP_PORT	= 33336
						fnPoll()
					}
					CASE 'DEBUG':{
						myChristieProj.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}

			CASE 'RAW':SEND_STRING dvDevice, "'(',DATA.TEXT,')'"

			CASE 'INPUT':{
				myChristieProj.desInput = fnGetInputString(DATA.TEXT)

				IF(myChristieProj.POWER){
					//fnSendCommand("'INPUT=',myChristieProj.desInput")
				}
				ELSE{
					fnSendCommand("'PWR 1'")
				}
			}

			CASE 'POWER':{
				myChristieProj.desVMute = FALSE
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnSendCommand("'PWR 1'")
					CASE 'OFF': fnSendCommand("'PWR 0'")
				}
			}

			CASE 'VMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':     myChristieProj.desVMute = TRUE
					CASE 'OFF':    myChristieProj.desVMute = FALSE
					CASE 'TOGGLE': myChristieProj.desVMute = !myChristieProj.desVMute
				}
				SWITCH(myChristieProj.desVMute){
					CASE TRUE:  fnSendCommand("'SHU 1'")
					CASE FALSE: fnSendCommand("'SHU 0'")
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] 	      = ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,252] 	      = ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,chnPOWER] 	= ( myChristieProj.POWER)
	[vdvControl,chnFreeze] 	= ( myChristieProj.FREEZE )
	[vdvControl,chnVMUTE]   = ( myChristieProj.VMUTE )
}
/******************************************************************************
	EoF
******************************************************************************/


/******************************************************************************
	EoF
******************************************************************************/
