MODULE_NAME='mDenonAVR'(DEV vdvZones[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Denon AVR Module
	By Solo Control Ltd (www.solocontrol.co.uk)
******************************************************************************/
DEFINE_CONSTANT
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

DEFINE_TYPE STRUCTURE uAVR{
	// Comms
	CHAR 		RX[500]			// Receieve Buffer
	INTEGER 	IP_PORT			//
	CHAR		IP_HOST[255]	//
	INTEGER 	IP_STATE			//
	INTEGER	isIP
	INTEGER 	DEBUG				// Debugging
}
DEFINE_TYPE STRUCTURE uZONE{
	INTEGER  POWER
	INTEGER	MUTE
	CHAR 		VOL_RAW[3]
	SINTEGER VOL_dB
	CHAR		VOL_MAX_RAW[3]
	SINTEGER VOL_MAX_dB
	CHAR		INPUT[10]
	(** Status **)
	INTEGER 	VOL_PEND			// Is a Volume Update pending
	SINTEGER	LAST_VOL			// Volume to Send
}

DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_RING		= 2
LONG TLID_RETRY	= 3

LONG TLID_COMMS	= 100

LONG TLID_VOL		= 200

DEFINE_VARIABLE
VOLATILE uAVR myAVR
VOLATILE uZONE myZONES[3]


LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myAVR.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myAVR.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[], CHAR pPARAM[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pCMD,pPARAM,$0D"
	IF(myAVR.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->AVR',toSend)
		SEND_STRING dvDevice, toSend
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myAVR.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "ITOA(vdvZones[1].Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myAVR.IP_HOST == ''){
		fnDebug(TRUE,'AVR IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to AVR on ',"myAVR.IP_HOST,':',ITOA(myAVR.IP_PORT)")
		myAVR.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myAVR.IP_HOST, myAVR.IP_PORT, IP_TCP)
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
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('PW','?')
	fnSendCommand('SI','?')
	fnSendCommand('MV','?')
	fnSendCommand('MU','?')
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'AVR->',pDATA)
	SWITCH(GET_BUFFER_STRING(pDATA,2)){
		CASE 'PW':{
			SWITCH(pDATA){
				CASE 'ON':			myZONES[1].POWER = TRUE
				CASE 'STANDBY':	myZONES[1].POWER = FALSE
			}
		}
		CASE 'SI':{
			IF(myZONES[1].INPUT != pDATA){
				myZONES[1].INPUT = pDATA
				SEND_STRING vdvZones[1],"'SOURCE-',myZONES[1].INPUT"
			}
		}
		CASE 'MV':{
			IF(LEFT_STRING(pDATA,3) == 'MAX'){
				GET_BUFFER_STRING(pDATA,4)
				myZONES[1].VOL_MAX_RAW = pDATA
				myZONES[1].VOL_MAX_dB 	= fnConvertVolume(myZONES[1].VOL_MAX_RAW) - 80
			}
			ELSE{
				myZONES[1].VOL_RAW	= pDATA
				myZONES[1].VOL_dB 	= fnConvertVolume(myZONES[1].VOL_RAW) - 80
			}
		}
		CASE 'MU':{
			myZONES[1].MUTE = (pDATA == 'ON')
		}
	}

	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION SINTEGER fnConvertVolume(CHAR pVOL[]){
	pVOL = fnPadTrailingChars(pVOL,'0',3)
	IF(pVOL[3] == '5'){pVOL[3] = '0'}
	RETURN ATOI(pVOL) / 10
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myAVR.IP_STATE	= IP_STATE_CONNECTED
		IF(!myAVR.isIP){
			SEND_COMMAND dvDevice,'SET BAUD 9600 N,8,1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		IF(myAVR.isIP){
			myAVR.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myAVR.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myAVR.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'SS IP Error:[',myAVR.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		WHILE(FIND_STRING(myAVR.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myAVR.RX,"$0D",1),1))
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvZones]{
	COMMAND:{
		STACK_VAR INTEGER z
		z = GET_LAST(vdvZones)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myAVR.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myAVR.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myAVR.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myAVR.IP_HOST = DATA.TEXT
							myAVR.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'POWER':{
				STACK_VAR CHAR pCMD[10]
				SWITCH(z){
					CASE 1: pCMD = 'PW'
					CASE 2: pCMD = 'Z2PW'
					CASE 3: pCMD = 'Z3PW'
				}
				SWITCH(DATA.TEXT){
					CASE 'ON': fnSendCommand(pCMD,'ON')
					CASE 'OFF':fnSendCommand(pCMD,'STANDBY')
				}
			}
			CASE 'INPUT':{
				STACK_VAR CHAR pCMD[10]
				SWITCH(z){
					CASE 1: pCMD = 'SI'
					CASE 2: pCMD = 'Z2SI'
					CASE 3: pCMD = 'Z3SI'
				}
				fnSendCommand(pCMD,DATA.TEXT)
			}
			CASE 'MUTE':{
				STACK_VAR CHAR pCMD[10]
				SWITCH(DATA.TEXT){
					CASE 'ON': 	myZones[z].MUTE = TRUE
					CASE 'OFF':	myZones[z].MUTE = FALSE
					CASE 'TOGGLE':
					CASE 'TOG':	myZones[z].MUTE = !myZones[z].MUTE
				}
				SWITCH(z){
					CASE 1: pCMD = 'MU'
					CASE 2: pCMD = 'Z2MU'
					CASE 3: pCMD = 'Z3MU'
				}
				SWITCH(myZONES[z].MUTE){
					CASE TRUE:	fnSendCommand(pCMD,'ON')
					CASE FALSE: fnSendCommand(pCMD,'OFF')
				}
			}
			CASE 'VOLUME':{
				STACK_VAR CHAR pCMD[10]
				SWITCH(z){
					CASE 1: pCMD = 'MV'
					CASE 2: pCMD = 'Z2'
					CASE 3: pCMD = 'Z3'
				}
				SWITCH(DATA.TEXT){
					CASE 'INC':	fnSendCommand(pCMD,'UP')
					CASE 'DEC':	fnSendCommand(pCMD,'DOWN')
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_VOL)){
							fnSendCommand(pCMD,fnPadTrailingChars(ITOA(ATOI(DATA.TEXT)+80),'0',3))
							TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myZones[z].LAST_VOL = ATOI(DATA.TEXT)+80
							myZones[z].VOL_PEND = TRUE
						}
					}
				}
			}
			CASE 'RAW':{	// Format "RAW-cmd,param"
				fnSendCommand(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),DATA.TEXT)
			}
		}
	}
}


DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	STACK_VAR INTEGER z
	FOR(z = 1; z <= 3; z++){
		STACK_VAR CHAR pCMD[10]
		SWITCH(z){
			CASE 1: pCMD = 'MV'
			CASE 2: pCMD = 'Z2'
			CASE 3: pCMD = 'Z3'
		}
		IF(myZones[z].VOL_PEND){
			fnSendCommand(pCMD,fnPadTrailingChars(ITOA(myZones[z].LAST_VOL),'0',2))
			myZones[z].VOL_PEND = FALSE
			TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER z
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZones); z++){
		[vdvZones[z],199] 	= ( myZones[z].MUTE )
		SEND_LEVEL vdvZones[z],1,myZones[z].VOL_dB
	}
	[vdvZones[1],251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvZones[1],252] = (TIMELINE_ACTIVE(TLID_COMMS))

}