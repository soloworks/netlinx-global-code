MODULE_NAME='mNECDisplay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Control Ltd (www.solocontrol.co.uk)

	NEC Screen - IP or RS232 control
	Single Screen control
	Requires ID & Control method setting up on display
	Inputs:
	HDMI1|HDMI2|DVI|RGB|VID1|VID2
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uComms{
	(** IP Comms Control **)
	INTEGER DISABLED
	INTEGER isIP
	INTEGER PEND
	INTEGER CONN_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	(** General Comms Control **)
	CHAR 	  Tx[1000]
	CHAR 	  TxPend[100]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
}
DEFINE_TYPE STRUCTURE uScreen{
	INTEGER 	ID
	// Meta Data
	CHAR 	  	MODEL[20]
	CHAR	  	SERIALNO[20]
	// State
	SINTEGER	DIAGNOSTICS
	SINTEGER POWER
	SINTEGER INPUT
	SINTEGER MUTE
	SINTEGER GAIN_CURRENT
	SINTEGER GAIN_RANGE[2]
	// Comms
	SINTEGER	GAIN_DESIRED
	SINTEGER	GAIN_PEND
	SINTEGER	GAIN_STEP
	// Desired Values
	SINTEGER desINPUT
	// Comms Sertings
	uComms	COMMS

	INTEGER  CARRIER_ENABLED
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timelines **)
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2
LONG TLID_SEND_TIMEOUT	= 3
LONG TLID_CLOSE_TIMEOUT = 4
LONG TLID_AUTOADJ 		= 5
LONG TLID_GAIN				= 6
LONG TLID_INPUT			= 7
LONG TLID_BOOT				= 8

INTEGER LVL_VOL_RAW = 1
INTEGER LVL_VOL_100 = 2
INTEGER LVL_VOL_255 = 3

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING			= 1
INTEGER CONN_STATE_CONNECTED		= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uScreen myNECDisplay
(** Timeline Times **)
LONG TLT_AUTOADJ[]			= {  3000}
LONG TLT_COMMS[]				= { 45000}
LONG TLT_POLL[]				= { 10000}
LONG TLT_GAIN[]				= {   400}
LONG TLT_SEND_TIMEOUT[]		= {  1000}
LONG TLT_CLOSE_TIMEOUT[]	= {  5000}
LONG TLT_BOOT[]				= {  5000}
/******************************************************************************
	System Startup & Defaults
******************************************************************************/
DEFINE_START{
	myNECDisplay.COMMS.isIP = !(dvDEVICE.NUMBER)
	myNECDisplay.GAIN_STEP 	= 2
	myNECDisplay.desInput 	= -1
	CREATE_BUFFER dvDevice, myNECDisplay.COMMS.Rx
}
/******************************************************************************
	Helper Functions - Communications
******************************************************************************/
// IP Connection Functions
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myNECDisplay.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'NEC IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,"'Connecting to NEC on '","myNECDisplay.COMMS.IP_HOST,':',ITOA(myNECDisplay.COMMS.IP_PORT)")
		myNECDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myNECDisplay.COMMS.IP_HOST, myNECDisplay.COMMS.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnSetGain(SINTEGER pGAIN){
	myNECDisplay.GAIN_DESIRED = pGAIN
	myNECDisplay.GAIN_PEND = TRUE
	IF(!TIMELINE_ACTIVE(TLID_GAIN)){
		fnSetParam('00','62',myNECDisplay.GAIN_DESIRED)
		myNECDisplay.GAIN_PEND = FALSE
		TIMELINE_CREATE(TLID_GAIN,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_GAIN]{
	IF(myNECDisplay.GAIN_PEND){
		fnSetParam('00','62',myNECDisplay.GAIN_DESIRED)
		myNECDisplay.GAIN_PEND = FALSE
		TIMELINE_CREATE(TLID_GAIN,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
// Command Queue Functions
DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[]){
	myNECDisplay.COMMS.Tx = "myNECDisplay.COMMS.Tx,pToSend,$0A,$0A,$0A"
	fnSendFromQueue()
	fnInitPoll()
}
(** Send with Delays between messages **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myNECDisplay.COMMS.CONN_STATE == CONN_STATE_CONNECTED && !myNECDisplay.COMMS.PEND){
		IF(FIND_STRING(myNECDisplay.COMMS.Tx,"$0A,$0A,$0A",1)){
			myNECDisplay.COMMS.TxPend = fnStripCharsRight(REMOVE_STRING(myNECDisplay.COMMS.Tx,"$0A,$0A,$0A",1),3)
			fnDebugHex(DEBUG_STD,'AMX->NEC',myNECDisplay.COMMS.TxPend);
			SEND_STRING dvDevice, myNECDisplay.COMMS.TxPend
			myNECDisplay.COMMS.PEND = TRUE
			fnInitSendTimeout()
			fnInitCloseTimeout()
		}
	}
	ELSE IF(myNECDisplay.COMMS.CONN_STATE == CONN_STATE_OFFLINE && myNECDisplay.COMMS.isIP){
		fnOpenTCPConnection();
	}
}
// Sending Failed Timeout
DEFINE_FUNCTION fnInitSendTimeout(){
	IF(TIMELINE_ACTIVE(TLID_SEND_TIMEOUT)){TIMELINE_KILL(TLID_SEND_TIMEOUT)}
	TIMELINE_CREATE(TLID_SEND_TIMEOUT,TLT_SEND_TIMEOUT,LENGTH_ARRAY(TLT_SEND_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND_TIMEOUT]{
	IF(TIMELINE.REPETITION == 3){
		TIMELINE_KILL(TLID_SEND_TIMEOUT)
		fnResetComms()
	}
	ELSE{
		fnDebugHex(DEBUG_STD,'AMX->NEC',myNECDisplay.COMMS.TxPend);
		SEND_STRING dvDevice, myNECDisplay.COMMS.TxPend
	}
}
// Connection Close Timeout
DEFINE_FUNCTION fnInitCloseTimeout(){
	IF(TIMELINE_ACTIVE(TLID_CLOSE_TIMEOUT)){TIMELINE_KILL(TLID_CLOSE_TIMEOUT)}
	TIMELINE_CREATE(TLID_CLOSE_TIMEOUT,TLT_CLOSE_TIMEOUT,LENGTH_ARRAY(TLT_CLOSE_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_CLOSE_TIMEOUT]{
	fnResetComms()
}
DEFINE_FUNCTION fnResetComms(){
	myNECDisplay.COMMS.Tx = ''
	myNECDisplay.COMMS.Rx = ''
	myNECDisplay.COMMS.TxPend = ''
	myNECDisplay.COMMS.PEND = FALSE
	IF(myNECDisplay.COMMS.isIP){ fnCloseTCPConnection() }
}
// Polling
DEFINE_FUNCTION fnInitPoll(){
	IF(!myNECDisplay.COMMS.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
		TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnGetCommand('01D6')	// Power Status Request
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myNECDisplay.COMMS.DISABLED){
		IF(!myNECDisplay.COMMS.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			myNECDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		}
		SEND_STRING  vdvControl, 'PROPERTY-META,TYPE,Display'
		SEND_STRING  vdvControl,"'PROPERTY-META,MAKE,NEC'"
		SEND_STRING  vdvControl, 'RANGE-0,100'
		SEND_STRING  vdvControl, 'PROPERTY-GAIN,RANGE,0,100'
		fnPoll()
	}
}
/******************************************************************************
	Helper Functions - Debugging
******************************************************************************/
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR pMSG[], CHAR pDATA[]){
	IF(myNECDisplay.COMMS.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMSG, ':', pDATA"
	}
}
(** Debugging Helper - Hex **)
DEFINE_FUNCTION fnDebugHex(INTEGER pLEVEL, CHAR pMSG[], CHAR pDATA[]){
	IF(myNECDisplay.COMMS.DEBUG >= pLEVEL)	{
		STACK_VAR CHAR myHexString[200]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(pDATA); x++){
			myHexString = "myHexString,fnPadLeadingChars(ITOHEX(pDATA[x]),'0',2)"
		}
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMSG, ':', myHexString"
	}
}
/******************************************************************************
	Utility Functions - NEC Message Builders
******************************************************************************/
DEFINE_FUNCTION fnGetParam(CHAR pOPP[2],CHAR pOPC[2]){
	fnDebug(DEBUG_DEV,'fnGetParam',"'pOPP=',pOPP,':','pOPC=',pOPC")
	fnBuildMsg($43, "$02,pOPP,pOPC,$03")
}

DEFINE_FUNCTION fnSetParam(CHAR pOPP[2],CHAR pOPC[2],SINTEGER  pPARAM){
	fnDebug(DEBUG_DEV,'fnSetParam',"'pOPP=',pOPP,':','pOPC=',pOPC,':','pPARAM=',ITOA(pPARAM)")
	fnBuildMsg($45,"$02,pOPP,pOPC,fnPadLeadingChars(ITOHEX(pPARAM),'0',4),$03")
}

DEFINE_FUNCTION fnGetCommand(CHAR pCMD[20]){
	fnDebug(DEBUG_DEV,'fnGetCommand',"'pCMD=',pCMD")
	fnBuildMsg($41,"$02,pCMD,$03")
}

DEFINE_FUNCTION fnSetCommand(CHAR pCMD[20],CHAR pPARAM[20]){
	fnDebug(DEBUG_DEV,'fnSetParam',"'pCMD=',pCMD,':','pPARAM=',pPARAM")
	fnBuildMsg($41,"$02,pCMD,pPARAM,$03")
}

(** Message Building Routine **)
DEFINE_FUNCTION fnBuildMsg(CHAR pType,CHAR pMSG[20]){
	STACK_VAR CHAR _TOSEND[50]
	STACK_VAR CHAR _HEADER[20]
	STACK_VAR CHAR _CHK
	STACK_VAR INTEGER _COUNT
	fnDebug(DEBUG_DEV,'fnBuildMsg',"'pType=',pType,':','pMSG=',pMSG")
	_HEADER = "_HEADER,$30"			// Reserved byte
	IF(myNECDisplay.ID == 0){ myNECDisplay.ID = 1 }
	IF(myNECDisplay.ID = 27){ _HEADER = "_HEADER,$2A" }		// All Monitors
	ELSE{ _HEADER = "_HEADER,$40+myNECDisplay.ID" }	// Monitor ID
	_HEADER = "_HEADER,$30"			// Source ID
	_HEADER = "_HEADER,pType"// Message 'Format'

	_HEADER = "_HEADER,fnPadLeadingChars(ITOHEX(LENGTH_ARRAY(pMSG)),$30,2)"

	_TOSEND = "_HEADER,pMSG"
	FOR(_COUNT = 1;_COUNT <= LENGTH_ARRAY(_TOSEND);_COUNT++){
		_CHK = _CHK BXOR _TOSEND[_COUNT]
	}
	_TOSEND = "$01,_TOSEND"				// Header Byte
	_TOSEND = "_TOSEND,_CHK"
	_TOSEND = "_TOSEND,$0D"
	fnAddToQueue(_TOSEND)
}
/******************************************************************************
	Utility Functions - NEC Utilities
******************************************************************************/
(** Input Translator **)
DEFINE_FUNCTION SINTEGER fnTextToInput(CHAR pInput[]){
	STACK_VAR SINTEGER _INPUT
	SWITCH(myNECDisplay.MODEL){
		CASE 'C651Q':
		CASE 'C751Q':
		CASE 'E656':
		CASE 'E705':
		CASE 'X651UHD':
		CASE 'X841UHD-2':
		CASE 'V484':
		CASE 'V554-T':{
			SWITCH(pINPUT){
				CASE 'HDMI1': 	_INPUT = $11
				CASE 'HDMI2': 	_INPUT = $12
				CASE 'HDMI3': 	_INPUT = $82
				CASE 'HDMI4': 	_INPUT = $83
			}
		}
		DEFAULT:{
			SWITCH(pINPUT){
				CASE 'HDMI1': 	_INPUT = $04
				CASE 'HDMI2':	_INPUT = $11
			}
		}
	}
	IF(_INPUT == 0){
		SWITCH(pINPUT){
			CASE 'VGA':  	_INPUT = $01
			CASE 'RGB':  	_INPUT = $02
			CASE 'DVI':  	_INPUT = $03
			CASE 'VID1': 	_INPUT = $05
			CASE 'VID2': 	_INPUT = $06
			CASE 'SVID': 	_INPUT = $07
			CASE 'DVD/HD1':_INPUT = $0C
			CASE 'OPTION':	_INPUT = $0D
			CASE 'DVD/HD2':_INPUT = $0E
			CASE 'DPORT':	_INPUT = $0F
		}
	}
	RETURN _INPUT
}
DEFINE_FUNCTION CHAR[10] fnInputToText(SINTEGER pInput){
	STACK_VAR CHAR _INPUT[10]
	SWITCH(myNECDisplay.MODEL){
		CASE 'C651Q':
		CASE 'C751Q':
		CASE 'E656':
		CASE 'E705':
		CASE 'X651UHD':
		CASE 'X841UHD-2':
		CASE 'V484':
		CASE 'V554-T':{
			SWITCH(pINPUT){
				CASE $11:_INPUT = 'HDMI1'
				CASE $12:_INPUT = 'HDMI2'
				CASE $82:_INPUT = 'HDMI3'
				CASE $83:_INPUT = 'HDMI4'
			}
		}
		DEFAULT:{
			SWITCH(pINPUT){
				CASE $04:_INPUT = 'HDMI1'
				CASE $11:_INPUT = 'HDMI2'
			}
		}
	}
	IF(LENGTH_ARRAY(_INPUT) == 0){
		SWITCH(pINPUT){
			CASE $01:_INPUT = 'VGA'
			CASE $02:_INPUT = 'RGB'
			CASE $03:_INPUT = 'DVI'
			CASE $05:_INPUT = 'VID1'
			CASE $06:_INPUT = 'VID2'
			CASE $07:_INPUT = 'SVID'
			CASE $0C:_INPUT = 'DVD/HD1'
			CASE $0D:_INPUT = 'OPTION'
			CASE $0E:_INPUT = 'DVD/HD2'
			CASE $0F:_INPUT = 'DPORT'
		}
	}

	RETURN _INPUT
}

/******************************************************************************
	Utility Functions - NEC Feedback
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER _ID
	STACK_VAR CHAR 	_TYPE
	STACK_VAR INTEGER _LEN
	STACK_VAR INTEGER _RESULT
	(** **)
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'pDATA=',pDATA")
	(** Header **)
	GET_BUFFER_STRING(pDATA,3) 					// Strip STX,00,00
	_ID = GET_BUFFER_CHAR(pDATA)					// Get ID
	_TYPE = GET_BUFFER_CHAR(pDATA)				// Get Type
	_LEN = HEXTOI(GET_BUFFER_STRING(pDATA,2))	// Get Msg Length
	pDATA = MID_STRING(pDATA,2,_LEN-2)			// Trip Actual Message Out
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'_ID=',_ID")
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'_TYPE=',_TYPE")
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'_LEN=',ITOA(_LEN)")
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'pDATA=',pDATA")
	(** Message **)
	SWITCH(_TYPE){
		CASE 'B':{	// Command Result
			SELECT{
				ACTIVE(LEFT_STRING(pDATA,4) == 'C311' ||
						 LEFT_STRING(pDATA,4) == 'C312' ||
						 LEFT_STRING(pDATA,4) == 'C313' ||
						 LEFT_STRING(pDATA,4) == 'C314' ||
						 LEFT_STRING(pDATA,4) == 'C315'):{	// Unknown
					STACK_VAR INTEGER x
					STACK_VAR CHAR temp[50]
					STACK_VAR CHAR temp2[50]
					GET_BUFFER_STRING(pDATA,4)
					FOR(x = 1; x <= LENGTH_ARRAY(pDATA);x = x+2){
						temp = "temp,HEXTOI(MID_STRING(pDATA,x,2))"
					}
					FOR(x = 1; x <= LENGTH_ARRAY(temp);x++){
						temp2 = "temp2,ITOA("temp[x]")"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,4) == 'C316'):{	// Serial Number
					STACK_VAR INTEGER x
					GET_BUFFER_STRING(pDATA,4)
					myNECDisplay.SERIALNO = ''
					FOR(x = 1; x <= LENGTH_ARRAY(pDATA);x = x+2){
						IF(HEXTOI(MID_STRING(pDATA,x,2))){
							myNECDisplay.SERIALNO = "myNECDisplay.SERIALNO,HEXTOI(MID_STRING(pDATA,x,2))"
						}
					}
					SEND_STRING vdvControl,"'PROPERTY-META,SN,',myNECDisplay.SERIALNO"
					IF(myNECDisplay.MODEL == ''){		fnGetCommand('C217')  }	// Read Model Number
				}
				ACTIVE(LEFT_STRING(pDATA,4) == 'C317'):{	// Model ID
					STACK_VAR INTEGER x
					GET_BUFFER_STRING(pDATA,4)
					myNECDisplay.MODEL = ''
					FOR(x = 1; x <= LENGTH_ARRAY(pDATA);x = x+2){
						IF(HEXTOI(MID_STRING(pDATA,x,2))){
							myNECDisplay.MODEL = "myNECDisplay.MODEL,HEXTOI(MID_STRING(pDATA,x,2))"
						}
					}
					SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myNECDisplay.MODEL"
					SEND_STRING vdvControl,"'PROPERTY-META,INPUTS,',fnGetSourceList(myNECDisplay.MODEL)"
					IF(myNECDisplay.CARRIER_ENABLED){
						SEND_COMMAND vdvControl,"'CARRIER-PROPERTY,CREATE,TEXT,Source,',fnGetSourceList(myNECDisplay.MODEL),',,,TRUE'"
						SEND_STRING vdvControl, "'SOURCE-',fnInputToText(myNECDisplay.INPUT)"
					}
				}
				ACTIVE(MID_STRING(pDATA,5,2) == 'D6'):{		// Power Status
					myNECDisplay.POWER = ATOI(MID_STRING(pDATA,13,4))
					IF(myNECDisplay.POWER == 1){ 		fnGetParam('00','60') }	//	Input Request
					ELSE{
						IF(myNECDisplay.SERIALNO == ''){ fnGetCommand('C216')  } // Read Serial Number
					}
				}
				ACTIVE(MID_STRING(pDATA,7,2) == 'D6'):{		// Power Status - Alt?!
					myNECDisplay.POWER = ATOI(MID_STRING(pDATA,9,4))
					IF(myNECDisplay.POWER == 1){ 		fnGetParam('00','60') }	//	Input Request
					ELSE{
						IF(myNECDisplay.SERIALNO == ''){ fnGetCommand('C216')  } // Read Serial Number
					}
				}
				ACTIVE(LEFT_STRING(pDATA,2) == 'A1'):{		// Self Diagnostics
					GET_BUFFER_STRING(pDATA,2)
					IF(myNECDisplay.DIAGNOSTICS != HEXTOI(pDATA)){
						STACK_VAR CHAR _MSG[255]
						myNECDisplay.DIAGNOSTICS = HEXTOI(pDATA)
						SWITCH(myNECDisplay.DIAGNOSTICS){
							CASE $00:_MSG = 'Normal'
							CASE $70:_MSG = '+3.3V Error'
							CASE $71:_MSG = '+5V Error'
							CASE $72:_MSG = '+12V Error'
							CASE $78:_MSG = '+24V Error'
							CASE $80:_MSG = 'Cooling Fan 1 Error'
							CASE $81:_MSG = 'Cooling Fan 2 Error'
							CASE $82:_MSG = 'Cooling Fan 3 Error'
							CASE $90:_MSG = 'Inverter Error'
							CASE $91:_MSG = 'LED Backlight Error'
							CASE $A0:_MSG = 'Temp Error - Shutdown'
							CASE $A1:_MSG = 'Temp Error - Half Brightness'
							CASE $A2:_MSG = 'Temp Sensor Triggered'
							CASE $B0:_MSG = 'No Signal'
							CASE $C0:_MSG = 'Option Board Error'
						}
						SEND_STRING vdvControl, "'DIAGNOSTICS-',_MSG"
					}
				}
			}
		}
		CASE 'D':
		CASE 'F':{
			STACK_VAR INTEGER _OPP
			STACK_VAR INTEGER _OPC
			STACK_VAR SINTEGER _Max
			STACK_VAR SINTEGER _Val

			_RESULT 		= HEXTOI(GET_BUFFER_STRING(pDATA,2))
			_OPP 			= HEXTOI(GET_BUFFER_STRING(pDATA,2))
			_OPC     	= HEXTOI(GET_BUFFER_STRING(pDATA,2))
			GET_BUFFER_STRING(pDATA,2)
			_Max    		= HEXTOI(GET_BUFFER_STRING(pDATA,4))
			_Val    		= HEXTOI(GET_BUFFER_STRING(pDATA,4))

			fnDebug(DEBUG_DEV,"'fnProcessFeedback'","'_RESULT:',ITOHEX(_RESULT)")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback'","'_OPP:',ITOHEX(_OPP)")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback'","'_OPC:',ITOHEX(_OPC)")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback'","'_Max:',ITOHEX(_Max)")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback'","'_Val:',ITOHEX(_Val)")
			SWITCH(_OPP){
				CASE $00:{
					SWITCH(_OPC){
						CASE $60:{	// Input
							IF(myNECDisplay.INPUT != _Val){
								myNECDisplay.INPUT = _Val
								SEND_STRING vdvControl, "'INPUT-',fnInputToText(myNECDisplay.INPUT)"
								IF(myNECDisplay.CARRIER_ENABLED){
									SEND_STRING vdvControl, "'SOURCE-',fnInputToText(myNECDisplay.INPUT)"
								}
							}
							IF(myNECDisplay.INPUT != myNECDisplay.desINPUT && myNECDisplay.desInput != -1){
								fnSetParam('00','60',myNECDisplay.desINPUT)
							}
							ELSE{
								myNECDisplay.desINPUT = -1
							}
							// Get Mute State
							fnGetParam('00','8D');
						}
						CASE $8D:{
							SWITCH(_Val){
								CASE 1:myNECDisplay.MUTE = TRUE
								CASE 2:myNECDisplay.MUTE = FALSE
							}
							// Get Volume
							fnGetParam('00','62');
						}
						CASE $62:{
							IF(myNECDisplay.GAIN_RANGE[2] != _MAX){
								myNECDisplay.GAIN_RANGE[2] = _MAX
								//SEND_STRING vdvControl,"'RANGE-0,',ITOA(myNECDisplay.GAIN_RANGE[2])"
							}
							myNECDisplay.GAIN_CURRENT = _Val
							IF(myNECDisplay.SERIALNO == ''){ fnGetCommand('C216')  } // Read Serial Number
						}
					}
				}
			}
		}
		IF(_RESULT){
			fnDebug(DEBUG_ERR,"'fnProcessFeedback'","'ERROR:UnsupportedOnMonitorOrCurrentCondition'")
		}
	}
	fnInitCloseTimeout()
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_FUNCTION CHAR[200] fnGetSourceList(CHAR m[]){
	SWITCH(myNECDisplay.MODEL){
		CASE 'V423':  	RETURN 'HDMI1|DPORT|DVI|VGA'
		CASE 'V554':  	RETURN 'HDMI1|HDMI2|DPORT|DVI|VGA'
		DEFAULT:  		RETURN 'HDMI1|HDMI2|HDMI3|HDMI4|DPORT|DVI|VGA'
	}
}
/******************************************************************************
	Device Events - Real Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myNECDisplay.COMMS.DISABLED){
			IF(myNECDisplay.COMMS.isIP){
				myNECDisplay.COMMS.CONN_STATE 	= CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(myNECDisplay.COMMS.isIP && !myNECDisplay.COMMS.DISABLED){
			myNECDisplay.COMMS.CONN_STATE 	= CONN_STATE_OFFLINE
			myNECDisplay.COMMS.Rx 		= ''
			myNECDisplay.COMMS.Tx 		= ''
		}
	}
	ONERROR:{
		IF(myNECDisplay.COMMS.isIP && !myNECDisplay.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			myNECDisplay.COMMS.CONN_STATE 	= CONN_STATE_OFFLINE
			myNECDisplay.COMMS.Rx 		= ''
			myNECDisplay.COMMS.Tx 		= ''
			SWITCH(DATA.NUMBER){
				CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
				CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
				CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
				CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
				CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
				CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
				CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
				CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
				CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
				CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
				CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
				CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
			}
			fnDebug(DEBUG_ERR,"'NEC IP Error:[',myNECDisplay.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myNECDisplay.COMMS.DISABLED){
			fnDebugHex(DEBUG_STD,'NEC->AMX',DATA.TEXT);
			WHILE(FIND_STRING(myNECDisplay.COMMS.Rx,"$0D",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myNECDisplay.COMMS.Rx,"$0D",1),1))
				myNECDisplay.COMMS.PEND = FALSE
				IF(TIMELINE_ACTIVE(TLID_SEND_TIMEOUT)){ TIMELINE_KILL(TLID_SEND_TIMEOUT) }
				fnSendFromQueue()
			}
		}
	}
}

/******************************************************************************
	Device Events - Control Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		myNECDisplay.GAIN_RANGE[1] = 0
		myNECDisplay.GAIN_RANGE[2] = 100
	}
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'NEC':
							CASE 'TRUE':myNECDisplay.COMMS.DISABLED = FALSE
							DEFAULT:		myNECDisplay.COMMS.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myNECDisplay.COMMS.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'CARRIER':{
					SWITCH(DATA.TEXT){
						CASE 'INIT':{
							myNECDisplay.CARRIER_ENABLED = TRUE
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,BOOLEAN,Power,255,TRUE'"
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,BOOLEAN,Mute,199,TRUE'"
							SEND_COMMAND DATA.DEVICE,"'CARRIER-PROPERTY,CREATE,INTEGER,Volume,1,0|100,,,TRUE'"
						}
					}
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP': {
							IF(LENGTH_ARRAY(DATA.TEXT)){
								myNECDisplay.COMMS.IP_HOST = DATA.TEXT
								myNECDisplay.COMMS.IP_PORT = 7142
									TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myNECDisplay.COMMS.DISABLED = TRUE
							}
						}
						CASE 'STEP': myNECDisplay.GAIN_STEP = ATOI(DATA.TEXT)
						CASE 'ID': {	myNECDisplay.ID = ATOI(DATA.TEXT) }
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE': myNECDisplay.COMMS.DEBUG = DEBUG_STD
								CASE 'DEV':  myNECDisplay.COMMS.DEBUG = DEBUG_DEV
								DEFAULT: 	 myNECDisplay.COMMS.DEBUG = DEBUG_ERR
							}
						}
						CASE 'FORCE_MODEL':{
							#WARN 'Added to force model number from corrupted feedback that needs more work from E656'
							myNECDisplay.MODEL = DATA.TEXT
						}
					}
				}
				CASE 'TEST':{
					SWITCH(DATA.TEXT){
						CASE '1':fnGetCommand('B1')
						CASE '2':fnGetCommand('01D6')
						CASE '3':fnGetCommand('C216')	// Read Serial Number
						CASE '4':fnGetCommand('C217')	// Read Model Number
						DEFAULT: fnGetCommand(DATA.TEXT)
					}
				}
				CASE 'INPUT':{
					IF(myNECDisplay.POWER == 1){
						fnSetParam('00','60',fnTextToInput(DATA.TEXT));
					}
					ELSE{
						myNECDisplay.desINPUT = fnTextToInput(DATA.TEXT)
						fnSetCommand("$43,$32,$30,$33,$44,$36",'0001');// Power ON
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':     myNECDisplay.POWER = TRUE
						CASE 'OFF':    myNECDisplay.POWER = FALSE
						CASE 'TOGGLE': myNECDisplay.POWER = !myNECDisplay.POWER
					}
					SWITCH(myNECDisplay.POWER){
						CASE TRUE:  fnSetCommand("$43,$32,$30,$33,$44,$36",'0001')
						CASE FALSE: fnSetCommand("$43,$32,$30,$33,$44,$36",'0004')
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		myNECDisplay.MUTE = TRUE
						CASE 'OFF':		myNECDisplay.MUTE = FALSE
						CASE 'TOGGLE':	myNECDisplay.MUTE = !myNECDisplay.MUTE
					}
					SWITCH(myNECDisplay.MUTE){
						CASE TRUE:	fnSetParam('00','8D',1);
						CASE FALSE:	fnSetParam('00','8D',2);
					}
				}
				CASE 'VOLUME':{
					STACK_VAR SINTEGER GAIN_NEW
					SWITCH(DATA.TEXT){
						CASE 'INC':	GAIN_NEW = myNECDisplay.GAIN_CURRENT + myNECDisplay.GAIN_STEP
						CASE 'DEC':	GAIN_NEW = myNECDisplay.GAIN_CURRENT - myNECDisplay.GAIN_STEP
						DEFAULT:		GAIN_NEW = ATOI(DATA.TEXT)
					}
					IF(GAIN_NEW < myNECDisplay.GAIN_RANGE[1]){GAIN_NEW = myNECDisplay.GAIN_RANGE[1]}
					IF(GAIN_NEW > myNECDisplay.GAIN_RANGE[2]){GAIN_NEW = myNECDisplay.GAIN_RANGE[2]}
					fnSetGain(GAIN_NEW)
					myNECDisplay.MUTE = FALSE
				}
			}
		}
	}
}
/******************************************************************************
	Control Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!myNECDisplay.COMMS.DISABLED){
		SEND_LEVEL vdvControl,LVL_VOL_RAW,myNECDisplay.GAIN_CURRENT
		SEND_LEVEL vdvControl,LVL_VOL_100,myNECDisplay.GAIN_CURRENT
		SEND_LEVEL vdvControl,LVL_VOL_255,fnScaleRange(myNECDisplay.GAIN_CURRENT,0,100,0,255)
		[vdvControl, 199] = (myNECDisplay.MUTE)
		[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 254] = (myNECDisplay.POWER == 2 || myNECDisplay.POWER == 3)
		[vdvControl, 255] = (myNECDisplay.POWER == 1)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
