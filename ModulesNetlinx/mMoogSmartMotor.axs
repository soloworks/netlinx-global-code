MODULE_NAME='mMoogSmartMotor'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module for RS232 control
******************************************************************************/
DEFINE_TYPE STRUCTURE uMoog{

	CHAR    Rx[500]

	INTEGER DEBUG
	LONG    POSITION
}

DEFINE_CONSTANT

LONG TLID_POLL  = 1
LONG TLID_COMMS = 2
LONG TLID_BOOT  = 3

DEFINE_VARIABLE
LONG TLT_POLL[]  = {10000}
LONG TLT_COMMS[] = {45000}
VOLATILE uMoog myMoog
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myMoog.Rx
}
/******************************************************************************
	Polling Routines
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('RPT')	// Device Power Query
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
/******************************************************************************
	Data Send Routine
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(myMoog.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pToSend[]){
	fnDebug('->MOOG',"pToSend,$0D")
	// $80 is a flagged byte
	// Message
	// $20 as space is send terminator
   SEND_STRING dvRS232, "$80,pToSend,$20"
	fnInitPoll()
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug('MOOG->',DATA.TEXT)
	GET_BUFFER_CHAR(DATA.TEXT)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'RPT':{	// Position Response
			myMoog.POSITION = ATOI(pDATA)
		}
	}
}
/******************************************************************************
	Physical Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
   ONLINE:{
		SEND_COMMAND dvRS232, 'SET BAUD 9600,N,8,1 485 DISABLE'
		fnPoll()
   }
	STRING:{
		fnDebug('MOOG_RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myMoog.Rx,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMoog.Rx,"$0D",1),1))
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
/******************************************************************************
	Virtual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
   COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						myMoog.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'POSITION':{
				fnSendCommand("'PT=',DATA.TEXT")
				fnSendCommand('G')
			}
			CASE 'MOVE':{
				SWITCH(DATA.TEXT){
					CASE 'STOP':fnSendCommand('X')
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'CLEAR_FLAGS':fnSendCommand('ZS')
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
   }
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/
