MODULE_NAME='mKramer3000'(DEV vdvControl,DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/27/2013  AT: 14:39:01        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the VP-730

******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uConn{
	(** Comms **)
	INTEGER 	STATE
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[128]
	INTEGER	iSIP
	INTEGER  PEND
	CHAR 		Tx[500]
	CHAR 		Rx[500]

}
DEFINE_TYPE STRUCTURE uKramer3K{
	(** System MetaData **)
	CHAR   	MODEL[50]
	CHAR	 	PROT_VER[10]
	CHAR	 	SERIAL_NO[20]
	CHAR	 	VERSION[10]

	SINTEGER GAIN_VALUE			// Current Volume Level
	INTEGER	GAIN_PEND_STATE	// True if Volume Send is Pending
	SINTEGER	GAIN_PEND_VALUE	// Value for a pending Volume
	INTEGER	MUTE					// Current Audio Mute State

	INTEGER 	DEBUG
	uConn    CONN
}
DEFINE_CONSTANT
LONG TLID_COMMS			= 1
LONG TLID_POLL				= 2
LONG TLID_RETRY 			= 3
LONG TLID_VOL				= 4
LONG TLID_TIMEOUT			= 5

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER MODEL_IN1604	= 1

DEFINE_VARIABLE
VOLATILE uKramer3K myKramer3K

LONG TLT_POLL[]    = {	 30000 }
LONG TLT_COMMS[]   = {	 90000 }
LONG TLT_RETRY[]   = {	  5000 }
LONG TLT_VOL[]   	 = {    250  }
LONG TLT_TIMEOUT[] = {    3000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myKramer3K.CONN.Rx
	myKramer3K.CONN.isIP = (!dvDevice.NUMBER)
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'CONN->KRA',"myKramer3K.CONN.IP_HOST,':',ITOA(myKramer3K.CONN.IP_PORT)")
	myKramer3K.CONN.STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myKramer3K.CONN.IP_HOST, myKramer3K.CONN.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnRetryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('MODEL?','')
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], CHAR pParam[]){
	// Add Command
	myKramer3K.CONN.Tx = "myKramer3K.CONN.Tx,'#',pCMD"
	IF(LENGTH_ARRAY(pPARAM)){
		myKramer3K.CONN.Tx = "myKramer3K.CONN.Tx,' ',pPARAM"
	}
	myKramer3K.CONN.Tx = "myKramer3K.CONN.Tx,$0D"
	// Send command
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myKramer3K.CONN.PEND && myKramer3K.CONN.STATE == CONN_STATE_CONNECTED && FIND_STRING(myKramer3K.CONN.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[255]
		toSend = REMOVE_STRING(myKramer3K.CONN.Tx,"$0D",1)
		fnDebug(FALSE,'->K3K',toSend)
		SEND_STRING dvDevice,toSend
		myKramer3K.CONN.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myKramer3K.CONN.Tx = ''
	myKramer3K.CONN.Rx = ''
	myKramer3K.CONN.PEND = FALSE
	IF(myKramer3K.CONN.isIP){
		fnCloseTCPConnection()
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(FALSE,'K3K->',pData)

	// Process Data
	REMOVE_STRING(pData,'@',1)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'MODEL':{
			IF(myKramer3K.MODEL != pData){
				myKramer3K.MODEL = pData
				SEND_STRING vdvControl,"'PROPERTY-META,MAKE,KRAMER'"
				SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myKramer3K.MODEL"
				SWITCH(myKramer3K.MODEL){
					CASE 'PA-240Z':{
						SEND_STRING vdvControl,'RANGE--80,10'
						fnAddToQueue('AUD-LVL?','1,1')
						fnAddToQueue('MUTE?','1')
					}
				}
			}
		}
		CASE 'AUD-LVL':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
				CASE '1':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
						CASE '1':{
							myKramer3K.GAIN_VALUE = ATOI(pData)
						}
					}
				}
			}
		}
		CASE 'MUTE':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
				CASE '1':{
					myKramer3K.MUTE = ATOI(pData)
				}
			}
		}
	}

	// Reset
	myKramer3K.CONN.PEND = FALSE
	fnSendFromQueue()

	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myKramer3K.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myKramer3K.CONN.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		myKramer3K.CONN.STATE = CONN_STATE_CONNECTED
		fnPoll()
	}
	OFFLINE:{
		myKramer3K.CONN.STATE = CONN_STATE_OFFLINE
		fnReTryConnection()
	}
	ONERROR:{
		SWITCH(DATA.NUMBER){			//Listening Error
			CASE 14:{
				fnDebug(FALSE,"'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")
			}
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
					CASE 4:{ fnDebug(TRUE,  "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
					CASE 6:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
					CASE 7:{ fnDebug(TRUE,  "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
					CASE 8:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
					CASE 9:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
					CASE 10:{fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
					CASE 11:{fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 				//Local Port Already Used
					CASE 15:{fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
					CASE 16:{fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
					CASE 17:{fnDebug(FALSE, "'Kramer IP Error:[',myKramer3K.CONN.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
				}
				myKramer3K.CONN.STATE = CONN_STATE_OFFLINE
				fnRetryConnection()
			}
		}
	}
	STRING:{
		fnDebug(FALSE,'RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myKramer3K.CONN.Rx,"$0D,$0A",1) > 0){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myKramer3K.CONN.Rx,"$0D,$0A",1),2));
		}
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR pCOMMAND[100]
		pCOMMAND = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(pCOMMAND){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myKramer3K.CONN.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myKramer3K.CONN.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myKramer3K.CONN.IP_HOST = DATA.TEXT
							myKramer3K.CONN.IP_PORT = 5000
						}
						fnOpenTCPConnection()
						fnInitPoll()
					}
					CASE 'DEBUG': myKramer3K.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice, "DATA.TEXT,$0D"
			}
			CASE 'CONNECTION':{
				SWITCH(DATA.TEXT){
					CASE 'BREAK':fnCloseTCPConnection()
				}
			}
			CASE 'INPUT':
			CASE 'MATRIX':
			CASE 'AMATRIX':
			CASE 'VMATRIX':{
				STACK_VAR CHAR pTYPE[5]
				STACK_VAR INTEGER pDest
				STACK_VAR INTEGER pSrc
				SWITCH(pCOMMAND){
					CASE 'MATRIX':		pTYPE = '12'
					CASE 'INPUT':
					CASE 'VMATRIX':	pTYPE = '1'
					CASE 'AMATRIX':	pTYPE = '2'
				}
				SWITCH(pCOMMAND){
					CASE 'INPUT':{
						pSrc = ATOI(DATA.TEXT)
						pDest = 1
					}
					DEFAULT:{
						pSRC = ATOI(fnGetSplitStringValue(DATA.TEXT,'*',1))-1
						pDest = ATOI(fnGetSplitStringValue(DATA.TEXT,'*',2))-1
					}
				}
				fnAddToQueue('ROUTE',"pTYPE,',',ITOA(pDest),',',ITOA(pSrc)")
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	myKramer3K.MUTE = TRUE
					CASE 'OFF':	myKramer3K.MUTE = FALSE
					CASE 'TOGGLE':myKramer3K.MUTE = !myKramer3K.MUTE
				}
				fnAddToQueue('MUTE',"'1,',ITOA(myKramer3K.MUTE)")
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':fnAddToQueue('AUD-LVL',"'1,1,',ITOA(myKramer3K.GAIN_VALUE+5)")
					CASE 'DEC':fnAddToQueue('AUD-LVL',"'1,1,',ITOA(myKramer3K.GAIN_VALUE-5)")
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_VOL)){
							fnAddToQueue('AUD-LVL',"'1,1,',DATA.TEXT")
							myKramer3K.GAIN_VALUE = ATOI(DATA.TEXT)
							TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myKramer3K.GAIN_PEND_VALUE = ATOI(DATA.TEXT)
							myKramer3K.GAIN_PEND_STATE = TRUE
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myKramer3K.GAIN_PEND_STATE){
		fnAddToQueue('AUD-LVL',"'1,1,',ITOA(myKramer3K.GAIN_PEND_VALUE)")
		myKramer3K.GAIN_VALUE = myKramer3K.GAIN_PEND_VALUE
		myKramer3K.GAIN_PEND_STATE = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myKramer3K.GAIN_VALUE
	[vdvControl,199] = myKramer3K.MUTE
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
}
/******************************************************************************
	EoF
******************************************************************************/