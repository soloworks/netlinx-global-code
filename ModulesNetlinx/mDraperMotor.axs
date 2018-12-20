MODULE_NAME='mDraperMotor'(DEV vdvControl,DEV dvDevice)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Draper Motor Control
	Tested against LVC-IV
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL  = 1
LONG TLID_COMMS = 2
DEFINE_VARIABLE
LONG TLT_POLL[] = {15000}
LONG TLT_COMMS[] = {45000}

DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	SEND_COMMAND dvDevice,pDATA
	fnInitPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$9A,$00,$00,$00,$CC,$CC")
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
		SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
	}
	STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'MOTOR':{
				SWITCH(DATA.TEXT){
					CASE 'UP':		fnSendCommand("$9A,$01,$01,$00,$0A,$DD,$D7")
					CASE 'DOWN':	fnSendCommand("$9A,$01,$01,$00,$0A,$CC,$C6")
					CASE 'STOP':	fnSendCommand("$9A,$01,$01,$00,$0A,$EE,$E4")
				}
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
