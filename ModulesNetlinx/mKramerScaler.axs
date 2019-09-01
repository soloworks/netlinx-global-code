MODULE_NAME='mKramerScaler'(DEV vdvControl, DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/27/2013  AT: 14:39:01        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the VP-730
	Inputs: (INPUT-)
	[PARAM]	- [Actual]	- FB Chan
	IN1		- Input 1	- 1
	IN2		- Input 2	- 2
	VGA1		- VGA 1		- 3
	VGA2		- VGA 2		- 4
	VGA3		- VGA 3		- 5
	VGA4		- VGA 4		- 6
	HDMI1		- HDMI 1		- 7
	HDMI2		- HDMI 2		- 8
	USB		- USB			- 9
******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uKramerSwitcher{
	(** System State **)
	SINTEGER VOLUME
	INTEGER READY
	(** Comms **)
	INTEGER isIP
	INTEGER PORT
	CHAR IP[128]
	INTEGER TRYING
	INTEGER CONNECTED
	INTEGER DEBUG
	CHAR Tx[500]
	CHAR Rx[500]
}
DEFINE_CONSTANT
LONG TLID_SEND_TIMEOUT	= 1
LONG TLID_POLL				= 2
LONG TLID_COMMS			= 3
LONG TLID_RETRY 			= 4

INTEGER 	_iSTEP			= 5
SINTEGER _iVolMin 		= -100
SINTEGER _iVolMax 		= 24
INTEGER defPORT			= 10001

DEFINE_VARIABLE
uKramerSwitcher myKramerSwitcher
LONG TLT_SEND_TIMEOUT[] = {5000}
LONG TLT_POLL[]  = {60000}
LONG TLT_COMMS[] = {300000}
LONG TLT_RETRY[] = {10000}		//
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myKramerSwitcher.Rx
	myKramerSwitcher.isIP = (!dvDevice.NUMBER)
	myKramerSwitcher.READY  = TRUE
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!myKramerSwitcher.PORT){myKramerSwitcher.PORT = defPORT}
	fnDebug(FALSE,'Connect->KRA',"myKramerSwitcher.IP,':',ITOA(myKramerSwitcher.PORT)")
	myKramerSwitcher.TRYING = TRUE
	ip_client_open(dvDevice.port, myKramerSwitcher.IP, myKramerSwitcher.PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnTryConnection()
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSetCommand( INTEGER pTYPE, INTEGER pFUNC,INTEGER pPARAM ){
	STACK_VAR CHAR toSend[255]
	toSend = "'Y ',ITOA(pTYPE),' ',ITOA(pFUNC)"
	IF(pPARAM){ toSend = "toSend,' ',ITOA(pPARAM)" }
	toSend = "toSend,$0D"
	fnActualSend(toSend)
}
DEFINE_FUNCTION fnActualSend(CHAR _CMD[50]){
	IF(myKramerSwitcher.READY){
		IF(myKramerSwitcher.isIP){fnDebug(FALSE,'AMX->KRA',_CMD)}
		SEND_STRING dvDevice, "_CMD"
		myKramerSwitcher.READY = FALSE
		IF(TIMELINE_ACTIVE(TLID_SEND_TIMEOUT)){ TIMELINE_KILL(TLID_SEND_TIMEOUT) }
		TIMELINE_CREATE(TLID_SEND_TIMEOUT,TLT_SEND_TIMEOUT,LENGTH_ARRAY(TLT_SEND_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE{
		myKramerSwitcher.Tx = "myKramerSwitcher.Tx,_CMD"
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND_TIMEOUT]{
	myKramerSwitcher.Tx = ''
	myKramerSwitcher.READY = TRUE
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	fnDebug(FALSE,'KRA->AMX',pData)
	IF(pData[1] == 'Z'){
		REMOVE_STRING(pData,' ',1)	// Remove 'Z '
		REMOVE_STRING(pData,' ',1)	// Remove Flag
		SWITCH(fnStripCharsRight(REMOVE_STRING(pData,' ',1),1)){
			CASE '48':{		// Audio Volume
				SEND_STRING vdvControl, "'VOLUME-',ITOA(ATOI(pData)+100)"
				SEND_LEVEL vdvControl, 1 ,(ATOI(pData)+100)
			}
			CASE '101':{		// Mute
				SWITCH(DATA.TEXT){
					CASE '1':ON[vdvControl,199]
					CASE '0':OFF[vdvControl,199]
				}
			}
			CASE '0':{		// Input
				SEND_STRING vdvControl, "'INPUT-',pData"
			}
		}
	}
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myKramerSwitcher.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Physical Events
******************************************************************************/

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myKramerSwitcher.isIP){
			fnDebug(FALSE,'Connected',DATA.TEXT)
			myKramerSwitcher.CONNECTED = TRUE
			myKramerSwitcher.TRYING = FALSE
		}
		ELSE{
			SEND_COMMAND dvDevice,'SET MODE DATA'
			SEND_COMMAND dvDevice,'SET BAUD 9600 N 8 1 485 DISABLE'
		}
	}
	OFFLINE:{
		myKramerSwitcher.CONNECTED = FALSE;
		myKramerSwitcher.TRYING = FALSE;
		fnTryConnection();
	}
	ONERROR:{
		myKramerSwitcher.CONNECTED = FALSE
		myKramerSwitcher.TRYING = FALSE
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'Kramer IP Error:[',myKramerSwitcher.IP,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		fnTryConnection()
	}
	STRING:{
		fnDebug(FALSE,'KRA->AMX RAW',DATA.TEXT)
		WHILE(FIND_STRING(myKramerSwitcher.Rx,"$0D,$0A",1) > 0){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myKramerSwitcher.Rx,"$0D,$0A",1),2));
		}
		IF(myKramerSwitcher.Rx[1] == '>'){
			GET_BUFFER_CHAR(myKramerSwitcher.Rx)
			IF(FIND_STRING(myKramerSwitcher.Tx,"$0D",1)){
				STACK_VAR CHAR toSend[25]
				toSend = REMOVE_STRING(myKramerSwitcher.Tx,"$0D",1)
				IF(myKramerSwitcher.isIP){fnDebug(FALSE,'AMX->KRA',toSend)}
				SEND_STRING dvDevice, toSend
			}
			ELSE{
				myKramerSwitcher.READY = TRUE
			}
		}
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP': 	  {
						myKramerSwitcher.IP = DATA.TEXT;
						IF(myKramerSwitcher.CONNECTED){
							fnCloseTCPConnection()
						}
						ELSE IF(!myKramerSwitcher.TRYING){
							fnOpenTCPConnection();
						}
					}
					CASE 'DEBUG': myKramerSwitcher.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
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
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'CV1':		fnSetCommand(3,0,1)
					CASE 'CV2':		fnSetCommand(3,0,2)
					CASE 'COMP1':	fnSetCommand(3,0,3)
					CASE 'COMP2':	fnSetCommand(3,0,4)
					CASE 'PC1':		fnSetCommand(3,0,5)
					CASE 'PC2':		fnSetCommand(3,0,6)
					CASE 'HDMI1':	fnSetCommand(3,0,7)
					CASE 'HDMI2':	fnSetCommand(3,0,8)
					CASE 'HDMI3':	fnSetCommand(3,0,9)
					CASE 'HDMI4':	fnSetCommand(3,0,10)
				}
			}
			/*
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnSetCommand('101','1')
					CASE 'OFF': fnSetCommand('101','0')
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':{
						IF(iKramVol <= _iVolMax - _iSTEP){	iKramVol = iKramVol + _iSTEP	}
						ELSE{	iKramVol = _iVolMax	}
					}
					CASE 'DEC':{
						IF(iKramVol >= _iVolMin + _iSTEP){	iKramVol = iKramVol - _iSTEP	}
						ELSE{	iKramVol = _iVolMin	}
					}
					DEFAULT:		{
						STACK_VAR SINTEGER UserVol
						UserVol = ATOI(DATA.TEXT)
						iKramVol = UserVol - 100
					}
					CASE '?':	fnGetCommand('48')
				}
				IF(DATA.TEXT != '?'){
					fnSetCommand('48',ITOA(iKramVol))
				}
			}
			*/
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
}