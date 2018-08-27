MODULE_NAME='mMitsubishiProj'(DEV vdvControl,DEV dvDevice)
/******************************************************************************
	Basic Mitsubishi Projector Module
******************************************************************************/
INCLUDE 'CustomFunctions'
INCLUDE 'md5'
/******************************************************************************
	Basic module tested on the Mitsubishi 330
	
******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uMitsuProj{
	(** Current State **)
	INTEGER 	POWER
	CHAR 		INPUT[20]
	INTEGER 	MUTE
	INTEGER 	FREEZE
	(** Desired State **)
	CHAR 	  	desINPUT[20]
	INTEGER 	desMUTE
	INTEGER 	desFREEZE
	INTEGER 	desPOWER
	(** Comms **)
	CHAR 		PASSWORD[32]
	CHAR 		KEY[32]
	CHAR 		MD5[32]
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[128]
	INTEGER 	CONN_STATE
	INTEGER 	DEBUG
	CHAR 		Tx[500]
	INTEGER	TxPEND
	CHAR 		Rx[500]
}
DEFINE_CONSTANT
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2
LONG TLID_RETRY 			= 3
LONG TLID_BUSY 			= 4
LONG TLID_TIMEOUT			= 5

INTEGER desTRUE		= 2
INTEGER desFALSE		= 1

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

DEFINE_VARIABLE
VOLATILE uMitsuProj myMitsuProj

LONG TLT_POLL[]  	 = { 30000 }
LONG TLT_TIMEOUT[] = { 10000 }
LONG TLT_COMMS[] 	 = { 90000 }

DEFINE_START{
	CREATE_BUFFER dvDevice, myMitsuProj.Rx
	myMitsuProj.isIP = !dvDevice.NUMBER
	// Set Default Password
	IF(myMitsuProj.PASSWORD == ''){
		myMitsuProj.PASSWORD = 'admin'
	}
}
/******************************************************************************
	Utility Functions - Connections
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'TRY->Mitsu',"myMitsuProj.IP_HOST,':',ITOA(myMitsuProj.IP_PORT),'[',ITOA(dvDevice.PORT),']'")
	myMitsuProj.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myMitsuProj.IP_HOST, myMitsuProj.IP_PORT, IP_TCP) 
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnInitTimeout(){	
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myMitsuProj.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Utility Functions - Control
******************************************************************************/
DEFINE_FUNCTION fnAddCommandToQueue(CHAR pCmd[]){
	myMitsuProj.Tx = "myMitsuProj.Tx,'00',pCmd,$0D"
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnAddQueryToQueue(CHAR pCmd[]){
	myMitsuProj.Tx = "'00',myMitsuProj.Tx,pCmd,$0D"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myMitsuProj.TxPEND && FIND_STRING(myMitsuProj.Tx,"$0D",1) && myMitsuProj.CONN_STATE == CONN_STATE_CONNECTED){
		STACK_VAR CHAR toSend[100]
		toSend = REMOVE_STRING(myMitsuProj.Tx,"$0D",1)
		IF(myMitsuProj.isIP){
			toSend = "myMitsuProj.MD5,toSend"
			fnInitTimeout()
		}
		fnDebug(FALSE,'->MIT',toSend)
		SEND_STRING dvDevice,toSend
		myMitsuProj.TxPEND = TRUE
	}
}
/******************************************************************************
	Utility Functions - Data Recieve
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(FALSE,'MIT->',pData)
	IF(LEFT_STRING(pData,3) == '$AK'){
		GET_BUFFER_STRING(pData,3)
		myMitsuProj.KEY = pData
		myMitsuProj.MD5 = fnEncryptToMD5("myMitsuProj.KEY,myMitsuProj.PASSWORD")
		myMitsuProj.CONN_STATE = CONN_STATE_CONNECTED
		fnSendFromQueue()
	}
	ELSE{
		IF(LEFT_STRING(pData,2) == '00'){
			GET_BUFFER_STRING(pData,2)
			SELECT{
				ACTIVE(LEFT_STRING(pData,2) == 'vP'):{
					GET_BUFFER_STRING(pData,2)
					myMitsuProj.POWER = ATOI(pData)
					IF(myMitsuProj.POWER){
						fnAddQueryToQueue('MUTE')
						fnAddQueryToQueue('FRZ')
						fnAddQueryToQueue('vI')
					}
					ELSE{
						myMitsuProj.FREEZE = FALSE
						myMitsuProj.MUTE = FALSE
					}
					IF( myMitsuProj.desPOWER && (myMitsuProj.POWER != myMitsuProj.desPOWER-1)){
						SWITCH(myMitsuProj.desPOWER){
							CASE desFALSE: fnAddCommandToQueue("$21")
							CASE desTRUE:  fnAddCommandToQueue("$22")
						}
					}
					IF(myMitsuProj.POWER == myMitsuProj.desPOWER-1){
						myMitsuProj.desPOWER = 0
					}
				}
				ACTIVE(LEFT_STRING(pData,4) == 'MUTE'):{
					GET_BUFFER_STRING(pData,4)
					myMitsuProj.MUTE = ATOI(pData)
					IF(myMitsuProj.POWER){
						IF( myMitsuProj.desMUTE && (myMitsuProj.MUTE != myMitsuProj.desMUTE-1)){
							fnAddCommandToQueue("'MUTE',ITOA(myMitsuProj.desMUTE-1)")
						}
						IF(myMitsuProj.MUTE == myMitsuProj.desMUTE-1){
							myMitsuProj.desMUTE = 0
						}
					}
				}
				ACTIVE(LEFT_STRING(pData,1) == 'vI'):{
					GET_BUFFER_CHAR(pData)
					myMitsuProj.INPUT = pData
				}
			}
		}
	}
	myMitsuProj.TxPEND = FALSE
	// Terminate Timeout Timeline
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	// Restart Communications Timeline
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	fnSendFromQueue()
}
/******************************************************************************
	Polling Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnAddQueryToQueue("'vP'")
}
/******************************************************************************
	Physical Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myMitsuProj.isIP){
			fnDebug(FALSE,'CONN->Mitsu',"myMitsuProj.IP_HOST,':',ITOA(myMitsuProj.IP_PORT),'[',ITOA(dvDevice.PORT),']'")
			SEND_STRING dvDevice,"'$AK',$0D"
			fnInitTimeout()
		}
		ELSE{
			myMitsuProj.CONN_STATE = CONN_STATE_CONNECTED
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myMitsuProj.CONN_STATE = CONN_STATE_OFFLINE
		myMitsuProj.Tx = ''
	}
	ONERROR:{
		myMitsuProj.CONN_STATE = CONN_STATE_OFFLINE
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}					//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}					//Already Closed
			CASE 10:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE, "'Mitsu IP Error:[',myMitsuProj.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		myMitsuProj.Tx = ''
	}
	STRING:{
		WHILE(FIND_STRING(myMitsuProj.Rx,"$0D",1) > 0){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMitsuProj.Rx,"$0D",1),1));
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{		
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myMitsuProj.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myMitsuProj.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myMitsuProj.IP_HOST = DATA.TEXT
							myMitsuProj.IP_PORT = 63007
						}
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG': 	myMitsuProj.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');	
				}
			}
			CASE 'ADJUST':{
				SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnAddCommandToQueue("$70,$30,$39")
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'HDMI1':myMitsuProj.desINPUT = '_r1'
				}
				
				SWITCH(myMitsuProj.POWER){
					CASE TRUE:	fnAddCommandToQueue("myMitsuProj.desINPUT")
					CASE FALSE:	fnAddCommandToQueue("$21")
				}
			}
			CASE 'RAW':{
				fnAddCommandToQueue(DATA.TEXT)
			}
			CASE 'MUTE':{	
				SWITCH(DATA.TEXT){
					CASE 'ON':	myMitsuProj.desMUTE = desTRUE
					CASE 'OFF':	myMitsuProj.desMUTE = desFALSE
					CASE 'TOGGLE':{
						IF(myMitsuProj.desMUTE){myMitsuProj.desMUTE = (!myMitsuProj.desMUTE-1)+1}
						ELSE{myMitsuProj.desMUTE = (!myMitsuProj.MUTE) + 1}
					}
				}
				IF(myMitsuProj.POWER && myMitsuProj.MUTE != myMitsuProj.desMUTE-1){
					fnAddCommandToQueue("'MUTE',ITOA(myMitsuProj.desMUTE-1)")
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnAddCommandToQueue("$21")
						myMitsuProj.desPOWER = desTRUE
					}
					CASE 'OFF':{
						fnAddCommandToQueue("$22")
						myMitsuProj.desPOWER = desFALSE
					}
				}
			}
		}
	}
}
/******************************************************************************
	Control Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,211] = (myMitsuProj.MUTE)
	[vdvControl,214] = (myMitsuProj.FREEZE)
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,255] = (myMitsuProj.POWER)
}
/******************************************************************************
	EoF
******************************************************************************/
