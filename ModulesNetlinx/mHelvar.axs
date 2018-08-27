MODULE_NAME='mHelvar'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'

DEFINE_CONSTANT
LONG TLID_COMMS = 1

DEFINE_TYPE STRUCTURE uHelvar{
	CHAR Rx[500]
}

DEFINE_VARIABLE
uHelvar myHelvar
LONG TLT_COMMS[] = { 30000 }

DEFINE_START{
	CREATE_BUFFER dvDevice, myHelvar.Rx
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE: SEND_COMMAND dvDevice, "'SET BAUD 19200, N, 8, 1 485 Disable'"
	STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'BUTTON':{
				STACK_VAR CHAR pCMD[4]
				pCMD = "$03,$59,(ATOI(fnGetCSV(DATA.TEXT,1))*2)-1"
				SWITCH(fnGetCSV(DATA.TEXT,2)){
					CASE '1':pCMD = "pCMD,$40"
					CASE '2':pCMD = "pCMD,$41"
					CASE '3':pCMD = "pCMD,$42"
					CASE '4':pCMD = "pCMD,$43"
					CASE '5':pCMD = "pCMD,$45"
					CASE '6':pCMD = "pCMD,$46"
					CASE '7':pCMD = "pCMD,$47"
					CASE '0':pCMD = "pCMD,$44"
				}
				SEND_STRING dvDevice, pCMD
			}
		}
	}
}

(** Code specific to SubSea7 London, needs ammending to cover all possiblities **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pcCMD[255]){
	
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}