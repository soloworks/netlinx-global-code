MODULE_NAME='mMartinLighting'(DEV vdvDevice,DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module for monitoring Solstice Pod based on an HTML / HTTP Response
******************************************************************************/
DEFINE_TYPE STRUCTURE uMartin{
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	CHAR 		Rx[10000]
	CHAR 		Tx[1000]
	INTEGER	HEADER_DONE
	INTEGER 	DEBUG
	INTEGER	CONN_STATE
	CHAR		WebPanelName[100]
	INTEGER 	DISABLED				// Disable Module
}

DEFINE_CONSTANT
INTEGER CONN_OFFLINE = 0
INTEGER CONN_TRYING	= 1
INTEGER CONN_ONLINE	= 2

LONG TLID_POLL = 1
LONG TLID_COMM = 2

DEFINE_VARIABLE
VOLATILE uMartin myMartin
LONG TLT_POLL[] = {45000}
LONG TLT_COMM[] = {120000}

DEFINE_EVENT DATA_EVENT[vdvDevice]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(DATA.TEXT){
			CASE 'PROPERTY-ENABLED,FALSE':myMartin.DISABLED = TRUE
			CASE 'PROPERTY-ENABLED,TRUE': myMartin.DISABLED = FALSE
		}
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'CUE':{
						fnGET("'CUE_',fnPadLeadingChars(DATA.TEXT,'0',4)")
					}
					CASE 'CLEAR':{
						fnGET("'FNC_',ITOA(ATOI(DATA.TEXT)+214)")
					}
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{	
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myMartin.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myMartin.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myMartin.IP_HOST = DATA.TEXT
							myMartin.IP_PORT = 80 
						}
					}
					CASE 'HTML':	myMartin.WebPanelName = DATA.TEXT
					CASE 'DEBUG':	myMartin.DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
		}
	}
	ONLINE:{
		IF(!myMartin.DISABLED){
			fnInitPoll()
		}
	}
}

DEFINE_START{
	CREATE_BUFFER ipDevice, myMartin.Rx
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,"'Trying '","myMartin.IP_HOST,':',ITOA(myMartin.IP_PORT)")
	myMartin.CONN_STATE = CONN_TRYING
	ip_client_open(ipDevice.port, "myMartin.IP_HOST", myMartin.IP_PORT, IP_TCP) 
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myMartin.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvDevice.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION INTEGER fnProcessHeader(CHAR pDATA[10000]){
	// Process First Line
	STACK_VAR CHAR pHeaderLine[1000]
	STACK_VAR INTEGER HTTP_CODE
	pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
	fnDebug(FALSE,'MAR->',pHeaderLine)
	REMOVE_STRING(pHeaderLine,' ',1)
	HTTP_CODE = ATOI(REMOVE_STRING(pHeaderLine,' ',1))
	// Process rest of fields
	WHILE(FIND_STRING(pDATA,"$0D,$0A",1)){
		pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
		IF(pHeaderLine = ''){
			RETURN HTTP_CODE
		}
		ELSE{
			fnDebug(FALSE,'MAR->',pHeaderLine)
		}
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnGET('')
}

DEFINE_FUNCTION fnGET(pDATA[]){
	STACK_VAR CHAR toSend[1000]
	(** Build Header **)
	toSend = "toSend,'GET /',myMartin.WebPanelName"
	IF(LENGTH_ARRAY(pDATA)){
		toSend = "toSend,'?LJM_',pDATA"
	}
	toSend = "toSend,' HTTP/1.0',$0D,$0A"
	toSend = "toSend,'Host: ',myMartin.IP_HOST,':',ITOA(myMartin.IP_PORT),$0D,$0A"
	toSend = "toSend,$0D,$0A"
	myMartin.Tx = "myMartin.Tx,toSend"
	IF(myMartin.CONN_STATE == CONN_OFFLINE){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}
	
DEFINE_EVENT DATA_EVENT[ipDevice]{
	STRING:{
		IF(!myMartin.DISABLED){
			STACK_VAR INTEGER HEAD_END_LOC
			STACK_VAR INTEGER BODY_LEN
			STACK_VAR INTEGER HEAD_TITLE
			STACK_VAR INTEGER HEAD_LINE_END
			fnDebug(FALSE,'MAR->',"'HTTP Response Recieved - Buffer Size [',ITOA(LENGTH_ARRAY(myMartin.Rx)),']'")
			(** Locate Body Size **)
			HEAD_TITLE = FIND_STRING(myMartin.Rx,'Content-Length:',1)
			IF(HEAD_TITLE){
				HEAD_LINE_END = FIND_STRING(myMartin.Rx,"$0D,$0A",HEAD_TITLE)
			}
			IF(HEAD_TITLE && HEAD_LINE_END){
				BODY_LEN = ATOI(MID_STRING(myMartin.Rx,HEAD_TITLE+15,HEAD_LINE_END-HEAD_TITLE+15))
				fnDebug(FALSE,'MAR->',"'HTTP Body Size is [',ITOA(BODY_LEN),']'")
			}
			HEAD_END_LOC = FIND_STRING(myMartin.Rx,"$0D,$0A,$0D,$0A",1)
			IF(HEAD_END_LOC && !myMartin.HEADER_DONE){
				STACK_VAR INTEGER HTTP_CODE
				fnDebug(FALSE,'MAR->AMX','HTTP Header Found')
				HTTP_CODE = fnProcessHeader(REMOVE_STRING(myMartin.Rx,"$0D,$0A,$0D,$0A",1))
				SWITCH(HTTP_CODE){
					CASE 200:{fnDebug(FALSE,'MAR->AMX','HTTP Response 200')}
					DEFAULT:{
						fnDebug(TRUE,"'HTTP Response ',ITOA(HTTP_CODE)","myMartin.WebPanelName")
					}
				}
				myMartin.HEADER_DONE = TRUE
			}
			ELSE{
				fnDebug(FALSE,'MAR->AMX','HTTP Header Done, Ignoring Body Data')
			}
		}
	}
	OFFLINE:{
		myMartin.Rx = ''
		myMartin.CONN_STATE = CONN_OFFLINE
		IF(FIND_STRING(myMartin.Tx,"$0D,$0A,$0D,$0A",1)){
			fnOpenTCPConnection()
		}
	}
	ONLINE:{    
		STACK_VAR CHAR toSend[1000]
		toSend = REMOVE_STRING(myMartin.Tx,"$0D,$0A,$0D,$0A",1)
		myMartin.CONN_STATE = CONN_ONLINE
		fnDebug(FALSE,'->MAR',toSend)
		myMartin.HEADER_DONE = FALSE
		SEND_STRING ipDevice,toSend
	}    
	ONERROR:{
		fnDebug(TRUE,'Martin Error',ITOA(DATA.NUMBER))
		SWITCH(DATA.NUMBER){
			CASE 2:{fnDebug(FALSE, "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{fnDebug(TRUE,  "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{fnDebug(TRUE,  "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{fnDebug(TRUE,  "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{fnDebug(FALSE, "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{fnDebug(FALSE, "'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'IP Error:[',myMartin.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:myMartin.CONN_STATE = CONN_OFFLINE
		}
	}
}

DEFINE_PROGRAM{
	[vdvDevice,251] = (TIMELINE_ACTIVE(TLID_COMM))
	[vdvDevice,252] = (TIMELINE_ACTIVE(TLID_COMM))
}
