MODULE_NAME='mCiscoISDNLink'(DEV vdvControl,DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 11/01/2013  AT: 14:10:09        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Solo Control module for Cisco ISDN Link Box

	Basic control developed for Cabinet Office Switching of lines
******************************************************************************/

/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_REBOOT = 1
LONG TLID_COMMS  = 2
LONG TLID_POLL	  = 3
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uLINK{
	// State
	CHAR		ISDN_NUM[2][4][25]
	CHAR		IPADDRESS[15]
	CHAR 		MODEL[15]
	CHAR		VERSION[15]
	// Comms
	INTEGER	SECURITY
	INTEGER  LOGGEDIN
	INTEGER	DEBUG
	CHAR 		Username[255]
	CHAR		Password[255]
	CHAR		BAUD[10]
	CHAR 		Rx[500]
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_REBOOT[] = {3000}
LONG TLT_COMMS[]  = {120000}
LONG TLT_POLL[]   = {45000}

uLINK  myLink

CHAR _USERNAME[] = 'admin'
CHAR _PASSWORD[] = ''
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCommand[255], CHAR pParam[255]){
	fnDebug('->ISDN',"pCommand,' ', pParam")
	SEND_STRING dvRS232, "pCommand,' ', pParam,$0D"
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myLink.DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION INTEGER fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER ProfileIndex
	fnDebug('LINK->',pDATA)
	IF(pDATA == ''){		 RETURN FALSE}
	IF(pDATA == '** end'){RETURN FALSE}
	IF(pDATA == 'OK'){	 RETURN FALSE}
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'xStatus':{SEND_STRING dvRS232,"'echo off',$0D" }// echoing - cancel
		CASE '*e':{	// Event Response
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'OutgoingCallIndication':{
					REMOVE_STRING(pDATA,':',1)
					fnSendCommand('xStatus Call',pDATA)
				}
			}
		}
		CASE '*s':{	// Status Response
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'Network':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
						CASE '1':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
								CASE 'IPv4':{
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
										CASE 'Address:':myLink.ipaddress = fnRemoveQuotes(pDATA)
									}
								}
							}
						}
					}
				}
				CASE 'SystemUnit':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
						CASE 'ProductPlatform':{
							myLink.MODEL   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
							SEND_STRING vdvControl, "'PROPERTY-MODEL,Cisco ',myLink.MODEL"
						}
						CASE 'Software Version':{
							myLink.VERSION = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
							SEND_STRING vdvControl, "'PROPERTY-SOFTWARE,',myLink.VERSION"
						}
					}
				}
			}
			RETURN TRUE;
		}
	}
}
(** Polling Events **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendPoll()
}
DEFINE_FUNCTION fnInitDevice(){
	myLink.SECURITY		= FALSE
	myLink.LOGGEDIN		= FALSE
	fnInitComms()
}
DEFINE_FUNCTION fnInitComms(){
	fnRegister();
	fnSendPoll()
}
DEFINE_FUNCTION fnSendPoll(){
	fnSendCommand('xStatus','Network 1 IPv4 Address')
}
DEFINE_FUNCTION fnRegister(){
	fnSendCommand('echo','off')
}
(** Reboot Events **)
DEFINE_FUNCTION fnReboot(){
	IF(TIMELINE_ACTIVE(TLID_REBOOT)){TIMELINE_KILL(TLID_REBOOT)}
	TIMELINE_CREATE(TLID_REBOOT,TLT_REBOOT,LENGTH_ARRAY(TLT_REBOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_REBOOT]{
	SEND_STRING vdvControl, 'ACTION-REBOOTING'
	fnSendCommand('xCommand Boot','')
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myLink.Rx
	fnInitDevice()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		WAIT 30{
			IF(myLink.BAUD = ''){
				myLink.BAUD = '115200'
				SEND_COMMAND dvRS232, "'SET BAUD ',myLink.BAUD,' N 8 1 485 DISABLE'"
				//fnInitComms()
			}
		}
	}
	STRING:{
		IF(FIND_STRING(DATA.TEXT,'login:',1)){
			myLink.SECURITY = TRUE;
			myLink.LOGGEDIN = FALSE;
			myLink.Rx = ''
			IF(myLink.Username == ''){myLink.Username = _username}
			SEND_STRING dvRS232, "myLink.Username,$0D"
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'Password:',1)){
			myLink.Rx = ''
			IF(myLink.Password == ''){myLink.Password = _password}
			SEND_STRING dvRS232, "myLink.Password,$0D"
		}
		ELSE IF(FIND_STRING(DATA.TEXT,'Welcome to',1)){
			myLink.LOGGEDIN = TRUE
			fnInitComms()
		}
		ELSE{
			WHILE(FIND_STRING(myLink.Rx,"$0D,$0A",1)){
				IF(fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLink.Rx,"$0D,$0A",1),2))){
					IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
					TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
		}
	}
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':{			fnInitComms() }
					CASE 'REBOOT':{ 	 	fnReboot() }
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						myLink.BAUD = DATA.TEXT;
						SEND_COMMAND dvRS232, "'SET BAUD ',myLink.BAUD,' N 8 1 485 DISABLE'"
						fnInitComms()
					}
					CASE 'DEBUG': myLink.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'LOGIN':{
						myLink.Username = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myLink.Password = DATA.TEXT
					}
				}
			}
			CASE 'DIRECTORYNO':{
				STACK_VAR INTEGER x
				STACK_VAR INTEGER y
				x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				y = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				myLink.ISDN_NUM[x][y] = DATA.TEXT
			}
			CASE 'RAW':{
				fnDebug('->ISDN',"DATA.TEXT")
				SEND_STRING dvRS232, "DATA.TEXT,$0D"
			}
			CASE 'CHANGENUMBERS':{
				STACK_VAR INTEGER x
				x = ATOI(DATA.TEXT)
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 1 DirectoryNumber 1 Number: "',myLink.ISDN_NUM[x][1],'"'")
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 1 DirectoryNumber 2 Number: "',myLink.ISDN_NUM[x][1],'"'")
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 2 DirectoryNumber 1 Number: "',myLink.ISDN_NUM[x][2],'"'")
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 2 DirectoryNumber 2 Number: "',myLink.ISDN_NUM[x][2],'"'")
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 3 DirectoryNumber 1 Number: "',myLink.ISDN_NUM[x][3],'"'")
				fnSendCommand('xConfiguration',"'ISDN BRI Interface 3 DirectoryNumber 2 Number: "',myLink.ISDN_NUM[x][3],'"'")
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
	[vdvControl,253] = (myLink.LOGGEDIN)
	[vdvControl,254] = (myLink.SECURITY)
}