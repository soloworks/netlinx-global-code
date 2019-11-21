MODULE_NAME='mAtlonaHDVS'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL	 = 2
DEFINE_VARIABLE
INTEGER DEBUG = 0
INTEGER doPOLL = TRUE
LONG TLT_COMMS[] = {60000}
LONG TLT_POLL[]  = {15000}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pToSend[255]){
	SEND_STRING dvRS232, "pToSend,$0D"
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
		SEND_STRING dvRS232, "'WP_IdentifyTx[?]$',$0D"
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 115200 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		fnDebug('ATL->AMX', DATA.TEXT);
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
			CASE 'RAW':fnSendCommand(DATA.TEXT)
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'HDMI':fnSendCommand('WP_Input[Hdmi]$')
					CASE 'VGA': fnSendCommand('WP_Input[Vga]$')
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
