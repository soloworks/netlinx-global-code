MODULE_NAME='mLutronGRX'(DEV vdvControl[], DEV dvRS232)
INCLUDE 'CustomFunctions'

DEFINE_CONSTANT
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2

DEFINE_VARIABLE
CHAR cIncBuffer[500]

LONG TLT_POLL[] 		= {20000}	// Poll Time
LONG TLT_COMMS[]		= {90000}	// Comms Timeout


/******************************************************************************
	Polling Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand("':G'")
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{	// Poll Device
	fnPoll()
}

DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	SEND_STRING dvRS232, "pCMD,$0D"
	fnInitPoll()
}
/******************************************************************************
	Communciation
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, cIncBuffer
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, "'SET BAUD 9600, N, 8, 1 485 Disable'"
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(cIncBuffer,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cIncBuffer,"$0D,$0A",1),1))
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR _Unit[1]
		_Unit = ITOHEX(GET_LAST(vdvControl))
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SCENE':fnSendCommand("':A',DATA.TEXT,_Unit")
			CASE 'RAMP':{
				SWITCH(DATA.TEXT){
					CASE 'UP':		fnSendCommand("':B',_Unit,'12'")
					CASE 'DN':		fnSendCommand("':D',_Unit,'12'")
					CASE 'STOPUP':	fnSendCommand("':B',_Unit")
					CASE 'STOPDN':	fnSendCommand("':D',_Unit")
				}
			}
		}
	}
}

(** Code specific to SubSea7 London, needs ammending to cover all possiblities **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pcCMD[255]){
	STACK_VAR INTEGER iROOM
	SWITCH(GET_BUFFER_CHAR(pcCMD)){
		CASE 'Q':iROOM = 1
		CASE 'I':iROOM = 2
	}
	IF(iROOM){
		SEND_STRING vdvControl[iROOM], "'KEYPAD-',ITOA(ATOI(DATA.TEXT))"
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}