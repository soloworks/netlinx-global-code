MODULE_NAME='mCleverTouchPro'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_TYPE STRUCTURE uCleverTouch{
	INTEGER DEBUG
	CHAR    Rx[200]

	INTEGER POWER
}
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
DEFINE_VARIABLE
uCleverTouch myCleverTouch
LONG TLT_COMMS[] 		= {120000}
LONG TLT_POLL[]  		= { 45000}
DEFINE_START{
	CREATE_BUFFER dvRS232, myCleverTouch.Rx
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(myCleverTouch.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[4]){
	STACK_VAR CHAR toSend[20]
	toSend = "$AA,$BB,$CC,pDATA,$DD,$EE,$FF"
	fnDebug('->CLEVERT', toSend);
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
	fnSendCommand("$01,$02,$00,$03")	// Power
	fnSendCommand("$03,$02,$00,$05")	// Volume
	fnSendCommand("$03,$03,$00,$06")	// Mute
	fnSendCommand("$02,$00,$00,$02")	// Source
	fnSendCommand("$09,$02,$00,$0B")	// PC Status
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		fnDebug('CTOUCH->', DATA.TEXT)
		WHILE(FIND_STRING(myCleverTouch.Rx,"$DD,$EE,$FF",1)){
			STACK_VAR CHAR pCMD[100]
			pCMD = REMOVE_STRING(myCleverTouch.Rx,"$DD,$EE,$FF",1)
			GET_BUFFER_STRING(pCMD,3)
			SWITCH(pCMD[1]){
				CASE $80:{	// POWER
					myCleverTouch.POWER = !pCMD[2]
				}
			}
		}
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
					CASE 'DEBUG': myCleverTouch.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		fnSendCommand("$01,$00,$00,$01")
					CASE 'OFF':		fnSendCommand("$01,$01,$00,$02")
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'HDMI1':fnSendCommand("$02,$06,$00,$08")
				}
			}
			CASE 'VMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		fnSendCommand("$07,$4E,$00,$55")
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myCleverTouch.POWER)
}

