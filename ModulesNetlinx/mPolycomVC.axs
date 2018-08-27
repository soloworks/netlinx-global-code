MODULE_NAME='mPolycomVC'(DEV vdvControl, DEV vdvCalls[], DEV tp[], DEV dvVC)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 10/10/2013  AT: 14:30:56        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Control Ltd (www.solocontrol.co.uk)

	Solo Control module for Polycom HDX Units
	Built to standard to be interchangable with Tandberg Cxx Module

	User Interface with dialing and directory
	Standard User Controls

	autoshowcontent <get|on|off>

******************************************************************************/
/******************************************************************************
	Interface levels
******************************************************************************/
DEFINE_CONSTANT
INTEGER lvlVolume	= 1
INTEGER lvlDIR_ScrollBar = 2
/******************************************************************************
	UI Text Field Addresses
******************************************************************************/
DEFINE_CONSTANT
INTEGER addIP					= 51
INTEGER addE164				= 52
INTEGER addH323				= 53
INTEGER addRoomNo				= 54
INTEGER addDirSearch			= 57
INTEGER addIncomingCallName= 58
INTEGER addVCCallStatus[]	= {61,62,63,64,65}
INTEGER addVCCallDuration[]= {71,72,73,74,75}
/******************************************************************************
	Button Numbers
******************************************************************************/
DEFINE_CONSTANT
(**	Microphone Mute		**)
INTEGER btnMicMute		= 201
(**	SelfView Toggle		**)
INTEGER btnSelfViewMode	= 202
(**	SelfView Toggle		**)
INTEGER btnSelfViewPos[]= {203,204}
(**	Hang Up Calls		**)
INTEGER btnTracking 		=  205
(**	AutoAnswer		**)
INTEGER btnAutoAnswer[] =  {207,208}	// Yes, DND
(**	Hang Up Calls		**)
INTEGER btnHangup[] = {
	210,211,212,213,214,215	// ALL | Call 1..5
}
INTEGER btnAnswer[] = {
	220
}
(**	Reject Calls		**)
INTEGER btnReject[] = {
	230
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
	284	// NUMLOCK ON
}
INTEGER btnDialSpecial[]={
	290,291,292		// . | .com | @
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
INTEGER btnCamNearPreset[] = {
	400,401,402,403,404,405,406,407,408,409,
	410,411,412,413,414,415,416,417,418,419,
	420,421,422,423,424,425,426,427,428,429,
	430,431,432,433,434
}
INTEGER btnCamNearSelect[] = {
	441,442,443,444,445,446,447
}
INTEGER btnCamNearControl[] = {
(**UP| DN| LT| RT| Z+| Z- **)
	451,452,453,454,455,456
}
/******************************************************************************
	Button Numbers - Far Side Camera Control
******************************************************************************/
INTEGER btnCamFarPreset[] = {
	501,502,503,504,505,506,507,508,509,510,
	511,512,513,514,515,516,517,518,519,520,
	521,522,523,524,525,526,527,528,529,530,
	531,532,533,534,535
}
INTEGER btnCamFarControl[] = {
(**UP| DN| LT| RT| Z+| Z- **)
	551,552,553,554,555,556
}
INTEGER btnCamFarCallSelect[] = {
	561,562,563,564,565
}

/******************************************************************************
	Button Numbers - Directory Control
******************************************************************************/
INTEGER btnDirLoading 		= 601
INTEGER btnDirBreadCrumbs 	= 602
INTEGER btnDirSearchBar1 	= 603
INTEGER btnDirPage			= 604
INTEGER btnDirSearchBar2 	= 605

INTEGER btnDirRecords[] = {
	11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
}
INTEGER btnDirMethods[] = {
	641,642,643
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
	Other Functions
******************************************************************************/
INTEGER btnContent[] = { 700,701,702,703,704 }
/******************************************************************************
	Button Numbers - Remote Control Emulation - See Below for Commands
******************************************************************************/
INTEGER btnRemote[] = {
	3001,3002,3003,3004,3005,3006,3007,3008,3009,3010,
	3011,3012,3013,3014,3015,3016,3017,3018,3019,3020,
	3021,3022,3023,3024,3025,3026,3027,3028,3029,3030,
	3031,3032,3033,3034,3035,3036,3037,3038,3039,3040,
	3041,3042,3043,3044,3045,3046,3047,3048,3049
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_REBOOT 			= 1
LONG TLID_COMMS  			= 2
LONG TLID_POLL	  			= 3
LONG TLID_TIMER  			= 4
LONG TLID_VCDIALLOCKOUT = 5
LONG TLID_RS232			= 6
LONG TLID_INIT				= 7
LONG TLID_RETRY			= 8

INTEGER DIR_TYPE_LOCAL 	= 0
INTEGER DIR_TYPE_GLOBAL	= 1
INTEGER DIR_TYPE_LDAP	= 2

INTEGER DEBUG_ERROR		= 0	// Only Errors Reported
INTEGER DEBUG_BASIC		= 1	// General Debugging
INTEGER DEBUG_DEVELOP	= 2	// Detailed Debugging

INTEGER CONN_STATE_IDLE			= 1
INTEGER CONN_STATE_CONNECTING	= 2
INTEGER CONN_STATE_NEGOTIATE	= 3
INTEGER CONN_STATE_CONNECTED	= 4

INTEGER AUTOSHOWCONTENT_LEAVE	= 0
INTEGER AUTOSHOWCONTENT_ON		= 1
INTEGER AUTOSHOWCONTENT_OFF	= 2

INTEGER DIRSIZE = 250	// Must be under a certain size or event stack dies
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uVC{
	// General
	CHAR		MODEL[50]
	CHAR 		VERSION[50]
	CHAR 		SERIALNO[50]
	// Config
	INTEGER 	AUTOSHOWCONTENT
	// VC Variables
	CHAR 		ipaddress[15]
	CHAR 		e164ext[50]
	CHAR 		h323name[50]
	CHAR 		roomno[50]
	// State
	INTEGER	MUTE
	INTEGER	VOLUME
	CHAR 		DIAL_STRING[255]
	INTEGER	ContentRx
	INTEGER	ContentTx
	INTEGER	curPreset
	INTEGER	CAMERA
	INTEGER	POWER
	INTEGER	TRACKING
	INTEGER	SELFVIEW
	INTEGER	VIDEOMUTE
	INTEGER	AUTO_ANSWER
	// Directory

	// Comms
	INTEGER 	DEBUG
	CHAR 	  	Rx[2000]
	INTEGER	EMULATE
	CHAR		BAUD[10]
	CHAR		USERNAME[25]
	CHAR		PASSWORD[25]
	CHAR		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER 	isIP
	INTEGER	CONN_STATE
}
DEFINE_TYPE STRUCTURE uCALL{
	INTEGER 	ID
	CHAR 		NAME[50]
	CHAR 		NUMBER[50]
	CHAR 		SPEED[50]
	CHAR 		STATUS[50]
	CHAR 		TYPE[25]
	INTEGER 	isMUTED
	INTEGER 	isINCOMING
	INTEGER	DURATION
}
DEFINE_TYPE STRUCTURE uEntry{
	CHAR NAME[40]			// Name Field
	CHAR SYS_LABEL[40]	// SYS_LABEL Field
	CHAR UID[50]			// UID (New Global Commands)
	INTEGER isGROUP		// True if a Group
}
DEFINE_TYPE STRUCTURE uDir{
	// Directory
	INTEGER  TYPE					// LOCAL | GLOBAL | LDAP
	INTEGER	noGroups				// Global Dir Support
	CHAR 		GLOBALNAME[50]		// Name of Global Directory to be ignored
	INTEGER  BUSY
	CHAR		SEARCH1[25]			// Actual Search Term
	CHAR		SEARCH2[25]			// User editing of search term
	INTEGER  dragBarActive
	INTEGER	PAGENO				// Current Page
	INTEGER	PAGESIZE				// Directory Interface Size
	CHAR 		GROUP[50]			// Current Group to Browse (empty = Home)
	INTEGER 	FORCEGROUP			// If true, will lock Directory into a single group
	INTEGER	RECORDSELECTED
	(** Directory - retrieved from Codec **)
	INTEGER  ENTRYCOUNT
	uEntry	ENTRYLIST[DIRSIZE]
	(** Search Subset - created from user string and above **)
	INTEGER  SEARCHCOUNT
	uEntry	SEARCHLIST[DIRSIZE]
}

DEFINE_TYPE STRUCTURE uPanel{
	INTEGER DIAL_CAPS
	INTEGER DIAL_SHIFT
	INTEGER DIAL_NUMLOCK
	INTEGER SEARCH_NUMLOCK
}

/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_REBOOT[]  = {3000}
LONG TLT_COMMS[]   = {120000}
LONG TLT_POLL[]    = {45000}
LONG TLT_TIMER[]	 = {1000}
LONG TLT_LOCKOUT[] = {4000}
LONG TLT_RS232[]	 = {2000}
LONG TLT_INIT[]	 = {1000,5000,10000}
LONG TLT_RETRY[]	 = {10000}

VOLATILE uVC   	myPCVC
VOLATILE uCALL 	myCalls[5]
VOLATILE uDir  	myDirectory
VOLATILE uPanel	myVCPanels[5]
/******************************************************************************
	Bootup
******************************************************************************/
DEFINE_FUNCTION fnRS232HoldOff(){
	IF(TIMELINE_ACTIVE(TLID_RS232)){ TIMELINE_KILL(TLID_RS232) }
	TIMELINE_CREATE(TLID_RS232,TLT_RS232,LENGTH_ARRAY(TLT_RS232),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RS232]{
	SEND_COMMAND dvVC, "'SET BAUD ',myPCVC.BAUD,' N 8 1 485 DISABLE'"
	myPCVC.CONN_STATE = CONN_STATE_CONNECTED
	fnSendCommand('whoami')
	fnInitComms()
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR ThisCommand[]){
	fnDebug(DEBUG_BASIC,'->VC',ThisCommand)
	SEND_STRING dvVC, "ThisCommand, $0D,$0A";
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR Msg[], CHAR MsgData[]){
	IF(myPCVC.DEBUG >= pLEVEL){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION INTEGER fnGetCallSlot(INTEGER pID){
	STACK_VAR INTEGER c
	FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
		IF(myCalls[c].ID == pID){ RETURN c; }
	}
	FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
		IF(myCalls[c].ID == 0){ RETURN c }
	}
}
DEFINE_FUNCTION fnKillCall(INTEGER pID){
	STACK_VAR INTEGER c
	FOR(c = 1;  c <= LENGTH_ARRAY(vdvCalls); c++){
		IF(myCalls[c].ID == pID || !pID){
			uCALL pCall
			myCalls[c] = pCall
			SEND_COMMAND vdvCalls[c],"'NAME-'"
			SEND_COMMAND vdvCalls[c],"'NUMBER-'"
			SEND_COMMAND vdvCalls[c],"'SPEED-'"
			SEND_COMMAND vdvCalls[c],"'STATUS-'"
		}
	}
}

DEFINE_FUNCTION INTEGER fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_BASIC,'VC->',pDATA)

	IF(LEFT_STRING(pDATA,8) == 'Password'){
		fnSendCommand(myPCVC.PASSWORD)
	}
	ELSE IF(pDATA == 'sleep'){myPCVC.POWER = FALSE}
	ELSE IF(pDATA == 'wake'){myPCVC.POWER = TRUE}
	ELSE IF(pDATA == 'Here is what I know about myself:'){
		fnInitComms()
	}
	ELSE IF(FIND_STRING(pDATA,'system is not in a call',1)){
		fnKillCall(0)
		RETURN TRUE
	}
	ELSE IF(LEFT_STRING(pDATA,14) == 'Control event:'){
		GET_BUFFER_STRING(pDATA,14)
		SWITCH(fnRemoveWhiteSpace(pDATA)){
			CASE 'vcbutton farstop':myPCVC.ContentRx = FALSE
			CASE 'vcbutton farplay':myPCVC.ContentRx = TRUE
			CASE 'vcbutton play failed':
			CASE 'vcbutton stop':	myPCVC.ContentTx = FALSE
			CASE 'vcbutton play':	myPCVC.ContentTx = TRUE
		}
	}
	ELSE IF(LEFT_STRING(pDATA,20) == 'vcbutton play failed'){
		myPCVC.ContentTx = FALSE
	}
	ELSE IF(LEFT_STRING(pDATA,6) == 'Model:'){
		GET_BUFFER_STRING(pDATA,6)
		myPCVC.MODEL   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
		SEND_STRING vdvControl, "'PROPERTY-META,TYPE,VideoConferencer'"
		SEND_STRING vdvControl, "'PROPERTY-META,MAKE,Polycom'"
		SEND_STRING vdvControl, "'PROPERTY-META,MODEL,',myPCVC.MODEL"
	}
	ELSE IF(LEFT_STRING(pDATA,17) == 'Software Version:'){
		GET_BUFFER_STRING(pDATA,17)
		myPCVC.VERSION   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
		SEND_STRING vdvControl, "'PROPERTY-META,SW,',myPCVC.VERSION"
	}
	ELSE IF(LEFT_STRING(pDATA,14) == 'Serial Number:'){
		GET_BUFFER_STRING(pDATA,14)
		myPCVC.SERIALNO   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
		SEND_STRING vdvControl, "'PROPERTY-META,SN,',myPCVC.SERIALNO"
	}
	ELSE IF(LEFT_STRING(pDATA,9) == 'callinfo:'){
		STACK_VAR uCALL thisCall
		STACK_VAR INTEGER c
		GET_BUFFER_STRING(pDATA,9)
		thisCall.ID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
		thisCall.NAME 			= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
		thisCall.NUMBER 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
		thisCall.SPEED 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
		thisCall.STATUS 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
		thisCall.isMUTED 		= (fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1) == 'muted')
		thisCall.isINCOMING 	= (fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1) == 'incoming')
		//thisCall.TYPE			= fnRemoveWhiteSpace(pDATA) == 'videocall'
		IF(thisCall.STATUS == 'disconnected'){
			fnKillCall(thisCall.ID)
			RETURN FALSE
		}
		IF(thisCall.STATUS != 'bonding' && thisCall.STATUS != 'allocated'){
			// Get or Allocate a new slot
			c = fnGetCallSlot(thisCall.ID)
			// If previously Allocated
			IF(c){
				// Transfer over Durations
				thisCall.DURATION = myCalls[c].DURATION
				// Transfer over call direction if set
				IF(myCalls[c].isINCOMING){thisCall.isINCOMING = myCalls[c].isINCOMING }
			}
			// Assign Values
			myCalls[c] = thisCall
		}
		RETURN TRUE
	}
	ELSE IF(LEFT_STRING(pDATA,13) == 'notification:'){
		// Remove the 'notification'
		REMOVE_STRING(pDATA,':',1)
		// Switch on next part
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
			CASE 'linestatus':{
				STACK_VAR uCALL thisCall
				thisCall.isINCOMING = (fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1) == 'incoming')
				fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)	// Name/Number? (Not in API)
				thisCall.ID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
				fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)	// LineID
				fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)	// ChannelID
				thisCall.STATUS = pDATA
				IF(thisCall.STATUS == 'opened'){
					fnSendCommand("'callinfo callid ',ITOA(thisCall.ID)")
				}
				IF(thisCall.STATUS == 'inactive'){
					fnKillCall(thisCall.ID)
					RETURN FALSE
				}
				ELSE{
					STACK_VAR INTEGER c
					c = fnGetCallSlot(thisCall.ID)
					myCalls[c].STATUS = thisCall.STATUS
					IF(thisCall.isINCOMING){
						myCalls[c].isINCOMING = thisCall.isINCOMING
					}
					fnSendCommand("'callinfo callid ',ITOA(thisCall.ID)")
				}
			}
			CASE 'callstatus':{
				STACK_VAR uCALL thisCall
				STACK_VAR INTEGER c
				thisCall.isINCOMING 	= (fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1) == 'incoming')
				thisCall.ID 			= ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
				thisCall.NAME 			= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
				thisCall.NUMBER 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
				thisCall.STATUS 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
				thisCall.SPEED 		= fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
				//thisCall.isMUTED 		= (fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1) == 'muted')
				//thisCall.TYPE			= fnRemoveWhiteSpace(pDATA) == 'videocall'
				IF(thisCall.STATUS == 'opened'){
					thisCall.STATUS = 'connecting'
				}
				IF(thisCall.STATUS == 'disconnected'){
					fnKillCall(thisCall.ID)
					RETURN FALSE
				}
				IF(thisCall.STATUS != 'bonding' && thisCall.STATUS != 'allocated'){
					// Get or Allocate a new slot
					c = fnGetCallSlot(thisCall.ID)
					// If previously Allocated
					IF(c){
						// Transfer over Durations
						thisCall.DURATION = myCalls[c].DURATION
						// Transfer over call direction if set
						IF(myCalls[c].isINCOMING){thisCall.isINCOMING = myCalls[c].isINCOMING }
					}
					// Assign Values
					myCalls[c] = thisCall
					fnSendCallDetail(0,c)
				}
				RETURN TRUE
			}
		}
	}
	ELSE{
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
			CASE 'systemsetting':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'selfview':{
						SWITCH(UPPER_STRING(fnRemoveWhiteSpace(pDATA))){
							CASE 'OFF': myPCVC.SELFVIEW = FALSE
							CASE 'ON':  myPCVC.SELFVIEW = TRUE
						}
					}
				}
			}
			CASE 'event:':{
				IF(LEFT_STRING(pDATA,16) == 'camera near move'){
					myPCVC.curPreset = 0
				}
			}
			CASE 'preset':{
				IF(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1) == 'near'){
					IF(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1) == 'go'){
						myPCVC.curPreset = ATOI(pDATA)
					}
				}
			}
			CASE 'listen':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'video':{
						SWITCH(fnRemoveWhiteSpace(pDATA)){
							CASE 'ringing':{

							}
						}
					}
				}
			}
			CASE 'active:':
			CASE 'incoming:':{
				REMOVE_STRING(pDATA,'[',1)
				fnSendCommand("'callinfo callid ',fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1)");
			}
			CASE 'dialing':{

			}
			CASE 'cleared:':
			CASE 'ended:':{
				REMOVE_STRING(pDATA,'[',1)
				fnKillCall(ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1)))
			}
			CASE 'cs:':{
				STACK_VAR INTEGER _CALL
				STACK_VAR INTEGER c
				STACK_VAR INTEGER _CHAN
				STACK_VAR CHAR 	_DIALSTR[255]
				STACK_VAR CHAR		_STATE[255]
				REMOVE_STRING(pDATA,'call[',1)
				_CALL = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1))
				REMOVE_STRING(pDATA,'chan[',1)
				_CHAN = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1))
				REMOVE_STRING(pDATA,'dialstr[',1)
				_DIALSTR = fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1)
				REMOVE_STRING(pDATA,'state[',1)
				_STATE = LOWER_STRING(fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1))
				IF(_STATE != 'bonding' && _STATE != 'allocated'){
					c = fnGetCallSlot(_CALL)
					myCalls[c].ID		= _CALL
					myCalls[c].NAME 	= _DIALSTR
					myCalls[c].NUMBER = _DIALSTR
					myCalls[c].STATUS = _STATE
					fnSendCallDetail(0,c)

					IF(FIND_STRING(myPCVC.MODEL,'HDX',1)){
						fnSendCommand("'callinfo callid ',ITOA(_CALL)")
					}
				}
			}
			CASE 'volume':{
				myPCVC.VOLUME = ATOI(pDATA)
			}
			CASE 'camera':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'near':{
						IF(FIND_STRING(pDATA,' ',1)){
							SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
								CASE 'tracking':{
									myPCVC.TRACKING = !(LEFT_STRING(pDATA,3) == 'off')
									//fnSendCommand('camera 1');
								}
							}
						}
						ELSE{
							myPCVC.CAMERA = ATOI(pDATA)
						}
					}
				}
			}
			CASE 'mute':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'near':{
						SWITCH(pDATA){
							CASE 'on': myPCVC.MUTE = TRUE
							CASE 'off':myPCVC.MUTE = FALSE
						}
					}
					CASE 'far':{ fnSendCommand('callinfo all') }
				}
			}
			CASE 'autoanswer':{
				SWITCH(pDATA){
					CASE 'donotdisturb':myPCVC.AUTO_ANSWER = 2
					CASE 'yes':			  myPCVC.AUTO_ANSWER = 1
					CASE 'no':			  myPCVC.AUTO_ANSWER = 0
				}
			}
			CASE 'ipaddress':{
				pDATA = fnRemoveWhiteSpace(pDATA)
				IF(myPCVC.IPAddress != pDATA){
					myPCVC.IPAddress = pDATA
					SEND_STRING vdvControl, "'PROPERTY-IP,',pDATA"
					SEND_COMMAND tp,"'^TXT-',ITOA(addIP),',0,',myPCVC.IPAddress"
				}
				// Escape for failed Directory calls
				myDirectory.BUSY = FALSE

				fnSendPoll(2)
				RETURN TRUE
			}
			CASE 'e164ext':{
				pDATA = fnRemoveWhiteSpace(pDATA)
				pDATA = fnRemoveQuotes(pDATA)
				IF(myPCVC.e164ext != pDATA){
					myPCVC.e164ext = pDATA
					SEND_STRING vdvControl, "'PROPERTY-E164EXT,',pDATA"
					SEND_COMMAND tp,"'^TXT-',ITOA(addE164),',0,',myPCVC.e164ext"
				}
			}
			CASE 'h323name':{
				pDATA = fnRemoveWhiteSpace(pDATA)
				pDATA = fnRemoveQuotes(pDATA)
				IF(myPCVC.h323name != pDATA){
					myPCVC.h323name = pDATA
					SEND_STRING vdvControl, "'PROPERTY-H323NAME,',pDATA"
					SEND_COMMAND tp,"'^TXT-',ITOA(
					addH323),',0,',myPCVC.h323name"
				}
			}
			CASE 'roomphonenumber':{
				pDATA = fnRemoveWhiteSpace(pDATA)
				pDATA = fnRemoveQuotes(pDATA)
				IF(myPCVC.roomno != pDATA){
					myPCVC.roomno = pDATA
					SEND_STRING vdvControl, "'PROPERTY-ROOMNUMBER,',pDATA"
					SEND_COMMAND tp,"'^TXT-',ITOA(addRoomNo),',0,',myPCVC.roomno"
				}
			}
			CASE 'globaldir':{
				IF(RIGHT_STRING(pDATA,4) == 'done'){
					fnDirViewReload()
				}
				ELSE{
					STACK_VAR INTEGER pIndex
					pIndex = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,'.',1),1)) + 1
					myDirectory.ENTRYLIST[pIndex].NAME = fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
					myDirectory.ENTRYLIST[pIndex].UID = fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
					myDirectory.ENTRYLIST[pIndex].isGROUP = (pDATA == 'group')
					myDirectory.ENTRYCOUNT = pIndex
				}
			}
			CASE 'gaddrbook':{
				STACK_VAR CHAR REF[255]
				REF = fnRemoveWhiteSpace(REMOVE_STRING(pDATA,' ',1))
				SELECT{
					ACTIVE(REF == 'grouplist'):{
						IF(fnRemoveWhiteSpace(pDATA) == 'not supported.'){
							myDirectory.noGroups = TRUE
							fnSendCommand('gaddrbook all')
						}
						ELSE IF(FIND_STRING(pDATA,'group:"',1)){
							STACK_VAR CHAR _name[255]
							REMOVE_STRING(pDATA,'group:"',1)
							_name = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
							myDirectory.ENTRYCOUNT++
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].NAME = _name
						}
						ELSE IF(RIGHT_STRING(pDATA,4) == 'done'){
							fnDirViewReload()
						}
					}
					ACTIVE(REF == 'system'):{
						IF(FIND_STRING(pDATA,'name:"',1)){
							STACK_VAR CHAR _name[255]
							REMOVE_STRING(pDATA,'name:"',1)
							_name = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
							myDirectory.ENTRYCOUNT++
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].NAME = _name
						}
					}
					ACTIVE(REF == 'group'):{
						IF(RIGHT_STRING(pDATA,4) == 'done'){
							fnDirViewReload()
						}
					}
					ACTIVE(RIGHT_STRING(REF,1) == '.'):{
						STACK_VAR CHAR _name[255]
						REMOVE_STRING(pDATA,'"',1)
						_name = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
						myDirectory.ENTRYCOUNT++
						myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].NAME = _name
					}
					ACTIVE(REF == 'all'):{
						IF(fnRemoveWhiteSpace(pDATA) == 'done'){
							fnDirViewReload()
						}
					}
				}
			}
			CASE 'addrbook':{
				STACK_VAR CHAR REF[255]
				REF = fnRemoveWhiteSpace(REMOVE_STRING(pDATA,' ',1))
				SELECT{
					ACTIVE(REF == 'grouplist'):{
						IF(FIND_STRING(pDATA,'type:group',1)){
							STACK_VAR CHAR _name[255]
							REMOVE_STRING(pDATA,'name:"',1)
							_name = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
							myDirectory.ENTRYCOUNT++
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].NAME = _name
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].isGROUP = TRUE
						}
						ELSE IF(fnRemoveWhiteSpace(pDATA) == 'done'){
							fnDirViewReload()
						}
					}
					ACTIVE(REF == 'group'):{
						IF(FIND_STRING(pDATA,'name:"',1)){
							STACK_VAR CHAR _name[255]
							STACK_VAR CHAR _sysname[255]
							REMOVE_STRING(pDATA,'name:"',1)
							_name = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
							REMOVE_STRING(pDATA,'sys_label:"',1)
							_sysname = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
							myDirectory.ENTRYCOUNT++
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].NAME = _name
							myDirectory.ENTRYLIST[myDirectory.ENTRYCOUNT].SYS_LABEL = _sysname
						}
						ELSE IF(RIGHT_STRING(pDATA,4) == 'done'){
							fnDirViewReload()
						}
					}
					ACTIVE(REF == 'names'):{
						 IF(pDATA != 'done'){
							STACK_VAR INTEGER x
							IF(FIND_STRING(pDATA,'.',1)){
								x = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,'. ',1),2)) + 1
								myDirectory.ENTRYCOUNT = x 	// Subtract group entries
								IF(FIND_STRING(pDATA,'name:',1)){
									REMOVE_STRING(pDATA,'name:',1)
									myDirectory.ENTRYLIST[x].NAME = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
								}
								IF(FIND_STRING(pDATA,'sys_label:',1)){
									REMOVE_STRING(pDATA,'sys_label:',1)
									myDirectory.ENTRYLIST[x].SYS_LABEL = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
								}
								IF(FIND_STRING(pDATA,'type:',1)){
									REMOVE_STRING(pDATA,'type:',1)
									myDirectory.ENTRYLIST[x].isGROUP = (pDATA == 'group')
								}
							}
						}
						ELSE{

							// Reload GUI
							fnDirViewReload()
						}
					}
				}
			}
		}
	}
}
(** Polling Events **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendPoll(1)
}
DEFINE_FUNCTION fnInitComms(){
	IF(TIMELINE_ACTIVE(TLID_INIT)){ TIMELINE_KILL(TLID_INIT) }
	TIMELINE_CREATE(TLID_INIT,TLT_INIT,LENGTH_ARRAY(TLT_INIT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_INIT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1: fnSendPoll(1)
		CASE 2:{
			fnSendCommand('all register')
			fnSendCommand('notify callstatus')
			fnSendCommand('notify linestatus')
			fnSendCommand('callinfo all')
			fnSendCommand('mute near get')
			fnSendCommand('camera near tracking get')
			fnSendCommand('systemsetting get selfview')
			SWITCH(myPCVC.AUTOSHOWCONTENT){
				CASE AUTOSHOWCONTENT_OFF:	fnSendCommand('autoshowcontent off')
				CASE AUTOSHOWCONTENT_ON:	fnSendCommand('autoshowcontent on')
			}
		}
		CASE 3:fnInitDirectory()
	}
}
DEFINE_FUNCTION fnSendPoll(INTEGER pSTAGE){
	SWITCH(pSTAGE){
		CASE 1:{
			fnSendCommand('ipaddress get')
		}
		CASE 2:{
			fnSendCommand('volume get');
			fnSendCommand('e164ext get');
			fnSendCommand('h323name get');
			//fnSendCommand('roomphonenumber get');
		}
	}
}
DEFINE_FUNCTION fnInitDevice(){
	myPCVC.e164ext 	= 'n/a'
	myPCVC.h323name 	= 'n/a'
	myPCVC.ipaddress 	= 'n/a'
	myPCVC.roomno 		= 'n/a'
	fnKillCall(0)
}
(** Reboot Events **)
DEFINE_FUNCTION fnReboot(){
	IF(TIMELINE_ACTIVE(TLID_REBOOT)){TIMELINE_KILL(TLID_REBOOT)}
	TIMELINE_CREATE(TLID_REBOOT,TLT_REBOOT,LENGTH_ARRAY(TLT_REBOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_REBOOT]{
	SEND_STRING vdvControl, 'ACTION-REBOOTING'
	fnSendCommand('reboot now')
}

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
	IF(myPCVC.IP_HOST == ''){
		fnDebug(DEBUG_ERROR,'ERR: VC','No IP Address')
	}
	ELSE{
		fnDebug(DEBUG_BASIC,'TryIP>VC on',"myPCVC.IP_HOST,':',ITOA(myPCVC.IP_PORT)")
		myPCVC.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvVC.port, myPCVC.IP_HOST, myPCVC.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvVC.port)
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	SET_VIRTUAL_CHANNEL_COUNT(vdvControl,500)
	myPCVC.isIP = !(dvVC.NUMBER)
	CREATE_BUFFER dvVC, myPCVC.Rx
	myDirectory.noGroups = TRUE
	fnInitDevice()
	TIMELINE_CREATE(TLID_TIMER,TLT_TIMER,LENGTH_ARRAY(TLT_TIMER),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvVC]{
	ONLINE:{
		IF(myPCVC.isIP){
			myPCVC.CONN_STATE = CONN_STATE_NEGOTIATE
		}
		ELSE{
			IF(myPCVC.BAUD = ''){myPCVC.BAUD = '57600'}
			fnRS232HoldOff()
		}
	}
	OFFLINE:{
		IF(myPCVC.isIP){
			myPCVC.CONN_STATE 	= CONN_STATE_IDLE;
			fnReTryTCPConnection()
		}
	}
	ONERROR:{
		IF(myPCVC.isIP){
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
			}
			SWITCH(DATA.NUMBER){
				CASE 14:{}		// Local Port Already Used
				DEFAULT:{
					myPCVC.CONN_STATE	= CONN_STATE_IDLE
					fnReTryTCPConnection()
				}
			}
			fnDebug(DEBUG_ERROR,"'ERR VC: [',myPCVC.IP_HOST,':',ITOA(myPCVC.IP_PORT),']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		// Telnet Negotiation
		/*WHILE(myPCVC.Rx[1] == $FF && LENGTH_ARRAY(myPCVC.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myPCVC.Rx,3)
			fnDebug(DEBUG_DEVELOP,'VC.Telnet->',NEG_PACKET)
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(DEBUG_DEVELOP,'->VC.Telnet',NEG_PACKET)
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}*/
		IF(FIND_STRING(myPCVC.Rx,"'ipaddress get',$0A,$0D",1) || FIND_STRING(myPCVC.Rx,"'ipaddress get',$0D,$0A",1) ){
			// Device is Echoing, remove
			myPCVC.Rx = ''
			fnSendCommand('cmdecho off')
			fnInitComms()
		}
		WHILE(FIND_STRING(myPCVC.Rx,"$0D,$0A",1)){
			IF(LEFT_STRING(myPCVC.Rx,5) == "$0D,$0A,'-> '"){
				GET_BUFFER_STRING(myPCVC.Rx,5)
			}
			ELSE{
				IF( fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPCVC.Rx,"$0D,$0A",1),2)) ){
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
					CASE 'INIT':{ 		 fnInitComms() }
					CASE 'WAKE':{ 		 fnSendCommand('wake')  }
					CASE 'SLEEP':{ 	 fnSendCommand('sleep') }
					CASE 'HANGUP':{	 fnSendCommand('hangup all') }
					CASE 'REBOOT':{ 	 fnReboot() }
					CASE 'RESETDIR':{	 fnInitDirectory() }
					CASE 'RESETGUI':{
						myPCVC.DIAL_STRING = ''
						myDirectory.SEARCH1 = ''
						myDirectory.SEARCH2 = ''
						fnPopulateSearch()
						fnUpdatePanelDialString(0)
						fnDisplaySearchStrings()
					}
				}
			}
			CASE 'AUTOANSWER':{
				SWITCH(DATA.TEXT){
					CASE 'DND':{ 		fnSendCommand('autoanswer donotdisturb')}
					CASE 'TRUE':{ 		fnSendCommand('autoanswer yes')}
					CASE 'FALSE':{ 	fnSendCommand('autoanswer no')}
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':  myPCVC.DEBUG = DEBUG_DEVELOP
							CASE 'TRUE': myPCVC.DEBUG = DEBUG_BASIC
							DEFAULT: 	 myPCVC.DEBUG = DEBUG_ERROR
						}
					}
					CASE 'E164EXT':{	fnSendCommand("'e164ext set ',DATA.TEXT");	fnReboot() }
					CASE 'H323NAME':{	fnSendCommand("'h323name set ',DATA.TEXT");	fnReboot() }
					CASE 'BAUD':{
						myPCVC.BAUD = DATA.TEXT
						fnRS232HoldOff()
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myPCVC.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myPCVC.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myPCVC.IP_HOST = DATA.TEXT
							myPCVC.IP_PORT = 24
						}
						fnOpenTCPConnection()
					}
					CASE 'USERNAME':	myPCVC.USERNAME = DATA.TEXT
					CASE 'PASSWORD':	myPCVC.PASSWORD = DATA.TEXT
					CASE 'DIRECTORY':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'TYPE':{
								SWITCH(DATA.TEXT){
									CASE 'GLOBAL':	myDirectory.TYPE = DIR_TYPE_GLOBAL
									CASE 'LDAP':	myDirectory.TYPE = DIR_TYPE_LDAP
									DEFAULT:			myDirectory.TYPE = DIR_TYPE_LOCAL
								}
							}
							CASE 'GLOBALENTRY':	myDirectory.GLOBALNAME = DATA.TEXT
							CASE 'PAGESIZE':		myDirectory.PAGESIZE = ATOI(DATA.TEXT)
							CASE 'FORCEGROUP':{
								myDirectory.FORCEGROUP = TRUE
								myDirectory.GROUP = DATA.TEXT
							}
						}
					}
					CASE 'AUTOSHOWCONTENT':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': 	myPCVC.AUTOSHOWCONTENT = AUTOSHOWCONTENT_ON
							CASE 'FALSE': 	myPCVC.AUTOSHOWCONTENT = AUTOSHOWCONTENT_OFF
						}
					}
				}
			}
			CASE 'RAW': 	fnSendCommand(DATA.TEXT)
			CASE 'REMOTE': fnSendCommand("'button ',DATA.TEXT")
			CASE 'SCREEN': fnSendCommand("'screen ',LOWER_STRING(DATA.TEXT)")
			CASE 'VOLUME': fnSendCommand("'volume set ',DATA.TEXT")
			CASE 'MICMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnSendCommand('mute near on');
					CASE 'OFF': fnSendCommand('mute near off');
				}
			}
			CASE 'CAMERA':{
				STACK_VAR CHAR _CMD[255]
				_CMD = "'camera ',LOWER_STRING(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),' '"
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'SELECT':{ fnSendCommand("_CMD,DATA.TEXT") }
					CASE 'GETPOS':{ fnSendCommand("_CMD,'getposition'") }
					CASE 'SETPOS':{
						STACK_VAR CHAR _X[10]
						STACK_VAR CHAR _Y[10]
						STACK_VAR CHAR _Z[10]
						_X = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						_Y = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						_Z = DATA.TEXT
						fnSendCommand("_CMD,'setposition "',_X,'" "',_Y,'" "',_Z,'"'")
					}
				}
			}
			CASE 'PRESET':{
				STACK_VAR CHAR _CMD[255]
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'STORE': fnSendCommand("'preset ',LOWER_STRING(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),' set ', DATA.TEXT")
					CASE 'RECALL':fnSendCommand("'preset ',LOWER_STRING(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),' go ', DATA.TEXT")
				}
			}
			CASE 'CONTENT':{
				SWITCH(DATA.TEXT){
					CASE 'START':{
						fnSendCommand("'vcbutton play'")
						myPCVC.ContentTx = TRUE
					}
					CASE 'STOP':
					CASE '0':{
						fnSendCommand("'vcbutton stop'")
						myPCVC.ContentTx = FALSE
					}
					DEFAULT:{
						fnSendCommand("'vcbutton play ',DATA.TEXT")
						myPCVC.ContentTx = TRUE
					}
				}
			}
			CASE 'SELFVIEW':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myPCVC.SELFVIEW = TRUE
					CASE 'OFF': 	myPCVC.SELFVIEW = FALSE
					CASE 'TOGGLE': myPCVC.SELFVIEW = !myPCVC.SELFVIEW
				}
				SWITCH(myPCVC.SELFVIEW){
					CASE TRUE:	fnSendCommand("'systemsetting selfview on'")
					CASE FALSE:	fnSendCommand("'systemsetting selfview off'")
				}
			}
			CASE 'VIDEOMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myPCVC.VIDEOMUTE = TRUE
					CASE 'OFF': 	myPCVC.VIDEOMUTE = FALSE
					CASE 'TOGGLE': myPCVC.VIDEOMUTE = !myPCVC.VIDEOMUTE
				}
				SWITCH(myPCVC.VIDEOMUTE){
					CASE TRUE:	fnSendCommand("'videomute near on'")
					CASE FALSE:	fnSendCommand("'videomute near off'")
				}
			}
			CASE 'TRACKING':{	// ON/OFF
				fnSendCommand("'camera near tracking ',LOWER_STRING(DATA.TEXT)")
			}
			CASE 'DIAL_ADD_BOOK':fnSendCommand("'dial addressbook "',DATA.TEXT,'"'")
			CASE 'DIAL':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'AUDIO':fnSendCommand("'dial phone "',DATA.TEXT,'"'")
					CASE 'AUTO':
					CASE 'VIDEO':fnSendCommand("'dial auto "',DATA.TEXT,'"'")
				}
			}
			CASE 'DTMF':fnSendCommand("'gendial ',DATA.TEXT")
			CASE 'MONITOR':{
				//takes monitor 1 or 2 and switches the output on or off
				//used for changing from single screen to dual screen mode
				STACK_VAR CHAR outputNum [10]
				outputNum = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				SWITCH(DATA.TEXT){
					CASE 'ON': fnSendCommand("'configdisplay monitor',outputNum,' hdmi'")
					CASE 'OFF':fnSendCommand("'configdisplay monitor',outputNum,' off'")
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER]{
	STACK_VAR INTEGER x;
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		IF(myCalls[x].STATUS == 'connected'){ myCalls[x].DURATION++ }
	}
	fnSendCallDurations()
}
DEFINE_EVENT
CHANNEL_EVENT[vdvCalls,236]
CHANNEL_EVENT[vdvCalls,237]
CHANNEL_EVENT[vdvCalls,238]{
	ON:fnSendCallDetail(0,GET_LAST(vdvCalls))
	OFF:{
		IF(![CHANNEL.DEVICE,236] && ![CHANNEL.DEVICE,237] && ![CHANNEL.DEVICE,238]){
			fnSendCallDetail(0,GET_LAST(vdvCalls))
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvCalls,236]{
	ON:{
		SEND_COMMAND tp,"'^TXT-',ITOA(addIncomingCallName),',0,',myCalls[GET_LAST(vdvCalls)].NAME,$0A,myCalls[GET_LAST(vdvCalls)].NUMBER"
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER c
	STACK_VAR INTEGER CALL_RINGING
	STACK_VAR INTEGER CALL_DIALLING
	STACK_VAR INTEGER CALL_CONNECTED
	FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
		[vdvCalls[c],198] = (myCalls[c].isMUTED)
		[vdvCalls[c],236] = ( myCalls[c].isINCOMING &&(
		                      myCalls[c].STATUS == 'opened'
		                      || myCalls[c].STATUS == 'ringing'
									 || myCalls[c].STATUS == 'connecting'
									 )
   								)
		[vdvCalls[c],237] = (myCalls[c].STATUS == 'connecting'
								|| myCalls[c].STATUS == 'opened')
		[vdvCalls[c],238] = (myCalls[c].STATUS == 'connected'
								|| myCalls[c].STATUS == 'completed'
								|| myCalls[c].STATUS == 'complete')
		IF([vdvCalls[c],236]){ CALL_DIALLING = TRUE }
		IF([vdvCalls[c],237]){ CALL_RINGING = TRUE }
		IF([vdvCalls[c],238]){ CALL_CONNECTED = TRUE }
		SELECT{
			ACTIVE ([vdvCalls[c],236]):{	SEND_LEVEL vdvCalls[c],1,236	}
			ACTIVE ([vdvCalls[c],237]):{	SEND_LEVEL vdvCalls[c],1,237	}
			ACTIVE ([vdvCalls[c],238]):{	SEND_LEVEL vdvCalls[c],1,238	}
			ACTIVE (TRUE):{					SEND_LEVEL vdvCalls[c],1,0		}
		}
	}
	[vdvControl,236] = CALL_DIALLING
	[vdvControl,237] = CALL_RINGING
	[vdvControl,238] = CALL_CONNECTED
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,198] = (myPCVC.MUTE)
	[vdvControl,241] = (myPCVC.ContentTx)
	[vdvControl,242] = (myPCVC.ContentRx)
	[vdvControl,243] = (myPCVC.TRACKING)
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myPCVC.POWER)

	SEND_LEVEL vdvControl, 1, myPCVC.VOLUME
}

/******************************************************************************
	User Interface Control
******************************************************************************/

/******************************************************************************
	UI Helpers
******************************************************************************/

DEFINE_VARIABLE
CHAR DialKB[3][26] = {
		{		// 1 - Lower Case Letters
		'qwertyuiopasdfghjklzxcvbnm'
		},{	// 2 - Upper Case Letters
		'QWERTYUIOPASDFGHJKLZXCVBNM'
		},{	// 3 - Digits
		'1234567890          _-#:  '
	}
}
CHAR DialSpecial[3][4] = {
	{'.'},
	{'.com'},
	{'@'}
}

DEFINE_FUNCTION fnInitPanel(INTEGER pPanel){
	STACK_VAR INTEGER x
	IF(pPanel == 0){
		STACK_VAR INTEGER p;
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnInitPanel(p)
		}
		RETURN
	}
	// Reset Keyboard Settings
	myVCPanels[pPanel].DIAL_CAPS 		= FALSE
	myVCPanels[pPanel].DIAL_NUMLOCK 	= FALSE
	myVCPanels[pPanel].DIAL_SHIFT 		= FALSE
	myVCPanels[pPanel].SEARCH_NUMLOCK 	= FALSE

	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addIP),',0,',myPCVC.IPAddress"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addE164),',0,',myPCVC.e164ext"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addH323),',0,',myPCVC.h323name"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addRoomNo),',0,',myPCVC.roomno"
	fnDrawDialKB(pPanel)
	fnDrawSearchKB(pPanel)
	fnUpdatePanelDialString(pPanel)
	fnDisplaySearchStrings()

	FOR(x = 1; x<= LENGTH_ARRAY(vdvCalls); x++){
		fnSendCallDetail(pPanel,x)
	}

	IF(myDirectory.BUSY){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDirBreadCrumbs),',0,Loading...'"
	}
	ELSE{
		fnDirViewReload()
	}
}

DEFINE_FUNCTION INTEGER fnGetDialKB(INTEGER pPanel){
	IF(myVCPanels[pPanel].DIAL_NUMLOCK){
		RETURN 3
	}
	ELSE IF(myVCPanels[pPanel].DIAL_CAPS && !myVCPanels[pPanel].DIAL_SHIFT){
		RETURN 2
	}
	ELSE IF(myVCPanels[pPanel].DIAL_SHIFT){
		RETURN 2
	}
	ELSE{
		RETURN 1
	}
}
DEFINE_FUNCTION fnDrawDialKB(INTEGER pPanel){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 26; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialKB[x]),',0,',DialKB[fnGetDialKB(pPanel)][x]"
	}
	FOR(x = 1; x <= LENGTH_ARRAY(btnDialSpecial); x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialSpecial[x]),',0,',DialSpecial[x]"
	}
}
DEFINE_FUNCTION INTEGER fnGetSearchKB(INTEGER pPanel){
	IF(myVCPanels[pPanel].SEARCH_NUMLOCK){
		RETURN 3
	}
	ELSE{
		RETURN 1
	}
}

DEFINE_FUNCTION fnDrawSearchKB(INTEGER pPanel){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 26; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDirSearchKB[x]),',0,',DialKB[fnGetSearchKB(pPanel)][x]"
	}
}

DEFINE_FUNCTION fnUpdatePanelDialString(INTEGER pPanel){
	IF(pPanel){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialString),',0,',myPCVC.DIAL_STRING"
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnDialKB[32]),',',ITOA(LENGTH_ARRAY(myPCVC.DIAL_STRING) > 0)"
	}
	ELSE{
		SEND_COMMAND tp,"'^TXT-',ITOA(btnDialString),',0,',myPCVC.DIAL_STRING"
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDialKB[32]),',',ITOA(LENGTH_ARRAY(myPCVC.DIAL_STRING) > 0)"
	}
}

DEFINE_FUNCTION fnSendCallDetail(INTEGER pPanel, INTEGER pCALL){
	STACK_VAR CHAR pStateText[200]
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendCallDetail(p, pCALL)
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
	pStateText =  UPPER_STRING(myCalls[pCALL].STATUS)
	pStateText = "pStateText,$0A,'Name:  ',myCalls[pCall].NAME"
	pStateText = "pStateText,$0A,'Number:',myCalls[pCall].NUMBER"

	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addVCCallStatus[pCall]),',2&3,',pStateText"
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnHangup[pCALL+1]),',',ITOA([vdvCalls[pCALL],236] || [vdvCalls[pCALL],237] || [vdvCalls[pCALL],238])"

}
DEFINE_FUNCTION fnSendCallDurations(){
	STACK_VAR INTEGER x
	STACK_VAR CHAR _TIME[10]
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		IF(myCalls[x].DURATION){
			_TIME = fnSecondsToTime(myCalls[x].DURATION)
			GET_BUFFER_STRING(_TIME,3)
			IF(_TIME[1] == '0'){GET_BUFFER_CHAR(_TIME)}
			SEND_COMMAND tp,"'^TXT-',ITOA(addVCCallDuration[x]),',0,',_TIME"
			SEND_STRING vdvCalls[x],"'DURATION-',_TIME"
		}
	}
}
/******************************************************************************
	Other Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		fnInitPanel(GET_LAST(tp))
	}
}
/******************************************************************************
	Button Events - General Control
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnRemote]{
	PUSH:{
		STACK_VAR CHAR cButtonCmd[20];
		SWITCH(BUTTON.INPUT.CHANNEL-3000){
			CASE 10:cButtonCmd = '0'; 			// 0
			CASE 11:cButtonCmd = '*'; 			// Asterix
			CASE 12:cButtonCmd = '#'; 			// Hash
			CASE 13:cButtonCmd = '.'; 			// Dot
			CASE 14:cButtonCmd = 'preset'
			CASE 15:cButtonCmd = 'camera'
			CASE 16:cButtonCmd = 'info'
			CASE 17:cButtonCmd = 'option'
			CASE 21:cButtonCmd = 'select'; 	// Enter
			CASE 24:cButtonCmd = 'volume+'
			CASE 25:cButtonCmd = 'volume-'
			CASE 26:cButtonCmd = 'mute'
			CASE 31:cButtonCmd = 'near'; 		// Near
			CASE 32:cButtonCmd = 'menu'; 		// Back
			CASE 33:cButtonCmd = 'far'; 		// Far
			CASE 34:cButtonCmd = 'keyboard'; // Keyboard
			CASE 35:cButtonCmd = 'directory';// Directory
			CASE 36:cButtonCmd = 'call'; 		// Call
			CASE 37:cButtonCmd = 'graphics'; // Graphics
			CASE 38:cButtonCmd = 'delete'; 	// Enter
			CASE 39:cButtonCmd = 'home'; 		// Home
			CASE 40:cButtonCmd = 'hangup'; 	// Hangup
			CASE 41:cButtonCmd = 'zoom+'
			CASE 42:cButtonCmd = 'zoom-'
			CASE 43:cButtonCmd = 'back'
			CASE 44:cButtonCmd = 'pip';		// PIP
			CASE 45:cButtonCmd = 'up';			// Up
			CASE 46:cButtonCmd = 'down'; 		// Down
			CASE 47:cButtonCmd = 'left'; 		// Left
			CASE 48:cButtonCmd = 'right';		// Right
			CASE 49:cButtonCmd = 'select'; 	// Enter
			DEFAULT: cButtonCmd = ITOA(BUTTON.INPUT.CHANNEL-3000)	// Digits
		}
		fnSendCommand("'button ',cButtonCmd")
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnContent]{
	PUSH:{

		SWITCH(GET_LAST(btnContent)){
			CASE 1:	fnSendCommand("'vcbutton stop'");
			DEFAULT:	fnSendCommand("'vcbutton play ',ITOA(GET_LAST(btnContent)-1)");
		}
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
		fnSendCommand("'gendial ',cButtonCmd")
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearPreset]{
	RELEASE:{
		SEND_COMMAND vdvControl, "'PRESET-RECALL,NEAR,',ITOA(GET_LAST(btnCamNearPreset)-1)"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamFarPreset]{
	RELEASE:{
		SEND_COMMAND vdvControl, "'PRESET-RECALL,FAR,',ITOA(GET_LAST(btnCamFarPreset)-1)"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamFarCallSelect]{
	PUSH:{
		SEND_COMMAND vdvControl, "'CAMERA-FAR,SELECT,',ITOA(GET_LAST(btnCamFarCallSelect))"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearSelect]{
	PUSH:{
		SEND_COMMAND vdvControl, "'CAMERA-NEAR,SELECT,',ITOA(GET_LAST(btnCamNearSelect))"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearControl]{
	PUSH:{
		SWITCH(GET_LAST(btnCamNearControl)){
			CASE 1:fnSendCommand('camera near move up')
			CASE 2:fnSendCommand('camera near move down')
			CASE 3:fnSendCommand('camera near move left')
			CASE 4:fnSendCommand('camera near move right')
			CASE 5:fnSendCommand('camera near move zoom+')
			CASE 6:fnSendCommand('camera near move zoom-')
		}
	}
	RELEASE:fnSendCommand('camera near move stop')
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamFarControl]{
	PUSH:{
		SWITCH(GET_LAST(btnCamFarControl)){
			CASE 1:fnSendCommand('camera far move up')
			CASE 2:fnSendCommand('camera far move down')
			CASE 3:fnSendCommand('camera far move left')
			CASE 4:fnSendCommand('camera far move right')
			CASE 5:fnSendCommand('camera far move zoom+')
			CASE 6:fnSendCommand('camera far move zoom-')
		}
	}
	RELEASE:fnSendCommand('camera far move stop')
}
DEFINE_EVENT BUTTON_EVENT[tp,btnHangup]{
	PUSH:{
		SWITCH(GET_LAST(btnHangup)){
			CASE 1:	fnSendCommand("'hangup all'")
			DEFAULT:	fnSendCommand("'hangup video ',ITOA(myCalls[GET_LAST(btnHangup)-1].ID)")
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnAnswer]{
	PUSH:{
		fnSendCommand('answer video')
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnReject]{
	PUSH:{
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
			IF([vdvCalls[x],236]){
				fnSendCommand("'hangup video ',ITOA(myCalls[x].ID)")
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnTracking]{
	PUSH:{
		IF(myPCVC.TRACKING){
			fnSendCommand('camera near tracking off')
		}
		ELSE{
			fnSendCommand('camera near tracking on')
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnAutoAnswer]{
	PUSH:{
		SWITCH(GET_LAST(btnAutoAnswer)){
			CASE 1:{	// AutoAnswer
				SWITCH(myPCVC.AUTO_ANSWER){
					CASE 1:	fnSendCommand('autoanswer no')
					DEFAULT:	fnSendCommand('autoanswer yes')
				}
			}
			CASE 2:{	// DoNotDisturb
				SWITCH(myPCVC.AUTO_ANSWER){
					CASE 2:	fnSendCommand('autoanswer no')
					DEFAULT:	fnSendCommand('autoanswer donotdisturb')
				}
			}
		}
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
				myPCVC.DIAL_STRING = "myPCVC.DIAL_STRING,' '"
				fnUpdatePanelDialString(0)
			}
			CASE 28:{	// SHIFT
				myVCPanels[p].DIAL_SHIFT = !myVCPanels[p].DIAL_SHIFT
				fnDrawDialKB(p)
			}
			CASE 29:{	// CAPS
				myVCPanels[p].DIAL_CAPS = !myVCPanels[p].DIAL_CAPS
				fnDrawDialKB(p)
			}
			CASE 30:{	// NUMLOCK
				myVCPanels[p].DIAL_NUMLOCK = !myVCPanels[p].DIAL_NUMLOCK
				fnDrawDialKB(p)
			}
			CASE 31:{	// DELETE
				myPCVC.DIAL_STRING = fnStripCharsRight(myPCVC.DIAL_STRING,1)
				fnUpdatePanelDialString(0)
			}
			CASE 32:{	// DIAL
				IF(LENGTH_ARRAY(myPCVC.DIAL_STRING)){
					fnSendCommand("'dial manual auto ',myPCVC.DIAL_STRING")
				}
			}
			CASE 33:{	// NUMLOCK ON
				myVCPanels[p].DIAL_NUMLOCK = TRUE
				fnDrawDialKB(p)
			}
			CASE 34:{	// NUMLOCK ON
				myVCPanels[p].DIAL_NUMLOCK = FALSE
				fnDrawDialKB(p)
			}
			DEFAULT:{
				STACK_VAR INTEGER kb
				kb = fnGetDialKB(p)
				IF(DialKB[kb][GET_LAST(btnDialKB)] != ''){
					myPCVC.DIAL_STRING = "myPCVC.DIAL_STRING,DialKB[kb][GET_LAST(btnDialKB)]"
					fnUpdatePanelDialString(0)
					IF(myVCPanels[p].DIAL_SHIFT){
						myVCPanels[p].DIAL_SHIFT = FALSE
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
				myPCVC.DIAL_STRING = ''
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
			myPCVC.DIAL_STRING = "myPCVC.DIAL_STRING,DialSpecial[k]"
			fnUpdatePanelDialString(0)
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		[tp[p],btnDialKB[28]] = myVCPanels[p].DIAL_SHIFT
		[tp[p],btnDialKB[29]] = myVCPanels[p].DIAL_CAPS
		[tp[p],btnDialKB[30]] = myVCPanels[p].DIAL_NUMLOCK
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnMicMute]{
	PUSH:{
		myPCVC.MUTE = !myPCVC.MUTE
		SWITCH(myPCVC.MUTE){
			CASE TRUE:	fnSendCommand("'mute near on'")
			CASE FALSE:	fnSendCommand("'mute near off'")
		}
		SEND_STRING 0, "'e:',ITOA(myPCVC.MUTE)"
	}
}
DEFINE_PROGRAM{
	[tp,btnMicMute] = (myPCVC.MUTE)
}
/******************************************************************************
	Directory Interface
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDirLoading]{
	PUSH:{
		IF(!myDirectory.BUSY){
			fnInitDirectory()
		}
	}
}

DEFINE_FUNCTION fnInitDirectory(){
	STACK_VAR INTEGER x
	fnDirViewClear()
	myDirectory.BUSY = TRUE;
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirBreadCrumbs),',0,Loading...'"
	FOR(x = 1; x <= DIRSIZE; x++){
		STACK_VAR uEntry pENTRY
		myDirectory.ENTRYLIST[x] = pENTRY
	}
	myDirectory.ENTRYCOUNT = 0
	IF(!myDirectory.FORCEGROUP){
		myDirectory.GROUP = ''
	}
	myDirectory.SEARCH1 = ''
	myDirectory.SEARCH2 = ''
	SWITCH(myDirectory.TYPE){
		CASE DIR_TYPE_GLOBAL:{
			SWITCH(myDirectory.FORCEGROUP){
				CASE TRUE:	fnGetGroup()
				CASE FALSE:	fnSendCommand('gaddrbook all')
			}
		}
		CASE DIR_TYPE_LOCAL:{
			fnSendCommand('addrbook names')
		}
		CASE DIR_TYPE_LDAP:{
			fnSendCommand('globaldir grouplist')
		}
	}
}
DEFINE_FUNCTION fnDirViewReload(){
	STACK_VAR INTEGER start
	STACK_VAR INTEGER x
	IF(myDirectory.PAGESIZE == 0){myDirectory.PAGESIZE = 6}
	start = myDirectory.PAGENO * myDirectory.PAGESIZE - myDirectory.PAGESIZE
	IF(myDirectory.PAGENO == 1){
		SELECT{
			ACTIVE(LENGTH_ARRAY(myDirectory.SEARCH1)):{
				SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,',myDirectory.SEARCH1"
			}
			ACTIVE(LENGTH_ARRAY(myDirectory.GROUP)):{
				SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,',myDirectory.GROUP"
			}
			ACTIVE(1):{
				SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,'"
			}
		}
		IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
			IF(myDirectory.SEARCHCOUNT > myDirectory.PAGESIZE){
				STACK_VAR FLOAT y
				y = myDirectory.SEARCHCOUNT MOD myDirectory.PAGESIZE
				y = myDirectory.SEARCHCOUNT - y + myDirectory.PAGESIZE
				y = y / myDirectory.PAGESIZE

				SEND_COMMAND tp, "'^GLL-',ITOA(lvlDIR_ScrollBar),',1'"
				SEND_COMMAND tp, "'^GLH-',ITOA(lvlDIR_ScrollBar),',',FTOA(y)"
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',1'"
			}
			ELSE{
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
			}
		}
		ELSE{
			IF(myDirectory.ENTRYCOUNT > myDirectory.PAGESIZE){
				STACK_VAR FLOAT y
				y = myDirectory.ENTRYCOUNT MOD myDirectory.PAGESIZE
				y = myDirectory.ENTRYCOUNT - y + myDirectory.PAGESIZE
				y = y / myDirectory.PAGESIZE

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
		FOR(x = 1; x <= myDirectory.PAGESIZE; x++){
			IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
				IF(start + x <= myDirectory.SEARCHCOUNT){
					SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[x]),',0,',myDirectory.SEARCHLIST[x+start].NAME"
					y = x
				}
			}
			ELSE{
				IF(start + x <= myDirectory.ENTRYCOUNT){
					SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[x]),',0,',myDirectory.ENTRYLIST[x+start].NAME"
					y = x
				}
			}
		}
		IF(y){
			SEND_COMMAND tp,"'^SHO-',ITOA(btnDirRecords[1]),'.',ITOA(btnDirRecords[y]),',1'"
		}
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDirRecords[y+1]),'.',ITOA(btnDirRecords[LENGTH_ARRAY(btnDirRecords)]),',0'"
	}
	myDirectory.RECORDSELECTED = 0
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirBreadCrumbs),',',ITOA((LENGTH_ARRAY(myDirectory.GROUP)))"
	fnDisplaySearchStrings()
	myDirectory.BUSY = FALSE
}

DEFINE_FUNCTION fnDirViewClear(){
	STACK_VAR INTEGER x
	SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,'"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
	SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirRecords[1]),'.',ITOA(btnDirRecords[LENGTH_ARRAY(btnDirRecords)]),',0'"
	fnDisplaySearchStrings()
	myDirectory.PAGENO = 1
}
DEFINE_FUNCTION fnGetGroup(){
	STACK_VAR INTEGER x;
	fnDirViewClear()
	FOR(x = 1; x <= DIRSIZE; x++){
		STACK_VAR uEntry pENTRY
		myDirectory.ENTRYLIST[x] = pENTRY
	}
	myDirectory.ENTRYCOUNT = 0
	myDirectory.BUSY = TRUE
	SWITCH(myDirectory.TYPE){
		CASE DIR_TYPE_GLOBAL:fnSendCommand("'gaddrbook group "',myDirectory.GROUP,'"'")
		CASE DIR_TYPE_LOCAL:	fnSendCommand("'addrbook group "',myDirectory.GROUP,'"'")
		CASE DIR_TYPE_LDAP:	fnSendCommand("'globaldir grouplist ',myDirectory.GROUP")
	}
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirBreadCrumbs),',0,Loading...'"
}
(** Populates internal search list based on search term **)
DEFINE_FUNCTION fnPopulateSearch(){
	STACK_VAR INTEGER x
	STACK_VAR uEntry pEntry
	// Clear Directory
	FOR(x = 1; x <= DIRSIZE; x++){
		myDirectory.SEARCHLIST[x] 	= pENTRY
		myDirectory.SEARCHCOUNT 	= 0
	}
	// Get Results
	IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
		STACK_VAR INTEGER y
		FOR(x = 1; x <= myDirectory.ENTRYCOUNT; x++){
			IF(FIND_STRING(UPPER_STRING(myDirectory.ENTRYLIST[x].NAME),UPPER_STRING(myDirectory.SEARCH1),1)){
				y++
				myDirectory.SEARCHLIST[y] = myDirectory.ENTRYLIST[x]
			}
		}
		myDirectory.SEARCHCOUNT 	= y
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
		pIndex = (myDirectory.PAGENO * myDirectory.PAGESIZE) - myDirectory.PAGESIZE + GET_LAST(btnDirRecords)
		IF(!LENGTH_ARRAY(myDirectory.SEARCH1) && myDirectory.ENTRYLIST[pIndex].isGroup && !myDirectory.noGroups){
			myDirectory.GROUP = myDirectory.ENTRYLIST[pIndex].UID
			fnGetGroup()
		}
		ELSE IF(LENGTH_ARRAY(myDirectory.SEARCH1) && myDirectory.SEARCHLIST[pIndex].isGroup && !myDirectory.noGroups){
			myDirectory.GROUP = myDirectory.SEARCHLIST[pIndex].UID
			fnGetGroup()
		}
		ELSE{
			IF(myDirectory.RECORDSELECTED == GET_LAST(btnDirRecords)){
				myDirectory.RECORDSELECTED = 0
				SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
			}
			ELSE{
				myDirectory.RECORDSELECTED = GET_LAST(btnDirRecords)
				SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',1'"
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDirBreadCrumbs]{
	PUSH:{
		myDirectory.GROUP = ''
		fnInitDirectory()
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,lvlDIR_ScrollBar]{
	PUSH:    myDirectory.dragBarActive = TRUE
	RELEASE: myDirectory.dragBarActive = FALSE
}
DEFINE_EVENT LEVEL_EVENT[tp,lvlDIR_ScrollBar]{
	IF(myDirectory.dragBarActive){
		myDirectory.PAGENO = LEVEL.VALUE
		fnDirViewReload()
	}
}
//Directory navigation and selection
define_event button_event[tp,btnDirControl] {
	PUSH: {
		SWITCH(get_last(btnDirControl)) {
			CASE 1: {	//Prev
				if(myDirectory.PAGENO > 1) {
					myDirectory.PAGENO--
					fnDirViewReload()
				}
			}
			CASE 2: { 	//Next
				IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
					IF(myDirectory.PAGENO * myDirectory.PAGESIZE + 1 <= myDirectory.SEARCHCOUNT){
						myDirectory.PAGENO++
						fnDirViewReload()
					}
				}
				ELSE{
					IF(myDirectory.PAGENO * myDirectory.PAGESIZE + 1 <= myDirectory.ENTRYCOUNT){
						myDirectory.PAGENO++
						fnDirViewReload()
					}
				}
			}
			CASE 3:
			CASE 4:{
				IF(!myDirectory.BUSY){
					fnInitDirectory()
				}
			}
		}
   }
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDirDial]{
	PUSH:{
		STACK_VAR INTEGER pRecord
		pRecord = (myDirectory.PAGENO * myDirectory.PAGESIZE) - myDirectory.PAGESIZE + myDirectory.RECORDSELECTED
		SWITCH(myDirectory.TYPE){
			CASE DIR_TYPE_LOCAL:
			CASE DIR_TYPE_GLOBAL:{
				IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
					fnSendCommand("'dial addressbook "',myDirectory.SEARCHLIST[pRecord].NAME,'"'")
				}
				ELSE{
					fnSendCommand("'dial addressbook "',myDirectory.ENTRYLIST[pRecord].NAME,'"'")
				}
			}
			CASE DIR_TYPE_LDAP:{
				IF(LENGTH_ARRAY(myDirectory.SEARCH1)){
					fnSendCommand("'dial addressbook_entry "',myDirectory.SEARCHLIST[pRecord].UID,'"'")
				}
				ELSE{
					fnSendCommand("'dial addressbook_entry "',myDirectory.ENTRYLIST[pRecord].UID,'"'")
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
			CASE 27:myDirectory.SEARCH2 = "myDirectory.SEARCH2,' '"
			CASE 28:{}
			CASE 29:{}
			CASE 30:{
				myVCPanels[GET_LAST(tp)].SEARCH_NUMLOCK = !myVCPanels[GET_LAST(tp)].SEARCH_NUMLOCK
				fnDrawSearchKB(GET_LAST(tp))
			}
			CASE 31:myDirectory.SEARCH2 =  fnStripCharsRight(myDirectory.SEARCH2,1)
			CASE 32:{
				myDirectory.SEARCH1 = myDirectory.SEARCH2
				myDirectory.PAGENO = 1
				fnPopulateSearch()
			}
			CASE 33:myDirectory.SEARCH2 =  myDirectory.SEARCH1
			DEFAULT:myDirectory.SEARCH2 = "myDirectory.SEARCH2,DialKB[fnGetSearchKB(GET_LAST(tp))][GET_LAST(btnDirSearchKB)]"
		}
		fnDisplaySearchStrings()
	}
	HOLD[3]:{
		SWITCH(GET_LAST(btnDirSearchKB)){
			CASE 31:myDirectory.SEARCH2 =  ''
		}
		fnDisplaySearchStrings()
	}
}

DEFINE_FUNCTION fnDisplaySearchStrings(){
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar1),',0,',myDirectory.SEARCH1"
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar2),',0,',myDirectory.SEARCH2"
}
/******************************************************************************
	SelfView
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnSelfViewMode]{
	PUSH:{
		SEND_COMMAND vdvControl,'SELFVIEW-TOGGLE'
	}
}
/******************************************************************************
	Interface Feedback
******************************************************************************/
DEFINE_PROGRAM {
	STACK_VAR INTEGER b;
	FOR(b = 1; b <= LENGTH_ARRAY(btnCamNearPreset); b++){
		[tp,btnCamNearPreset[b]] = (myPCVC.curPreset == b-1)
		[vdvControl,btnCamNearPreset[1]-1+b] = (myPCVC.curPreset == b-1)
	}
	FOR(b = 1; b <= LENGTH_ARRAY(btnCamNearSelect); b++){
		[tp,btnCamNearSelect[b]] = (myPCVC.CAMERA == b)	// Panel Feedback
		[vdvControl,btnCamNearSelect[1]-1+b] 	 = (myPCVC.CAMERA == b)	// Virt Device FB
	}
	// Directory Entry Updates
	FOR(b = 1; b <= myDIRECTORY.PAGESIZE; b++){
		SELECT{
			ACTIVE(myDIRECTORY.RECORDSELECTED == b):SEND_LEVEL tp,btnDirRecords[b],4
			ACTIVE(1):                              SEND_LEVEL tp,btnDirRecords[b],1
		}
	}

	// Call Status Feedback based on call state
	FOR(b = 1; b <= LENGTH_ARRAY(vdvCalls); b++){
		SELECT{
			ACTIVE([vdvCalls[b],238]):                   	SEND_LEVEL tp,addVCCallStatus[b],3
			ACTIVE([vdvCalls[b],237] || [vdvCalls[b],236]): SEND_LEVEL tp,addVCCallStatus[b],2
			ACTIVE(1):                                   	SEND_LEVEL tp,addVCCallStatus[b],1
		}
	}

	[tp,btnSelfViewMode] = (myPCVC.SELFVIEW)
	[tp,btnTracking] = (myPCVC.TRACKING)
	[tp,btnAutoAnswer[1]] = (myPCVC.AUTO_ANSWER == 1)
	[tp,btnAutoAnswer[2]] = (myPCVC.AUTO_ANSWER == 2)
	[vdvControl,235] = (myPCVC.AUTO_ANSWER == 1)
	[vdvControl,234] = (myPCVC.AUTO_ANSWER == 2)


	[tp,btnDirLoading] = (myDirectory.BUSY)
	[tp,btnDirControl[3]] = (myDirectory.BUSY)
	SEND_LEVEL tp,lvlDIR_ScrollBar,myDirectory.PAGENO
}