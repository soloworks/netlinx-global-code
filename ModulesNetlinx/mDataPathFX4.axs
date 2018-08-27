MODULE_NAME='mDataPathFX4'(DEV vdvControl, DEV ipDataPath)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2
LONG TLID_ERROR	   = 3
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uHTTP{
	CHAR		URL[200]
	CHAR     DATA[1000]
	CHAR		REQUEST[2000]
}
DEFINE_TYPE STRUCTURE uSystem{

	CHAR		SERIAL_NUMBER[50]		
	CHAR 		FIRMWARE_VER[50]
	CHAR		NAME[50]
	
	INTEGER	CONN_STATE
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	INTEGER	DEBUG
	uHTTP		Tx[10]
	CHAR		Rx[5000]
	uHTTP		LastHTTP
	
	INTEGER  INPUT_ACTIVE
	INTEGER  INPUT_PREFERED
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER	CONN_STATE_OFFLINE		= 0
INTEGER	CONN_STATE_CONNECTING	= 1
INTEGER	CONN_STATE_CONNECTED		= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

INTEGER HTTP_TYPE_POST = 1
INTEGER HTTP_TYPE_GET  = 2

DEFINE_VARIABLE
LONG 		TLT_POLL[] 		= { 15000 }
LONG 		TLT_COMMS[] 	= { 60000 }
LONG 		TLT_ERROR[] 	= {  5000 }
VOLATILE uSystem myDataPath
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDataPath, myDataPath.Rx
}

/******************************************************************************
	Helper Utility
******************************************************************************/
DEFINE_FUNCTION INTEGER fnInputToInteger(CHAR pNAME[]){
	SWITCH(pNAME){
		CASE 'HDMI1':RETURN 0
		CASE 'HDMI2':RETURN 1
		CASE 'DPORT':RETURN 2
	}
}
/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[]){
	IF(myDataPath.DEBUG >= pDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg"
	}
}
DEFINE_FUNCTION fnDebugHTTP(INTEGER pDEBUG,CHAR MsgTitle[100],CHAR MsgData[5000]){
	STACK_VAR pMsgCopy[5000]
	fnDebug(DEBUG_DEV,"'fnDebugHTTP Called'")
	IF(myDataPath.DEBUG >= pDEBUG){
		fnDebug(DEBUG_STD,"'fnDebugHTTP Head STX-----------------------------'")
		// Cope body to prevent issues
		pMsgCopy = MsgData
		// Headers
		WHILE(FIND_STRING(pMsgCopy,"$0D,$0A",1)){
			STACK_VAR CHAR HEADER[100]
			HEADER = REMOVE_STRING(pMsgCopy,"$0D,$0A",1)
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':HEADER:',HEADER"
			IF(HEADER == "$0D,$0A"){
				BREAK
			}
		}
		fnDebug(DEBUG_STD,"'fnDebugHTTP Body STX-----------------------------'")
		//SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMsgCopy"
		fnDebug(DEBUG_STD,"'fnDebugHTTP HTTP ETX-----------------------------'")
	}
	fnDebug(DEBUG_DEV,"'fnDebugHTTP Ended'")
}
/******************************************************************************
	Connection Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Called'")
	fnDebug(DEBUG_STD,"'Connecting to ',myDataPath.IP_HOST,':',ITOA(myDataPath.IP_PORT)")
	myDataPath.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDataPath.port, "myDataPath.IP_HOST", myDataPath.IP_PORT, IP_TCP) 
	fnTimeoutConnection(TRUE)
	fnDebug(DEBUG_DEV,"'fnOpenTCPConnection','Ended'")
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Called'")
	IP_CLIENT_CLOSE(ipDataPath.port)
	fnDebug(DEBUG_DEV,"'fnCloseTCPConnection','Ended'")
}
DEFINE_FUNCTION fnTimeoutConnection(INTEGER pSTATE){
	IF(TIMELINE_ACTIVE(TLID_ERROR)){TIMELINE_KILL(TLID_ERROR)}
	SWITCH(pSTATE){
		CASE TRUE:{
			TIMELINE_CREATE(TLID_ERROR,TLT_ERROR,LENGTH_ARRAY(TLT_ERROR),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_ERROR]{
	STACK_VAR INTEGER x
	STACK_VAR uHTTP blankHTTP
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT:TLID_ERROR Called'")
	FOR(x = 1; x <= 10; x++){
		myDataPath.Tx[x] = blankHTTP
	}
	myDataPath.LastHTTP = blankHTTP
	myDataPath.Rx = ''

	IF(myDataPath.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT:TLID_ERROR Ended'")
}
/******************************************************************************
	Packaging Functions Functions
******************************************************************************/
DEFINE_FUNCTION fnSendRequest(INTEGER pTYPE, CHAR pURL[100],CHAR pArgs[500]){
	STACK_VAR uHTTP pHTTP
	fnDebug(DEBUG_DEV,"'fnSendRequest','Called'")
	pHTTP.URL = pURL
	pHTTP.DATA = pARGS
	
	SWITCH(pTYPE){
		CASE HTTP_TYPE_GET: pHTTP.REQUEST = fnBuildGETRequest(pURL,pARgs)
		CASE HTTP_TYPE_POST:pHTTP.REQUEST = fnBuildPOSTRequest(pURL,pARgs)
	}
	
	fnAddToQueue(pHTTP)
	fnDebug(DEBUG_DEV,"'fnSendRequest','Called'")
}


DEFINE_FUNCTION fnAddToQueue(uHTTP pHTTP){
	fnDebug(DEBUG_DEV,"'fnAddToQueue','Called'")
	IF(1){
		STACK_VAR INTEGER x
		FOR(x = 1; x <= 10; x++){
			IF(!LENGTH_ARRAY(myDataPath.Tx[x].URL)){
				myDataPath.Tx[x] = pHTTP
				BREAK
			}
		}
		fnSendFromQueue()
	}
	fnDebug(DEBUG_DEV,"'fnAddToQueue','Ended'")
}

DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug(DEBUG_DEV,"'fnSendFromQueue','Called'")
	IF(myDataPath.CONN_STATE == CONN_STATE_OFFLINE && LENGTH_ARRAY(myDataPath.Tx[1].URL)){
		fnOpenTCPConnection()
	}
	fnDebug(DEBUG_DEV,"'fnSendFromQueue','Ended'")
}

DEFINE_FUNCTION CHAR[10000] fnBuildPOSTRequest(CHAR pURL[100],CHAR pBody[1000]){
	STACK_VAR CHAR cToReturn[10000]
	fnDebug(DEBUG_DEV,"'fnWrapPOSTRequest','Called'")
	(** Build Header **)
	cToReturn = "cToReturn,'POST ',pURL,'',' HTTP/1.1',$0D,$0A"
	cToReturn = "cToReturn,'Host: ',myDataPath.IP_HOST,':',myDataPath.IP_PORT,$0D,$0A"
	cToReturn = "cToReturn,'Content-Type: application/json',$0D,$0A"
	cToReturn = "cToReturn,'Content-length: ',ITOA(LENGTH_ARRAY(pBody)),$0D,$0A"
	cToReturn = "cToReturn,$0D,$0A"
	(** Combine **)
	fnDebug(DEBUG_DEV,"'fnWrapPOSTRequest','Returning'")
	RETURN( "cToReturn, pBody" )
	
}

DEFINE_FUNCTION CHAR[10000] fnBuildGETRequest(CHAR pURL[100],CHAR pArgs[500]){
	STACK_VAR CHAR cToReturn[10000]
	fnDebug(DEBUG_DEV,"'fnWrapGETRequest','Called'")
	(** Build Header **)
	cToReturn = "cToReturn,'GET ',pURL"
	IF(LENGTH_ARRAY(pArgs)){
		cToReturn = "cToReturn,'?',pArgs"
	}
	cToReturn = "cToReturn,' HTTP/1.1',$0D,$0A"
	cToReturn = "cToReturn,'Host: ',myDataPath.IP_HOST,':',myDataPath.IP_PORT,$0D,$0A"
	cToReturn = "cToReturn,$0D,$0A"
	(** Combine **)
	fnDebug(DEBUG_DEV,"'fnWrapGETRequest','Returning'")
	RETURN( cToReturn )
	
}
/******************************************************************************
	Feedback Processing
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessFeedback(){
	STACK_VAR INTEGER RESPONSE_CODE
	STACK_VAR pValue[100]
	
	// Process Headers
	fnDebug(DEBUG_DEV,"'fnProcessFeedback() Head STX-----------------------------'")
	// Headers
	WHILE(FIND_STRING(myDataPath.Rx,"$0D,$0A",1)){
		STACK_VAR CHAR HEADER[100]
		fnDebug(DEBUG_DEV,"'fnProcessFeedback() HeaderLoop Start'")
		HEADER = fnStripCharsRight(REMOVE_STRING(myDataPath.Rx,"$0D,$0A",1),2)
		fnDebug(DEBUG_DEV,"'fnProcessFeedback() HEADER=',HEADER")
		IF(LEFT_STRING(HEADER,4) == 'HTTP'){
			REMOVE_STRING(HEADER,' ',1)
			RESPONSE_CODE = ATOI(REMOVE_STRING(HEADER,' ',1))
			fnDebug(DEBUG_DEV,"'fnProcessFeedback() RESPONSE_CODE=',ITOA(RESPONSE_CODE)")
			IF(RESPONSE_CODE == 400){
				RETURN RESPONSE_CODE
			}
		}
		ELSE IF(HEADER == ''){
			fnDebug(DEBUG_STD,"'fnProcessFeedback() Empty Row for Header End Found'")
			BREAK
		}
		fnDebug(DEBUG_DEV,"'fnProcessFeedback() HeaderLoop End'")
	}
	
	fnDebug(DEBUG_DEV,"'fnProcessFeedback() Body STX-----------------------------'")
	fnDebug(DEBUG_DEV,"'fnProcessFeedback() myDataPath.Rx:'")
	fnDebug(DEBUG_DEV,"myDataPath.Rx")
	// Check for Session Update
	SWITCH(myDataPath.LastHTTP.URL){
		CASE '/FriendlyName.cgx':{
			// Get Friendly Name
			pValue = fnGetJSONValue('FriendlyName',myDataPath.Rx)
			IF(LENGTH_ARRAY(pValue)){
				IF(myDataPath.NAME != pValue){
					myDataPath.NAME = pValue
					SEND_STRING vdvControl, "'PROPERTY-META,MAKE,DataPath'"
					SEND_STRING vdvControl, "'PROPERTY-META,MODEL,FX4'"
					SEND_STRING vdvControl, "'PROPERTY-META,NAME,',myDataPath.NAME"
				}
			}
		}
		CASE '/SerialNumber.cgx':{
			// Get Serial Number
			pValue = fnGetJSONValue('SerialNumber',myDataPath.Rx)
			IF(LENGTH_ARRAY(pValue)){
				IF(myDataPath.SERIAL_NUMBER != pValue){
					myDataPath.SERIAL_NUMBER = pValue
					SEND_STRING vdvControl, "'PROPERTY-META,SN,',myDataPath.SERIAL_NUMBER"
				}
			}
		}
		CASE '/SystemInfo.cgx':{
			// Get Firmware Version
			pValue = fnGetJSONValue('FirmwareVersion',myDataPath.Rx)
			IF(LENGTH_ARRAY(pValue)){
				IF(myDataPath.FIRMWARE_VER != pValue){
					myDataPath.FIRMWARE_VER = pValue
					SEND_STRING vdvControl, "'PROPERTY-META,FW_VER,',myDataPath.FIRMWARE_VER"
				}
			}
		}
		CASE '/ActiveInput.cgx':{
			// Get Active Input
			pValue = fnGetJSONValue('Input',myDataPath.Rx)
			IF(LENGTH_ARRAY(pValue)){
				IF(myDataPath.INPUT_ACTIVE != ATOI(pValue)){
					myDataPath.INPUT_ACTIVE = ATOI(pValue)
					SEND_STRING vdvControl, "'INPUT-ACTIVE,',ITOA(myDataPath.INPUT_ACTIVE)"
				}
			}
		}
		CASE '/PreferredInput.cgx':{
			// Get Preferred Input
			pValue = fnGetJSONValue('Input',myDataPath.Rx)
			IF(LENGTH_ARRAY(pValue)){
				IF(myDataPath.INPUT_PREFERED != ATOI(pValue)){
					myDataPath.INPUT_PREFERED = ATOI(pValue)
					SEND_STRING vdvControl, "'INPUT-PREFERRED,',ITOA(myDataPath.INPUT_PREFERED)"
				}
			}
		}
	}
	
	fnDebug(DEBUG_STD,"'fnProcessFeedback() HTTP ETX-----------------------------'")
	
	IF(RESPONSE_CODE == 200){
		fnTimeoutConnection(FALSE)
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		RETURN 200
	}
}
DEFINE_FUNCTION CHAR[500] fnGetJSONValue(CHAR pKey[100], CHAR pJSON[2000]){
	STACK_VAR pJSON_COPY[2000]
	pJSON_COPY = pJSON
	IF(FIND_STRING(pJSON_COPY,"'"',pKey,'"'",1)){
		REMOVE_STRING(pJSON_COPY,"'"',pKey,'"'",1)
		REMOVE_STRING(pJSON_COPY,"':'",1)
		REMOVE_STRING(pJSON_COPY,"'"'",1)
		RETURN(fnStripCharsRight(REMOVE_STRING(pJSON_COPY,'"',1),1))
	}
}
/******************************************************************************
	Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Called'")
	fnPoll()
	fnDebug(DEBUG_DEV,"'TIMELINE_EVENT','TLID_POLL Ended'")
}

DEFINE_FUNCTION fnPoll(){
	fnDebug(DEBUG_DEV,"'fnPoll()','Called'")
	fnSendRequest(HTTP_TYPE_GET,'/FriendlyName.cgx','')
	fnSendRequest(HTTP_TYPE_GET,'/SerialNumber.cgx','')
	fnSendRequest(HTTP_TYPE_GET,'/SystemInfo.cgx','')
	fnSendRequest(HTTP_TYPE_GET,'/PreferredInput.cgx','')
	fnSendRequest(HTTP_TYPE_GET,'/ActiveInput.cgx','')
	fnDebug(DEBUG_DEV,"'fnPoll()','Ended'")
	
}
/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'POLL':fnPoll()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myDataPath.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myDataPath.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myDataPath.IP_HOST = DATA.TEXT
							myDataPath.IP_PORT = 80 
						}
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myDataPath.DEBUG = DEBUG_STD
							CASE 'DEV': myDataPath.DEBUG = DEBUG_DEV
							DEFAULT:    myDataPath.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'INPUT':{
				
				fnSendRequest(HTTP_TYPE_POST,'/PreferredInput.cgx',"'{"Input": ',ITOA(fnInputToInteger(DATA.TEXT)),'}'")
			}
		}
	}
}
/******************************************************************************
	IP Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDataPath]{
	STRING:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','STRING Called'")
		//fnDebugHTTP(DEBUG_DEV,"'DP->',myDataPath.Rx")
		fnDebug(DEBUG_DEV,"'DATA_EVENT','STRING Ended'")
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','OFFLINE Called'")
		fnDebugHTTP(DEBUG_STD,'DP->',myDataPath.Rx)
		myDataPath.CONN_STATE = CONN_STATE_OFFLINE
		fnProcessFeedback()
		myDataPath.Rx = ''
		fnSendFromQueue()
		fnDebug(DEBUG_DEV,"'DATA_EVENT','OFFLINE Ended'")
	}
	ONLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONLINE Called'")
		myDataPath.CONN_STATE = CONN_STATE_CONNECTED
		IF(LENGTH_ARRAY(myDataPath.Tx[1].REQUEST)){
			SEND_STRING DATA.DEVICE, myDataPath.Tx[1].REQUEST
			fnDebugHTTP(DEBUG_DEV,'->DP',myDataPath.Tx[1].REQUEST)
		}
		IF(1){
			STACK_VAR INTEGER x
			STACK_VAR uHTTP blankHTTP
			myDataPath.LastHTTP = myDataPath.Tx[1]
			FOR(x = 1; x <= 9; x++){
				myDataPath.Tx[x] = myDataPath.Tx[x+1]
			}
			myDataPath.Tx[10] = blankHTTP
		}
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONLINE Ended'")
	}
	ONERROR:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONERROR Called'")
		myDataPath.CONN_STATE = CONN_STATE_OFFLINE
		fnDebug(TRUE,"'DataPath Error ',ITOA(DATA.NUMBER),':',DATA.TEXT")
		fnDebug(DEBUG_DEV,"'DATA_EVENT','ONERROR Ended'")
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/