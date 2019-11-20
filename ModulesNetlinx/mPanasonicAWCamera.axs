MODULE_NAME='mPanasonicAWCamera'(DEV vdvControl, DEV dvCamera)
INCLUDE 'CustomFunctions'
/******************************************************************************
	IP via HTTP Get Request control of Panasonic Cameras
	Tested against the AW-HE60HE
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uCamera{
	// State
	INTEGER 	POWER
	CHAR		META_MODEL[20]
	INTEGER	PAN_MAX
	INTEGER	PAN_MIN
	INTEGER 	TILT_MAX
	INTEGER	TILT_MIN
	INTEGER 	ZOOM_MIN
	INTEGER	ZOOM_MAX
	INTEGER	curPTZ[3]
	// Comms
	CHAR 		IP_ADD[15]
	INTEGER 	IP_PORT
	INTEGER 	DEBUG
	CHAR 		Rx[1000]
	CHAR		Tx[1000]
	INTEGER	TRYING
	INTEGER 	CONNECTED
	INTEGER 	LAST_POLL
}
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_BOOT 	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 3

INTEGER POLL_STATE 	= 1
INTEGER POLL_PanTilt = 2
INTEGER POLL_Zoom		= 3

DEFINE_VARIABLE
VOLATILE uCamera myCamera
LONG TLT_BOOT[] 	= { 5000 }
LONG TLT_POLL[]	= { 45000 }
LONG TLT_COMMS[]	= { 180000 }
/******************************************************************************
	Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myCamera.IP_ADD)){
		fnDebug(TRUE,'Camera IP Address Not Set','')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Camera',"myCamera.IP_ADD,':',ITOA(myCamera.IP_PORT)")
		myCamera.TRYING = TRUE
		ip_client_open(dvCamera.port, myCamera.IP_ADD, myCamera.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvCamera.port)
}

DEFINE_FUNCTION fnDebug(INTEGER pForce, CHAR Msg[], CHAR MsgData[]){
	IF(myCamera.DEBUG || pForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnDebugHTTP(CHAR Msg[], CHAR MsgData[]){
	IF(myCamera.DEBUG)	{
		WHILE(FIND_STRING(MsgData,"$0D,$0A",1)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', REMOVE_STRING(MsgData,"$0D,$0A",1)"
		}
		IF(LENGTH_ARRAY(MsgData)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
		}
	}
}

DEFINE_FUNCTION fnURLGetRequest(CHAR pSERVICE[],CHAR pPARAMS[],INTEGER isQUERY){
	STACK_VAR CHAR toSend[1000]
	STACK_VAR IP_ADDRESS_STRUCT _tThisIP
	GET_IP_ADDRESS(0:1:0,_tThisIp)
	(** Build Header **)
	toSend = "toSend,'GET ',pSERVICE"
	IF(LENGTH_ARRAY(pPARAMS)){
		toSend = "toSend,'?',pPARAMS"
	}
	toSend = "toSend,' HTTP/1.1',$0D,$0A"
	toSend = "toSend,'Host: ',_tThisIp.IPADDRESS,$0D,$0A"
	toSend = "toSend,'Connection: close',$0D,$0A"
	toSend = "toSend,$0D,$0A"
	(** Combine **)
	myCamera.Tx = "myCamera.Tx,toSend"
	fnDoSend()
	IF(!isQUERY){
		fnInitPoll()
	}
}
DEFINE_FUNCTION fnDoSend(){
	IF(!myCamera.TRYING && !myCamera.CONNECTED){
		fnOpenTCPConnection()
	}
}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvCamera, myCamera.Rx
	myCamera.IP_PORT = 80
}
/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	COMMAND:{
		STACK_VAR CHAR _cCMD[255]
		_cCMD = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(_cCMD){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myCamera.DEBUG = 1
						}
					}
					CASE 'IP':		myCamera.IP_ADD = DATA.TEXT
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':{
						fnInitPoll()
					}
				}
			}
			CASE 'GOTO':{
				STACK_VAR CHAR PAN[4]
				STACK_VAR CHAR TILT[4]
				STACK_VAR CHAR ZOOM[3]
				PAN  = fnPadLeadingChars(ITOHEX(ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))),'0',4)
				TILT = fnPadLeadingChars(ITOHEX(ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))),'0',4)
				ZOOM = fnPadLeadingChars(ITOHEX(ATOI(DATA.TEXT)),'0',3)
				fnSendCommand('/cgi-bin/aw_ptz',"'cmd=#APC',PAN,TILT,'&res=1'")
				fnSendCommand('/cgi-bin/aw_ptz',"'cmd=#AXZ',ZOOM,'&res=1'")
			}
			CASE 'PRESET':{
				fnSendCommand('/cgi-bin/aw_ptz',"'cmd=#R',fnPadLeadingChars(ITOA(ATOI(DATA.TEXT)-1),'0',2),'&res=1'")
			}
		}
	}
}
DEFINE_CONSTANT
INTEGER chnPanTilt[] = {
	132,	// Tilt Up
	133,	// Tilt Down
	134,	// Pan Left
	135	// Pan Right
}
INTEGER chnZoom[] = {
	158,	// Zoom Out
	159	// Zoom In
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,chnPanTilt]{
	ON:{
		SWITCH(CHANNEL.CHANNEL){
			CASE 132:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#T80&res=1')
			}
			CASE 133:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#T20&res=1')
			}
			CASE 134:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#P20&res=1')
			}
			CASE 135:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#P80&res=1')
			}
		}
	}
	OFF:{
		fnSendCommand('/cgi-bin/aw_ptz','cmd=#PTS5050&res=1')
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,chnZoom]{
	ON:{
		SWITCH(CHANNEL.CHANNEL){
			CASE 158:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#Z80&res=1')
			}
			CASE 159:{
				fnSendCommand('/cgi-bin/aw_ptz','cmd=#Z20&res=1')
			}
		}
	}
	OFF:{
		fnSendCommand('/cgi-bin/aw_ptz','cmd=#Z50&res=1')
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	fnSendPoll(POLL_STATE)
	fnInitPoll()
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendPoll(POLL_STATE)
}
DEFINE_FUNCTION fnSendPoll(INTEGER pPOLL_TYPE){
	myCamera.LAST_POLL = pPOLL_TYPE
	SWITCH(myCamera.LAST_POLL){
		CASE POLL_STATE:		fnURLGetRequest('/live/camdata.html','',FALSE)
		CASE POLL_PanTilt:	fnURLGetRequest('/cgi-bin/aw_ptz','cmd=#APC&res=1',FALSE)
		CASE POLL_Zoom:		fnURLGetRequest('/cgi-bin/aw_ptz','cmd=#GZ&res=1',FALSE)
	}

}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[],pPARAM[]){
	fnURLGetRequest(pCMD,pPARAM,FALSE)
}
/******************************************************************************
	HTTP Device Handling
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvCamera]{
	STRING:{
		STACK_VAR INTEGER HEAD_END_LOC
		STACK_VAR INTEGER BODY_LEN
		STACK_VAR INTEGER HEAD_TITLE
		STACK_VAR INTEGER HEAD_LINE_END
		//fnDebug(FALSE,'CAM->',DATA.TEXT)
		//fnDebug(FALSE,'CAM->',"'HTTP Response Recieved - Buffer Size [',ITOA(LENGTH_ARRAY(DATA.TEXT)),']'")
		(** Locate Body Size **)
		HEAD_TITLE = FIND_STRING(LOWER_STRING(myCamera.Rx),LOWER_STRING('Content-Length:'),1)
		IF(HEAD_TITLE){
			HEAD_LINE_END = FIND_STRING(myCamera.Rx,"$0D,$0A",HEAD_TITLE)
		}
		IF(HEAD_TITLE && HEAD_LINE_END){
			BODY_LEN = ATOI(MID_STRING(myCamera.Rx,HEAD_TITLE+15,HEAD_LINE_END-HEAD_TITLE+15))
			//fnDebug(FALSE,'CAM->',"'HTTP Body Size is [',ITOA(BODY_LEN),']'")
		}
		HEAD_END_LOC = FIND_STRING(myCamera.Rx,"$0D,$0A,$0D,$0A",1)
		IF(HEAD_END_LOC){
			IF(LENGTH_ARRAY(myCamera.Rx) == HEAD_END_LOC+3+BODY_LEN){
				STACK_VAR INTEGER HTTP_RESP_CODE
				//fnDebug(FALSE,'CAM->','HTTP Full Response Gathered - Processing')
				HTTP_RESP_CODE = fnProcessHTTPHeader(GET_BUFFER_STRING(myCamera.Rx,HEAD_END_LOC+3))
				IF(HTTP_RESP_CODE == 200){
					IF(myCamera.LAST_POLL){
						fnProcessPollResponse(myCamera.Rx)
					}
					ELSE{
						fnProcessOtherResponse(myCamera.Rx)
					}
				}
				ELSE{
					fnProcessHTTPErrorBody(myCamera.Rx,HTTP_RESP_CODE)
				}
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				myCamera.Rx = ''
			}
			ELSE{
				//fnDebug(FALSE,'CAM->','HTTP More Body Expected - Waiting')
			}
		}
		ELSE{
			//fnDebug(FALSE,'CAM->','HTTP More Header Expected - Waiting')
		}
	}
	OFFLINE:{
		myCamera.Rx = ''
		myCamera.CONNECTED = FALSE
		myCamera.TRYING = FALSE
		IF(FIND_STRING(myCamera.TX,"$0D,$0A,$0D,$0A",1)){
			fnDoSend()
		}
	}
	ONLINE:{
		STACK_VAR CHAR toSend[1000]
		myCamera.CONNECTED = TRUE
		myCamera.TRYING = FALSE
		toSend = REMOVE_STRING(myCamera.Tx,"$0D,$0A,$0D,$0A",1)
		SEND_STRING dvCamera,toSend
		fnDebugHTTP('->CAM',toSend)
	}
	ONERROR:{
		myCamera.CONNECTED = FALSE
		myCamera.TRYING = FALSE
		myCamera.LAST_POLL = 0
		fnDebug(TRUE,'CAM IP Error',ITOA(DATA.NUMBER))
		SWITCH(DATA.NUMBER){
			CASE 2:{fnDebug(FALSE, "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{fnDebug(TRUE,  "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{fnDebug(TRUE,  "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{fnDebug(TRUE,  "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{fnDebug(FALSE, "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{fnDebug(FALSE, "'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 						//Binding Error
			CASE 11:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}			//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'IP Error:[',myCamera.IP_ADD,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		//cSendStack = ''
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	myCamera.LAST_POLL = 0
	myCamera.Rx = ''
	myCamera.Tx = ''
	myCamera.CONNECTED = FALSE
	myCamera.TRYING = FALSE
}
/******************************************************************************
	HTTP Utility Functions
******************************************************************************/
DEFINE_FUNCTION INTEGER fnProcessHTTPHeader(CHAR pHEAD[1000]){
	STACK_VAR INTEGER HTTP_RESP_CODE
	fnDebug(FALSE,'CAM->','HTTP HEADER - Processing')
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
				fnDebug(FALSE,'CAM->AMX',"'HTTP Response Code [',ITOA(HTTP_RESP_CODE),']'")
			}
		}
	}
	RETURN HTTP_RESP_CODE
}
DEFINE_FUNCTION fnProcessPollResponse(CHAR pDATA[5000]){
	STACK_VAR INTEGER pCount
	IF(!LENGTH_ARRAY(pDATA)){
		fnDebug(FALSE,'CAM->','No Poll Body in Response')
		RETURN
	}
	fnDebug(FALSE,'CAM->','HTTP BODY - Processing')
	SWITCH(myCamera.LAST_POLL){
		CASE POLL_STATE:{
			GET_BUFFER_STRING(pDATA,3)	// Chew out unexplained "$EF,$BB,$BF"
			// Processing Code Here
			WHILE(FIND_STRING(pDATA,"$0D,$0A",1)){
				STACK_VAR CHAR pLine[50]
				pCount++
				pLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
				fnDebug(FALSE,'CAM->',"ITOA(pCount),':',pLine")
				SWITCH(pCount){
					CASE 1:{	// Power
						myCamera.POWER = ATOI("pLine[2]")
					}
					CASE 2:{	// Model
						GET_BUFFER_STRING(pLine,4)
						myCamera.META_MODEL = pLine
						myCamera.PAN_MIN  = $2D08
						myCamera.PAN_MAX  = $D2F5
						myCamera.TILT_MAX = $8E38
						myCamera.ZOOM_MIN = $555
						myCamera.ZOOM_MAX = $FFF
						SWITCH(myCamera.META_MODEL){
							CASE 'AW-HE50':
							CASE 'AW-HE60':{
								myCamera.TILT_MIN = $5556
							}
							CASE 'AW-HE120':{
								myCamera.TILT_MIN = $1C73
							}
						}
					}
				}
			}
			myCamera.LAST_POLL = 0
			IF(!(FIND_STRING(myCamera.Tx,"$0D,$0A,$0D,$0A",1))){
				fnSendPoll(POLL_PanTilt)
			}
		}
		CASE POLL_PanTilt:{

			myCamera.LAST_POLL = 0
			IF(!(FIND_STRING(myCamera.Tx,"$0D,$0A,$0D,$0A",1))){
				fnSendPoll(POLL_Zoom)
			}
		}
		CASE POLL_Zoom:{

			myCamera.LAST_POLL = 0
		}
	}
}
DEFINE_FUNCTION fnProcessOtherResponse(CHAR pDATA[5000]){
	IF(!LENGTH_ARRAY(pDATA)){
		fnDebug(FALSE,'CAM->','No Body in Response')
		RETURN
	}
	fnDebug(FALSE,'CAM->','HTTP BODY - Processing')
	// Processing Code Here
	fnDebug(FALSE,'CAM->',pDATA)
}
DEFINE_FUNCTION fnProcessHTTPErrorBody(CHAR pDATA[2000],INTEGER pCODE){
	fnDebug(TRUE,'CAM->',"'HTTP ERROR CODE [',ITOA(pCODE),']'")
	WHILE(LENGTH_ARRAY(pDATA)){
		fnDebug(TRUE,'CAM->',"'HTTP ERROR [',GET_BUFFER_STRING(pDATA,100)")
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}