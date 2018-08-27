MODULE_NAME='mYamahaRX'(DEV vdvControl[], DEV dvDEVICE)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Yamaha Amp Control via YNCA

******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uAVRZone{
	INTEGER 	POWER
	INTEGER 	MUTE
	SINTEGER VOL
	SINTEGER VOL_MAX
	CHAR 	  	curSRC[5]
	CHAR 	  	desSRC[5]
}
DEFINE_TYPE STRUCTURE uComms{
	CHAR 	  	RX[1000]
	INTEGER 	DEBUG
	INTEGER 	isIP
	CHAR		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	IP_STATE
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_COMMS	= 2
LONG TLID_RETRY	= 3
LONG TLID_SEND		= 4
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uAVRZone myYAMRXZones[4]	// Player Data
VOLATILE uComms	myYAMRXComms
LONG 		TLT_POLL[]	= {15000}
LONG 		TLT_COMMS[]	= {60000}
LONG 		TLT_RETRY[]	= {15000}
LONG		TLT_SEND[]	= {100}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Feedback Processing **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'YAM->',pDATA)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
		CASE '@MAIN':{	
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)){
				CASE 'PWR':{
					myYAMRXZones[1].POWER = (UPPER_STRING(pDATA) == 'ON')
				}
				CASE 'VOL':{
					myYAMRXZones[1].VOL = ATOI(pDATA)
				}
				CASE 'MUTE':{
					myYAMRXZones[1].MUTE = (UPPER_STRING(pDATA) == 'ON')
				}
				CASE 'INP':{
					myYAMRXZones[1].curSRC = pDATA
					IF(myYAMRXZones[1].desSRC != '' && myYAMRXZones[1].desSRC != pDATA){
						fnSendCommand('MAIN','INP',myYAMRXZones[1].desSRC)
						myYAMRXZones[1].desSRC = ''
					}
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

(** Polling Code **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('MAIN', 'BASIC','?')
	fnSendCommand('ZONE2','BASIC','?')
}
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myYAMRXComms.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "'[',ITOA(vdvControl[1].Number),':',Msg, ']', MsgData"
	}
}
/******************************************************************************
	Comms Functions - Grouped ready for Abstraction
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	myYAMRXComms.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice,myYAMRXComms.RX
}
(** Device Events **)
DEFINE_EVENT DATA_EVENT[dvDEVICE]{
	ONLINE:{
		myYAMRXComms.IP_STATE	 = IP_STATE_CONNECTED
		IF(!myYAMRXComms.isIP){
			SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
			SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		IF(myYAMRXComms.isIP){
			myYAMRXComms.IP_STATE	  = IP_STATE_OFFLINE
			IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myYAMRXComms.isIP){
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
			fnDebug(TRUE,"'YamRX Error:[',myYAMRXComms.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myYAMRXComms.IP_STATE 	= IP_STATE_OFFLINE
					fnRetryConnection()
				}
			}
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		fnDebug(FALSE,'LEN->',ITOA(LENGTH_ARRAY(DATA.TEXT)))
		WHILE(FIND_STRING(myYAMRXComms.RX,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myYAMRXComms.RX,"$0D,$0A",1),2))
		}
	}
}
(** Send Routine **)
DEFINE_FUNCTION fnSendCommand(CHAR pUnit[], CHAR pFunc[],CHAR pParam[]){
	IF(myYAMRXComms.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->YAM',"'@',pUnit,':',pFunc,'=',pParam,$0D,$0A")
		SEND_STRING dvDevice,"'@',pUnit,':',pFunc,'=',pParam,$0D,$0A"
	}
}
(** IP Helpers **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myYAMRXComms.IP_HOST == ''){
		fnDebug(TRUE,'YamRX IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to Yamaha on'","myYAMRXComms.IP_HOST,':',ITOA(myYAMRXComms.IP_PORT)")
		myYAMRXComms.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myYAMRXComms.IP_HOST, myYAMRXComms.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){ TIMELINE_KILL(TLID_RETRY) }
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'RANGE--80,16'
	}
	COMMAND:{
		STACK_VAR INTEGER z;
		STACK_VAR CHAR Unit[5]
		z = GET_LAST(vdvControl)
		SWITCH(z){
			CASE 1:Unit = 'MAIN'
			CASE 2:Unit = 'ZONE2'
		}
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){	
					CASE 'DEBUG':myYAMRXComms.DEBUG 	 = (DATA.TEXT == 'TRUE')
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myYAMRXComms.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myYAMRXComms.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myYAMRXComms.IP_HOST = DATA.TEXT
							myYAMRXComms.IP_PORT = 50000 
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'OFF': fnSendCommand(Unit,'PWR','Standby')
					CASE 'ON':	fnSendCommand(Unit,'PWR','On')
				}
			}
			CASE 'INPUT':{
				myYAMRXZones[1].desSRC = DATA.TEXT
				IF(myYAMRXZones[z].POWER){
					fnSendCommand(Unit,'INP',myYAMRXZones[1].desSRC)
				}
				ELSE{
					fnSendCommand(Unit,'PWR','On')
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC': fnSendCommand(Unit,'VOL','Up')
					CASE 'DEC': fnSendCommand(Unit,'VOL','Down')
					//DEFAULT:		fnSendCommand(Unit,'VOL',ITOHEX(ATOI(DATA.TEXT)))
					DEFAULT:		fnSendCommand(Unit,'VOL',"DATA.TEXT,'.0'")
				}
			}
			CASE 'PROGRAM':{
				fnSendCommand(Unit,'SOUNDPRG',DATA.TEXT)
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myYAMRXZones[1].MUTE = TRUE
					CASE 'OFF':		myYAMRXZones[1].MUTE = FALSE
					CASE 'TOGGLE':	myYAMRXZones[1].MUTE = !myYAMRXZones[1].MUTE
				}
				SWITCH(myYAMRXZones[1].MUTE){
					CASE TRUE:	fnSendCommand(Unit,'MUTE','On')
					CASE FALSE:	fnSendCommand(Unit,'MUTE','Off')
				}
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER z;
	FOR(z = 1; z <= LENGTH_ARRAY(vdvControl); z++){
		[vdvControl[z],199] = myYAMRXZones[z].MUTE
		[vdvControl[z],255] = myYAMRXZones[z].POWER
		[vdvControl[z],251] = TIMELINE_ACTIVE(TLID_COMMS)
	}
	SEND_LEVEL vdvControl[1],1,myYAMRXZones[1].VOL
}