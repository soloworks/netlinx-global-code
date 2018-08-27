MODULE_NAME='mEncodedMedia'(DEV vdvControl, DEV tp[], DEV dvIPTV)
(***********************************************************)
(*  FILE CREATED ON: 05/21/2013  AT: 18:48:26              *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 06/25/2013  AT: 11:45:48        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uIPTV{
	(** Status **)
	CHAR 	  CHANNAME[50]
	CHAR 	  CHANNUM[10]
	CHAR	  SOFTWARE[25]
	CHAR	  LOCATION[50]
	CHAR	  MODEL[25]
	CHAR	  PLATFORM[25]
	CHAR	  SN[25]
	INTEGER VOLUME
}
DEFINE_TYPE STRUCTURE uChan{
	INTEGER NUMBER
	CHAR	  NAME[25]
}
DEFINE_TYPE STRUCTURE uComms{
	(** IP Comms Control **)
	INTEGER CONNECTED
	INTEGER TRYING
	INTEGER PORT
	CHAR	  IP[15]
	INTEGER isIP
	(** General Comms Control **)
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
	INTEGER PASSED
	CHAR 	  USERNAME[20]
	CHAR 	  PASSWORD[20]
}
DEFINE_TYPE STRUCTURE uPanel{
	CHAR CHAN[3]
	INTEGER ENTRIES
	INTEGER PAGE
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
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
uIPTV   myIPTV
uComms  myIPTVComms
uPanel  myIPTVPanel[10]
uChan	  myIPTVChans[100]
(** Timeline Times **)
LONG TLT_RETRY[]		= {10000}
LONG TLT_COMMS[]		= {60000}
LONG TLT_POLL[]		= {30000}
LONG TLT_CHAN_SHORT[]= {750}
LONG TLT_CHAN_LONG[] = {4000}
/******************************************************************************
	Helper Functions
******************************************************************************/
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myIPTVComms.DEBUG = 1 || bForce)	{
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
(** IP CoNNECtion Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myIPTVComms.IP == ''){
		fnDebug(FALSE,'IPTV IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to IPTV Port ',ITOA(myIPTVComms.PORT),' on '",myIPTVComms.IP)
		IF(!myIPTVComms.TRYING){
			myIPTVComms.TRYING = TRUE
			IP_CLIENT_OPEN(dvIPTV.port, myIPTVComms.IP, myIPTVComms.PORT, IP_TCP)
		}
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIPTV.port)
}

DEFINE_FUNCTION fnSendCommand(CHAR pCMD[],CHAR pPARAM[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pCMD"
	IF(LENGTH_ARRAY(pPARAM)){
		toSend = "toSend,' ',pParam"
	}
	toSend = "toSend,$0D"
	fnDebug(FALSE,'AMX->IPTV',toSend)
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
	fnSendCommand('STBSTATUS','')
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'FB',"pDATA")
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
		CASE 'Channel':			myIPTV.CHANNAME 	= pDATA
		CASE 'Channel Number':	myIPTV.CHANNUM 	= pDATA
		CASE 'EM Release':		myIPTV.SOFTWARE 	= pDATA
		CASE 'Location':			myIPTV.LOCATION 	= pDATA
		CASE 'Model':				myIPTV.MODEL	 	= pDATA
		CASE 'Platform':			myIPTV.PLATFORM 	= pDATA
		CASE 'Serial':				myIPTV.SN		 	= pDATA
		CASE 'Volume':				myIPTV.VOLUME 		= ATOI(pDATA)
	}
}
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	// Default Values
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		myIPTVPanel[p].ENTRIES = 24
	}
	//myIPTVComms.USERNAME = 'admin'
	//myIPTVComms.PASSWORD = 'labrador'
	myIPTVComms.USERNAME = 'engineer'
	myIPTVComms.PASSWORD = 'BG!iptv!stb'
	CREATE_BUFFER dvIPTV, myIPTVComms.Rx
	myIPTVComms.isIP = !(dvIPTV.NUMBER)
}
DEFINE_START{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 100; x++){
		SWITCH(x){
			CASE 01:myIPTVChans[x].NUMBER =   1; myIPTVChans[x].NAME 	= 'BBC One';
			CASE 02:myIPTVChans[x].NUMBER =   2; myIPTVChans[x].NAME 	= 'BBC Two';
			CASE 03:myIPTVChans[x].NUMBER =   3; myIPTVChans[x].NAME 	= 'ITV';
			CASE 04:myIPTVChans[x].NUMBER =   4; myIPTVChans[x].NAME 	= 'Channel 4';
			CASE 05:myIPTVChans[x].NUMBER =   5; myIPTVChans[x].NAME 	= 'Channel 5';
			CASE 06:myIPTVChans[x].NUMBER =   6; myIPTVChans[x].NAME 	= 'ITV 2';
			CASE 07:myIPTVChans[x].NUMBER =   7; myIPTVChans[x].NAME 	= 'BBC Three';
			CASE 08:myIPTVChans[x].NUMBER =   9; myIPTVChans[x].NAME 	= 'BBC Four';
			CASE 09:myIPTVChans[x].NUMBER =  10; myIPTVChans[x].NAME 	= 'ITV 3';
			CASE 10:myIPTVChans[x].NUMBER =  11; myIPTVChans[x].NAME 	= 'pick';
			CASE 11:myIPTVChans[x].NUMBER =  12; myIPTVChans[x].NAME 	= 'Dave';
			CASE 12:myIPTVChans[x].NUMBER =  13; myIPTVChans[x].NAME 	= 'Channel 4+1';
			CASE 13:myIPTVChans[x].NUMBER =  14; myIPTVChans[x].NAME 	= 'More 4';
			CASE 14:myIPTVChans[x].NUMBER =  15; myIPTVChans[x].NAME 	= 'Film4';
			CASE 15:myIPTVChans[x].NUMBER =  19; myIPTVChans[x].NAME 	= 'Yesterday';
			CASE 16:myIPTVChans[x].NUMBER =  24; myIPTVChans[x].NAME 	= 'ITV 4';
			CASE 17:myIPTVChans[x].NUMBER =  25; myIPTVChans[x].NAME 	= 'Dave ja vu';
			CASE 18:myIPTVChans[x].NUMBER =  27; myIPTVChans[x].NAME 	= 'ITV 2+1';
			CASE 19:myIPTVChans[x].NUMBER =  28; myIPTVChans[x].NAME 	= 'E4';
			CASE 20:myIPTVChans[x].NUMBER =  29; myIPTVChans[x].NAME 	= 'E4+1';
			CASE 21:myIPTVChans[x].NUMBER =  30; myIPTVChans[x].NAME 	= '5*';
			CASE 22:myIPTVChans[x].NUMBER =  31; myIPTVChans[x].NAME 	= '5 USA';
			CASE 23:myIPTVChans[x].NUMBER =  32; myIPTVChans[x].NAME 	= 'Movie Mix';
			CASE 24:myIPTVChans[x].NUMBER =  33; myIPTVChans[x].NAME 	= 'ITV +1';
			CASE 25:myIPTVChans[x].NUMBER =  38; myIPTVChans[x].NAME 	= 'QUEST';
			CASE 26:myIPTVChans[x].NUMBER =  44; myIPTVChans[x].NAME 	= 'Channel 5+1';
			CASE 27:myIPTVChans[x].NUMBER =  45; myIPTVChans[x].NAME 	= 'Film4+1';
			CASE 28:myIPTVChans[x].NUMBER =  47; myIPTVChans[x].NAME 	= '4seven';
			CASE 29:myIPTVChans[x].NUMBER =  61; myIPTVChans[x].NAME 	= 'True Entertainment';
			CASE 30:myIPTVChans[x].NUMBER =  80; myIPTVChans[x].NAME 	= 'BBC News';
			CASE 31:myIPTVChans[x].NUMBER =  81; myIPTVChans[x].NAME 	= 'BBC Parliment';
			CASE 32:myIPTVChans[x].NUMBER =  82; myIPTVChans[x].NAME 	= 'Sky News';
			CASE 33:myIPTVChans[x].NUMBER =  83; myIPTVChans[x].NAME 	= 'Al Jazeera Eng';
			CASE 34:myIPTVChans[x].NUMBER =  85; myIPTVChans[x].NAME 	= 'RT';
			CASE 35:myIPTVChans[x].NUMBER =  87; myIPTVChans[x].NAME 	= 'CNN';
			CASE 36:myIPTVChans[x].NUMBER =  90; myIPTVChans[x].NAME 	= 'CCTV News';
			CASE 37:myIPTVChans[x].NUMBER =  91; myIPTVChans[x].NAME 	= 'Euronews';
			CASE 38:myIPTVChans[x].NUMBER = 100; myIPTVChans[x].NAME 	= 'News Multiview';
			CASE 39:myIPTVChans[x].NUMBER = 101; myIPTVChans[x].NAME 	= 'BBC One HD';
			CASE 40:myIPTVChans[x].NUMBER = 102; myIPTVChans[x].NAME 	= 'BBC Two HD';
			CASE 41:myIPTVChans[x].NUMBER = 103; myIPTVChans[x].NAME 	= 'ITV HD';
			CASE 42:myIPTVChans[x].NUMBER = 104; myIPTVChans[x].NAME 	= 'Channel 4 HD';
			CASE 43:myIPTVChans[x].NUMBER = 105; myIPTVChans[x].NAME 	= 'BBC Three HD';
			(** Misc Channels **)
			CASE 44:myIPTVChans[x].NUMBER = 301; myIPTVChans[x].NAME 	= 'BBC RB 301';
			(** Radio Channels **)
			CASE 45:myIPTVChans[x].NUMBER = 700; myIPTVChans[x].NAME 	= 'BBC Radio 1';
			CASE 46:myIPTVChans[x].NUMBER = 701; myIPTVChans[x].NAME 	= 'BBC R1X';
			CASE 47:myIPTVChans[x].NUMBER = 702; myIPTVChans[x].NAME 	= 'BBC Radio 2';
			CASE 48:myIPTVChans[x].NUMBER = 703; myIPTVChans[x].NAME 	= 'BBC Radio 3';
			CASE 49:myIPTVChans[x].NUMBER = 704; myIPTVChans[x].NAME 	= 'BBC Radio 4';
			CASE 50:myIPTVChans[x].NUMBER = 705; myIPTVChans[x].NAME 	= 'BBC 5 Live';
			CASE 51:myIPTVChans[x].NUMBER = 706; myIPTVChans[x].NAME 	= 'BBC R5SX';
			CASE 52:myIPTVChans[x].NUMBER = 707; myIPTVChans[x].NAME 	= 'BBC 6 Music';
			CASE 53:myIPTVChans[x].NUMBER = 708; myIPTVChans[x].NAME 	= 'BBC Radio 4 Ex';
			CASE 54:myIPTVChans[x].NUMBER = 709; myIPTVChans[x].NAME 	= 'BBC Asian Network';
			CASE 55:myIPTVChans[x].NUMBER = 710; myIPTVChans[x].NAME 	= 'BBC World Service';
			CASE 56:myIPTVChans[x].NUMBER = 715; myIPTVChans[x].NAME 	= 'Magic';
			CASE 57:myIPTVChans[x].NUMBER = 718; myIPTVChans[x].NAME 	= 'Smooth Radio';
			CASE 58:myIPTVChans[x].NUMBER = 722; myIPTVChans[x].NAME 	= 'Kerrang!';
			CASE 59:myIPTVChans[x].NUMBER = 723; myIPTVChans[x].NAME 	= 'talkSPORT';
			CASE 60:myIPTVChans[x].NUMBER = 724; myIPTVChans[x].NAME 	= 'Capital FM';
			CASE 61:myIPTVChans[x].NUMBER = 727; myIPTVChans[x].NAME 	= 'Absolute Radio';
			CASE 62:myIPTVChans[x].NUMBER = 728; myIPTVChans[x].NAME 	= 'Heart';
		}
	}
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvIPTV]{
	ONLINE:{
		IF(myIPTVComms.isIP){
			myIPTVComms.CONNECTED 	= TRUE;
			myIPTVComms.TRYING 		= FALSE;
		}
		ELSE{
			SEND_COMMAND dvIPTV, 'SET MODE DATA'
			SEND_COMMAND dvIPTV, 'SET BAUD 115200 N 8 1 485 DISABLE'
		}
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		myIPTVComms.Rx = ''
		myIPTVComms.CONNECTED 	= FALSE;
		myIPTVComms.TRYING 		= FALSE;
		myIPTVComms.PASSED		= FALSE
		fnTryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myIPTVComms.Rx = ''
		myIPTVComms.CONNECTED 	= FALSE;
		myIPTVComms.TRYING 		= FALSE;
		myIPTVComms.PASSED		= FALSE
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
		fnDebug(TRUE,"'Exterity IP Error:[',myIPTVComms.IP,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		fnTryConnection()
	}
	STRING:{
		//fnDebug(FALSE,'RAW->AMX',DATA.TEXT);
		IF(FIND_STRING(myIPTVComms.Rx,'Username:',1)){
			fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
			myIPTVComms.Rx = ''
			fnDebug(FALSE,'AMX->IPTV',"myIPTVComms.USERNAME,$0D");
			SEND_STRING dvIPTV,"myIPTVComms.USERNAME,$0D"
		}
		ELSE IF(FIND_STRING(myIPTVComms.Rx,'Password:',1)){
			fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
			myIPTVComms.Rx = ''
			fnDebug(FALSE,'AMX->IPTV',"myIPTVComms.PASSWORD,$0D");
			SEND_STRING dvIPTV,"myIPTVComms.PASSWORD,$0D"
		}
		ELSE{
			WHILE(FIND_STRING(myIPTVComms.Rx,"$0D,$0A",1)){
				STACK_VAR CHAR _LINE[255]
				//fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
				_LINE = fnStripCharsRight(REMOVE_STRING(myIPTVComms.Rx,"$0D,$0A",1),2)

				IF(FIND_STRING(_LINE,'EMSTB control interface',1)){
					myIPTVComms.Rx = ''
					myIPTVComms.PASSED = TRUE
					fnPoll()
				}
				IF(LENGTH_ARRAY(_LINE)){
					fnProcessFeedback(_LINE)
				}
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}
(** Delay for IP based control to allow system to boot **)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{myIPTVComms.DEBUG = (DATA.TEXT == 'TRUE')}
					CASE 'USERNAME':{myIPTVComms.USERNAME = DATA.TEXT}
					CASE 'PASSWORD':{myIPTVComms.PASSWORD = DATA.TEXT}
					CASE 'PAGESIZE':{myIPTVPanel[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))].ENTRIES = ATOI(DATA.TEXT)}
					CASE 'IP':{
						IF(myIPTVComms.isIP){
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myIPTVComms.IP = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myIPTVComms.PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myIPTVComms.IP = DATA.TEXT
								myIPTVComms.PORT = 5004
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
					CASE 'INC':fnSendCommand('STBKEYPRESS','CH+')
					CASE 'DEC':fnSendCommand('STBKEYPRESS','CH-')
					DEFAULT:{
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'URI':fnSendCommand('playChannelUri',DATA.TEXT)
							CASE 'NUM':fnSendCommand('playChannelNumber',DATA.TEXT)
						}
					}
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
		myIPTVPanel[GET_LAST(tp)].PAGE = 1
		SEND_COMMAND DATA.DEVICE,"'^TXT-',ITOA(addCurChan),',0,'"
		fnSetupChanList(GET_LAST(tp))
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE 22:fnSendCommand('STBKEYPRESS','CH+')
			CASE 23:fnSendCommand('STBKEYPRESS','CH-')
			CASE 31:fnSendCommand('STBKEYPRESS','UP')
			CASE 32:fnSendCommand('STBKEYPRESS','DOWN')
			CASE 33:fnSendCommand('STBKEYPRESS','LEFT')
			CASE 34:fnSendCommand('STBKEYPRESS','RIGHT')
			CASE 35:fnSendCommand('STBKEYPRESS','OK')
			CASE 36:fnSendCommand('STBKEYPRESS','MENU')
			CASE 37:fnSendCommand('STBKEYPRESS','BACK')
			DEFAULT:{
				IF(BUTTON.INPUT.CHANNEL >= 10 && BUTTON.INPUT.CHANNEL <= 19){
					IF(LENGTH_ARRAY(myIPTVPanel[GET_LAST(tp)].CHAN) == 3){ fnResetChanInput() }
					myIPTVPanel[GET_LAST(tp)].CHAN = "myIPTVPanel[GET_LAST(tp)].CHAN,ITOA(BUTTON.INPUT.CHANNEL-10)"
					SEND_COMMAND tp[GET_LAST(tp)],"'^TXT-',ITOA(addCurChan),',0,',fnPadLeadingChars(myIPTVPanel[GET_LAST(tp)].CHAN,'-',3)"
					IF(LENGTH_ARRAY(myIPTVPanel[GET_LAST(tp)].CHAN) == 3){
						SEND_COMMAND vdvControl, "'CHANNEL-NUM,',myIPTVPanel[GET_LAST(tp)].CHAN"
						fnTimeoutChanInput(750)
					}
					ELSE{
						fnTimeoutChanInput(4000)
					}
				}
				ELSE IF(BUTTON.INPUT.CHANNEL >= 1000 && BUTTON.INPUT.CHANNEL <= 2000){
					SEND_COMMAND vdvControl, "'CHANNEL-NUM,',ITOA(BUTTON.INPUT.CHANNEL-1000)"
				}
				ELSE IF(BUTTON.INPUT.CHANNEL > 2000){
					SWITCH(BUTTON.INPUT.CHANNEL){
						CASE 2098:{
							myIPTVPanel[GET_LAST(tp)].PAGE--
							fnSetupChanList(GET_LAST(tp))
						}
						CASE 2099:{
							myIPTVPanel[GET_LAST(tp)].PAGE++
							fnSetupChanList(GET_LAST(tp))
						}
						DEFAULT:{
							STACK_VAR INTEGER y
							y = (myIPTVPanel[GET_LAST(tp)].ENTRIES * myIPTVPanel[GET_LAST(tp)].PAGE) - myIPTVPanel[GET_LAST(tp)].ENTRIES + BUTTON.INPUT.CHANNEL-2000
							IF(myIPTVChans[y].NUMBER){	SEND_COMMAND vdvControl, "'CHANNEL-NUM,',ITOA(myIPTVChans[y].NUMBER)" }
						}
					}
				}
			}
		}
	}
}
DEFINE_FUNCTION fnSetupChanList(INTEGER pPanel){
	STACK_VAR INTEGER x
	IF(myIPTVPanel[pPanel].PAGE = 0){
		myIPTVPanel[pPanel].PAGE = 1
	}
	// Don't allow back if on first page
	SEND_COMMAND tp[pPanel],"'^SHO-2098,',ITOA(myIPTVPanel[pPanel].PAGE != 1)"
	// Don't allow forward if first entry on new page is empty
	SEND_COMMAND tp[pPanel],"'^SHO-2099,',ITOA(LENGTH_ARRAY(myIPTVChans[myIPTVPanel[pPanel].PAGE*myIPTVPanel[pPanel].ENTRIES+1].NAME) > 0)"
	FOR(x = 1; x <= myIPTVPanel[pPanel].ENTRIES; x++){
		STACK_VAR INTEGER y
		y = (myIPTVPanel[pPanel].ENTRIES * myIPTVPanel[pPanel].PAGE) - myIPTVPanel[pPanel].ENTRIES + x
		IF(myIPTVChans[y].NUMBER){
			SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(2000+x),',0,[',fnPadLeadingChars(ITOA(myIPTVChans[y].NUMBER),'0',3),'] ', myIPTVChans[y].NAME"
		}
		ELSE{
			SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(2000+x),',0,'"
		}
	}
}
DEFINE_FUNCTION fnResetChanInput(){
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		myIPTVPanel[p].CHAN = ''
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