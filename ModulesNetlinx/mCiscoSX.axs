MODULE_NAME='mCiscoSX'(DEV vdvControl, DEV vdvCalls[], DEV tp[], DEV dvVC)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Solo Control module for Cisco SX Units
	Built to SC standards
	Adapted to handle both
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_CALLS	  = 5
INTEGER MAX_PRESETS = 15
INTEGER MAX_CAMERAS = 7

DEFINE_TYPE STRUCTURE uCall{
	INTEGER 	ID
	CHAR 		TYPE[20]
	CHAR 		DIRECTION[20]
	CHAR 		NAME[50]
	CHAR 		NUMBER[50]
	CHAR 		STATUS[20]
	INTEGER 	isMUTED
	INTEGER	DURATION
}

DEFINE_TYPE STRUCTURE uDirEntry{
	INTEGER 	FOLDER
	CHAR 		RefID[20]
	CHAR 		NAME[75]
	CHAR 		METHOD_NUMBER[5][255]
	CHAR 		METHOD_PROTOCOL[5][10]
}

DEFINE_TYPE STRUCTURE uPreset{
	INTEGER  DEFINED
	CHAR 		NAME[20]
	INTEGER	PresetID
	INTEGER  CameraID
}

DEFINE_TYPE STRUCTURE uPTrack{
	INTEGER  ENABLED
	INTEGER	TRACKING
	INTEGER  CameraID
}

DEFINE_TYPE STRUCTURE uCamera{
	INTEGER  CONNECTOR
	CHAR 		MAKE[20]
	CHAR 		MODEL[20]
	CHAR 		SN[20]
	CHAR 		MAC[20]
	INTEGER  CONNECTOR_OVERRIDE
}

DEFINE_TYPE STRUCTURE uDir{
	// Directory
	INTEGER  STATE					// Flat to show Directory is Processing
	INTEGER	IGNORE_TOTALROWS	// TotalRows value is not garanteed
	INTEGER	NO_MORE_ENTRIES	// Expected a directory entry, didn't find one, so end of directory reached
	INTEGER  CORPORATE			// If true use Corporate Directory
	CHAR		SEARCH1[20]			// Current Search String Restriction
	CHAR		SEARCH2[20]			// Current Search String Being Edited
	INTEGER  dragBarActive		// Side Drag Bar is currently being interacted with
	INTEGER	PAGENO				// Current Page Number
	INTEGER	PAGESIZE				// Interface Page Size
	INTEGER	SELECTED_RECORD
	INTEGER	SELECTED_METHOD
	INTEGER	CURRENT_RECORD		// Work out current record index - Folders and Contacts in same list don't list properly
	INTEGER	RECORDCOUNT
	uDirEntry	RECORDS[20]			// Directory Size
	uDirEntry	TRAIL[8]				// Breadcrumb Trail
	CHAR		PREFERED_METHOD[10]	// Prefered protocol from Dircetory list (optional)
}

DEFINE_TYPE STRUCTURE uSX{
	INTEGER  CARRIER_ENABLED
	// Meta Data
	CHAR		META_MODEL[10]
	CHAR 		META_SW_APP[20]
	CHAR 		META_SW_VER[20]
	CHAR 		META_SW_NAME[20]
	CHAR		META_SW_RELEASE[20]
	CHAR		META_SN[20]
	CHAR		META_SYS_NAME[20]
	// System State
	INTEGER	SYS_MULTISITE
	INTEGER	SYS_MAX_TEMP
	FLOAT 	SYS_TEMP
	LONG		SYS_UPTIME
	CHAR 		SYS_IP[15]
	INTEGER	hasSpeakerTrack

	// Control State
	INTEGER	MIC_MUTE
	INTEGER  VOL_MUTE
	SINTEGER VOL
	INTEGER	SELF_VIEW_POS
	INTEGER	SELF_VIEW
	INTEGER	SELF_VIEW_FULL
	INTEGER	SpeakerTracking
	INTEGER  NEAR_CAMERA				// Which near camera to control
	INTEGER	NEAR_CAMERA_LOCKED	// Don't change camera based on MainInputSource feedback
	INTEGER  FAR_CAMERA				// Which far  camera to control
	uPTrack  PRESENTERTRACK
	INTEGER  CONTENT_PIP_POS
	INTEGER  CONTENT_PIP_FULL

	// Vol Helpers
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
	// Other
	CHAR 		DIAL_STRING[255]
	INTEGER	ContentRx
	INTEGER	ContentTx
	// Presets
	INTEGER	PRESETS_LOADING
	uPreset	PRESET[MAX_PRESETS]
	INTEGER	curPreset
	INTEGER	FORCE_PRESET_COUNT	// A number of presets this system always shows
	uCamera  CAMERA[MAX_CAMERAS]
	// Comms
	INTEGER	DISABLED
	INTEGER 	DEBUG
	INTEGER	isIP
	INTEGER 	CONN_STATE
	INTEGER 	API_VER
	INTEGER 	PEND
	CHAR 	  	Rx[8000]
	CHAR 	  	Tx[4000]
	CHAR 		Username[25]
	CHAR		Password[25]
	CHAR		BAUD[10]
	CHAR 		IP_HOST[15]
	INTEGER 	IP_PORT
	// Call State
	uCall		ACTIVE_CALLS[MAX_CALLS]
	// Directory
	uDir		DIRECTORY
}


DEFINE_TYPE STRUCTURE uSXPanel{
	INTEGER DIAL_CAPS
	INTEGER DIAL_SHIFT
	INTEGER DIAL_NUMLOCK
}
/******************************************************************************
	GUI Interface levels
******************************************************************************/
DEFINE_CONSTANT
INTEGER lvlVolume				= 1
INTEGER lvlDIR_ScrollBar 	= 2
/******************************************************************************
	Interface Text Fields
******************************************************************************/
// Meta Data
INTEGER addDirSearch		    = 57
INTEGER addIncomingCallName = 58
INTEGER addVCCallStatus[]	 = {61,62,63,64,65}
INTEGER addVCCallTime[]     = {71,72,73,74,75}
/******************************************************************************
	Button Numbers - General Control
******************************************************************************/
DEFINE_CONSTANT
(**	Microphone Mute		**)
INTEGER btnMicMute		= 201
(**	SelfView Toggle		**)
INTEGER btnSelfViewMode	= 202
(**	SelfView Toggle		**)
INTEGER btnSelfViewPos[]= {203,204}
(**	Toggle Tracking Mode **)
INTEGER btnSpeakerTrack		= 205
INTEGER btnPresenterTrack	= 206
INTEGER btnSelfViewToggle  = 209
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
INTEGER btnLayoutLocal[] = {
	241,242,243,244,245
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
INTEGER btnPresets[] = {
	301,302,303,304,305,306,307,308,309,310,
	311,312,313,314,315,316,317,318,319,320,
	321,322,323,324,325,326,327,328,329,330
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
INTEGER btnDirType[]       = {606,607,608} // Local/Corporate/Toggle

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
	Button Numbers - Custom Speed Dialing
******************************************************************************/
INTEGER btnSpeedDialToDial[] = {
	2001,2002,2003,2004,2005,2006,2007,2008,2009,2010
}

INTEGER btnSpeedDialDirect[] = {
	2101,2102,2103,2104,2105,2106,2107,2108,2109,2110
}

/******************************************************************************
	Button Numbers - Remote Control Emulation - See Below for Commands
******************************************************************************/
INTEGER btnRemote[] = {
	3001,3002,3003,3004,3005,3006,3007,3008,3009,3010,
	3011,3012,3013,3014,3015,3016,3017,3018,3019,3020,
	3021,3022,3023,3024,3025,3026,3027,3028,3029,3030,
	3031,3032,3033,3034,3035,3036,3037,3038,3039,3040,
	3041,3042,3043,3044,3045,3046
}
/******************************************************************************
	Custom Dial Commands
	These buttons initiate dialing through a custom method
	They should not be altered, but can be added to as required
	They are created as client requirements appear
******************************************************************************/
INTEGER btnCustomDial[] = {
	3101,3102,3103,3104,3105,3106,3107,3108,3109,3110
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

INTEGER DIR_STATE_IDLE	= 0
INTEGER DIR_STATE_PEND	= 1
INTEGER DIR_STATE_LOAD	= 2
INTEGER DIR_STATE_SHOW	= 3

INTEGER API_TC	= 1
INTEGER API_CE	= 2

INTEGER DEBUG_ERROR		= 0	// Only Errors Reported
INTEGER DEBUG_BASIC		= 1	// General Debugging
INTEGER DEBUG_DEVELOP	= 2	// Detailed Debugging

INTEGER SELF_VIEW_POS_CL = 2
INTEGER SELF_VIEW_POS_CR = 6
INTEGER SELF_VIEW_POS_LL = 1
INTEGER SELF_VIEW_POS_LR = 7
INTEGER SELF_VIEW_POS_UC = 4
INTEGER SELF_VIEW_POS_UL = 3
INTEGER SELF_VIEW_POS_UR = 5

INTEGER chnNearCam[] = {101,102,103,104,105,106}
INTEGER chnFarCam[]  = {111,112,113,114,115,116}

DEFINE_FUNCTION CHAR[20] fnGetSelfviewString(INTEGER pPOS){
	SWITCH(pPOS){
		CASE SELF_VIEW_POS_CL:RETURN 'CenterLeft'
		CASE SELF_VIEW_POS_CR:RETURN 'CenterRight'
		CASE SELF_VIEW_POS_LL:RETURN 'LowerLeft'
		CASE SELF_VIEW_POS_LR:RETURN 'LowerRight'
		CASE SELF_VIEW_POS_UC:RETURN 'UpperCenter'
		CASE SELF_VIEW_POS_UL:RETURN 'UpperLeft'
		CASE SELF_VIEW_POS_UR:RETURN 'UpperRight'
	}
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_REBOOT[]		= {3000}
LONG TLT_COMMS[]  	= {120000}
LONG TLT_POLL[]   	= {45000}
LONG TLT_TIMER[]		= {1000}
LONG TLT_VOL[]			= {200}
LONG TLT_TIMEOUT[]	= {20000}
LONG TLT_RETRY[]		= {2000}
LONG TLT_CALL_EVENT[]= {1000}

VOLATILE uSX   	mySX
VOLATILE uSXPanel	mySXPanel[5]

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
	IF(mySX.IP_HOST == ''){
		fnDebug(DEBUG_ERROR,'ERR: SX','No IP Address')
	}
	ELSE{
		fnDebug(DEBUG_BASIC,'TryIP>SX on',"mySX.IP_HOST,':',ITOA(mySX.IP_PORT)")
		mySX.CONN_STATE = CONN_TRYING
		SWITCH(mySX.IP_PORT){
			CASE 23: IP_CLIENT_OPEN(dvVC.port, mySX.IP_HOST, mySX.IP_PORT, IP_TCP)
			CASE 22:{
				IF(mySX.Username = ''){ mySX.Username = 'admin' }
				SSH_CLIENT_OPEN(dvVC.port,mySX.IP_HOST,mySX.IP_PORT,mySX.Username,mySX.Password,'','')
			}
		}
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	SWITCH(mySX.IP_PORT){
		CASE 23: IP_CLIENT_CLOSE(dvVC.port)
		CASE 22: SSH_CLIENT_CLOSE(dvVC.port)
	}
}

DEFINE_FUNCTION fnQueueTx(CHAR pCommand[255], CHAR pParam[255]){
	fnDebug(DEBUG_DEVELOP,'fnQueueTX',"'[',ITOA(LENGTH_ARRAY(mySX.Tx)),']',pCommand,' ', pParam,$0D")
	mySX.Tx = "mySX.Tx,pCommand,' ', pParam,$0D"
	fnSendTx()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendTx(){
	IF((!mySX.isIP || mySX.CONN_STATE == CONN_CONNECTED) && !mySX.PEND){
		IF(FIND_STRING(mySX.Tx,"$0D",1)){
			STACK_VAR CHAR toSend[200]
			toSend = REMOVE_STRING(mySX.Tx,"$0D",1)
			fnDebug(DEBUG_BASIC,'->VC ',toSend)
			SEND_STRING dvVC, toSend
			mySX.PEND = TRUE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	mySX.PEND = FALSE
	mySX.TX = ''
	IF(mySX.ISIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pTYPE,CHAR Msg[], CHAR MsgData[]){
	IF(mySX.DEBUG >= pTYPE){
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
DEFINE_FUNCTION fnPoll(){
	fnQueueTx('xStatus','SystemUnit Uptime')
	fnQueueTx('xStatus','SystemUnit Hardware Temperature')
}
DEFINE_FUNCTION fnInitData(){
	fnQueueTx('echo','off')
	fnQueueTx('xFeedback deregister','/Status/Diagnostics')
	fnQueueTx('xFeedback register','/Status/SystemUnit')
	fnQueueTx('xFeedback register','/Event')
	fnQueueTx('xFeedback register','/Status/Audio')
	fnQueueTx('xFeedback register','/Status/Video/Input')
	fnQueueTx('xFeedback register','/Status/Video/Selfview')
	fnQueueTx('xFeedback register','/Status/Call')
	fnQueueTx('xFeedback register','/Status/Camera')
	fnQueueTx('xFeedback register','/Status/Cameras')
	fnQueueTx('xFeedback register','/Status/Conference')
	fnQueueTx('xFeedback register','/Status/Network')
	fnQueueTx('xFeedback register','/Status/Standby')

	fnQueueTx('xConfiguration','Peripherals Profile Touchpanels: 0')

	fnQueueTx('xStatus','Audio')
	fnQueueTx('xStatus','Call')
	fnQueueTx('xStatus','Video Input')
	fnQueueTx('xStatus','Video Selfview')
	fnQueueTx('xStatus','Conference')
	fnQueueTx('xStatus','Network')
	fnQueueTx('xStatus','Standby')
	fnQueueTx('xStatus','SystemUnit')

	fnInitPoll()
}
DEFINE_FUNCTION fnResetData(){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= MAX_CALLS; x++){
		STACK_VAR uCALL blankCall
		mySX.ACTIVE_CALLS[x] = blankCall
	}
	mySX.SYS_IP   			= ''
	mySX.META_MODEL 			= ''
	mySX.META_SW_APP 		= ''
	mySX.META_SW_VER 		= ''
	mySX.META_SW_NAME 		= ''
	mySX.META_SW_RELEASE 	= ''
	mySX.META_SN 				= ''
	mySX.SYS_MULTISITE 		= FALSE
	mySX.SYS_MAX_TEMP 		= 0
	mySX.SYS_TEMP 			= 0
	mySX.SYS_UPTIME 			= 0
	mySX.Tx = ''
	mySX.Rx = ''
}
(** Reboot Events **)
DEFINE_FUNCTION fnReboot(){
	IF(TIMELINE_ACTIVE(TLID_REBOOT)){TIMELINE_KILL(TLID_REBOOT)}
	TIMELINE_CREATE(TLID_REBOOT,TLT_REBOOT,LENGTH_ARRAY(TLT_REBOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_REBOOT]{
	SEND_STRING vdvControl, 'ACTION-REBOOTING'
	fnQueueTx('xCommand Boot','')
}
/******************************************************************************
	Utility Functions - Device Feedback
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER ProfileIndex
	fnDebug(DEBUG_BASIC,'VC-> ',pDATA)
	IF(pDATA == ''){		 RETURN FALSE}
	ELSE IF(pDATA == 'Command not recognized.'){
		mySX.PEND = FALSE
		WAIT 10{
			IF(mySX.ISIP){
				fnCloseTCPConnection()
			}
			ELSE{
				mySX.Tx = ''
				fnInitData()
			}
		}
	}
	ELSE IF(pDATA == '** end'){
		// Directory End
		IF(mySX.DIRECTORY.STATE == DIR_STATE_LOAD){
			IF(mySX.DIRECTORY.IGNORE_TOTALROWS){
				IF(mySX.DIRECTORY.CURRENT_RECORD < mySX.DIRECTORY.PAGESIZE){
					mySX.DIRECTORY.NO_MORE_ENTRIES = TRUE
				}
			}
			fnDisplayDirectory()
		}
		// Presets End
		IF(mySX.PRESETS_LOADING == TRUE){
			mySX.PRESETS_LOADING = FALSE
			fnInitPanel(0)
		}
		RETURN TRUE
	}
	ELSE IF(pDATA == 'OK' || pDATA == 'ERROR'){
		mySX.PEND = FALSE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		fnSendTx()
		RETURN TRUE
	}
	ELSE{
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
			CASE 'xStatus':{	// echoing - Re-init
				fnInitData()
			}
			CASE '*r':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'ConfigurationProfileListResult':{
						ProfileIndex = 1
					}
					CASE 'SelfviewSetResult':{

					}
					CASE 'PresetListResult':{
						mySX.PRESETS_LOADING = TRUE
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Preset':{
								STACK_VAR INTEGER pIndex
								pIndex = ATOI(REMOVE_STRING(pDATA,' ',1))
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Name:':		mySX.PRESET[pIndex].NAME = fnRemoveQuotes(pDATA)
									CASE 'PresetId:':{
										mySX.PRESET[pIndex].PresetID = ATOI(pDATA)
										mySX.PRESET[pIndex].DEFINED = TRUE
									}
									CASE 'CameraId:': mySX.PRESET[pIndex].CameraID = ATOI(pDATA)
								}
							}
						}
					}
					CASE 'PhonebookSearchResult':
					CASE 'ResultSet':{
						IF(FIND_STRING(pDATA,'(status=Error)',1)){
							mySX.DIRECTORY.RECORDCOUNT = 0
							fnDisplayDirectoryLoading()
							SWITCH(mySX.DIRECTORY.CORPORATE){
								CASE TRUE:	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[1]),',0,Global Directory Error'"
								CASE FALSE:	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[1]),',0,Local Directory Error'"
							}
							// Hide Breadcrumbs
							SEND_COMMAND tp, "'^SHO-',ITOA(btnDirBreadCrumbs),',0'"
							// Hide Page Number
							SEND_COMMAND tp, "'^SHO-',ITOA(btnDirPage),',0'"
							// Hide Search Bar
							SEND_COMMAND tp, "'^SHO-',ITOA(btnDirSearchBar1),',0'"
							// Hide Controls - Scroll Bar
							SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
							// Hide Controls - Up/Dn/Home
							SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[1]),'.',ITOA(btnDirControl[4]),',0'"
							// Hide Controls - Dial Button
							SEND_COMMAND tp, "'^SHO-',ITOA(btnDirDial),',0'"
						}
						ELSE{
							mySX.DIRECTORY.STATE = DIR_STATE_LOAD
							SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
								CASE 'ResultInfo':{
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
										CASE 'TotalRows':{
											IF(!mySX.DIRECTORY.IGNORE_TOTALROWS){
												mySX.DIRECTORY.RECORDCOUNT = ATOI(pDATA)
											}
										}
									}
									mySX.DIRECTORY.NO_MORE_ENTRIES = FALSE
									mySX.DIRECTORY.CURRENT_RECORD = 0
								}
								CASE 'Folder':{
									STACK_VAR INTEGER x
									mySX.DIRECTORY.CURRENT_RECORD = ATOI(REMOVE_STRING(pDATA,' ',1))
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
										CASE 'Name:':{
											mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].NAME  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'FolderId:':{
											mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].FOLDER = TRUE
											mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].RefID  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
									}
								}
								CASE 'Contact':{
									STACK_VAR INTEGER x
									mySX.DIRECTORY.CURRENT_RECORD = ATOI(REMOVE_STRING(pDATA,' ',1))
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
										CASE 'Name:':{
											mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].NAME  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'ContactId:':{
											mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].RefID = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'ContactMethod':{
											STACK_VAR INTEGER y
											y = ATOI(REMOVE_STRING(pDATA,' ',1))
											SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
												CASE 'Number:':{
													pDATA = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
													mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].METHOD_NUMBER[y] = pDATA
												}
												CASE 'Protocol:':{
													mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.CURRENT_RECORD].METHOD_PROTOCOL[y] = pDATA
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			CASE '*e':{	// Event Response
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'CameraPresetListUpdated':{
						STACK_VAR INTEGER p
						FOR(p = 1; p <= MAX_PRESETS; p++){
							STACK_VAR uPreset myPreset
							mySX.PRESET[p] = myPreset
						}
						fnQueueTx('xCommand','Camera Preset List')
					}
					CASE 'IncomingCallIndication':
					CASE 'OutgoingCallIndication':{
						REMOVE_STRING(pDATA,'CallId:',1)
						fnRegisterCall(ATOI(pDATA))
						fnQueueTx('xStatus Call',pDATA)
					}
					CASE 'CallSuccessful':{
						REMOVE_STRING(pDATA,'CallId:',1)
						fnQueueTx('xStatus Call',REMOVE_STRING(pDATA,' ',1))
					}
					CASE 'CallDisconnect':{
						// Variable to hold this call ID once found
						STACK_VAR INTEGER pCallID
						SWITCH(mySX.API_VER){
							CASE API_TC:{
								REMOVE_STRING(pDATA,'CallId: ',1)
								pCallID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
							}
							CASE API_CE:{
								IF(FIND_STRING(pDATA,'CallId: ',1)){
									REMOVE_STRING(pDATA,'CallId: ',1)
									pCallID = ATOI(pDATA)
								}
							}
						}
						IF(pCallID){
							// Debug Feedback
							fnDebug(DEBUG_DEVELOP,'FB CalDis',ITOA(pCallID))
							// Remove this call from the list of active calls
							IF(fnGetCall(pCallID)){
								fnRemoveCall(pCallID)
							}
						}
					}
					CASE 'UserInterface':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Extensions':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Event':{
										STACK_VAR CHAR pEVENT[100]
										SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
											CASE 'Pressed Signal':pEVENT = 'INTERFACE_API-PRESS,'
											CASE 'Clicked Signal':pEVENT = 'INTERFACE_API-CLICK,'
											CASE 'Released Signal':pEVENT = 'INTERFACE_API-RELEASE,'
										}

										pData = fnRemoveWhiteSpace(pData)
										pDATA = fnRemoveQuotes(pData)
										IF(FIND_STRING(pDATA,':',1)){
											pEVENT = "pEVENT,fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1),',',pDATA"
										}
										ELSE{
											pEVENT = "pEVENT,pDATA,',NONE'"
										}
										SEND_STRING vdvControl,pEVENT
									}
								}
							}
						}
					}
				}
			}
			CASE '*s':{	// Status Response
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'Preset':{
						STACK_VAR INTEGER Preset
						Preset = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Defined:':{
								mySX.PRESET[Preset].DEFINED = (fnRemoveWhiteSpace(pDATA) == 'True')
							}
							CASE 'Description:':{
								mySX.PRESET[Preset].NAME = fnRemoveWhiteSpace(fnRemoveQuotes(pDATA))
							}
						}
						IF(Preset == 15){
							fnSetupPresetButtons(0)
						}
					}
					CASE 'Audio':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Microphones':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Mute:':{
										SWITCH(fnRemoveWhiteSpace(pDATA)){
											CASE 'On': mySX.MIC_MUTE = TRUE
											CASE 'Off':mySX.MIC_MUTE = FALSE
										}
									}
								}
							}
							CASE 'Volume:':{
								mySX.VOL = ATOI(fnRemoveWhiteSpace(pDATA))
							}
							CASE 'VolumeMute:':{
								IF(pDATA == 'Off'){
									mySX.VOL_MUTE = FALSE
								}
								ELSE IF(pDATA == 'On'){
									mySX.VOL_MUTE = TRUE
								}
							}
						}
					}
					CASE 'Video':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Selfview':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Mode:':{
										SWITCH(fnRemoveWhiteSpace(pDATA)){
											CASE 'On': mySX.SELF_VIEW = TRUE
											CASE 'Off':mySX.SELF_VIEW = FALSE
										}
									}
									CASE 'FullscreenMode:':{
										SWITCH(fnRemoveWhiteSpace(pDATA)){
											CASE 'On': mySX.SELF_VIEW_FULL = TRUE
											CASE 'Off':mySX.SELF_VIEW_FULL = FALSE
										}
									}
									CASE 'PIPPosition':{
										SWITCH(fnRemoveWhiteSpace(pDATA)){
											CASE 'CenterLeft':	mySX.SELF_VIEW_POS = SELF_VIEW_POS_CL
											CASE 'CenterRight':	mySX.SELF_VIEW_POS = SELF_VIEW_POS_CR
											CASE 'LowerLeft':		mySX.SELF_VIEW_POS = SELF_VIEW_POS_LL
											CASE 'LowerRight':	mySX.SELF_VIEW_POS = SELF_VIEW_POS_LR
											CASE 'UpperCenter':	mySX.SELF_VIEW_POS = SELF_VIEW_POS_UC
											CASE 'UpperLeft':		mySX.SELF_VIEW_POS = SELF_VIEW_POS_UL
											CASE 'UpperRight':	mySX.SELF_VIEW_POS = SELF_VIEW_POS_UR
										}
									}
								}
							}
							CASE 'Input':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'MainVideoSource:':{
										IF(mySX.NEAR_CAMERA != ATOI(pDATA) && !mySX.NEAR_CAMERA_LOCKED){
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Pan:Stop'")
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Tilt:Stop'")
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Zoom:Stop'")
											mySX.NEAR_CAMERA = ATOI(pDATA)
											SEND_STRING vdvControl,"'CAMERA-CONTROL,',ITOA(mySX.NEAR_CAMERA)"
										}
									}
								}
							}
						}
					}
					CASE 'Network':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE '1':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'IPv4':{
										SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
											CASE 'Address:':mySX.SYS_IP = fnRemoveQuotes(pDATA)
										}
									}
								}
							}
						}
					}
					CASE 'Cameras':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'SpeakerTrack':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Availability:':{
										mySX.hasSpeakerTrack = (pDATA == 'Available')
										SEND_COMMAND tp,"'^SHO-',ITOA(btnSpeakerTrack),',',ITOA(mySX.hasSpeakerTrack)"
									}
									CASE 'Status:':{
										mySX.SpeakerTracking = (pDATA == 'Active')
										IF(!mySX.SpeakerTracking){
											SWITCH(mySX.API_VER){
												CASE API_TC:	fnQueueTx('xCommand Preset',"'Activate PresetId: ', ITOA(1)")
												CASE API_CE:	fnQueueTx('xCommand Camera Preset',"'Activate PresetId: ', ITOA(1)")
											}
										}
									}
								}
							}
							CASE 'PresenterTrack':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'Availability:':{
										mySX.PRESENTERTRACK.ENABLED = (pDATA == 'Available')
										SEND_COMMAND tp,"'^SHO-',ITOA(btnPresenterTrack),',',ITOA(mySX.PRESENTERTRACK.ENABLED)"
									}
									CASE 'Status:':{
										mySX.PRESENTERTRACK.TRACKING = (pDATA == 'Follow')
										IF(mySX.PRESENTERTRACK.TRACKING && mySX.PRESENTERTRACK.CameraID){
											IF(mySX.CAMERA[mySX.PRESENTERTRACK.CameraID].CONNECTOR_OVERRIDE){
												fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[mySX.PRESENTERTRACK.CameraID].CONNECTOR_OVERRIDE)")
											}
											ELSE{
												fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[mySX.PRESENTERTRACK.CameraID].CONNECTOR)")
											}
										}
									}
								}
							}
							CASE 'Camera':{
								STACK_VAR INTEGER pCam
								pCam = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
									CASE 'DetectedConnector': mySX.CAMERA[pCam].Connector = ATOI(pDATA)
									CASE 'Manufacturer':      mySX.CAMERA[pCam].MAKE  = fnRemoveWhiteSpace(fnRemoveQuotes(pData))
									CASE 'Model':             mySX.CAMERA[pCam].MODEL = fnRemoveWhiteSpace(fnRemoveQuotes(pData))
									CASE 'SerialNumber':      mySX.CAMERA[pCam].SN    = fnRemoveWhiteSpace(fnRemoveQuotes(pData))
									CASE 'MacAddress':        mySX.CAMERA[pCam].MAC   = fnRemoveWhiteSpace(fnRemoveQuotes(pData))
								}
							}
						}
					}
					CASE 'Call':{
						STACK_VAR INTEGER CallID
						STACK_VAR CHAR	CallDetail[50]
						CallID = ATOI(REMOVE_STRING(pDATA,' ',1))
						CallDetail = fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)
						IF(CallDetail == '(ghost=True)'){RETURN TRUE}
						pDATA = fnRemoveWhiteSpace(pDATA)
						pDATA = fnRemoveQuotes(pDATA)
						fnDebug(DEBUG_DEVELOP,'FB Call',"ITOA(CallID),',',CallDetail,',',pDATA")
						IF(mySX.ACTIVE_CALLS[2].ID != 0){
							fnDebug(DEBUG_DEVELOP,'ID SET!!!!!',ITOA(mySX.ACTIVE_CALLS[2].ID))
						}
						SWITCH(CallDetail){
							CASE 'CallType':
							CASE 'Direction':
							CASE 'Status':
							CASE 'DisplayName':
							CASE 'RemoteNumber':{
								IF(fnGetCall(CallID)){
									CallID = fnGetCall(CallID)
								}
								ELSE{
									CallID = fnRegisterCall(CallID)
								}
								SWITCH(CallDetail){
									CASE 'CallType':		mySX.ACTIVE_CALLS[CallID].TYPE 		= pDATA
									CASE 'Direction':		mySX.ACTIVE_CALLS[CallID].DIRECTION 	= pDATA
									CASE 'Status':			mySX.ACTIVE_CALLS[CallID].STATUS 		= pDATA
									CASE 'DisplayName':{
										IF(mySX.ACTIVE_CALLS[CallID].NAME != pDATA){
											mySX.ACTIVE_CALLS[CallID].NAME = pDATA
											fnSendCallDetail(0,CallID)
										}
									}
									CASE 'RemoteNumber':{
										IF(mySX.ACTIVE_CALLS[CallID].NUMBER != pDATA){
											mySX.ACTIVE_CALLS[CallID].NUMBER = pDATA
											fnSendCallDetail(0,CallID)
										}
									}
								}
							}
						}
					}
					CASE 'SystemUnit':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
							CASE 'Software Version':{
								mySX.META_SW_VER = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SWITCH(UPPER_STRING(LEFT_STRING(mySX.META_SW_VER,2))){
									CASE 'TC':mySX.API_VER = API_TC
									CASE 'CE':mySX.API_VER = API_CE
								}
								SWITCH(mySX.API_VER){
									CASE API_TC:{
										fnQueueTx('xStatus','Camera')
										fnQueueTx('xStatus','Preset')
									}
									CASE API_CE:{
										fnQueueTx('xStatus','Cameras')
										fnQueueTx('xCommand','Camera Preset List')
									}
								}
								SEND_STRING vdvControl, "'PROPERTY-META,SOFTWARE,',mySX.META_SW_VER"
							}
							CASE 'ProductPlatform':{
								mySX.META_MODEL   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl, "'PROPERTY-META,TYPE,VideoConferencer'"
								SEND_STRING vdvControl, "'PROPERTY-META,MAKE,Cisco'"
								SEND_STRING vdvControl, "'PROPERTY-META,MODEL,',mySX.META_MODEL"
							}
							CASE 'Hardware Module SerialNumber':{
								mySX.META_SN   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl, "'PROPERTY-META,SN,',mySX.META_SN"
							}
							CASE 'Software Application':{
								mySX.META_SW_APP = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl, "'PROPERTY-META,APPLICATION,',mySX.META_SW_APP"
							}
							CASE 'Software ReleaseDate':{
								mySX.META_SW_RELEASE = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl, "'PROPERTY-META,RELEASE,',mySX.META_SW_VER"
							}
							CASE 'ContactInfo':{
								mySX.META_SYS_NAME = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl, "'PROPERTY-META,DESC,',mySX.META_SYS_NAME"
							}
							CASE 'Hardware TemperatureThreshold':{
								IF(mySX.SYS_MAX_TEMP != ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_MAX_TEMP = ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))
									SEND_STRING vdvControl, "'PROPERTY-META,MAX_TEMP,',ITOA(mySX.SYS_MAX_TEMP)"
								}
							}
							CASE 'Hardware Temperature':{
								IF(mySX.SYS_TEMP != ATOF(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_TEMP = ATOF(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))
									SEND_STRING vdvControl, "'PROPERTY-STATE,TEMP,',FTOA(mySX.SYS_TEMP)"
								}
								IF(mySX.META_SN == ''){ fnInitData() }
							}
							CASE 'Uptime':{
								IF(mySX.SYS_UPTIME != ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_UPTIME = ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ) )
									SEND_STRING vdvControl, "'PROPERTY-STATE,UPTIME,',ITOA(mySX.SYS_UPTIME)"
								}
							}
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Utility Functions - Call Handling
******************************************************************************/
DEFINE_FUNCTION INTEGER fnRegisterCall(INTEGER pCallID){
	STACK_VAR INTEGER c
	IF(!fnGetCall(pCallID)){
		FOR(c = 1; c <= MAX_CALLS; c++){
			IF(mySX.ACTIVE_CALLS[c].ID == 0){
				mySX.ACTIVE_CALLS[c].ID = pCallID
				RETURN c
			}
		}
	}
	ELSE{
		RETURN fnGetCall(pCallID)
	}
}
DEFINE_FUNCTION INTEGER fnGetCall(INTEGER pCallID){
	STACK_VAR INTEGER c
	FOR(c = 1; c <= MAX_CALLS; c++){
		IF(mySX.ACTIVE_CALLS[c].ID == pCallID){
			RETURN c
		}
	}
}
DEFINE_FUNCTION fnRemoveCall(INTEGER pCallID){
	STACK_VAR INTEGER c
	STACK_VAR uCALL newCall
	FOR(c = 1; c <= MAX_CALLS; c++){
		IF(mySX.ACTIVE_CALLS[c].ID == pCallID){
			BREAK
		}
	}
	FOR(c = c; c < MAX_CALLS; c++){
		mySX.ACTIVE_CALLS[c] = mySX.ACTIVE_CALLS[c+1]
	}
	mySX.ACTIVE_CALLS[c] = newCall
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER c
	STACK_VAR INTEGER CALL_RINGING
	STACK_VAR INTEGER CALL_DIALLING
	STACK_VAR INTEGER CALL_CONNECTED
	FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
		[vdvCalls[c],236] = (mySX.ACTIVE_CALLS[c].DIRECTION == 'Incoming' && (mySX.ACTIVE_CALLS[c].STATUS == 'Ringing'))
		[vdvCalls[c],237] = (mySX.ACTIVE_CALLS[c].DIRECTION == 'Outgoing' && (mySX.ACTIVE_CALLS[c].STATUS == 'Dialling' || mySX.ACTIVE_CALLS[c].STATUS == 'Connecting'))
		[vdvCalls[c],238] = (mySX.ACTIVE_CALLS[c].STATUS == 'Connected' || mySX.ACTIVE_CALLS[c].STATUS == 'OnHold')
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
	mySX.isIP = !(dvVC.NUMBER)
	CREATE_BUFFER dvVC, mySX.Rx
	TIMELINE_CREATE(TLID_TIMER,TLT_TIMER,LENGTH_ARRAY(TLT_TIMER),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvVC]{
	ONLINE:{
		IF(!mySX.DISABLED){
			IF(mySX.isIP){
				mySX.CONN_STATE = CONN_NEGOTIATE
			}
			ELSE{
				IF(mySX.BAUD = ''){ mySX.BAUD = '115200' }
				SEND_COMMAND dvVC, "'SET BAUD ',mySX.BAUD,' N 8 1 485 DISABLE'"
				mySX.CONN_STATE = CONN_CONNECTED
				fnPoll()
				fnInitPoll()
			}
		}
	}
	OFFLINE:{
		IF(mySX.isIP){
			mySX.CONN_STATE 	= CONN_OFFLINE;
			fnResetData()
			fnReTryTCPConnection()
		}
	}
	ONERROR:{
		IF(mySX.isIP){
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
					mySX.CONN_STATE	= CONN_OFFLINE
					fnResetData()
					fnReTryTCPConnection()
				}
			}
			fnDebug(DEBUG_ERROR,"'ERR SX: [',mySX.IP_HOST,':',ITOA(mySX.IP_PORT),']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!mySX.DISABLED){
			STACK_VAR INTEGER x
			x = 1
			WHILE(x <= LENGTH_ARRAY(DATA.TEXT)){
				fnDebug(DEBUG_DEVELOP,'RAW.Rx->',MID_STRING(DATA.TEXT,x,150))
				x = x+150
			}

			// Telnet Negotiation
			WHILE(mySX.Rx[1] == $FF && LENGTH_ARRAY(mySX.Rx) >= 3){
				STACK_VAR CHAR NEG_PACKET[3]
				NEG_PACKET = GET_BUFFER_STRING(mySX.Rx,3)
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
			IF(FIND_STRING(mySX.Rx,'login:',1) || FIND_STRING(mySX.Rx,'login as:',1)){
				mySX.CONN_STATE = CONN_SECURITY
				fnDebug(DEBUG_DEVELOP,'SX->',mySX.Rx)
				mySX.Rx = ''
				IF(mySX.Username == ''){mySX.Username = 'admin'}
				fnDebug(DEBUG_DEVELOP,'->SX',"mySX.Username,$0D")
				SEND_STRING dvVC, "mySX.Username,$0D"
			}
			ELSE IF(FIND_STRING(mySX.Rx,'Password:',1)){
				fnDebug(DEBUG_DEVELOP,'SX->',mySX.Rx)
				mySX.Rx = ''
				fnDebug(DEBUG_DEVELOP,'->SX',"mySX.Password,$0D")
				SEND_STRING dvVC, "mySX.Password,$0D"
			}
			ELSE IF(FIND_STRING(mySX.Rx,'Welcome to',1) || (FIND_STRING(mySX.Rx,'Login successful',1))){
				fnDebug(DEBUG_DEVELOP,'VC.Rx->',mySX.Rx)
				mySX.Rx = ''
				mySX.Tx = ''
				mySX.PEND = FALSE
				mySX.CONN_STATE = CONN_CONNECTED
				WAIT 10{
					fnInitData()
				}
			}
			ELSE{
				IF(mySX.CONN_STATE == CONN_CONNECTED){
					WHILE(FIND_STRING(mySX.Rx,"$0D,$0A",1)){
						IF(fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySX.Rx,"$0D,$0A",1),2))){
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
	// Switch the Camera
	SWITCH(mySX.API_VER){
		CASE API_CE: fnQueueTx('xCommand',"'Camera Preset',' Activate PresetId: ', ITOA(pPresetID)")
		CASE API_TC: fnQueueTx('xCommand',"'Preset Activate PresetId: ', ITOA(pPresetID)")
	}
	// Set Video (Cisco removed this from presets around 8.2.2 and it's caused many issues)
	IF(mySX.API_VER == API_CE){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= MAX_PRESETS; p++){
			IF(mySX.PRESET[p].PresetID == pPresetID && mySX.PRESET[p].CameraID){
				IF(mySX.CAMERA[mySX.PRESET[p].CameraID].CONNECTOR_OVERRIDE){
					fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[mySX.PRESET[p].CameraID].CONNECTOR_OVERRIDE)")
				}
				ELSE IF(mySX.CAMERA[mySX.PRESET[p].CameraID].Connector){
					fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[mySX.PRESET[p].CameraID].Connector)")
				}
				ELSE{
					SEND_STRING 0,'SX ERROR - CONNECTORID NOT SET'
				}
			}
		}
	}
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
			mySX.DISABLED = TRUE
		}
		IF(!mySX.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'CARRIER':{	
					SWITCH(DATA.TEXT){
						CASE 'INIT':{
							mySX.CARRIER_ENABLED = TRUE
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,BOOLEAN,Power,255,TRUE'"
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,BOOLEAN,Mute,199,TRUE'"
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,INTEGER,Volume,1,0|100,,,TRUE'"
						}
					}
				}
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
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':
						CASE 'TRUE':{
							SEND_COMMAND DATA.DEVICE,'ACTION-WAKE'
						}
						CASE 'OFF':
						CASE 'FALSE':{
							SEND_COMMAND DATA.DEVICE,'ACTION-SLEEP'
						}
					}
				}
				CASE 'ACTION':{
					SWITCH(DATA.TEXT){
						CASE 'WAKE':{ 			fnQueueTx('xCommand Standby','Deactivate') }
						CASE 'SLEEP':{
							mySX.DIAL_STRING = ''
							fnUpdatePanelDialString(0)
							fnQueueTx('xCommand Standby','Activate')
						}
						CASE 'HANGUP':{
							SWITCH(mySX.API_VER){
								CASE API_TC:fnQueueTx('xCommand Call','DisconnectAll')
								CASE API_CE:fnQueueTx('xCommand Call','Disconnect')
							}
						}
						CASE 'REBOOT':{ 	 	fnReboot() }
						CASE 'RESETGUI':{
							mySX.DIAL_STRING = ''
							fnUpdatePanelDialString(0)
						}
						CASE 'RESETDIR':{
							fnClearDirectory()
						}
					}
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'USERNAME':{ mySX.Username = DATA.TEXT }
						CASE 'PASSWORD':{ mySX.Password = DATA.TEXT }
						CASE 'BAUD':{
							mySX.BAUD = DATA.TEXT;
							SEND_COMMAND dvVC, "'SET BAUD ',mySX.BAUD,' N 8 1 485 DISABLE'"
							fnInitData()
						}
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'DEV':	mySX.DEBUG = DEBUG_DEVELOP
								CASE 'TRUE':mySX.DEBUG = DEBUG_BASIC
							}
						}
						CASE 'LOGIN':{
							mySX.Username = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							mySX.Password = DATA.TEXT
						}
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								mySX.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								mySX.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								mySX.IP_HOST = DATA.TEXT
								mySX.IP_PORT = 22
							}
							fnReTryTCPConnection()
						}
						CASE 'PRESENTERCAM':{
							mySX.PRESENTERTRACK.CameraID = ATOI(DATA.TEXT)
						}
						CASE 'DIRECTORY':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'TYPE':{
									mySX.DIRECTORY.CORPORATE = (DATA.TEXT =='CORPORATE')
								}
								CASE 'PAGESIZE':{
									mySX.DIRECTORY.PAGESIZE = ATOI(DATA.TEXT)
								}
								CASE 'METHOD':{
									mySX.DIRECTORY.PREFERED_METHOD = DATA.TEXT
								}
								CASE 'IGNORE_TOTALROWS':{
									mySX.DIRECTORY.IGNORE_TOTALROWS = (DATA.TEXT == 'TRUE')
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
									mySX.FORCE_PRESET_COUNT = ATOI(DATA.TEXT)
								}
							}
						}
						CASE 'CAMERA':{
							STACK_VAR INTEGER c
							c = ATOI(fnGetCSV(DATA.TEXT,1))
							SWITCH(fnGetCSV(DATA.TEXT,2)){
								CASE 'CONNECTOR':{
									mySX.CAMERA[c].CONNECTOR_OVERRIDE = ATOI(fnGetCSV(DATA.TEXT,3))
								}
							}
						}
					}
				}
				CASE 'RAW': 	fnQueueTx(DATA.TEXT,'')
				CASE 'REMOTE': fnQueueTx('xCommand Key',"'Click Key:',DATA.TEXT")
				CASE 'PRESET':{
					STACK_VAR CHAR PRESET_STRING[30]
					SWITCH(mySX.API_VER){
						CASE API_CE:PRESET_STRING = 'Camera Preset'
						CASE API_TC:PRESET_STRING = 'Preset'
					}
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'RECALL':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'NEAR':{
									fnRecallPreset(ATOI(DATA.TEXT))
								}
								CASE 'FAR':{
									SWITCH(mySX.API_VER){
										CASE API_CE: fnQueueTx('xCommand FarEndControl',"'Camera Preset',' Activate PresetId: ', DATA.TEXT")
										CASE API_TC: fnQueueTx('xCommand FarEndControl',"'Preset Activate PresetId: ', DATA.TEXT")
									}
								}
							}
						}
						CASE 'STORE':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'NEAR':{
									SWITCH(mySX.API_VER){
										CASE API_CE:{
											// Not finished, and probably never used
											fnQueueTx('xCommand','Preset Store')
											fnQueueTx('xCommand','Camera Preset List')
										}
										CASE API_TC:{
											fnQueueTx('xCommand', "'Preset Store PresetId: ', fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),' Type:All Description:"',DATA.TEXT,'"'")
											fnQueueTx('xStatus','Preset')
										}
									}
								}
							}
						}
					}
				}
				CASE 'CONTENT':{
					SWITCH(DATA.TEXT){
						CASE 'START': fnQueueTx('xCommand Presentation','start'); mySX.ContentTx = TRUE;
						CASE 'STOP':
						CASE '0':     fnQueueTx('xCommand Presentation','stop');  mySX.ContentTx = FALSE;
						DEFAULT:		  fnQueueTx('xCommand Presentation',"'start PresentationSource:',DATA.TEXT");	  mySX.ContentTx = TRUE;
					}
				}
				CASE 'DIAL':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'AUDIO':fnQueueTx('xCommand Dial',"'CallType:Audio Number:',DATA.TEXT")
						CASE 'AUTO':
						CASE 'VIDEO':fnQueueTx('xCommand Dial',"'CallType:Video Number:',DATA.TEXT")
						CASE 'CUSTOM':{
							STACK_VAR CHAR cmd[255]
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'VIDEO':cmd = "cmd,'CallType:Video'"
								CASE 'AUDIO':cmd = "cmd,'CallType:Audio'"
							}
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'H320':cmd = "cmd,' Protocol:H320'"
								CASE 'H323':cmd = "cmd,' Protocol:H323'"
								CASE 'SIP':cmd = "cmd,' Protocol:Sip'"
							}
							IF(FIND_STRING(DATA.TEXT,',',1)){
								cmd = "cmd,' CallRate:',fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)"
							}
							SWITCH(DATA.TEXT){
								CASE '#CURRENT':	cmd = "cmd,' Number:',mySX.DIAL_STRING"
								DEFAULT:				cmd = "cmd,' Number:',DATA.TEXT"
							}
							fnQueueTx('xCommand Dial',cmd)
						}
					}
				}
				CASE 'DTMF':{
					SWITCH(mySX.API_VER){
						CASE API_TC:fnQueueTx('xCommand DTMFSend',"'DTMFString:',DATA.TEXT")
						CASE API_CE:fnQueueTx('xCommand Call DTMFSend',"'DTMFString:',DATA.TEXT")
					}
				}
				CASE 'SELFVIEW':{
					IF(FIND_STRING(DATA.TEXT,',',1)){
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'POS':fnQueueTx('xCommand Video',"'Selfview Set PIPPosition: ',fnGetSelfviewString(ATOI(DATA.TEXT))")
						}
					}
					ELSE{
						SWITCH(DATA.TEXT){
							CASE 'OFF':{fnQueueTx('xCommand Video','Selfview Set Mode: Off')}
							CASE 'ON':{ fnQueueTx('xCommand Video','Selfview Set Mode: On')}
						}
					}
				}
				CASE 'CAMERA':{
					IF(FIND_STRING(DATA.TEXT,',',1)){
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'CONTROL':{
								IF(FIND_STRING(DATA.TEXT,',',1)){
									mySX.NEAR_CAMERA = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
									mySX.NEAR_CAMERA_LOCKED = (DATA.TEXT == 'LOCKED')
								}
								ELSE{
									mySX.NEAR_CAMERA = ATOI(DATA.TEXT)
								}
							}
						}
					}
					ELSE{
						fnQueueTx('xCommand Video Input',"'SetMainVideoSource ConnectorId: ',DATA.TEXT")
					}
				}
				CASE 'TRACKING':{
					SWITCH(DATA.TEXT){
						CASE 'ON': fnQueueTx('xCommand Cameras SpeakerTrack','Activate')
						CASE 'OFF':fnQueueTx('xCommand Cameras SpeakerTrack','Deactivate')
					}
				}
				CASE 'MICMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON': 		mySX.MIC_MUTE = TRUE
						CASE 'OFF': 	mySX.MIC_MUTE = FALSE
						CASE 'TOGGLE':	mySX.MIC_MUTE = !mySX.MIC_MUTE
					}
					SWITCH(mySX.MIC_MUTE){
						CASE TRUE:  fnQueueTx('xCommand Audio','Microphones Mute');
						CASE FALSE: fnQueueTx('xCommand Audio','Microphones Unmute');
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		fnQueueTx('xCommand Audio','Volume Mute')
						CASE 'OFF':		fnQueueTx('xCommand Audio','Volume Unmute')
						CASE 'TOGGLE':{
							IF(mySX.VOL_MUTE){
								fnQueueTx('xCommand Audio','Volume Unmute')
							}
							ELSE{
								fnQueueTx('xCommand Audio','Volume Mute')
							}
						}
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){

						CASE 'INC':{
							mySX.VOL = mySX.VOL + 5
							IF(mySX.VOL > 100){mySX.VOL = 100}
							fnQueueTx('xCommand Audio',"'Volume Set Level:',ITOA(mySX.VOL)")
						}
						CASE 'DEC':{
							mySX.VOL = mySX.VOL - 5
							IF(mySX.VOL < 0){mySX.VOL = 0}
							fnQueueTx('xCommand Audio',"'Volume Set Level:',ITOA(mySX.VOL)")
						}
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								mySX.VOL = ATOI(DATA.TEXT)
								fnQueueTx('xCommand Audio',"'Volume Set Level:',ITOA(mySX.VOL)")
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								mySX.LAST_VOL = ATOI(DATA.TEXT)
								mySX.VOL_PEND = TRUE
							}
						}
					}
				}
				CASE 'INTERFACE_API':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'SET':{
							STACK_VAR CHAR pWidget[50]
							pWidget = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							SWITCH(DATA.TEXT){
								CASE 'None':	fnQueueTx("'xCommand UserInterface Extensions Widget SetValue'","'Value: "',DATA.TEXT,'" WidgetId: "',pWidget,'"'")
								DEFAULT:			fnQueueTx("'xCommand UserInterface Extensions Widget UnsetValue'","'WidgetId: "',pWidget,'"'")
							}
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(mySX.VOL_PEND){
		mySX.VOL = TYPE_CAST( mySX.LAST_VOL )
		fnQueueTx('xCommand Audio',"'Volume Set Level:',ITOA(mySX.VOL)")
		mySX.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER]{
	STACK_VAR INTEGER x;
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		IF(mySX.ACTIVE_CALLS[x].STATUS == 'Connected'){ mySX.ACTIVE_CALLS[x].DURATION++ }
	}
	fnUpdatePanelCallDuration()
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!mySX.DISABLED){
		STACK_VAR INTEGER c;
		FOR(c = 1; c <= LENGTH_ARRAY(vdvCalls); c++){
			[vdvCalls[c],198] = (mySX.ACTIVE_CALLS[c].isMUTED)
		}
		[vdvControl,198] = (mySX.MIC_MUTE)
		[vdvControl,199] = (mySX.VOL_MUTE)
		SEND_LEVEL vdvControl,1,mySX.VOL
		[vdvControl,241] = (mySX.ContentTx)
		[vdvControl,242] = (mySX.ContentRx)
		[vdvControl,247] = (mySX.PRESENTERTRACK.TRACKING && mySX.PRESENTERTRACK.ENABLED)
		[vdvControl,248] = (mySX.SpeakerTracking && mySX.hasSpeakerTrack)
		[vdvControl,249] = (mySX.hasSpeakerTrack)
		[vdvControl,250] = (mySX.PRESENTERTRACK.ENABLED)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		//[vdvControl,253] = (mySX.CONN_STATE == CONN_SECURITY)
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
	fnUpdatePanelCallDuration()
	fnDrawDialKB(pPanel)
	fnDrawSearchKB(pPanel)
	fnSetupPresetButtons(pPanel)

	SEND_COMMAND tp[pPanel], "'^GLL-',ITOA(lvlDIR_ScrollBar),',1'"

	// Hide or Show the Speaker Track option
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnSpeakerTrack),',',ITOA(mySX.hasSpeakerTrack)"

	// Hide or Show the Presenter Track option
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnPresenterTrack),',',ITOA(mySX.PRESENTERTRACK.ENABLED)"
}

DEFINE_FUNCTION INTEGER fnGetDialKB(INTEGER pPanel){
	IF(mySXPanel[pPanel].DIAL_NUMLOCK){
		RETURN 3
	}
	ELSE IF(mySXPanel[pPanel].DIAL_CAPS && !mySXPanel[pPanel].DIAL_SHIFT){
		RETURN 2
	}
	ELSE IF(mySXPanel[pPanel].DIAL_SHIFT){
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
DEFINE_FUNCTION fnDrawSearchKB(INTEGER pPanel){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 26; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDirSearchKB[x]),',0,',DialKB[1][x]"
	}
}

DEFINE_FUNCTION fnUpdatePanelDialString(INTEGER pPanel){
	IF(pPanel){SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialString),',0,',mySX.DIAL_STRING"}
	ELSE{SEND_COMMAND tp,"'^TXT-',ITOA(btnDialString),',0,',mySX.DIAL_STRING"}
	SEND_COMMAND tp,"'^SHO-',ITOA(btnDialKB[32]),',',ITOA(LENGTH_ARRAY(mySX.DIAL_STRING) > 0)"
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
	pStateText =  UPPER_STRING(mySX.ACTIVE_CALLS[pCALL].STATUS)
	pStateText = "pStateText,$0A,'Name:  ',mySX.ACTIVE_CALLS[pCALL].NAME"
	pStateText = "pStateText,$0A,'Number:',mySX.ACTIVE_CALLS[pCALL].NUMBER"

	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addVCCallStatus[pCall]),',2&3,',pStateText"
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnHangup[pCALL+1]),',',ITOA([vdvCalls[pCALL],236] || [vdvCalls[pCALL],237] || [vdvCalls[pCALL],238])"
}

DEFINE_FUNCTION fnUpdatePanelCallDuration(){
	STACK_VAR INTEGER x
	STACK_VAR CHAR _TIME[10]
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		IF(mySX.ACTIVE_CALLS[x].DURATION){
			IF(![vdvCalls[x],238]){
				IF(mySX.ACTIVE_CALLS[x].DURATION){
					mySX.ACTIVE_CALLS[x].DURATION = 0
					SEND_COMMAND tp,"'^TXT-',ITOA(addVCCallTime[x]),',0,'"
				}
			}
			ELSE{
				_TIME = fnSecondsToTime(mySX.ACTIVE_CALLS[x].DURATION)
				IF(LEFT_STRING(_TIME,3) == '00:'){ GET_BUFFER_STRING(_TIME,3) }
				IF(_TIME[1] == '0'){GET_BUFFER_CHAR(_TIME)}
				SEND_COMMAND tp,"'^TXT-',ITOA(addVCCallTime[x]),',0,',_TIME"
				SEND_STRING vdvCalls[x],"'DURATION-',_TIME"
			}
		}
	}
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
		SWITCH(mySX.API_VER){
			CASE API_TC:fnQueueTx('xCommand DTMFSend',"'DTMFString:',cButtonCmd")
			CASE API_CE:fnQueueTx('xCommand Call DTMFSend',"'DTMFString:',cButtonCmd")
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnMicMute]{
	PUSH:{
		SWITCH(mySX.MIC_MUTE){
			CASE TRUE:	fnQueueTx('xCommand Audio','Microphones UnMute')
			CASE FALSE: fnQueueTx('xCommand Audio','Microphones Mute')
		}
		mySX.MIC_MUTE = !mySX.MIC_MUTE
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnSelfViewToggle]{
	PUSH:{
		SWITCH(mySX.SELF_VIEW){
			CASE TRUE:{  fnQueueTx('xCommand Video','Selfview Set Mode: Off')}
			CASE FALSE:{ fnQueueTx('xCommand Video','Selfview Set Mode: On') }
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnSelfViewMode]{
	PUSH:{
		SWITCH(mySX.SELF_VIEW_FULL){
			CASE TRUE:	fnQueueTx('xCommand Video','Selfview Set FullScreenMode: Off')
			CASE FALSE: fnQueueTx('xCommand Video','Selfview Set FullScreenMode: On')
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnSelfViewPos]{
	PUSH:{
		IF(mySX.SELF_VIEW_POS == 0){mySX.SELF_VIEW_POS = 1}
		SWITCH(GET_LAST(btnSelfViewPos)){
			CASE 1:mySX.SELF_VIEW_POS--
			CASE 2:mySX.SELF_VIEW_POS++
		}
		SWITCH(mySX.SELF_VIEW_POS){
			CASE 0:mySX.SELF_VIEW_POS = 7
			CASE 8:mySX.SELF_VIEW_POS = 1
		}
		fnQueueTx('xCommand Video',"'Selfview Set PIPPosition: ',fnGetSelfviewString(mySX.SELF_VIEW_POS)")
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnLayoutLocal]{
	PUSH:{
		SWITCH(GET_LAST(btnLayoutLocal)){
			CASE 1:fnQueueTx('xCommand','Video Layout LayoutFamily Set Target:Local LayoutFamily:auto')
			CASE 2:fnQueueTx('xCommand','Video Layout LayoutFamily Set Target:Local LayoutFamily:equal')
			CASE 3:fnQueueTx('xCommand','Video Layout LayoutFamily Set Target:Local LayoutFamily:overlay')
			CASE 4:fnQueueTx('xCommand','Video Layout LayoutFamily Set Target:Local LayoutFamily:prominent')
			CASE 5:fnQueueTx('xCommand','Video Layout LayoutFamily Set Target:Local LayoutFamily:single')
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnSpeakerTrack]{
	PUSH:{
		IF(mySX.SpeakerTracking){
			fnQueueTx('xCommand Cameras SpeakerTrack','Deactivate')
		}
		ELSE{
			fnQueueTx('xCommand Cameras SpeakerTrack','Activate')
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnPresenterTrack]{
	PUSH:{
		IF(mySX.PRESENTERTRACK.TRACKING){
			fnQueueTx('xCommand Cameras PresenterTrack','Set Mode: Off')
		}
		ELSE{
			fnQueueTx('xCommand Cameras PresenterTrack','Set Mode: Follow')
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnPresets]{
	PUSH:{
		// To allow feedback on locking channel buttons
		TO[BUTTON.INPUT.DEVICE,BUTTON.INPUT.CHANNEL]
	}
	HOLD[75]:{
		SWITCH(mySX.API_VER){
			CASE API_TC:	fnQueueTx('xCommand Preset',"'Store PresetId: ', ITOA(GET_LAST(btnPresets)),' Type:All Description:"Preset ',ITOA(GET_LAST(btnPresets)),'"'")
			CASE API_CE:{
				fnQueueTx('xCommand Camera Preset',"'Store CameraId: ',ITOA(mySX.NEAR_CAMERA),' PresetID: ', ITOA(GET_LAST(btnPresets))")
			}
		}
	}
	RELEASE:{
		SWITCH(mySX.API_VER){
			CASE API_TC:	fnQueueTx('xCommand Preset',"'Activate PresetId: ', ITOA(GET_LAST(btnPresets))")
			CASE API_CE:{
				fnQueueTx('xCommand Camera Preset',"'Activate PresetId: ', ITOA(GET_LAST(btnPresets))")
			}
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnHangup]{
	PUSH:{
		STACK_VAR INTEGER x
		SWITCH(GET_LAST(btnHangup)){
			CASE 1:{
				SWITCH(mySX.API_VER){
					CASE API_TC:fnQueueTx('xCommand Call','DisconnectAll')
					CASE API_CE:fnQueueTx('xCommand Call','Disconnect')
				}
			}
			DEFAULT:{
				IF(mySX.ACTIVE_CALLS[GET_LAST(btnHangup)-1].ID){
					fnQueueTx('xCommand',"'Call Disconnect CallId:',ITOA(mySX.ACTIVE_CALLS[GET_LAST(btnHangup)-1].ID)")
				}
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnAnswer]{
	PUSH:{
		SWITCH(GET_LAST(btnAnswer)){
			CASE 1:{
				fnQueueTx('xCommand',"'Call Accept'")
			}
			DEFAULT:{
				IF(mySX.ACTIVE_CALLS[GET_LAST(btnAnswer)-1].ID){
					fnQueueTx('xCommand',"'Call Accept CallId:',ITOA(mySX.ACTIVE_CALLS[GET_LAST(btnAnswer)-1].ID)")
				}
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnReject]{
	PUSH:{
		SWITCH(GET_LAST(btnReject)){
			CASE 1:{
				fnQueueTx('xCommand',"'Call Reject'")
			}
			DEFAULT:{
				IF(mySX.ACTIVE_CALLS[GET_LAST(btnReject)-1].ID){
					fnQueueTx('xCommand',"'Call Reject CallId:',ITOA(mySX.ACTIVE_CALLS[GET_LAST(btnReject)-1].ID)")
				}
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

		FOR(b = 1; b <= LENGTH_ARRAY(btnCamNearPreset); b++){
			SWITCH(mySX.API_VER){
				CASE API_TC:{	// Flag if a preset is found
					IF(mySX.PRESET[b].DEFINED){
						y = TRUE
						SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnCamNearPreset[b]),',1'"
						SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnCamNearPreset[b]),',0,',mySX.PRESET[b].NAME"
					}
				}
				CASE API_CE:{
					STACK_VAR pPreset
					FOR(pPreset = 1; pPreset <= MAX_PRESETS; pPreset++){
						IF(b == mySX.PRESET[pPreset].PresetID){
							// Flag if a preset is found
							IF(mySX.PRESET[pPreset].DEFINED){y = TRUE}
							SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnCamNearPreset[b]),',1'"
							SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnCamNearPreset[b]),',0,',mySX.PRESET[pPreset].NAME"
						}
					}
				}
			}
		}
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
		mySX.NEAR_CAMERA = GET_LAST(btnCamNearSelect)
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamNearControl]{
	PUSH:{
		TO[vdvControl,chnNearCam[GET_LAST(btnCamNearControl)]]
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,chnNearCam]{
	ON:{
		STACK_VAR CHAR _VAL[255]
		IF(mySX.NEAR_CAMERA == 0){
			mySX.NEAR_CAMERA = 1
		}
		_VAL = "'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' '"
		SWITCH(GET_LAST(chnNearCam)){
			CASE 1:_VAL = "_VAL,'Tilt:Up   TiltSpeed:1'"
			CASE 2:_VAL = "_VAL,'Tilt:Down TiltSpeed:1'"
			CASE 3:_VAL = "_VAL,'Pan:left  PanSpeed:1'"
			CASE 4:_VAL = "_VAL,'Pan:right PanSpeed:1'"
			CASE 5:_VAL = "_VAL,'Zoom:In   ZoomSpeed:1'"
			CASE 6:_VAL = "_VAL,'Zoom:Out  ZoomSpeed:1'"
		}
		fnQueueTx('xCommand Camera',_VAL)
	}
	OFF:{
		STACK_VAR CHAR _VAL[255]
		_VAL = "'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' '"
		SWITCH(GET_LAST(chnNearCam)){
			CASE 1:
			CASE 2:_VAL = "_VAL,'Tilt:Stop'"
			CASE 3:
			CASE 4:_VAL = "_VAL,'Pan:Stop'"
			CASE 5:
			CASE 6:_VAL = "_VAL,'Zoom:Stop'"
		}
		fnQueueTx('xCommand Camera',_VAL)
	}
}
/******************************************************************************
	Touch Panel Events - Far Camera Control
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnCamFarCallSelect]{
	PUSH:{
		mySX.FAR_CAMERA = GET_LAST(btnCamFarCallSelect)
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCamFarControl]{
	PUSH:{
		TO[vdvControl,chnFarCam[GET_LAST(btnCamFarControl)]]
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,chnFarCam]{
	ON:{
		STACK_VAR CHAR _VAL[255]
		IF(mySX.FAR_CAMERA == 0){
			mySX.FAR_CAMERA = 1
		}
		_VAL = "'Camera Move CallId:',ITOA(mySX.ACTIVE_CALLS[mySX.FAR_CAMERA].ID),' '"
		SWITCH(GET_LAST(chnFarCam)){
			CASE 1:_VAL = "_VAL,'Value:Up'"
			CASE 2:_VAL = "_VAL,'Value:Down'"
			CASE 3:_VAL = "_VAL,'Value:Left'"
			CASE 4:_VAL = "_VAL,'Value:Right'"
			CASE 5:_VAL = "_VAL,'Value:ZoomIn'"
			CASE 6:_VAL = "_VAL,'Value:ZoomOut'"
		}
		fnQueueTx('xCommand FarEndControl',_VAL)
	}
	OFF:fnQueueTx('xCommand FarEndControl',"'Camera Stop CallId:',ITOA(mySX.ACTIVE_CALLS[mySX.FAR_CAMERA].ID)")
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
				mySX.DIAL_STRING = "mySX.DIAL_STRING,' '"
				fnUpdatePanelDialString(0)
			}
			CASE 28:{	// SHIFT
				mySXPanel[p].DIAL_SHIFT = !mySXPanel[p].DIAL_SHIFT
				fnDrawDialKB(p)
			}
			CASE 29:{	// CAPS
				mySXPanel[p].DIAL_CAPS = !mySXPanel[p].DIAL_CAPS
				fnDrawDialKB(p)
			}
			CASE 30:{	// NUMLOCK
				mySXPanel[p].DIAL_NUMLOCK = !mySXPanel[p].DIAL_NUMLOCK
				fnDrawDialKB(p)
			}
			CASE 31:{	// DELETE
				mySX.DIAL_STRING = fnStripCharsRight(mySX.DIAL_STRING,1)
				fnUpdatePanelDialString(0)
			}
			CASE 32:{	// DIAL
				IF(LENGTH_ARRAY(mySX.DIAL_STRING)){
					fnQueueTx('xCommand Dial',"'CallType:Video Number:',mySX.DIAL_STRING")
				}
			}
			CASE 33:{	// NUMLOCK ON
				mySXPanel[p].DIAL_NUMLOCK = TRUE
				fnDrawDialKB(p)
			}
			CASE 34:{	// NUMLOCK OFF
				mySXPanel[p].DIAL_NUMLOCK = FALSE
				fnDrawDialKB(p)
			}
			DEFAULT:{
				STACK_VAR INTEGER kb
				kb = fnGetDialKB(p)
				IF(DialKB[kb][GET_LAST(btnDialKB)] != ' '){
					mySX.DIAL_STRING = "mySX.DIAL_STRING,DialKB[kb][GET_LAST(btnDialKB)]"
					fnUpdatePanelDialString(0)
					IF(mySXPanel[p].DIAL_SHIFT){
						mySXPanel[p].DIAL_SHIFT = FALSE
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
				mySX.DIAL_STRING = ''
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
			mySX.DIAL_STRING = "mySX.DIAL_STRING,DialSpecial[k]"
			fnUpdatePanelDialString(0)
		}
	}
	HOLD[10]:{
		STACK_VAR INTEGER k
		k = GET_LAST(btnDialSpecial)
		IF(DialSpecial_Alt[k] != ''){
			mySX.DIAL_STRING = fnStripCharsRight(mySX.DIAL_STRING,1)
			mySX.DIAL_STRING = "mySX.DIAL_STRING,DialSpecial_Alt[k]"
			fnUpdatePanelDialString(0)
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		[tp[p],btnDialKB[28]] = mySXPanel[p].DIAL_SHIFT
		[tp[p],btnDialKB[29]] = mySXPanel[p].DIAL_CAPS
		[tp[p],btnDialKB[30]] = mySXPanel[p].DIAL_NUMLOCK
	}
}
/******************************************************************************
	Directory Interface
******************************************************************************/
DEFINE_FUNCTION fnClearDirectory(){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 20; x++){
		STACK_VAR uDirEntry BlankEntry
		mySX.DIRECTORY.RECORDS[x] = BlankEntry
	}
	FOR(x = 1; x <= 8; x++){
		STACK_VAR uDirEntry BlankEntry
		mySX.DIRECTORY.TRAIL[x] = BlankEntry
	}
	mySX.DIRECTORY.SEARCH1 = ''
	mySX.DIRECTORY.SEARCH2 = ''
	mySX.DIRECTORY.PAGENO 	= 1
	fnLoadDirectory()
}
DEFINE_FUNCTION fnLoadDirectory(){
	STACK_VAR INTEGER x
	STACK_VAR CHAR toSend[255]
	// Clear out existing data
	FOR(x = 1; x <= mySX.DIRECTORY.PAGESIZE; x++){
		STACK_VAR uDirEntry BlankEntry
		mySX.DIRECTORY.RECORDS[x] = BlankEntry
	}
	// Set directory type based on settings
	SWITCH(mySX.DIRECTORY.CORPORATE){
		CASE TRUE: toSend = "'PhonebookType:Corporate'"
		CASE FALSE:toSend = "'PhonebookType:Local'"
	}
	// Grab highest breadcrumb as the folder to use
	FOR(x = 8; x >= 1; x--){
		IF(LENGTH_ARRAY(mySX.DIRECTORY.TRAIL[x].RefID)){
			toSend = "toSend, ' FolderId:',mySX.DIRECTORY.TRAIL[x].RefID"
			BREAK
		}
	}
	// Set the limit of returned entries
	IF(mySX.DIRECTORY.PAGESIZE == 0){mySX.DIRECTORY.PAGESIZE = 10}
	toSend = "toSend, ' Limit:',ITOA(mySX.DIRECTORY.PAGESIZE)"
	// Set the start record based on what page we are on
	IF(mySX.DIRECTORY.PAGENO > 1){
		toSend = "toSend, ' Offset:',ITOA((mySX.DIRECTORY.PAGENO * mySX.DIRECTORY.PAGESIZE) - mySX.DIRECTORY.PAGESIZE)"
	}
	// If there is a search string in play, use that
	IF(LENGTH_ARRAY(mySX.DIRECTORY.SEARCH1)){
		toSend = "toSend, ' SearchString:',mySX.DIRECTORY.SEARCH1"
	}
	// Send the request and lock out the system until processed
	mySX.DIRECTORY.STATE = DIR_STATE_PEND;
	fnDisplayDirectoryLoading()
	fnQueueTx('xCommand Phonebook Search',toSend)
}

DEFINE_FUNCTION fnDisplayDirectoryLoading(){
	STACK_VAR INTEGER x
	// Show Records
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[1]),',0,Loading...'"
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[2]),'.',ITOA(btnDirRecords[LENGTH_ARRAY(btnDirRecords)]),',0,'"
}

DEFINE_FUNCTION fnDisplayDirectory(){
	STACK_VAR INTEGER x
	STACK_VAR CHAR tmpText[100]

	mySX.DIRECTORY.STATE = DIR_STATE_SHOW

	// Show Search Bar
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirSearchBar1),',1'"
	// Set Up Breadcrumb Trail
	FOR(x = 1; x <= 8; x++){
		IF(mySX.DIRECTORY.TRAIL[x].NAME != ''){
			IF(x == 1){
				tmpText = "mySX.DIRECTORY.TRAIL[x].NAME"
			}
			ELSE{
				tmpText = "tmpText,' > ',mySX.DIRECTORY.TRAIL[x].NAME"
			}
		}
	}
	SEND_COMMAND tp, "'^TXT-',ITOA(btnDirBreadCrumbs),',0,',tmpText"
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirBreadCrumbs),',',ITOA(LENGTH_ARRAY(tmpText) > 0)"

	// Deal with Navigation Bar on first page load
	IF(!mySX.DIRECTORY.IGNORE_TOTALROWS){
		IF(mySX.DIRECTORY.PAGENO == 1){
			IF(mySX.DIRECTORY.RECORDCOUNT > mySX.DIRECTORY.PAGESIZE){
				STACK_VAR INTEGER y
				y = mySX.DIRECTORY.RECORDCOUNT / mySX.DIRECTORY.PAGESIZE
				IF(mySX.DIRECTORY.RECORDCOUNT MOD mySX.DIRECTORY.PAGESIZE){
					y = y+1
				}
				ELSE{
					y = y
				}

				SEND_COMMAND tp, "'^GLH-',ITOA(lvlDIR_ScrollBar),',',FTOA(y)"
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',1'"
				SEND_COMMAND tp, "'^SHO-',ITOA(btnDirPage),',1'"
			}
			ELSE{
				SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
			}
		}
	}
	ELSE{
		SEND_COMMAND tp, "'^SHO-',ITOA(lvlDIR_ScrollBar),',0'"
		SEND_COMMAND tp, "'^SHO-',ITOA(btnDirPage),',0'"
	}


	// Show/Hide 'Prev' Button
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[1]),',',ITOA(mySX.DIRECTORY.PAGENO > 1)"
	// Show/Hide 'Next' Button
	IF(!mySX.DIRECTORY.IGNORE_TOTALROWS){
		SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[2]),',',ITOA(mySX.DIRECTORY.PAGENO * mySX.DIRECTORY.PAGESIZE + 1 <= mySX.DIRECTORY.RECORDCOUNT)"
	}
	ELSE{
		SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[2]),',',ITOA(!mySX.DIRECTORY.NO_MORE_ENTRIES)"
	}
	// Show/Hide 'Reset Dir' Button
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[3]),',',ITOA(LENGTH_ARRAY(mySX.DIRECTORY.TRAIL[1].RefID) || LENGTH_ARRAY(mySX.DIRECTORY.SEARCH1))"

	// Show/Hide 'Clear Search' Button
	SEND_COMMAND tp, "'^SHO-',ITOA(btnDirControl[4]),',',ITOA(LENGTH_ARRAY(mySX.DIRECTORY.SEARCH1) > 0)"



	// Show Records
	FOR(x = 1; x <= mySX.DIRECTORY.PAGESIZE; x++){
		SEND_COMMAND tp,"'^TXT-',ITOA(btnDirRecords[x]),',0,',mySX.DIRECTORY.RECORDS[x].NAME"
	}

	IF(!mySX.DIRECTORY.IGNORE_TOTALROWS){
		// Show Paging Info
		tmpText = ITOA((mySX.DIRECTORY.PAGENO * mySX.DIRECTORY.PAGESIZE) - mySX.DIRECTORY.PAGESIZE+1)
		tmpText = "tmpText,' to '"
		x = mySX.DIRECTORY.PAGENO * mySX.DIRECTORY.PAGESIZE
		IF(x > mySX.DIRECTORY.RECORDCOUNT){x = mySX.DIRECTORY.RECORDCOUNT}
		tmpText = "tmpText,ITOA(x),' of ',ITOA(mySX.DIRECTORY.RECORDCOUNT)"
		SEND_COMMAND tp,"'^TXT-',ITOA(btnDirPage),',0,',tmpText"
	}

	mySX.DIRECTORY.SELECTED_METHOD = 0
	mySX.DIRECTORY.SELECTED_RECORD = 0

	fnDisplayMethods()
	fnDisplaySearchStrings()

	mySX.DIRECTORY.STATE = DIR_STATE_IDLE
}

DEFINE_FUNCTION fnDisplayMethods(){
	IF(mySX.DIRECTORY.SELECTED_RECORD){
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(btnDirMethods); x++){
			SEND_COMMAND tp, "'^TXT-',ITOA(btnDirMethods[x]),',0,',mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_NUMBER[x]"
			SEND_COMMAND tp, "'^SHO-',ITOA(btnDirMethods[x]),',',ITOA(mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_NUMBER[x] != 0)"
		}
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDirDial),',1'"
		IF(mySX.DIRECTORY.SELECTED_METHOD == 0){
			mySX.DIRECTORY.SELECTED_METHOD = 1
			IF(LENGTH_ARRAY(mySX.DIRECTORY.PREFERED_METHOD)){
				FOR(x = 1; x <= 5; x++){
					IF(mySX.DIRECTORY.PREFERED_METHOD == mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_PROTOCOL[x]){
						mySX.DIRECTORY.SELECTED_METHOD = x
						BREAK
					}
				}
			}
		}
		ELSE{
			mySX.DIRECTORY.SELECTED_METHOD = 1
		}
	}
	ELSE{
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDirMethods[1]),'.',ITOA(btnDirMethods[LENGTH_ARRAY(btnDirMethods)]),',0'"
		SEND_COMMAND tp,"'^SHO-',ITOA(btnDirDial),',0'"
		mySX.DIRECTORY.SELECTED_METHOD = 0
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnDirRecords] {
	PUSH:{
		IF(mySX.DIRECTORY.STATE == DIR_STATE_IDLE){
			IF(mySX.DIRECTORY.RECORDS[GET_LAST(btnDirRecords)].FOLDER){
				STACK_VAR INTEGER x
				mySX.DIRECTORY.PAGENO = 1
				FOR(x = 1; x <= 8; x++){
					IF(mySX.DIRECTORY.TRAIL[x].RefID == ''){
						mySX.DIRECTORY.TRAIL[x] = mySX.DIRECTORY.RECORDS[GET_LAST(btnDirRecords)]
						fnLoadDirectory()
						BREAK
					}
				}
			}
			ELSE{
				IF(mySX.DIRECTORY.SELECTED_RECORD = GET_LAST(btnDirRecords)){
					mySX.DIRECTORY.SELECTED_RECORD = 0
				}
				ELSE{
					mySX.DIRECTORY.SELECTED_RECORD = GET_LAST(btnDirRecords)
				}
				fnDisplayMethods()
			}
		}
	}
}

DEFINE_EVENT LEVEL_EVENT[tp,lvlDIR_ScrollBar]{
	IF(mySX.DIRECTORY.dragBarActive){
		mySX.DIRECTORY.PAGENO = LEVEL.VALUE
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,lvlDIR_ScrollBar]{
	PUSH:    mySX.DIRECTORY.dragBarActive = TRUE
	RELEASE:{
		mySX.DIRECTORY.dragBarActive = FALSE
		IF(mySX.DIRECTORY.STATE == DIR_STATE_IDLE){
			fnLoadDirectory()
		}
	}
}

//Directory navigation and selection
define_event button_event[tp,btnDirControl] {
	PUSH: {
		IF(mySX.DIRECTORY.STATE == DIR_STATE_IDLE){
			SWITCH(GET_LAST(btnDirControl)) {
				CASE 1: {	//Prev
					if(mySX.DIRECTORY.PAGENO > 1) {
						mySX.DIRECTORY.PAGENO--
						fnLoadDirectory()
					}
				}
				CASE 2: { 	//Next
					IF(mySX.DIRECTORY.STATE == DIR_STATE_IDLE){
						mySX.DIRECTORY.PAGENO++
						fnLoadDirectory()
					}
				}
				CASE 3:{
					// Reset All
					fnClearDirectory()
				}
				CASE 4:{
					// Clear Search
					fnClearDirectory()
				}
			}
		}
   }
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDirBreadCrumbs]{
	PUSH:{
		STACK_VAR INTEGER x
		FOR(x = 8; x >= 1; x--){
			IF(mySX.DIRECTORY.TRAIL[x].RefID != ''){
				STACK_VAR uDirEntry BlankEntry
				mySX.DIRECTORY.TRAIL[x] = BlankEntry
				BREAK
			}
		}
		mySX.DIRECTORY.PAGENO = 1
		mySX.DIRECTORY.SELECTED_METHOD = 0
		mySX.DIRECTORY.SELECTED_RECORD = 0
		fnLoadDirectory()
	}
}

// Dial Entry
DEFINE_EVENT BUTTON_EVENT[tp,btnDirDial]{
	PUSH:{
		STACK_VAR CHAR toSend[255]
		toSend = "'Number:',mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_NUMBER[mySX.DIRECTORY.SELECTED_METHOD]"
		IF(LENGTH_ARRAY(mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_PROTOCOL[mySX.DIRECTORY.SELECTED_METHOD])){
			toSend = "toSend,' Protocol:',mySX.DIRECTORY.RECORDS[mySX.DIRECTORY.SELECTED_RECORD].METHOD_PROTOCOL[mySX.DIRECTORY.SELECTED_METHOD]"
		}
		fnQueueTx('xCommand Dial',toSend)
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnDirType]{
	PUSH:{
		SWITCH(GET_LAST(btnDirType)){
			CASE 1: mySX.DIRECTORY.CORPORATE = FALSE
			CASE 2: mySX.DIRECTORY.CORPORATE = TRUE
			CASE 3: mySX.DIRECTORY.CORPORATE = !mySX.DIRECTORY.CORPORATE
		}
		fnClearDirectory()
	}
}
/******************************************************************************
	Directory Search
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnDirSearchKB]{
	PUSH:{
		SWITCH(GET_LAST(btnDirSearchKB)){
			CASE 27:mySX.DIRECTORY.SEARCH2 = "mySX.DIRECTORY.SEARCH2,' '"
			CASE 28:{}
			CASE 29:{}
			CASE 30:{}
			CASE 31:mySX.DIRECTORY.SEARCH2 =  fnStripCharsRight(mySX.DIRECTORY.SEARCH2,1)
			CASE 32:{
				mySX.DIRECTORY.SEARCH1 = mySX.DIRECTORY.SEARCH2
				mySX.DIRECTORY.PAGENO = 1
				fnLoadDirectory()
			}
			CASE 33:mySX.DIRECTORY.SEARCH2 =  mySX.DIRECTORY.SEARCH1
			DEFAULT:mySX.DIRECTORY.SEARCH2 = "mySX.DIRECTORY.SEARCH2,DialKB[1][GET_LAST(btnDirSearchKB)]"
		}
		fnDisplaySearchStrings()
	}
	HOLD[3]:{
		SWITCH(GET_LAST(btnDirSearchKB)){
			CASE 31:mySX.DIRECTORY.SEARCH2 =  ''
		}
		fnDisplaySearchStrings()
	}
}
DEFINE_FUNCTION fnDisplaySearchStrings(){
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar1),',0,',mySX.DIRECTORY.SEARCH1"
	SEND_COMMAND tp,"'^TXT-',ITOA(btnDirSearchBar2),',0,',mySX.DIRECTORY.SEARCH2"
}

/******************************************************************************
	Interface Feedback
******************************************************************************/
DEFINE_PROGRAM {
	// Local Variable
	STACK_VAR INTEGER b;
	// Directory Entry Feedback
	FOR(b = 1; b <= mySX.DIRECTORY.PAGESIZE; b++){
		SELECT{
			ACTIVE(mySX.DIRECTORY.SELECTED_RECORD == b):SEND_LEVEL tp,btnDirRecords[b],4
			ACTIVE(mySX.DIRECTORY.RECORDS[b].FOLDER):SEND_LEVEL tp,btnDirRecords[b],2
			ACTIVE(LENGTH_ARRAY(mySX.DIRECTORY.RECORDS[b].RefID)):SEND_LEVEL tp,btnDirRecords[b],3
			ACTIVE(1):SEND_LEVEL tp,btnDirRecords[b],1
		}
	}
	// Directory Methods Feedback
	FOR(b = 1; b <= LENGTH_ARRAY(btnDirMethods); b++){
		[tp,btnDirMethods[b]] = (mySX.DIRECTORY.SELECTED_METHOD == b)
	}
	// Directory Control Feedback
	[tp,btnDirLoading] = (mySX.DIRECTORY.STATE != DIR_STATE_IDLE)
	SEND_LEVEL tp,lvlDIR_ScrollBar,mySX.DIRECTORY.PAGENO
	[tp,btnDirType[1]] = (!mySX.DIRECTORY.CORPORATE)
	[tp,btnDirType[2]] = ( mySX.DIRECTORY.CORPORATE)
	[tp,btnDirType[3]] = ( mySX.DIRECTORY.CORPORATE)

	// Selfview Feedback
	[tp,btnSelfViewMode]   = (mySX.SELF_VIEW_FULL)
	[tp,btnSelfViewToggle] = (mySX.SELF_VIEW)

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
	GUI - Button Events - Remote Control Emulation
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnRemote]{
	PUSH:{
		STACK_VAR CHAR cButtonCmd[20]
		SWITCH(GET_LAST(btnRemote)){
			CASE 10:cButtonCmd = '0' 				//	Zero
			CASE 11:cButtonCmd = 'star' 			//	Asterix
			CASE 12:cButtonCmd = 'square' 		//	Hash
			CASE 14:cButtonCmd = 'preset'			//	Preset
			CASE 15:cButtonCmd = 'camera'			//	Camera
			CASE 19:cButtonCmd = 'VolumeUp'		// Volume Up
			CASE 20:cButtonCmd = 'VolumeDown'	//	Volume Down
			CASE 21:cButtonCmd = 'MuteMic'		// Mic Mute
			CASE 26:cButtonCmd = 'PhoneBook'		//	phonebook
			CASE 27:cButtonCmd = 'Call' 			//	Call
			CASE 28:cButtonCmd = 'Presentation' // Presentation source
			CASE 29:cButtonCmd = 'C' 	      	//	Delete
			CASE 30:cButtonCmd = 'Home' 			//	home
			CASE 31:cButtonCmd = 'Disconnect' 	//	hangup
			CASE 32:cButtonCmd = 'ZoomIn'			// Zoom In
			CASE 33:cButtonCmd = 'ZoomOut'		// Zoom Out
			CASE 35:cButtonCmd = 'Layout'			//	Layout/PIP/SelfView
			CASE 36:cButtonCmd = 'Up'				//	Up
			CASE 37:cButtonCmd = 'Down' 			//	Down
			CASE 38:cButtonCmd = 'Left' 			//	Left
			CASE 39:cButtonCmd = 'Right'			//	Right
			CASE 40:cButtonCmd = 'Ok' 		//	Enter
			CASE 41:cButtonCmd = 'F1' 				// Function Key 1
			CASE 42:cButtonCmd = 'F2' 				// Function Key 2
			CASE 43:cButtonCmd = 'F3' 				// Function Key 3
			CASE 44:cButtonCmd = 'F4' 				// Function Key 4
			CASE 45:cButtonCmd = 'F5' 				// Function Key 5
			DEFAULT:{
				// Buttons 3001-3009
				cButtonCmd = ITOA(GET_LAST(btnRemote))	// Digits 1-9
			}
		}
		fnQueueTx('xCommand Key',"'Click Key:',cButtonCmd")
	}
	HOLD[2,REPEAT]:{
		STACK_VAR CHAR cButtonCmd[20];
		SWITCH(GET_LAST(btnRemote)-3000){
			CASE 19:cButtonCmd = 'VolumeUp'		// Volume Up
			CASE 20:cButtonCmd = 'VolumeDown'	//	Volume Down
			CASE 32:cButtonCmd = 'ZoomIn'			// Zoom In
			CASE 33:cButtonCmd = 'ZoomOut'		// Zoom Out
			CASE 36:cButtonCmd = 'Up'				//	Up
			CASE 37:cButtonCmd = 'Down' 			//	Down
			CASE 38:cButtonCmd = 'Left' 			//	Left
			CASE 39:cButtonCmd = 'Right'			//	Right
		}
		IF(LENGTH_ARRAY(cButtonCmd)){
			fnQueueTx('xCommand Key',"'Click Key:',cButtonCmd")
		}
	}
}

DEFINE_PROGRAM{
	[tp,btnMicMute] 			= (mySX.MIC_MUTE)
	[tp,btnPresenterTrack] 	= (mySX.PRESENTERTRACK.TRACKING)
	[tp,btnSpeakerTrack] 	= (mySX.SpeakerTracking)
}
/******************************************************************************
	Custom Dial Commands
	These buttons initiate dialing through a custom method
	They should not be altered, but can be added to as required
	They are created as client requirements appear
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT [tp,btnCustomDial]{
	PUSH:{
		SWITCH(GET_LAST(btnCustomDial)){
			CASE 1:SEND_COMMAND vdvControl, "'DIAL-CUSTOM,VIDEO,H323,#CURRENT'"		// IP
			CASE 2:SEND_COMMAND vdvControl, "'DIAL-CUSTOM,VIDEO,H320,#CURRENT'"		// ISDN FULL or AUTO
			CASE 3:SEND_COMMAND vdvControl, "'DIAL-CUSTOM,VIDEO,H320,128,#CURRENT'"	// ISDN 2CHN or 128
			CASE 4:SEND_COMMAND vdvControl, "'DIAL-CUSTOM,AUDIO,H320,#CURRENT'"		// ISDN AUDIO ONLY
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/