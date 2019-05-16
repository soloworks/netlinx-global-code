MODULE_NAME='mSharpDisplay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Sharp Display

	Display may require the following command:
	"RSPW1   " or "RSPW0001"
	to disable power savings
******************************************************************************/
/******************************************************************************
	Structures, Constants, Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uSharpDisplay{

	INTEGER 	DISABLED
	CHAR 		Rx[500]
	CHAR 		Tx[500]
	INTEGER 	TX_PEND
	INTEGER 	isIP
	INTEGER 	IP_PORT
	CHAR	 	IP_HOST[255]
	INTEGER 	CONN_STATE
	CHAR		USERNAME[20]
	CHAR		PASSWORD[20]
	LONG		BAUD
	INTEGER  PROTOCOL_PAD
	INTEGER  INPUT_CONFIG
	INTEGER  isRS232OVERIP
	INTEGER  MODEL_QTYPE		// Differnet models have different model query strings MODEL_QTYPE = 0 FOR "'INF1????',$0D" MODEL_QTYPE = 1 FOR "'MNRD1   ',$OD"

	INTEGER	VOL_PEND
	INTEGER	LAST_VOL

	CHAR 		META_MODEL[100]
	CHAR		META_SN[100]

	INTEGER 	DEBUG
	CHAR 		lastPOLL[4]
	CHAR 		lastCMD[16]		// For storing last requested command ie. power off

	INTEGER 	POWER
	INTEGER 	VOLUME
	INTEGER 	MUTE
	CHAR 		INPUT[4]
}
DEFINE_CONSTANT
LONG TLID_INPUT 	= 01
LONG TLID_POLL  	= 02
LONG TLID_COMMS 	= 03
LONG TLID_VOL		= 04
LONG TLID_TIMEOUT = 05
LONG TLID_BOOT		= 06

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_NEGOTIATING	= 2
INTEGER CONN_STATE_CONNECTED		= 3

INTEGER DEBUG_ALWAYS	= 0
INTEGER DEBUG_TRUE	= 1
INTEGER DEBUG_DEV		= 2

INTEGER PROTOCOL_PAD_ZERO  = 0
INTEGER PROTOCOL_PAD_SPACE = 1

INTEGER INPUT_CONFIG_01 = 0
INTEGER INPUT_CONFIG_02 = 1
INTEGER INPUT_CONFIG_03 = 2

DEFINE_VARIABLE
uSharpDisplay mySharpDisplay

LONG TLT_POLL[]  		= {  45000 }
LONG TLT_COMMS[] 		= { 120000 }
LONG TLT_INPUT[] 		= {  10000 }
LONG TLT_TIMEOUT[] 	= {  20000 }
LONG TLT_BOOT[]		= {   5000 }
LONG TLT_VOL[]			= {    150 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	mySharpDisplay.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, mySharpDisplay.RX
}
/******************************************************************************
	Utility Functions - General
******************************************************************************/

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(mySharpDisplay.IP_HOST == ''){
		fnDebug(TRUE,'Sharp IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Sharp on ',"mySharpDisplay.IP_HOST,':',ITOA(mySharpDisplay.IP_PORT)")
		mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, mySharpDisplay.IP_HOST, mySharpDisplay.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnAddCmdToQueue(CHAR cmd[], CHAR param[]){
	SWITCH(mySharpDisplay.PROTOCOL_PAD){
		CASE PROTOCOL_PAD_ZERO:  fnAddToQueue("cmd,fnPadLeadingChars(param,'0',4),$0D")
		CASE PROTOCOL_PAD_SPACE: fnAddToQueue("cmd,fnPadTrailingChars(param,' ',4),$0D")
	}
	fnInitPoll()
}
DEFINE_FUNCTION fnAddQueryToQueue(CHAR cmd[]){
	fnAddToQueue("cmd,'????',$0D")
}

DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[]){
	mySharpDisplay.Tx = "mySharpDisplay.Tx,pToSend"
	IF(length_string(mySharpDisplay.Tx)>=max_length_string(mySharpDisplay.Tx)){//someting has gone wrong, so empty and refresh.
		mySharpDisplay.Tx = pToSend
	}
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(mySharpDisplay.CONN_STATE == CONN_STATE_CONNECTED && !mySharpDisplay.TX_PEND){
		STACK_VAR CHAR toSend[100]
		STACK_VAR INTEGER pVALUE
		IF(FIND_STRING(mySharpDisplay.Tx,"$0D",1)){
			toSend = REMOVE_STRING(mySharpDisplay.Tx,"$0D",1)
			fnDebug(FALSE,'->SHP',toSend)
			IF(FIND_STRING(toSend,'????',1)){
				mySharpDisplay.lastPOLL = LEFT_STRING(toSend,4)
			}ELSE{
				IF(LEFT_STRING(toSend,4) == 'POWR'){
					pVALUE = AToI(toSend)
					IF(pVALUE == 1){
						mySharpDisplay.lastCMD = 'power on'
					}ELSE{
						mySharpDisplay.lastCMD = 'power off'
					}
				}
			}
			SEND_STRING dvDevice,toSend
			mySharpDisplay.TX_PEND = TRUE
		}
	}
	ELSE IF(mySharpDisplay.CONN_STATE == CONN_STATE_OFFLINE && mySharpDisplay.isIP && FIND_STRING(mySharpDisplay.Tx,"$0D",1)){
		fnOpenTCPConnection()
	}
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	mySharpDisplay.Tx 		= ''
	mySharpDisplay.TX_PEND 	= FALSE
	IF(mySharpDisplay.isIP && mySharpDisplay.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!mySharpDisplay.DISABLED){
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Sharp'
		IF(!mySharpDisplay.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			IF(mySharpDisplay.BAUD == 0){mySharpDisplay.BAUD = 9600}
			SEND_COMMAND dvDevice, "'SET BAUD ',ITOA(mySharpDisplay.BAUD),' N 8 1 485 DISABLE'"
			mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
		}
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(mySharpDisplay.DEBUG || pFORCE){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	IF(pDATA == 'WAIT'){
		RETURN
	}
//	ELSE IF(pDATA == 'ERR' || pDATA == 'OK'){
//		mySharpDisplay.lastPOLL = ''
//		mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
//	}
	ELSE IF(pDATA == 'ERR'){//TOGGLE BETWEEN THE TWO DIFFERENT TYPES OF MODEL QUERY STRING IF 'ERR' IS THE RESPONSE
		IF(mySharpDisplay.lastPOLL = 'INF1'){
			mySharpDisplay.MODEL_QTYPE = 1
			mySharpDisplay.lastPOLL = ''
			mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
		}
		ELSE IF(mySharpDisplay.lastPOLL = 'MNRD'){
			mySharpDisplay.MODEL_QTYPE = 0
			mySharpDisplay.lastPOLL = ''
			mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
		}
		ELSE{
			mySharpDisplay.lastPOLL = ''
			mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
		}
	}
	ELSE IF(pDATA == 'OK'){
		mySharpDisplay.lastPOLL = ''
		mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
		IF(mySharpDisplay.lastCMD != ''){
			fnPoll()
		}
	}
	ELSE{
		SWITCH(mySharpDisplay.lastPOLL){
			CASE 'POWR':{
				mySharpDisplay.POWER = ATOI(pDATA)
				SWITCH(mySharpDisplay.POWER){
					CASE 1:{//Display is ON
						SWITCH(mySharpDisplay.lastCMD){
							CASE 'power on':{
								mySharpDisplay.lastCMD = ''
								IF(mySharpDisplay.INPUT_CONFIG==INPUT_CONFIG_01){
									fnAddQueryToQueue('INPS')
								}ELSE{
									fnAddQueryToQueue('IAVD')
								}
								fnAddCmdToQueue('RSPW','1')
							}
							CASE 'power off':{
								fnPoll()
							}
						}
					}
					CASE 0:{//Display is OFF
						SWITCH(mySharpDisplay.lastCMD){
							CASE 'power off':{
								mySharpDisplay.lastCMD = ''
							}
							CASE 'power on':{
								fnPoll()
							}
						}
					}
				}
				IF(!LENGTH_ARRAY(mySharpDisplay.META_MODEL)){
					IF(mySharpDisplay.MODEL_QTYPE){
						IF(mySharpDisplay.POWER){
							fnAddCmdToQueue('MNRD','1')
						}
					}ELSE{
						fnAddQueryToQueue('INF1')
					}
				}
				IF(!mySharpDisplay.MODEL_QTYPE){
					IF(!LENGTH_ARRAY(mySharpDisplay.META_SN)){
						fnAddQueryToQueue('SRNO')
					}
				}
			}
			CASE 'VOLM':{
				mySharpDisplay.VOLUME = ATOI(pDATA)
			}
			CASE 'MUTE':{
				mySharpDisplay.MUTE= ATOI(pDATA)
			}
			CASE 'IAVD':
			CASE 'INPS':{
				mySharpDisplay.INPUT = pDATA
				fnAddQueryToQueue('VOLM')
				fnAddQueryToQueue('MUTE')
			}
			CASE 'MNRD':
			CASE 'INF1':{
				mySharpDisplay.META_MODEL = pDATA
				SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',mySharpDisplay.META_MODEL"
				SWITCH(mySharpDisplay.META_MODEL){
					CASE 'PN-60TA3':{ mySharpDisplay.INPUT_CONFIG = INPUT_CONFIG_01}
					CASE 'PN-LE901':
					CASE 'PN-LE601':{ mySharpDisplay.INPUT_CONFIG = INPUT_CONFIG_03}
				}
			}
			CASE 'SRNO':{
				mySharpDisplay.META_SN = pDATA
				SEND_STRING vdvControl,"'PROPERTY-META,SN,',mySharpDisplay.META_SN"
			}
		}
		mySharpDisplay.lastPOLL = ''
	}

	mySharpDisplay.TX_PEND = FALSE
	fnSendFromQueue()
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Utility Functions - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnAddQueryToQueue('POWR')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
/******************************************************************************
	Screen Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!mySharpDisplay.DISABLED){
			IF(mySharpDisplay.isIP){
				IF(mySharpDisplay.isRS232OVERIP){
					mySharpDisplay.CONN_STATE = CONN_STATE_CONNECTED
					fnSendFromQueue()
				}
				ELSE{
					mySharpDisplay.CONN_STATE = CONN_STATE_NEGOTIATING
				}
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(mySharpDisplay.isIP && !mySharpDisplay.DISABLED){
			mySharpDisplay.CONN_STATE	= CONN_STATE_OFFLINE
		}
	}
	ONERROR:{
		IF(mySharpDisplay.isIP && !mySharpDisplay.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					mySharpDisplay.CONN_STATE = CONN_STATE_OFFLINE
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
				}
			}
			fnDebug(TRUE,"'Sharp IP Error:[',mySharpDisplay.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!mySharpDisplay.DISABLED){
			IF(mySharpDisplay.DEBUG){
				fnDebug(FALSE,'RAW->',DATA.TEXT)
			}
			IF(FIND_STRING(mySharpDisplay.Rx,'Login:',1)){
				mySharpDisplay.Rx = ''
				IF(mySharpDisplay.USERNAME = ''){mySharpDisplay.USERNAME = 'admin'}
				fnDebug(FALSE,'RAW->',"mySharpDisplay.USERNAME,$0D")
				SEND_STRING dvDevice,"mySharpDisplay.USERNAME,$0D"
			}
			ELSE IF(FIND_STRING(mySharpDisplay.Rx,'Password:',1)){
				mySharpDisplay.Rx = ''
				IF(mySharpDisplay.PASSWORD = ''){mySharpDisplay.PASSWORD = 'password'}
				fnDebug(FALSE,'RAW->',"mySharpDisplay.PASSWORD,$0D")
				SEND_STRING dvDevice,"mySharpDisplay.PASSWORD,$0D"
			}
			ELSE{
				IF(mySharpDisplay.isIP && !mySharpDisplay.isRS232OVERIP){
					WHILE(FIND_STRING(mySharpDisplay.Rx,"$0D,$0A",1)){
						fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySharpDisplay.Rx,"$0D,$0A",1),2))
					}
				}
				ELSE{
					WHILE(FIND_STRING(mySharpDisplay.Rx,"$0D",1)){
						fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySharpDisplay.Rx,"$0D",1),1))
					}
				}
			}
		}
	}
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'SHARP':
							CASE 'TRUE':mySharpDisplay.DISABLED = FALSE
							DEFAULT:		mySharpDisplay.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!mySharpDisplay.DISABLED){
			SWITCH(fnStripCharsRight( REMOVE_STRING(DATA.TEXT,'-',1) , 1 )){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight( REMOVE_STRING(DATA.TEXT,',',1) , 1 )){
						CASE 'DEBUG': mySharpDisplay.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								mySharpDisplay.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								mySharpDisplay.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								mySharpDisplay.IP_HOST = DATA.TEXT
								mySharpDisplay.IP_PORT = 10008
							}
							WAIT 20{
								fnPoll()
								fnInitPoll()
							}
						}
						CASE 'RS232OVERIP':{
							mySharpDisplay.isRS232OVERIP = (DATA.TEXT == 'TRUE')
						}
						CASE 'BAUD':{
							mySharpDisplay.BAUD = ATOI(DATA.TEXT)
						}
						CASE 'PADDING':{
							SWITCH(DATA.TEXT){
								CASE 'ZERO':  mySharpDisplay.PROTOCOL_PAD = PROTOCOL_PAD_ZERO
								CASE 'SPACE': mySharpDisplay.PROTOCOL_PAD = PROTOCOL_PAD_SPACE
							}
						}
						CASE 'INPUT_CONFIG':{
							SWITCH(DATA.TEXT){
								CASE '1': mySharpDisplay.INPUT_CONFIG = INPUT_CONFIG_01
								CASE '2': mySharpDisplay.INPUT_CONFIG = INPUT_CONFIG_02
								CASE '3': mySharpDisplay.INPUT_CONFIG = INPUT_CONFIG_03
							}
						}
					}
				}
				CASE 'RAW':{
					SEND_STRING dvDevice,"DATA.TEXT,$0D"
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':		mySharpDisplay.POWER = TRUE
						CASE 'OFF':		mySharpDisplay.POWER = FALSE
						CASE 'TOGGLE':	mySharpDisplay.POWER = !mySharpDisplay.POWER
					}
					fnAddCmdToQueue('POWR',ITOA(mySharpDisplay.POWER))
				}
				CASE 'MUTE':{
					mySharpDisplay.MUTE = !mySharpDisplay.MUTE
					SWITCH(mySharpDisplay.MUTE){
						CASE TRUE: fnAddCmdToQueue('MUTE','1')
						CASE FALSE:fnAddCmdToQueue('MUTE','0')
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':{
							IF(mySharpDisplay.VOLUME <= 29){
								mySharpDisplay.VOLUME = mySharpDisplay.VOLUME + 2
							}
							fnAddCmdToQueue('VOLM',fnPadLeadingChars(ITOA(mySharpDisplay.VOLUME),' ',4))
						}
						CASE 'DEC':{
							IF(mySharpDisplay.VOLUME >= 2){
								mySharpDisplay.VOLUME = mySharpDisplay.VOLUME - 2
							}
							fnAddCmdToQueue('VOLM',fnPadLeadingChars(ITOA(mySharpDisplay.VOLUME),' ',4))
						}
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								mySharpDisplay.VOLUME = ATOI(DATA.TEXT)
								fnAddCmdToQueue('VOLM',fnPadLeadingChars(ITOA(mySharpDisplay.VOLUME),' ',4))
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								mySharpDisplay.LAST_VOL = ATOI(DATA.TEXT)
								mySharpDisplay.VOL_PEND = TRUE
							}
						}
					}
				}

				CASE 'INPUT':{
					IF(TIMELINE_ACTIVE(TLID_INPUT)){TIMELINE_KILL(TLID_INPUT)}
					SWITCH(mySharpDisplay.INPUT_CONFIG){
						CASE INPUT_CONFIG_01:{
							SWITCH(DATA.TEXT){
								CASE 'DVI':			mySharpDisplay.INPUT = '1'
								CASE 'VIDEO':		mySharpDisplay.INPUT = '4'
								CASE 'HDMI1':		mySharpDisplay.INPUT = '9'
								CASE 'HDMI1PC':	mySharpDisplay.INPUT = '10'
								CASE 'HDMI2':		mySharpDisplay.INPUT = '12'
								CASE 'HDMI2PC':	mySharpDisplay.INPUT = '13'
								CASE 'HDMI3':		mySharpDisplay.INPUT = '17'
								CASE 'HDMI3PC':	mySharpDisplay.INPUT = '18'
							}
						}
						CASE INPUT_CONFIG_02:{
							SWITCH(DATA.TEXT){
								CASE 'VIDEO':	mySharpDisplay.INPUT = '2'
								CASE 'HDMI1':	mySharpDisplay.INPUT = '4'
								CASE 'HDMI2':	mySharpDisplay.INPUT = '5'
							}
						}
						CASE INPUT_CONFIG_03:{//PN-LE901
							SWITCH(DATA.TEXT){
								CASE 'HDMI1':	mySharpDisplay.INPUT = '1'
								CASE 'HDMI2':	mySharpDisplay.INPUT = '2'
								CASE 'HDMI3':	mySharpDisplay.INPUT = '3'
								CASE 'VIDEO':	mySharpDisplay.INPUT = '4'
								CASE 'COMPO':	mySharpDisplay.INPUT = '5'
								CASE 'VGA'  :	mySharpDisplay.INPUT = '6'
								CASE 'USB'  :	mySharpDisplay.INPUT = '7'
								CASE 'NET'  :	mySharpDisplay.INPUT = '8'
							}
						}
					}
					IF(!mySharpDisplay.POWER){
						fnAddCmdToQueue('POWR','1')
						TIMELINE_CREATE(TLID_INPUT,TLT_INPUT,LENGTH_ARRAY(TLT_INPUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
					ElSE{
						SWITCH(mySharpDisplay.INPUT_CONFIG){
							CASE INPUT_CONFIG_01:{
								fnAddCmdToQueue('INPS',mySharpDisplay.INPUT)
							}
							CASE INPUT_CONFIG_02:
							CASE INPUT_CONFIG_03:{
								fnAddCmdToQueue('IAVD',mySharpDisplay.INPUT)
							}
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
	IF(mySharpDisplay.VOL_PEND){
		fnAddCmdToQueue('VOLM',ITOA(mySharpDisplay.LAST_VOL))
		mySharpDisplay.VOLUME = mySharpDisplay.LAST_VOL
		mySharpDisplay.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_INPUT]{
	SWITCH(mySharpDisplay.INPUT_CONFIG){
		CASE INPUT_CONFIG_01:{
			fnAddCmdToQueue('INPS',mySharpDisplay.INPUT)
		}
		CASE INPUT_CONFIG_02:
		CASE INPUT_CONFIG_03:{
			fnAddCmdToQueue('IAVD',mySharpDisplay.INPUT)
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!mySharpDisplay.DISABLED){
		[vdvControl,199] = (mySharpDisplay.MUTE)
		[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
		[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
		[vdvControl,255] = ((mySharpDisplay.POWER)&&(mySharpDisplay.lastCMD == ''))
		SEND_LEVEL vdvControl,1,mySharpDisplay.VOLUME
	}
}