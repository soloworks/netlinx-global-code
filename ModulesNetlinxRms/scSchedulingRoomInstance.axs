MODULE_NAME='scSchedulingRoomInstance'(DEV vdvConn, DEV vdvRoom, DEV tp[])
INCLUDE 'CustomFunctions'
INCLUDE 'UnicodeLib'
/********************************************************************************************************************************************************************************************************************************************************
	Bespoke simplified RMS Room Booking panel control
	All AMX control stripped out and re-coded

	This module handles a single room instance and the TouchPanel for that room

	Channels on Virtual Device:
	?? - Incoming - Sensor State (Fed from main program)
	?? - Outgoing - Occupancy State (Derived from 1 via module)
	?? - Outgoing - Meeting Currently Active

	Levels on Virtual Device
	?? - Outgoing - Occupancy State Countdown
********************************************************************************************************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************************************************************************************************
	Constants
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_CONSTANT
// Module Maximums
INTEGER _MAX_SLOTS	 	= 99			// Max slots for bookings and free time
INTEGER _MAX_PANELS	 	= 2			// Max number of panels supported

// Language
INTEGER LANG_EN  = 1
INTEGER LANG_JPN = 2
INTEGER LANG_CHN = 3
INTEGER LANG_KOR = 4

// Constant to represent '00:00:00' at end of day (As it appears twice in 24hr clock)
LONG		MIDNIGHT_SECS	= 86400 // 24*60*60 (note: Netlinx thinks 24*60*60 = 128. changed 20190411, gmm)

// Virtual Device Channels
INTEGER chn_vdv_SensorOnline	    = 1	// External Trigger indicating Sensor is connected
INTEGER chn_vdv_SensorTriggered   = 2	// External Trigger indicating Sensor has tripped
INTEGER chn_vdv_SlotBooked        = 3	// Internal Indicator room is Booked (Based on RMS Data)
INTEGER chn_vdv_RoomOccupied      = 4	// Internal Indicator room is Occupied (Based on Timer)

// Virtual Device Levels
INTEGER lvl_vdv_SlotRemain  	    = 3	// Internal Timer showing Booking Remaining Time
INTEGER lvl_vdv_Timer_Occupied  	 = 4	// Internal Timer for Room Occupancy
INTEGER lvl_vdv_Timer_NoShow	    = 5	// Internal Timer for Booking NoShow Action
INTEGER lvl_vdv_Timer_QuickBook   = 6	// Internal Timer for QuickBook NoShow Action
INTEGER lvl_vdv_Timer_AutoBook	 = 7	// Internal Timer for deciding AutoBook should trigger
INTEGER lvl_vdv_AutoBookTriggers	 = 8	// Internal Counter for Sensor Events for AutoBook Trigger

// Interface Overlays
INTEGER OVERLAY_NONE			= 0	// No Overlay on Panel
INTEGER OVERLAY_QUICK		= 1	// Quick Booking Interface
INTEGER OVERLAY_EXTEND		= 2	// Extend Meeting Interface
INTEGER OVERLAY_MESSAGE		= 3	// System messages
INTEGER OVERLAY_CALVIEW		= 4	// Calendar View
INTEGER OVERLAY_DIAG			= 5	// Calendar View

INTEGER AUTOBOOK_MODE_OFF     = 0
INTEGER AUTOBOOK_MODE_EVENTS  = 1
INTEGER AUTOBOOK_MODE_LATCHED = 2

// Interface Modes
INTEGER MODE_NAME				= 0	// Panel just shows room name
INTEGER MODE_DIARY			= 1	// Panel shows diary only, non interactive
INTEGER MODE_QUICKBOOK		= 2	// Panel shows Diary and Quick Book / extend function
INTEGER MODE_SENSOR			= 3	// Panel LEDs reflect Occupancy State Timer

//LED constants
INTEGER LED_STATE_OFF		= 1
INTEGER LED_STATE_GREEN		= 2
INTEGER LED_STATE_RED		= 3

// Debug
INTEGER DEBUG_ERR				= 0
INTEGER DEBUG_STD				= 1
INTEGER DEBUG_DEV				= 2
INTEGER DEBUG_LOG				= 3

// Page Details
INTEGER DETAILS_ON			= 0
INTEGER DETAILS_OFF			= 1
INTEGER DETAILS_DEV			= 2
INTEGER DETAILS_LOG			= 3

// Timeout timeline for calendar page
LONG TLID_TIMEOUT_OVERLAYS				= 01
LONG TLID_FB_TIME_CHECK					= 02
LONG TLID_TIMER_NOSHOW_TIMEOUT		= 03
LONG TLID_TIMER_QUICKBOOK_TIMEOUT	= 04
LONG TLID_TIMER_OCCUPANCY_TIMEOUT	= 05
LONG TLID_TIMER_AUTOBOOK_ACTION		= 06
LONG TLID_TIMER_AUTOBOOK_STANDOFF	= 07
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Internal Booking Slot
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uSlot{
	INTEGER  BOOKING_INDEX							// Booking Index if actual meeting
	INTEGER  ALLDAY									// True if Meeting is All Day
	INTEGER  isQUICKBOOK								// True if QuickBooked
	INTEGER  isAUTOBOOK								// True if AutoBooked
	INTEGER  isPRIVATE								// True if AutoBooked
	CHAR 		START_TIME[8]							// Slot start time - 00:00:00 Format
	SLONG 	START_REF								// Slot start time in seconds for comparisons
	CHAR 		END_TIME[8]								// Slot end time - 00:00:00 Format
	SLONG		END_REF									// Slot end time in seconds for comparisons
	SLONG		DURATION_SECS							// Slot Duration in Seconds
	SLONG		DURATION_MINS							// Slot Duration in MINS
	SLONG    REMAIN_SECS								// Remaining Time in Seconds
	SLONG    REMAIN_MINS								// Remaining Time in Mins

	WIDECHAR	SUBJECT[250]					   	// Booking Subject
	WIDECHAR	ORGANISER[250]				   		// Booking Organiser
}
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Internal Panel
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uPanel{
	CHAR		PAGE[30]			            // The name of the Room Booking page (default: RoomBooking)
	INTEGER 	OVERLAY			            // Panel current overlay
	INTEGER	MODE				            // Panel Operation Mode
	CHAR		ENDTIME[5]		            // Quick Book / Extend Meeting current end time
	CHAR		SUBJECT[50]		            // Quick Book current subject line
	SLONG 	QUICK_DURATION            	// Quick book duration field
	SLONG 	EXTEND_DURATION            // Extend book duration field
	INTEGER 	KEYBOARD_STATE	            // Current Shift State (ABC | NUM)
	INTEGER	CAL_SLOT_STATE[_MAX_SLOTS]	// Is cal slot shown (used to limit messages to panel)
}
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Timer
	This was getting too confusing so this structure is to help out
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uTimer{
	LONG INIT_VAL		// Initial Value for Timer
	LONG COUNTER		// Current Countdown Value
}
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Internal Main Module Data
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uRoom{
	// System Info
	INTEGER        LANGUAGE							// Panel Font Language to utilise
	INTEGER        DATE_FORMAT                // Panel Date Format

	// Room Infomation
	INTEGER 			LOC_ID							// RMS Supplied Location ID
	CHAR 				LOC_NAME[75]					// RMS Supplied Location Name
	CHAR 				DEF_NAME[75]					// Local Location Name

	// Slots Infomation
	uSlot       	SLOTS[_MAX_SLOTS]				// Panel Slots
	INTEGER			SLOT_CURRENT					// Current Slot Reference
	INTEGER        SLOTS_LOADING

	// Timers and Occupancy
	uTimer         OCCUPANCY_TIMEOUT

	// No Show Settings
	uTimer         NOSHOW_TIMEOUT             // Mins to wait before checking Occ State and cancelling (0 = Never)
	SLONG				NOSHOW_MAXIMUM					// Meetings longer than this will not be cancelled

	// Quick Booking Settings
	uTimer         QUICKBOOK_TIMEOUT
	CHAR				QUICKBOOK_SUBJECT[50]		// If present, place this in default meeting title
	SLONG 			QUICKBOOK_MINIMUM				// Dictates max no of free mins before hiding Quick Book pane
	SLONG				QUICKBOOK_MAXIMUM				//
	SLONG				QUICKBOOK_STEP					// Rounding for Quick Book - Valid Values: 5,10,15,20,30
	CHAR				QUICKBOOK_END_TIME[8]		// Quick reference for end time for next QuickBook
	CHAR				QUICKBOOK_START_TIME[8]		// Quick reference for start time for next QuickBook

	// Auto Booking Settings
	INTEGER        AUTOBOOK_MODE
	uTimer			AUTOBOOK_ACTION
	uTimer 			AUTOBOOK_STANDOFF
	CHAR				AUTOBOOK_SUBJECT[50]			// If present, place this in default meeting title
	INTEGER 			AUTOBOOK_EVENTS_COUNT		// Each movement triggers a Tick
	INTEGER			AUTOBOOK_EVENTS_THRESHOLD		// Total Ticks to consider constant movement

	// Programming Variables
	INTEGER 			DEBUG
	SINTEGER 		LAST_TRIGGERED_MINUTE		// Use to store state to check against raising events
	INTEGER        PAGE_DETAILS					// Used as flag for whether to display the pMsgDetail info on the overlay pane
}
/********************************************************************************************************************************************************************************************************************************************************
	Interface Constants
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_CONSTANT

//keyboard constants
INTEGER KEY_SPACE				= 1
INTEGER KEY_SHIFT				= 2
INTEGER KEY_DELETE			= 3

// Levels
INTEGER lvlRoomState						= 01
INTEGER lvlRoomOccupied					= 02
INTEGER lvlMeetingRemain				= 03
INTEGER lvlNoShowTimer  				= 04
INTEGER lvlQuickBookStandoffTimer  	= 05
INTEGER lvlAutoBookActionTimer  	 	= 06
INTEGER lvlAutoBookTickCount			= 07
INTEGER lvlAutoBookStandOffTimer		= 08

INTEGER lvlLangFeedback				   = 21
INTEGER lvlLangNowNext				   = 22
INTEGER lvlLangSlots					   = 23

// Addresses
INTEGER addRoomName				= 50

INTEGER addNowSubject 			= 51
INTEGER addNowOrganiser			= 52
INTEGER addNowStart				= 53
INTEGER addNowEnd					= 54
INTEGER btnNowBooked				= 55
INTEGER addNowDuration			= 56
INTEGER addNowRemaining			= 57

INTEGER addNextSubject 			= 61
INTEGER addNextOrganiser		= 62
INTEGER addNextStart				= 63
INTEGER addNextEnd				= 64
INTEGER btnNextBooked			= 65
INTEGER addNextDuration			= 66

INTEGER addQuickBookSubject 	= 80
INTEGER addQuickBookDuration	= 81
INTEGER addExtendDuration		= 82
INTEGER addQuickBookInstDur	= 83

INTEGER addMessage				= 90
INTEGER addMessageDetail		= 91
INTEGER addConnectionMsg		= 92

INTEGER addSlot					= 100
INTEGER addSlotName				= 200
INTEGER addSlotSubject			= 300
INTEGER addSlotStart				= 400
INTEGER addSlotEnd				= 500

// Buttons
INTEGER btnQuickBookInstant		= 701
INTEGER btnQuickbookDuration[]	= {711,712} //+15,-15
INTEGER btnQuickbook 				=  720
INTEGER btnExtendDuration[]		= {731,732} //+15,-15
INTEGER btnExtend						=  733

// KEYBOARD
INTEGER btnKeyboard[]	= {
801,802,803,804,805,806,807,808,809,810,
811,812,813,814,815,816,817,818,819,
820,821,822,823,824,825,826
}
INTEGER btnKeyboardSpecial[] = {
827, //SPACE
828, //SHIFT
829 //DELETE
}
INTEGER btnOverlayHide				= 1000
INTEGER btnOverlayShow[]			= {1001,1002,1003,1004,1005}

INTEGER btnDiagStateSensorOnline		= 3001
INTEGER btnDiagStateSensorTrigger	= 3002
INTEGER btnDiagStateRoomOccupied		= 3003
INTEGER btnDiagStateRoomBooked		= 3004

INTEGER addDiagSettingsRoomMode		= 3051
INTEGER addDiagSettingsOccupancy		= 3052
INTEGER addDiagSettingsQuickBook		= 3053
INTEGER addDiagSettingsAutoBook		= 3054
INTEGER addDiagSettingsNoShow 		= 3055
INTEGER addDiagSettingsLocation 		= 3056

INTEGER addDiagTimeOccupancy			= 3102
INTEGER addDiagTimeNoShow 				= 3104
INTEGER addDiagTimeQuickBook			= 3105
INTEGER addDiagTimeAutoBookAction	= 3106
INTEGER addDiagTimeAutoBookStandoff	= 3108

INTEGER addDiagTimeAutoBookEvents	= 3121

CHAR keyboard[][] = {
	{
		'q','w','e','r','t','y','u','i','o','p',
		'a','s','d','f','g','h','j','k','l',
		'z','x','c','v','b','n','m'
	},
	{
		'1','2','3','4','5','6','7','8','9','0',
		' ',' ',' ',' ',' ',' ',' ',' ',' ',
		' ',' ',' ',' ',' ',' ',' '
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Variables - General

********************************************************************************************************************************************************************************************************************************************************/
DEFINE_VARIABLE
VOLATILE uRoom 	myRoom			// RMS Room Booking data for this room
VOLATILE uPanel 	myRMSPanel[5]		// Allowance for multiple touch panels on one room

LONG TLT_OLAY_TIMEOUT[]  = {  45000 }	// Timeout for any overlay on the GUI
LONG TLT_ONE_MIN[]		 = {  60000 }	// One Min time array for Countdown Timelines
LONG TLT_FB_TIME_CHECK[] = {	 2500 }	// Repeating timer for Feedback (Increased to 2500 to chill processor out)

/********************************************************************************************************************************************************************************************************************************************************
	Helper Functions - Debugging
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_VARIABLE
VOLATILE CHAR DEBUG_LOG_FILENAME[255]

DEFINE_FUNCTION fnInitateLogFile(){
	STACK_VAR LONG HFile
	STACK_VAR CHAR pTIMESTAMP[255]
	STACK_VAR CHAR pFILELINE[255]

	pTIMESTAMP = "ITOA(DATE_TO_YEAR(LDATE)),'_'"
	pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',DATE_TO_MONTH(LDATE)),'_'"
	pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',DATE_TO_DAY(LDATE)),'_'"

	pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_HOUR(TIME)),'_'"
	pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_MINUTE(TIME)),'_'"
	pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_SECOND(TIME))"

	DEBUG_LOG_FILENAME = "'DEBUG_LOG_scRoomBookInstance_',ITOA(vdvRoom.Number),'_',pTIMESTAMP,'.log'"
	fnDebug(DEBUG_LOG,'FUNCTION','fnInitateLogFile',"'File Created:',pTIMESTAMP")
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR pOrigin[], CHAR pRef[],CHAR pData[]){
	// Check the requested debug against the current module setting
	IF(myRoom.DEBUG >= pDEBUG){
		STACK_VAR CHAR dbgMsg[255]
		dbgMsg = "ITOA(vdvRoom.Number),'|',pOrigin,'|',pRef,'| ',pData"
		// Send to diagnostics screen
		SEND_STRING 0:0:0, dbgMsg
		// Log to file if required
		IF(myRoom.DEBUG == DEBUG_LOG){
			STACK_VAR CHAR pTIMESTAMP[50]
			STACK_VAR SLONG HFile
			pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_HOUR(TIME)),':'"
			pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_MINUTE(TIME)),':'"
			pTIMESTAMP = "pTIMESTAMP,FORMAT('%02d',TIME_TO_SECOND(TIME))"
			dbgMsg = "pTIMESTAMP,'|',dbgMsg"
			HFile = FILE_OPEN(DEBUG_LOG_FILENAME,FILE_RW_APPEND)
			FILE_WRITE_LINE(HFile,dbgMsg,LENGTH_ARRAY(dbgMsg))
			FILE_CLOSE(HFile)
		}
	}
}

DEFINE_EVENT CHANNEL_EVENT[vdvConn,251]{
	ON: { fnSetupPanel(0) }
	OFF:{ fnSetupPanel(0) }
}
/********************************************************************************************************************************************************************************************************************************************************
*
*	Slots Management
*
********************************************************************************************************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************************************************************************************************
	Populate Slots
	This routine clears all slots and populates them for use with the panels
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnClearSlots(){
	STACK_VAR INTEGER s
	FOR(s = 1; s <= _MAX_SLOTS; s++){
		STACK_VAR uSlot blankSlot
		myRoom.SLOTS[s] = blankSlot
	}
}

DEFINE_FUNCTION INTEGER fnGetCurrentSlot(){
	STACK_VAR INTEGER s
	FOR(s = 1; s <= _MAX_SLOTS; s++){
		IF(myRoom.SLOTS[s].START_REF <= fnTimeToSeconds(TIME) && myRoom.SLOTS[s].END_REF >= fnTimeToSeconds(TIME)){
			RETURN s
		}
	}
	RETURN 0
}
DEFINE_FUNCTION INTEGER fnGetNextMeetingSlot(){

	STACK_VAR INTEGER s
	FOR(s = fnGetCurrentSlot()+1; s <= _MAX_SLOTS; s++){
		IF(myRoom.SLOTS[s].BOOKING_INDEX){
			RETURN s
		}
	}
}

DEFINE_FUNCTION fnInsertFreeSlot(INTEGER s){
	STACK_VAR uSlot freeSlot
	STACK_VAR CHAR pStartTime[8]
	STACK_VAR CHAR pEndTime[8]
	fnDebug(DEBUG_LOG,'FUNCTION',"'fnInsertFreeSlot(',ITOA(s),')'",'<-- Called')
	// Prepare a free slot for use
	freeSlot.SUBJECT   = CH_TO_WC('Free')
	freeSlot.ORGANISER = CH_TO_WC('N/A')
	// Sort out the Start
	SWITCH(s){
		CASE 1:  freeslot.START_REF = 0
		DEFAULT: freeslot.START_REF = myRoom.SLOTS[s-1].END_REF
	}
	pStartTime = fnSecondsToTime(freeSlot.START_REF)
	IF(LEFT_STRING(pStartTime,3) = '24:'){
		GET_BUFFER_STRING(pStartTime,2)
		pStartTime = "'00',pStartTime"
	}
	freeSlot.START_TIME 	= pStartTime//fnSecondsToTime(freeSlot.START_REF)
	// Sort out the End
	SWITCH(myRoom.SLOTS[s+1].START_REF){
		CASE FALSE: freeSlot.END_REF = MIDNIGHT_SECS
		DEFAULT:    freeSlot.END_REF = myRoom.SLOTS[s+1].START_REF
	}
	pEndTime   = fnSecondsToTime(freeSlot.END_REF)
	IF(LEFT_STRING(pEndTime,3) = '24:'){
		GET_BUFFER_STRING(pEndTime,2)
		pEndTime = "'00',pEndTime"
	}
	freeSlot.END_TIME 	= pEndTime//fnSecondsToTime(freeSlot.END_REF)
	// Insert Duration
	freeSlot.DURATION_SECS = freeSlot.END_REF - freeSlot.START_REF
	freeSlot.DURATION_MINS = fnSecsToMins(freeSlot.DURATION_SECS,TRUE)
	// Insert it
	myRoom.SLOTS[s] = freeSlot
	fnDebug(DEBUG_LOG,'FUNCTION',"'fnInsertFreeSlot(',ITOA(s),')'",'--> Done')
}

DEFINE_FUNCTION INTEGER fnAddSlot(uSlot S){
	// If this is an All Day, then just set it over everything else
	IF(S.ALLDAY){
		fnClearSlots()
		myRoom.SLOTS[1] = S
	}
	ELSE IF(!myRoom.SLOTS[1].ALLDAY){
		STACK_VAR INTEGER b
		// Find the first free slot
		FOR(b = 1; b <= _MAX_SLOTS; b++){
			// If there is no end ref, this slot has not been used
			IF(!myRoom.SLOTS[b].END_REF){
				// If this is the first slot and has a time later than 0
				IF(S.START_REF && b == 1){
					myRoom.SLOTS[b+1] = S
					fnInsertFreeSlot(b)
					RETURN b+1
				}
				// If the previous and this don't butt up (Can't check with above as b-1 may be negative)
				ELSE IF(S.START_REF > myRoom.SLOTS[b-1].END_REF){
					myRoom.SLOTS[b+1] = S
					fnInsertFreeSlot(b)
					RETURN b+1
				}
				ELSE{
					myRoom.SLOTS[b] = S
					RETURN b
				}
			}
		}
	}
}

/********************************************************************************************************************************************************************************************************************************************************
*
*	Virtual Device Control Section
*
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_START{
	// Create timeline to check for time ticking over to new Minute value
	TIMELINE_CREATE(TLID_FB_TIME_CHECK,TLT_FB_TIME_CHECK,LENGTH_ARRAY(TLT_FB_TIME_CHECK),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_FB_TIME_CHECK','<-- Created')
}
/********************************************************************************************************************************************************************************************************************************************************
	Timeline instead of Feedback to determine Remaining Time
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_FB_TIME_CHECK]{
	// Check if a new Min is in progress
	IF(myRoom.LAST_TRIGGERED_MINUTE != TIME_TO_MINUTE(TIME)){
		// Log for Debugging
		fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_FB_TIME_CHECK','<-- Called')
		// Set Comparison Value to prevent reoccurance until next Min
		myRoom.LAST_TRIGGERED_MINUTE = TIME_TO_MINUTE(TIME)
		// If this room has any data to even bother with this
		IF(myRoom.SLOT_CURRENT != fnGetCurrentSlot() && fnGetCurrentSlot() != 0){
			// Set Current Slot to new slot
			myRoom.SLOT_CURRENT = fnGetCurrentSlot()
			// Force the channel down, ensuring a trigger if a new meeting is in place
			OFF[vdvRoom,chn_vdv_SlotBooked]
			// Update meeting variables as required
			myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS   = myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF - fnTimeToSeconds(TIME)
			myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_MINS = fnSecsToMins(myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS,FALSE)
			// Update the panel
		}
		IF(myRoom.SLOT_CURRENT){
			fnUpdatePanel(0)
		}
		fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_FB_TIME_CHECK','--> Done')
	}
}

/********************************************************************************************************************************************************************************************************************************************************
	Virtual Device Data Events
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvRoom]{
	COMMAND:{
		//fnDebug(DEBUG_DEV,'DATA_EVENT [COMMAND] Called','vdvRoom',DATA.TEXT)
		fnDebug(DEBUG_DEV,'DATA_EVENT [COMMAND]','vdvRoom','<-- Called')
		fnDebug(DEBUG_DEV,'DATA_EVENT [COMMAND]','vdvRoom',DATA.TEXT)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'LOCATION':{
						myRoom.LOC_ID   = ATOI(fnGetCSV(DATA.TEXT,1))
						myRoom.LOC_NAME = fnGetCSV(DATA.TEXT,2)
						fnSetupPanel(0)
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	myRoom.DEBUG = DEBUG_STD
							CASE 'DEV':		myRoom.DEBUG = DEBUG_DEV
							CASE 'LOG':		myRoom.DEBUG = DEBUG_LOG
						}
						IF(myRoom.DEBUG == DEBUG_LOG){
							fnInitateLogFile()
						}
					}
					// Panel Page Settings
					CASE 'PAGE':{
						STACK_VAR INTEGER x
						FOR(x = 1; x <= LENGTH_ARRAY(tp); x++){
							myRMSPanel[x].PAGE = DATA.TEXT
						}
					}
					// Panel Settings
					CASE 'LANGUAGE':{
						SWITCH(DATA.TEXT){
							CASE 'JPN':	myRoom.LANGUAGE = LANG_JPN
							CASE 'CHN':	myRoom.LANGUAGE = LANG_CHN
							CASE 'KOR':	myRoom.LANGUAGE = LANG_KOR
							DEFAULT:		myRoom.LANGUAGE = LANG_EN
						}
					}
					CASE 'PAGE_DETAILS':{
						SWITCH(DATA.TEXT){
							CASE 'FALSE':	myRoom.PAGE_DETAILS = DETAILS_OFF
							CASE 'DEV':		myRoom.PAGE_DETAILS = DETAILS_DEV
							CASE 'LOG':		myRoom.PAGE_DETAILS = DETAILS_LOG
							DEFAULT:			myRoom.PAGE_DETAILS = DETAILS_ON
						}
						IF(myRoom.PAGE_DETAILS == DETAILS_LOG){
							myRoom.DEBUG = DEBUG_LOG
							fnInitateLogFile()
						}
					}
					CASE 'PANELMODE':{
						STACK_VAR INTEGER p
						p = 0
						IF(FIND_STRING(DATA.TEXT,',',1)){
							p = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						}
						ELSE{
							p = 0
						}
						fnSetPanelMode(p,DATA.TEXT)
					}
					CASE 'ROOMNAME':{
						myRoom.DEF_NAME = DATA.TEXT
					}
					CASE 'OCCUPANCY':{
						myRoom.OCCUPANCY_TIMEOUT.INIT_VAL	 = ATOI(fnGetCSV(DATA.TEXT,1))
					}
					// Room Settings
					CASE 'NOSHOW':{
						myRoom.NOSHOW_TIMEOUT.INIT_VAL = ATOI(fnGetCSV(DATA.TEXT,1))
						myRoom.NOSHOW_MAXIMUM = ATOI(fnGetCSV(DATA.TEXT,2))
					}
					// Quick Book Settings
					CASE 'QUICKBOOK':{
						myRoom.QUICKBOOK_TIMEOUT.INIT_VAL = ATOI(fnGetCSV(DATA.TEXT,1))
						myRoom.QUICKBOOK_MINIMUM = ATOI(fnGetCSV(DATA.TEXT,2))
						myRoom.QUICKBOOK_MAXIMUM = ATOI(fnGetCSV(DATA.TEXT,3))
						// Ensure STEP is within set parameters, default to 5
						SWITCH(ATOI(fnGetCSV(DATA.TEXT,4))){
							CASE 10:myRoom.QUICKBOOK_STEP = 10
							CASE 15:myRoom.QUICKBOOK_STEP = 15
							CASE 20:myRoom.QUICKBOOK_STEP = 20
							CASE 30:myRoom.QUICKBOOK_STEP = 30
							DEFAULT:myRoom.QUICKBOOK_STEP = 5
						}
						myRoom.QUICKBOOK_SUBJECT = fnGetCSV(DATA.TEXT,5)
					}

					// Auto Book Settings
					CASE 'AUTOBOOK':{
						SWITCH(fnGetCSV(DATA.TEXT,1)){
							CASE 'EVENTS':  myRoom.AUTOBOOK_MODE = AUTOBOOK_MODE_EVENTS
							CASE 'LATCHED': myRoom.AUTOBOOK_MODE = AUTOBOOK_MODE_LATCHED
						}
						myRoom.AUTOBOOK_STANDOFF.INIT_VAL   = ATOI(fnGetCSV(DATA.TEXT,2))
						myRoom.AUTOBOOK_ACTION.INIT_VAL     = ATOI(fnGetCSV(DATA.TEXT,3))
						myRoom.AUTOBOOK_EVENTS_THRESHOLD 	= ATOI(fnGetCSV(DATA.TEXT,4))
						myRoom.AUTOBOOK_SUBJECT             = fnGetCSV(DATA.TEXT,5)
					}
				}
			}
			CASE 'ACTION':{
				SWITCH(fnGetCSV(DATA.TEXT,1)){
					CASE 'OVERRIDE':{
						SWITCH(fnGetCSV(DATA.TEXT,2)){
							CASE 'NOSHOW':{
								IF(TIMELINE_ACTIVE(TLID_TIMER_NOSHOW_TIMEOUT)){
									TIMELINE_KILL(TLID_TIMER_NOSHOW_TIMEOUT)
									myRoom.NOSHOW_TIMEOUT.COUNTER = 0
								}
							}
						}
					}
					CASE 'RELOAD_PANEL':{
						fnInitPanel(0)
					}
				}
			}
			CASE 'RESPONSE':{
				STACK_VAR CHAR pMSG[255]
				STACK_VAR CHAR pDATA3[50]
				SWITCH(fnGetCSV(DATA.TEXT,1)){
					CASE 'EXTEND':pMsg = 'Booking '
					CASE 'CREATE':pMsg = 'Booking '
					CASE 'CANCEL':pMsg = 'Release Room '
					DEFAULT:      pMsg = 'Undefined Action'
				}
				SWITCH(fnGetCSV(DATA.TEXT,2)){
					CASE 'SUCCESS':pMsg = "pMsg,'Successful.'"
					CASE 'FAILURE':pMsg = "pMsg,'Declined.'"
					DEFAULT:       pMsg = "pMsg,'Undefined State.'"
				}
				IF(pMSG != 'Release Room Successful'){
					IF(fnGetCSV(DATA.TEXT,3) == ''){
						fnDisplayStatusMessage(pMSG,pMSG)
					}
					ELSE{
						// Fixing typo from RMS ('g' missing from end of booking
						//STACK_VAR CHAR pDATA3[50]
						pDATA3 = fnGetCSV(DATA.TEXT,3)
						IF(UPPER_STRING(pDATA3) == 'CANNOT CREATE EVENT BOOKING'){}//do nothing if the spelling is correct
						ELSE IF(UPPER_STRING(pDATA3) == 'CANNOT CREATE EVENT BOOKIN'){
							pDATA3 = 'Cannot create event booking'
						}
						fnDisplayStatusMessage(pMSG,pDATA3)
					}
				}
			}
			CASE 'BOOKING':{
				STACK_VAR INTEGER b	// Booking Index
				STACK_VAR INTEGER T	// Total Bookings
				STACK_VAR INTEGER s	// Total Bookings
				STACK_VAR uSlot thisSlot
				STACK_VAR CHAR pStartTime[8]
				STACK_VAR CHAR pEndTime[8]

				b = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				T = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))

				// If this is the first slot in the list
				IF(b == 1 || b = 0){
					// Flag up that slots are loading in
					myRoom.SLOTS_LOADING = TRUE
					// New Run of Slots - clear them out
					fnClearSlots()
				}
				IF(b >= 1){
					STACK_VAR INTEGER LEN
					// Populate Slot from incoming data
					thisSlot.BOOKING_INDEX = b
					thisSlot.ALLDAY    = (fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1) == 'true')
					thisSlot.isPRIVATE = (fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1) == 'true')
					thisSlot.START_REF = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
					thisSlot.END_REF   = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))

					thisSlot.SUBJECT   = WC_DECODE(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),WC_FORMAT_TP,1)
					thisSlot.ORGANISER = WC_DECODE(DATA.TEXT,WC_FORMAT_TP,1)

					// Populate additional fields
					thisSlot.DURATION_SECS = thisSlot.END_REF - thisSlot.START_REF
					thisSlot.DURATION_MINS = fnSecsToMins(thisSlot.DURATION_SECS,TRUE)
					pStartTime = fnSecondsToTime(thisSlot.START_REF)
					pEndTime   = fnSecondsToTime(thisSlot.END_REF)
					IF(LEFT_STRING(pStartTime,3) = '24:'){
						GET_BUFFER_STRING(pStartTime,2)
						pStartTime = "'00',pStartTime"
					}
					IF(LEFT_STRING(pEndTime,3) = '24:'){
						GET_BUFFER_STRING(pEndTime,2)
						pEndTime = "'00',pEndTime"
					}
					thisSlot.START_TIME = pStartTime//fnSecondsToTime(thisSlot.START_REF)
					thisSlot.END_TIME   = pEndTime//fnSecondsToTime(thisSlot.END_REF)

					IF(thisSlot.ALLDAY){
						thisSlot.START_REF  = 0
						thisSlot.END_REF    = MIDNIGHT_SECS
						pStartTime = fnSecondsToTime(thisSlot.START_REF)
						pEndTime   = fnSecondsToTime(thisSlot.END_REF)
						IF(LEFT_STRING(pStartTime,3) = '24:'){
							GET_BUFFER_STRING(pStartTime,2)
							pStartTime = "'00',pStartTime"
						}
						IF(LEFT_STRING(pEndTime,3) = '24:'){
							GET_BUFFER_STRING(pEndTime,2)
							pEndTime = "'00',pEndTime"
						}
						thisSlot.START_TIME = pStartTime//fnSecondsToTime(thisSlot.START_REF)
						thisSlot.END_TIME   = pEndTime//fnSecondsToTime(thisSlot.END_REF)
					}

					if(thisSlot.isPRIVATE){
						thisSlot.SUBJECT   = CH_TO_WC('Private')
						thisSlot.ORGANISER = CH_TO_WC('Private')
					}
					if(WC_TO_CH(thisSlot.SUBJECT) == myRoom.QUICKBOOK_SUBJECT){
						thisSlot.isQUICKBOOK = TRUE
					}
					if(WC_TO_CH(thisSlot.SUBJECT) == myRoom.AUTOBOOK_SUBJECT){
						thisSlot.isAUTOBOOK = TRUE
					}

					// Store Slot
					s = fnAddSlot(thisSlot)
				}
				// If this is the last slot to be sent
				IF(b == T){
					// Insert last free slot if required
					IF(thisSlot.END_REF != MIDNIGHT_SECS){
						fnInsertFreeSlot(s+1)
					}
					// Find and set the Current Slot
					myRoom.SLOT_CURRENT = fnGetCurrentSlot()
					// If this slot has no meeting, kill the timer(s)
					IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX == 0){
						IF(TIMELINE_ACTIVE(TLID_TIMER_NOSHOW_TIMEOUT)){
							myRoom.NOSHOW_TIMEOUT.COUNTER = 0
							TIMELINE_KILL(TLID_TIMER_NOSHOW_TIMEOUT)
						}
					}
					// Update meeting variables as required
					myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS = myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF - fnTimeToSeconds(TIME)
					myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_MINS = fnSecsToMins(myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS,TRUE)
					// This is the last slot, so we are now loaded
					myRoom.SLOTS_LOADING = FALSE
					// Re-load panels
					fnSetupPanel(0)
				}
			}
		}
		//fnDebug(DEBUG_DEV,'DATA_EVENT [COMMAND] Ended','vdvRoom','')
		fnDebug(DEBUG_DEV,'DATA_EVENT [COMMAND]','vdvRoom','--> Done')
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Virtual Device Channel Event - Meeting Active

	Use this to process things that need setting on meeting first occuring
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvRoom,chn_vdv_SlotBooked]{
	ON:{
		// If the Occupancy Sensors are active on this room
		IF([vdvROOM,chn_vdv_SensorOnline]){

			// If this is not a QuickBooked Meeting
			IF(!myRoom.SLOTS[myRoom.SLOT_CURRENT].isQUICKBOOK){
				// If No Show is configured for this room and the booking isn't an all day one
				IF(myRoom.NOSHOW_TIMEOUT.INIT_VAL && !myRoom.SLOTS[myRoom.SLOT_CURRENT].ALLDAY){
					// If current booking is not larger than max cancellable size
					IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].DURATION_MINS < myRoom.NOSHOW_MAXIMUM){
						// Set Timeout Timer to Threshold
						myRoom.NOSHOW_TIMEOUT.COUNTER = myRoom.NOSHOW_TIMEOUT.INIT_VAL
						// Start Timer
						IF(TIMELINE_ACTIVE(TLID_TIMER_NOSHOW_TIMEOUT)){TIMELINE_KILL(TLID_TIMER_NOSHOW_TIMEOUT)}
						TIMELINE_CREATE(TLID_TIMER_NOSHOW_TIMEOUT,TLT_ONE_MIN,LENGTH_ARRAY(TLT_ONE_MIN),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
					}
				}
			}
			// If this ia QuickBook Meeting then start the Quick Book cancellation standoff
			ELSE{
				// Set Timeout Timer to Threshold
				myRoom.QUICKBOOK_TIMEOUT.COUNTER = myRoom.QUICKBOOK_TIMEOUT.INIT_VAL
				SEND_COMMAND tp,"'^TXT-',ITOA(lvlQuickBookStandoffTimer),',2,',FORMAT('%02d',myRoom.QUICKBOOK_TIMEOUT.COUNTER),' min'"
				// Start Timer
				IF(TIMELINE_ACTIVE(TLID_TIMER_QUICKBOOK_TIMEOUT)){TIMELINE_KILL(TLID_TIMER_QUICKBOOK_TIMEOUT)}
				TIMELINE_CREATE(TLID_TIMER_QUICKBOOK_TIMEOUT,TLT_ONE_MIN,LENGTH_ARRAY(TLT_ONE_MIN),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
			}

			// Start AutoBook Standoff Timer
			IF(TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF)){
				myRoom.AUTOBOOK_STANDOFF.COUNTER = myRoom.AUTOBOOK_STANDOFF.INIT_VAL
				TIMELINE_KILL(TLID_TIMER_AUTOBOOK_STANDOFF)
			}
		}

		SEND_STRING vdvRoom,'ACTION-MEETING,STARTED'
		// Update Panels
		fnUpdatePanel(0)
	}
	OFF:{
		// Kill Timers
		myRoom.NOSHOW_TIMEOUT.COUNTER = 0
		IF(TIMELINE_ACTIVE(TLID_TIMER_NOSHOW_TIMEOUT)){TIMELINE_KILL(TLID_TIMER_NOSHOW_TIMEOUT)}
		myRoom.QUICKBOOK_TIMEOUT.COUNTER = 0
		IF(TIMELINE_ACTIVE(TLID_TIMER_QUICKBOOK_TIMEOUT)){TIMELINE_KILL(TLID_TIMER_QUICKBOOK_TIMEOUT)}

		// Start AutoBook Standoff Timer
		IF(!TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF)){
			myRoom.AUTOBOOK_STANDOFF.COUNTER = myRoom.AUTOBOOK_STANDOFF.INIT_VAL
			IF(TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF)){TIMELINE_KILL(TLID_TIMER_AUTOBOOK_STANDOFF)}
			TIMELINE_CREATE(TLID_TIMER_AUTOBOOK_STANDOFF,TLT_ONE_MIN,LENGTH_ARRAY(TLT_ONE_MIN),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
			// Update Timer
			SEND_COMMAND tp,"'^TXT-',ITOA(lvlAutoBookStandOffTimer),',2,',FORMAT('%02d',myRoom.AUTOBOOK_STANDOFF.COUNTER),' min'"
		}
		// Update Panels
		fnUpdatePanel(0)

		SEND_STRING vdvRoom,'ACTION-MEETING,ENDED'
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Virtual Device Timeline Event - Inactivity
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER_QUICKBOOK_TIMEOUT]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT',"'TLID_TIMER_QUICKBOOK_TIMEOUT',' ','TIMELINE.REPETITION=',ITOA(TIMELINE.REPETITION)",'<-- Called')

	// Knock a Min off the timer
	myRoom.QUICKBOOK_TIMEOUT.COUNTER--
	SEND_COMMAND tp,"'^TXT-',ITOA(lvlQuickBookStandoffTimer),',2,',FORMAT('%02d',myRoom.QUICKBOOK_TIMEOUT.COUNTER),' min'"

	// Act if Timer has run out
	IF(myRoom.QUICKBOOK_TIMEOUT.COUNTER == 0){
		// Kill own timeline
		TIMELINE_KILL(TLID_TIMER_QUICKBOOK_TIMEOUT)

		// Check for Room Occupancy
		IF(![vdvRoom,chn_vdv_RoomOccupied] && [vdvRoom,chn_vdv_SensorOnline]){
			SEND_COMMAND vdvRoom,"'ACTION-CANCEL,',ITOA(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX),',QuickBook Timeout'"
			fnDisplayStatusMessage('Ending Meeting','Room is being released...')
		}
	}
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_QUICKBOOK_TIMEOUT','--> Done')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER_NOSHOW_TIMEOUT]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_NOSHOW_TIMEOUT',"'TIMELINE.REPETITION=',ITOA(TIMELINE.REPETITION)")

	// Knock a Min off the timer
	myRoom.NOSHOW_TIMEOUT.COUNTER--

	// Update Panels
	SEND_COMMAND tp,"'^TXT-',ITOA(lvlNoShowTimer),',2,',FORMAT('%02d',myRoom.NOSHOW_TIMEOUT.COUNTER),' min'"
	// Act if Timer has run out
	IF(myRoom.NOSHOW_TIMEOUT.COUNTER == 0){
		// Kill own timeline
		TIMELINE_KILL(TLID_TIMER_NOSHOW_TIMEOUT)
		// Check for Room Occupancy
		IF(![vdvRoom,chn_vdv_RoomOccupied] && [vdvRoom,chn_vdv_SensorOnline]){
			SEND_COMMAND vdvRoom,"'ACTION-CANCEL,',ITOA(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX),',No Show'"
			fnDisplayStatusMessage('Ending Meeting','Room is being released...')
		}
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Virtual Device Channel Event - Occupancy Sensor
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvRoom,chn_vdv_RoomOccupied]{
	ON:{
		fnDebug(DEBUG_DEV,'CHANNEL_EVENT','chn_vdv_RoomOccupied','<-- ON')
		fnUpdateLEDs(0)
	}
	OFF:{
		fnDebug(DEBUG_DEV,'CHANNEL_EVENT','chn_vdv_RoomOccupied','--> OFF')
		fnUpdateLEDs(0)
		IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].isQUICKBOOK || myRoom.SLOTS[myRoom.SLOT_CURRENT].isAUTOBOOK){
			SEND_COMMAND vdvRoom,"'ACTION-CANCEL,',ITOA(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX),',Unoccupied'"
			fnDisplayStatusMessage('Ending Meeting','Room is being released...')
		}
	}
}

DEFINE_EVENT CHANNEL_EVENT[vdvRoom,chn_vdv_SensorTriggered]{
	ON:{
		fnDebug(DEBUG_DEV,'CHANNEL_EVENT','chn_vdv_SensorTriggered','<-- ON')

		// Reset the Occupancy Timer Value
		myRoom.OCCUPANCY_TIMEOUT.COUNTER = myRoom.OCCUPANCY_TIMEOUT.INIT_VAL

		// If timeline is running, kill it for now
		IF(TIMELINE_ACTIVE(TLID_TIMER_OCCUPANCY_TIMEOUT)){TIMELINE_KILL(TLID_TIMER_OCCUPANCY_TIMEOUT)}

		// Set Diagnostics Text
		SEND_COMMAND tp,"'^TXT-',ITOA(lvlRoomOccupied),',2,',ITOA(myRoom.OCCUPANCY_TIMEOUT.COUNTER),' min'"

		// Do an AutoBook Trigger Event
		SWITCH(myRoom.AUTOBOOK_MODE){
			CASE AUTOBOOK_MODE_EVENTS:{
				fnAutoBookEvent()
			}
			CASE AUTOBOOK_MODE_LATCHED:{
				myRoom.AUTOBOOK_ACTION.COUNTER = 0
				IF(TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_ACTION)){TIMELINE_KILL(TLID_TIMER_AUTOBOOK_ACTION)}
				TIMELINE_CREATE(TLID_TIMER_AUTOBOOK_ACTION,TLT_ONE_MIN,1,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
			}
		}
	}
	OFF:{
		fnDebug(DEBUG_DEV,'CHANNEL_EVENT','chn_vdv_SensorTriggered','--> OFF')

		// Set Diagnostics Text
		SEND_COMMAND tp,"'^TXT-',ITOA(lvlRoomOccupied),',2,',ITOA(myRoom.OCCUPANCY_TIMEOUT.COUNTER),' min'"

		// Create a new timeline
		TIMELINE_CREATE(TLID_TIMER_OCCUPANCY_TIMEOUT,TLT_ONE_MIN,LENGTH_ARRAY(TLT_ONE_MIN),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)

		// Debug Out
		fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_OCCUPANCY_TIMEOUT',"'<-- Created'")//"'Exit'")
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER_OCCUPANCY_TIMEOUT]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT',"'TLID_TIMER_OCCUPANCY_TIMEOUT',' ','TIMELINE.REPETITION=',ITOA(TIMELINE.REPETITION)",'<-- Called')

	// Subtract one Min from the Occupancy Timer
	myRoom.OCCUPANCY_TIMEOUT.COUNTER--

	// Set Diagnostics Text
	SEND_COMMAND tp,"'^TXT-',ITOA(lvlRoomOccupied),',2,',ITOA(myRoom.OCCUPANCY_TIMEOUT.COUNTER),' min'"

	// If Occupancy has run out, kill the Timeline
	IF(myRoom.OCCUPANCY_TIMEOUT.COUNTER == 0){ TIMELINE_KILL(TLID_TIMER_OCCUPANCY_TIMEOUT) }

	// Debug Out
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_OCCUPANCY_TIMEOUT','--> Done')//"'Exit'")
}
/********************************************************************************************************************************************************************************************************************************************************
	Timer Control - AutoBooking
********************************************************************************************************************************************************************************************************************************************************/
// AutoBook Control
DEFINE_FUNCTION fnAutoBookEvent(){
	fnDebug(DEBUG_DEV,'FUNCTION','fnAutoBookEvent',"'<-- Called'/*'Started'*/")
	IF(myRoom.SLOT_CURRENT){
		// If AutoBook is configured AND Autobook is not currently supposed to standoff
		IF(myRoom.AUTOBOOK_ACTION.INIT_VAL && !TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF)  && !myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX){
			// If timeline is not currently active
			IF(!TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_ACTION)){
				// Set Event Count by 1
				myRoom.AUTOBOOK_EVENTS_COUNT = 1
				// Fill up AutoBook Timer
				myRoom.AUTOBOOK_ACTION.COUNTER = myRoom.AUTOBOOK_ACTION.INIT_VAL
				// Start the Timer
				IF(TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_ACTION)){TIMELINE_KILL(TLID_TIMER_AUTOBOOK_ACTION)}
				TIMELINE_CREATE(TLID_TIMER_AUTOBOOK_ACTION,TLT_ONE_MIN,LENGTH_ARRAY(TLT_ONE_MIN),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
			}
			// If the timeline is currently active
			ELSE{
				// Increment the Events by 1
				myRoom.AUTOBOOK_EVENTS_COUNT++
			}
			// Update the GUI to match
			fnUpdateAutoBookFB(0)
		}
	}
	fnDebug(DEBUG_DEV,'FUNCTION','fnAutoBookEvent',"'--> Done'")
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER_AUTOBOOK_ACTION]{
	// Debug Out
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT',"'TLID_TIMER_AUTOBOOK',' ','TIMELINE.REPETITION=',ITOA(TIMELINE.REPETITION)",'<-- Called')
	SWITCH(myRoom.AUTOBOOK_MODE){
		CASE AUTOBOOK_MODE_EVENTS:{
			// Decrement the AutoBook timer value by 1
			myRoom.AUTOBOOK_ACTION.COUNTER--

			// Check if the Timer has expired and act if so
			IF(myRoom.AUTOBOOK_ACTION.COUNTER == 0){
				// Check Events total is high enough
				IF(myRoom.AUTOBOOK_EVENTS_COUNT >= myRoom.AUTOBOOK_EVENTS_THRESHOLD){
					// Check Sensors are online
					IF([vdvRoom,chn_vdv_SensorOnline]){
						fnDoAutoBook()
					}
				}
				// Tidy Up
				TIMELINE_KILL(TLID_TIMER_AUTOBOOK_ACTION)
				myRoom.AUTOBOOK_EVENTS_COUNT = 0
			}

			fnUpdateAutoBookFB(0)
		}
		CASE AUTOBOOK_MODE_LATCHED:{
			// Incremement timer to show note how long this occupancy has been high for
			myRoom.AUTOBOOK_ACTION.COUNTER++
			// Check and Do
			IF(myRoom.AUTOBOOK_ACTION.COUNTER == myRoom.AUTOBOOK_ACTION.INIT_VAL){
				IF(!TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF)){
					fnDoAutoBook()
					myRoom.AUTOBOOK_ACTION.COUNTER = 0
				}
				TIMELINE_KILL(TLID_TIMER_AUTOBOOK_ACTION)
			}
		}
	}
	// Debug Out
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_AUTOBOOK_ACTION','--> Done')
}

DEFINE_FUNCTION fnDoAutoBook(){
	// Check a booking isn't active
	IF(!myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX){
		// Check there is enough time left for booking to be made (using QuickBook settings)
		IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF - fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME) >= myRoom.QUICKBOOK_MINIMUM*60){
			STACK_VAR CHAR pMSG[255]
			pMSG = "'ACTION-CREATE'"	// Booking Index
			pMSG = "pMSG,',',myRoom.AUTOBOOK_SUBJECT"
			pMSG = "pMSG,',',myRoom.QUICKBOOK_START_TIME"
			pMSG = "pMSG,',',myRoom.QUICKBOOK_END_TIME"
			SEND_COMMAND vdvRoom,pMSG
			SEND_STRING vdvRoom, 'MEETING-AUTOBOOK'
			fnDisplayStatusMessage('Booking','Booking Meeting...')
		}
	}
}

DEFINE_FUNCTION fnUpdateAutoBookFB(INTEGER pPanel){
	STACK_VAR CHAR txtCommand[100]

	// Loop if all panels
	IF(pPanel == 0){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnUpdateAutoBookFB(p)
		}
		RETURN
	}
	// Update Timer
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlAutoBookActionTimer),',2,',FORMAT('%02d',myRoom.AUTOBOOK_ACTION.COUNTER),' min'"

	// Update Events
	IF(myRoom.AUTOBOOK_MODE == AUTOBOOK_MODE_EVENTS){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookEvents),',2,',FORMAT('%02d',myRoom.AUTOBOOK_EVENTS_COUNT),' of ',FORMAT('%02d',myRoom.AUTOBOOK_EVENTS_THRESHOLD),' events'"
	}

	SEND_COMMAND tp[pPanel],txtCommand
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMER_AUTOBOOK_STANDOFF]{

	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_AUTOBOOK_STANDOFF',"'<-- Called'")
	// Decrement the AutoBook timer value by 1
	myRoom.AUTOBOOK_STANDOFF.COUNTER--

	// Update Timer
	SEND_COMMAND tp,"'^TXT-',ITOA(lvlAutoBookStandOffTimer),',2,',FORMAT('%02d',myRoom.AUTOBOOK_STANDOFF.COUNTER),' min'"

	// Check if the Timer has expired and act if so
	IF(myRoom.AUTOBOOK_STANDOFF.COUNTER == 0){
		// Tidy Up
		TIMELINE_KILL(TLID_TIMER_AUTOBOOK_STANDOFF)
		myRoom.AUTOBOOK_EVENTS_COUNT = 0
		SWITCH(myRoom.AUTOBOOK_MODE){
			CASE AUTOBOOK_MODE_LATCHED:{
				IF(myRoom.AUTOBOOK_ACTION.COUNTER == myRoom.AUTOBOOK_ACTION.INIT_VAL){
					myRoom.AUTOBOOK_ACTION.COUNTER = 0
					fnDoAutoBook()
				}
			}
		}
	}
	// Debug Out
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMER_AUTOBOOK_STANDOFF',"'--> Done'")
}

/********************************************************************************************************************************************************************************************************************************************************
*
*	Interface Control Section
*
********************************************************************************************************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************************************************************************************************
	Interface Data Events
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		STACK_VAR INTEGER x
		fnDebug(DEBUG_DEV,'DATA_EVENT',"'Panel[',ITOA(DATA.DEVICE.NUMBER),']'",'<-- Online')

		// Hide all cal slots and store state
		IF(1){
			FOR(x = 1; x <= _MAX_SLOTS; x++){
				SEND_COMMAND tp[GET_LAST(tp)], "'^SHD-',ITOA(addSlot),',bookSlot',FORMAT('%02d',x)"
				myRMSPanel[GET_LAST(tp)].CAL_SLOT_STATE[x] = FALSE
			}
		}
		fnInitPanel(GET_LAST(tp))
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,'DATA_EVENT',"'Panel[',ITOA(DATA.DEVICE.NUMBER),']'",'<-- Offline')
		myRMSPanel[GET_LAST(tp)].OVERLAY = OVERLAY_NONE
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Interface Button Events
********************************************************************************************************************************************************************************************************************************************************/
//button presses that activate overlays
DEFINE_EVENT BUTTON_EVENT[tp,btnOverlayHide]{
	PUSH:{
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnOverlayHide','PUSH')
		fnSetupOverlay(GET_LAST(tp), OVERLAY_NONE)
	}
}

//button presses that activate overlays
DEFINE_EVENT BUTTON_EVENT[tp,btnOverlayShow]{
	PUSH:{
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnOverlayShow','PUSH')
		IF(GET_LAST(btnOverlayShow) != OVERLAY_DIAG){
			fnSetupOverlay(GET_LAST(tp), GET_LAST(btnOverlayShow))
		}
	}
	HOLD[15]:{
		IF(GET_LAST(btnOverlayShow) == OVERLAY_DIAG){
			fnSetupOverlay(GET_LAST(tp), GET_LAST(btnOverlayShow))
		}
	}
}

//send keyboard presses
DEFINE_EVENT BUTTON_EVENT[tp, btnKeyboard]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tp)
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnKeyboard','PUSH')
		myRMSPanel[p].SUBJECT = "myRMSPanel[p].SUBJECT, keyboard[myRMSPanel[p].KEYBOARD_STATE+1][GET_LAST(btnKeyboard)]"
		fnUpdatePanelQuickBook(p)
	}
}

//all keys that aren't QWERTY
DEFINE_EVENT BUTTON_EVENT[tp, btnKeyboardSpecial]{
	PUSH:{
		STACK_VAR INTEGER pPanel
		pPanel = GET_LAST(tp)
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnKeyboardSpecial','PUSH')
		SWITCH(GET_LAST(btnKeyboardSpecial)){
			CASE KEY_SPACE:{
				myRMSPanel[pPanel].SUBJECT = "myRMSPanel[pPanel].SUBJECT,' '"
				fnUpdatePanelQuickBook(pPanel)
			}
			CASE KEY_SHIFT:{
				myRMSPanel[pPanel].KEYBOARD_STATE = !(myRMSPanel[pPanel].KEYBOARD_STATE)
				fnUpdateKeyboard(pPanel, myRMSPanel[pPanel].KEYBOARD_STATE)
			}
			CASE KEY_DELETE:{
				myRMSPanel[pPanel].SUBJECT = fnStripCharsRight(myRMSPanel[pPanel].SUBJECT,1)
				fnUpdatePanelQuickBook(pPanel)
			}
		}
	}
	HOLD[10]:{
		STACK_VAR INTEGER pPanel
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnKeyboardSpecial','HOLD')
		pPanel = GET_LAST(tp)
		SWITCH(GET_LAST(btnKeyboardSpecial)){
			CASE KEY_DELETE:{
				myRMSPanel[pPanel].SUBJECT = ''
				fnUpdatePanelQuickBook(pPanel)
			}
		}
	}
}

//update the quick booking duration on press and stop overlaping bookings being sent
DEFINE_EVENT BUTTON_EVENT[tp,btnQuickbookDuration]{
	PUSH:{
		// Declare Local Variables
		STACK_VAR INTEGER pPanel
		STACK_VAR SLONG pMyDuration

		// Set Local Variables
		pPanel = GET_LAST(tp)
		pMyDuration = myRMSPanel[pPanel].QUICK_DURATION

		// Debug Out
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnQuickbookDuration','PUSH')
		fnDebug(DEBUG_DEV,'btnQuickbookDuration','pMyDuration 1',ITOA(pMyDuration))

		// Action Button to Value
		SWITCH(GET_LAST(btnQuickbookDuration)){
			CASE 1:{ // Increment Time
				pMyDuration = pMyDuration + myRoom.QUICKBOOK_STEP
			}
			CASE 2:{ // Decrement Time
				IF(pMyDuration - myRoom.QUICKBOOK_STEP <= 0){
					pMyDuration = 0
				}
				ELSE{
					pMyDuration = pMyDuration - myRoom.QUICKBOOK_STEP
				}
			}
		}
		fnDebug(DEBUG_DEV,'btnQuickbookDuration','pMyDuration 2',ITOA(pMyDuration))

		// Check new value against min and max and correct if required
		SWITCH(GET_LAST(btnQuickbookDuration)){
			CASE 1:{	// Increment Time

				// Check meeting isn't longer than Max Duration
				IF(pMyDuration > myRoom.QUICKBOOK_MAXIMUM){
					pMyDuration = myRoom.QUICKBOOK_MAXIMUM
				}

				// Check meeting doesn't encroach on next one
				IF(fnGetNextMeetingSlot()){
					IF(fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME)+(pMyDuration * 60) > myRoom.SLOTS[fnGetNextMeetingSlot()].START_REF){
						pMyDuration = (myRoom.SLOTS[fnGetNextMeetingSlot()].START_REF - fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME)) / 60
					}
				}
			}
			CASE 2:{	// Decrement Time
				// Check meeting isn't longer than Max Duration
				IF(pMyDuration < myRoom.QUICKBOOK_MINIMUM){
					pMyDuration = myRoom.QUICKBOOK_MINIMUM
				}
			}
		}
		fnDebug(DEBUG_DEV,'btnQuickbookDuration','pMyDuration 3',ITOA(pMyDuration))

		// Update variable
		myRMSPanel[pPanel].QUICK_DURATION = pMyDuration

		// Update display
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addQuickBookDuration),',0,',ITOA(myRMSPanel[pPanel].QUICK_DURATION)"
	}
}

//update the extend booking duration on press and stop overlaping bookings being sent
DEFINE_EVENT BUTTON_EVENT[tp,btnExtendDuration]{
	PUSH:{
		// Declare Local Variables
		STACK_VAR INTEGER pPanel
		STACK_VAR SLONG   pMyDuration

		// Set Local Variables
		pPanel = GET_LAST(tp)
		pMyDuration = myRMSPanel[pPanel].EXTEND_DURATION

		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnExtendDuration','PUSH')

		// Action Button to Value
		SWITCH(GET_LAST(btnExtendDuration)){
			CASE 1:{ // Increment Time
				pMyDuration = pMyDuration + myRoom.QUICKBOOK_STEP
			}
			CASE 2:{ // Decrement Time
				IF(pMyDuration - myRoom.QUICKBOOK_STEP <= 0){
					pMyDuration = 0
				}
				ELSE{
					pMyDuration = pMyDuration - myRoom.QUICKBOOK_STEP
				}
			}
		}
		// Check new value against min and max and correct if required
		SWITCH(GET_LAST(btnExtendDuration)){
			CASE 1:{	// Increment Time

				// Check meeting isn't longer than Max Duration
				IF(pMyDuration > myRoom.QUICKBOOK_MAXIMUM){
					pMyDuration = myRoom.QUICKBOOK_MAXIMUM
				}

				// Check meeting doesn't encroach on next one
				IF(fnGetNextMeetingSlot()){
					IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].START_REF+(pMyDuration * 60) > myRoom.SLOTS[fnGetNextMeetingSlot()].START_REF){
						pMyDuration = (myRoom.SLOTS[fnGetNextMeetingSlot()].START_REF - fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME)) / 60
					}
				}
			}
			CASE 2:{	// Decrement Time
				// Check meeting isn't longer than Max Duration
				IF(pMyDuration < myRoom.QUICKBOOK_MINIMUM){
					pMyDuration = myRoom.QUICKBOOK_MINIMUM
				}
			}
		}

		// Update variable
		myRMSPanel[pPanel].EXTEND_DURATION = pMyDuration

		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addExtendDuration),',0,',ITOA(myRMSPanel[pPanel].EXTEND_DURATION)"
	}
}

// create the booking if subject and time are filled out
DEFINE_EVENT BUTTON_EVENT[tp, btnQuickbook]{
	PUSH:{
		STACK_VAR INTEGER pPanel
		pPanel = GET_LAST(tp)
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnQuickbook','PUSH')
		IF(LENGTH_ARRAY(myRMSPanel[pPanel].SUBJECT) && myRMSPanel[pPanel].QUICK_DURATION){	//details filled out
			STACK_VAR CHAR pMSG[255]
			pMSG = "'ACTION-CREATE'"	// Booking Index
			pMSG = "pMSG,',',myRoom.QUICKBOOK_SUBJECT"
			pMSG = "pMSG,',',myRoom.QUICKBOOK_START_TIME"
			pMSG = "pMSG,',',fnSecondsToTime( fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME)+(myRMSPanel[pPanel].QUICK_DURATION*60) )"
			SEND_COMMAND vdvRoom,pMSG
			fnDisplayStatusMessage('Quick Book','Booking Meeting...')
		}
	}
}
// create the booking if subject and time are filled out
DEFINE_EVENT BUTTON_EVENT[tp, btnQuickBookInstant]{//instance booking button on the AZ booking panels.
	PUSH:{
		STACK_VAR CHAR pMSG[255]
		pMSG = "'ACTION-CREATE'"	// Booking Index
		pMSG = "pMSG,',',myRoom.QUICKBOOK_SUBJECT"
		pMSG = "pMSG,',',myRoom.QUICKBOOK_START_TIME"
		pMSG = "pMSG,',',myRoom.QUICKBOOK_END_TIME"
		SEND_COMMAND vdvRoom,pMSG
		fnDisplayStatusMessage('Quick Book','Booking Meeting...')
	}
}

//extend current booking if details filled out
DEFINE_EVENT BUTTON_EVENT[tp, btnExtend]{
	PUSH:{
		STACK_VAR INTEGER pPanel
		pPanel = GET_LAST(tp)
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','btnExtend','PUSH')
		IF(myRMSPanel[pPanel].EXTEND_DURATION){	//details filled out
			SEND_COMMAND vdvRoom,"'ACTION-EXTEND,',ITOA(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX),',',ITOA(myRMSPanel[pPanel].EXTEND_DURATION)"
			fnDisplayStatusMessage('Extend Meeting','Extending Meeting...')
		}
	}
}

//timeout for calendar page to return to main page after no presses
DEFINE_EVENT BUTTON_EVENT[tp,0]{ //any presses for timeline below
	PUSH:{
		fnDebug(DEBUG_DEV,'BUTTON_EVENT','ALL','PUSH')

		// Reset overlay timeout if active
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT_OVERLAYS)){TIMELINE_KILL(TLID_TIMEOUT_OVERLAYS)}
		TIMELINE_CREATE(TLID_TIMEOUT_OVERLAYS,TLT_OLAY_TIMEOUT,LENGTH_ARRAY(TLT_OLAY_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)

		fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLT_OLAY_TIMEOUT','<-- Created')
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT_OVERLAYS]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_TIMEOUT_OVERLAYS','<-- Called')
	fnSetupOverlay(0,OVERLAY_NONE)
}
/********************************************************************************************************************************************************************************************************************************************************
	Interface Control - Init Panel Functions
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnInitPanel(INTEGER pPanel){
	// Debug Out
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnInitPanel(','pPanel=',ITOA(pPanel),')'",'<-- Called')

	// Cater for when all panels should be updated
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnInitPanel(p)
		}
		RETURN
	}

	// Copy Font to buttons as required by Language from Diagnostics Reference Point
	IF(1){
		STACK_VAR CHAR pButtonRange[200]
		STACK_VAR INTEGER wtf

		pButtonRange = "ITOA(addNowSubject)"
		pButtonRange = "pButtonRange,'&',ITOA(addNowOrganiser)"
		pButtonRange = "pButtonRange,'&',ITOA(addNextSubject)"
		pButtonRange = "pButtonRange,'&',ITOA(addNextOrganiser)"
		SEND_COMMAND tp[pPanel],"'^BMC-',pButtonRange,',0,',ITOA(tp[pPanel].PORT),',',ITOA(lvlLangNowNext),',',ITOA(myRoom.LANGUAGE),',%FT'"

		// This was added because ITOA(addSlotName+_MAX_SLOTS) returned 43 instead of 299
		wtf = addSlotName + _MAX_SLOTS
		pButtonRange = "ITOA(addSlotName+1),'.',ITOA(wtf)"
		pButtonRange = "pButtonRange,'&',ITOA(addSlotSubject+1),'.',ITOA(addSlotSubject+_MAX_SLOTS)"
		SEND_COMMAND tp[pPanel], "'^BMC-',pButtonRange,',0,',ITOA(tp[pPanel].PORT),',',ITOA(lvlLangSlots),',',ITOA(myRoom.LANGUAGE),',%FT'"
	}

	// Set the default page unless it has been overridden
	IF(myRMSPanel[pPanel].PAGE == ''){ myRMSPanel[pPanel].PAGE = 'RoomBooking' }

	// Setup General Diagnostics Feedback
	SWITCH(myRMSPanel[pPanel].MODE){
		CASE MODE_NAME:		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsRoomMode),',0,Name'"
		CASE MODE_SENSOR:		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsRoomMode),',0,Sensor'"
		CASE MODE_DIARY:		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsRoomMode),',0,Diary'"
		CASE MODE_QUICKBOOK:	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsRoomMode),',0,QuickBook'"
	}

	// Setup Occupancy Diagnostics Feedback
	IF(myRoom.OCCUPANCY_TIMEOUT.INIT_VAL){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsOccupancy),',0,',ITOA(myRoom.OCCUPANCY_TIMEOUT.INIT_VAL),' min'"
		SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlRoomOccupied),',0,%GL0%GH',ITOA(myRoom.OCCUPANCY_TIMEOUT.INIT_VAL)"
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeOccupancy),',0,',FORMAT('%02d',myRoom.OCCUPANCY_TIMEOUT.INIT_VAL)"
	}
	ELSE{
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeOccupancy),',0,N/A'"
	}

	// Setup QuickBook Diagnostics Feedback
	IF(1){
		STACK_VAR CHAR MSG[250]

		MSG = "ITOA(myRoom.QUICKBOOK_TIMEOUT.INIT_VAL),','"
		MSG = "MSG,ITOA(myRoom.QUICKBOOK_MINIMUM),','"
		MSG = "MSG,ITOA(myRoom.QUICKBOOK_MAXIMUM),','"
		MSG = "MSG,ITOA(myRoom.QUICKBOOK_STEP),','"
		MSG = "MSG,myRoom.QUICKBOOK_SUBJECT"

		IF(MSG == '0,0,0,0,'){ MSG = 'Not Set' }

		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsQuickBook),',0,',MSG"
		SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlQuickBookStandoffTimer),',0,%GL0%GH',ITOA(myRoom.QUICKBOOK_TIMEOUT.INIT_VAL)"

		SWITCH(myRoom.QUICKBOOK_TIMEOUT.INIT_VAL){
			CASE 0:	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeQuickBook),',0,N/A'"
			DEFAULT:	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeQuickBook),',0,',FORMAT('%02d',myRoom.QUICKBOOK_TIMEOUT.INIT_VAL)"
		}
	}

	// Setup NoShow Diagnostics Feedback
	IF(1){
		STACK_VAR CHAR MSG[250]

		MSG = "ITOA(myRoom.NOSHOW_TIMEOUT.INIT_VAL),','"
		MSG = "MSG,ITOA(myRoom.NOSHOW_MAXIMUM)"

		IF(MSG == '0,'){ MSG = 'Not Set' }

		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsNoShow),',0,',MSG"

		SWITCH(myRoom.NOSHOW_TIMEOUT.INIT_VAL){
			CASE 0:	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeNoShow),',0,N/A'"
			DEFAULT:{
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeNoShow),',0,',FORMAT('%02d',myRoom.NOSHOW_TIMEOUT.INIT_VAL)"
				SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlNoShowTimer),',0,%GL0%GH',ITOA(myRoom.NOSHOW_TIMEOUT.INIT_VAL)"
			}
		}
	}

	// Setup AutoBook Action Diagnostics Feedback
	IF(1){
		STACK_VAR CHAR MSG[250]
		SWITCH(myRoom.AUTOBOOK_MODE){
			CASE AUTOBOOK_MODE_EVENTS: MSG = 'EVENTS,'
			CASE AUTOBOOK_MODE_LATCHED:MSG = 'LATCHED,'
		}
		MSG = "MSG,ITOA(myRoom.AUTOBOOK_STANDOFF.INIT_VAL),','"
		MSG = "MSG,ITOA(myRoom.AUTOBOOK_ACTION.INIT_VAL),','"
		MSG = "MSG,ITOA(myRoom.AUTOBOOK_EVENTS_THRESHOLD),','"
		MSG = "MSG,myRoom.AUTOBOOK_SUBJECT"

		IF(MSG == '0,0,0,'){ MSG = 'Not Set' }

		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagSettingsAutoBook),',0,',MSG"

		SWITCH(myRoom.AUTOBOOK_ACTION.INIT_VAL){
			CASE 0:	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookAction),',0,N/A'"
			DEFAULT:{
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookAction),',0,',FORMAT('%02d',myRoom.AUTOBOOK_ACTION.INIT_VAL)"
				SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlAutoBookActionTimer),',0,%GL0%GH',ITOA(myRoom.AUTOBOOK_ACTION.INIT_VAL)"
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlAutoBookActionTimer),',2,',FORMAT('%02d',myRoom.AUTOBOOK_ACTION.COUNTER),' min'"
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookStandoff),',0,',FORMAT('%02d',myRoom.AUTOBOOK_STANDOFF.INIT_VAL)"
				SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlAutoBookStandOffTimer),',0,%GL0%GH',ITOA(myRoom.AUTOBOOK_STANDOFF.INIT_VAL)"
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlAutoBookStandOffTimer),',2,',FORMAT('%02d',myRoom.AUTOBOOK_STANDOFF.COUNTER),' min'"
				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlNoShowTimer),',2,',FORMAT('%02d',myRoom.NOSHOW_TIMEOUT.COUNTER),' min'"
			}
		}
		SWITCH(myRoom.AUTOBOOK_MODE){
			CASE AUTOBOOK_MODE_OFF:		 SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookEvents),',2,N/A'"
			CASE AUTOBOOK_MODE_LATCHED: SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookEvents),',2,Latched'"
			CASE AUTOBOOK_MODE_EVENTS:  SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addDiagTimeAutoBookEvents),',2,'"
		}
	}

	// Call Next Stage
	fnSetupPanel(pPanel)

	// Debug Out
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnInitPanel(','pPanel=',ITOA(pPanel),')'",'<-- Called')
}
/********************************************************************************************************************************************************************************************************************************************************
	Interface Control - Panel Setup Functions
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnSetupPanel(INTEGER pPanel){
	// Debug Out
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnSetupPanel(','pPanel=',ITOA(pPanel),')'",'<-- Called')

	// Cater for when all panels should be updated
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSetupPanel(p)
		}
		RETURN
	}

	// Send the room name
	IF(LENGTH_ARRAY(myRoom.LOC_NAME)){
		// Send the location
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addDiagSettingsLocation),',0,',FORMAT('%04d',myRoom.LOC_ID),':',myRoom.LOC_NAME"
		// RMS supplied Room Name
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addRoomName),',0,',myRoom.LOC_NAME"
	}
	ELSE{
		// Local supplied Room Name
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addRoomName),',0,',myRoom.DEF_NAME"
	}

	// Setup for Non Diary
	IF(!myRoom.SLOT_CURRENT || myRMSPanel[pPanel].MODE == MODE_NAME || myRMSPanel[pPanel].MODE == MODE_SENSOR || ![vdvConn,251]){
		fnSetupOverlay(pPanel,OVERLAY_NONE)
		SEND_COMMAND tp[pPanel], "'@PPF-bookingInfoNowNext;',myRMSPanel[pPanel].PAGE"
		SEND_COMMAND tp[pPanel], "'@PPN-paneRoomBookNamePlaque;',myRMSPanel[pPanel].PAGE"

		// Set info message on Name page
		SELECT{
			ACTIVE(![vdvConn,251]):					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addConnectionMsg),',0,Connecting to Server'"
			ACTIVE(!myRoom.LOC_ID):{				SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addConnectionMsg),',0,Syncing with Server'"  }
			ACTIVE(!myRoom.SLOT_CURRENT):{		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addConnectionMsg),',0,Downloading Bookings'" }
			ACTIVE(1):{									SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addConnectionMsg),',0,'" }
		}

		// Setup LEDs
		fnUpdateLEDs(pPanel)
	}
	// Setup For Diary
	ELSE{
		// Show the Header Section
		SEND_COMMAND tp[pPanel], "'@PPN-paneRoomBookHeader;',myRMSPanel[pPanel].PAGE"

		// Hide any Popups
		fnSetupOverlay(pPanel, OVERLAY_NONE)

		// Setup Panel
		fnBuildDiaryDetailOnPanel(pPanel)

	}


	fnDebug(DEBUG_DEV,'FUNCTION',"'fnSetupPanel(','pPanel=',ITOA(pPanel),')'",'--> Done')
}

//core function for updating the panel with the correct booking info
DEFINE_FUNCTION fnBuildDiaryDetailOnPanel(INTEGER pPanel){
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnBuildDiaryDetailOnPanel(','pPanel=',ITOA(pPanel),')'",'<-- Called')

	// Call all panels
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnBuildDiaryDetailOnPanel(p)
		}
		RETURN
	}

	// Setup SubPane
	IF(1){
		//
		STACK_VAR CHAR pBookinfoPane[50]

		// Work out correct Booking pane
		SWITCH(myRoom.SLOTS[myRoom.SLOT_CURRENT].ALLDAY){
			CASE TRUE: pBookinfoPane = 'bookingInfoAllDay'
			DEFAULT:{
				// Set to NowNext
				pBookinfoPane = 'bookingInfoNowNext'

				If(myRMSPanel[pPanel].MODE == MODE_QUICKBOOK && !myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX){
					// Populate Quick Book Settings
					STACK_VAR SLONG NEW_END_TIME

					// Wipe old time off
					myRoom.QUICKBOOK_START_TIME = ''
					myRoom.QUICKBOOK_END_TIME = ''

					// Calculate what it should be on current rules in seconds
					NEW_END_TIME = (fnTimeToSeconds(TIME) + (60*myRoom.QUICKBOOK_MAXIMUM))
					// MOD off any spare seconds
					NEW_END_TIME = NEW_END_TIME - NEW_END_TIME%60

					// MOD this back to rounding option
					IF(!myRoom.QUICKBOOK_STEP){myRoom.QUICKBOOK_STEP = 5}
					NEW_END_TIME = NEW_END_TIME - NEW_END_TIME%(myRoom.QUICKBOOK_STEP*60)

					IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF < NEW_END_TIME){
						NEW_END_TIME = myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF
					}

					// Convert it to a Time value
					myRoom.QUICKBOOK_END_TIME = fnSecondsToTime(NEW_END_TIME)
					IF(myRoom.QUICKBOOK_END_TIME = '24:00:00'){myRoom.QUICKBOOK_END_TIME = '23:59:00'}

					// Set Start Time as well
					myRoom.QUICKBOOK_START_TIME = fnSecondsToTime(fnTimeToSeconds(TIME)-(fnTimeToSeconds(TIME)%60))

					IF(myRoom.SLOTS[myRoom.SLOT_CURRENT].END_REF - fnTimeToSeconds(myRoom.QUICKBOOK_START_TIME) >= myRoom.QUICKBOOK_MINIMUM*60){
						pBookinfoPane = 'bookingInfoQuickBook'
					}
				}
			}
		}

		// Send actual command
		SWITCH(LENGTH_ARRAY(pBookinfoPane)){
			CASE 0:	SEND_COMMAND tp[pPanel], "'@PPF-',pBookinfoPane,';',myRMSPanel[pPanel].PAGE"
			DEFAULT:	SEND_COMMAND tp[pPanel], "'@PPN-',pBookinfoPane,';',myRMSPanel[pPanel].PAGE"
		}
	}
	fnUpdatePanel(pPanel)

	fnDebug(DEBUG_DEV,'FUNCTION',"'fnBuildDiaryDetailOnPanel(','pPanel=',ITOA(pPanel),')'",'--> Done')
}

DEFINE_FUNCTION fnUpdatePanel(INTEGER pPanel){
	STACK_VAR CHAR pStartTime[8]
	STACK_VAR CHAR pEndTime[8]

	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanel(','pPanel=',ITOA(pPanel),')'",'<-- Called')

	// Call all panels
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnUpdatePanel(p)
		}
		RETURN
	}

	// Populate Now Fields
	SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addNowSubject),   ',0,',WC_TP_ENCODE(myRoom.SLOTS[myRoom.SLOT_CURRENT].SUBJECT)"

	pStartTime = fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT].START_TIME,3)
	pEndTime   = fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT].END_TIME,3)
	IF(LEFT_STRING(pStartTime,3) = '24:'){
		GET_BUFFER_STRING(pStartTime,2)
		pStartTime = "'00',pStartTime"
	}
	IF(LEFT_STRING(pEndTime,3) = '24:'){
		GET_BUFFER_STRING(pEndTime,2)
		pEndTime = "'00',pEndTime"
	}
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNowStart),     ',0,',pStartTime"//fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT].START_TIME,3)"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNowEnd),       ',0,',pEndTime"//fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT].END_TIME,3)"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNowDuration),  ',0,',fnSecondsToDurationText(myRoom.SLOTS[myRoom.SLOT_CURRENT].DURATION_SECS,0)"
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNowRemaining), ',0,',fnSecondsToDurationText(myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS,0)"//2)"

	// Populate Now Organiser
	IF(!myRoom.SLOTS[myRoom.SLOT_CURRENT].isQUICKBOOK && !myRoom.SLOTS[myRoom.SLOT_CURRENT].isAUTOBOOK){
		SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addNowOrganiser),',0,',WC_TP_ENCODE(myRoom.SLOTS[myRoom.SLOT_CURRENT].ORGANISER)"
	}
	ELSE{
		SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addNowOrganiser),',0,',WC_TP_ENCODE(myRoom.SLOTS[myRoom.SLOT_CURRENT].SUBJECT)"
	}

	// Send Diagnostics Details - Meeting Remaining Limits
	SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(lvlMeetingRemain),',0,%GL0%GH',ITOA(myRoom.SLOTS[myRoom.SLOT_CURRENT].DURATION_MINS)"

	// Send Diagnostics Details - Meeting Remaining Timer Value
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlMeetingRemain),',0,',fnSecondsToDurationText(myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_SECS,2)"

	IF(myRoom.SLOTS[myRoom.SLOT_CURRENT+1].END_REF){
		SEND_COMMAND tp[pPanel],"'^SHO-61.66,1'"
		// Populate Next Subject
		SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addNextSubject),  ',0,',WC_TP_ENCODE(myRoom.SLOTS[myRoom.SLOT_CURRENT+1].SUBJECT)"
		SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addNextOrganiser),',0,',WC_TP_ENCODE(myRoom.SLOTS[myRoom.SLOT_CURRENT+1].ORGANISER)"

	pStartTime = fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT+1].START_TIME,3)
	pEndTime   = fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT+1].END_TIME,3)
	IF(LEFT_STRING(pStartTime,3) = '24:'){
		GET_BUFFER_STRING(pStartTime,2)
		pStartTime = "'00',pStartTime"
	}
	IF(LEFT_STRING(pEndTime,3) = '24:'){
		GET_BUFFER_STRING(pEndTime,2)
		pEndTime = "'00',pEndTime"
	}
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNextStart),    ',0,',pStartTime"//fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT+1].START_TIME,3)"
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNextEnd),      ',0,',pEndTime"//fnStripCharsRight( myRoom.SLOTS[myRoom.SLOT_CURRENT+1].END_TIME,3)"
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addNextDuration), ',0,',fnSecondsToDurationText(myRoom.SLOTS[myRoom.SLOT_CURRENT+1].DURATION_SECS,0)"
		fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanel(','pPanel=',ITOA(pPanel),')'","'next pStartTime = ',pStartTime")
		fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanel(','pPanel=',ITOA(pPanel),')'","'next pEndTime = ',  pEndTime")
	}
	ELSE{
		SEND_COMMAND tp[pPanel],"'^SHO-61.66,0'"
	}

	// Populate Quick Book End Time
	IF(myRMSPanel[pPanel].MODE == MODE_QUICKBOOK){
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addQuickBookInstDur),',0,Until ',fnStripCharsRight(myRoom.QUICKBOOK_END_TIME,3)"
	}

	// Populate the Cal Popup
	fnPopulateCalView(pPanel)

	// Setup LEDs
	fnUpdateLEDs(pPanel)

	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanel(','pPanel=',ITOA(pPanel),')'",'--> Done')
}
//changes the LED's on the pannel and the background border to match
DEFINE_FUNCTION fnUpdateLEDs(INTEGER pPanel){
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdateLED(','pPanel=',ITOA(pPanel),')'",'<-- Called')
	// Loop if all panels
	IF(pPanel == 0){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnUpdateLEDs(p)
		}
		RETURN
	}

	// Check against Mode and if RMS has returned values yet
	IF(myRMSPanel[pPanel].MODE == MODE_SENSOR){
		SWITCH([vdvRoom,chn_vdv_RoomOccupied]){
			CASE TRUE: fnSetLEDs(pPanel,LED_STATE_RED)
			CASE FALSE:fnSetLEDs(pPanel,LED_STATE_GREEN)
		}
	}
	ELSE IF(!myRoom.SLOT_CURRENT || myRMSPanel[pPanel].MODE == MODE_NAME){
		fnSetLEDs(pPanel,LED_STATE_OFF)
	}
	ELSE{
		SWITCH(myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX){
			CASE 0:	fnSetLEDs(pPanel,LED_STATE_GREEN)
			DEFAULT: fnSetLEDs(pPanel,LED_STATE_RED)
		}
	}
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdateLED(','pPanel=',ITOA(pPanel),')'",'--> Done')
}

DEFINE_FUNCTION fnSetLEDs(INTEGER pPanel, INTEGER pState){
	SWITCH(pState){
		CASE LED_STATE_OFF:{
			SEND_COMMAND tp[pPanel], "'^WLD-0,0'"	// Red LED OFF
			SEND_COMMAND tp[pPanel], "'^WLD-2,0'"	// Green LED OFF
			SEND_LEVEL   tp[pPanel],lvlRoomState,1
		}
		CASE LED_STATE_GREEN:{
			SEND_COMMAND tp[pPanel], "'^WLD-0,0'"	// Red LED OFF
			SEND_COMMAND tp[pPanel], "'^WLD-2,1'"	// Green LED ON
			SEND_LEVEL   tp[pPanel],lvlRoomState,2
		}
		CASE LED_STATE_RED:{
			SEND_COMMAND tp[pPanel], "'^WLD-0,1'"	// Red LED ON
			SEND_COMMAND tp[pPanel], "'^WLD-2,0'"	// Green LED OFF
			SEND_LEVEL   tp[pPanel],lvlRoomState,3
		}
	}
}



//hides/shows overlays
DEFINE_FUNCTION fnSetupOverlay(INTEGER pPanel, INTEGER pOVERLAY){
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnSetupOverlay(','pPanel=',ITOA(pPanel),',pOVERLAY=',ITOA(pOVERLAY),')'",'<-- Called')
	IF(pPanel == 0){
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(tp); x++){
			fnSetupOverlay(x,pOVERLAY)
		}
		RETURN
	}

	IF(pOVERLAY != OVERLAY_NONE && myRMSPanel[pPanel].OVERLAY == OVERLAY_NONE){
		SEND_COMMAND tp[pPanel],"'@PPN-overlayBaseRoomBook;',		myRMSPanel[pPanel].PAGE"
	}

	SWITCH(pOVERLAY){
		CASE OVERLAY_NONE:{
			SEND_COMMAND tp[pPanel],"'@PPF-overlayRoomBookQuickBook;',		myRMSPanel[pPanel].PAGE"
			SEND_COMMAND tp[pPanel],"'@PPF-overlayBaseRoomBook;',		myRMSPanel[pPanel].PAGE"
		}
		CASE OVERLAY_QUICK:{
			myRMSPanel[pPanel].SUBJECT = myRoom.QUICKBOOK_SUBJECT
			fnUpdatePanelQuickBook(pPanel)
			myRMSPanel[pPanel].QUICK_DURATION = myRoom.QUICKBOOK_MINIMUM
			SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addQuickBookDuration),',0,',ITOA(myRMSPanel[pPanel].QUICK_DURATION)"

			SEND_COMMAND tp[pPanel],"'@PPN-overlayRoomBookQuickBook;',		myRMSPanel[pPanel].PAGE"
		}
		CASE OVERLAY_CALVIEW:{
			SEND_COMMAND tp[pPanel],"'@PPN-overlayRoomBookCalendar;',  myRMSPanel[pPanel].PAGE"
			// Centre View
			SEND_COMMAND tp[pPanel],"'^SSH-',ITOA(addSlot),',bookSlot',FORMAT('%02d',myRoom.SLOT_CURRENT)"
		}
		CASE OVERLAY_EXTEND:{
			myRMSPanel[pPanel].EXTEND_DURATION = myRoom.QUICKBOOK_MINIMUM
			SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addExtendDuration),',0,',ITOA(myRMSPanel[pPanel].EXTEND_DURATION)"
			SEND_COMMAND tp[pPanel],"'@PPN-overlayRoomBookExtend;',	myRMSPanel[pPanel].PAGE"
		}
		CASE OVERLAY_MESSAGE: SEND_COMMAND tp[pPanel],"'@PPN-overlayRoomBookMessage;',  myRMSPanel[pPanel].PAGE"
		CASE OVERLAY_DIAG: 	 SEND_COMMAND tp[pPanel],"'@PPN-overlayRoomBookDiagnostics;',  myRMSPanel[pPanel].PAGE"
	}

	// Timeout the Overlay
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT_OVERLAYS)){ TIMELINE_KILL(TLID_TIMEOUT_OVERLAYS) }
	IF(pOVERLAY != OVERLAY_NONE){
		TIMELINE_CREATE(TLID_TIMEOUT_OVERLAYS,TLT_OLAY_TIMEOUT,LENGTH_ARRAY(TLT_OLAY_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLT_OLAY_TIMEOUT','<-- Created')
	}

	// Store Value
	myRMSPanel[pPanel].OVERLAY = pOVERLAY

	fnDebug(DEBUG_DEV,'FUNCTION',"'fnSetupOverlay(','pPanel=',ITOA(pPanel),',pOVERLAY=',ITOA(pOVERLAY),')'",'--> Done')
}

// updates the booking response pop-up when creating/updating
DEFINE_FUNCTION fnDisplayStatusMessage(CHAR pMsg[], CHAR pMsgDetail[50]){
	STACK_VAR CHAR pTempMsg[64]
	STACK_VAR CHAR pTempMsgDetail[64]
	// Debugging
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnDisplayStatusMessage(','pMsg=',pMsg,',pMsgDetail=',pMsgDetail,')'",'<-- Called')

	IF(UPPER_STRING(pMsg) == 'BOOKING DECLINED'){
		pTempMsg = pMsg
	}
	ELSE IF(UPPER_STRING(pMsg) == 'BOOKING'){
		pTempMsg = pMsgDetail
	}
	ELSE IF(UPPER_STRING(pMsg) == 'QUICK BOOK'){
		pTempMsg = pMsgDetail
		pTempMsgDetail = pMsg
	}
	ELSE{
		pTempMsg = pMsg
		pTempMsgDetail = pMsgDetail
	}
	IF(myRoom.PAGE_DETAILS == DETAILS_ON){
		// Show details
	}
	ELSE{
		pTempMsgDetail = ''//Don't show details
	}
//	IF(pTempMsg == pTempMsgDetail){
//		pTempMsgDetail = ''
//	}
	// Set Message and show
   SEND_COMMAND tp,"'^TXT-',ITOA(addMessage),',0,',pTempMsg"
   SEND_COMMAND tp,"'^TXT-',ITOA(addMessageDetail),',0,',pTempMsgDetail"
	fnSetupOverlay(0,OVERLAY_MESSAGE)

	// Debugging
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnDisplayStatusMessage(','pMsg=',pTempMsg,',pMsgDetail=',pTempMsgDetail,')'",'--> Done')
}

// updates the text on the keyboard in line with keyboard array. Num/letters
DEFINE_FUNCTION fnUpdateKeyboard(INTEGER pPanel, INTEGER state){
	INTEGER x
	FOR(x=1; x<=LENGTH_ARRAY(btnKeyboard); x++){
		SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(btnKeyboard[x]),',0,',keyboard[state+1][x]"
	}
}

//add text to the input string on the keyboard for quick book
DEFINE_FUNCTION fnUpdatePanelQuickBook(INTEGER pPanel){
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanelQuickBook(','pPanel=',ITOA(pPanel),')'",'<-- Called')
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addQuickBookSubject),',0,',myRMSPanel[pPanel].SUBJECT"
	SEND_COMMAND tp[pPanel],"'^SHO-',ITOA(btnQuickBook),',',ITOA(LENGTH_ARRAY(myRMSPanel[pPanel].SUBJECT) > 0)"
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnUpdatePanelQuickBook(','pPanel=',ITOA(pPanel),')'",'--> Done')
}

DEFINE_FUNCTION fnPopulateCalView(INTEGER pPanel){
	STACK_VAR INTEGER x
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnPopulateCalView(','pPanel=',ITOA(pPanel),')'",'<-- Called')
	FOR(x = 1; x <= _MAX_SLOTS; x++){
		IF(myRMSPanel[pPanel].CAL_SLOT_STATE[x]){
			SEND_COMMAND tp[pPanel], "'^SHD-',ITOA(addSlot),',bookSlot',FORMAT('%02d',x)"
			myRMSPanel[pPanel].CAL_SLOT_STATE[x] = FALSE
		}
	}
	FOR(x = _MAX_SLOTS; x >= 1; x--){
		IF(myRoom.SLOTS[x].END_REF){
			// Show Slot
			SEND_COMMAND tp[pPanel], "'^SSH-',ITOA(addSlot),',bookSlot',FORMAT('%02d',x)"
			myRMSPanel[pPanel].CAL_SLOT_STATE[x] = TRUE

			// Populate Values
			SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addSlotStart+x),',0,',fnStripCharsRight(myRoom.SLOTS[x].START_TIME,3)"
			SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addSlotEnd+x),',0,',fnStripCharsRight(myRoom.SLOTS[x].END_TIME,3)"


			SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addSlotSUBJECT+x),  ',0,',WC_TP_ENCODE(myRoom.SLOTS[x].SUBJECT)"
			SEND_COMMAND tp[pPanel],"'^UNI-',ITOA(addSlotName+x),  ',0,',WC_TP_ENCODE(myRoom.SLOTS[x].ORGANISER)"

			// Set ON/OFF meeting FB
			[tp[pPanel],addSlot+x] = (myRoom.SLOTS[x].BOOKING_INDEX)

			// Fade out Past
			IF(fnTimeToSeconds(TIME) > myRoom.SLOTS[x].END_REF){
				SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(addSlot+x),',0,%OP150'"
			}
			ELSE{
				SEND_COMMAND tp[pPanel],"'^BMF-',ITOA(addSlot+x),',0,%OP255'"
			}
		}
	}
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnPopulateCalView(','pPanel=',ITOA(pPanel),')'",'--> Done')
}

DEFINE_FUNCTION fnSetPanelMode(INTEGER pPanel,CHAR pMODE[20]){
	fnDebug(DEBUG_DEV,'FUNCTION',"'fnSetPanelMode(','pPanel=',ITOA(pPanel),',pMODE=',pMODE,')'",'<-- Called')

	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSetPanelMode(p,pMODE)
		}
		RETURN
	}

	// Set the Panel Mode Variable
	SWITCH(pMODE){
		CASE 'NAME':   	myRMSPanel[pPanel].MODE = MODE_NAME
		CASE 'SENSOR':		myRMSPanel[pPanel].MODE = MODE_SENSOR
		CASE 'DIARY':		myRMSPanel[pPanel].MODE = MODE_DIARY
		CASE 'QUICKBOOK':	myRMSPanel[pPanel].MODE = MODE_QUICKBOOK
	}

	fnDebug(DEBUG_DEV,'FUNCTION','fnSetPanelMode','--> Done')
}
/********************************************************************************************************************************************************************************************************************************************************
	Feedback
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_PROGRAM{
	// Virtual Device

	// Occupancy Sensor Feedback
	SEND_LEVEL vdvRoom,chn_vdv_RoomOccupied,myRoom.OCCUPANCY_TIMEOUT.COUNTER		// Occupied Countdown
	[vdvRoom,chn_vdv_RoomOccupied] = myRoom.OCCUPANCY_TIMEOUT.COUNTER	// Occupied Flag

	// Room Release Feedback
	SEND_LEVEL vdvRoom,lvl_vdv_Timer_NoShow,myRoom.NOSHOW_TIMEOUT.COUNTER						// Release Countdown Value


	// Online Feedback for Virtual Device
	[vdvRoom,251] = TRUE
	[vdvRoom,252] = TRUE

	// Interface

	// Language Feedback
	SEND_LEVEL tp,lvlLangFeedback, myRoom.LANGUAGE

	// Set Feedback if Timers are Active
	[tp,lvlRoomOccupied]   			= (TIMELINE_ACTIVE(TLID_TIMER_OCCUPANCY_TIMEOUT))
	[tp,lvlNoShowTimer]    			= (TIMELINE_ACTIVE(TLID_TIMER_NOSHOW_TIMEOUT))
	[tp,lvlQuickBookStandoffTimer]= (TIMELINE_ACTIVE(TLID_TIMER_QUICKBOOK_TIMEOUT))
	[tp,lvlAutoBookActionTimer]  	= (TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_ACTION))
	[tp,lvlAutoBookStandOffTimer] = (TIMELINE_ACTIVE(TLID_TIMER_AUTOBOOK_STANDOFF))

	// Send Levels to Panel
	SEND_LEVEL tp,lvlRoomOccupied,myRoom.OCCUPANCY_TIMEOUT.COUNTER
	SEND_LEVEL tp,lvlNoShowTimer,myRoom.NOSHOW_TIMEOUT.COUNTER
	SEND_LEVEL tp,lvlQuickBookStandoffTimer,myRoom.QUICKBOOK_TIMEOUT.COUNTER
	SEND_LEVEL tp,lvlAutoBookActionTimer,myRoom.AUTOBOOK_ACTION.COUNTER
	SEND_LEVEL tp,lvlAutoBookStandOffTimer,myRoom.AUTOBOOK_STANDOFF.COUNTER

	// Set Feedback Channels
	[tp,btnDiagStateSensorTrigger] 	= [vdvRoom,chn_vdv_SensorTriggered]
	[tp,btnDiagStateSensorOnline] 	= [vdvRoom,chn_vdv_SensorOnline]
	[tp,btnDiagStateRoomOccupied] 	= [vdvRoom,chn_vdv_RoomOccupied]

	// Panel Button Feedback
	IF(!myRoom.SLOTS_LOADING){
		IF(myRoom.SLOT_CURRENT){
		// Feedback on Active Meeting
			SEND_LEVEL vdvRoom,lvl_vdv_SlotRemain,myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_MINS
			[vdvRoom,chn_vdv_SlotBooked] = (myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX)
			[tp,btnNowBooked]  = (myRoom.SLOTS[myRoom.SLOT_CURRENT].BOOKING_INDEX)
			[tp,btnNextBooked] = (myRoom.SLOTS[myRoom.SLOT_CURRENT+1].BOOKING_INDEX)
			SEND_LEVEL tp,lvlMeetingRemain,myRoom.SLOTS[myRoom.SLOT_CURRENT].REMAIN_MINS
		}
		[tp,btnDiagStateRoomBooked] 		= [vdvRoom,chn_vdv_SlotBooked]
	}
	// Is Location Name Set
	[tp,3999] = (LENGTH_ARRAY(myRoom.LOC_NAME))
	// Standard Comms
	[tp,4000] = (TRUE)
}
/********************************************************************************************************************************************************************************************************************************************************
	End Of File
********************************************************************************************************************************************************************************************************************************************************/
