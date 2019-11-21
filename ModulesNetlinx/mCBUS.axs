MODULE_NAME='mCBUS'(DEV vdvCBUS, DEV ipCBUS)
INCLUDE 'CustomFunctions'
/******************************************************************************
	CBUS Control Module via Ethernet
	Listening Events implemented only
******************************************************************************/

/******************************************************************************
	Module Structures, Constants, Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_APPS = 10

DEFINE_TYPE STRUCTURE uComms{
	CHAR 		Rx[1000]						// Receieve Buffer
	CHAR		Tx[1000]						// Transmit Buffer
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER 	DEBUG							// Debugging
}

DEFINE_TYPE STRUCTURE uCBUS{
	uComms	COMMS

	CHAR		META_MAKE[18]
	CHAR		META_MODEL[18]
	CHAR 		META_FIRMWARE[18]
}

DEFINE_CONSTANT
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
// Timelines
LONG TLID_POLL		= 1
LONG TLID_RETRY	= 2
LONG TLID_COMMS	= 3
LONG TLID_BOOT		= 4
// Debugging
LONG DEBUG_ERR	= 0
LONG DEBUG_STD	= 1
LONG DEBUG_DEV	= 2
LONG DEBUG_LOG	= 3

DEFINE_VARIABLE
// Complex Types
VOLATILE uCBUS myCBUS
// Timelines
LONG 		TLT_COMMS[] = {  45000 }
LONG 		TLT_POLL[]  = {  15000 }
LONG 		TLT_RETRY[]	= {  60000 }
LONG 		TLT_BOOT[]	= {   5000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipCBUS, myCBUS.COMMS.Rx
}

/******************************************************************************
	Helper Function - fnDebug()
******************************************************************************/
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

	DEBUG_LOG_FILENAME = "'DEBUG_LOG_mCBUS_',ITOA(vdvCBUS.Number),'_',pTIMESTAMP,'.log'"
	fnDebug(DEBUG_LOG,'fnInitateLogFile','File Created',pTIMESTAMP)
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR pOrigin[], CHAR pRef[],CHAR pData[]){
	// Check the requested debug against the current module setting
	IF(myCBUS.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR dbgMsg[255]
		dbgMsg = "ITOA(vdvCBUS.Number),'|',pOrigin,'|',pRef,'|',pData"
		// Send to diagnostics screen
		SEND_STRING 0:0:0, dbgMsg
		// Log to file if required
		IF(myCBUS.COMMS.DEBUG == DEBUG_LOG){
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
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pCMD,$0D"
	SWITCH(myCBUS.COMMS.IP_STATE){
		CASE IP_STATE_CONNECTED:{
			fnDebug(DEBUG_STD,'fnSendCommand','->CBUS',toSend)
			SEND_STRING ipCBUS, toSend
		}
	}
	fnInitPoll()
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myCBUS.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'fnOpenTCPConnection','CBUS IP','Not Set')
	}
	ELSE{
		IF(!myCBUS.COMMS.IP_PORT){myCBUS.COMMS.IP_PORT = 20023}
		fnDebug(DEBUG_STD,'fnOpenTCPConnection','Connecting to CBUS on ',"myCBUS.COMMS.IP_HOST,':',ITOA(myCBUS.COMMS.IP_PORT)")
		myCBUS.COMMS.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(ipCBUS.port, myCBUS.COMMS.IP_HOST, myCBUS.COMMS.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipCBUS.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('2100')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
/******************************************************************************
	Actual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipCBUS]{
	ONLINE:{
		TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	OFFLINE:{
		IF(TIMELINE_ACTIVE(TLID_BOOT)){TIMELINE_KILL(TLID_BOOT)}
		myCBUS.COMMS.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myCBUS.COMMS.IP_STATE = IP_STATE_OFFLINE
				SWITCH(DATA.NUMBER){
					CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
					CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
					CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
					CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
					CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
					CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
					CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
					CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
					CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
					CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
					CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
				}
				fnRetryConnection()
			}
		}
		fnDebug(DEBUG_ERR,'DATA_EVENT[ipCBUS]',"'SS IP Error:[',myCBUS.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		//fnDebug(DEBUG_DEV,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myCBUS.COMMS.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myCBUS.COMMS.Rx,"$0D,$0A",1),2))
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	myCBUS.COMMS.IP_STATE	= IP_STATE_CONNECTED
	fnPoll()
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA_ASCII[]){
	STACK_VAR CHAR pDATA[30]
	// Log the incoming data
	fnDebug(DEBUG_STD,'fnProcessFeedback','CBUS->',pDATA_ASCII)
	// Convert data from Ascii format Hex
	WHILE(LENGTH_ARRAY(pDATA_ASCII)){
		pDATA = "pDATA,HEXTOI(GET_BUFFER_STRING(pDATA_ASCII,2))"
	}
	// Swicth on Message Type
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE $05:{	// Monitored SAL Reply
			STACK_VAR INTEGER pApp
			STACK_VAR INTEGER pUnitadd
			pApp = pData[2]	// Get Application
			pDATA = fnStripCharsRight(pDATA,1)	// Strip checksum
			// If there is a Reply Network part
			IF(pDATA[3]){
				STACK_VAR INTEGER pListlength
				GET_BUFFER_STRING(pDATA,2)					// Strip first Bridge Add and Application
				pListlength = GET_BUFFER_CHAR(pData)	// Get length of chain
				pUnitadd = pDATA[pListlength]				// Get last in list as Unit Address
				GET_BUFFER_STRING(pDATA,pListlength)	// Clear out the list
			}
			ELSE{
				pUnitadd = pDATA[1]
				GET_BUFFER_STRING(pData,3)	// Strip UnitAdd,Application,$00
			}
			// Should just have SAL Data left
			fnDebug(DEBUG_DEV,'fnProcessFeedback',"'Application=',ITOA(pApp)","'SALData=',fnBytesToString(pDATA)")

			SWITCH(pDATA[1]){
				CASE $01:{	// Group Off
					fnDebug(DEBUG_DEV,'fnProcessFeedback','GROUP:OFF',"'ADDRESS HEX=',ITOHEX(pApp),':',ITOHEX(pDATA[2]),' ADDRESS DEC=',ITOA(pApp),':',ITOA(pDATA[2])")
					SEND_STRING vdvCBUS,"'STATE-',ITOHEX(pApp),',',ITOHEX(pDATA[2]),',ON'"
				}
				CASE $79:{	// Group On
					fnDebug(DEBUG_DEV,'fnProcessFeedback','GROUP:ON',"'ADDRESS HEX=',ITOHEX(pApp),':',ITOHEX(pDATA[2]),' ADDRESS DEC=',ITOA(pApp),':',ITOA(pDATA[2])")
					SEND_STRING vdvCBUS,"'STATE-',ITOHEX(pApp),',',ITOHEX(pDATA[2]),',OFF'"
				}
			}
		}
		CASE $86:{	// CAL Reply
			GET_BUFFER_CHAR(pData)	// Consume Unit or Bridge address
			GET_BUFFER_CHAR(pData)	// Consume Serial Interface Address
			GET_BUFFER_CHAR(pData)	// Consume 00 or Reply Network
			GET_BUFFER_CHAR(pData)	// Consume Unknown byte (Possibly Length)
			pData = fnStripCharsRight(pData,1)	// Remove Checksum
			SWITCH(GET_BUFFER_CHAR(pData)){
				CASE $00:{	// Manufacturer
					fnRemoveWhiteSpace(pData)	// Clear off white space
					IF(myCBUS.META_MAKE != pDATA){
						myCBUS.META_MAKE = pDATA
						SEND_STRING vdvCBUS,"'PROPERTY-META,MAKE,',myCBUS.META_MAKE"
					}
					IF(!LENGTH_ARRAY(myCBUS.META_MODEL)){
						fnSendCommand('2101')
					}
				}
				CASE $01:{	// Type (Model)
					fnRemoveWhiteSpace(pData)	// Clear off white space
					IF(myCBUS.META_MODEL != pDATA){
						myCBUS.META_MODEL = pDATA
						SEND_STRING vdvCBUS,"'PROPERTY-META,MODEL,',myCBUS.META_MODEL"
					}
					IF(!LENGTH_ARRAY(myCBUS.META_FIRMWARE)){
						fnSendCommand('2102')
					}
				}
				CASE $02:{	// Firmware
					fnRemoveWhiteSpace(pData)	// Clear off white space
					IF(myCBUS.META_FIRMWARE != pDATA){
						myCBUS.META_FIRMWARE = pDATA
						SEND_STRING vdvCBUS,"'PROPERTY-META,FIRMWARE,',myCBUS.META_FIRMWARE"
					}
				}
			}
		}
	}

	// Start comms timeline
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Main Virtual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvCBUS]{
	ONLINE:{
		fnRetryConnection()
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':	myCBUS.COMMS.DEBUG = DEBUG_DEV
							CASE 'TRUE':myCBUS.COMMS.DEBUG = DEBUG_STD
							CASE 'LOG':{
								myCBUS.COMMS.DEBUG = DEBUG_LOG
								fnInitateLogFile()
							}
							DEFAULT:		myCBUS.COMMS.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myCBUS.COMMS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myCBUS.COMMS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myCBUS.COMMS.IP_HOST = DATA.TEXT
							myCBUS.COMMS.IP_PORT = 10001
						}
						fnRetryConnection()
					}
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvCBUS,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvCBUS,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/
