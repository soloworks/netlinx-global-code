MODULE_NAME='mInFocusProjector'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL	 = 2
LONG TLID_BOOT  = 3
DEFINE_VARIABLE
INTEGER DEBUG = 0
LONG TLT_COMMS[] = {60000} 
LONG TLT_POLL[]  = {15000}
LONG TLT_BOOT[]  = {2000}
LONG BAUD_RATE
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pToSend[255]){
	SEND_STRING dvRS232, pToSend
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
	SEND_STRING dvRS232, '(PWR?)'
}
/******************************************************************************
	Boot Handler
******************************************************************************/
DEFINE_FUNCTION fnBootDelay(){
	IF(TIMELINE_ACTIVE(TLID_BOOT)){TIMELINE_KILL(TLID_BOOT)}
	TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	SEND_COMMAND dvRS232, "'SET MODE DATA'"
	SEND_COMMAND dvRS232, "'SET BAUD ',ITOA(BAUD_RATE),' N 8 1 485 DISABLE'"
	fnPoll()
	fnInitPoll()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		IF(!BAUD_RATE){BAUD_RATE = 9600}
		fnBootDelay()
	}
	STRING:{
		fnDebug('InF->AMX', DATA.TEXT);
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
					CASE 'BAUD':{
						BAUD_RATE = ATOI(DATA.TEXT)
						fnBootDelay()
					}
				}
			}
			CASE 'INPUT': fnSendCommand("'(SRC',DATA.TEXT,')'")
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnSendCommand('(PWR1)')
					CASE 'OFF': fnSendCommand('(PWR0)')
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}