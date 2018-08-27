MODULE_NAME='mSmart'(DEV vdvControl, DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 06/07/2013  AT: 21:30:15        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
Smart Display Module
Tested against Smart Board 8070i, but should work on all including Projectors

Input List:
	VGA
	RGB/HV
	DVI
	Video[1|2]
	S_Video
	DVD/HD[1|2]
	DisplayPort
	HDMI[1|2]
******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uDisplay{
	INTEGER  POWER
	CHAR  	SOURCE[20]
	CHAR  	newSOURCE[20]
}
DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	CHAR 	   Tx[1000]
	CHAR 	   Rx[1000]
	INTEGER  DEBUG
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_COMMS	= 2
LONG TLID_PEND		= 3

DEFINE_VARIABLE
uComms   mySmartComms
uDisplay mySmartDisplay
LONG TLT_POLL[]	= {10000}
LONG TLT_COMMS[]	= {30000}
LONG TLT_PEND[]	= {5000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, mySmartComms.Rx
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA' 
		SEND_COMMAND dvRS232, 'SET BAUD 19200 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(mySmartComms.Rx,"$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySmartComms.Rx,"$0A",1),1))
		}
		IF(mySmartComms.Rx = '>'){
			TIMELINE_KILL(TLID_PEND)
			fnActualSend()
		}
	} 
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	WHILE(pDATA[LENGTH_ARRAY(pDATA)] == $0D){
		pDATA = fnStripCharsRight(pDATA,1)
	}
	fnDebug('SMA->AMX', pDATA)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)){
		CASE 'powerstate':{
			SWITCH(pDATA){
				CASE 'on': mySmartDisplay.POWER = TRUE
				CASE 'off':mySmartDisplay.POWER = FALSE
			}
		}
		CASE 'input':{
			mySmartDisplay.SOURCE = pDATA
			IF(mySmartDisplay.SOURCE == mySmartDisplay.newSOURCE){
				mySmartDisplay.newSOURCE = ''
			}
			IF(mySmartDisplay.SOURCE != mySmartDisplay.newSOURCE && LENGTH_ARRAY(mySmartDisplay.newSOURCE)){
				fnSendCommand("'set input=',mySmartDisplay.newSOURCE")
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': mySmartComms.DEBUG 	= ATOI(DATA.TEXT);
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'TOGGLE':{ mySmartDisplay.POWER = !mySmartDisplay.POWER }
					CASE 'ON':{  mySmartDisplay.POWER = TRUE  }
					CASE 'OFF':{ mySmartDisplay.POWER = FALSE }
				}
				SWITCH(mySmartDisplay.POWER){
					CASE TRUE:{  fnSendCommand('set powerstate =on') }
					CASE FALSE:{ fnSendCommand('set powerstate =off') }
				}
			}
			CASE 'INPUT':{				
				mySmartDisplay.newSOURCE = DATA.TEXT
				IF(mySmartDisplay.POWER){
					fnSendCommand("'set input=',mySmartDisplay.newSOURCE")
				}
				ELSE{
					fnSendCommand('on')
					//IF(TIMELINE_ACTIVE(TLID_INPUT))TIMELINE_KILL(TLID_INPUT)
					//TIMELINE_CREATE(TLID_INPUT,TLT_Input,LENGTH_ARRAY(TLT_Input),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
		}
	}
}
	
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	mySmartComms.Tx = "mySmartComms.Tx,pCMD,$0D"
	fnActualSend()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendQuery(CHAR pCMD[]){
	mySmartComms.Tx = "mySmartComms.Tx,'get ',pCMD,$0D"
	fnActualSend()
}
DEFINE_FUNCTION fnActualSend(){
	IF(!TIMELINE_ACTIVE(TLID_PEND) && FIND_STRING(mySmartComms.Tx,"$0D",1)){
		SEND_STRING dvRS232,REMOVE_STRING(mySmartComms.Tx,"$0D",1)
		TIMELINE_CREATE(TLID_PEND,TLT_PEND,LENGTH_ARRAY(TLT_PEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_PEND]{
	mySmartComms.Tx = ''
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(mySmartComms.DEBUG = 1){
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
	fnSendQuery('powerstate')
	fnSendQuery('input')
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (mySmartDisplay.POWER)
}