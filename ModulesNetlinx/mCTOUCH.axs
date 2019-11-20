MODULE_NAME='mCTOUCH'(DEV vdvControl, DEV dvRS232)

INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_LOCKOUT = 3
DEFINE_VARIABLE
INTEGER DEBUG = 0
INTEGER POWER
INTEGER doPOLL = FALSE
LONG TLT_COMMS[] 		= {120000}
LONG TLT_POLL[]  		= { 45000}
LONG TLT_LOCKOUT[]  	= { 10000}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[20]){
	STACK_VAR CHAR toSend[20]
	toSend = "$A9,pDATA,$8A"
	fnDebug('AMX->CTOUCH', toSend);
	SEND_STRING dvRS232, toSend
	fnInitPoll()
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	IF(doPOLL){
		SEND_STRING dvRS232, 'Q'
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 38400 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		fnDebug('CTOUCH->AMX', DATA.TEXT);
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'POLL':	doPOLL = (DATA.TEXT == 'TRUE')
				}
			}
			CASE 'INPUT': fnSendCommand("DATA.TEXT,'!'")
			CASE 'POWER':{
				IF(!TIMELINE_ACTIVE(TLID_LOCKOUT)){
					SWITCH(DATA.TEXT){
						CASE 'ON': 		POWER = TRUE
						CASE 'OFF':		POWER = FALSE
						CASE 'TOGGLE':	POWER = !POWER
					}
					SWITCH(POWER){
						CASE TRUE: fnSendCommand("$D7")
						CASE FALSE:fnSendCommand("$08,$F7,$D7")
					}
					TIMELINE_CREATE(TLID_LOCKOUT,TLT_LOCKOUT,LENGTH_ARRAY(TLT_LOCKOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (POWER)
}
