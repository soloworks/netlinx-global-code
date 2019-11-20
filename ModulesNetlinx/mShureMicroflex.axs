MODULE_NAME='mShureMicroflex'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Shure Microflex Module
	By Solo Control Ltd (www.solocontrol.co.uk)
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uShure{
	// Comms
	INTEGER 	DEBUG							// Debugging Mode
	CHAR 		Rx[2000]						// Receieve Buffer
	CHAR 		Tx[2000]						// Transmit Buffer
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	PEND							//
	INTEGER 	CONN_STATE					//
	// State
	CHAR		DEV_ID[50]
	CHAR		MODEL[50]
	CHAR		SERIAL_NO[50]
	CHAR		MAC_ADD[50]
	INTEGER 	BUTTON_PUSHED
	INTEGER	CUR_PRESET
	INTEGER	DES_PRESET
	INTEGER	MUTE_STATE
	INTEGER  LED_STATE_MUTED
	INTEGER  LED_STATE_UNMUTED
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
// Timeline IDs
LONG TLID_POLL		= 1
LONG TLID_RETRY	= 2
LONG TLID_COMMS	= 3

DEFINE_CONSTANT
// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

DEFINE_CONSTANT
// MIC LED States
INTEGER FLASHING  = 3

/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uShure	myShure

LONG 		TLT_POLL[] 	= { 45000 }
LONG 		TLT_COMMS[] = { 90000 }
LONG 		TLT_RETRY[]	= {  5000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myShure.Rx
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	IF(myShure.CONN_STATE == CONN_STATE_CONNECTED){
		fnDebug(FALSE,'->Shure',"'< ',pCMD,' >'")
		SEND_STRING dvDevice, "'< ',pCMD,' >'"
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myShure.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myShure.IP_HOST == ''){
		fnDebug(TRUE,'Shure Host','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Shure on ',"myShure.IP_HOST,':',ITOA(myShure.IP_PORT)")
		myShure.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myShure.IP_HOST, myShure.IP_PORT, IP_TCP)
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

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	pDATA = MID_STRING(pDATA,3,LENGTH_ARRAY(pDATA)-4)
	fnDebug(FALSE,'Shure->',pDATA)

	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'REP':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'CONTROL_MAC_ADDR':{
					IF(myShure.MAC_ADD != fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))){
						myShure.MAC_ADD = fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))
						SEND_STRING vdvControl,"'PROPERTY-META,NET_MAC,',myShure.MAC_ADD"
					}
				}
				CASE 'DEVICE_ID':{
					IF(myShure.DEV_ID != fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))){
						myShure.DEV_ID = fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))
						SEND_STRING vdvControl,"'PROPERTY-META,DEV_ID,',myShure.DEV_ID"
					}
				}
				CASE 'SERIAL_NUM':{
					IF(myShure.SERIAL_NO != fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))){
						myShure.SERIAL_NO = fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))
						SEND_STRING vdvControl,"'PROPERTY-META,SERIALNO,',myShure.SERIAL_NO"
					}
				}
				CASE 'MODEL':{
					IF(myShure.MODEL != fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))){
						myShure.MODEL = fnRemoveWhiteSpace(MID_STRING(pDATA,2,LENGTH_ARRAY(pDATA)-2))
						SEND_STRING vdvControl,"'PROPERTY-META,MAKE,SHURE'"
						SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myShure.MODEL"
					}
				}
				CASE 'MUTE_BUTTON_STATUS':{
					SWITCH(pDATA){
						CASE 'ON':	myShure.BUTTON_PUSHED = TRUE
						CASE 'OFF':	myShure.BUTTON_PUSHED = FALSE
					}
				}
				CASE 'DEVICE_AUDIO_MUTE':{
					SWITCH(pDATA){
						CASE 'ON':	myShure.MUTE_STATE = TRUE
						CASE 'OFF':	myShure.MUTE_STATE = FALSE
					}
				}
				CASE 'LED_STATE_MUTED':{
					SWITCH(pDATA){
						CASE 'ON':			myShure.LED_STATE_MUTED = TRUE
						CASE 'OFF':			myShure.LED_STATE_MUTED = FALSE
						CASE 'FLASHING':	myShure.LED_STATE_MUTED = FLASHING
					}
				}
				CASE 'LED_STATE_UNMUTED':{
					SWITCH(pDATA){
						CASE 'ON':			myShure.LED_STATE_MUTED = TRUE
						CASE 'OFF':			myShure.LED_STATE_MUTED = FALSE
						CASE 'FLASHING':	myShure.LED_STATE_MUTED = FLASHING
					}
				}
				CASE 'PRESET':{
					myShure.CUR_PRESET = ATOI(pDATA)
					IF(myShure.DES_PRESET && myShure.CUR_PRESET != myShure.DES_PRESET){
						fnSendCommand("'SET PRESET ',FORMAT('%02d',myShure.DES_PRESET)")
					}
					myShure.DES_PRESET = 0
				}
			}
		}
	}

	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}


DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand('GET DEVICE_ID')
}
DEFINE_FUNCTION fnInit(){
	fnSendCommand('GET DEVICE_ID')
	fnSendCommand('GET PRESET')
	fnSendCommand('GET 0 ALL')
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myShure.CONN_STATE	= CONN_STATE_CONNECTED
		fnInit()
	}
	OFFLINE:{
		myShure.CONN_STATE	= CONN_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myShure.CONN_STATE = CONN_STATE_OFFLINE
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
		fnDebug(TRUE,"'Shure IP Error:[',myShure.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myShure.RX,"'>'",1)){
			fnProcessFeedback(REMOVE_STRING(myShure.RX,"'>'",1))
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':fnInit()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myShure.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myShure.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myShure.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myShure.IP_HOST = DATA.TEXT
							myShure.IP_PORT = 2202
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'PRESET':{
				myShure.DES_PRESET = ATOI(DATA.TEXT)
				fnSendCommand("'SET PRESET ',FORMAT('%02d',ATOI(DATA.TEXT))")
			}
			CASE 'RAW':{
				IF(myShure.CONN_STATE == CONN_STATE_CONNECTED){
					fnDebug(FALSE,'->Shure',"'< ',DATA.TEXT,' >'")
					SEND_STRING dvDevice, "'< ',DATA.TEXT,' >'"
				}
			}
			CASE 'MUTE':
			CASE 'MICMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnSendCommand('SET DEVICE_AUDIO_MUTE ON')
					CASE 'OFF':	fnSendCommand('SET DEVICE_AUDIO_MUTE OFF')
				}
			}
			CASE 'LEDS_STATE':
			CASE 'LED_STATE':
			CASE 'LEDSTATE':{
				STACK_VAR CHAR pSTATE[7]
				pSTATE = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				SWITCH(DATA.TEXT){
					CASE 'ON':		fnSendCommand("'SET LED_STATE_',pSTATE,' ON'")
					CASE 'OFF':		fnSendCommand("'SET LED_STATE_',pSTATE,' OFF'")
					CASE 'FLASH':	fnSendCommand("'SET LED_STATE_',pSTATE,' FLASHING'")
				}
			}
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,1]		= (myShure.BUTTON_PUSHED)
	SEND_LEVEL vdvControl,2,myShure.CUR_PRESET
	[vdvControl,198]	= (myShure.MUTE_STATE)
	[vdvControl,251] 	= (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] 	= (TIMELINE_ACTIVE(TLID_COMMS))
}