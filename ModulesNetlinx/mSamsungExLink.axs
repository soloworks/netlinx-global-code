MODULE_NAME='mSamsungExLink'(DEV vdvControl, DEV dvExLink)
/******************************************************************************
	Samsung Residential ExLink Control
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Components
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL	 = 2
LONG TLID_VOL	 = 3

DEFINE_TYPE STRUCTURE uExLink{
	CHAR    LAST_SENT[3]
	INTEGER POWER
	INTEGER VOL
	INTEGER MUTE
	
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
}

DEFINE_VARIABLE
uExLink myExLink
LONG TLT_COMMS[] = { 30000 }
LONG TLT_POLL[]  = { 15000 }
LONG TLT_VOL[]			= {  150}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$F0,$00,$00",$00)
}
/******************************************************************************
	Physical Device Handling
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR CMD[3],INTEGER VAL){
	STACK_VAR CHAR toSend[10]
	STACK_VAR INTEGER CHK
	STACK_VAR INTEGER x
	toSend = "$08,$22,CMD,VAL"
	FOR(x = 1; x <= LENGTH_ARRAY(toSend); x++){
		CHK = CHK + toSend[x]
	}
	CHK = $FF-CHK+1
	toSend = "toSend,CHK"
	myExLink.LAST_SENT = CMD
	SEND_STRING dvExLink,toSend
	fnInitPoll()
}
DEFINE_EVENT DATA_EVENT[dvExLink]{
	ONLINE:{
		IF(dvExLink.NUMBER){
			SEND_COMMAND dvExLink, "'SET BAUD 9600, N, 8, 1 485 Disable'"
		}
		fnPoll()
	}
	STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[10]){
	SELECT{
		// Power Query
		ACTIVE(myExLink.LAST_SENT == "$F0,$00,$00"):{
			myExLink.POWER = pDATA[1]-1
		}
	}
}
/******************************************************************************
	Virtual Device Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'PROPERTY-RANGE,0,100'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'POWER':{
				// Set value
				SWITCH(DATA.TEXT){
					CASE 'ON':     myExLink.POWER = TRUE
					CASE 'OFF':    myExLink.POWER = FALSE
					CASE 'TOGGLE': myExLink.POWER = !myExLink.POWER
				}
				// Send Command
				fnSendCommand("$00,$00,$00",myExLink.POWER+1)
			}
			CASE 'BUTTON':{
				SWITCH(DATA.TEXT){
					CASE 'UP':       fnSendCommand("$0D,$00,$00",$60)
					CASE 'DOWN':     fnSendCommand("$0D,$00,$00",$61)
					CASE 'LEFT':     fnSendCommand("$0D,$00,$00",$65)
					CASE 'RIGHT':    fnSendCommand("$0D,$00,$00",$62)
					CASE 'MENU':     fnSendCommand("$0D,$00,$00",$1A)
					CASE 'INTERNET': fnSendCommand("$0D,$00,$00",$93)
					CASE 'ENTER':    fnSendCommand("$0D,$00,$00",$68)
					CASE 'EXIT':     fnSendCommand("$0D,$00,$00",$2D)
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'HDMI1':    fnSendCommand("$0A,$00,$05",$00)
					CASE 'HDMI2':    fnSendCommand("$0A,$00,$05",$01)
					CASE 'HDMI3':    fnSendCommand("$0A,$00,$05",$02)
					CASE 'HDMI4':    fnSendCommand("$0A,$00,$05",$03)
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':	fnSendCommand("$01,$00,$01",$00)
					CASE 'DEC':	fnSendCommand("$01,$00,$02",$00)
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_VOL)){
							fnSendCommand("$01,$00,$00",ATOI(DATA.TEXT))
							myExLink.VOL = ATOI(DATA.TEXT)
							TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myExLink.LAST_VOL = ATOI(DATA.TEXT)
							myExLink.VOL_PEND = TRUE
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myExLink.VOL_PEND){
		fnSendCommand("$01,$00,$00",myExLink.LAST_VOL)
		myExLink.VOL = myExLink.LAST_VOL
		myExLink.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myExLink.VOL
	[vdvControl,199] = (myExLink.MUTE)
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myExLink.POWER)
}

/******************************************************************************
	EoF
******************************************************************************/
