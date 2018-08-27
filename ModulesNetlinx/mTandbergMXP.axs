MODULE_NAME='mTandbergMXP'(DEV vdvControl, DEV vdvCalls[], DEV tp[], DEV dvVC)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Solo Control module for Tandberg MXP
	Built to SC standards - Basic functionality for Burberry
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_CALLS	  = 7
INTEGER MAX_PRESETS = 15
INTEGER MAX_CAMERAS = 13
INTEGER DIRSIZE         = 100	// Must be under a certain size or event stack dies

DEFINE_TYPE STRUCTURE uCall{
	CHAR 		STATUS[20]
	CHAR 		TYPE[20]
	CHAR     PROTOCOL[20]
	CHAR 		DIRECTION[20]
	CHAR 		NAME[50]
	CHAR 		NUMBER[50]
	INTEGER  isMuted
}
DEFINE_TYPE STRUCTURE uDirEntry{
	CHAR 		NAME[75]
	CHAR 		NUMBER[100]
	INTEGER  LINK // Index of original list for dialling from search
}
DEFINE_TYPE STRUCTURE uDir{
	// Directory
	INTEGER  LOADING					// Flat to show Directory is Processing
	CHAR     TYPE[20]     		// LocalEntry | GlobalEntry
	CHAR		SEARCH1[20]			// Current Search String Restriction
	CHAR		SEARCH2[20]			// Current Search String Being Edited
	INTEGER  dragBarActive		// Side Drag Bar is currently being interacted with
	INTEGER	PAGENO				// Current Page Number
	INTEGER	PAGESIZE				// Interface Page Size
	INTEGER	RECORDSELECTED
	(** Directory - retrieved from Codec **)
	INTEGER  ENTRYCOUNT
	(** Search Subset - created from user string and above **)
	INTEGER  SEARCHCOUNT
}

DEFINE_TYPE STRUCTURE uMXP{
	// Meta Data
	CHAR		META_MODEL[10]
	CHAR 		META_SW_VER[20]
	CHAR		META_SW_RELEASE[20]
	CHAR		META_SN[20]
	CHAR		META_SYS_NAME[20]
	// System State
	INTEGER	SYS_MULTISITE
	FLOAT 	SYS_TEMP
	LONG		SYS_UPTIME
	CHAR 		SYS_IP[15]

	// Control State
	INTEGER	MIC_MUTE
	INTEGER	SELF_VIEW
	INTEGER  NEAR_CAMERA				// Which near camera to control

	// Other
	CHAR 		DIAL_STRING[255]
	INTEGER	ContentTx

	// Presets
	INTEGER	PRESETS_LOADING
	uPreset	PRESET[MAX_PRESETS]
	INTEGER	curPreset
	INTEGER	FORCE_PRESET_COUNT	// A number of presets this system always shows

	// Comms
	INTEGER	DISABLED
	INTEGER 	DEBUG
	INTEGER	isIP
	INTEGER 	CONN_STATE
	INTEGER 	PEND
	CHAR 	  	Rx[8000]
	CHAR 	  	Tx[4000]
	CHAR 		Username[25]
	CHAR		Password[25]
	CHAR		BAUD[10]
	CHAR 		IP_HOST[15]
	INTEGER 	IP_PORT
	CHAR     CurRxStatusPacket[250]

	// Call State
	uCall		ACTIVE_CALLS[MAX_CALLS]

	// Directory
	uDir		DIRECTORY
}


DEFINE_TYPE STRUCTURE uMXPPanel{
	INTEGER DIAL_CAPS
	INTEGER DIAL_SHIFT
	INTEGER DIAL_NUMLOCK
	INTEGER SEARCH_NUMLOCK
}
/******************************************************************************
	GUI Interface levels
******************************************************************************/
DEFINE_CONSTANT
INTEGER lvlDIR_ScrollBar 	= 2
/******************************************************************************
	Interface Text Fields
******************************************************************************/
// Meta Data
INTEGER addDirSearch		    = 57
INTEGER addIncomingCallName = 58
INTEGER addVCCallStatus[]	 = {61,62,63,64,65}
/******************************************************************************
	Button Numbers - General Control
******************************************************************************/
DEFINE_CONSTANT
(**	SelfView Toggle		**)
INTEGER btnSelfViewMode	= 202
(**	SelfView Toggle		**)
INTEGER btnSelfViewPos[]= {203,204}
(**	Hang Up Calls		**)
INTEGER btnHangup[] = {
	210,211,212,213,214,215	// ALL | Call 1..5
}
(**	Answer Calls		**)
INTEGER btnAnswer[] = {
	220,221,222,223,224,225	// ALL | Call 1..5
}
(**	Reject Calls		**)
INTEGER btnReject[] = {
	230,231,232,233,234,235	// ALL | Call 1..5
}

(** Dialing Interface **)
INTEGER btnDialString 	= 250						// Address for DialString
INTEGER btnDialKB[] = {
	251,252,253,254,255,256,257,258,259,260,	// Row One
	261,262,263,264,265,266,267,268,269,		// Row Two
	270,271,272,273,274,275,276,					// Row Three
	277,	// SPACE
	278,	// SHIFT
	279,	// CAPS
	280,	// NUMLOCK
	281,	// DELETE
	282,	// DIAL
	283,	// NUMLOCK ON
	284	// NUMLOCK OFF
}
INTEGER btnDialSpecial[]={
	290,291,292
}

(**	Send DTMF Tones	**)
(**	340..349 | 0..9	**)
(**	350		| *		**)
(**	351		| #		**)
(**							**)
INTEGER btnDTMF[] = {
	340,341,342,343,344,345,346,347,348,349,350,351
}

/******************************************************************************
	Button Numbers - Near Side Camera Control
******************************************************************************/
INTEGER addCamNearPresetArea = 400
INTEGER btnCamNearPreset[] = {
	401,402,403,404,405,406,407,408,409,410,
	411,412,413,414,415
}
INTEGER btnCamNearSelect[] = {
	441,442,443,444,445,446,447
}
INTEGER btnCamNearControl[] = {
(**UP| DN| LT| RT| Z+| Z- **)
	451,452,453,454,455,456
}
/******************************************************************************
	Button Numbers - Directory Control
******************************************************************************/
INTEGER btnDirLoading 		= 601
INTEGER btnDirBreadCrumbs 	= 602
INTEGER btnDirSearchBar1 	= 603
INTEGER btnDirPage			= 604
INTEGER btnDirSearchBar2 	= 605
INTEGER btnDirType[]       = {606,607,608} // Local/Corporate/Toggle

INTEGER btnDirRecords[] = {
	11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
}

INTEGER btnDirControl[] = {
	651,652,653,654	// PREV|NEXT|RESET|CLEARSEARCH
}
INTEGER btnDirDial	 	= 655

INTEGER btnDirSearchKB[] = {
	661,662,663,664,665,666,667,668,669,670,	// Row One
	671,672,673,674,675,676,677,678,679,		// Row Two
	680,681,682,683,684,685,686,					// Row Three
	687,	// SPACE
	688,	// SHIFT
	689,	// CAPS
	690,	// NUMLOCK
	691,	// DELETE
	692,	// SUBMIT
	693	// CANCEL
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_REBOOT 		= 1
LONG TLID_COMMS  		= 2
LONG TLID_POLL	  		= 3
LONG TLID_TIMER  		= 4
LONG TLID_VOL			= 5
LONG TLID_TIMEOUT		= 6
LONG TLID_RETRY		= 7
LONG TLID_CALL_EVENT	= 8

INTEGER CONN_OFFLINE 	= 0
INTEGER CONN_TRYING		= 1
INTEGER CONN_NEGOTIATE	= 2
INTEGER CONN_SECURITY	= 3
INTEGER CONN_CONNECTED	= 4

INTEGER DEBUG_ERROR		= 0	// Only Errors Reported
INTEGER DEBUG_BASIC		= 1	// General Debugging
INTEGER DEBUG_DEVELOP	= 2	// Detailed Debugging

INTEGER chnNearCam[] = {101,102,103,104,105,106}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_REBOOT[]		= {3000}
LONG TLT_COMMS[]  	= {120000}
LONG TLT_POLL[]   	= {45000}
LONG TLT_TIMEOUT[]	= {20000}
LONG TLT_RETRY[]		= {2000}
LONG TLT_CALL_EVENT[]= {1000}

VOLATILE  uMXP   		myMXP
VOLATILE  uMXPPanel	myMXPPanel[5]
uDirEntry DIRLIST[DIRSIZE]
uDirEntry SEARCHLIST[DIRSIZE]

DEFINE_VARIABLE
CHAR DialKB[3][26] = {
		{		// 1 - Lower Case Letters
		'qwertyuiopasdfghjklzxcvbnm'
		},{	// 2 - Upper Case Letters
		'QWERTYUIOPASDFGHJKLZXCVBNM'
		},{	// 3 - Digits
		'1234567890            _-#:'
	}
}
CHAR DialSpecial[3][4] = {
	{'.'},
	{'.com'},
	{'@'}
}
CHAR DialSpecial_Alt[3][4]	// Characters after holding DialSpecial for 1sec

/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
(** IP Connection Helpers **)
DEFINE_FUNCTION fnRetryTCPConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myMXP.IP_HOST == ''){
		fnDebug(DEBUG_ERROR,'ERR: MXP','No IP Address')
	}
	ELSE{
		fnDebug(DEBUG_BASIC,'TryIP>MXP on',"myMXP.IP_HOST,':',ITOA(myMXP.IP_PORT)")
		myMXP.CONN_STATE = CONN_TRYING
		SWITCH(myMXP.IP_PORT){
			CASE 23: IP_CLIENT_OPEN(dvVC.port, myMXP.IP_HOST, myMXP.IP_PORT, IP_TCP)
		}
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	SWITCH(myMXP.IP_PORT){
		CASE 23: IP_CLIENT_CLOSE(dvVC.port)
	}
}

DEFINE_FUNCTION fnQueueTx(CHAR pCommand[255], CHAR pParam[255]){
	fnDebug(DEBUG_DEVELOP,'fnQueueTX',"'[',ITOA(LENGTH_ARRAY(myMXP.Tx)),']',pCommand,' ', pParam,$0D")
	myMXP.Tx = "myMXP.Tx,pCommand,' ', pParam,$0D"
	fnSendTx()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendTx(){
	IF((!myMXP.isIP || myMXP.CONN_STATE == CONN_CONNECTED) && !myMXP.PEND){
		IF(FIND_STRING(myMXP.Tx,"$0D",1)){
			STACK_VAR CHAR toSend[200]
			toSend = REMOVE_STRING(myMXP.Tx,"$0D",1)
			fnDebug(DEBUG_BASIC,'->VC ',toSend)
			SEND_STRING dvVC, toSend
			myMXP.PEND = TRUE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myMXP.PEND = FALSE
	myMXP.TX = ''
	IF(myMXP.ISIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pTYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myMXP.DEBUG >= pTYPE){
		IF(MsgData[1] == $FF){	// Telnet Raw Data - make readable(ish)
			STACK_VAR CHAR msg_ascii[40]
			STACK_VAR INTEGER x
			FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
				msg_ascii = "msg_ascii,fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2),','"
			}
			msg_ascii = fnStripCharsRight(msg_ascii,1)
			SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',fnPadLeadingChars(Msg,' ',12), ' |', msg_ascii"
		}
		ELSE{
			SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',fnPadLeadingChars(Msg,' ',12), ' |', MsgData"
		}
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnInitData(){
	fnQueueTx('echo','off')
	fnQueueTx('xFeedback register','/Status/SystemUnit')
	fnQueueTx('xFeedback register','/Status/Video/Selfview')
	fnQueueTx('xFeedback register','/Status/Call')
	fnQueueTx('xFeedback register','/Status/Conference')
	fnQueueTx('xFeedback register','/Status/Standby')
	fnQueueTx('xFeedback register','/Status/Ethernet')
	fnQueueTx('xFeedback register','/Status/IP')
	fnQueueTx('xFeedback register','/Configuration/Audio')

	fnQueueTx('xStatus','SystemUnit')
	fnQueueTx('xStatus','Video Selfview')
	fnQueueTx('xStatus','Call 1')
	fnQueueTx('xStatus','Call 2')
	fnQueueTx('xStatus','Call 3')
	fnQueueTx('xStatus','Call 4')
	fnQueueTx('xStatus','Call 5')
	fnQueueTx('xStatus','Call 6')
	fnQueueTx('xStatus','Call 7')
	fnQueueTx('xStatus','Standby')
	fnQueueTx('xStatus','Ethernet')
	fnQueueTx('xStatus','IP')
	fnQueueTx('xConfiguration','Audio')

	fnInitPoll()
	fnInitDirectory()
}
DEFINE_FUNCTION fnPoll(){
	fnQueueTx('xStatus','SystemUnit')
	fnQueueTx('xStatus','IP')
}

DEFINE_FUNCTION fnResetData(){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= MAX_CALLS; x++){
		STACK_VAR uCALL blankCall
		myMXP.ACTIVE_CALLS[x] = blankCall
	}
	myMXP.SYS_IP   			= ''
	myMXP.META_MODEL 			= ''
	myMXP.META_SW_VER 		= ''
	myMXP.META_SW_RELEASE 	= ''
	myMXP.META_SN 				= ''
	myMXP.SYS_TEMP 			= 0
	myMXP.SYS_UPTIME 			= 0
	myMXP.Tx = ''
	myMXP.Rx = ''
}
/******************************************************************************
	Utility Functions - Device Feedback
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER ProfileIndex
	fnDebug(DEBUG_BASIC,'MXP-> ',pDATA)
	IF(pDATA == ''){		 RETURN FALSE}
	ELSE IF(pDATA == 'Command not recognized.'){
		myMXP.PEND = FALSE
		WAIT 10{
			IF(myMXP.ISIP){
				fnCloseTCPConnection()
			}
			ELSE{
				myMXP.Tx = ''
				fnInitData()
			}
		}
	}
	ELSE IF(pDATA == 'OK' || pDATA == 'ERROR' || pDATA == 'off' || pDATA == 'on'){
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		IF(pDATA == 'OK' && myMXP.DIRECTORY.LOADING){
			fnDirViewReload()
		}
		RETURN TRUE
	}
	ELSE IF(LEFT_STRING(pDATA,2) == '*c'){
		// Some packets on same line
		SWITCH(fnGetSplitStringValue(pDATA,':',1)){
			CASE '*c xConfiguration Audio Microphones Mode':{
				SWITCH(fnGetSplitStringValue(pDATA,':',2)){
					CASE 'Off': myMXP.MIC_MUTE = TRUE
					CASE 'On':	myMXP.MIC_MUTE = FALSE
				}
				IF(myMXP.PEND){
					RETURN TRUE
				}
			}
		}
		SWITCH(fnGetSplitStringValue(pDATA,' ',2)){
			CASE 'xDirectory':{
				STACK_VAR INTEGER pEntry
				myMXP.DIRECTORY.LOADING = TRUE
				pEntry = ATOI(fnGetSplitStringValue(pDATA,' ',4))
				IF(myMXP.DIRECTORY.TYPE = ''){myMXP.DIRECTORY.TYPE = 'LocalEntry'}
				IF(fnGetSplitStringValue(pDATA,' ',3) == myMXP.DIRECTORY.TYPE){
					// Strip this down to just the value:
					STACK_VAR CHAR CmdPart[200]
					cmdPart = REMOVE_STRING(pDATA,':',1)
					// This is our directory type
					SWITCH(fnGetSplitStringValue(cmdPart,' ',5)){
						CASE 'Name:':   DIRLIST[pEntry].NAME   = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
						CASE 'Number:': DIRLIST[pEntry].NUMBER = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
					}
					myMXP.DIRECTORY.ENTRYCOUNT = pEntry
				}
			}
		}
	}
	ELSE IF(pData == '*s/end'){
		// Status Message Ended
		myMXP.CurRxStatusPacket = ''
		RETURN TRUE
	}
	ELSE IF(LEFT_STRING(pDATA,2) == '*s'){
		myMXP.CurRxStatusPacket = fnGetSplitStringValue(pDATA,':',1)
		// Deal with 'Call' which has info on start line
		IF(LEFT_STRING(myMXP.CurRxStatusPacket,7) == '*s Call'){
			STACK_VAR INTEGER pCallID
			STACK_VAR CHAR pDetails[1000]
			pDetails = myMXP.CurRxStatusPacket
			myMXP.CurRxStatusPacket = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDetails,'(',1),1))
			pDetails = fnStripCharsRight(pDetails,1)	// Strip Rear Bracket
			// Get Call ID
			pCallId = ATOI(fnGetSplitStringValue(myMXP.CurRxStatusPacket,' ',3))
			//	Extract Detail
			myMXP.ACTIVE_CALLS[pCallID].STATUS    = fnGetSplitStringValue(fnGetCSV(pDetails,1),'=',2)
			myMXP.ACTIVE_CALLS[pCallID].TYPE      = fnGetSplitStringValue(fnGetCSV(pDetails,2),'=',2)
			myMXP.ACTIVE_CALLS[pCallID].PROTOCOL  = fnGetSplitStringValue(fnGetCSV(pDetails,3),'=',2)
			myMXP.ACTIVE_CALLS[pCallID].DIRECTION = fnGetSplitStringValue(fnGetCSV(pDetails,4),'=',2)

		}
	}
	ELSE IF(LENGTH_ARRAY(myMXP.CurRxStatusPacket)){
		// Local Variables
		STACK_VAR CHAR pKey[30]
		STACK_VAR CHAR pValue[50]
		// Get Values
		pKey   = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
		pValue = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))

		SWITCH(myMXP.CurRxStatusPacket){
			CASE '*s SystemUnit':{
				SWITCH(pKey){
					CASE 'SerialNumber':			myMXP.META_SN = pValue
					CASE 'ProductId':   			myMXP.META_MODEL = pValue
					CASE 'Version':     			myMXP.META_SW_VER = pValue
					CASE 'ReleaseDate': 			myMXP.META_SW_RELEASE = pValue
					CASE 'Uptime':      			myMXP.SYS_UPTIME = ATOI(pValue)
					CASE 'TemperatureCelcius': myMXP.SYS_TEMP = ATOI(pValue)
				}
			}
			CASE '*s IP':{
				SWITCH(pKey){
					CASE 'Address':				myMXP.SYS_IP = pValue
				}
			}
			CASE '*s Call 1':
			CASE '*s Call 2':
			CASE '*s Call 3':{
				STACK_VAR INTEGER pCallID
				pCallID = ATOI(fnGetSplitStringValue(myMXP.CurRxStatusPacket,' ',3))
				SWITCH(pKey){
					CASE 'Mute':				myMXP.ACTIVE_CALLS[pCallID].isMuted = (pValue == 'On')
					CASE 'RemoteNumber':{
						myMXP.ACTIVE_CALLS[pCallID].NUMBER = pValue
						fnSendCallDetail(0,pCallID)
					}
				}
			}
		}
	}
}
/******************************************************************************
	Utility Functions - Call Handling
******************************************************************************/
DEFINE_CONSTANT
INTEGER CALL_STATE_IDLE       = 0
INTEGER CALL_STATE_CONNECTING = 1
INTEGER CALL_STATE_CONNECTED  = 2
DEFINE_FUNCTION INTEGER fnGetCallState(INTEGER pCallID){
	SWITCH(myMXP.ACTIVE_CALLS[pCallID].STATUS){
		CASE 'Idle':
		CASE 'ClearOut':
		CASE 'Disconnected':{
			RETURN CALL_STATE_IDLE
		}
		CASE 'EstablOut':
		CASE 'Proceeding':
		CASE 'Alerting':{
			RETURN CALL_STATE_CONNECTING
		}
		CASE 'Synced':
		CASE 'Connected':{
			RETURN CALL_STATE_CONNECTED
		}
	}
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER c
	STACK_VAR INTEGER CALL_RINGING
	STACK_VAR INTEGER CALL_DIALLING
	STACK_VAR INTEGER CALL_CONNECTED
	FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
		[vdvCalls[c],236] = (myMXP.ACTIVE_CALLS[c].DIRECTION == 'Incoming' && fnGetCallState(c) == CALL_STATE_CONNECTING)
		[vdvCalls[c],237] = (myMXP.ACTIVE_CALLS[c].DIRECTION == 'Outgoing' && fnGetCallState(c) == CALL_STATE_CONNECTING )
		[vdvCalls[c],238] =  fnGetCallState(c) == CALL_STATE_CONNECTED
		IF([vdvCalls[c],236]){ CALL_RINGING = TRUE }
		IF([vdvCalls[c],237]){ CALL_DIALLING = TRUE }
		IF([vdvCalls[c],238]){ CALL_CONNECTED = TRUE }
		SELECT{
			ACTIVE ([vdvCalls[c],236]):{	SEND_LEVEL vdvCalls[c],1,236	}
			ACTIVE ([vdvCalls[c],237]):{	SEND_LEVEL vdvCalls[c],1,237	}
			ACTIVE ([vdvCalls[c],238]):{	SEND_LEVEL vdvCalls[c],1,238	}
			ACTIVE (TRUE):{					SEND_LEVEL vdvCalls[c],1,0		}
		}
	}
	[vdvControl,236] = CALL_RINGING
	[vdvControl,237] = CALL_DIALLING
	[vdvControl,238] = CALL_CONNECTED

}

/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	myMXP.isIP = !(dvVC.NUMBER)
	CREATE_BUFFER dvVC, myMXP.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvVC]{
	ONLINE:{
		IF(!myMXP.DISABLED){
			IF(myMXP.isIP){
				myMXP.CONN_STATE = CONN_NEGOTIATE
			}
			ELSE{
				IF(myMXP.BAUD = ''){ myMXP.BAUD = '115200' }
				SEND_COMMAND dvVC, "'SET BAUD ',myMXP.BAUD,' N 8 1 485 DISABLE'"
				myMXP.CONN_STATE = CONN_CONNECTED
				fnPoll()
				fnInitPoll()
			}
		}
	}
	OFFLINE:{
		IF(myMXP.isIP){
			myMXP.CONN_STATE 	= CONN_OFFLINE;
			fnResetData()
			fnReTryTCPConnection()
		}
	}
	ONERROR:{
		IF(myMXP.isIP){
			STACK_VAR CHAR _MSG[255]
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
				CASE 18:{_MSG = 'SSH Login Error'}					// Error with SSH Credentials
				DEFAULT:{_MSG = 'Error Undefined'}					// No idea what the error is
			}
			SWITCH(DATA.NUMBER){
				CASE 14:{}		// Local Port Already Used
				DEFAULT:{
					myMXP.CONN_STATE	= CONN_OFFLINE
					fnResetData()
					fnReTryTCPConnection()
				}
			}
			fnDebug(DEBUG_ERROR,"'ERR SX: [',myMXP.IP_HOST,':',ITOA(myMXP.IP_PORT),']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myMXP.DISABLED){

			// Telnet Negotiation
			WHILE(myMXP.Rx[1] == $FF && LENGTH_ARRAY(myMXP.Rx) >= 3){
				STACK_VAR CHAR NEG_PACKET[3]
				NEG_PACKET = GET_BUFFER_STRING(myMXP.Rx,3)
				fnDebug(DEBUG_DEVELOP,'SX.Telnet->',NEG_PACKET)
				SWITCH(NEG_PACKET[2]){
					CASE $FB:
					CASE $FC:NEG_PACKET[2] = $FE
					CASE $FD:
					CASE $FE:NEG_PACKET[2] = $FC
				}
				fnDebug(DEBUG_DEVELOP,'->SX.Telnet',NEG_PACKET)
				SEND_STRING DATA.DEVICE,NEG_PACKET
			}

			// Security Negotiation
			IF(FIND_STRING(myMXP.Rx,'Welcome to',1)){
				myMXP.CONN_STATE = CONN_SECURITY
				fnDebug(DEBUG_DEVELOP,'SX->',myMXP.Rx)
			}
			IF(FIND_STRING(myMXP.Rx,'Password:',1)){
				fnDebug(DEBUG_DEVELOP,'SX->',myMXP.Rx)
				myMXP.Rx = ''
				fnDebug(DEBUG_DEVELOP,'->SX',"myMXP.Password,$0D")
				SEND_STRING dvVC, "myMXP.Password,$0D"
			}
			ELSE IF(FIND_STRING(myMXP.Rx,'OK',1) && myMXP.CONN_STATE == CONN_SECURITY){
				fnDebug(DEBUG_DEVELOP,'VC.Rx->',myMXP.Rx)
				myMXP.Rx = ''
				myMXP.Tx = ''
				myMXP.PEND = FALSE
				myMXP.CONN_STATE = CONN_CONNECTED
				WAIT 10{
					fnInitData()
				}
			}
			ELSE{
				IF(myMXP.CONN_STATE == CONN_CONNECTED){
					WHILE(FIND_STRING(myMXP.Rx,"$0D,$0A",1)){
						IF(fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMXP.Rx,"$0D,$0A",1),2))){
							myMXP.PEND = FALSE
							fnSendTx()
							IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
							TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
			}
		}
	}
}
DEFINE_EVENT
CHANNEL_EVENT[vdvCalls,236]
CHANNEL_EVENT[vdvCalls,237]
CHANNEL_EVENT[vdvCalls,238]{
	OFF:fnCallEvent()
	ON: fnCallEvent()
}

DEFINE_FUNCTION fnCallEvent(){
	IF(TIMELINE_ACTIVE(TLID_CALL_EVENT)){TIMELINE_KILL(TLID_CALL_EVENT)}
	TIMELINE_CREATE(TLID_CALL_EVENT,TLT_CALL_EVENT,LENGTH_ARRAY(TLT_CALL_EVENT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_CALL_EVENT]{
	fnSendCallDetail(0,0)
}

DEFINE_FUNCTION fnRecallPreset(INTEGER pPresetID){
	fnQueueTx('xCommand',"'PresetActivate number: ', ITOA(pPresetID)")
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'RANGE-0,100'
	}
	COMMAND:{
		IF(DATA.TEXT == 'PROPERTY-ENABLED,FALSE'){
			myMXP.DISABLED = TRUE
		}
		IF(!myMXP.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'DEVELOPER':{
					SWITCH(DATA.TEXT){
						CASE 'INIT':{
							fnInitData()
						}
						CASE 'DISCONNECT':{
							fnCloseTCPConnection()
						}
						CASE 'CONNECT':{
							fnOpenTCPConnection()
						}
					}
				}
				CASE 'ACTION':{
					SWITCH(DATA.TEXT){
						CASE 'WAKE':{ 			fnQueueTx('xCommand','ScreensaverDeactivate') }
						CASE 'SLEEP':{
							myMXP.DIAL_STRING = ''
							fnUpdatePanelDialString(0)
							fnQueueTx('xCommand','ScreensaverActivate')
						}
						CASE 'HANGUP':{
							fnQueueTx('xCommand','DisconnectCall')
						}
						CASE 'RESETGUI':{
							myMXP.DIAL_STRING = ''
							fnUpdatePanelDialString(0)
						}
						CASE 'RESETDIR':{
							fnDirViewReload()
						}
					}
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'USERNAME':{ myMXP.Username = DATA.TEXT }
						CASE 'PASSWORD':{ myMXP.Password = DATA.TEXT }
						CASE 'BAUD':{
							myMXP.BAUD = DATA.TEXT;
							SEND_COMMAND dvVC, "'SET BAUD ',myMXP.BAUD,' N 8 1 485 DISABLE'"
							fnInitData()
						}
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'DEV':	myMXP.DEBUG = DEBUG_DEVELOP
								CASE 'TRUE':myMXP.DEBUG = DEBUG_BASIC
							}
						}
						CASE 'LOGIN':{
							myMXP.Username = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							myMXP.Password = DATA.TEXT
						}
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myMXP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myMXP.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myMXP.IP_HOST = DATA.TEXT
								myMXP.IP_PORT = 23
							}
							fnReTryTCPConnection()
						}
						CASE 'DIRECTORY':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'TYPE':{
									SWITCH(DATA.TEXT){
										CASE 'CORPORATE':myMXP.DIRECTORY.TYPE = 'GlobalEntry'
										CASE 'LOCAL':    myMXP.DIRECTORY.TYPE = 'LocalEntry'
									}
								}
								CASE 'PAGESIZE':{
									myMXP.DIRECTORY.PAGESIZE = ATOI(DATA.TEXT)
								}
							}
						}
						CASE 'SET_KEYBOARD':{
							STACK_VAR CHAR pKeyB[20]
							pKeyB = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							SWITCH(pKeyB){
								CASE 'MAIN1':			DialKB[1] = DATA.TEXT
								CASE 'MAIN2':			DialKB[2] = DATA.TEXT
								CASE 'MAIN3':			DialKB[3] = DATA.TEXT
								CASE 'SPECIAL':
								CASE 'SPECIAL_ALT':{
									STACK_VAR INTEGER x
									WHILE(FIND_STRING(DATA.TEXT,',',1)){
										x = x+1
										SWITCH(pKeyB){
											CASE 'SPECIAL':		DialSpecial[x] 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
											CASE 'SPECIAL_ALT':	DialSpecial_Alt[x] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
										}
									}
									x = x+1
									SWITCH(pKeyB){
										CASE 'SPECIAL':		DialSpecial[x] 		= DATA.TEXT
										CASE 'SPECIAL_ALT':	DialSpecial_Alt[x] 	= DATA.TEXT
									}
								}
							}
							fnDrawDialKB(0)
						}
						CASE 'PRESET':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'FORCE_STRUCTURED':{
									myMXP.FORCE_PRESET_COUNT = ATOI(DATA.TEXT)
								}
							}
						}
					}
				}
				CASE 'RAW': 	fnQueueTx(DATA.TEXT,'')
				CASE 'REMOTE': fnQueueTx('xCommand Key',"'Click Key:',DATA.TEXT")
				CASE 'PRESET':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'RECALL':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'NEAR':{
									fnRecallPreset(ATOI(DATA.TEXT))
								}
							}
						}
					}
				}
				CASE 'CONTENT':{
					SWITCH(DATA.TEXT){
						CASE 'START': fnQueueTx('xCommand', 'DuoVideoStart'); myMXP.ContentTx = TRUE;
						CASE 'STOP':
						CASE '0':     fnQueueTx('xCommand', 'DuoVideoStop');  myMXP.ContentTx = FALSE;
						DEFAULT:		  fnQueueTx('xCommand',"'DuoVideoStart VideoSource:',DATA.TEXT");	  myMXP.ContentTx = TRUE;
					}
				}
				CASE 'DIAL':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'AUDIO':
						CASE 'AUTO':
						CASE 'VIDEO':fnQueueTx('xCommand Dial',"'Number:',DATA.TEXT,' CallRate:auto'")
					}
				}
				CASE 'DTMF':{
					fnQueueTx('xCommand DTMFSend',"'Value:',DATA.TEXT")
				}
				CASE 'SELFVIEW':{
					SWITCH(DATA.TEXT){
						CASE 'OFF':{fnQueueTx('xCommand','PIPHide VirtualMonitor:1')}
						CASE 'ON':{ fnQueueTx('xCommand','PIPShow VirtualMonitor:1 Picture:LocalMain')}
					}
				}
				CASE 'MICMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON': 		myMXP.MIC_MUTE = TRUE
						CASE 'OFF': 	myMXP.MIC_MUTE = FALSE
						CASE 'TOGGLE':	myMXP.MIC_MUTE = !myMXP.MIC_MUTE
					}
					SWITCH(myMXP.MIC_MUTE){
						CASE TRUE:  fnQueueTx('xConfiguration','Audio Microphones Mode: Off');
						CASE FALSE: fnQueueTx('xConfiguration','Audio Microphones Mode: On');
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
	IF(!myMXP.DISABLED){
		STACK_VAR INTEGER c;
		FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
			[vdvCalls[c],198] = (myMXP.ACTIVE_CALLS[c].isMUTED)
		}
		[vdvControl,198] = (myMXP.MIC_MUTE)
		[vdvControl,241] = (myMXP.ContentTx)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	}
}

/******************************************************************************
	User Interface Control
******************************************************************************/
/******************************************************************************
	UI Helpers
******************************************************************************/
DEFINE_FUNCTION fnInitPanel(INTEGER pPanel){
	IF(pPanel == 0){
		STACK_VAR INTEGER p; FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){ fnInitPanel(p) }
		RETURN
	}
	fnUpdatePanelDialString(pPanel)
	fnSendCallDetail(pPanel,0)
	fnDrawDialKB(pPanel)
	fnDrawSearchKB(pPanel)
	SEND_COMMAND tp[pPanel], "'^GLL-',ITOA(lvlDIR_ScrollBar),',1'"

}

DEFINE_FUNCTION INTEGER fnGetDialKB(INTEGER pPanel){
	IF(myMXPPanel[pPanel].DIAL_NUMLOCK){
		RETURN 3
	}
	ELSE IF(myMXPPanel[pPanel].DIAL_CAPS && !myMXPPanel[pPanel].DIAL_SHIFT){
		RETURN 2
	}
	ELSE IF(myMXPPanel[pPanel].DIAL_SHIFT){
		RETURN 2
	}
	ELSE{
		RETURN 1
	}
}

DEFINE_FUNCTION fnDrawDialKB(INTEGER pPanel){
	STACK_VAR INTEGER x
	IF(!pPanel){
		STACK_VAR INTEGER p; FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){ fnDrawDialKB(p) }
		RETURN
	}
	FOR(x = 1; x <= 26; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialKB[x]),',0,',DialKB[fnGetDialKB(pPanel)][x]"
	}
	FOR(x = 1; x <= LENGTH_ARRAY(btnDialSpecial); x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialSpecial[x]),',0,',DialSpecial[x]"
	}
}
DEFINE_FUNCTION INTEGER fnGetSearchKB(INTEGER pPanel){
	IF(myMXPPanel[pPanel].SEARCH_NUMLOCK){
		RETURN 3
	}
	ELSE{
		RETURN 1
	}
}
DEFINE_FUNCTION fnDrawSearchKB(INTEGER pPanel){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 26; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDirSearchKB[x]),',0,',DialKB[1][x]"
	}
}

DEFINE_FUNCTION fnUpdatePanelDialString(INTEGER pPanel){
	IF(pPanel){SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialString),',0,',myMXP.DIAL_STRING"}
	ELSE{SEND_COMMAND tp,"'^TXT-',ITOA(btnDialString),',0,',myMXP.DIAL_STRING"}
	SEND_COMMAND tp,"'^SHO-',ITOA(btnDialKB[32]),',',ITOA(LENGTH_ARRAY(myMXP.DIAL_STRING) > 0)"
}

DEFINE_FUNCTION fnSendCallDetail(INTEGER pPanel, INTEGER pCALL){

	STACK_VAR CHAR pStateText[200]
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendCallDetail(p,pCALL)
		}
		RETURN
	}
	IF(!pCALL){
		STACK_VAR INTEGER c
		FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
			fnSendCallDetail(pPanel, c)
		}
		RETURN
	}
	pStateText =  UPPER_STRING(myMXP.ACTIVE_CALLS[pCALL].STATUS)
	pStateText = "pStateText,$0A,'Name:  ',myMXP.ACTIVE_CALLS[pCALL].NAME"
	pStateText = "pStateText,$0A,'Number:',myMXP.ACTIVE_CALLS[pCALL].NUMBER"

	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addVCCallStatus[pCall]),',2&3,',pStateText"
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnHangup[pCALL+1]),',',ITOA([vdvCalls[pCALL],236] || [vdvCalls[pCALL],237] || [vdvCalls[pCALL],238])"
}
/******************************************************************************
	Touch Panel Events - General
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		fnInitPanel(GET_LAST(tp))
	}
}


DEFINE_EVENT BUTTON_EVENT[tp,btnDTMF]{
	PUSH:{
		STACK_VAR CHAR cButtonCmd[20];
		SWITCH(GET_LAST(btnDTMF)){
			CASE 11:cButtonCmd = '*';
			CASE 12:cButtonCmd = '#';
			DEFAULT:cButtonCmd = ITOA(GET_LAST(btnDTMF) - 1);
		}
		fnQueueTx('xCommand DTMFSend',"'Value:',cButtonCmd")
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnHangup]{
	PUSH:{
		STACK_VAR INTEGER x
		SWITCH(GET_LAST(btnHangup)){
			CASE 1:{
				fnQueueTx('xCommand','DisconnectCall')
			}
			DEFAULT:{
				fnQueueTx('xCommand',"'DisconnectCall Call:',ITOA(GET_LAST(btnHangup)-1)")
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnAnswer]{
	PUSH:{
		SWITCH(GET_LAST(btnAnswer)){
			CASE 1:{
				fnQueueTx('xCommand',"'CallAccept'")
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnReject]{
	PUSH:{
		SWITCH(GET_LAST(btnReject)){
			CASE 1:{
				fnQueueTx('xCommand',"'DisconnectCall'")
			}
			DEFAULT:{
				fnQueueTx('xCommand',"'DisconnectCall Call:',ITOA(GET_LAST(btnReject)-1)")
			}
		}
	}
}
/******************************************************************************
	Touch Panel Events - Near Camera Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		fnSetupPresetButtons(GET_LAST(tp))
	}
}
DEFINE_FUNCTION fnSetupPresetButtons(INTEGER pPanel){
	STACK_VAR INTEGER p
	IF(!pPanel){
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSetupPresetButtons(p)
		}
		RETURN
	}
	IF(1){
		STACK_VAR INTEGER b
		STACK_VAR INTEGER y
		// Hide all preset buttons
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnCamNearPreset[1]),'.',ITOA(btnCamNearPreset[LENGTH_ARRAY(btnCamNearPreset)]),',0'"
/*
		FOR(b = 1; b <= LENGTH_ARRAY(btnCamNearPreset); b++){
			STACK_VAR pPreset
			FOR(pPreset = 1; pPreset <= MAX_PRESETS; pPreset++){
				IF(b == myMXP.PRESET[pPreset].PresetID){
					// Flag if a preset is found
					IF(myMXP.PRESET[pPreset].DEFINED){y = TRUE}

					SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnCamNearPreset[b]),',1'"
					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnCamNearPreset[b]),',0,',myMXP.PRESET[pPreset].NAME"
				}
			}
		}*/
		// Show / Hide preset area graphic if any presets are present
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(addCamNearPresetArea),',',ITOA(y)"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearPreset]{
	PUSH:{
		// To allow feedback on locking channel buttons
		TO[BUTTON.INPUT.DEVICE,BUTTON.INPUT.CHANNEL]
	}
	RELEASE:{
		fnRecallPreset(GET_LAST(btnCamNearPreset))
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearSelect]{
	PUSH:{
		myMXP.NEAR_CAMERA = GET_LAST(btnCamNearSelect)
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearControl]{
	PUSH:{
		TO[vdvControl,chnNearCam[GET_LAST(btnCamNearControl)]]
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,chnNearCam]{
	ON:{
		STACK_VAR CHAR pDir[255]
		IF(myMXP.NEAR_CAMERA == 0){
			myMXP.NEAR_CAMERA = 1
		}
		SWITCH(GET_LAST(chnNearCam)){
			CASE 1:pDir = 'Up'
			CASE 2:pDir = 'Down'
			CASE 3:pDir = 'Left'
			CASE 4:pDir = 'Right'
			CASE 5:pDir = 'In'
			CASE 6:pDir = 'Out'
		}
		fnQueueTx('xCommand',"'CameraMove Camera:1 Direction:',pDir")
	}
	OFF:{
		fnQueueTx('xCommand','CameraHalt Camera:1')
	}
}
/******************************************************************************
	Dialing Interface - Video
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDialKB]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SWITCH(GET_LAST(btnDialKB)){
			CASE 27:{	// SPACE
				myMXP.DIAL_STRING = "myMXP.DIAL_STRING,' '"
				fnUpdatePanelDialString(0)
			}
			CASE 28:{	// SHIFT
				myMXPPanel[p].DIAL_SHIFT = !myMXPPanel[p].DIAL_SHIFT
				fnDrawDialKB(p)
			}
			CASE 29:{	// CAPS
				myMXPPanel[p].DIAL_CAPS = !myMXPPanel[p].DIAL_CAPS
				fnDrawDialKB(p)
			}
			CASE 30:{	// NUMLOCK
				myMXPPanel[p].DIAL_NUMLOCK = !myMXPPanel[p].DIAL_NUMLOCK
				fnDrawDialKB(p)
			}
			CASE 31:{	// DELETE
				myMXP.DIAL_STRING = fnStripCharsRight(myMXP.DIAL_STRING,1)
				fnUpdatePanelDialString(0)
			}
			CASE 32:{	// DIAL
				IF(LENGTH_ARRAY(myMXP.DIAL_STRING)){
					fnQueueTx('xCommand Dial',"'CallType:Video Number:',myMXP.DIAL_STRING")
				}
			}
			CASE 33:{	// NUMLOCK ON
				myMXPPanel[p].DIAL_NUMLOCK = TRUE
				fnDrawDialKB(p)
			}
			CASE 34:{	// NUMLOCK OFF
				myMXPPanel[p].DIAL_NUMLOCK = FALSE
				fnDrawDialKB(p)
			}
			DEFAULT:{
				STACK_VAR INTEGER kb
				kb = fnGetDialKB(p)
				IF(DialKB[kb][GET_LAST(btnDialKB)] != ' '){
					myMXP.DIAL_STRING = "myMXP.DIAL_STRING,DialKB[kb][GET_LAST(btnDialKB)]"
					fnUpdatePanelDialString(0)
					IF(myMXPPanel[p].DIAL_SHIFT){
						myMXPPanel[p].DIAL_SHIFT = FALSE
						fnDrawDialKB(p)
					}
				}
			}
		}
	}
	HOLD[4]:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		SWITCH(GET_LAST(btnDialKB)){
			CASE 31:{	// CLEAR
				myMXP.DIAL_STRING = ''
				fnUpdatePanelDialString(0)
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT [tp,btnDialSpecial]{
	PUSH:{
		STACK_VAR INTEGER k
		k = GET_LAST(btnDialSpecial)
		IF(DialSpecial[k] != ''){
			myMXP.DIAL_STRING = "myMXP.DIAL_STRING,DialSpecial[k]"
			fnUpdatePanelDialString(0)
		}
	}
	HOLD[10]:{
		STACK_VAR INTEGER k
		k = GET_LAST(btnDialSpecial)
		IF(DialSpecial_Alt[k] != ''){
			myMXP.DIAL_STRING = fnStripCharsRight(myMXP.DIAL_STRING,1)
			myMXP.DIAL_STRING = "myMXP.DIAL_STRING,DialSpecial_Alt[k]"
			fnUpdatePanelDialString(0)
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		[tp[p],btnDialKB[28]] = myMXPPanel[p].DIAL_SHIFT
		[tp[p],btnDialKB[29]] = myMXPPanel[p].DIAL_CAPS
		[tp[p],btnDialKB[30]] = myMXPPanel[p].DIAL_NUMLOCK
	}
}
/******************************************************************************
	Directory Interface
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDirLoading]{
	PUSH:{
		IF(!myMXP.DIRECTORY.LOADING){
			fnDirViewReload()
		}
	}
}

DEFINE_FUNCTION fnInitDirectory(){
	STACK_VAR INTEGER x
	fnDirViewClear()
	myMXP.DIRECTORY.LOADING = TRUE
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirBreadCrumbs),',0,Loading...'"
	FOR(x = 1; x <= DIRSIZE; x++){
		STACK_VAR uDirEntry pENTRY
		DIRLIST[x] = pENTRY
	}
	myMXP.DIRECTORY.ENTRYCOUNT = 0
	myMXP.DIRECTORY.SEARCH1 = ''
	myMXP.DIRECTORY.SEARCH2 = ''
	fnQueueTx('xDirectory','')
}
DEFINE_FUNCTION fnDirViewReload(){
	STACK_VAR INTEGER start
	STACK_VAR INTEGER x
	IF(myMXP.DIRECTORY.PAGESIZE == 0){myMXP.DIRECTORY.PAGESIZE = 6}
	start = myMXP.DIRECTORY.PAGENO * myMXP.DIRECTORY.PAGESIZE - myMXP.DIRECTORY.PAGESIZE
	IF(myMXP.DIRECTORY.PAGENO == 1){
		SELECT{
			ACTIVE(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)):{
				SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,',myMXP.DIRECTORY.SEARCH1"
			}
			ACTIVE(1):{
				SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,'"
			}
		}
		IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
			IF(myMXP.DIRECTORY.SEARCHCOUNT > myMXP.DIRECTORY.PAGESIZE){
				STACK_VAR FLOAT y
				y = myMXP.DIRECTORY.SEARCHCOUNT MOD myMXP.DIRECTORY.PAGESIZE
				y = myMXP.DIRECTORY.SEARCHCOUNT - y + myMXP.DIRECTORY.PAGESIZE
				y = y / myMXP.DIRECTORY.PAGESIZE

				SEND_COMMAND tp, "'^GLL-',ITOA(lvlDIR_ScrollBar),',1'"
				SEND_COMMAND tp, "'^GLH-',ITOA(lvlDIR_ScrollBar),',',FTOA(y)"
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',1'"
			}
			ELSE{
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
			}
		}
		ELSE{
			IF(myMXP.DIRECTORY.ENTRYCOUNT > myMXP.DIRECTORY.PAGESIZE){
				STACK_VAR FLOAT y
				y = myMXP.DIRECTORY.ENTRYCOUNT MOD myMXP.DIRECTORY.PAGESIZE
				y = myMXP.DIRECTORY.ENTRYCOUNT - y + myMXP.DIRECTORY.PAGESIZE
				y = y / myMXP.DIRECTORY.PAGESIZE

				SEND_COMMAND tp, "'^GLL-',ITOA(lvlDIR_ScrollBar),',1'"
				SEND_COMMAND tp, "'^GLH-',ITOA(lvlDIR_ScrollBar),',',FTOA(y)"
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',1'"
			}
			ELSE{
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
			}
		}
	}
	IF(1){
		STACK_VAR INTEGER y
		FOR(x = 1; x <= myMXP.DIRECTORY.PAGESIZE; x++){
			IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
				IF(start + x <= myMXP.DIRECTORY.SEARCHCOUNT){
					SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[x]),',0,',SEARCHLIST[x+start].NAME,' [',SEARCHLIST[x+start].NUMBER,']'"
					y = x
				}
			}
			ELSE{
				IF(start + x <= myMXP.DIRECTORY.ENTRYCOUNT){
					SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[x]),',0,',DIRLIST[x+start].NAME,' [',DIRLIST[x+start].NUMBER,']'"
					y = x
				}
			}
		}
		IF(y){
			SEND_COMMAND tp,"'^SHO-',ITOA(btnDirRecords[1]),'.',ITOA(btnDirRecords[y]),',1'"
		}
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDirRecords[y+1]),'.',ITOA(btnDirRecords[LENGTH_ARRAY(btnDirRecords)]),',0'"
	}
	myMXP.DIRECTORY.RECORDSELECTED = 0
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
	fnDisplaySearchStrings()
	myMXP.DIRECTORY.LOADING = FALSE
}

DEFINE_FUNCTION fnDirViewClear(){
	STACK_VAR INTEGER x
	SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,'"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
	SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirRecords[1]),'.',ITOA(btnDirRecords[LENGTH_ARRAY(btnDirRecords)]),',0'"
	fnDisplaySearchStrings()
	myMXP.DIRECTORY.PAGENO = 1
}
(** Populates internal search list based on search term **)
DEFINE_FUNCTION fnPopulateSearch(){
	STACK_VAR INTEGER x
	STACK_VAR uDirEntry pEntry
	// Clear Directory
	FOR(x = 1; x <= DIRSIZE; x++){
		SEARCHLIST[x] 	= pENTRY
		myMXP.DIRECTORY.SEARCHCOUNT 	= 0
	}
	// Get Results
	IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
		STACK_VAR INTEGER y
		FOR(x = 1; x <= myMXP.DIRECTORY.ENTRYCOUNT; x++){
			IF(FIND_STRING(UPPER_STRING(DIRLIST[x].NAME),UPPER_STRING(myMXP.DIRECTORY.SEARCH1),1)){
				y++
				SEARCHLIST[y] = DIRLIST[x]
				SEARCHLIST[y].LINK = x
			}
		}
		myMXP.DIRECTORY.SEARCHCOUNT 	= y
	}
	// Load GUI
	fnDirViewReload()
}
/******************************************************************************
	Directory Navigation
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDirRecords] {
	PUSH: {
		STACK_VAR INTEGER pIndex
		pIndex = (myMXP.DIRECTORY.PAGENO * myMXP.DIRECTORY.PAGESIZE) - myMXP.DIRECTORY.PAGESIZE + GET_LAST(btnDirRecords)
		IF(myMXP.DIRECTORY.RECORDSELECTED == GET_LAST(btnDirRecords)){
			myMXP.DIRECTORY.RECORDSELECTED = 0
			SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
		}
		ELSE{
			myMXP.DIRECTORY.RECORDSELECTED = GET_LAST(btnDirRecords)
			SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',1'"
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDirBreadCrumbs]{
	PUSH:{
		fnDirViewReload()
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,lvlDIR_ScrollBar]{
	PUSH:    myMXP.DIRECTORY.dragBarActive = TRUE
	RELEASE: myMXP.DIRECTORY.dragBarActive = FALSE
}
DEFINE_EVENT LEVEL_EVENT[tp,lvlDIR_ScrollBar]{
	IF(myMXP.DIRECTORY.dragBarActive){
		myMXP.DIRECTORY.PAGENO = LEVEL.VALUE
		fnDirViewReload()
	}
}
//Directory navigation and selection
define_event button_event[tp,btnDirControl] {
	PUSH: {
		SWITCH(get_last(btnDirControl)) {
			CASE 1: {	//Prev
				if(myMXP.DIRECTORY.PAGENO > 1) {
					myMXP.DIRECTORY.PAGENO--
					fnDirViewReload()
				}
			}
			CASE 2: { 	//Next
				IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
					IF(myMXP.DIRECTORY.PAGENO * myMXP.DIRECTORY.PAGESIZE + 1 <= myMXP.DIRECTORY.SEARCHCOUNT){
						myMXP.DIRECTORY.PAGENO++
						fnDirViewReload()
					}
				}
				ELSE{
					IF(myMXP.DIRECTORY.PAGENO * myMXP.DIRECTORY.PAGESIZE + 1 <= myMXP.DIRECTORY.ENTRYCOUNT){
						myMXP.DIRECTORY.PAGENO++
						fnDirViewReload()
					}
				}
			}
			CASE 3:
			CASE 4:{
				IF(!myMXP.DIRECTORY.LOADING){
					fnDirViewReload()
				}
			}
		}
   }
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDirDial]{
	PUSH:{
		STACK_VAR INTEGER pRecord
		pRecord = (myMXP.DIRECTORY.PAGENO * myMXP.DIRECTORY.PAGESIZE) - myMXP.DIRECTORY.PAGESIZE + myMXP.DIRECTORY.RECORDSELECTED
		SWITCH(myMXP.DIRECTORY.TYPE){
			CASE 'LocalEntry':{
				IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
					fnQueueTx('xCommand',"'DialLocalEntry LocalEntryID:',ITOA(SEARCHLIST[pRecord].LINK)")
				}
				ELSE{
					fnQueueTx('xCommand',"'DialLocalEntry LocalEntryID:',ITOA(pRecord)")
				}
			}
			CASE 'GlobalEntry':{
				IF(LENGTH_ARRAY(myMXP.DIRECTORY.SEARCH1)){
					fnQueueTx('xCommand',"'DialGlobalEntry GlobalEntryID:',ITOA(SEARCHLIST[pRecord].LINK)")
				}
				ELSE{
					fnQueueTx('xCommand',"'DialGlobalEntry GlobalEntryID:',ITOA(pRecord)")
				}
			}
		}
	}
}
/******************************************************************************
	Directory Search
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDirSearchKB]{
	PUSH:{
		SWITCH(GET_LAST(btnDirSearchKB)){
			CASE 27:myMXP.DIRECTORY.SEARCH2 = "myMXP.DIRECTORY.SEARCH2,' '"
			CASE 28:{}
			CASE 29:{}
			CASE 30:{
				myMXPPanel[GET_LAST(tp)].SEARCH_NUMLOCK = !myMXPPanel[GET_LAST(tp)].SEARCH_NUMLOCK
				fnDrawSearchKB(GET_LAST(tp))
			}
			CASE 31:myMXP.DIRECTORY.SEARCH2 =  fnStripCharsRight(myMXP.DIRECTORY.SEARCH2,1)
			CASE 32:{
				myMXP.DIRECTORY.SEARCH1 = myMXP.DIRECTORY.SEARCH2
				myMXP.DIRECTORY.PAGENO = 1
				fnPopulateSearch()
			}
			CASE 33:myMXP.DIRECTORY.SEARCH2 =  myMXP.DIRECTORY.SEARCH1
			DEFAULT:myMXP.DIRECTORY.SEARCH2 = "myMXP.DIRECTORY.SEARCH2,DialKB[fnGetSearchKB(GET_LAST(tp))][GET_LAST(btnDirSearchKB)]"
		}
		fnDisplaySearchStrings()
	}
	HOLD[3]:{
		SWITCH(GET_LAST(btnDirSearchKB)){
			CASE 31:myMXP.DIRECTORY.SEARCH2 =  ''
		}
		fnDisplaySearchStrings()
	}
}

DEFINE_FUNCTION fnDisplaySearchStrings(){
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar1),',0,',myMXP.DIRECTORY.SEARCH1"
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar2),',0,',myMXP.DIRECTORY.SEARCH2"
}

/******************************************************************************
	Interface Feedback
******************************************************************************/
DEFINE_PROGRAM {
	// Local Variable
	STACK_VAR INTEGER b;
	// Directory Entry Feedback
	FOR(b = 1; b <= myMXP.DIRECTORY.PAGESIZE; b++){
		SELECT{
			ACTIVE(myMXP.DIRECTORY.RECORDSELECTED == b):SEND_LEVEL tp,btnDirRecords[b],4
			ACTIVE(1):SEND_LEVEL tp,btnDirRecords[b],1
		}
	}
	// Directory Control Feedback
	[tp,btnDirLoading] = (myMXP.DIRECTORY.LOADING)
	SEND_LEVEL tp,lvlDIR_ScrollBar,myMXP.DIRECTORY.PAGENO
	[tp,btnDirType[1]] = ( myMXP.DIRECTORY.TYPE != 'LocalEntry')
	[tp,btnDirType[2]] = ( myMXP.DIRECTORY.TYPE == 'GlobalEntry')
	[tp,btnDirType[3]] = ( myMXP.DIRECTORY.TYPE == 'GlobalEntry')

	// Call Status Feedback based on call state
	FOR(b = 1; b <= LENGTH_ARRAY(vdvCalls); b++){
		SELECT{
			ACTIVE([vdvCalls[b],238]):                   	SEND_LEVEL tp,addVCCallStatus[b],3
			ACTIVE([vdvCalls[b],237] || [vdvCalls[b],236]): SEND_LEVEL tp,addVCCallStatus[b],2
			ACTIVE(1):                                   	SEND_LEVEL tp,addVCCallStatus[b],1
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/


