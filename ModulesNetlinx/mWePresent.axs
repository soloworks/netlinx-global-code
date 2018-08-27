﻿MODULE_NAME='mWePresent'(DEV vdvDevice,DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module for monitoring Solstice Pod based on an HTML / HTTP Response
******************************************************************************/
DEFINE_TYPE STRUCTURE uWePresent{
	CHAR 		IP_HOST[255]
	INTEGER	IP_PORT
	CHAR 		Rx[10000]
	CHAR 		Tx[1000]
	INTEGER	HEADER_DONE
	INTEGER 	DEBUG
	INTEGER	CONN_STATE
	CHAR		DEVICE_NAME[100]
	INTEGER  DISABLED				// Disable Module
}

DEFINE_CONSTANT
INTEGER CONN_OFFLINE = 0
INTEGER CONN_TRYING	= 1
INTEGER CONN_ONLINE	= 2

LONG TLID_POLL = 1
LONG TLID_COMM = 2

DEFINE_VARIABLE
VOLATILE uWePresent myWePresent
LONG TLT_POLL[] = {45000}
LONG TLT_COMM[] = {120000}

DEFINE_EVENT DATA_EVENT[vdvDevice]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(DATA.TEXT){
			CASE 'PROPERTY-ENABLED,FALSE':myWePresent.DISABLED = TRUE
			CASE 'PROPERTY-ENABLED,TRUE': myWePresent.DISABLED = FALSE
		}
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'QUERY':fnSendQuery()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{	
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myWePresent.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myWePresent.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myWePresent.IP_HOST = DATA.TEXT
							myWePresent.IP_PORT = 80 
						}
						fnSendQuery()
						fnInitPoll()
					}
					CASE 'DEBUG':	myWePresent.DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
		}
	}
}

DEFINE_START{
	CREATE_BUFFER ipDevice, myWePresent.Rx
}

DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,"'Trying '","myWePresent.IP_HOST,':',ITOA(myWePresent.IP_PORT)")
	myWePresent.CONN_STATE = CONN_TRYING
	ip_client_open(ipDevice.port, "myWePresent.IP_HOST", myWePresent.IP_PORT, IP_TCP) 
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myWePresent.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvDevice.Number),':',Msg, ':', MsgData"
	}
}


DEFINE_FUNCTION INTEGER fnProcessHeader(CHAR pDATA[10000]){
	// Process First Line
	STACK_VAR CHAR pHeaderLine[1000]
	STACK_VAR INTEGER HTTP_CODE
	pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
	fnDebug(FALSE,'WeP->',pHeaderLine)
	REMOVE_STRING(pHeaderLine,' ',1)
	HTTP_CODE = ATOI(REMOVE_STRING(pHeaderLine,' ',1))
	// Process rest of fields
	WHILE(FIND_STRING(pDATA,"$0D,$0A",1)){
		pHeaderLine = fnStripCharsRight(REMOVE_STRING(pDATA,"$0D,$0A",1),2)
		IF(pHeaderLine = ''){
			RETURN HTTP_CODE
		}
		ELSE{
			fnDebug(FALSE,'WeP->',pHeaderLine)
			IF(FIND_STRING(pHeaderLine,'lighttpd',1)){
				fnDebug(FALSE,'WeP->','COMMS_TRIGGER')
				IF(TIMELINE_ACTIVE(TLID_COMM)){TIMELINE_KILL(TLID_COMM)}
				TIMELINE_CREATE(TLID_COMM,TLT_COMM,LENGTH_ARRAY(TLT_COMM),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendQuery()
}

DEFINE_FUNCTION fnSendQuery(){
	STACK_VAR CHAR toSend[1000]
	(** Dump If Requested **)
	
	(** Build Header **)
	toSend = "toSend,'GET / HTTP/1.0',$0D,$0A"
	toSend = "toSend,'Host: ',myWePresent.IP_HOST,':',ITOA(myWePresent.IP_PORT),$0D,$0A"
	toSend = "toSend,$0D,$0A"
	myWePresent.Tx = "myWePresent.Tx,toSend"
	IF(myWePresent.CONN_STATE == CONN_OFFLINE){
		fnOpenTCPConnection()
	}
}
	
DEFINE_EVENT DATA_EVENT[ipDevice]{
	STRING:{
		IF(!myWePresent.DISABLED){
			STACK_VAR INTEGER HEAD_END_LOC
			STACK_VAR INTEGER BODY_LEN
			STACK_VAR INTEGER HEAD_TITLE
			STACK_VAR INTEGER HEAD_LINE_END
			fnDebug(FALSE,'WeP->',"'HTTP Response Recieved - Buffer Size [',ITOA(LENGTH_ARRAY(myWePresent.Rx)),']'")
			(** Locate Body Size **)
			HEAD_TITLE = FIND_STRING(myWePresent.Rx,'Content-Length:',1)
			IF(HEAD_TITLE){
				HEAD_LINE_END = FIND_STRING(myWePresent.Rx,"$0D,$0A",HEAD_TITLE)
			}
			IF(HEAD_TITLE && HEAD_LINE_END){
				BODY_LEN = ATOI(MID_STRING(myWePresent.Rx,HEAD_TITLE+15,HEAD_LINE_END-HEAD_TITLE+15))
				fnDebug(FALSE,'WeP->',"'HTTP Body Size is [',ITOA(BODY_LEN),']'")
			}
			HEAD_END_LOC = FIND_STRING(myWePresent.Rx,"$0D,$0A,$0D,$0A",1)
			IF(HEAD_END_LOC && !myWePresent.HEADER_DONE){
				STACK_VAR INTEGER HTTP_CODE
				fnDebug(FALSE,'WeP->AMX','HTTP Header Found')
				HTTP_CODE = fnProcessHeader(REMOVE_STRING(myWePresent.Rx,"$0D,$0A,$0D,$0A",1))
				SWITCH(HTTP_CODE){
					CASE 200:{fnDebug(FALSE,'WeP->AMX','HTTP Response 200')}
					DEFAULT:{
						fnDebug(TRUE,'HTTP Response Code ',ITOA(HTTP_CODE))
					}
				}
				myWePresent.HEADER_DONE = TRUE
			}
			ELSE{
				fnDebug(FALSE,'WeP->AMX','HTTP Header Done, Skimming Body Data')
				IF(FIND_STRING(myWePresent.Rx,'<title>',1) && FIND_STRING(myWePresent.Rx,'</title>',1)){
					STACK_VAR INTEGER pStart
					STACK_VAR INTEGER pEnd
					STACK_VAR CHAR 	pName[100]
					pStart 	= FIND_STRING(myWePresent.Rx,'<title>',1) + 7
					pEnd 		= FIND_STRING(myWePresent.Rx,'</title>',1) - pStart 
					fnDebug(FALSE,'Start/End',"ITOA(pStart),'/',ITOA(pEnd)")
					pName 	= MID_STRING(myWePresent.Rx,pStart,pEnd)
					IF(myWePresent.DEVICE_NAME != pName){
						myWePresent.DEVICE_NAME = pName
						SEND_STRING vdvDevice,"'PROPERTY-META,TITLE,',myWePresent.DEVICE_NAME"
					}
				}
				GET_BUFFER_STRING(myWePresent.Rx,LENGTH_ARRAY(myWePresent.Rx)-100)
			}
		}
	}
	OFFLINE:{
		myWePresent.Rx = ''
		myWePresent.HEADER_DONE = FALSE
		myWePresent.CONN_STATE = CONN_OFFLINE
		IF(FIND_STRING(myWePresent.Tx,"$0D,$0A,$0D,$0A",1)){
			fnOpenTCPConnection()
		}
	}
	ONLINE:{    
		STACK_VAR CHAR toSend[1000]
		toSend = REMOVE_STRING(myWePresent.Tx,"$0D,$0A,$0D,$0A",1)
		myWePresent.CONN_STATE = CONN_ONLINE
		fnDebug(FALSE,'->WeP',toSend)
		myWePresent.HEADER_DONE = FALSE
		SEND_STRING ipDevice,toSend
	}    
	ONERROR:{
		IF(myWePresent.CONN_STATE == CONN_ONLINE){
			myWePresent.CONN_STATE = CONN_OFFLINE
			fnCloseTCPConnection()
		}
		fnDebug(TRUE,'WeTransfer Error',ITOA(DATA.NUMBER))
		SWITCH(DATA.NUMBER){
			CASE 2:{fnDebug(FALSE, "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{fnDebug(TRUE,  "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{fnDebug(TRUE,  "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{fnDebug(TRUE,  "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{fnDebug(FALSE, "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{fnDebug(FALSE, "'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'IP Error:[',myWePresent.IP_HOST,']'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:myWePresent.CONN_STATE = CONN_OFFLINE
		}
	}
}

DEFINE_PROGRAM{
	[vdvDevice,251] = (TIMELINE_ACTIVE(TLID_COMM))
	[vdvDevice,252] = (TIMELINE_ACTIVE(TLID_COMM))
}