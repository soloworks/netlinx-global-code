MODULE_NAME='mOppoDVD'(DEV vdvControl, DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 07/19/2013  AT: 14:54:14        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Types & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uPlayer{
	INTEGER POWER
	CHAR SUBS[30]
	CHAR TITLE[3]
	CHAR CHAPTER[3]
	CHAR UTC_TYPE[1]
	CHAR UTC_TIME[8]
}	
DEFINE_TYPE STRUCTURE uCOMMS{
	CHAR RX[500]
	INTEGER DEBUG
}
DEFINE_CONSTANT
LONG TLID_POLL 	= 1
LONG TLID_COMMS 	= 2

DEFINE_VARIABLE
uPlayer myOppoPlayer
uCOMMS  myOppoComms

LONG 	  TLT_POLL[]  = { 15000 }
LONG 	  TLT_COMMS[] = { 45000 }
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myOppoComms.RX
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(myOppoComms.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myOppoComms.RX,"$0D",1),1))
		}
		IF(DATA.TEXT[1] == '@'){
			IF(!TIMELINE_ACTIVE(TLID_COMMS)){ fnSendCommand('SVM','3') }
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[],CHAR pPARAM[]){
	STACK_VAR CHAR toSend[25]
	toSend = "'#',pCMD"
	IF(LENGTH_ARRAY(pPARAM)){ toSend = "toSend,' ',pPARAM" }
	fnDebug('->OPPO',"toSend,$0D")
	SEND_STRING dvRS232, "toSend,$0D"
	fnInitPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnDebug('->OPPO',"'#QPW',$0D")
	SEND_STRING dvRS232, "'#QPW',$0D"
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug('OPPO->',pDATA)
	IF(GET_BUFFER_CHAR(pDATA) != '@'){RETURN}
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'QPW':{ 
			myOppoPlayer.POWER = (pDATA == 'OK ON')
		}
		CASE 'PON':{ myOppoPlayer.POWER = TRUE }
		CASE 'POF':{ myOppoPlayer.POWER = FALSE }
		CASE 'UPW':{ myOppoPlayer.POWER = ATOI(pDATA) }
		CASE 'UST':{ myOppoPlayer.SUBS = pDATA }
		CASE 'UTC':{
			myOppoPlayer.TITLE    = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			myOppoPlayer.CHAPTER  = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			myOppoPlayer.UTC_TYPE = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			myOppoPlayer.UTC_TIME = pDATA
			SWITCH(myOppoPlayer.UTC_TYPE){
				CASE 'T':SEND_STRING vdvControl, "'TIME-Elapsed: ',  myOppoPlayer.UTC_TIME"
				CASE 'X':SEND_STRING vdvControl, "'TIME-Remaining: ',myOppoPlayer.UTC_TIME"
			}
		}
	}
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myOppoComms.DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Device Control Code
******************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvControl,0]{
	ON:{
		SWITCH(CHANNEL.CHANNEL){
			CASE 45:		fnSendCommand('NUP','')
			CASE 46:		fnSendCommand('NDN','')
			CASE 47:		fnSendCommand('NLT','')
			CASE 48:		fnSendCommand('NRT','')
			CASE 49:		fnSendCommand('SEL','')
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	 COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':myOppoComms.DEBUG = ATOI(DATA.TEXT)
				}
			}
			CASE 'TIME':{
				SWITCH(DATA.TEXT){
					CASE 'REMAIN':fnSendCommand('STC','T')
					CASE 'ELAPSE':fnSendCommand('STC','X')
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT,'')
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': { fnSendCommand('PON','');myOppoPlayer.POWER = TRUE }
					CASE 'OFF':{ fnSendCommand('POF','');myOppoPlayer.POWER = FALSE }
				}
			}
			CASE 'MENU':{
				SWITCH(DATA.TEXT){
					CASE 'UP':			fnSendCommand('NUP','')
					CASE 'RIGHT':		fnSendCommand('NRT','')
					CASE 'LEFT':		fnSendCommand('NLT','')
					CASE 'DOWN':		fnSendCommand('NDN','')
					CASE 'ENTER':		fnSendCommand('SEL','')
					CASE 'MENU':		fnSendCommand('POP','')
					CASE 'TOP':			fnSendCommand('TTL','')
					CASE 'HOME':		fnSendCommand('HOM','')
					CASE 'SUBTITLE':	fnSendCommand('SUB','')
					CASE 'RETURN':		fnSendCommand('RET','')
					CASE 'RED':			fnSendCommand('RED','')
					CASE 'GREEN':		fnSendCommand('GRN','')
					CASE 'YELLOW':		fnSendCommand('YLW','')
					CASE 'BLUE':		fnSendCommand('BLU','')
					CASE 'DISPLAY':	fnSendCommand('OSD','')
					CASE 'POPUP':		fnSendCommand('POP','')
				}
			}
			CASE 'TRANSPORT':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY':		fnSendCommand('PLA','')
					CASE 'PAUSE':		fnSendCommand('PAU','')
					CASE 'STOP':		fnSendCommand('STP','')
					CASE 'SKIP+':		fnSendCommand('NXT','')
					CASE 'SKIP-':		fnSendCommand('PRE','')
					CASE 'SCAN+': 		fnSendCommand('FWD','')
					CASE 'SCAN-': 		fnSendCommand('REV','')
				}
			}
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myOppoPlayer.POWER)
}