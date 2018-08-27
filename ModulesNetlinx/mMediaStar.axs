MODULE_NAME='mMediaStar'(DEV vdvControl, DEV tp[], DEV dvIPTV)
/******************************************************************************
	Cabletime Mediastar 780 Control Module
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uState{
	INTEGER 	  CHAN_NO
}
DEFINE_TYPE STRUCTURE uConn{
	(** IP Comms Control **)
	INTEGER STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	INTEGER isIP
	(** General Comms Control **)
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
	CHAR 	  PASSWORD[20]
}
DEFINE_TYPE STRUCTURE uPanel{
	CHAR    CHAN[3]
}
DEFINE_TYPE STRUCTURE uMediaStar{
	uState  STATE
	CHAR	  MODEL[25]
	uConn   CONN
	uPanel  PANEL[5]
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER CONN_STATE_OFFLINE		  = 0
INTEGER CONN_STATE_CONNECTING	  = 1
INTEGER CONN_STATE_NEGOTIATING  = 2
INTEGER CONN_STATE_CONNECTED	  = 3
(** Timelines **)
LONG TLID_RETRY		= 1
LONG TLID_COMMS		= 2
LONG TLID_CHAN			= 3
LONG TLID_POLL			= 4
/******************************************************************************
	Module Variable
******************************************************************************/
DEFINE_VARIABLE
(** General **)
uMediaStar   myMediaStar
(** Timeline Times **)
LONG TLT_RETRY[]		= {  5000 }
LONG TLT_COMMS[]		= { 60000 }
LONG TLT_POLL[]		= { 15000 }
LONG TLT_CHAN_SHORT[]= {   750 }
LONG TLT_CHAN_LONG[] = {  4000 }
/******************************************************************************
	Helper Functions
******************************************************************************/
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myMediaStar.CONN.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnTryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myMediaStar.CONN.IP_HOST == ''){
		fnDebug(FALSE,'IPTV IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to IPTV Port ',ITOA(myMediaStar.CONN.IP_PORT),' on '",myMediaStar.CONN.IP_HOST)
		IF(myMediaStar.CONN.STATE == CONN_STATE_OFFLINE){
			myMediaStar.CONN.STATE = CONN_STATE_CONNECTING
			IP_CLIENT_OPEN(dvIPTV.PORT, myMediaStar.CONN.IP_HOST, myMediaStar.CONN.IP_PORT, IP_TCP)
		}
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIPTV.PORT)
}

DEFINE_FUNCTION fnSendCommand(CHAR pCMD[],CHAR pPARAM[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pCMD"
	IF(LENGTH_ARRAY(pPARAM)){
		toSend = "toSend,' ',pParam"
	}
	toSend = "toSend,$0D"
	fnDebug(FALSE,'->IPTV',toSend)
	SEND_STRING dvIPTV, toSend
	fnInitPoll()
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('getmodel','')
	fnSendCommand('getchannel','')
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'IPTV->',"pDATA")
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
		CASE 'getchannel':{
			REMOVE_STRING(pDATA,'=',1)
			myMediaStar.STATE.CHAN_NO = ATOI(fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)))
		}
		CASE 'getmodel':{
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	CREATE_BUFFER dvIPTV, myMediaStar.CONN.Rx
	myMediaStar.CONN.isIP = !(dvIPTV.NUMBER)
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvIPTV]{
	ONLINE:{
		myMediaStar.CONN.STATE 	= CONN_STATE_CONNECTED
		IF(!myMediaStar.CONN.isIP){
			SEND_COMMAND dvIPTV, 'SET MODE DATA'
			SEND_COMMAND dvIPTV, 'SET BAUD 115200 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		myMediaStar.CONN.Rx = ''
		myMediaStar.CONN.STATE 	= CONN_STATE_OFFLINE
		fnTryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myMediaStar.CONN.Rx = ''
		myMediaStar.CONN.STATE 	= CONN_STATE_OFFLINE
		SWITCH(DATA.NUMBER){
			CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
			CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
			CASE 6:{ _MSG = 'Conn Refused'}						// CoNNECtion Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// CoNNECtion Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown CoNNECtion Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		fnDebug(TRUE,"'MediaStar IP Error:[',myMediaStar.CONN.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{ fnTryConnection() }
		}
	}
	STRING:{
		//fnDebug(FALSE,'RAW->AMX',DATA.TEXT);
		WHILE(FIND_STRING(myMediaStar.CONN.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMediaStar.CONN.Rx,"$0D,$0A",1),2))
		}
	}
}
(** Delay for IP based control to allow system to boot **)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{myMediaStar.CONN.DEBUG = (DATA.TEXT == 'TRUE')}
					CASE 'PASSWORD':{myMediaStar.CONN.PASSWORD = DATA.TEXT}
					CASE 'IP':{
						IF(myMediaStar.CONN.isIP){
							myMediaStar.CONN.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
							myMediaStar.CONN.IP_PORT = 2026
							IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
								myMediaStar.CONN.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
							}
							fnOpenTCPConnection()
						}
					}
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT,'')
			}
			CASE 'CHANNEL':{
				SWITCH(DATA.TEXT){
					CASE 'INC':fnSendCommand('channelup','')
					CASE 'DEC':fnSendCommand('channeldown','')
					DEFAULT:   fnSendCommand('viewchan',"'channel="',DATA.TEXT,'"'")
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
}
/******************************************************************************
	Control Interface
******************************************************************************/
DEFINE_CONSTANT
INTEGER addCurChan = 1

DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{

	}
}
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		SWITCH(BUTTON.INPUT.CHANNEL){
			DEFAULT:{
				IF(BUTTON.INPUT.CHANNEL >= 10 && BUTTON.INPUT.CHANNEL <= 19){
					IF(LENGTH_ARRAY(myMediaStar.PANEL[GET_LAST(tp)].CHAN) == 3){ fnResetChanInput() }
					myMediaStar.PANEL[GET_LAST(tp)].CHAN = "myMediaStar.PANEL[GET_LAST(tp)].CHAN,ITOA(BUTTON.INPUT.CHANNEL-10)"
					SEND_COMMAND tp[GET_LAST(tp)],"'^TXT-',ITOA(addCurChan),',0,',fnPadLeadingChars(myMediaStar.PANEL[GET_LAST(tp)].CHAN,'-',3)"
					IF(LENGTH_ARRAY(myMediaStar.PANEL[GET_LAST(tp)].CHAN) == 3){
						SEND_COMMAND vdvControl, "'CHANNEL-',myMediaStar.PANEL[GET_LAST(tp)].CHAN"
						fnTimeoutChanInput(750)
					}
					ELSE{
						fnTimeoutChanInput(4000)
					}
				}
				ELSE IF(BUTTON.INPUT.CHANNEL >= 1000 && BUTTON.INPUT.CHANNEL <= 2000){
					SEND_COMMAND vdvControl, "'CHANNEL-',ITOA(BUTTON.INPUT.CHANNEL-1000)"
				}
			}
		}
	}
}
DEFINE_FUNCTION fnResetChanInput(){
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		myMediaStar.PANEL[p].CHAN = ''
		SEND_COMMAND tp[p],"'^TXT-',ITOA(addCurChan),',0,'"
	}
}
DEFINE_FUNCTION fnTimeoutChanInput(INTEGER pSHORT){
	IF(pSHORT){
		IF(TIMELINE_ACTIVE(TLID_CHAN)){TIMELINE_KILL(TLID_CHAN)}
		TIMELINE_CREATE(TLID_CHAN,TLT_CHAN_SHORT,LENGTH_ARRAY(TLT_CHAN_SHORT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE{
		IF(TIMELINE_ACTIVE(TLID_CHAN)){TIMELINE_KILL(TLID_CHAN)}
		TIMELINE_CREATE(TLID_CHAN,TLT_CHAN_LONG,LENGTH_ARRAY(TLT_CHAN_LONG),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_CHAN]{
	fnResetChanInput()
}
/******************************************************************************
	EoF
******************************************************************************/