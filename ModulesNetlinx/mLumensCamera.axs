MODULE_NAME='mLumensCamera'(DEV vdvControl, DEV tpMain[], DEV dvDevice)
INCLUDE'CustomFunctions'
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL	 = 2

INTEGER btnDpad[] = {
	101,	// UP
	102,	//	DN
	103,	// LT
	104,	// RT
	105,	// UL
	106,	// UR
	107,	//	DL
	108	// DR
}

INTEGER btnZoom[] = {
	121,	// Zoom IN
	122	// Zoom OUT
}

INTEGER btnPresets[]={200,201,202,203,204,205,206,207,208,209,210}

DEFINE_VARIABLE
LONG TLT_COMMS[] = {60000}
LONG TLT_POLL[]  = {15000}
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE STRUCTURE uCamera{
	INTEGER 	CAMERA_ID
	INTEGER	DEBUG
	LONG		BAUD
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
uCamera myCamera
(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
DEFINE_FUNCTION fnSendCommand(CHAR cmd[]){
	SEND_STRING dvDevice, cmd
	fnInitPoll()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand("$88,$01,$02,$03,$FF")
}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myCamera.BAUD){
			myCamera.BAUD = 9600
		}
		SEND_COMMAND dvDevice, 'SET MODE DATA'
		SEND_COMMAND dvDevice, "'SET BAUD ',ITOA(myCamera.BAUD),' N 8 1 485 DISABLE'"
		fnInitPoll()
	}
	STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
//char 5 is pan speed, char 6 is tilt speed
DEFINE_EVENT BUTTON_EVENT[tpMain,btnDPad]{
	PUSH:{
		SWITCH(GET_LAST(btnDPad)){
			CASE 1:fnSendCommand("$88,$01,$06,$01,$06,$06,$03,$01,$FF")	// UP
			CASE 2:fnSendCommand("$88,$01,$06,$01,$06,$06,$03,$02,$FF")	//	DN
			CASE 3:fnSendCommand("$88,$01,$06,$01,$06,$06,$01,$03,$FF")	// LT
			CASE 4:fnSendCommand("$88,$01,$06,$01,$06,$06,$02,$03,$FF")	// RT
			CASE 5:fnSendCommand("$88,$01,$06,$01,$06,$06,$01,$01,$FF")	// UL
			CASE 6:fnSendCommand("$88,$01,$06,$01,$06,$06,$02,$01,$FF")	// UP
			CASE 7:fnSendCommand("$88,$01,$06,$01,$06,$06,$02,$02,$FF")	// DL
			CASE 8:fnSendCommand("$88,$01,$06,$01,$06,$06,$03,$03,$FF") // DR
		}
	}
	RELEASE:{
		fnSendCommand("$88,$01,$06,$01,$06,$06,$03,$03,$FF")	// STOP
	}
}

DEFINE_EVENT BUTTON_EVENT[tpMain,btnZoom]{
	PUSH:{
		SWITCH(GET_LAST(btnZoom)){
			CASE 1: 	fnSendCommand("$88,$01,$04,$07,$02,$FF")	// Zoom In
			CASE 2:	fnSendCommand("$88,$01,$04,$07,$03,$FF")	// Zoom Out
		}
	}
	RELEASE:{
		fnSendCommand("$88,$01,$04,$07,$00,$FF")	// Ztop
	}
}

DEFINE_VARIABLE

DEFINE_EVENT BUTTON_EVENT[tpMain,btnPresets]{
	PUSH:{
		fnSendCommand("$88,$01,$04,$3F,$02,GET_LAST(btnPresets)-1,$FF")
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						myCamera.BAUD 	= ATOI(DATA.TEXT)
						SEND_COMMAND dvDevice, 'SET MODE DATA'
						SEND_COMMAND dvDevice, "'SET BAUD ',ITOA(myCamera.BAUD),' N 8 1 485 DISABLE'"
						fnInitPoll()
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnSendCommand("$88,$01,$04,$00,$02,$FF")
					CASE 'OFF': fnSendCommand("$88,$01,$04,$00,$03,$FF")
				}
			}
			CASE 'SAVEPRESET':{
				fnSendCommand("$88,$01,$04,$3F,$01,ATOI(DATA.TEXT),$FF")
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}

