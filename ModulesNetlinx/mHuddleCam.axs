MODULE_NAME='mHuddleCam'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Huddlecam Camera Control


******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uHuddleCam{
	INTEGER	POWER
	INTEGER  DEBUG
	INTEGER	ID
	LONG 		BAUD
	CHAR 	   Rx[500]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_COMMS	= 2

DEFINE_VARIABLE
uHuddleCam myHuddleCam
LONG TLT_POLL[]	= {15000}
LONG TLT_COMMS[]	= {180000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myHuddleCam.Rx
	myHuddleCam.ID 	= 1
	myHuddleCam.BAUD 	= 9600
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, "'SET MODE DATA'"
		SEND_COMMAND DATA.DEVICE, "'SET BAUD ',ITOA(myHuddleCam.BAUD),',N,8,1,485 DISABLE'"
		fnPoll()
	}
	STRING:{
		WHILE(FIND_STRING(myHuddleCam.Rx,"$FF",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myHuddleCam.Rx,"$FF",1),1))
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':	myHuddleCam.BAUD = ATOI(DATA.TEXT)
					CASE 'ID':		myHuddleCam.ID = ATOI(DATA.TEXT)
					CASE 'DEBUG':	myHuddleCam.DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
			CASE 'CONTROL':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'PRESET':{
						SWITCH(DATA.TEXT){
							CASE 'HOME': fnSendCommand("$01,$06,$04")
							CASE 'RESET':fnSendCommand("$01,$06,$05")
						}
					}
					CASE 'PAN':{
						SWITCH(DATA.TEXT){
							CASE 'LEFT':  fnSendCommand("$01,$06,$01,$09,$07,$01,$03")
							CASE 'RIGHT': fnSendCommand("$01,$06,$01,$09,$07,$02,$03")
							CASE 'STOP':  fnSendCommand("$01,$06,$01,$09,$07,$03,$03")
						}
					}
					CASE 'TILT':{
						SWITCH(DATA.TEXT){
							CASE 'UP':   fnSendCommand("$01,$06,$01,$09,$07,$03,$01")
							CASE 'DOWN': fnSendCommand("$01,$06,$01,$09,$07,$03,$02")
							CASE 'STOP': fnSendCommand("$01,$06,$01,$09,$07,$03,$03")
						}
					}
					CASE 'ZOOM':{
						SWITCH(DATA.TEXT){
							CASE 'IN':   fnSendCommand("$01,$04,$07,$02")
							CASE 'OUT':  fnSendCommand("$01,$04,$07,$03")
							CASE 'STOP': fnSendCommand("$01,$04,$07,$00")
						}
					}
				}
			}
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){

	// Debug the Data
	fnDebug('CAM->',fnBytesToString(pDATA))

	// Protocol requires last command to be stored, and Tx Pend implmenetd
	// So feedback is limited to knowing commands are sending


	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[20]){
	SEND_STRING dvDevice, "$80+myHuddleCam.ID,pCMD,$FF"
	fnInitPoll()
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myHuddleCam.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$09,$04,$00")
}

/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = myHuddleCam.POWER
}

