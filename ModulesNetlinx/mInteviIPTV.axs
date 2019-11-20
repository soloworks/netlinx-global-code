MODULE_NAME='mInteviIPTV'(DEV vdvServer, DEV vdvEndPoint[],DEV tp[], DEV ipHTTP)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'

/******************************************************************************
	Itevi IPTV Control via Server API
******************************************************************************/
DEFINE_CONSTANT
INTEGER _MAX_ENDPOINTS = 10
INTEGER _MAX_CHANNELS  = 10
LONG    TLID_POLL = 1
LONG    TLID_COMMS = 2

INTEGER btnChannel[] = {
	101,102,103,104,105,106,107,108,109,110
}
INTEGER btnEndPoint[] = {
	501,502,503,504,505,506,507,508,509,510
}
DEFINE_TYPE STRUCTURE uPanel{
	INTEGER ENDPOINT
}

DEFINE_TYPE STRUCTURE uEndPoint{
	INTEGER COMMS_STATE
	INTEGER VOLUME
	INTEGER MUTE
	INTEGER SUBTITLES
	CHAR    STATUS[50]
	CHAR    MODEL[20]
	CHAR    NAME[100]
	CHAR    HOST[100]
	CHAR    IP[100]
}
DEFINE_TYPE STRUCTURE uChannel{
	CHAR    IP[100]
	CHAR    MODEL[20]
	INTEGER LOCAL_NUMBER
	INTEGER COMMS_STATE
	CHAR    NAME[100]
	CHAR    ID[100]
	CHAR    LOGO[100]
}
DEFINE_TYPE STRUCTURE uIPTV{
	CHAR      NAME[50]
	CHAR      ID[100]
	INTEGER   PIN	// Group PIN For this module to control
	uEndPoint ENDPOINT[_MAX_ENDPOINTS]
	uChannel  CHAN[_MAX_CHANNELS]
	uPanel    PANEL[10]
}
DEFINE_VARIABLE
uIPTV myIPTV
LONG TLT_COMMS[] = {30000}
LONG TLT_POLL[]  = {10000}
/******************************************************************************
	Server Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvServer]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						HTTP.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							HTTP.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
						}
					}
					CASE 'PIN':{
						myIPTV.PIN = ATOI(DATA.TEXT)
						fnInitPoll()
						fnPoll()
					}
					CASE 'DEBUG':{
						HTTP.DEBUG.LOG_LEVEL = DEBUG_DEV
					}
				}
			}
		}
	}
}
/******************************************************************************
	EndPoint Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvEndPoint]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':{
						myIPTV.ENDPOINT[GET_LAST(vdvEndPoint)].NAME = DATA.TEXT
						fnSetEndPointName(0,GET_LAST(vdvEndPoint))
					}
				}
			}
			CASE 'CHAN':{
				STACK_VAR INTEGER CH
				STACK_VAR INTEGER EP
				EP = GET_LAST(vdvEndPoint)
				FOR(CH = 1; CH <= _MAX_CHANNELS; CH++){
					IF(myIPTV.CHAN[CH].LOCAL_NUMBER == ATOI(DATA.TEXT)){
						fnChangeChannel(EP,CH)
					}
				}
			}
		}
	}
}
/******************************************************************************
	Touchpanel Helpers
******************************************************************************/
DEFINE_FUNCTION fnSetEndPointName(INTEGER p, INTEGER e){
	IF(!p){
		STACK_VAR INTEGER pPanel
		FOR(pPanel = 1; pPanel <= LENGTH_ARRAY(tp); pPanel++){
			fnSetEndPointName(pPanel,e)
		}
		RETURN
	}
	IF(!e){
		STACK_VAR INTEGER pEP
		FOR(pEP = 1; pEP <= LENGTH_ARRAY(vdvEndPoint); pEP++){
			IF(myIPTV.ENDPOINT[pEP].NAME != ''){
				fnSetEndPointName(p,pEP)
			}
		}
		RETURN
	}
	SEND_COMMAND tp[p],"'^TXT-',ITOA(btnEndPoint[e]),',0,',myIPTV.ENDPOINT[e].NAME"
}
DEFINE_FUNCTION fnSetChannelName(INTEGER p, INTEGER c){
	IF(!p){
		STACK_VAR INTEGER pPanel
		FOR(pPanel = 1; pPanel <= LENGTH_ARRAY(tp); pPanel++){
			fnSetChannelName(pPanel,c)
		}
		RETURN
	}
	IF(!c){
		STACK_VAR INTEGER pChan
		FOR(pChan = 1; pChan <= LENGTH_ARRAY(btnChannel); pChan++){
			IF(myIPTV.CHAN[pChan].NAME != ''){
				fnSetChannelName(p,pChan)
			}
		}
		RETURN
	}
	SEND_COMMAND tp[p],"'^TXT-',ITOA(btnChannel[c]),',0,',myIPTV.CHAN[c].NAME"
}

DEFINE_FUNCTION fnSetChannelLogo(INTEGER p, INTEGER c){
	IF(!p){
		STACK_VAR INTEGER pPanel
		FOR(pPanel = 1; pPanel <= LENGTH_ARRAY(tp); pPanel++){
			fnSetChannelLogo(pPanel,c)
		}
		RETURN
	}
	IF(!c){
		STACK_VAR INTEGER pChan
		FOR(pChan = 1; pChan <= LENGTH_ARRAY(tp); pChan++){
			fnSetChannelLogo(p,pChan)
		}
		RETURN
	}
	//SEND_COMMAND tp[p],"'^TXT-',ITOA(btnChannel[c]),',0,',myIPTV.CHAN[c].NAME"
}
/******************************************************************************
	Touchpanel Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		IF(myIPTV.PANEL[GET_LAST(tp)].ENDPOINT == 0){
			myIPTV.PANEL[GET_LAST(tp)].ENDPOINT = 1
		}
		fnSetEndPointName(GET_LAST(tp),0)
		fnSetChannelName(GET_LAST(tp),0)
		fnSetChannelLogo(GET_LAST(tp),0)
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnEndPoint]{
	PUSH:{
		myIPTV.PANEL[GET_LAST(tp)].ENDPOINT = GET_LAST(btnEndPoint)
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnChannel]{
	PUSH:{
		STACK_VAR INTEGER CH
		STACK_VAR INTEGER EP
		CH = GET_LAST(btnChannel)
		EP = myIPTV.PANEL[GET_LAST(tp)].ENDPOINT
		fnChangeChannel(EP,CH)
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		STACK_VAR INTEGER b
		IF(myIPTV.PANEL[p].ENDPOINT == 0){
			myIPTV.PANEL[p].ENDPOINT = 1
		}
		FOR(b = 1; b <= LENGTH_ARRAY(btnChannel); b++){
			[tp[p],btnChannel[b]] = (myIPTV.ENDPOINT[myIPTV.PANEL[p].ENDPOINT].STATUS == myIPTV.CHAN[b].NAME)
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
	newRequest.PATH = "'/mobile/getendpointgroupsforpin/',FORMAT('%04d',myIPTV.PIN)"
	// Queue Request
	fnAddToHTTPQueue(newRequest)
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnChangeChannel(INTEGER EP, INTEGER CH){
	STACK_VAR uHTTPRequest r
	// Set Values
	r.METHOD = HTTP_METHOD_GET
	r.PATH = "'/mobile/changechannel/',myIPTV.ENDPOINT[EP].IP,'/',myIPTV.CHAN[CH].ID"
	// Queue Request
	fnAddToHTTPQueue(r)
	// Force Feedback pending Polling update
	myIPTV.ENDPOINT[EP].STATUS = myIPTV.CHAN[CH].NAME
	// Reset Poll
	fnInitPoll()
}
/******************************************************************************
	WebSocket Callback Events
******************************************************************************/
DEFINE_FUNCTION eventHTTPResponse(uHTTPResponse r){
	STACK_VAR CHAR TEMP[10000]
	STACK_VAR INTEGER CH

	// Eat up to Group Detail
	REMOVE_STRING(r.body,'"groups"',1)
	myIPTV.NAME = fnGetNextValueByKey('name',r.body)
	myIPTV.ID = fnGetNextValueByKey('id',r.body)

	// Eat up to endpoints
	REMOVE_STRING(r.body,'"endpoints"',1)
	TEMP = REMOVE_STRING(r.body,']',1)

	// Process Endpoints
	WHILE(FIND_STRING(TEMP,'}',1)){
		STACK_VAR INTEGER EP
		STACK_VAR CHAR NAME[100]
		NAME = fnGetNextValueByKey('name',TEMP)
		FOR(EP = 1; EP <= LENGTH_ARRAY(vdvEndPoint); EP++){
			IF(UPPER_STRING(myIPTV.ENDPOINT[EP].NAME) == UPPER_STRING(NAME)){
				SEND_STRING 0, "'Finding online for : ',NAME"
				myIPTV.ENDPOINT[EP].COMMS_STATE = (fnGetNextValueByKey('online',TEMP) == 'true')
				myIPTV.ENDPOINT[EP].MUTE = (fnGetNextValueByKey('mute',TEMP) == 'true')
				myIPTV.ENDPOINT[EP].VOLUME = ATOI(fnGetNextValueByKey('volume',TEMP))
				myIPTV.ENDPOINT[EP].STATUS = fnGetNextValueByKey('status',TEMP)
				myIPTV.ENDPOINT[EP].MODEL = fnGetNextValueByKey('type',TEMP)
				myIPTV.ENDPOINT[EP].HOST = fnGetNextValueByKey('address',TEMP)
				myIPTV.ENDPOINT[EP].IP = fnGetNextValueByKey('ipAddress',TEMP)
				BREAK
			}
		}
		REMOVE_STRING(TEMP,'}',1)
	}

	// Eat up to Channels
	REMOVE_STRING(r.body,'"channels"',1)
	TEMP = REMOVE_STRING(r.body,']',1)

	// Process channels
	WHILE(FIND_STRING(TEMP,'}',1)){
		CH++
		IF(myIPTV.CHAN[CH].NAME != fnGetNextValueByKey('name',TEMP)){
			myIPTV.CHAN[CH].NAME  = fnGetNextValueByKey('name',TEMP)
			fnSetChannelName(0,CH)
		}
		myIPTV.CHAN[CH].NAME    = fnGetNextValueByKey('name',TEMP)
		myIPTV.CHAN[CH].ID    = fnGetNextValueByKey('id',TEMP)
		myIPTV.CHAN[CH].IP    = fnGetNextValueByKey('ip',TEMP)
		myIPTV.CHAN[CH].MODEL = fnGetNextValueByKey('type',TEMP)
		myIPTV.CHAN[CH].COMMS_STATE = (fnGetNextValueByKey('online',TEMP) == 'true')
		myIPTV.CHAN[CH].LOCAL_NUMBER = ATOI(fnGetNextValueByKey('lcn',TEMP))

		REMOVE_STRING(TEMP,'}',1)
	}
	IF(r.code == 200){
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION CHAR[500] fnGetNextValueByKey(CHAR pKey[],CHAR pJS[10000]){
	STACK_VAR INTEGER VAL_START
	STACK_VAR INTEGER VAL_END
	STACK_VAR CHAR TEXT[10000]
	STACK_VAR CHAR ret[500]

	TEXT = pJS

	IF(FIND_STRING(TEXT,"'"',pKey,'"'",1)){
		REMOVE_STRING(TEXT,"'"',pKey,'"'",1)
		REMOVE_STRING(TEXT,"':'",1)
		WHILE(TEXT[1] == ' '){
			GET_BUFFER_CHAR(TEXT)
		}
		// Value should be next string
		IF(TEXT[1] == '"'){
			ret =  fnRemoveQuotes(REMOVE_STRING(TEXT,'"',2))
		}
		ELSE{
			// Deal with last case in object as well
			INTEGER comma
			INTEGER brace
			comma = FIND_STRING(TEXT,',',1)
			brace = FIND_STRING(TEXT,'}',1)

			IF(comma < brace && comma != 0){
				ret =  fnStripCharsRight(REMOVE_STRING(TEXT,',',1),1)
			}
			ELSE{
				ret =  fnStripCharsRight(REMOVE_STRING(TEXT,'}',1),1)
			}
		}
	}

	RETURN fnRemoveWhiteSpace(ret)
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{

	STACK_VAR INTEGER x;

	// Server Communications
	[vdvServer,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvServer,252] = TIMELINE_ACTIVE(TLID_COMMS)

	// Player Communications
	FOR(x = 1; x <= LENGTH_ARRAY(vdvEndPoint); x++){
		[vdvEndPoint[x],251] = (TIMELINE_ACTIVE(TLID_COMMS) && myIPTV.ENDPOINT[x].COMMS_STATE == TRUE)
		[vdvEndPoint[x],252] = (TIMELINE_ACTIVE(TLID_COMMS) && myIPTV.ENDPOINT[x].COMMS_STATE == TRUE)
	}
}
/******************************************************************************
	EoF
******************************************************************************/