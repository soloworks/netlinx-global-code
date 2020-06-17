MODULE_NAME='mZeeVeeMXEPlus'(DEV vdvControl, DEV ipHTTP)
/******************************************************************************
	Control of ZeeVee ZvMXE+ IPTV Decoder via HTTP
	ToDo:
	- Extract Channel List
	- Send Channel
	- Store last channel, recall with CHAN-PREVIOUS
******************************************************************************/
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'
/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_START{
	// Override default HeaderETX ($0D,$0A) as this has a broken HTTP server instance
	_HeaderETX = "$0A"
}

DEFINE_CONSTANT
INTEGER _MAX_CHANNELS = 250
LONG    TLID_POLL     = 1
LONG    TLID_COMMS    = 2

DEFINE_TYPE STRUCTURE uSTB{
	INTEGER  CurrentChannel
	INTEGER  PreviousChannel
	CHAR     ChannelName[_MAX_CHANNELS][20]
}

DEFINE_VARIABLE
uSTB mySTB
LONG TLT_COMMS[] = {30000}
LONG TLT_POLL[]  = {10000}
/******************************************************************************
	Virtual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						HTTP.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							HTTP.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
						}
						ELSE{
							HTTP.IP_PORT = 8080
						}
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': HTTP.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'DEV':	 HTTP.DEBUG.LOG_LEVEL = DEBUG_DEV
							DEFAULT:	    HTTP.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
					}
				}
			}
			CASE 'CHAN':{
				SWITCH(DATA.TEXT){
					CASE 'PREVIOUS':{
						SEND_COMMAND DATA.DEVICE,"FORMAT('CHAN-%d',mySTB.PreviousChannel)"
					}
					DEFAULT:{
						fnChangeChannel(ATOI(DATA.TEXT))
					}
				}
			}
		}
	}
}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,1,TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR uHTTPRequest newRequest
	// Set Values
	newRequest.METHOD = HTTP_METHOD_GET
	newRequest.PATH = "'/'"
	// Queue Request
	fnAddToHTTPQueue(newRequest)
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnChangeChannel(INTEGER CH){
	STACK_VAR uHTTPRequest r
	// Set Values
	r.METHOD = HTTP_METHOD_GET
	r.PATH = FORMAT('/channel=%d',CH)
	// Queue Request
	fnAddToHTTPQueue(r)
	// Force Feedback pending Polling update
	mySTB.PreviousChannel = mySTB.CurrentChannel
	mySTB.CurrentChannel = ch
	// Reset Poll
	fnInitPoll()
}

/******************************************************************************
	Callback Events
******************************************************************************/
DEFINE_FUNCTION eventHTTPResponse(uHTTPResponse r){
	// Process Feedback

	WHILE(FIND_STRING(r.body,"$0A",1)){
		STACK_VAR CHAR l[200]
		STACK_VAR INTEGER isCurrent
		STACK_VAR INTEGER chanNumber
		l = fnStripCharsRight(REMOVE_STRING(r.body,"$0A",1),1)
		IF(l == 'Invalid Channel Number'){
			SEND_STRING vdvControl,'ERROR: Invalid Channel Number'
			RETURN
		}
		// Detect current channel
		isCurrent = (LEFT_STRING(l,3) == ' * ')
		GET_BUFFER_STRING(l,3)
		// Remove "Channel Number " string
		REMOVE_STRING(l,'Channel Number ',1)
		// Get Channel Number
		chanNumber = ATOI(REMOVE_STRING(l,' ',1))
		IF(mySTB.ChannelName[chanNumber] != l){
			mySTB.ChannelName[chanNumber] = l
			SEND_STRING vdvControl,"FORMAT('CHAN-%d,',chanNumber),mySTB.ChannelName[chanNumber]"
		}
		// Set current channel if required
		IF(isCurrent){
			IF(mySTB.CurrentChannel != chanNumber){
				mySTB.PreviousChannel = mySTB.CurrentChannel
				mySTB.CurrentChannel = chanNumber
			}
		}
	}

	// Reset comms loop
	IF(r.code == 200){
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x;
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
	FOR(x = 1; x <= _MAX_CHANNELS; x++){
		[vdvControl,x] = (mySTB.CurrentChannel == x)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
