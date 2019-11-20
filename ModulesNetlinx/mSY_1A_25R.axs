MODULE_NAME='mSY_1A_25R'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	SY 1A 25R Amplifier Module
******************************************************************************/
/******************************************************************************
	Module  Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uSYAmp{
	INTEGER  MUTE
	INTEGER	GAIN
	INTEGER  DEBUG
	CHAR 	   Rx[500]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_COMMS	= 2

DEFINE_VARIABLE
uSYAmp   mySYAmp
LONG TLT_POLL[]	= {  15000,1000 }
LONG TLT_COMMS[]	= { 180000 }
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, mySYAmp.Rx
}
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND dvDevice, 'SET MODE DATA'
		SEND_COMMAND dvDevice, 'SET BAUD 57600 N 8 1 485 DISABLE'
		fnPoll(1)
		WAIT 10{fnPoll(2)}
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(mySYAmp.Rx,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySYAmp.Rx,"$0D",1),1))
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE, 'RANGE-0,100'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		mySYAmp.MUTE = TRUE
					CASE 'OFF':		mySYAmp.MUTE = FALSE
					CASE 'TOGGLE':	mySYAmp.MUTE = !mySYAmp.MUTE
				}
				SWITCH(mySYAmp.MUTE){
					CASE TRUE:	fnSendCommand('MUTE=ON')
					CASE FALSE:	fnSendCommand('MUTE=OFF')
				}
				fnSendCommand("'D02*',ITOA(mySYAmp.MUTE),'GRPM'")
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':		fnSendCommand('VOL UP')
					CASE 'DEC':		fnSendCommand('VOL DOWN')
					DEFAULT:			fnSendCommand("'VOL=',fnPadLeadingChars(DATA.TEXT,'0',3)")
				}
			}
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)){
		CASE 'VOL':{
			mySYAmp.GAIN = ATOI(pDATA)
		}
		CASE 'MUTE':{
			SWITCH(pDATA){
				CASE 'ON':	mySYAmp.MUTE = TRUE
				CASE 'OFF':	mySYAmp.MUTE = FALSE
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION fnSendCommand(CHAR cmd[20]){
	SEND_STRING dvDevice, "cmd,$0D"
	fnInitPoll()
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(mySYAmp.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll(TIMELINE.SEQUENCE)
}
DEFINE_FUNCTION fnPoll(INTEGER pStage){
	SWITCH(pStage){
		CASE 1:fnSendCommand('VOL?')
		CASE 2:fnSendCommand('MUTE?')
	}
}

/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,199] = mySYAmp.MUTE
	SEND_LEVEL vdvControl,1,mySYAmp.GAIN

	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}