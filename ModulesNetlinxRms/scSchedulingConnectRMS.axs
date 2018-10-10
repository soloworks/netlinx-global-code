MODULE_NAME='scSchedulingConnectRMS'(DEV vdvRMSNetlinx, DEV vdvRMSDuet, DEV vdvRoom[], DEV tpRMS[][])
INCLUDE 'CustomFunctions'
INCLUDE 'UnicodeLib'
/********************************************************************************************************************************************************************************************************************************************************
	Bespoke simplified RMS Room Booking panel control
	All AMX control stripped out and re-coded

	This module handles the communications from RMS and sends it on to the
	registered room.

	Channels on Room Virtual Device:
	1 - Sensor State (Fed from main program)
	2 - Occupancy State (Derived from 1 via module)
	3 - Meeting Currently Active

	Levels on Virtual Device
	1 - Occupancy State Countdown
********************************************************************************************************************************************************************************************************************************************************/

/********************************************************************************************************************************************************************************************************************************************************
	Constants
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_CONSTANT
LONG TLID_GET_BOOKINGS_00 = 1000
LONG TLID_GET_BOOKINGS_01 = 1001
LONG TLID_GET_BOOKINGS_02 = 1002
LONG TLID_GET_BOOKINGS_03 = 1003
LONG TLID_GET_BOOKINGS_04 = 1004
LONG TLID_GET_BOOKINGS_05 = 1005
LONG TLID_GET_BOOKINGS_06 = 1006
LONG TLID_GET_BOOKINGS_07 = 1007
LONG TLID_GET_BOOKINGS_08 = 1008
LONG TLID_GET_BOOKINGS_09 = 1009
LONG TLID_GET_BOOKINGS_10 = 1010
LONG TLID_GET_BOOKINGS_11 = 1011
LONG TLID_GET_BOOKINGS_12 = 1012
LONG TLID_GET_BOOKINGS_13 = 1013
LONG TLID_GET_BOOKINGS_14 = 1014
LONG TLID_GET_BOOKINGS_15 = 1015
LONG TLID_GET_BOOKINGS_16 = 1016
LONG TLID_GET_BOOKINGS_17 = 1017
LONG TLID_GET_BOOKINGS_18 = 1018
LONG TLID_GET_BOOKINGS_19 = 1019
LONG TLID_GET_BOOKINGS_20 = 1020
LONG TLID_GET_BOOKINGS_21 = 1021
LONG TLID_GET_BOOKINGS_22 = 1022
LONG TLID_GET_BOOKINGS_23 = 1023
LONG TLID_GET_BOOKINGS_24 = 1024
// Imported from RMS API for their structures
INTEGER RMS_MAX_DATE_TIME_LEN       = 10
INTEGER RMS_MAX_PARAM_LEN           = 250

// RMS Custom Event Addresses
RMS_CUSTOM_EVENT_ADDRESS_CLIENT           					= 1;
RMS_CUSTOM_EVENT_ADDRESS_LOCATION        						= 2;
RMS_CUSTOM_EVENT_ADDRESS_ASSET            					= 3;
RMS_CUSTOM_EVENT_ADDRESS_DISPLAY_MESSAGE  					= 4;
RMS_CUSTOM_EVENT_ADDRESS_SERVICE_PROVIDER 					= 5;
RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING    					= 6;

// RMS Custom Event IDs - Server Initiated
RMS_EVENT_BOOKING_STARTED                     = 1;
RMS_EVENT_BOOKING_ENDED                       = 2;
RMS_EVENT_BOOKING_EXTENDED                    = 3;
RMS_EVENT_BOOKING_cancelled                    = 4;
RMS_EVENT_BOOKING_CREATED                     = 5;
RMS_EVENT_BOOKING_UPDATED                     = 6;
RMS_EVENT_BOOKING_MONTHLY_SUMMARY_UPDATED		= 7;
RMS_EVENT_BOOKING_ACTIVE_UPDATED              = 8;
RMS_EVENT_BOOKING_NEXT_ACTIVE_UPDATED         = 9;
RMS_EVENT_BOOKING_DAILY_COUNT                 = 10;

// RMS Custom Event IDs - Response to Clue
RMS_EVENT_BOOKING_ACTIVE_RESPONSE             = 30;
RMS_EVENT_BOOKING_cancelled_RESPONSE           = 31;
RMS_EVENT_BOOKING_CREATED_RESPONSE            = 32;
RMS_EVENT_BOOKING_ENDED_RESPONSE              = 33;
RMS_EVENT_BOOKING_EXTENDED_RESPONSE           = 34;
RMS_EVENT_BOOKING_INFORMATION_RESPONSE        = 35;
RMS_EVENT_BOOKING_NEXT_ACTIVE_RESPONSE        = 36;
RMS_EVENT_BOOKING_RECORD_RESPONSE             = 37;
RMS_EVENT_BOOKING_SUMMARIES_DAILY_RESPONSE    = 38;
RMS_EVENT_BOOKING_SUMMARY_DAILY_RESPONSE      = 39;

// Module Maximums
INTEGER _MAX_BOOKINGS 	= 50			// Max number of actual meetings

// Constant to represent '00:00:00' at end of day (As it appears twice in 24hr clock)
LONG		MIDNIGHT_SECS	= 24*60*60

// Debug Values
INTEGER DEBUG_ERR				= 0
INTEGER DEBUG_STD				= 1
INTEGER DEBUG_DEV				= 2
INTEGER DEBUG_LOG				= 3

/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Original AMX API
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE RmsEventBookingDailyCount{
   LONG    location;
   INTEGER dayOfMonth;
   INTEGER bookingCount;
   INTEGER recordCount;
   INTEGER recordNumber;
}
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Modified AMX API (Handles WideChar in UTF Charset: Worked out by inspecting raw data)
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uRmsBookRespOriginal{
    WIDECHAR bookingId[RMS_MAX_PARAM_LEN];
    LONG     location;
    CHAR     isPrivateEvent;
    WIDECHAR startDate[RMS_MAX_DATE_TIME_LEN];
    WIDECHAR startTime[RMS_MAX_DATE_TIME_LEN];
    WIDECHAR endDate[RMS_MAX_DATE_TIME_LEN];
    WIDECHAR endTime[RMS_MAX_DATE_TIME_LEN];
    WIDECHAR subject[RMS_MAX_PARAM_LEN];
    WIDECHAR details[RMS_MAX_PARAM_LEN];
    WIDECHAR clientGatewayUid[RMS_MAX_PARAM_LEN];
    CHAR     isAllDayEvent;
    WIDECHAR organizer[RMS_MAX_PARAM_LEN];
    LONG     elapsedMinutes;								// Only used for active booking events
    LONG     minutesUntilStart;							// Only used for next active booking events
    LONG     remainingMinutes;							// Only used for active booking events
    WIDECHAR onBehalfOf[RMS_MAX_PARAM_LEN];
    WIDECHAR attendees[RMS_MAX_PARAM_LEN];			// Not used in some contexts such as adhoc creation
    CHAR     isSuccessful;
    WIDECHAR failureDescription[RMS_MAX_PARAM_LEN];// Not used if result is from a successful event
    LONG     totalAttendeeCount;							// In some cases attendee names may be truncated
    																// due to the length, totalAttendeeCount is helpful
    																// to indicate the total number of attendees
}
DEFINE_TYPE STRUCTURE uRmsBookResp{
    CHAR     bookingId[RMS_MAX_PARAM_LEN];
    LONG     location;
    CHAR     isPrivateEvent;
    CHAR     startDate[RMS_MAX_DATE_TIME_LEN];
    CHAR     startTime[RMS_MAX_DATE_TIME_LEN];
    CHAR     endDate[RMS_MAX_DATE_TIME_LEN];
    CHAR     endTime[RMS_MAX_DATE_TIME_LEN];
    WIDECHAR subject[RMS_MAX_PARAM_LEN];
    WIDECHAR details[RMS_MAX_PARAM_LEN];
    CHAR     clientGatewayUid[RMS_MAX_PARAM_LEN];
    CHAR     isAllDayEvent;
    WIDECHAR organizer[RMS_MAX_PARAM_LEN];
    LONG     elapsedMinutes;								// Only used for active booking events
    LONG     minutesUntilStart;							// Only used for next active booking events
    LONG     remainingMinutes;							// Only used for active booking events
    WIDECHAR onBehalfOf[RMS_MAX_PARAM_LEN];
    WIDECHAR attendees[RMS_MAX_PARAM_LEN];			// Not used in some contexts such as adhoc creation
    CHAR     isSuccessful;
    CHAR     failureDescription[RMS_MAX_PARAM_LEN];// Not used if result is from a successful event
    LONG     totalAttendeeCount;							// In some cases attendee names may be truncated
    																// due to the length, totalAttendeeCount is helpful
    																// to indicate the total number of attendees
}
DEFINE_FUNCTION fnGetCleanBookingResponse(CHAR encode[10000],uRmsBookResp pResp){

	STACK_VAR uRmsBookRespOriginal myRmsEventBookingResponse

	fnDebug(DEBUG_DEV,vdvRMSDuet,'fnGetCleanBookingResponse','Called')

	STRING_TO_VARIABLE(myRmsEventBookingResponse,encode,1)

	pResp.bookingId 				= WC_TO_CH(myRmsEventBookingResponse.bookingId)
	pResp.location 				= myRmsEventBookingResponse.location
	pResp.isPrivateEvent 		= myRmsEventBookingResponse.isPrivateEvent
	pResp.isAllDayEvent 			= myRmsEventBookingResponse.isAllDayEvent
	pResp.elapsedMinutes 		= myRmsEventBookingResponse.elapsedMinutes
	pResp.minutesUntilStart 	= myRmsEventBookingResponse.minutesUntilStart
	pResp.remainingMinutes 		= myRmsEventBookingResponse.remainingMinutes
	pResp.isSuccessful 			= myRmsEventBookingResponse.isSuccessful
	pResp.totalAttendeeCount 	= myRmsEventBookingResponse.totalAttendeeCount
	pResp.subject	 				= myRmsEventBookingResponse.subject
	pResp.details 		   		= myRmsEventBookingResponse.details
	pResp.organizer 		    	= myRmsEventBookingResponse.organizer
	pResp.onBehalfOf 	  	   	= myRmsEventBookingResponse.onBehalfOf
	pResp.attendees   			= myRmsEventBookingResponse.attendees

	pResp.startDate 				= WC_TO_CH(myRmsEventBookingResponse.startDate)
	pResp.startTime 				= WC_TO_CH(myRmsEventBookingResponse.startTime)
	pResp.endDate 					= WC_TO_CH(myRmsEventBookingResponse.endDate)
	pResp.endTime 					= WC_TO_CH(myRmsEventBookingResponse.endTime)
	pResp.clientGatewayUid 		= WC_TO_CH(myRmsEventBookingResponse.clientGatewayUid)
	pResp.failureDescription   = WC_TO_CH(myRmsEventBookingResponse.failureDescription)

	fnDebug(DEBUG_DEV,vdvRMSDuet,'fnGetCleanBookingResponse','Done')

}
/********************************************************************************************************************************************************************************************************************************************************
	Data Structure - Internal Main Module Data
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_TYPE STRUCTURE uRoom{
	CHAR           ROOM_NAME[50]           // Room Name as supplied from Config File
	INTEGER 			LOC_ID						// RMS Supplied Location ID
	CHAR   			LOC_NAME[50]				// RMS Supplied Location Name

	// Timers and Occupancy
	LONG 				OCCUPANCY_TIMER					// Current occupied timer
	LONG 				OCCUPANCY_TIMEOUT				// Time to consider room Occupied after movement

	// No Show Settings
	INTEGER        NOSHOW_ACTIVE
	LONG 				NOSHOW_TIMER					// Mins to wait before checking Occ State and cancelling (0 = Never)
	LONG 				NOSHOW_TIMEOUT					// Mins to wait before checking Occ State and cancelling (0 = Never)
	LONG				NOSHOW_MAXIMUM					// Meetings longer than this will not be cancelled

	// Quick Booking Settings
	INTEGER        QUICKBOOK_ACTIVE
	LONG 				QUICKBOOK_STANDOFF_TIMER	// Countdown until Inactivity Trigger (Not occupancy)
	LONG           QUICKBOOK_STANDOFF_TIMEOUT	// Time to delay meeting ending logic
	LONG 				QUICKBOOK_MINIMUM				// Dictates max no of free mins before hiding Quick Book pane
	LONG				QUICKBOOK_MAXIMUM				//
	LONG				QUICKBOOK_STEP					// Rounding for Quick Book - Valid Values: 5,10,15,20,30

	// Auto Booking Settings
	INTEGER        AUTOBOOK_ACTIVE
	LONG 				AUTOBOOK_ACTION_TIMER		// Current auto book timer
	INTEGER 			AUTOBOOK_ACTION_TIMEOUT		// Dictates max no of free mins before hiding Quick Book pane
	LONG 				AUTOBOOK_STANDOFF_TIMER		// Current auto book timer
	INTEGER 			AUTOBOOK_STANDOFF_TIMEOUT	// Dictates max no of free mins before hiding Quick Book pane
	INTEGER			AUTOBOOK_EVENTS_TARGET		// Total Ticks to consider constant movement

	INTEGER        BOOKING_COUNT
}

DEFINE_TYPE STRUCTURE uSystem{
	// System Info
	uRoom   ROOM[24]		  // Room Instance Data
	INTEGER DEBUG			  // Debugging
	CHAR    RMS_SYSREF[50] // RMS System Name
	CHAR    RMS_HOST[255]  // RMS Host Name
}

/********************************************************************************************************************************************************************************************************************************************************
	Variables - General

********************************************************************************************************************************************************************************************************************************************************/
DEFINE_VARIABLE
VOLATILE uSystem 	      myConnectRMS			// Module Data Structure
// Bookings Infomation - seperated to stop debugger exploding
VOLATILE uRmsBookResp	BOOKING[24][_MAX_BOOKINGS]	// Room Bookings

LONG TLT_GET_BOOKINGS_SHORT[] = {   2500 }	// Delay to get bookings (prevents multiple requests in rapid succession)
LONG TLT_GET_BOOKINGS_LONG[] 	= { 150000 }
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

	DEBUG_LOG_FILENAME = "'DEBUG_LOG_scRoomBookRMSConn_',ITOA(vdvRMSNetlinx.Number),'_',pTIMESTAMP,'.log'"
	fnDebug(DEBUG_LOG,vdvRMSNetlinx,'fnInitateLogFile',"'File Created',pTIMESTAMP")
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,DEV dvOrigin, CHAR pRef[],CHAR pData[]){
	// Check the requested debug against the current module setting
	IF(myConnectRMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR dbgMsg[255]
		dbgMsg = "ITOA(dvOrigin.Number),'|RMSConnect|',pRef,'|',pData"
		// Send to diagnostics screen
		SEND_STRING 0:0:0, dbgMsg
		// Log to file if required
		IF(myConnectRMS.DEBUG == DEBUG_LOG){
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

DEFINE_FUNCTION fnDebugBooking(INTEGER pDebug,SLONG Index, SLONG Total, uRmsBookResp b){
	// Check the requested debug against the current module setting
	IF(myConnectRMS.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "'RmsBook  [index] ',FORMAT('%02d',Index),':',FORMAT('%02d',Total)"
		SEND_STRING 0:0:0, "'RmsBook     [id] ',b.bookingId"
		SEND_STRING 0:0:0, "'RmsBook  [Start] ',b.startDate,',',b.startTime"
		SEND_STRING 0:0:0, "'RmsBook    [End] ',b.endDate,',',b.endTime"
		SEND_STRING 0:0:0, "'RmsBook    [sub] ',WC_TO_CH(b.subject)"
		SEND_STRING 0:0:0, "'RmsBook    [org] ',WC_TO_CH(b.organizer)"
		SEND_STRING 0:0:0, "'RmsBook [AllDay] ',fnGetBooleanString(b.isAllDayEvent)"
		SEND_STRING 0:0:0, "'RmsBook   [Priv] ',fnGetBooleanString(b.isPrivateEvent)"
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Netlinx Data Events
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvRoom]{
	COMMAND:{
		STACK_VAR INTEGER r
		r = GET_LAST(vdvRoom)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'OCCUPANCY':{
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].OCCUPANCY_TIMEOUT          = ATOI(fnGetCSV(DATA.TEXT,1))
					}
					CASE 'NOSHOW':{
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].NOSHOW_ACTIVE              = TRUE
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].NOSHOW_TIMEOUT             = ATOI(fnGetCSV(DATA.TEXT,1))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].NOSHOW_MAXIMUM             = ATOI(fnGetCSV(DATA.TEXT,2))
					}
					CASE 'QUICKBOOK':{
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].QUICKBOOK_ACTIVE           = TRUE
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].QUICKBOOK_STANDOFF_TIMEOUT = ATOI(fnGetCSV(DATA.TEXT,1))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].QUICKBOOK_MINIMUM          = ATOI(fnGetCSV(DATA.TEXT,2))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].QUICKBOOK_MAXIMUM          = ATOI(fnGetCSV(DATA.TEXT,3))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].QUICKBOOK_STEP             = ATOI(fnGetCSV(DATA.TEXT,4))
					}
					CASE 'AUTOBOOK':{
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].AUTOBOOK_ACTIVE           = TRUE
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].AUTOBOOK_STANDOFF_TIMEOUT = ATOI(fnGetCSV(DATA.TEXT,1))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].AUTOBOOK_ACTION_TIMEOUT   = ATOI(fnGetCSV(DATA.TEXT,2))
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].AUTOBOOK_EVENTS_TARGET    = ATOI(fnGetCSV(DATA.TEXT,3))
					}
					CASE 'ROOMNAME':{
						myConnectRMS.ROOM[GET_LAST(vdvRoom)].ROOM_NAME = DATA.TEXT
					}
				}
			}
			CASE 'ACTION':{
				SWITCH(fnGetCSV(DATA.TEXT,1)){
					CASE 'RESET':{
						fnResetRoom(GET_LAST(vdvRoom))
					}
					CASE 'CREATE':{
						// Local Variables
						STACK_VAR CHAR ToSend[300]
						// Build Message
						ToSend = 'SCHEDULING.BOOKING.CREATE-'
						// Add Start Date
						ToSend = "ToSend,LDATE"
						// Add Start Time
						ToSend = "ToSend,',',fnGetCSV(DATA.TEXT,3)"
						// Add Duration (Mins
						ToSend = "ToSend,',',ITOA((fnTimeToSeconds(fnGetCSV(DATA.TEXT,4))-fnTimeToSeconds(fnGetCSV(DATA.TEXT,3)))/60)"
						// Add Subject
						ToSend = "ToSend,',',fnGetCSV(DATA.TEXT,2)"
						// Add Body
						ToSend = "ToSend,',AMX Created Meeting: ',fnGetCSV(DATA.TEXT,2)"
						// Add LocationID
						ToSend = "ToSend,',',ITOA(myConnectRMS.ROOM[GET_LAST(vdvRoom)].LOC_ID)"
						// Send Command
						SEND_COMMAND vdvRMSDuet,ToSend
					}

					CASE 'EXTEND':{
						// Local Variables
						STACK_VAR CHAR ToSend[300]
						// Build Message
						ToSend = 'SCHEDULING.BOOKING.EXTEND-'
						// Add BookingID to be extended
						ToSend = "ToSend,BOOKING[GET_LAST(vdvRoom)][ATOI(fnGetCSV(DATA.TEXT,2))].bookingId"
						// Add Extending Duration
						ToSend = "ToSend,',',fnGetCSV(DATA.TEXT,3)"
						// Add LocationID
						ToSend = "ToSend,',',ITOA(myConnectRMS.ROOM[GET_LAST(vdvRoom)].LOC_ID)"
						// Send Command
						SEND_COMMAND vdvRMSDuet,ToSend
					}

					CASE 'CANCEL':{
						// Local Variables
						STACK_VAR CHAR ToSend[300]
						// Build Message
						ToSend = 'SCHEDULING.BOOKING.END-'
						// Add BookingID to be Cancelled
						ToSend = "ToSend,BOOKING[GET_LAST(vdvRoom)][ATOI(fnGetCSV(DATA.TEXT,2))].bookingId"
						// Add LocationID
						ToSend = "ToSend,',',ITOA(myConnectRMS.ROOM[GET_LAST(vdvRoom)].LOC_ID)"
						// Send Command
						SEND_COMMAND vdvRMSDuet,ToSend
					}

					CASE 'OVERRIDE':{
						SWITCH(fnGetCSV(DATA.TEXT,2)){
							CASE 'NOSHOW':{
								fnUpdateStatusString(GET_LAST(vdvRoom),"'OverRide: NoShow'")
							}
						}
					}
				}
			}
		}
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Room Netlinx  Data Events
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvRMSNetlinx]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'HOST':   myConnectRMS.RMS_HOST   = DATA.TEXT
					CASE 'SYSREF': myConnectRMS.RMS_SYSREF = DATA.TEXT
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	myConnectRMS.DEBUG = DEBUG_STD
							CASE 'DEV':		myConnectRMS.DEBUG = DEBUG_DEV
							CASE 'LOG':		myConnectRMS.DEBUG = DEBUG_LOG
						}
						IF(myConnectRMS.DEBUG == DEBUG_LOG){
							fnInitateLogFile()
						}
					}
				}
			}
		}
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Duet Data Events
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvRMSDuet]{
	ONLINE:{
		fnDebug(DEBUG_DEV,vdvRMSDuet,'DATA_EVENT [ONLINE] vdvRMSDuet','Called')
		IF(myConnectRMS.RMS_HOST != ''){
			// System Reference is blank, fill it with the Serial Number
			IF(myConnectRMS.RMS_SYSREF == ''){
				STACK_VAR DEV_INFO_STRUCT sDeviceInfo
				DEVICE_INFO(0:1:0, sDeviceInfo)
				myConnectRMS.RMS_SYSREF = sDeviceInfo.SERIAL_NUMBER
			}
			// Set RMS Java module to use UniCode
			SEND_COMMAND DATA.DEVICE, "'CLIENT.CHARSET-UTF-16BE'"
			// Request Version
			SEND_COMMAND DATA.DEVICE, '?CLIENT.VERSION'
			// Set System Name
			SEND_COMMAND DATA.DEVICE, "'CONFIG.CLIENT.NAME-',myConnectRMS.RMS_SYSREF"
			// Set Host
			SEND_COMMAND DATA.DEVICE, "'CONFIG.SERVER.URL-',myConnectRMS.RMS_HOST"
			// Set password
			SEND_COMMAND DATA.DEVICE, "'CONFIG.SERVER.PASSWORD-password'"
			// Set Enabled
			SEND_COMMAND DATA.DEVICE, "'CONFIG.CLIENT.ENABLED-true'"
		}
		fnDebug(DEBUG_DEV,vdvRMSDuet,'DATA_EVENT [ONLINE] vdvRMSDuet','Finished')
	}
	COMMAND:{
		// Local variable to hold converted data
		STACK_VAR CHAR pDATA[1000]
		// Dev Debug Out
		fnDebug(DEBUG_DEV,vdvRMSDuet,'[DATA_EVENT][COMMAND]','Called')
		// Convert incoming from WCHAR to CHAR
		pDATA = WC_TO_CH(_WC(DATA.TEXT))
		fnDebug(DEBUG_DEV,vdvRMSDuet,'pDATA',pDATA)

		// Switch on Data
		SWITCH(pDATA){
			CASE 'ASSETS.REGISTER':{
				// This is a call for the assets to be registered, so loop through the declared room devices
				STACK_VAR INTEGER x
				FOR(x = 1; x <= LENGTH_ARRAY(vdvRoom); x++){
					IF(myConnectRMS.ROOM[x].ROOM_NAME != ''){
						// Register Asset Itself
						SEND_COMMAND DATA.DEVICE, "'ASSET.REGISTER.DEV-',DEVTOA(vdvRoom[x]),',Room Booking Status,',DEVTOA(vdvRoom[x]),',Utility,'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.MANUFACTURER-',DEVTOA(vdvRoom[x]),',AMX,www.amx.com'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.MODEL-',DEVTOA(vdvRoom[x]),',RMS Scheduling,'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.DESCRIPTION-',DEVTOA(vdvRoom[x]),',Virtual Room Device for Room Ref: ',myConnectRMS.ROOM[x].ROOM_NAME"
						SEND_COMMAND DATA.DEVICE, "'ASSET.SUBMIT-',DEVTOA(vdvRoom[x])"
						// Register Parameters - Occupancy
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',state.occupied,Occupied State,Logical state of Occupancy,BOOLEAN,NONE,',fnGetBooleanString([vdvRoom[x],4]),',,false,false,,,,true'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',level.occupied,Occupancy Timer,Time until occupancy flag expires,LEVEL,NONE,',ITOA(myConnectRMS.ROOM[x].OCCUPANCY_TIMER),',,false,false,0,',ITOA(myConnectRMS.ROOM[x].OCCUPANCY_TIMEOUT),',,true'"
						// Register Parameters - Current Meeting Info
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',state.meeting,Meeting Active,A meeting currently booked in the room,BOOLEAN,NONE,',fnGetBooleanString([vdvRoom[x],3]),',,false,false,,,,true'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',string.subject,Meeting Subject,Current Meeting Subject,STRING,NONE,,,false,false,,,,true'"
						// Register Parameters - NoShow
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',level.noshowtime,NoShow Time,Length of time in mins before cancelling meeting,LEVEL,NONE,',ITOA(myConnectRMS.ROOM[x].NOSHOW_TIMER),',,false,false,0,',ITOA(myConnectRMS.ROOM[x].NOSHOW_TIMEOUT),',,true'"
						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM-',DEVTOA(vdvRoom[x]),',level.noshowmax,NoShow Max,Largest meeting in Mins to cancel,LEVEL,NONE,',ITOA(myConnectRMS.ROOM[x].NOSHOW_MAXIMUM),',,false,false,0,',ITOA(myConnectRMS.ROOM[x].NOSHOW_MAXIMUM),',,true'"
						// Register Parameters - QuickBook

						// Register Parameters - AutoBook

						SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.SUBMIT-',DEVTOA(vdvRoom[x])"
					}
				}
			}
			DEFAULT:{
				SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'-',1),1)){
					CASE 'ASSET.LOCATION.CHANGE':		// An Asset Location has changed
					CASE 'ASSET.REGISTERED':{			// An Asset has registered
						STACK_VAR INTEGER r
						// Get the relevant Device from the incoming string
						STACK_VAR DEV myDevice
						ATODEV(myDevice,fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
						// Find the Room this data is for
						FOR(r = 1; r <= LENGTH_ARRAY(vdvRoom); r++){
							// Check local asset against the asset reference by this event
							IF(myDevice == vdvRoom[r]){
								// Send in all Parameter Updates
								SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',state.occupied,SET_VALUE,',fnGetBooleanString([vdvRoom[r],4]),',true'"
								SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',level.occupied,SET_VALUE,',ITOA(myConnectRMS.ROOM[r].OCCUPANCY_TIMER),',true'"

								SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',state.meeting,SET_VALUE,',fnGetBooleanString([vdvRoom[r],3]),',true'"
								fnUpdateStatusString(r,'SYSTEM:ONLINE')

								//SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',state.noshow,SET_VALUE,',fnGetBooleanString(TIMELINE_ACTIVE(TLID_TIMER_NOSHOW)),',true'"
								SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',level.noshowtime,SET_VALUE,',ITOA(myConnectRMS.ROOM[r].NOSHOW_TIMER),',false'"
								SEND_COMMAND DATA.DEVICE, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[r]),',level.noshowmar,SET_VALUE,',ITOA(myConnectRMS.ROOM[r].NOSHOW_MAXIMUM),',false'"

								// If this room matches, reset and trigger re-init of data
								fnResetRoom(r)
							}
						}
					}
					CASE 'ASSET.LOCATION':{	// Response to request for asset data
						STACK_VAR INTEGER r
						// Get the relevant Device from the incoming string
						STACK_VAR DEV myDevice
						ATODEV(myDevice,fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
						// Find the Room this data is for
						FOR(r = 1; r <= LENGTH_ARRAY(vdvRoom); r++){
							// Check local asset against the asset reference by this event
							IF(myDevice == vdvRoom[r]){

								// Process Location ID
								myConnectRMS.ROOM[r].LOC_ID   = ATOI(fnGetCSV(pDATA,1))
								myConnectRMS.ROOM[r].LOC_NAME = fnGetCSV(pDATA,2)
								SEND_COMMAND vdvRoom[r],"'PROPERTY-LOCATION,',ITOA(myConnectRMS.ROOM[r].LOC_ID),',',myConnectRMS.ROOM[r].LOC_NAME"

								// Request all Bookings
								fnGetBookings(r)
							}
						}
					}
				}
			}
		}
		fnDebug(DEBUG_DEV,vdvRMSDuet,'DATA_EVENT [COMMAND] vdvRMSDuet','Finished')
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Custom Events - Booking Record Response
	This will be returned when bookins are requested, so will be part of a set
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT CUSTOM_EVENT[vdvRMSDuet,
	RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
		RMS_EVENT_BOOKING_RECORD_RESPONSE]{

	IF(custom.flag == TRUE){
		// Local Variables
		STACK_VAR INTEGER r
		STACK_VAR uRmsBookResp thisBooking
		// Debug Out
		fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_RECORD_RESPONSE','Called')
		// Decode Variable
		fnGetCleanBookingResponse(custom.encode,thisBooking)
		// Find matching Room
		FOR(r = 1; r <= LENGTH_ARRAY(vdvRoom); r++){
			IF(thisBooking.location && thisBooking.location == myConnectRMS.ROOM[r].LOC_ID){
				STACK_VAR INTEGER b
				fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_RECORD_RESPONSE',"'Matched','Room: ',ITOA(r)")

				// Get Current Booking Index
				b = TYPE_CAST( CUSTOM.VALUE2 )	// Booking Index#

				// Get Total Bookings
				myConnectRMS.ROOM[r].BOOKING_COUNT = TYPE_CAST( CUSTOM.VALUE3 )	// Booking Index

				// Clear out bookings if this is the first of a new set
				IF(b == 1){
					fnClearBookings(r)
				}
				fnDebugBooking(DEBUG_DEV,CUSTOM.VALUE2,CUSTOM.VALUE3,thisBooking)

				// Store this booking
				IF(b != 0){
					BOOKING[r][b] = thisBooking
				}

				// If this is the last booking in the list
				IF(myConnectRMS.ROOM[r].BOOKING_COUNT == b){
					fnSendBookingsToRoom(r)
				}
			}
		}
		fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_RECORD_RESPONSE','Finished')
	}
}

/********************************************************************************************************************************************************************************************************************************************************
	RMS Custom Events - All Responses
	As most responses return a single and a booking to match, we just need to act on that as required,
	update existing booking and resend
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT
CUSTOM_EVENT[vdvRMSDuet, RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING, RMS_EVENT_BOOKING_EXTENDED_RESPONSE]
CUSTOM_EVENT[vdvRMSDuet, RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING, RMS_EVENT_BOOKING_CREATED_RESPONSE]
CUSTOM_EVENT[vdvRMSDuet, RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING, RMS_EVENT_BOOKING_ENDED_RESPONSE]{

	IF(custom.flag == TRUE){
		// Local Variables
		STACK_VAR INTEGER r
		STACK_VAR CHAR EventMessage[50]
		STACK_VAR uRmsBookResp thisBooking

		// Debug Out
		fnDebug(DEBUG_DEV,vdvRMSDuet,'RMS_CUSTOM_ACTION_EVENT','Called')
		// decode custom enceded data to event booking structure
		fnGetCleanBookingResponse(custom.encode,thisBooking)
		fnDebugBooking(DEBUG_DEV,CUSTOM.VALUE2,CUSTOM.VALUE3,thisBooking)

		// Get friendly name for this booking event
		EventMessage = 'RESPONSE-'
		SWITCH(CUSTOM.TYPE){
			CASE RMS_EVENT_BOOKING_EXTENDED_RESPONSE: EventMessage = "EventMessage,'EXTEND'"
			CASE RMS_EVENT_BOOKING_CREATED_RESPONSE:  EventMessage = "EventMessage,'CREATE'"
			CASE RMS_EVENT_BOOKING_ENDED_RESPONSE:    EventMessage = "EventMessage,'CANCEL'"
		}
		SWITCH(thisBooking.isSuccessful){
			CASE TRUE:  EventMessage = "EventMessage,',SUCCESS'"
			CASE FALSE: EventMessage = "EventMessage,',FAILURE,',thisBooking.failureDescription"
		}

		// Find the relevant room
		FOR(r = 1; r <= LENGTH_ARRAY(vdvRoom); r++){
			IF(thisBooking.location && thisBooking.location == myConnectRMS.ROOM[r].LOC_ID){
				fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EXTENDED_RESPONSE',"'Matched Room: ',ITOA(vdvRoom[r].Number)")
				SEND_COMMAND vdvRoom[r],EventMessage
				IF(thisBooking.isSuccessful){
					fnGetBookings(r)
				}
			}
		}

		// Debug Out
		fnDebug(DEBUG_DEV,vdvRMSDuet,'RMS_CUSTOM_ACTION_EVENT','Exit')
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Custom Events - Server Initiated Messages
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT
CUSTOM_EVENT[vdvRMSDuet,6,3]	// A meeting has been Extended
CUSTOM_EVENT[vdvRMSDuet,6,4]	// A Meeting has been Cancelled
CUSTOM_EVENT[vdvRMSDuet,6,5]	// A Meeting has been Created
CUSTOM_EVENT[vdvRMSDuet,6,6]	// A meeting has been Updated
CUSTOM_EVENT[vdvRMSDuet,6,8]	// The current Active Booking has Updated
CUSTOM_EVENT[vdvRMSDuet,6,9]{	// The Next Active Booking has Updated

	IF(custom.flag == TRUE){
		STACK_VAR INTEGER r
		STACK_VAR uRmsBookResp thisBooking
		fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','Enter')
		// decode custom enceded data to event booking structure
		fnGetCleanBookingResponse(custom.encode,thisBooking)
		fnDebugBooking(DEBUG_DEV,CUSTOM.VALUE2,CUSTOM.VALUE3,thisBooking)
		fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT',"'thisBooking.location:',ITOA(thisBooking.location)")

		SWITCH(CUSTOM.TYPE){
			CASE 3:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','A Meeting Extended')
			CASE 4:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','A Meeting Cancelled')
			CASE 5:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','A Meeting Created')
			CASE 6:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','A Meeting Updated')
			CASE 8:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','Active Booking Updated')
			CASE 9:fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','Next Booking Updated')
		}

		// Find the relevant room
		FOR(r = 1; r <= LENGTH_ARRAY(vdvRoom); r++){
			IF(thisBooking.location && thisBooking.location == myConnectRMS.ROOM[r].LOC_ID){
				fnGetBookings(r)
			}
		}
		fnDebug(DEBUG_DEV,vdvRMSDuet,'BOOKING_EVENT','Exit')
	}
}
DEFINE_FUNCTION INTEGER fnUpdateBooking(INTEGER r, uRmsBookResp thisBooking){
	// Find and update the booking
	STACK_VAR INTEGER b
	FOR(b = 1; b <= _MAX_BOOKINGS; b++){
		IF(thisBooking.bookingid == BOOKING[r][b].bookingId){
			BOOKING[r][b] = thisBooking
			RETURN b
		}
	}
	RETURN 0
}
/********************************************************************************************************************************************************************************************************************************************************
	Send Details to Room Devices
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION  fnSendBookingsToRoom(INTEGER r){
	// Local Variables
	IF(BOOKING[r][1].bookingId == ''){
		SEND_COMMAND vdvRoom[r], 'BOOKING-0,0,,,,,,'
	}
	ELSE{
		STACK_VAR INTEGER b
		FOR(b = 1; b <= _MAX_BOOKINGS; b++){
			IF(BOOKING[r][b].bookingId != ''){
				STACK_VAR CHAR ToSend[2000]
				STACK_VAR CHAR wce[500]
				// Command Name
				ToSend = 'BOOKING-'
				// Bookings Index
				ToSend = "ToSend,ITOA(b)"
				// Bookings Total
				ToSend = "ToSend,',',ITOA(myConnectRMS.ROOM[r].BOOKING_COUNT)"
				// Is All Day
				ToSend = "ToSend,',',fnGetBooleanString(BOOKING[r][b].isAllDayEvent)"
				// Is Private
				ToSend = "ToSend,',',fnGetBooleanString(BOOKING[r][b].isPrivateEvent)"
				// Start Time (Seconds since Midnight)
				IF(fnDateDif(BOOKING[r][b].startDate,LDATE) < 0){
					// If this meeting started before today, set time to midnight
					ToSend = "ToSend,',',ITOA(fnTimeToSeconds(0))"
				}
				ELSE{
					ToSend = "ToSend,',',ITOA(fnTimeToSeconds(BOOKING[r][b].startTime))"
				}
				// End Time (Seconds since Midnight)
				IF(fnDateDif(LDATE,BOOKING[r][b].endDate) > 0 || BOOKING[r][b].endTime == '00:00:00'){
					// If this meeting Ends After today, set time to midnight
					ToSend = "ToSend,',',ITOA(MIDNIGHT_SECS)"
				}
				ELSE{
					ToSend = "ToSend,',',ITOA(fnTimeToSeconds(BOOKING[r][b].endTime))"
				}
				// Subject
				ToSend = "ToSend,',',WC_ENCODE(BOOKING[r][b].subject,WC_FORMAT_TP,1)"
				// Organiser
				ToSend = "ToSend,',',WC_ENCODE(BOOKING[r][b].organizer,WC_FORMAT_TP,1)"
				// Send it on
				SEND_COMMAND vdvRoom[r], ToSend
			}
		}
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Feedback
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvRoom,4]{
	ON:{  IF([vdvRMSDuet,249]){ SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[GET_LAST(vdvRoom)]),',state.occupied,SET_VALUE,true,true'"  } }
	OFF:{ IF([vdvRMSDuet,249]){ SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[GET_LAST(vdvRoom)]),',state.occupied,SET_VALUE,false,true'" } }
}

DEFINE_EVENT LEVEL_EVENT[vdvRoom,4]{
	IF([vdvRMSDuet,249]){
		SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[GET_LAST(vdvRoom)]),',level.occupied,SET_VALUE,',ITOA(LEVEL.VALUE),',true'"
	}
}

DEFINE_EVENT CHANNEL_EVENT[vdvRoom,3]{
	ON:{ IF([vdvRMSDuet,249]){ SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[GET_LAST(vdvRoom)]),',state.meeting,SET_VALUE,true,true'"  } }
	OFF:{IF([vdvRMSDuet,249]){ SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[GET_LAST(vdvRoom)]),',state.meeting,SET_VALUE,false,true'" } }
}

/********************************************************************************************************************************************************************************************************************************************************
	RMS Function - Update Status String
	Sets the current freetext status field on the virtual device for this room
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnUpdateStatusString(INTEGER pROOM, CHAR pMSG[]){
	// Debug Out
	fnDebug(DEBUG_DEV,vdvRoom[pRoom],'fnUpdateStatusString','Called')
	//
	SEND_COMMAND vdvRMSDuet, "'ASSET.PARAM.UPDATE-',DEVTOA(vdvRoom[pROOM]),',string.subject,SET_VALUE,[',TIME,']"',pMSG,'",true'"
	// Debug out
	fnDebug(DEBUG_DEV,vdvRoom[pRoom],'fnUpdateStatusString','Ended')
}
/********************************************************************************************************************************************************************************************************************************************************
	RMS Function - Get All Bookings
	Clears and Requests all bookings from the Server
	Built into a timer to prevent mutiple requests in quick successsion
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnGetBookings(INTEGER pROOM){
	// Debug Out
	fnDebug(DEBUG_DEV,vdvRoom[pRoom],'fnGetBookings','Called')
	// Reinitialise Timeline
	IF(TIMELINE_ACTIVE(TLID_GET_BOOKINGS_00+pROOM)){ TIMELINE_KILL(TLID_GET_BOOKINGS_00+pROOM) }
	TIMELINE_CREATE(TLID_GET_BOOKINGS_00+pROOM,TLT_GET_BOOKINGS_SHORT,LENGTH_ARRAY(TLT_GET_BOOKINGS_SHORT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	// Debug Out
	fnDebug(DEBUG_DEV,vdvRoom[pRoom],'fnGetBookings','Ended')
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_GET_BOOKINGS_01]
TIMELINE_EVENT[TLID_GET_BOOKINGS_02]
TIMELINE_EVENT[TLID_GET_BOOKINGS_03]
TIMELINE_EVENT[TLID_GET_BOOKINGS_04]
TIMELINE_EVENT[TLID_GET_BOOKINGS_05]
TIMELINE_EVENT[TLID_GET_BOOKINGS_06]
TIMELINE_EVENT[TLID_GET_BOOKINGS_07]
TIMELINE_EVENT[TLID_GET_BOOKINGS_08]
TIMELINE_EVENT[TLID_GET_BOOKINGS_09]
TIMELINE_EVENT[TLID_GET_BOOKINGS_10]
TIMELINE_EVENT[TLID_GET_BOOKINGS_11]
TIMELINE_EVENT[TLID_GET_BOOKINGS_12]
TIMELINE_EVENT[TLID_GET_BOOKINGS_13]
TIMELINE_EVENT[TLID_GET_BOOKINGS_14]
TIMELINE_EVENT[TLID_GET_BOOKINGS_15]
TIMELINE_EVENT[TLID_GET_BOOKINGS_16]
TIMELINE_EVENT[TLID_GET_BOOKINGS_17]
TIMELINE_EVENT[TLID_GET_BOOKINGS_18]
TIMELINE_EVENT[TLID_GET_BOOKINGS_19]
TIMELINE_EVENT[TLID_GET_BOOKINGS_20]
TIMELINE_EVENT[TLID_GET_BOOKINGS_21]
TIMELINE_EVENT[TLID_GET_BOOKINGS_22]
TIMELINE_EVENT[TLID_GET_BOOKINGS_23]
TIMELINE_EVENT[TLID_GET_BOOKINGS_24]{
	// Local Variables
	STACK_VAR INTEGER r
	STACK_VAR CHAR pMSG[200]
	// Get Current Room
	r = TIMELINE.ID - TLID_GET_BOOKINGS_00
	// Debugging
	fnDebug(DEBUG_DEV,vdvRoom[r],'TLID_GET_BOOKINGS','TRIGGERED')
	// Send Request to RMS
	fnDebug(DEBUG_DEV,vdvRoom[r],'TLID_GET_BOOKINGS',"'?SCHEDULING.BOOKING-',LDATE,',',ITOA(myConnectRMS.ROOM[r].LOC_ID)")
	SEND_COMMAND vdvRMSDuet, "'?SCHEDULING.BOOKINGS-',LDATE,',',ITOA(myConnectRMS.ROOM[r].LOC_ID)"
	// Restart Timeline to repoll this data
	TIMELINE_CREATE(TIMELINE.ID,TLT_GET_BOOKINGS_LONG,LENGTH_ARRAY(TLT_GET_BOOKINGS_LONG),TIMELINE_RELATIVE,TIMELINE_ONCE)
	// Debugging
	fnDebug(DEBUG_DEV,vdvRoom[r],'TLID_GET_BOOKINGS','PROCESSED')
}
/********************************************************************************************************************************************************************************************************************************************************
	Helper Function - fnResetModule()
	Strips all data down in the module allowing for re-initialisation as requried
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_FUNCTION fnResetRoom(INTEGER r){
	// Debug Out
	fnDebug(DEBUG_DEV,vdvRoom[r],'fnResetModule','Called')
	// Clear Existing Bookings
	fnClearBookings(r)
	// Clear Location Details
	myConnectRMS.ROOM[r].LOC_ID 	= 0			// Reset Location ID
	myConnectRMS.ROOM[r].LOC_NAME 	= ''		// Clear location name
	// Request RMS Location to trigger new data
	SEND_COMMAND vdvRMSDuet, "'?ASSET.LOCATION-',DEVTOA(vdvRoom[r])"
	// Debug Out
	fnDebug(DEBUG_DEV,vdvRoom[r],'fnResetModule','Ended')
}

DEFINE_FUNCTION fnClearBookings(INTEGER r){
	STACK_VAR INTEGER b
	// Cycle through and clear all Bookings
	FOR(b = 1; b <= _MAX_BOOKINGS; b++){
		STACK_VAR uRmsBookResp blankBooking
		BOOKING[r][b] = blankBooking
	}
}
/********************************************************************************************************************************************************************************************************************************************************
	Feedback
********************************************************************************************************************************************************************************************************************************************************/
DEFINE_PROGRAM{
	// Pass through various channels
	[vdvRMSNetlinx,251] = [vdvRMSDuet,251]
}
/********************************************************************************************************************************************************************************************************************************************************
	End Of File
********************************************************************************************************************************************************************************************************************************************************/
