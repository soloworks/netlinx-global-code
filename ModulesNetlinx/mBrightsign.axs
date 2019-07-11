MODULE_NAME='mBrightsign'(DEV vdvPlayer, DEV ipHTTP, DEV ipUDP)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG     TLID_POLL		= 1
LONG     TLID_COMMS		= 2
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uSystem{
	uDebug   DEBUG

	CHAR		MODEL[20]		// Device Model
	CHAR		MAC[20]			// MAC Address
	CHAR		NAME[50]			// Name
	CHAR		DESC[100]		// Description
	CHAR		BOOTVER[20]		// Boot Version
	CHAR		SOFTVER[20]		// Software Version
	CHAR		UPTIME[30]		// Uptime
	CHAR     UID[20]			// Unique ID
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
LONG 		TLT_POLL[] 						= {  45000 }
LONG 		TLT_COMMS[]						= {  90000 }
VOLATILE uSystem myBrightsign
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myBrightsign.DEBUG.UID = 'BS'
}
/******************************************************************************
	HTTP Callback Functions
******************************************************************************/
DEFINE_FUNCTION eventHTTPResponse(uHTTPResponse r){
	STACK_VAR CHAR uOutput[8]
	
	// Check for a title that shows this is a brightsign
	IF(FIND_STRING(r.body,'BrightSign',1)){
		// Reset Communication Timeout
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE{
		RETURN
	}
	
	// Whilst closing tags for tables exist
	WHILE(FIND_STRING(r.Body,'<td>',1)){
		STACK_VAR CHAR pKEY[200]
		STACK_VAR CHAR pVAL[200]
		
		// Get Possible Key
		REMOVE_STRING(r.Body,'<td>',1)
		pKey = REMOVE_STRING(r.Body,'</td>',1)
		SET_LENGTH_ARRAY(pKey,LENGTH_ARRAY(pKey)-5)
		pKey = fnRemoveWhiteSpace(pKey)
		
		// Get Probable Value
		REMOVE_STRING(r.Body,'<td>',1)
		pVAL = REMOVE_STRING(r.Body,'</td>',1)
		SET_LENGTH_ARRAY(pVAL,LENGTH_ARRAY(pVAL)-5)
		pVal = fnRemoveWhiteSpace(pVal)
		
		SWITCH(pKey){
			CASE 'Name:':{
				IF(myBrightsign.NAME != pVAL){
					myBrightsign.NAME = pVAL
					SEND_STRING vdvPlayer,"'PROPERTY-META,NAME,',myBrightsign.NAME"
				}
			}
			CASE 'Ethernet MAC:':{
				IF(myBrightsign.MAC != pVAL){
					myBrightsign.MAC = pVAL
					SEND_STRING vdvPlayer,"'PROPERTY-META,MAC,',myBrightsign.MAC"
				}
			}
			CASE 'Description:':	     myBrightsign.DESC    = pVAL
			CASE 'Model:':	           myBrightsign.MODEL   = pVAL
			CASE 'Unique ID:':	     myBrightsign.UID     = pVAL
			CASE 'Boot Version:':     myBrightsign.BOOTVER = pVAL
			CASE 'Firmware Version:': myBrightsign.SOFTVER = pVAL
			CASE 'Uptime:':	        myBrightsign.Uptime  = pVAL
		}
	}
	
}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR uHTTPRequest r
	// Setup Request
	r.METHOD = HTTP_METHOD_GET
	r.PATH   = '/index.html'
	// Submit
	fnAddToHTTPQueue(r)
	fnInitPoll()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvPlayer]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'TESTPOLL':{
				fnPoll()
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						HTTP.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							STACK_VAR INTEGER UDP_PORT
							UDP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
							// Open UDP Sender
							IP_CLIENT_OPEN(ipUDP.PORT,HTTP.IP_HOST,UDP_PORT,IP_UDP)
						}
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myBrightsign.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV': myBrightsign.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:    myBrightsign.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
						HTTP.DEBUG = myBrightsign.DEBUG
					}
				}
			}
			CASE 'UDP':{
				// Send Request
				fnSendUDP(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvPlayer,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvPlayer,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	UDP Message Handling
******************************************************************************/
DEFINE_FUNCTION fnSendUDP(CHAR pMSG[]){
	SEND_STRING ipUDP,pMSG
}
/******************************************************************************
	EoF
******************************************************************************/

