MODULE_NAME='mBoschCamera'(DEV vdvControl,DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module for monitoring Solstice Pod based on an HTML / HTTP Response

	Live Stream 1: rtsp://192.168.64.239/
	Live Stream 2: rtsp://192.168.64.239/video?inst=2

******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uBoschCamera{
	// Communications
	CHAR 		IP_HOST[255]
	INTEGER 	IP_PORT
	INTEGER	IP_CONN_STATE
	INTEGER 	DEBUG
	CHAR 		Rx[5000]
	CHAR		Tx[5000]
	// State
	LONG		PAN
	LONG		TILT
	LONG		ZOOM
}

/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER IP_STATE_IDLE			= 0
INTEGER IP_STATE_REQUESTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

LONG TLID_POLL = 1
LONG TLID_COMM = 2

DEFINE_VARIABLE
VOLATILE uBoschCamera myBoschCamera
LONG TLT_POLL[] = {  10000 }
LONG TLT_COMM[] = { 120000 }

/******************************************************************************
	Connection Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnStartHTTPConnection(){
	IF(!LENGTH_ARRAY(myBoschCamera.IP_HOST)){
		fnDebug(TRUE,'Bosch IP not set','')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Bosch on',"myBoschCamera.IP_HOST,':',ITOA(myBoschCamera.IP_PORT)")
		myBoschCamera.IP_CONN_STATE = IP_STATE_REQUESTING
		ip_client_open(ipDevice.port, myBoschCamera.IP_HOST, myBoschCamera.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseHTTPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnDebug(INTEGER pForce, CHAR Msg[], CHAR MsgData[]){
	IF(myBoschCamera.DEBUG || pForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.NUMBER),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnDebugHTTP(CHAR Msg[], CHAR MsgData[]){
	IF(myBoschCamera.DEBUG)	{
		WHILE(FIND_STRING(MsgData,"$0D,$0A",1)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.NUMBER),':',Msg, ':', REMOVE_STRING(MsgData,"$0D,$0A",1)"
		}
		IF(LENGTH_ARRAY(MsgData)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.NUMBER),':',Msg, ':', MsgData"
		}
	}
}
/******************************************************************************
	Command Format Utlity Functions
******************************************************************************/

DEFINE_FUNCTION CHAR[1000] fnGetBICOMviaRCP(CHAR pREQ[2],CHAR pBOSCHID[4],CHAR pObjectID[4],CHAR pOperation[]){
	STACK_VAR CHAR pReturn[1000]
	pReturn = 'rcp.xml?command=0x09a5&type=P_OCTET&direction=WRITE&'
	pReturn = "pReturn,'payload=0x',pREQ,pBOSCHID,pObjectID,pOperation"
	RETURN pReturn
}
/******************************************************************************
	Command Queuing Utlity Functions
******************************************************************************/

DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[]){
	STACK_VAR CHAR pRequest[1000]
	(** Build Header **)
	pRequest = "pRequest,'GET /',pDATA,' HTTP/1.1',$0D,$0A"
	pRequest = "pRequest,'Host: ',myBoschCamera.IP_HOST,$0D,$0A"
	pRequest = "pRequest,$0D,$0A"
	myBoschCamera.Tx = "myBoschCamera.Tx,pRequest"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myBoschCamera.IP_CONN_STATE == IP_STATE_IDLE && FIND_STRING(myBoschCamera.Tx,"$0D,$0A,$0D,$0A",1)){
		fnStartHTTPConnection()
		fnInitPoll()
	}
}
/******************************************************************************
	Polling Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue(fnGetBICOMviaRCP('80','0006','0112','01')) // Get Pan Position
	fnAddToQueue(fnGetBICOMviaRCP('80','0006','0113','01')) // Get Tilt Position
	fnAddToQueue(fnGetBICOMviaRCP('80','0006','0114','01')) // Get Zoom Position
}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, myBoschCamera.Rx
}

/******************************************************************************
	HTTP Device Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	STRING:{
		STACK_VAR INTEGER HEAD_END_LOC
		STACK_VAR INTEGER BODY_LEN
		STACK_VAR INTEGER HEAD_TITLE
		STACK_VAR INTEGER HEAD_LINE_END
		//fnDebug(FALSE,'BOSCH->',DATA.TEXT)
		//fnDebug(FALSE,'BOSCH->',"'HTTP Response Recieved - Buffer Size [',ITOA(LENGTH_ARRAY(DATA.TEXT)),']'")
		(** Locate Body Size **)
		HEAD_TITLE = FIND_STRING(LOWER_STRING(myBoschCamera.Rx),LOWER_STRING('Content-Length:'),1)
		IF(HEAD_TITLE){
			HEAD_LINE_END = FIND_STRING(myBoschCamera.Rx,"$0D,$0A",HEAD_TITLE)
		}
		IF(HEAD_TITLE && HEAD_LINE_END){
			BODY_LEN = ATOI(MID_STRING(myBoschCamera.Rx,HEAD_TITLE+15,HEAD_LINE_END-HEAD_TITLE+15))
			//fnDebug(FALSE,'BOSCH->',"'HTTP Body Size is [',ITOA(BODY_LEN),']'")
		}
		HEAD_END_LOC = FIND_STRING(myBoschCamera.Rx,"$0D,$0A,$0D,$0A",1)
		IF(HEAD_END_LOC){
			IF(LENGTH_ARRAY(myBoschCamera.Rx) == HEAD_END_LOC+3+BODY_LEN){
				STACK_VAR INTEGER HTTP_RESP_CODE
				//fnDebug(FALSE,'BOSCH->','HTTP Full Response Gathered - Processing')
				HTTP_RESP_CODE = fnProcessHTTPHeader(GET_BUFFER_STRING(myBoschCamera.Rx,HEAD_END_LOC+3))
				IF(HTTP_RESP_CODE == 200){
					fnProcessBody()
				}
				ELSE{
					fnDebug(TRUE,'BOSCH->',"'Error: HTTP CODE ',ITOA(HTTP_RESP_CODE)")
				}
				myBoschCamera.Rx = ''
			}
			ELSE{
				fnDebug(FALSE,'BOSCH->','Buffer: HTTP Gathering Body...')
			}
		}
		ELSE{
			fnDebug(FALSE,'BOSCH->','Buffer: HTTP Gathering Header...')
		}
	}
	OFFLINE:{
		myBoschCamera.Rx = ''
		myBoschCamera.IP_CONN_STATE = IP_STATE_IDLE
		fnSendFromQueue()
	}
	ONLINE:{
		STACK_VAR CHAR toSend[1000]
		myBoschCamera.IP_CONN_STATE = IP_STATE_CONNECTED
		toSend = REMOVE_STRING(myBoschCamera.Tx,"$0D,$0A,$0D,$0A",1)
		SEND_STRING ipDevice,toSend
		fnDebugHTTP('->BOSCH',toSend)
	}
	ONERROR:{
		STACK_VAR CHAR pERROR[50]
		SWITCH(DATA.NUMBER){
			CASE 14:pERROR = 'Local Port Already Used'
			CASE 17:pERROR = 'Local Port Not Open'						//Local Port Not Open
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE  2:pERROR = 'General Failure'					//General Failure - Out Of Memory
					CASE  4:pERROR = 'Unknown Host'						//Unknown Host
					CASE  6:pERROR = 'Conn Refused'						//Connection Refused
					CASE  7:pERROR = 'Conn Timed Out'					//Connection Timed Out
					CASE  8:pERROR = 'Unknown'								//Unknown Connection Error
					CASE  9:pERROR = 'Already Closed'					//Already Closed
					CASE 10:pERROR = 'Binding Error' 					//Binding Error
					CASE 11:pERROR = 'Listening Error' 					//Listening Error
					CASE 15:pERROR = 'UDP Socket Already Listening' //UDP socket already listening
					CASE 16:pERROR = 'Too many open Sockets'			//Too many open sockets
				}
				myBoschCamera.Tx = ''
				myBoschCamera.IP_CONN_STATE = IP_STATE_IDLE
			}
		}
		fnDebug(TRUE,'BOSCH->',"'Error: ',ITOA(DATA.NUMBER),'-',pERROR")
	}
}
/******************************************************************************
	HTTP Utility Functions
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessHTTPHeader(CHAR pHEAD[1000]){
	STACK_VAR INTEGER HTTP_RESP_CODE
	fnDebug(FALSE,'BOSCH->','HTTP HEADER - Processing')
	WHILE(FIND_STRING(pHEAD,"$0D,$0A",1)){
		STACK_VAR CHAR HEAD_LINE[200]
		HEAD_LINE = REMOVE_STRING(pHEAD,"$0D,$0A",1)
		SELECT{
			ACTIVE(FIND_STRING(HEAD_LINE,'HTTP/',1)):{
				STACK_VAR INTEGER RESPCODE_START
				STACK_VAR INTEGER RESPCODE_END
				RESPCODE_START = FIND_STRING(HEAD_LINE,' ',1)
				RESPCODE_END = FIND_STRING(HEAD_LINE,' ',RESPCODE_START+1)
				HTTP_RESP_CODE = ATOI(MID_STRING(HEAD_LINE,RESPCODE_START+1,RESPCODE_END))
				fnDebug(FALSE,'BOSCH->AMX',"'HTTP Response Code [',ITOA(HTTP_RESP_CODE),']'")
			}
		}
	}
	RETURN HTTP_RESP_CODE
}
DEFINE_FUNCTION fnProcessBody(){
	fnDebug(FALSE,'BOSCH->','fnProcessBody()')
	IF(!LENGTH_ARRAY(myBoschCamera.Rx)){
		fnDebug(FALSE,'BOSCH->','Error: HTTP Body Empty')
		RETURN
	}
	// Processing Code Here
	IF(1){
		STACK_VAR CHAR 	str_ContentRaw[100]
		STACK_VAR CHAR 	str_ContentNoSpaces[100]
		REMOVE_STRING(myBoschCamera.Rx,'<str>',1)
		str_ContentRaw = fnStripCharsRight(REMOVE_STRING(myBoschCamera.Rx,'</str>',1),LENGTH_ARRAY('</str>'))
		WHILE(LENGTH_ARRAY(str_ContentRaw)){
			IF(str_ContentRaw[1] == ' '){
				GET_BUFFER_CHAR(str_ContentRaw)
			}
			ELSE{
				str_ContentNoSpaces = "str_ContentNoSpaces,GET_BUFFER_CHAR(str_ContentRaw)"
			}
		}
		SWITCH(GET_BUFFER_STRING(str_ContentNoSpaces,12)){
			CASE '800006011201':myBoschCamera.PAN  = HEXTOI(str_ContentNoSpaces)
			CASE '800006011301':myBoschCamera.TILT = HEXTOI(str_ContentNoSpaces)
			CASE '800006011401':myBoschCamera.ZOOM = HEXTOI(str_ContentNoSpaces)
		}
	}
}
DEFINE_FUNCTION fnProcessHTTPErrorBody(CHAR pDATA[2000],INTEGER pCODE){
	fnDebug(TRUE,'BOSCH->',"'HTTP ERROR CODE [',ITOA(pCODE),']'")
	WHILE(LENGTH_ARRAY(pDATA)){
		fnDebug(TRUE,'BOSCH->',"'HTTP ERROR [',GET_BUFFER_STRING(pDATA,100)")
	}
}
/******************************************************************************
	Module Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myBoschCamera.IP_HOST = DATA.TEXT
						myBoschCamera.IP_PORT = 80
						fnPoll()
					}
					CASE 'DEBUG':{
						myBoschCamera.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'PRESET':{
				STACK_VAR INTEGER pPreset
				pPreset = ATOI(DATA.TEXT)
				fnAddToQueue(fnGetBICOMviaRCP('80','0002','01B0',"'800705',fnPadLeadingChars(ITOHEX(pPreset),'0',2)"))
			}
			CASE 'PTZ':{
				STACK_VAR CHAR pDATA[6]
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'LEFT':	pDATA = "'0',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1),'0000'"
					CASE 'RIGHT': 	pDATA = "'8',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1),'0000'"
					CASE 'DOWN':	pDATA = "'000',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1),'00'"
					CASE 'UP': 		pDATA = "'008',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1),'00'"
					CASE 'OUT': 	pDATA = "'00000',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1)"
					CASE 'IN': 		pDATA = "'00008',RIGHT_STRING(ITOHEX(ATOI(DATA.TEXT)),1)"
					DEFAULT:			pDATA = "'000000'"
				}
				fnAddToQueue(fnGetBICOMviaRCP('80','0006','0110',"'85',pDATA")) // Get Pan Position
			}
		}
	}
}
DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myBoschCamera.PAN
	SEND_LEVEL vdvControl,2,myBoschCamera.TILT
	SEND_LEVEL vdvControl,3,myBoschCamera.ZOOM
}
/******************************************************************************
	EoF
******************************************************************************/