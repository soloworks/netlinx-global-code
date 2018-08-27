MODULE_NAME='mTascamDVD'(DEV vdvControl,DEV tp[], DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
Tascam DVD

******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uDVD{
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
uDVD   myDVD
LONG TLT_POLL[]	= {15000}
LONG TLT_COMMS[]	= {180000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myDVD.Rx
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA' 
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'POWER':{
				
			}
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
}
DEFINE_FUNCTION fnSendCommand(CHAR pCODE[3],CHAR pCMD[1],CHAR pPARAM[8]){
	STACK_VAR CHAR toSend[100]
	STACK_VAR INTEGER CHK
	STACK_VAR INTEGER x
	toSend = "'>',pCODE,pCMD,fnPadTrailingChars(pPARAM,' ',8)"
	FOR(x = 1; x <= LENGTH_ARRAY(toSend); x++){
		CHK = CHK + toSend[x]
	}
	toSend = "toSend,RIGHT_STRING(ITOHEX(CHK),2)"
	SEND_STRING dvRS232,"$02,toSend,$03"
	fnInitPoll()
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myDVD.DEBUG){
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
	fnSendCommand('MOD','c','')
}

/******************************************************************************
	TP Events
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE 101: fnSendCommand('PLY','c','FWD')	// Play
			CASE 102: fnSendCommand('PLY','c','PAU')	// Pause
			CASE 103: fnSendCommand('STP','c','')		// Stop
			CASE 104: fnSendCommand('SKP','c','N')		// Skip+
			CASE 105: fnSendCommand('SKP','c','P')		// Skip-
			CASE 106: fnSendCommand('PLY','c','FFW')	// Scan+
			CASE 107: fnSendCommand('PLY','c','FBW')	// Scan-
			     
			CASE 108: fnSendCommand('MNU','c','T')		// Menu Title
			CASE 109: fnSendCommand('MNU','c','R')		// Menu Root
			     
			CASE 110: fnSendCommand('NAV','c','UP')	// Menu UP
			CASE 111: fnSendCommand('NAV','c','DWN')	// Menu DN
			CASE 112: fnSendCommand('NAV','c','LFT')	// Menu LT
			CASE 113: fnSendCommand('NAV','c','RIT')	// Menu RT
			CASE 114: fnSendCommand('NAV','c','ENT')	// Menu SEL
			CASE 115: fnSendCommand('NAV','c','RTN')	// Menu Return
			     
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
