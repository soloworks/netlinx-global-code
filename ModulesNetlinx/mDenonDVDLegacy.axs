MODULE_NAME='mDenonDVDLegacy'(DEV vdvControl,DEV tp[], DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module for Legacy RS232 Denon players with nasty Byte based protocol
******************************************************************************/
DEFINE_TYPE STRUCTURE uDenonDVD{
	INTEGER DEBUG
	INTEGER POWER
}
DEFINE_CONSTANT
LONG TLID_POLL  = 1
LONG TLID_COMMS = 2
DEFINE_VARIABLE
LONG TLT_POLL[]  = {10000}
LONG TLT_COMMS[] = {45000}
VOLATILE uDenonDVD myDenonDVD
/******************************************************************************
	Polling Routines
******************************************************************************/
DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$30,$00,$00,$00,$00,$00",FALSE)	// Device Status Query
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
/******************************************************************************
	Data Send Routine
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(myDenonDVD.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', fnBytesToString(MsgData)"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pBytes[], INTEGER pResetPoll){

	STACK_VAR INTEGER nCKS
	STACK_VAR INTEGER nHigh
	STACK_VAR INTEGER nLow
	STACK_VAR INTEGER x
	
	//Work out the stupid checksum
	FOR(x =1; x <= LENGTH_ARRAY(pBytes); x++){
		nCKS = nCKS + pBytes[x]
	}
	nCKS= nCKS + $03
	
	nHigh = (nCKS & $F0)/16
	nLow = nCKS & $0F
	
	IF(nHigh>$09){ nHigh=nHigh+55} ELSE { nHigh=nHigh+48 }
	
	IF(nLow>$09){ nLow=nLow+55 } ELSE { nLow=nLow+48}
	
	fnDebug('->DVD',"$02,pBytes,$03,nHigh,nLow")
   SEND_STRING dvRS232, "$02,pBytes,$03,nHigh,nLow"
	IF(pResetPoll){
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE $30:{	// Status Response
			
		}
	}
}
/******************************************************************************
	Physical Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
   ONLINE:{
      SEND_COMMAND DATA.DEVICE, "'SET BAUD 9600,E,8,1 485 DISABLE'"
		fnPoll()
		fnInitPoll()
   }
	STRING:{
		fnDebug('DVD->',DATA.TEXT)
		GET_BUFFER_CHAR(DATA.TEXT)	// Eat $02
		fnProcessFeedback(fnStripCharsRight(DATA.TEXT,3)	// Eat CHKx2 & $03
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	TouchPanel Control
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE 01:fnSendCommand("$40,$00,$00,$00,$00,$00",TRUE)	// Play
			CASE 02:fnSendCommand("$41,$00,$00,$00,$00,$00",TRUE)	// Stop
			CASE 03:fnSendCommand("$42,$00,$00,$00,$00,$00",TRUE)	// Pause
			CASE 04:fnSendCommand("$43,$2B,$00,$00,$00,$00",TRUE)	// SKIP+
			CASE 05:fnSendCommand("$43,$2D,$00,$00,$00,$00",TRUE)	// SKIP-
			CASE 06:fnSendCommand("$44,$2B,$00,$00,$00,$00",TRUE)	// FFWD
			CASE 07:fnSendCommand("$44,$2D,$00,$00,$00,$00",TRUE)	// RWND
			CASE 45:fnSendCommand("$4D,$31,$00,$00,$00,$00",TRUE)	// Left
			CASE 46:fnSendCommand("$4D,$33,$00,$00,$00,$00",TRUE)	// Right
			CASE 47:fnSendCommand("$4D,$32,$00,$00,$00,$00",TRUE)	// Up
			CASE 48:fnSendCommand("$4D,$34,$00,$00,$00,$00",TRUE)	// Down
			CASE 49:fnSendCommand("$4E,$00,$00,$00,$00,$00",TRUE)	// Select
			CASE 71:fnSendCommand("$50,$00,$00,$00,$00,$00",TRUE)	// Home
			CASE 72:fnSendCommand("$46,$00,$00,$00,$00,$00",TRUE)	// Top Menu
			CASE 73:fnSendCommand("$47,$00,$00,$00,$00,$00",TRUE)	// Menu
			CASE 75:fnSendCommand("$48,$00,$00,$00,$00,$00",TRUE)	// Return
			CASE 76:fnSendCommand("$69,$00,$00,$00,$00,$00",TRUE)	// Repeat
			
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
						myDenonDVD.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		{fnSendCommand("$20,$00,$00,$00,$00,$00",TRUE)}
					CASE 'OFF':		{fnSendCommand("$21,$00,$00,$00,$00,$00",TRUE)}
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
