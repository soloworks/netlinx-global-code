MODULE_NAME='mExterity'(DEV vdvControl, DEV tp[], DEV dvExterity)
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
	INTEGER POWER
	CHAR	  MODE[255]
	CHAR	  NAME[255]
	CHAR	  LOCATION[255]
	CHAR	  SOFTWARE[255]
	CHAR	  MODEL[255]
	CHAR 	  CHAN[255]

	INTEGER CONFIG_FILE_FOUND
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
LONG TLT_POLL[]		= {15000}
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
		fnDebug(TRUE,'Exterity IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to IPTV Port ',ITOA(myIPTVComms.PORT),' on '",myIPTVComms.IP)
		IF(!myIPTVComms.TRYING){
			myIPTVComms.TRYING = TRUE
			IP_CLIENT_OPEN(dvExterity.port, myIPTVComms.IP, myIPTVComms.PORT, IP_TCP)
		}
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvExterity.port)
}

DEFINE_FUNCTION fnSendQuery(CHAR pParam[]){
	STACK_VAR CHAR toSend[255]
	toSend = "'^get:',pParam,'!',$0D"
	fnDebug(FALSE,'AMX->IPTV',toSend)
	SEND_STRING dvExterity, toSend
}
DEFINE_FUNCTION fnSendCommand(CHAR pParam[],CHAR pValue[]){
	STACK_VAR CHAR toSend[255]
	toSend = "'^set:',pParam,':',pVALUE,'!',$0D"
	fnDebug(FALSE,'AMX->IPTV',toSend)
	SEND_STRING dvExterity, toSend
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
	fnSendQuery('currentChannel')
}
DEFINE_FUNCTION fnFullPoll(){
	fnSendQuery('currentMode')
	fnSendQuery('name')
	fnSendQuery('location')
	fnSendQuery('softwareVersion')
	fnSendQuery('productType')
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR CHAR _TYPE[255]
	pDATA = fnStripCharsRight(pDATA,1)	// Chew off !
	GET_BUFFER_CHAR(pDATA)				// Chew off ^
	_TYPE = fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
	IF(_TYPE == 'get' || _TYPE == 'set' || _TYPE == 'CECMessageTxFailed'){ RETURN }
	fnDebug(FALSE,'FB',"_TYPE,'|',pDATA")
	SWITCH(_TYPE){
		CASE 'name':				myIPTV.NAME 	 = pDATA
		CASE 'location':			myIPTV.LOCATION = pDATA
		CASE 'softwareVersion':	myIPTV.SOFTWARE = pDATA
		CASE 'productType':		myIPTV.MODEL 	 = pDATA
		CASE 'currentMode':		myIPTV.MODE		 = pDATA
		CASE 'currentChannel':{
			myIPTV.CHAN 	 = pDATA
			IF(!myIPTVComms.PASSED){
				myIPTVComms.PASSED = TRUE
				fnFullPoll()
			}
		}
	}
	myIPTV.POWER = (myIPTV.MODE != 'off')
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
	myIPTVComms.USERNAME = 'ctrl'
	myIPTVComms.PASSWORD = 'labrador'
	CREATE_BUFFER dvExterity, myIPTVComms.Rx
	myIPTVComms.isIP = !(dvExterity.NUMBER)

	fnLoadConfigFile('ExterityConfig.txt')
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvExterity]{
	ONLINE:{
		IF(myIPTVComms.isIP){
			myIPTVComms.CONNECTED 	= TRUE;
			myIPTVComms.TRYING 		= FALSE;
		}
		ELSE{
			SEND_COMMAND dvExterity, 'SET MODE DATA'
			SEND_COMMAND dvExterity, 'SET BAUD 115200 N 8 1 485 DISABLE'
		}
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		myIPTVComms.Rx = ''
		myIPTVComms.CONNECTED 	= FALSE;
		myIPTVComms.TRYING 		= FALSE;
		myIPTVComms.PASSED		= FALSE
		IF(myIPTVComms.isIP){
			fnTryConnection()
		}
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
			CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		fnDebug(TRUE,"'Exterity IP Error:[',myIPTVComms.IP,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		IF(myIPTVComms.isIP){
			fnTryConnection()
		}
	}
	STRING:{
		fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
		IF(FIND_STRING(myIPTVComms.Rx,'login:',1)){
			fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
			myIPTVComms.Rx = ''
			fnDebug(FALSE,'AMX->IPTV',"myIPTVComms.USERNAME,$0D");
			SEND_STRING dvExterity,"myIPTVComms.USERNAME,$0D"
		}
		ELSE IF(FIND_STRING(myIPTVComms.Rx,'Password:',1)){
			fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
			myIPTVComms.Rx = ''
			fnDebug(FALSE,'AMX->IPTV',"myIPTVComms.PASSWORD,$0D");
			SEND_STRING dvExterity,"myIPTVComms.PASSWORD,$0D"
		}
		ELSE{
			WHILE(FIND_STRING(myIPTVComms.Rx,"$0D,$0A",1)){
				STACK_VAR CHAR _LINE[255]
				fnDebug(FALSE,'IPTV->AMX',DATA.TEXT);
				_LINE = fnStripCharsRight(REMOVE_STRING(myIPTVComms.Rx,"$0D,$0A",1),2)

				IF(FIND_STRING(_LINE,'Exterity Control Interface',1)){
					myIPTVComms.Rx = ''
					myIPTVComms.PASSED = TRUE
					fnFullPoll()
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
								myIPTVComms.PORT = 23
							}
							fnOpenTCPConnection()
						}
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvExterity, "DATA.TEXT,$0D"
			}
			CASE 'QUERY': fnSendQuery(DATA.TEXT)
			CASE 'CHANNEL':{
				SWITCH(DATA.TEXT){
					//CASE 'INC':fnSendCommand('upChannel','')
					//CASE 'DEC':fnSendCommand('dnChannel','')
					CASE 'INC':SEND_STRING dvExterity,"'^send:rm_chup!',$0D"
					CASE 'DEC':SEND_STRING dvExterity,"'^send:rm_chdown!',$0D"
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
	[vdvControl,255] = (myIPTV.POWER)
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
			CASE 22:SEND_COMMAND vdvControl,'CHANNEL-INC'
			CASE 23:SEND_COMMAND vdvControl,'CHANNEL-DEC'
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

DEFINE_FUNCTION fnLoadConfigFile(CHAR pFile[]){
	STACK_VAR CHAR FileName[255]
	STACK_VAR SLONG NumFiles
 	STACK_VAR SLONG Entry
	STACK_VAR INTEGER x
	NumFiles = 1
	Entry = 1
	WHILE(NumFiles > 0){
		NumFiles = FILE_DIR('.',FileName,Entry)
		Entry++
		IF(LOWER_STRING(FileName) == LOWER_STRING(pFile)){
			myIPTV.CONFIG_FILE_FOUND = TRUE
			fnProcessConfig(pFile)
			RETURN
		}
	}
}

//config is processed by the setting type and assigned to the appropriate room config strucutre
DEFINE_FUNCTION fnProcessConfig(CHAR pFILE[]){
	STACK_VAR SLONG slFileHandle
	STACK_VAR CHAR  thisLine[1000]
	STACK_VAR INTEGER _LINE
	STACK_VAR INTEGER x

	// Load Config
	fnDebug(FALSE,'Opening File ',pFILE)
	slFileHandle = FILE_OPEN(pFILE,FILE_READ_ONLY)

	IF(slFileHandle > 0){
		STACK_VAR SLONG readRESULT
		_LINE = 1
		readRESULT = FILE_READ_LINE(slFileHandle,thisLine,MAX_LENGTH_ARRAY(thisLine))
		WHILE(readRESULT >= 0){
			IF(readRESULT == 0){
				// Blank Line
			}
			ELSE IF(thisLine[1] == '#'){
				// Comment Line
			}
			ELSE IF(FIND_STRING(thisLine,',',1)){
				myIPTVChans[_LINE].NUMBER = ATOI(fnStripCharsRight(REMOVE_STRING(thisLine,',',1),1))
				myIPTVChans[_LINE].NAME = thisLine
				_LINE++
			}
			readRESULT = FILE_READ_LINE(slFileHandle,thisLine,MAX_LENGTH_ARRAY(thisLine))
		}
		FILE_CLOSE(slFileHandle)
	}
}
