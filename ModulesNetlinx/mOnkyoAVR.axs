MODULE_NAME='mOnkyoAVR'(DEV vdvZone[], DEV dvDEVICE)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Onkyo AVR Control Module

******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uAVRZone{
	INTEGER POWER
	INTEGER MUTE
	INTEGER VOL
	INTEGER VOL_MAX
	CHAR 	  SRC[2]
	CHAR	  SRC_TEXT[20]
	CHAR 	  desSRC[2]
	CHAR 	  cDECODE[30]
	INTEGER bSPEAKER_B
}
DEFINE_TYPE STRUCTURE uAVRUnit{
	(** State - Tuner **)
	INTEGER FREQ_1	// Large Part of Freq
	INTEGER FREQ_2	// Small Part of Freq
	INTEGER curPreset
	(** State - Device **)
	INTEGER TRIGGER_12V[3]
	INTEGER LEDS
	(** Comms Data **)
	CHAR 	  TX[1000]
	CHAR 	  RX[1000]
	//INTEGER PEND
	INTEGER DEBUG
	INTEGER isIP
	INTEGER IP_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2
LONG TLID_RETRY		= 3
LONG TLID_INIT			= 4

LONG TLID_VOL_00		= 200
LONG TLID_VOL_01		= 201
LONG TLID_VOL_02		= 202
LONG TLID_VOL_03		= 203

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uAVRZone myAVRZones[4]	// Zone Data
VOLATILE uAVRUnit	myAVRUnit

LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
LONG 		TLT_INIT[]	= {	2500 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myAVRUnit.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice,myAVRUnit.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnQueueCommand(CHAR _cmd[], CHAR _param[]){
	fnAddToQueue("_cmd,_param")
	fnInitPoll()
}
DEFINE_FUNCTION fnQueueQuery(CHAR _cmd[]){
	fnAddToQueue("_cmd,'QSTN'")
}
DEFINE_FUNCTION fnAddToQueue(CHAR pPacket[]){
	STACK_VAR CHAR toSend[255]
	pPacket = "'!1',pPacket,$0D"
	IF(myAVRUnit.isIP){
		toSend = "'ISCP', $00,$00,$00,$10"
		toSend = "toSend,$00,$00,$00,LENGTH_ARRAY(pPacket)"
		toSend = "toSend,$01,$00,$00,$00"
		toSend = "toSend,pPacket"
	}
	ELSE{
		toSend = pPacket
	}
	myAVRUnit.TX = "myAVRUnit.TX,toSend"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	//IF(myAVRUnit.IP_STATE == IP_STATE_CONNECTED && !myAVRUnit.PEND){
	IF(myAVRUnit.IP_STATE == IP_STATE_CONNECTED){
		IF(FIND_STRING(myAVRUnit.TX,"$0D",1)){
			STACK_VAR CHAR toSend[255]
			toSend = REMOVE_STRING(myAVRUnit.TX,"$0D",1)
			fnDebug(FALSE,'->ONK',toSend)
			SEND_STRING dvDEVICE,toSend
			//myAVRUnit.PEND = TRUE
		}
	}
}

(** Polling Code **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	IF(myAVRZones[1].POWER){fnQueueQuery('SLI')} ELSE {fnQueueQuery('PWR')}
	IF(myAVRZones[2].POWER){fnQueueQuery('SLZ')} ELSE {fnQueueQuery('ZPW')}
	IF(myAVRZones[3].POWER){fnQueueQuery('SL3')} ELSE {fnQueueQuery('PW3')}
	fnQueueQuery('DIM')
}
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myAVRUnit.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvZone[1].Number),':',Msg, ':', MsgData"
	}
}

(** IP Helpers **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myAVRUnit.IP_STATE == IP_STATE_OFFLINE){
		myAVRUnit.IP_STATE = IP_STATE_CONNECTING
		fnDebug(FALSE,"'Connecting to AVR on'","myAVRUnit.IP_HOST,':',ITOA(myAVRUnit.IP_PORT)")
		ip_client_open(dvDevice.port, myAVRUnit.IP_HOST, myAVRUnit.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){	TIMELINE_KILL(TLID_RETRY) }
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY), TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Feedback Processing **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR CHAR pCMD[3]
	STACK_VAR CHAR pParam[3]
	fnDebug(FALSE,'ONK->',pDATA)
	GET_BUFFER_STRING(pDATA,2)		// DROP '!1'
	pCMD = GET_BUFFER_STRING(pDATA,3);
	pParam = pDATA;
	SWITCH(pCMD){
		CASE 'PWR':
		CASE 'ZPW':
		CASE 'PW3':{
			STACK_VAR INTEGER z
			SWITCH(pCMD){
				CASE 'PWR':z=1
				CASE 'ZPW':z=2
				CASE 'PW3':z=3
			}
			IF(myAVRZones[z].POWER != ATOI(pParam)){
				myAVRZones[z].POWER = ATOI(pParam)
				IF(myAVRZones[z].POWER){
					SWITCH(pCMD){
						CASE 'PWR':fnQueueQuery('SLI')
						CASE 'ZPW':fnQueueQuery('SLZ')
						CASE 'PW3':fnQueueQuery('SL3')
					}
					SWITCH(pCMD){
						CASE 'PWR':fnQueueQuery('MVL')
						CASE 'ZPW':fnQueueQuery('ZVL')
						CASE 'PW3':fnQueueQuery('VL3')
					}
					SWITCH(pCMD){
						CASE 'PWR':fnQueueQuery('AMT')
						CASE 'ZPW':fnQueueQuery('ZMT')
						CASE 'PW3':fnQueueQuery('MT3')
					}
				}
			}
		}
		CASE 'MVL':{
			myAVRZones[1].VOL = HEXTOI(pParam)
			SEND_LEVEL vdvZone[1], 1, myAVRZones[1].VOL
		}
		CASE 'AMT':{
			myAVRZones[1].MUTE = ATOI(pParam)
		}
		CASE 'SLI':
		CASE 'SLZ':
		CASE 'SL3':{
			STACK_VAR INTEGER z
			SWITCH(pCMD){
				CASE 'SLI':z=1
				CASE 'SLZ':z=2
				CASE 'SL3':z=3
			}
			IF(LENGTH_ARRAY(myAVRZones[z].desSRC) && myAVRZones[z].desSRC != pParam){
				fnQueueCommand(pCMD,GET_BUFFER_STRING(myAVRZones[z].desSRC,2))
			}
			ELSE IF(myAVRZones[z].SRC != pParam){
				myAVRZones[z].SRC = pParam
				myAVRZones[z].SRC_TEXT = fnGetInputString(myAVRZones[z].SRC)
				SEND_STRING vdvZone[z], "'INPUT-',myAVRZones[z].SRC_TEXT"
			}
		}
		CASE 'TGA':myAVRUnit.TRIGGER_12V[1] = ATOI(pParam)
		CASE 'TGB':myAVRUnit.TRIGGER_12V[2] = ATOI(pParam)
		CASE 'TGC':myAVRUnit.TRIGGER_12V[3] = ATOI(pParam)
		CASE 'DIM':myAVRUnit.LEDS				= ATOI(pParam)
	}
	//myAVRUnit.PEND = FALSE
	fnSendFromQueue()
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

(** Input Translation **)
DEFINE_FUNCTION CHAR[255] fnGetInputString(CHAR pINPUT[2]){
	SWITCH(pINPUT){
		CASE '00':RETURN 'VIDEO1'
		CASE '01':RETURN 'VIDEO2'
		CASE '02':RETURN 'VIDEO3'
		CASE '03':RETURN 'VIDEO4'
		CASE '04':RETURN 'VIDEO5'
		CASE '05':RETURN 'VIDEO6'
		CASE '06':RETURN 'VIDEO7'
		CASE '10':RETURN 'DVD'
		CASE '20':RETURN 'TAPE1'
		CASE '21':RETURN 'TAPE2'
		CASE '22':RETURN 'PHONO'
		CASE '23':RETURN 'CD'
		CASE '24':RETURN 'FM'
		CASE '25':RETURN 'AM'
		CASE '26':RETURN 'TUNER'
		CASE '27':RETURN 'MUSICSERVER'
		CASE '28':RETURN 'INTERNETRADIO'
		CASE '29':RETURN 'USBFRONT'
		CASE '2A':RETURN 'USBREAR'
		CASE '2E':RETURN 'BLUETOOTH'
		CASE '40':RETURN 'UNIVERSALPORT'
		CASE '30':RETURN 'MULTICHANNEL'
		CASE '80':RETURN 'SOURCE'
	}
}
DEFINE_FUNCTION CHAR[2] fnGetInputNumber(CHAR pINPUT[255]){
	SWITCH(pINPUT){
		CASE 'VIDEO1':			RETURN '00'
		CASE 'VIDEO2':			RETURN '01'
		CASE 'VIDEO3':			RETURN '02'
		CASE 'VIDEO4':			RETURN '03'
		CASE 'VIDEO5':			RETURN '04'
		CASE 'VIDEO6':			RETURN '05'
		CASE 'VIDEO7':			RETURN '06'
		CASE 'EXTRA1':			RETURN '07'
		CASE 'EXTRA2':			RETURN '08'
		CASE 'EXTRA3':			RETURN '09'
		CASE 'DVD':				RETURN '10'
		CASE 'TAPE1':			RETURN '20'
		CASE 'TAPE2':			RETURN '21'
		CASE 'PHONO':			RETURN '22'
		CASE 'CD':				RETURN '23'
		CASE 'FM':				RETURN '24'
		CASE 'AM':				RETURN '25'
		CASE 'TUNER':			RETURN '26'
		CASE 'MUSICSERVER':	RETURN '27'
		CASE 'INTERNETRADIO':RETURN '28'
		CASE 'USBFRONT':		RETURN '29'
		CASE 'USBREAR':		RETURN '2A'
		CASE 'BLUETOOTH':		RETURN '2E'
		CASE 'UNIVERSALPORT':RETURN '40'
		CASE 'MULTICHANNEL':	RETURN '30'
		CASE 'SOURCE':			RETURN '80'
	}
}
/******************************************************************************
	Comms Functions - Grouped ready for Abstraction
******************************************************************************/
(** Device Events **)
DEFINE_EVENT DATA_EVENT[dvDEVICE]{
	ONLINE:{
		IF(myAVRUnit.isIP){
			myAVRUnit.IP_STATE = IP_STATE_CONNECTED
		}
		ELSE{
			SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
			SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
		fnInitPoll()
	}
	OFFLINE:{
		IF(myAVRUnit.isIP){
			myAVRUnit.IP_STATE = IP_STATE_OFFLINE
		}
	}
	ONERROR:{
		IF(myAVRUnit.isIP){
			STACK_VAR CHAR _MSG[255]
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
			fnDebug(TRUE,"'Onkyo Error:[',myAVRUnit.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")

			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myAVRUnit.IP_STATE = IP_STATE_OFFLINE
					myAVRUnit.TX = ''
					fnRetryConnection()
				}
			}
		}
	}
	STRING:{
		IF(myAVRUnit.isIP){
			WHILE(FIND_STRING(myAVRUnit.RX,"$1A,$0D,$0A",1)){
				GET_BUFFER_STRING(myAVRUnit.RX,16)
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myAVRUnit.RX,"$1A,$0D,$0A",1),3))
			}
		}
		ELSE{
			WHILE(FIND_STRING(myAVRUnit.RX,"$1A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myAVRUnit.RX,"$1A",1),1))
			}
		}
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvZone]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'RANGE-0,100'
	}
	COMMAND:{
		STACK_VAR INTEGER z;
		STACK_VAR CHAR cmd[3]
		z = GET_LAST(vdvZone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':myAVRUnit.DEBUG 	 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myAVRUnit.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)

						}
						ELSE{
							myAVRUnit.IP_HOST = DATA.TEXT
							myAVRUnit.IP_PORT = 60128
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'RAW':{

			}
			CASE 'LEDS':{
				SWITCH(DATA.TEXT){
					CASE 'BRIGHT':	fnQueueCommand('DIM','00')
					CASE 'DIM':		fnQueueCommand('DIM','01')
					CASE 'DARK':	fnQueueCommand('DIM','02')
					CASE 'SHUTOFF':fnQueueCommand('DIM','03')
					CASE 'BRIGHT-':fnQueueCommand('DIM','08')
					CASE 'CYCLE':	fnQueueCommand('DIM','DIM')
				}
			}
			CASE 'POWER':{
				SWITCH(z){
					CASE 1:cmd = 'PWR'
					CASE 2:cmd = 'ZPW'
					CASE 3:cmd = 'PW3'
				}
				SWITCH(DATA.TEXT){
					CASE 'OFF': fnQueueCommand(cmd,'00')
					CASE 'ON':	fnQueueCommand(cmd,'01')
				}
			}
			CASE 'INPUT':{
				SWITCH(z){
					CASE 1:cmd = 'SLI'
					CASE 2:cmd = 'SLZ'
					CASE 3:cmd = 'SL3'
				}
				IF(LENGTH_ARRAY(fnGetInputNumber(DATA.TEXT))){
					myAVRZones[z].desSRC = fnGetInputNumber(DATA.TEXT)
					IF(myAVRZones[z].POWER){
						fnQueueCommand(cmd,fnGetInputNumber(DATA.TEXT))
					}
					ELSE{
						SEND_COMMAND DATA.DEVICE, 'POWER-ON'
					}
				}
				ELSE{
					SEND_STRING DATA.DEVICE, 'ERROR-UNKNOWN INPUT'
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC': fnQueueCommand('MVL','UP')
					CASE 'DEC': fnQueueCommand('MVL','DOWN')
					DEFAULT:		fnQueueCommand('MVL',ITOHEX(ATOI(DATA.TEXT)))
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnQueueCommand('AMT','01')
					CASE 'OFF':	fnQueueCommand('AMT','00')
					CASE 'TOGGLE':{
						IF(myAVRZones[1].MUTE){
							SEND_COMMAND vdvZone[1], 'MUTE-OFF'
						}
						ELSE{
							SEND_COMMAND vdvZone[1], 'MUTE-ON'
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER z;
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
		[vdvZone[z],199] = myAVRZones[z].MUTE
		[vdvZone[z],255] = myAVRZones[z].POWER
		[vdvZone[z],251] = TIMELINE_ACTIVE(TLID_COMMS)
		[vdvZone[z],252] = TIMELINE_ACTIVE(TLID_COMMS)
	}
}