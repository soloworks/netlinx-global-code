MODULE_NAME='mCiscoSX'(DEV vdvControl[], DEV vdvCalls[], DEV tp[], DEV dvVC)
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
INTEGER MAX_CALLS	       =  5
INTEGER MAX_PRESETS      = 15
INTEGER MAX_CAMERAS      =  7
INTEGER MAX_PERIPHERAL   = 10
INTEGER MAX_RECENT_CALLS = 15

DEFINE_TYPE STRUCTURE uPeripheral{
	INTEGER INDEX
	CHAR    ID[30]
	CHAR    SoftwareInfo[30]
	CHAR    Hardwareinfo[30]
	CHAR    LastSeen[30]
	CHAR    Name[30]
	CHAR    NetworkAddress[30]
	CHAR    SerialNumber[30]
	CHAR    Type[30]
	INTEGER StatusOnline
}

DEFINE_TYPE STRUCTURE uPeripherals{
	// Peripherals List
	INTEGER     LoadingOnline
	INTEGER     LoadingOffline
	uPeripheral Device[MAX_PERIPHERAL]
}

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

DEFINE_TYPE STRUCTURE uRecentCall{
	CHAR    LastOccurenceStartTime[20]
	CHAR    OccurenceType[20]
	INTEGER OccurenceCount
	CHAR    CallbackNumber[100]
	CHAR    DisplayName[100]
	CHAR    Direction[20]
}

DEFINE_TYPE STRUCTURE uDirEntry{
	INTEGER  INDEX		// API Index for reference as we pull out records
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

DEFINE_TYPE STRUCTURE uExtSource{
	INTEGER  CONNECTOR_ID
	CHAR     NAME[40]
	CHAR     IDENTIFIER[40]
	CHAR     TYPE[15]
	INTEGER  SIGNAL
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
	INTEGER    STATE					// Flag to show Directory is Processing
	INTEGER	  IGNORE_TOTALROWS	// TotalRows value is not garanteed
	INTEGER	  NO_MORE_ENTRIES	// Expected a directory entry, didn't find one, so end of directory reached
	INTEGER    CORPORATE			// If true use Corporate Directory
	CHAR		  SEARCH1[20]			// Current Search String Restriction
	CHAR		  SEARCH2[20]			// Current Search String Being Edited
	INTEGER    dragBarActive		// Side Drag Bar is currently being interacted with
	INTEGER	  PAGENO				// Current Page Number
	INTEGER	  PAGESIZE				// Interface Page Size
	INTEGER	  SELECTED_RECORD
	INTEGER	  SELECTED_METHOD
	INTEGER	  RECORDCOUNT
	uDirEntry  RECORDS[20]			// Directory Size
	uDirEntry  TRAIL[8]				// Breadcrumb Trail
	CHAR		  PREFERED_METHOD[10]	// Prefered protocol from Dircetory list (optional)
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
	INTEGER  POWER

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
	CHAR 	  	Tx[5000]
	CHAR 		Username[25]
	CHAR		Password[25]
	CHAR		BAUD[10]
	CHAR 		IP_HOST[15]
	INTEGER 	IP_PORT
	// Call State
	uCall		   ACTIVE_CALLS[MAX_CALLS]
	uRecentCall RecentCalls[MAX_RECENT_CALLS]
	INTEGER     RecentCallsLoading
	INTEGER     RecentCallSelected
	// Directory
	uDir		DIRECTORY
	// Touch10
	uExtSource   ExtSources[8]
	INTEGER      ExtSourceHide
	uPeripherals PERIPHERALS
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
INTEGER btnDirRecords[] = {
	11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
}
INTEGER btnRecentCalls[] = {
	31,32,33,34,35,36,37,38,39,40,41,42,43,44,45
}
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
(**   Microphone Mute               **)
INTEGER btnMicMute      = 201
(**   SelfView Fullscreen Toggle    **)
INTEGER btnSelfViewMode   = 202
(**   SelfView Toggle               **)
INTEGER btnSelfViewPos[]= {203,204}
(**   Toggle Tracking Mode          **)
INTEGER btnSpeakerTrack      = 205
INTEGER btnPresenterTrack   = 206
(**   SelfView Toggle               **)
INTEGER btnSelfViewToggle  = 209
(**   Hang Up Calls                 **)
INTEGER btnHangup[] = {
   210,211,212,213,214,215   // ALL | Call 1..5
}
(**   Answer Calls                  **)
INTEGER btnAnswer[] = {
   220,221,222,223,224,225   // ALL | Call 1..5
}
(**   Reject Calls                  **)
INTEGER btnReject[] = {
   230,231,232,233,234,235   // ALL | Call 1..5
}
INTEGER btnLayoutLocal[] = {
   241,242,243,244,245
}

(**   Dialing Interface   **)
INTEGER btnDialString    = 250                  // Address for DialString
INTEGER btnDialKB[] = {
   251,252,253,254,255,256,257,258,259,260,   // Row One
   261,262,263,264,265,266,267,268,269,      // Row Two
   270,271,272,273,274,275,276,               // Row Three
   277,   // SPACE
   278,   // SHIFT
   279,   // CAPS
   280,   // NUMLOCK
   281,   // DELETE
   282,   // DIAL
   283,   // NUMLOCK ON
   284    // NUMLOCK OFF
}
INTEGER btnDialSpecial[]={
   290,291,292,293,294,295
}
INTEGER btnPresets[] = {
   301,302,303,304,305,306,307,308,309,310,
   311,312,313,314,315,316,317,318,319,320,
   321,322,323,324,325,326,327,328,329,330
}

(**   Send DTMF Tones   **)
(**   340..349 | 0..9   **)
(**   350      | *      **)
(**   351      | #      **)
(**                     **)
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

INTEGER btnDirMethods[] = {
	641,642,643
}

INTEGER btnDirControl[] = {
	651,652,653,654	// PREV|NEXT|RESET|CLEARSEARCH
}
INTEGER btnDirDial	 		= 655
INTEGER btnRecentCallDial	= 656

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
	693,	// CANCEL
	694,695,696,697,698,699,700,701,702,703	// Row 4 (Digits)
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

INTEGER API_TC7	= 1
INTEGER API_CE8	= 2
INTEGER API_CE9	= 3

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
CHAR DialSpecial[6][255] = {
	{'.'},
	{'.com'},
	{'@'},
	{'.webex.com'}
}
CHAR DialSpecial_Alt[6][4]	// Characters after holding DialSpecial for 1sec

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

DEFINE_FUNCTION fnQueueTx(CHAR pCommand[1000], CHAR pParam[1000]){
	fnDebug(DEBUG_DEVELOP,'fnQueueTX',"'[',ITOA(LENGTH_ARRAY(mySX.Tx)),']',pCommand,' ', pParam,$0D")
	mySX.Tx = "mySX.Tx,pCommand,' ', pParam,$0D"
	fnSendTx()
	fnInitPoll()
}

DEFINE_FUNCTION fnSendTx(){
	IF((!mySX.isIP || mySX.CONN_STATE == CONN_CONNECTED) && !mySX.PEND){
		IF(FIND_STRING(mySX.Tx,"$0D",1)){
			STACK_VAR CHAR toSend[1000]
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
			SEND_STRING 0:0:0, "ITOA(vdvControl[1].Number),':',fnPadLeadingChars(Msg,' ',12), ' |', msg_ascii"
		}
		ELSE{
			SEND_STRING 0:0:0, "ITOA(vdvControl[1].Number),':',fnPadLeadingChars(Msg,' ',12), ' |', MsgData"
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
	STACK_VAR CHAR pParams[500]
	fnQueueTx('xStatus','SystemUnit Uptime')
	fnQueueTx('xStatus','SystemUnit Hardware Temperature')
	// Heartbeat AMX as addition to SX
	pParams = 'HeartBeat'
	pParams = "pParams,' ID: "',fnHexToString(GET_UNIQUE_ID()),'"'"
	fnQueueTx('xCommand Peripherals',pParams)
}
DEFINE_FUNCTION fnInitData(){
	STACK_VAR CHAR pParams[500]
	// Populate System Variables
	STACK_VAR DEV_INFO_STRUCT sDeviceInfo
	STACK_VAR IP_ADDRESS_STRUCT sNetworkInfo

	// Turn off Echo
	fnQueueTx('echo','off')

	// Register AMX as addition to SX
	DEVICE_INFO(DATA.DEVICE, sDeviceInfo)
	GET_IP_ADDRESS(0:1:0,sNetworkInfo)
	pParams = 'Connect'
	pParams = "pParams,' ID: "',fnHexToString(GET_UNIQUE_ID()),'"'"
	pParams = "pParams,' Name: "AMX Control System"'"
	pParams = "pParams,' NetworkAddress: "',sNetworkInfo.IPADDRESS,'"'"
	pParams = "pParams,' SerialNumber: "',fnRemoveNonPrintableChars(sDeviceInfo.SERIAL_NUMBER),'"'"
	pParams = "pParams,' SoftwareInfo: "',sDeviceInfo.VERSION,'"'"
	pParams = "pParams,' HardwareInfo: "',sDeviceInfo.DEVICE_ID_STRING,'"'"
	pParams = "pParams,' Type: ControlSystem'"
	fnQueueTx('xCommand Peripherals',pParams)

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
	fnQueueTx('xFeedback register','/Status/Peripherals')

	fnQueueTx('xConfiguration','Peripherals Profile Touchpanels: 0')

	fnQueueTx('xStatus','Audio')
	fnQueueTx('xStatus','Call')
	fnQueueTx('xStatus','Video Input')
	fnQueueTx('xStatus','Video Selfview')
	fnQueueTx('xStatus','Conference')
	fnQueueTx('xStatus','Network')
	fnQueueTx('xStatus','Standby')
	fnQueueTx('xStatus','SystemUnit')


	fnQueueTx('xCommand UserInterface Presentation ExternalSource','RemoveAll')
	// Init GUI bits if required
	IF(mySX.ExtSources[1].IDENTIFIER != ''){
		STACK_VAR INTEGER s
		FOR(s = 1; s <= 8; s++){
			IF(mySX.ExtSources[s].IDENTIFIER != ''){
				pParams = 'Add'
				pParams = "pParams,' ConnectorId: ',ITOA(mySX.ExtSources[s].CONNECTOR_ID)"
				pParams = "pParams,' SourceIdentifier: "',mySX.ExtSources[s].IDENTIFIER,'"'"
				pParams = "pParams,' Name: "',mySX.ExtSources[s].NAME,'"'"
				pParams = "pParams,' Type: ',mySX.ExtSources[s].TYPE"
				fnQueueTx('xCommand UserInterface Presentation ExternalSource',pParams)
			}
		}
		fnSetExtSourceSignals(0)
	}

	// Query and process connected peripherals
	fnClearPeripherals()
	fnQueueTx('xCommand peripherals list','Connected: True')

	// Get latest Recent Calls list
	fnQueueTx('xCommand CallHistory Recents',"'Limit: ',ITOA(MAX_RECENT_CALLS),' DetailLevel: Full'")

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
	SEND_STRING vdvControl[1], 'ACTION-REBOOTING'
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
				STACK_VAR INTEGER x
				FOR(x = 1; x <= mySX.DIRECTORY.PAGESIZE; x++){
					IF(mySX.DIRECTORY.RECORDS[x].INDEX == 0){
						BREAK
					}
				}
				IF(x < mySX.DIRECTORY.PAGESIZE){
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
		// Peripherals
		IF(mySX.Peripherals.LoadingOnline){
			mySX.Peripherals.LoadingOnline = FALSE
			mySX.Peripherals.LoadingOffline = TRUE
			fnQueueTx('xCommand peripherals list','Connected: False')
		}
		//
		ELSE IF(mySX.Peripherals.LoadingOffline){
			mySX.Peripherals.LoadingOffline = FALSE
			fnSendPeripheralsData()
		}
		// Recent Calls
		IF(mySX.RecentCallsLoading){
			mySX.RecentCallsLoading = FALSE
			fnDisplayRecentCalls(0)
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
					// Recent Call List
					CASE 'CallHistoryRecentsResult':{
						STACK_VAR INTEGER x
						// Clear existing history if loading starting
						IF(!mySX.RecentCallsLoading){
							FOR(x = 1; x <= MAX_RECENT_CALLS; x++){
								STACK_VAR uRecentCall blankRecentCall
								mySX.RecentCalls[x] = blankRecentCall
							}
						}
						// Set Loading Variable
						mySX.RecentCallsLoading = TRUE
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'Entry':{
								// Get Entry Number
								x = ATOI(REMOVE_STRING(pDATA,' ',1))+1
								// Get the Data
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),2)){
									CASE 'LastOccurrenceStartTime': mySX.RecentCalls[x].LastOccurenceStartTime = fnRemoveQuotes(pDATA)
									CASE 'OccurrenceType':          mySX.RecentCalls[x].OccurenceType          = fnRemoveQuotes(pDATA)
									CASE 'CallbackNumber':          mySX.RecentCalls[x].CallbackNumber         = fnRemoveQuotes(pDATA)
									CASE 'DisplayName':             mySX.RecentCalls[x].DisplayName            = fnRemoveQuotes(pDATA)
									CASE 'Direction':               mySX.RecentCalls[x].Direction              = fnRemoveQuotes(pDATA)
									CASE 'OccurrenceCount':         mySX.RecentCalls[x].OccurenceCount         = ATOI(pDATA)
								}
							}
						}
					}
					CASE 'PeripheralsListResult':{
						// Set status for incoming list
						IF(FIND_STRING(pDATA,'(status=OK)',1)){
							IF(!mySX.Peripherals.LoadingOnline && !mySX.Peripherals.LoadingOffline){
								mySX.Peripherals.LoadingOnline = TRUE
							}
						}
						ELSE{
							STACK_VAR INTEGER ID
							STACK_VAR INTEGER x
							REMOVE_STRING(pDATA,' ',1)					// Remove Device
							fnStorePeripheralField(pDATA)
						}
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
								}
								CASE 'Folder':{
									STACK_VAR INTEGER x
									x = fnGetDirSlot(TRUE,ATOI(REMOVE_STRING(pDATA,' ',1)))
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
										CASE 'Name:':{
											mySX.DIRECTORY.RECORDS[x].NAME  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'FolderId:':{
											mySX.DIRECTORY.RECORDS[x].FOLDER = TRUE
											mySX.DIRECTORY.RECORDS[x].RefID  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
									}
								}
								CASE 'Contact':{
									STACK_VAR INTEGER x
									x = fnGetDirSlot(FALSE,ATOI(REMOVE_STRING(pDATA,' ',1)))
									SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
										CASE 'Name:':{
											mySX.DIRECTORY.RECORDS[x].NAME  = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'ContactId:':{
											mySX.DIRECTORY.RECORDS[x].RefID = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
										}
										CASE 'ContactMethod':{
											STACK_VAR INTEGER y
											y = ATOI(REMOVE_STRING(pDATA,' ',1))
											SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
												CASE 'Number:':{
													pDATA = fnRemoveQuotes(fnRemoveWhiteSpace(pDATA))
													mySX.DIRECTORY.RECORDS[x].METHOD_NUMBER[y] = pDATA
												}
												CASE 'Protocol:':{
													mySX.DIRECTORY.RECORDS[x].METHOD_PROTOCOL[y] = pDATA
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
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
							CASE 'CallId':{
								fnRegisterCall(ATOI(pDATA))
								fnQueueTx('xStatus Call',pDATA)
							}
							CASE 'RemoteURI':{}
							CASE 'DisplayNameValue':{}
						}
					}
					CASE 'CallSuccessful':{
						REMOVE_STRING(pDATA,'CallId:',1)
						fnQueueTx('xStatus Call',REMOVE_STRING(pDATA,' ',1))
					}
					CASE 'CallDisconnect':{
						// Variable to hold this call ID once found
						STACK_VAR INTEGER pCallID
						SWITCH(mySX.API_VER){
							CASE API_TC7:{
								REMOVE_STRING(pDATA,'CallId: ',1)
								pCallID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
							}
							CASE API_CE8:
							CASE API_CE9:{
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
											CASE 'PageOpened PageId':  pEVENT = 'INTERFACE_API-PAGE_OPENED,'
											CASE 'PageClosed PageId':  pEVENT = 'INTERFACE_API-PAGE_CLOSED,'
											CASE 'Pressed Signal':     pEVENT = 'INTERFACE_API-PRESS,'
											CASE 'Clicked Signal':     pEVENT = 'INTERFACE_API-CLICK,'
											CASE 'Released Signal':    pEVENT = 'INTERFACE_API-RELEASE,'
											CASE 'Changed Signal':     pEVENT = 'INTERFACE_API-CHANGED,'
										}

										pData = fnRemoveWhiteSpace(pData)
										pDATA = fnRemoveQuotes(pData)
										IF(FIND_STRING(pDATA,':',1)){
											pEVENT = "pEVENT,fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1),',',pDATA"
										}
										ELSE{
											pEVENT = "pEVENT,pDATA,',NONE'"
										}
										SEND_STRING vdvControl[1],pEVENT
									}
									CASE 'Panel':{
										SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
											CASE 'Clicked':{
												SWITCH(REMOVE_STRING(pDATA,':',1)){
													CASE 'PanelId:':{
														STACK_VAR CHAR pEVENT[100]
														pEVENT = 'INTERFACE_PANEL-CLICK,'
														pEVENT = "pEvent,fnRemoveQuotes(fnRemoveWhiteSpace(pData))"
														SEND_STRING vdvControl[1],pEVENT
													}
												}
											}
										}
									}
								}
							}
							CASE 'Presentation':{
								SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
									CASE 'ExternalSource':{
										SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
											CASE 'Selected':{
												REMOVE_STRING(pDATA,'SourceIdentifier: "',1)
												SEND_STRING vdvControl[1],"'INTERFACE_API-EXTSOURCE,',fnStripCharsRight(pDATA,1)"
											}
										}
									}
								}
							}
						}
					}
				}
			}
			CASE '*s':{	// Status Response
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
					CASE 'Standby':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'State:':{
								SWITCH(fnRemoveWhiteSpace(pDATA)){
									CASE 'Standby': mySX.POWER = FALSE
									CASE 'Off':     mySX.POWER = TRUE
								}
							}
						}
					}
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
										STACK_VAR INTEGER x
										STACK_VAR INTEGER pCONNECTOR
										STACK_VAR INTEGER pCAMERA
										pCONNECTOR = ATOI(pDATA)
										fnDebug(DEBUG_DEVELOP,'FB Input',"'pCONNECTOR = ',ITOA(pCONNECTOR)")
										FOR (x=1; x<=MAX_CAMERAS; x++){
											IF(mySX.CAMERA[x].CONNECTOR_OVERRIDE){
												IF(mySX.CAMERA[x].CONNECTOR_OVERRIDE == pCONNECTOR){
													pCAMERA = x
													BREAK
												}
											}
											ELSE{
												pCAMERA = pCONNECTOR
											}
										}
										fnDebug(DEBUG_DEVELOP,'FB Input',"'pCAMERA = ',ITOA(pCAMERA)")
										IF(mySX.NEAR_CAMERA != pCAMERA && !mySX.NEAR_CAMERA_LOCKED && mySX.NEAR_CAMERA){
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Pan:Stop'")
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Tilt:Stop'")
											fnQueueTx('xCommand Camera',"'Ramp CameraId:',ITOA(mySX.NEAR_CAMERA),' Zoom:Stop'")
											mySX.NEAR_CAMERA = pCAMERA
											SEND_STRING vdvControl[1],"'CAMERA-CONTROL,',ITOA(mySX.NEAR_CAMERA)"
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
												CASE API_TC7:	fnQueueTx('xCommand Preset',"'Activate PresetId: ', ITOA(1)")
												CASE API_CE8:
												CASE API_CE9:{
													fnQueueTx('xCommand Camera Preset',"'Activate PresetId: ', ITOA(1)")
												}
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
									CASE 'TC':mySX.API_VER = API_TC7
									CASE 'CE':{
										SWITCH(UPPER_STRING(MID_STRING(mySX.META_SW_VER,3,1))){
											CASE '8':mySX.API_VER = API_CE8
											CASE '9':mySX.API_VER = API_CE9
										}
									}
								}
								SWITCH(mySX.API_VER){
									CASE API_TC7:{
										fnQueueTx('xStatus','Camera')
										fnQueueTx('xStatus','Preset')
									}
									CASE API_CE8:
									CASE API_CE9:{
										fnQueueTx('xStatus','Cameras')
										fnQueueTx('xCommand','Camera Preset List')
									}
								}
								SEND_STRING vdvControl[1], "'PROPERTY-META,SOFTWARE,',mySX.META_SW_VER"
							}
							CASE 'ProductPlatform':{
								mySX.META_MODEL   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl[1], "'PROPERTY-META,TYPE,VideoConferencer'"
								SEND_STRING vdvControl[1], "'PROPERTY-META,MAKE,Cisco'"
								SEND_STRING vdvControl[1], "'PROPERTY-META,MODEL,',mySX.META_MODEL"
							}
							CASE 'Hardware Module SerialNumber':{
								mySX.META_SN   = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl[1], "'PROPERTY-META,SN,',mySX.META_SN"
							}
							CASE 'Software Application':{
								mySX.META_SW_APP = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl[1], "'PROPERTY-META,APPLICATION,',mySX.META_SW_APP"
							}
							CASE 'Software ReleaseDate':{
								mySX.META_SW_RELEASE = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl[1], "'PROPERTY-META,RELEASE,',mySX.META_SW_VER"
							}
							CASE 'ContactInfo':{
								mySX.META_SYS_NAME = fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) )
								SEND_STRING vdvControl[1], "'PROPERTY-META,DESC,',mySX.META_SYS_NAME"
							}
							CASE 'Hardware TemperatureThreshold':{
								IF(mySX.SYS_MAX_TEMP != ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_MAX_TEMP = ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))
									SEND_STRING vdvControl[1], "'PROPERTY-META,MAX_TEMP,',ITOA(mySX.SYS_MAX_TEMP)"
								}
							}
							CASE 'Hardware Temperature':{
								IF(mySX.SYS_TEMP != ATOF(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_TEMP = ATOF(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))
									SEND_STRING vdvControl[1], "'PROPERTY-STATE,TEMP,',FTOA(mySX.SYS_TEMP)"
								}
								IF(mySX.META_SN == ''){ fnInitData() }
							}
							CASE 'Uptime':{
								IF(mySX.SYS_UPTIME != ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ))){
									mySX.SYS_UPTIME = ATOI(fnRemoveQuotes( fnRemoveWhiteSpace( pDATA ) ) )
									SEND_STRING vdvControl[1], "'PROPERTY-STATE,UPTIME,',ITOA(mySX.SYS_UPTIME)"
								}
							}
						}
					}
					CASE 'Peripherals':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
							CASE 'ConnectedDevice':{
								fnStorePeripheralField(pDATA)
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
	[vdvControl[1],236] = CALL_RINGING
	[vdvControl[1],237] = CALL_DIALLING
	[vdvControl[1],238] = CALL_CONNECTED

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
DEFINE_EVENT CHANNEL_EVENT[vdvControl[1],238]{
	OFF:{
		// Get latest Recent Calls list
		fnQueueTx('xCommand CallHistory Recents',"'Limit: ',ITOA(MAX_RECENT_CALLS),' DetailLevel: Full'")
	}
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
		CASE API_TC7: fnQueueTx('xCommand',"'Preset Activate PresetId: ', ITOA(pPresetID)")
		CASE API_CE8:
		CASE API_CE9:{
			fnQueueTx('xCommand',"'Camera Preset',' Activate PresetId: ', ITOA(pPresetID)")
		}
	}
	// Set Video (Cisco removed this from presets around 8.2.2 and it's caused many issues)
	SWITCH(mySX.API_VER){
		CASE API_CE8:
		CASE API_CE9:{
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
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl[1]]{
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
								CASE API_TC7:fnQueueTx('xCommand Call','DisconnectAll')
								CASE API_CE8:
								CASE API_CE9:{
									fnQueueTx('xCommand Call','Disconnect')
								}
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
								DEFAULT:    mySX.DEBUG = DEBUG_ERROR
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
							IF(mySX.isIP){fnReTryTCPConnection()}
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
						CASE API_TC7:PRESET_STRING = 'Preset'
						CASE API_CE8:
						CASE API_CE9:{
							PRESET_STRING = 'Camera Preset'
						}
					}
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'RECALL':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'NEAR':{
									fnRecallPreset(ATOI(DATA.TEXT))
								}
								CASE 'FAR':{
									SWITCH(mySX.API_VER){
										CASE API_TC7: fnQueueTx('xCommand FarEndControl',"'Preset Activate PresetId: ', DATA.TEXT")
										CASE API_CE8:
										CASE API_CE9:{
											fnQueueTx('xCommand FarEndControl',"'Camera Preset',' Activate PresetId: ', DATA.TEXT")
										}
									}
								}
							}
						}
						CASE 'STORE':{
							SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
								CASE 'NEAR':{
									SWITCH(mySX.API_VER){
										CASE API_CE8:
										CASE API_CE9:{
											// Not finished, and probably never used
											fnQueueTx('xCommand','Preset Store')
											fnQueueTx('xCommand','Camera Preset List')
										}
										CASE API_TC7:{
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
						CASE 'START': fnQueueTx('xCommand Presentation','Start'); mySX.ContentTx = TRUE;
						CASE 'STOP':
						CASE '0':     fnQueueTx('xCommand Presentation','Stop');  mySX.ContentTx = FALSE;
						DEFAULT:		  fnQueueTx('xCommand Presentation',"'Start PresentationSource: ',DATA.TEXT");	  mySX.ContentTx = TRUE;
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
						CASE API_TC7:fnQueueTx('xCommand DTMFSend',"'DTMFString:',DATA.TEXT")
						CASE API_CE8:
						CASE API_CE9:fnQueueTx('xCommand Call DTMFSend',"'DTMFString:',DATA.TEXT")
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
						STACK_VAR INTEGER ConnectorID
						ConnectorID = ATOI(DATA.TEXT)
						//fnQueueTx('xCommand Video Input',"'SetMainVideoSource ConnectorId: ',ITOA(ConnectorID)")
						IF(mySX.CAMERA[ConnectorID].CONNECTOR_OVERRIDE){
							fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[ConnectorID].CONNECTOR_OVERRIDE)")
						}
						ELSE{
							fnQueueTx("'xCommand Video Input'","' SetMainVideoSource ConnectorId: ', ITOA(mySX.CAMERA[ConnectorID].CONNECTOR)")
						}
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
					STACK_VAR CHAR pWIDGET[32]
					STACK_VAR CHAR pVALUE[32]
					STACK_VAR CHAR pTITLE[32]
					STACK_VAR CHAR pBODY[255]
					STACK_VAR CHAR pTIME[4]
					SWITCH(fnGetCSV(DATA.TEXT,1)){
						CASE 'SET':{
							pWIDGET = fnGetCSV(DATA.TEXT,2)
							pVALUE  = fnGetCSV(DATA.TEXT,3)
							fnDebug(DEBUG_DEVELOP,'Cisco Rx INTERFACE_API-',"'SET,',pWIDGET,',',pVALUE")
							SWITCH(pVALUE){
								CASE '':
								CASE 'none':
								CASE 'None':
								CASE 'NONE': fnQueueTx("'xCommand UserInterface Extensions Widget UnsetValue'","'WidgetId: "',pWIDGET,'"'")
								DEFAULT:	    fnQueueTx("'xCommand UserInterface Extensions Widget SetValue'","'Value: "',pVALUE,'" WidgetId: "',pWIDGET,'"'")
							}
						}
						CASE 'MESSAGE':{
							pTITLE  = fnGetCSV(DATA.TEXT,2)
							pBODY   = fnGetCSV(DATA.TEXT,3)
							pTIME   = fnGetCSV(DATA.TEXT,4)
							fnDebug(DEBUG_DEVELOP,'Cisco Rx INTERFACE_API-',"'MESSAGE,',pTITLE,',',pBODY,',',pTIME")
							fnQueueTx("'xCommand UserInterface Message Alert Display'",
							"'Title: "',pTITLE,'" Text: "',pBODY,'" Duration: ',pTIME")
						}
						CASE 'EXTSOURCE':{
							IF(fnGetCSV(DATA.TEXT,2) == 'HIDE'){
								mySX.ExtSourceHide = TRUE
							}
							ELSE{
								STACK_VAR INTEGER x
								FOR(x = 1; x <= 8; x++){
									IF(mySX.ExtSources[x].IDENTIFIER == ''){
										mySX.ExtSources[x].CONNECTOR_ID = ATOI(fnGetCSV(DATA.TEXT,2))
										mySX.ExtSources[x].IDENTIFIER = fnGetCSV(DATA.TEXT,3)
										mySX.ExtSources[x].NAME = fnGetCSV(DATA.TEXT,4)
										mySX.ExtSources[x].TYPE = fnGetCSV(DATA.TEXT,5)
										BREAK
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
		[vdvControl[1],198] = (mySX.MIC_MUTE)
		[vdvControl[1],199] = (mySX.VOL_MUTE)
		SEND_LEVEL vdvControl[1],1,mySX.VOL
		[vdvControl[1],241] = (mySX.ContentTx)
		[vdvControl[1],242] = (mySX.ContentRx)
		[vdvControl[1],247] = (mySX.PRESENTERTRACK.TRACKING && mySX.PRESENTERTRACK.ENABLED)
		[vdvControl[1],248] = (mySX.SpeakerTracking && mySX.hasSpeakerTrack)
		[vdvControl[1],249] = (mySX.hasSpeakerTrack)
		[vdvControl[1],250] = (mySX.PRESENTERTRACK.ENABLED)
		[vdvControl[1],251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl[1],252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl[1],255] = (mySX.POWER)
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
	fnDisplayRecentCalls(pPanel)
	fnClearDirectory()

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
	FOR(x = 1; x <= 10; x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDirSearchKB[33+x]),',0,',DialKB[3][x]"
	}
}

DEFINE_FUNCTION fnUpdatePanelDialString(INTEGER pPanel){
	IF(!pPanel){
		STACK_VAR INTEGER p; FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){ fnUpdatePanelDialString(p) }
		RETURN
	}
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnDialString),',0,',mySX.DIAL_STRING"
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnDialKB[32]),',',ITOA(LENGTH_ARRAY(mySX.DIAL_STRING) > 0)"
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
	IF(LENGTH_ARRAY(vdvCalls) >= pCALL){
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnHangup[pCALL+1]),',',ITOA([vdvCalls[pCALL],236] || [vdvCalls[pCALL],237] || [vdvCalls[pCALL],238])"
	}
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
DEFINE_FUNCTION fnDisplayRecentCalls(INTEGER pPanel){
	STACK_VAR INTEGER x
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnDisplayRecentCalls(p)
		}
		RETURN
	}
	FOR(x = 1; x <= MAX_RECENT_CALLS; x++){
		IF(mySX.RecentCalls[x].CallbackNumber != ''){
			IF(mySX.RecentCalls[x].DisplayName != ''){
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnRecentCalls[x]),',0,',mySX.RecentCalls[x].DisplayName"
			}
			ELSE{
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnRecentCalls[x]),',0,',mySX.RecentCalls[x].CallbackNumber"
			}
		}
		ELSE{
			BREAK
		}
	}
	IF(x = MAX_RECENT_CALLS+1){x = MAX_RECENT_CALLS-1}
	// Show all the calls that we have detail for
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnRecentCalls[1]),'.',ITOA(btnRecentCalls[x]),',1'"
	// Hide all the ones we don't, if there are any
	IF(x < MAX_RECENT_CALLS){
		SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnRecentCalls[x+1]),'.',ITOA(btnRecentCalls[LENGTH_ARRAY(btnRecentCalls)]),',0'"
	}
	// Deselect any calls and hide the call buttong
	mySX.RecentCallSelected = 0
	SEND_COMMAND tp,"'^SHO-',ITOA(btnRecentCallDial),',0'"
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
			CASE API_TC7:fnQueueTx('xCommand DTMFSend',"'DTMFString:',cButtonCmd")
			CASE API_CE8:
			CASE API_CE9:fnQueueTx('xCommand Call DTMFSend',"'DTMFString:',cButtonCmd")
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
			CASE API_TC7:	fnQueueTx('xCommand Preset',"'Store PresetId: ', ITOA(GET_LAST(btnPresets)),' Type:All Description:"Preset ',ITOA(GET_LAST(btnPresets)),'"'")
			CASE API_CE8:
			CASE API_CE9:fnQueueTx('xCommand Camera Preset',"'Store CameraId: ',ITOA(mySX.NEAR_CAMERA),' PresetID: ', ITOA(GET_LAST(btnPresets))")
		}
	}
	RELEASE:{
		SWITCH(mySX.API_VER){
			CASE API_TC7:	fnQueueTx('xCommand Preset',"'Activate PresetId: ', ITOA(GET_LAST(btnPresets))")
			CASE API_CE8:
			CASE API_CE9:	fnQueueTx('xCommand Camera Preset',"'Activate PresetId: ', ITOA(GET_LAST(btnPresets))")
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnHangup]{
	PUSH:{
		STACK_VAR INTEGER x
		SWITCH(GET_LAST(btnHangup)){
			CASE 1:{
				SWITCH(mySX.API_VER){
					CASE API_TC7:fnQueueTx('xCommand Call','DisconnectAll')
					CASE API_CE8:
					CASE API_CE9:fnQueueTx('xCommand Call','Disconnect')
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
				CASE API_TC7:{	// Flag if a preset is found
					IF(mySX.PRESET[b].DEFINED){
						y = TRUE
						SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnCamNearPreset[b]),',1'"
						SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnCamNearPreset[b]),',0,',mySX.PRESET[b].NAME"
					}
				}
				CASE API_CE8:
				CASE API_CE9:{
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
		TO[vdvControl[1],chnNearCam[GET_LAST(btnCamNearControl)]]
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl[1],chnNearCam]{
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
		TO[vdvControl[1],chnFarCam[GET_LAST(btnCamFarControl)]]
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl[1],chnFarCam]{
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
DEFINE_FUNCTION INTEGER fnGetDirSlot(INTEGER isFolder, INTEGER Index){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= mySX.DIRECTORY.PAGESIZE; x++){
		IF(isFolder == mySX.DIRECTORY.RECORDS[x].FOLDER && Index == mySX.DIRECTORY.RECORDS[x].INDEX){
			RETURN x
		}
		ELSE IF(mySX.DIRECTORY.RECORDS[x].INDEX == 0){
			mySX.DIRECTORY.RECORDS[x].FOLDER = isFolder
			mySX.DIRECTORY.RECORDS[x].INDEX = Index
			RETURN x
		}
	}
}
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
	// If there is a search string in play, use that
	SWITCH(mySX.API_VER){
		CASE API_CE9:{
			IF(!mySX.DIRECTORY.CORPORATE){
				toSend = "toSend, ' Recursive: False'"
			}
		}
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
			DEFAULT:{
				IF(GET_LAST(btnDirSearchKB) <= 26){
					mySX.DIRECTORY.SEARCH2 = "mySX.DIRECTORY.SEARCH2,DialKB[1][GET_LAST(btnDirSearchKB)]"
				}
				ELSE{
					mySX.DIRECTORY.SEARCH2 = "mySX.DIRECTORY.SEARCH2,DialKB[3][GET_LAST(btnDirSearchKB)-33]"
				}
			}
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
	Recent Call Interface
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tp,btnRecentCalls]{
	PUSH:{
		IF(mySX.RecentCallSelected == GET_LAST(btnRecentCalls)){
			mySX.RecentCallSelected = 0
		}ELSE{
			mySX.RecentCallSelected = GET_LAST(btnRecentCalls)
		}
		SEND_COMMAND tp,"'^SHO-',ITOA(btnRecentCallDial),',',ITOA(mySX.RecentCallSelected != 0)"
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnRecentCallDial]{
	PUSH:{
		fnQueueTx('xCommand Dial',"'Number: ',mySX.RecentCalls[mySx.RecentCallSelected].CallbackNumber")
	}
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

	// Recent Calls Feedback
	FOR(b = 1; b <= LENGTH_ARRAY(btnRecentCalls); b++){
		IF(mySX.RecentCallSelected == b){
			SEND_LEVEL tp,btnRecentCalls[b],4
		}
		ELSE{
			SWITCH(mySX.RecentCalls[b].Direction){
				CASE 'Outgoing':{
					SEND_LEVEL tp,btnRecentCalls[b],3
				}
				CASE 'Incoming':{
					SWITCH(mySX.RecentCalls[b].OccurenceType){
						CASE 'Missed':
						CASE 'Rejected':
						CASE 'UnacknowledgedMissed':SEND_LEVEL tp,btnRecentCalls[b],1
						DEFAULT:SEND_LEVEL tp,btnRecentCalls[b],2
					}
				}
			}
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
			CASE 1:SEND_COMMAND vdvControl[1], "'DIAL-CUSTOM,VIDEO,H323,#CURRENT'"		// IP
			CASE 2:SEND_COMMAND vdvControl[1], "'DIAL-CUSTOM,VIDEO,H320,#CURRENT'"		// ISDN FULL or AUTO
			CASE 3:SEND_COMMAND vdvControl[1], "'DIAL-CUSTOM,VIDEO,H320,128,#CURRENT'"	// ISDN 2CHN or 128
			CASE 4:SEND_COMMAND vdvControl[1], "'DIAL-CUSTOM,AUDIO,H320,#CURRENT'"		// ISDN AUDIO ONLY
		}
	}
}
/******************************************************************************
	External Source Control (Touch10)
******************************************************************************/
DEFINE_CONSTANT
INTEGER chnExtSourceSignal[] = {11,12,13,14,15,16,17,18,19,20}
DEFINE_EVENT CHANNEL_EVENT[vdvControl[1],chnExtSourceSignal]{
	ON:{
		mySX.ExtSources[GET_LAST(chnExtSourceSignal)].SIGNAL = TRUE
		fnSetExtSourceSignals(GET_LAST(chnExtSourceSignal))
	}
	OFF:{
		mySX.ExtSources[GET_LAST(chnExtSourceSignal)].SIGNAL = FALSE
		fnSetExtSourceSignals(GET_LAST(chnExtSourceSignal))
	}
}

DEFINE_FUNCTION fnSetExtSourceSignals(INTEGER src){

	STACK_VAR CHAR pParams[500]

	IF(!src){
		STACK_VAR INTEGER s
		FOR(s = 1; s <= 8; s++){
			fnSetExtSourceSignals(s)
		}
		RETURN
	}

	IF(mySX.ExtSources[src].IDENTIFIER != ''){
		pParams = 'Set'
		pParams = "pParams,' SourceIdentifier: "',mySX.ExtSources[src].IDENTIFIER,'"'"
		SWITCH(mySX.ExtSources[src].SIGNAL){
			CASE TRUE:  pParams = "pParams,' State: Ready'"
			CASE FALSE:{
				SWITCH(mySX.ExtSourceHide){
					CASE TRUE:  pParams = "pParams,' State: Hidden'"
					CASE FALSE: pParams = "pParams,' State: NotReady'"
				}
			}
		}
		fnQueueTx('xCommand UserInterface Presentation ExternalSource State',pParams)
	}
}
/******************************************************************************
	Peripheral Monitoring
******************************************************************************/
DEFINE_FUNCTION fnClearPeripherals(){
	STACK_VAR INTEGER p
	STACK_VAR uPeripheral blankPeripheral
	fnDebug(DEBUG_DEVELOP,'fnClearPeripherals','Called')
	FOR(p = 1; p <= MAX_PERIPHERAL; p++){
		mySX.Peripherals.Device[p] = blankPeripheral
	}
	fnDebug(DEBUG_DEVELOP,'fnClearPeripherals','Ended')
}

DEFINE_FUNCTION INTEGER fnGetPeripheralSlot(INTEGER pINDEX){
	STACK_VAR INTEGER p
	fnDebug(DEBUG_DEVELOP,'fnGetPeripheralSlot',"'pINDEX=',ITOA(pINDEX)")
	// Get slot if this already exists
	FOR(p = 1; p <= MAX_PERIPHERAL; p++){
		// This is the slot - return
		IF(mySX.Peripherals.Device[p].INDEX == pINDEX){
			RETURN p
		}
		// This slot is empty - allocate and return
		IF(mySX.Peripherals.Device[p].INDEX == 0){
			mySX.Peripherals.Device[p].INDEX = pINDEX
			RETURN p
		}
		// Check if this slot should be before the next one
		IF(p < MAX_PERIPHERAL && mySX.Peripherals.Device[p].INDEX > pINDEX){
			STACK_VAR INTEGER y
			STACK_VAR uPeripheral blankPeripheral
			// Move all up by one (last will be knocked off, so list will be accurate but missing more than MAX_PERIPHERALS)
			FOR(y = MAX_PERIPHERAL; y > p; y--){
				mySX.Peripherals.Device[y] = mySX.Peripherals.Device[y-1]
			}
			// Add this one in, wipe existing data as it has moved up
			mySX.Peripherals.Device[p] = blankPeripheral
			mySX.Peripherals.Device[p].INDEX = pINDEX
			RETURN p
		}
	}
	// If here then will return 0
	fnDebug(DEBUG_DEVELOP,'fnGetPeripheralSlot','Ended')
}

DEFINE_FUNCTION INTEGER fnStorePeripheralField(CHAR pDATA[]){
	STACK_VAR INTEGER p
	STACK_VAR INTEGER pIndex
	fnDebug(DEBUG_DEVELOP,'fnStorePeripheralField',"'pDATA=',pDATA")

	// Get this Index
	pINDEX = ATOI(REMOVE_STRING(pDATA,' ',1))
	p = fnGetPeripheralSlot(pIndex)

	// Set Status if this is a loading process
	IF(mySX.Peripherals.LoadingOnline){
		mySX.Peripherals.Device[p].StatusOnline = TRUE
	}

	// Set Status if this is a loading process
	IF(mySX.Peripherals.LoadingOffline){
		mySX.Peripherals.Device[p].StatusOnline = FALSE
	}

	IF(p){
		// Store Field
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),2)){
			CASE 'HardwareInfo':   mySX.Peripherals.Device[p].Hardwareinfo = fnRemoveQuotes(pDATA)
			CASE 'ID':             mySX.Peripherals.Device[p].ID = fnRemoveQuotes(pDATA)
			CASE 'Name':           mySX.Peripherals.Device[p].Name = fnRemoveQuotes(pDATA)
			CASE 'NetworkAddress': mySX.Peripherals.Device[p].NetworkAddress = fnRemoveQuotes(pDATA)
			CASE 'SerialNumber':   mySX.Peripherals.Device[p].SerialNumber = fnRemoveQuotes(pDATA)
			CASE 'SoftwareInfo':   mySX.Peripherals.Device[p].SoftwareInfo = fnRemoveQuotes(pDATA)
			CASE 'Type':           mySX.Peripherals.Device[p].Type = fnRemoveQuotes(pDATA)
			CASE 'LastSeen':       mySX.Peripherals.Device[p].LastSeen = fnRemoveQuotes(pDATA)
			CASE 'Status':{
				mySX.Peripherals.Device[p].StatusOnline = pDATA == 'Connected'
			}
		}
	}
	fnDebug(DEBUG_DEVELOP,'fnStorePeripheralField','Ended')
}

DEFINE_FUNCTION fnSendPeripheralsData(){
	STACK_VAR INTEGER d
	FOR(d = 1; d < LENGTH_ARRAY(vdvControl); d++){
		SEND_STRING vdvControl[d+1],"'PROPERTY-META,MAKE,CiscoPeripheral'"
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].Name)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,NAME,',mySX.PERIPHERALS.Device[d].Name"
		}
		ELSE{
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,NAME,NotDefined'"
		}
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].Hardwareinfo)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,MODEL,',mySX.PERIPHERALS.Device[d].Hardwareinfo"
		}
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].SoftwareInfo)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,SWVERSION,',mySX.PERIPHERALS.Device[d].SoftwareInfo"
		}
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].SerialNumber)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,SERIALNO,',mySX.PERIPHERALS.Device[d].SerialNumber"
		}
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].ID)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-META,PARTNO,',mySX.PERIPHERALS.Device[d].ID"
		}
		IF(LENGTH_ARRAY(mySX.PERIPHERALS.Device[d].NetworkAddress)){
			SEND_STRING vdvControl[d+1],"'PROPERTY-IP,',mySX.PERIPHERALS.Device[d].NetworkAddress"
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER d
	FOR(d = 1; d < LENGTH_ARRAY(vdvControl); d++){
		[vdvControl[d+1],251] = (mySX.PERIPHERALS.Device[d].StatusOnline)
		[vdvControl[d+1],252] = (mySX.PERIPHERALS.Device[d].StatusOnline)
	}
}
/******************************************************************************
	EoF
******************************************************************************/