MODULE_NAME='mDexon'(DEV vdvControl, DEV tp, DEV dvIP)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 10/06/2013  AT: 23:17:06        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	MCE Control module for sending text command strings to a PC
	Re-written by Solo Control to prevent excessive errors in diagnostics
******************************************************************************/
/******************************************************************************
	Structure
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_SOURCES = 20
INTEGER MAX_WINDOWS = 20

DEFINE_TYPE STRUCTURE uDexon{
	(** Comms **)
	INTEGER 	PORT
	CHAR 		IP[15]
	INTEGER  TRYING
	INTEGER  CONNECTED
	CHAR 		Rx[1000]
	CHAR 		Tx[1000]
	INTEGER  DEBUG
	INTEGER	REQUEST
	INTEGER 	REQ_INDEX
	INTEGER 	isIP
	(** Scenarios **)
	CHAR 		FILE[255]
	CHAR		SCENARIOS[20][255]
}
DEFINE_TYPE STRUCTURE uWindow{
	CHAR 		HANDLE[20]
	INTEGER 	HEIGHT
	INTEGER 	WIDTH
	INTEGER 	TOP 
	INTEGER 	LEFT
	CHAR 		SOURCE[255]
}
DEFINE_TYPE STRUCTURE uSource{
	CHAR 		HANDLE[20]
	CHAR		NAME[255]
}

DEFINE_CONSTANT
LONG TLID_COMMS		= 1
LONG TLID_POLL 		= 2
LONG TLID_TIMEOUT		= 3

INTEGER QUERY_GET_WINDOWS 	= 1
INTEGER QUERY_GET_SOURCES 	= 2
INTEGER QUERY_GET_HEIGHT 	= 3
INTEGER QUERY_GET_WIDTH 	= 4
INTEGER QUERY_GET_TOP 		= 5
INTEGER QUERY_GET_LEFT 		= 6
INTEGER CMD_SCENARIO 		= 21
INTEGER CMD_PING		 		= 22
INTEGER CMD_END		 		= 23

INTEGER defPORT = 6466

DEFINE_VARIABLE
uDexon myDexon;
	(** State **)
uWINDOW	WINDOWS[MAX_WINDOWS]
uSOURCE	SOURCES[MAX_SOURCES]
LONG TLT_COMMS[]		= {120000}		// Time before Comms flagged
LONG TLT_POLL[]		= {20000}		// Boot Up Time
LONG TLT_TIMEOUT[]	= {10000}		// Boot Up Time

/******************************************************************************
	Start Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvIP, myDexon.Rx
	myDexon.isIP = (!dvIP.NUMBER)
}
/******************************************************************************
	Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!myDexon.PORT){myDexon.PORT = defPORT}
	fnDebug(FALSE,"'TRY','[',ITOA(dvIP.PORT),']->DEX'","myDexon.IP,':',ITOA(myDexon.PORT)")
	myDexon.TRYING = TRUE
	IP_CLIENT_OPEN(dvIP.port, myDexon.IP, myDexon.PORT, IP_TCP) 
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIP.port)
}

DEFINE_FUNCTION fnInitTimeout(){	
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Utility Functions - Data Sending
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(INTEGER pCMD,CHAR pDATA[20]){
	STACK_VAR CHAR toSend[255]
	myDexon.REQUEST 	= pCMD
	SWITCH(myDexon.REQUEST){
		CASE QUERY_GET_SOURCES:{ 
			toSend = 'get sources'
		}
		CASE QUERY_GET_WINDOWS:{ 
			toSend = 'get windows'
		}
		CASE QUERY_GET_HEIGHT:{ 
			myDexon.REQ_INDEX = ATOI(pDATA)
			toSend = "'SEL WND ',WINDOWS[myDexon.REQ_INDEX].HANDLE,$0D,$0A,'GET HEIGHT'"
		}
		CASE QUERY_GET_WIDTH:{ 
			toSend = "'GET WIDTH'"
		}
		CASE QUERY_GET_TOP:{ 
			toSend = "'GET TOP'"
		}
		CASE QUERY_GET_LEFT:{ 
			toSend = "'GET LEFT'"
		}
		CASE CMD_SCENARIO:{
			IF(ATOI(DATA.TEXT)){ toSend = "'EVP #',DATA.TEXT,' "',myDexon.FILE,'"'" }ELSE{ toSend = 'CLR' }
		}
		CASE CMD_PING:{
			toSend = 'PING'
		}
		CASE CMD_END:{
			myDexon.REQUEST = 0
			myDexon.REQ_INDEX = 0
			toSend = 'END'
		}
		DEFAULT:{
			toSend = pDATA
		}
	}
	myDexon.Tx = "myDexon.Tx,toSend,$0D,$0A" 
	IF(!myDexon.isIP || myDexon.CONNECTED){ fnActualSend() }
	ELSE IF(!myDexon.TRYING){ fnOpenTCPConnection() }
}
DEFINE_FUNCTION fnActualSend(){
	WHILE(FIND_STRING(myDexon.Tx,"$0D,$0A",1)){
		STACK_VAR CHAR toSend[100]
		toSend = REMOVE_STRING(myDexon.Tx,"$0D,$0A",1)
		IF(myDexon.isIP){
			fnDebug(FALSE,'AMX->DEX',toSend)
			fnInitTimeout()
		}
		SEND_STRING dvIP,toSend
	}
}
/******************************************************************************
	Polling Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand(CMD_PING,'')
}
/******************************************************************************
	Utility Functions - Data Recieve
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	LOCAL_VAR INTEGER x
	fnDebug(FALSE,'DEXON->AMX',"pDATA")
	SWITCH(GET_BUFFER_STRING(pDATA,3)){
		CASE 'ACK':{
			SWITCH(myDexon.REQUEST){	
				CASE CMD_SCENARIO:fnSendCommand(QUERY_GET_WINDOWS,'')
			}
		}
		CASE 'BEG':{
			x = 1
		}
		CASE 'SRC':{
			GET_BUFFER_CHAR(pDATA)
			SWITCH(myDexon.REQUEST){
				CASE QUERY_GET_SOURCES:{
					SOURCES[x].HANDLE 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					SOURCES[x].NAME 	= fnRemoveQuotes(pDATA)
					x++;
				}
			}
		}
		CASE 'WND':{
			GET_BUFFER_CHAR(pDATA)
			REMOVE_STRING(pDATA,' ',1)
			SWITCH(myDexon.REQUEST){
				CASE QUERY_GET_WINDOWS:{
					WINDOWS[x].HANDLE 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					WINDOWS[x].SOURCE 	= fnRemoveQuotes(pDATA)
					x++;
				}
			}
		}
		CASE 'INT':{
			GET_BUFFER_CHAR(pDATA)
			SWITCH(myDexon.REQUEST){
				CASE QUERY_GET_HEIGHT:{
					WINDOWS[myDexon.REQ_INDEX].HEIGHT = ATOI(pDATA)
					fnSendCommand(QUERY_GET_WIDTH,'')
				}
				CASE QUERY_GET_WIDTH:{
					WINDOWS[myDexon.REQ_INDEX].WIDTH = ATOI(pDATA)
					fnSendCommand(QUERY_GET_TOP,'')
				}
				CASE QUERY_GET_TOP:{
					WINDOWS[myDexon.REQ_INDEX].TOP = ATOI(pDATA)
					fnSendCommand(QUERY_GET_LEFT,'')
				}
				CASE QUERY_GET_LEFT:{
					WINDOWS[myDexon.REQ_INDEX].LEFT = ATOI(pDATA)
					fnSendCommand(CMD_END,'')
					x++
					IF(LENGTH_ARRAY(WINDOWS[x].HANDLE)){
						fnSendCommand(QUERY_GET_HEIGHT,ITOA(x))
					}
				}
			}
		}
		CASE 'END':{
			SWITCH(myDexon.REQUEST){
				CASE QUERY_GET_SOURCES:{
					FOR(x = x; x <= MAX_SOURCES; x++){
						SOURCES[x].HANDLE 	= ''
						SOURCES[x].NAME 	= ''
					}
					fnSendCommand(QUERY_GET_WINDOWS,'')
				}
				CASE QUERY_GET_WINDOWS:{
					FOR(x = x; x <= MAX_WINDOWS; x++){
						WINDOWS[x].HANDLE = ''
						WINDOWS[x].SOURCE = ''
						WINDOWS[x].HEIGHT = 0
						WINDOWS[x].WIDTH 	= 0
						WINDOWS[x].TOP 	= 0
						WINDOWS[x].LEFT 	= 0
					}
					x = 1
					IF(LENGTH_ARRAY(WINDOWS[x].HANDLE)){
						fnSendCommand(QUERY_GET_HEIGHT,ITOA(x))
					}
				}
			}
		}
	}
}

/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myDexon.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{ 
						IF(FIND_STRING(DATA.TEXT,',',1)){
							myDexon.IP = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1);
							myDexon.PORT = ATOI(DATA.TEXT);
						}
						ELSE{
							myDexon.IP = DATA.TEXT;
						}
						fnSendCommand(QUERY_GET_SOURCES,'')
					}
					CASE 'SCENARIO':{
						myDexon.SCENARIOS[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT
					}
					CASE 'DEBUG': { myDexon.DEBUG = ATOI(DATA.TEXT) }
					CASE 'FILE': { myDexon.FILE = DATA.TEXT }
				}
			}
			CASE 'RAW':{
				fnSendCommand(0,DATA.TEXT)
			}
			CASE 'SYSTEM':{
				SWITCH(DATA.TEXT){
					CASE 'RELOAD':{
						fnSendCommand(QUERY_GET_SOURCES,'')
					}
				}
			}
			CASE 'SCENARIO':{
				fnSendCommand(CMD_SCENARIO,DATA.TEXT)
				
			}
		}
	}
}

DATA_EVENT[dvIP]{
	ONLINE:{
		IF(myDexon.isIP){
			fnDebug(FALSE,"'CONN','[',ITOA(dvIP.PORT),']->DEX'","myDexon.IP,':',ITOA(myDexon.PORT)")
			myDexon.TRYING    = FALSE
			myDexon.CONNECTED = TRUE
			fnActualSend()
			fnInitTimeout()
		}
		ELSE{
			SEND_COMMAND dvIP,'SET MODE DATA'
			SEND_COMMAND dvIP,'SET BAUD 19200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myDexon.CONNECTED = FALSE;
		myDexon.TRYING 	= FALSE;
		myDexon.Tx 			= ''
		myDexon.REQUEST 	= 0
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myDexon.CONNECTED 	= FALSE;
		myDexon.TRYING 		= FALSE;
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
		fnDebug(TRUE,"'Dexon IP Error:[',ITOA(myDexon.PORT),'@',myDexon.IP,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		myDexon.Tx = ''
	}
	STRING:{
		WHILE(FIND_STRING(myDexon.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myDexon.Rx,"$0D,$0A",1),2));
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}


(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	[vdvControl, 251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl, 252] = TIMELINE_ACTIVE(TLID_COMMS)
}/*
/************************************
	User Interface
************************************/
DEFINE_CONSTANT 
INTEGER btnScene[] = {10,11,12,13,14,15,16,17,18,19}
INTEGER btnWindows[] = {31,32,33,34,35,36,37}
INTEGER btnSources[] = {51,52,53,54,55,56,57,58,59}
INTEGER addDest	= 100
DEFINE_VARIABLE
INTEGER iselWindow
DEFINE_EVENT BUTTON_EVENT[tp,btnScene]{
	PUSH:SEND_COMMAND vdvControl,"'RECALL-',ITOA(GET_LAST(btnScene)-1)"
}
DEFINE_EVENT BUTTON_EVENT[tp,btnWindows]{
	PUSH:{
		iselWindow = GET_LAST(btnWindows)
		SEND_COMMAND tp,"'^TXT-',ITOA(addDest),',0,',myDexon.cWindowName[iselWindow]"
		SEND_COMMAND tp,'@PPN-Sources'
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnSources]{
	PUSH:{
		SEND_COMMAND vdvControl, "'CREATE-',ITOA(GET_LAST(btnSources)),',',ITOA(myDexon.cWindowLEFT[iselWindow]),',',ITOA(myDexon.cWindowTOP[iselWindow])"
		SEND_COMMAND tp,'@PPF-Sources'
	}
}
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:fnPopulateInterface()
}
/****************************
	Interface Events
***************************/
DEFINE_FUNCTION fnPopulateInterface(){
	STACK_VAR INTEGER b;
	FOR(b = 1; b <= LENGTH_ARRAY(btnWindows);b++){
		SEND_COMMAND tp,"'^TXT-',ITOA(btnWindows[b]),',0,',myDexon.cWindowName[b]"
	}
	FOR(b = 1; b <= LENGTH_ARRAY(btnSources);b++){
		SEND_COMMAND tp,"'^TXT-',ITOA(btnSources[b]),',0,',myDexon.cSourceName[b]"
	}
	SEND_COMMAND tp,"'^TXT-',ITOA(btnScene[1]),',0,Clear'"
	FOR(b = 2; b <= LENGTH_ARRAY(btnScene);b++){
		SEND_COMMAND tp,"'^TXT-',ITOA(btnScene[b]),',0,',myDexon.cScenarioName[b-1]"
	}
}*/