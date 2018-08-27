MODULE_NAME='mDenonDVD'(DEV vdvControl,DEV tp[],DEV dvDevice)
/******************************************************************************
	Set up for basic control - not zoned
******************************************************************************/
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uDenonDVD{
	// COMMS
	CHAR RX[200]
	INTEGER 	IP_PORT						// IP Address
	CHAR		IP_HOST[255]				//	IP Port
	INTEGER 	IP_STATE						// Connection State
	INTEGER	isIP							// Device is IP driven
	INTEGER 	DEBUG							// Debugging	
	// State
	INTEGER POWER
}

DEFINE_CONSTANT
// Timelines
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_RETRY	= 3
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= { 120000 } 
LONG TLT_POLL[]  		= {  25000 }
LONG TLT_RETRY[]		= {   5000 }

VOLATILE uDenonDVD myDenonDVD
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myDenonDVD.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myDenonDVD.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	IF(myDenonDVD.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->DVD',"'@0',pCMD,$0D")
		SEND_STRING dvDevice, "'@0',pCMD,$0D"
		fnInitPoll()
	}
}
DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myDenonDVD.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "'[',ITOA(vdvControl.Number),':',Msg, ']', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myDenonDVD.IP_HOST == ''){
		fnDebug(TRUE,'DVD IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to DVD on ',"myDenonDVD.IP_HOST,':',ITOA(myDenonDVD.IP_PORT)")
		myDenonDVD.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myDenonDVD.IP_HOST, myDenonDVD.IP_PORT, IP_TCP) 
	}
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('?PW')	// STANDBY Query
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myDenonDVD.IP_STATE	= IP_STATE_CONNECTED
		IF(!myDenonDVD.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, "'SET BAUD 38400 N 8 1 485 DISABLE'"
		}
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		IF(myDenonDVD.isIP){
			myDenonDVD.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myDenonDVD.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myDenonDVD.IP_STATE = IP_STATE_OFFLINE
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
					fnRetryConnection()
				}
			}
			fnDebug(TRUE,"'DVD IP Error:[',myDenonDVD.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		IF(DATA.TEXT == 'ack'){
			REMOVE_STRING(DATA.TEXT,'ack',1)
		}
		IF(DATA.TEXT == 'nack'){
			REMOVE_STRING(DATA.TEXT,'nack',1)
		}
		WHILE(FIND_STRING(myDenonDVD.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myDenonDVD.RX,"$0D",1),1))
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	REMOVE_STRING(pDATA,'@0',1)	// Strip ID and any Garbage (ACK/NACKs)
	fnDebug(FALSE,'DVD->',pDATA)
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myDenonDVD.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						myDenonDVD.IP_HOST = DATA.TEXT
						myDenonDVD.IP_PORT = 9030 
						fnRetryConnection()
					}
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		fnSendCommand('PW00')
					CASE 'OFF':		fnSendCommand('PW01')
				}
			}
		}
	}
}


DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myDenonDVD.POWER)
}
/******************************************************************************
	Interface Events
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE 01:fnSendCommand('2353')		// Play
			CASE 02:fnSendCommand('2354')		// Stop
			CASE 03:fnSendCommand('2348')		// Pause
			CASE 04:fnSendCommand('2332')		// SKIP+
			CASE 05:fnSendCommand('2333')		// SKIP-
			CASE 06:fnSendCommand('PCSLSFf')	// FFWD
			CASE 07:fnSendCommand('PCSLSRf')	// RWND
			CASE 45:fnSendCommand('PCCUSR1')	// Left
			CASE 46:fnSendCommand('PCCUSR2')	// Right
			CASE 47:fnSendCommand('PCCUSR3')	// Up
			CASE 48:fnSendCommand('PCCUSR4')	// Down
			CASE 49:fnSendCommand('PCENTR')	// Select
			CASE 61:fnSendCommand('DVFCLR1')	// Red
			CASE 62:fnSendCommand('DVFCLR2')	// Green
			CASE 63:fnSendCommand('DVFCLR3')	// Blue
			CASE 64:fnSendCommand('DVFCLR4')	// Yellow
			CASE 71:fnSendCommand('PCHM')		// Home
			CASE 72:fnSendCommand('DVTP')		// Top Menu
			CASE 73:fnSendCommand('DVOP')		// Option Menu
			CASE 74:fnSendCommand('DVPU')		// Popup Menu
			CASE 75:fnSendCommand('PCRTN')		// Return
			
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/