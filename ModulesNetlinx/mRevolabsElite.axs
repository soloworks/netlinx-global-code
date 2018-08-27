MODULE_NAME='mRevolabsElite'(DEV vdvControl,DEV vdvMics[],DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	
	Revolabs control module.
	RS232 or IP
	For IP, the Revolabs is required to be pointed to the AMX IP address and use
	port 5051 by default (change with COMMAND: PROPERTY-PORT,xxxx)

******************************************************************************/
DEFINE_CONSTANT
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_USERSENT		= 2
INTEGER IP_STATE_PASSSENT		= 3
INTEGER IP_STATE_CONNECTED		= 4

DEFINE_TYPE STRUCTURE uExecElite{
	// Comms
	CHAR 		RX[1000]
	CHAR 		TX[1000]
	INTEGER	IP_PORT
	CHAR		IP_HOST[255]
	INTEGER	IP_STATE 
	CHAR		IP_USERNAME[20]
	CHAR		IP_PASSWORD[20]
	INTEGER	isIP
	INTEGER	PEND
	INTEGER 	DEBUG
	// Device State
	CHAR 		PRODUCT_NAME[20]
	CHAR 		IP_ADDRESS[15]
	CHAR		BASE_SN[20]
}

DEFINE_TYPE STRUCTURE uMicrophone{
	INTEGER 		BATTERY
	INTEGER 		STATUS
	INTEGER		MUTE
}
DEFINE_CONSTANT
LONG TLID_POLL 		= 1
LONG TLID_RETRY 		= 2
LONG TLID_COMM 		= 3
LONG TLID_TIMEOUT		= 4

DEFINE_VARIABLE
VOLATILE uExecElite myExecElite
VOLATILE uMicrophone myMic[8]
	
LONG TLT_COMMS[] 		= {90000}
LONG TLT_POLL[] 		= {30000}
LONG TLT_RETRY[] 		= {5000}
LONG TLT_TIMEOUT[]	= {  3000 }
/******************************************************************************
	Helper Functions
******************************************************************************/

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myExecElite.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg,'[',ITOA(LENGTH_ARRAY(MsgData)),'][', MsgData,']'"
	}
}
DEFINE_FUNCTION fnInitPoll(){	
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnInitData(){
	STACK_VAR INTEGER x
	fnAddToQueue('get productname')
	fnAddToQueue('get serialnumber base')
	fnAddToQueue('get currentipaddress')
	FOR(x = 1; x <= LENGTH_ARRAY(vdvMics); x++){
		fnAddToQueue("'get micstatus ch ',ITOA(x)")
	}
	FOR(x = 1; x <= LENGTH_ARRAY(vdvMics); x++){
		fnAddToQueue("'get mute ch ',ITOA(x)")
	}
}

DEFINE_FUNCTION fnPoll(){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvMics); x++){
		fnAddToQueue("'get mute ch ',ITOA(x)")
	}
}

DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[]){
	myExecElite.Tx = "myExecElite.Tx,pDATA,$0A"
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myExecElite.IP_STATE == IP_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	IF(myExecElite.IP_STATE == IP_STATE_CONNECTED && !myExecElite.PEND && FIND_STRING(myExecElite.Tx,"$0A",1)){
		STACK_VAR CHAR toSend[50]
		toSend = REMOVE_STRING(myExecElite.Tx,"$0A",1)
		fnDebug(FALSE,'->REVO',toSend)
		SEND_STRING dvDevice, "toSend"
		myExecElite.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT), TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	
	STACK_VAR INTEGER pCHAN
	
	IF(RIGHT_STRING(pDATA,1) == "$0A"){
		pDATA = fnStripCharsRight(pDATA,1)
	}
	
	fnDebug(FALSE,'REVO->',"pData")
	
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'val':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'currentipaddress':{
					IF(myExecElite.IP_ADDRESS != pDATA){
						myExecElite.IP_ADDRESS = pDATA
					}
				}
				CASE 'productname':{
					myExecElite.PRODUCT_NAME = pDATA
				}
				CASE 'serialnumber':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
						CASE 'base':{
							myExecElite.BASE_SN = pDATA
						}
					}
				}
				CASE 'micstatus':{
					REMOVE_STRING(pDATA,' ',1)
					pCHAN = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
					myMic[pCHAN].STATUS = ATOI(pDATA)
				}
				CASE 'mutestatus':{
					REMOVE_STRING(pDATA,' ',1)
					pCHAN = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
					myMic[pCHAN].MUTE = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
				}
				CASE 'mute':{
					REMOVE_STRING(pDATA,' ',1)
					pCHAN = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
					myMic[pCHAN].MUTE = ATOI(pDATA)
				}
			}
			myExecElite.PEND = FALSE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			fnSendFromQueue()
		}
		CASE 'notify':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'status_change_battery':{
					pCHAN = ATOI(RIGHT_STRING(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1),1))
					myMic[pCHAN].BATTERY = ATOI(pDATA)
				}
			}
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
				CASE 'set_mute_status':{
					pCHAN = ATOI(RIGHT_STRING(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1),1))
					myMic[pCHAN].MUTE = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
				}
			}
		}
	}
	
	IF(TIMELINE_ACTIVE(TLID_COMM)){TIMELINE_KILL(TLID_COMM)}
	TIMELINE_CREATE(TLID_COMM,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myExecElite.IP_HOST == ''){
		fnDebug(TRUE,'RevoLabs IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to RevoLabs on ',"myExecElite.IP_HOST,':',ITOA(myExecElite.IP_PORT)")
		myExecElite.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myExecElite.IP_HOST, myExecElite.IP_PORT, IP_TCP) 
	}
} 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	IP Control
******************************************************************************/
DEFINE_START{
	myExecElite.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myExecElite.RX
}
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myExecElite.isIP){
			myExecElite.IP_STATE = IP_STATE_CONNECTED
			SEND_COMMAND dvDevice,'SET BAUD 19200 N,8,1 485 DISABLE'
			fnInitData()
		}
	}
	OFFLINE:{
		IF(myExecElite.isIP){
			myExecElite.IP_STATE	= IP_STATE_OFFLINE
			myExecElite.Rx = ''
			myExecElite.Tx = ''
			myExecElite.PEND = FALSE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myExecElite.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myExecElite.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'RevoLabs IP Error:[',myExecElite.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(FALSE,'REVO.Raw->',DATA.TEXT)
		// Telnet Negotiation
		WHILE(myExecElite.Rx[1] == $FF && LENGTH_ARRAY(myExecElite.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myExecElite.Rx,3)
			fnDebug(FALSE,'REVO.Telnet->',NEG_PACKET)
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(FALSE,'->REVO.Telnet',NEG_PACKET)
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}
		// 
		IF(FIND_STRING(LOWER_STRING(myExecElite.Rx),'login',1)){
			fnDebug(FALSE,'REVO.Login->',myExecElite.RX)
			fnDebug(FALSE,'->REVO.Login',"myExecElite.IP_USERNAME,$0A")
			SEND_STRING dvDevice,"myExecElite.IP_USERNAME,$0A"
			myExecElite.IP_STATE = IP_STATE_USERSENT
			myExecElite.RX = ''
		}
		ELSE IF(FIND_STRING(LOWER_STRING(myExecElite.Rx),'password',1)){
			fnDebug(FALSE,'REVO.Password->',myExecElite.RX)
			fnDebug(FALSE,'->REVO.Password',"myExecElite.IP_PASSWORD,$0A")
			SEND_STRING dvDevice,"myExecElite.IP_PASSWORD,$0A"
			myExecElite.IP_STATE = IP_STATE_PASSSENT
			myExecElite.RX = ''
		}
		ELSE{
			IF(myExecElite.IP_STATE == IP_STATE_CONNECTED){
				WHILE(FIND_STRING(myExecElite.RX,"$0D",1)){
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myExecElite.RX,"$0D",1),1))
				}
			}
			ELSE IF(myExecElite.Rx = "$0D,$0A,$0D"){
				myExecElite.Rx = ''
				myExecElite.IP_STATE = IP_STATE_CONNECTED
				SEND_STRING dvDevice,"'regnotify',$0A"
				fnInitData()
			}
		}
	}
}
/******************************************************************************
	Actual Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myExecElite.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myExecElite.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myExecElite.IP_HOST = DATA.TEXT
							myExecElite.IP_PORT = 23 
						}
						fnRetryConnection()
					}
					CASE 'LOGIN':{
						myExecElite.IP_USERNAME = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myExecElite.IP_PASSWORD = DATA.TEXT
					}
					CASE 'DEBUG':myExecElite.DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
			CASE 'CONNECT':{
				SWITCH(DATA.TEXT){
					CASE 'TRUE':	fnOpenTCPConnection()
					CASE 'FALSE':	fnCloseTCPConnection()
				}
			}
			CASE 'RAW':{
				fnAddToQueue(DATA.TEXT)
			}
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvMics]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'MICMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnAddToQueue("'set mute ch ',ITOA(GET_LAST(vdvMics)),' 1'")
					CASE 'OFF':	fnAddToQueue("'set mute ch ',ITOA(GET_LAST(vdvMics)),' 0'")
				}
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvMics); x++){
		[vdvMics[x],198] = myMic[x].MUTE
		SEND_LEVEL vdvMics[x],2,myMic[x].BATTERY
		SEND_LEVEL vdvMics[x],3,myMic[x].STATUS
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMM))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMM))
}





















