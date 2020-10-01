MODULE_NAME='mSamsungDisplay'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
Samsung Screen Module
Note: Defaults to ID 1, set to ID 254 for broadcast control with no FB

******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	INTEGER 	DISABLED
	CHAR 	   Tx[1000]
	CHAR 	   Rx[1000]
	INTEGER	PEND
	INTEGER  DEBUG
	INTEGER  ID
	INTEGER	isIP
	INTEGER 	CONN_STATE
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[255]
}
DEFINE_TYPE STRUCTURE uDisplay{

	uComms	COMMS

	INTEGER  POWER
	INTEGER  SOURCE
	CHAR 		SOURCE_NAME[40]
	INTEGER  desSOURCE
	INTEGER  LOCKED
	INTEGER  OSD
	INTEGER 	VOL
	INTEGER  MUTE

	INTEGER	VOL_PEND
	INTEGER	LAST_VOL

	INTEGER	HDMI_AUD_NATIVE[2]
	INTEGER	HDMI_AUD_EXT[2]

	CHAR 		META_SN[14]
	CHAR		META_MODEL[50]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_INPUT 	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 3
LONG TLID_VOL		= 4
LONG TLID_TIMEOUT	= 5
LONG TLID_BOOT		= 6

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV		= 2

DEFINE_VARIABLE
VOLATILE uDisplay mySamsungDisplay
LONG TLT_POLL[]		= { 30000}
LONG TLT_COMMS[]		= { 90000}
LONG TLT_INPUT[]		= { 2000,12000}
LONG TLT_VOL[]			= {  150}
LONG TLT_TIMEOUT[]	= { 1500}
LONG TLT_BOOT[]		= { 5000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	mySamsungDisplay.COMMS.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, mySamsungDisplay.COMMS.Rx
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(mySamsungDisplay.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Samsung Error','IP Address Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Attemping Connect',"'Samsung ',mySamsungDisplay.COMMS.IP_HOST,':',ITOA(mySamsungDisplay.COMMS.IP_PORT)")
		mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, mySamsungDisplay.COMMS.IP_HOST, mySamsungDisplay.COMMS.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION CHAR[25] fnBuildCommand(INTEGER pID, INTEGER pCMD, CHAR pDATA[]){

	STACK_VAR CHAR 	myPacket[25]
	STACK_VAR INTEGER CHK_SUM;
	STACK_VAR INTEGER x

	myPacket = "pCMD,pID,LENGTH_ARRAY(pDATA),pDATA"
	FOR (x = 1; x <=LENGTH_ARRAY(myPacket); x++){
		CHK_SUM = CHK_SUM + myPacket[x];
	}
	CHK_SUM = HEXTOI(RIGHT_STRING(ITOHEX(CHK_SUM),2))

	RETURN "$AA,myPacket,CHK_SUM"
}

DEFINE_FUNCTION fnAddToQueue(INTEGER pCMD, CHAR pDATA[]){

	STACK_VAR CHAR myMessage[25]

	IF(mySamsungDisplay.COMMS.ID == 0){ mySamsungDisplay.COMMS.ID = 1 }

	myMessage = fnBuildCommand(mySamsungDisplay.COMMS.ID,pCMD,pDATA)

	mySamsungDisplay.COMMS.Tx = "mySamsungDisplay.COMMS.Tx,myMessage,$AA,$BB,$CC,$DD"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!mySamsungDisplay.COMMS.PEND && mySamsungDisplay.COMMS.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(mySamsungDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(mySamsungDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1),4)
		SEND_STRING dvDevice,toSend
		fnDebugHex(DEBUG_STD,'->SAM',toSend)
		mySamsungDisplay.COMMS.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(mySamsungDisplay.COMMS.isIP && mySamsungDisplay.COMMS.CONN_STATE == CONN_STATE_OFFLINE && FIND_STRING(mySamsungDisplay.COMMS.Tx,"$AA,$BB,$CC,$DD",1)){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	mySamsungDisplay.COMMS.PEND = FALSE
	mySamsungDisplay.COMMS.Tx = ''
	IF(mySamsungDisplay.COMMS.isIP && mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!mySamsungDisplay.COMMS.DISABLED){
		IF(!mySamsungDisplay.COMMS.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		}
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Samsung'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2|DPORT|DVI|PC'
		SEND_STRING vdvControl,'RANGE-0,100'
		fnInit()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(mySamsungDisplay.COMMS.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnDebugHex(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(mySamsungDisplay.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR pHEX[1000]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
			pHEX = "pHEX,'$',fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2)"
		}
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', pHEX"
	}
}

/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(!mySamsungDisplay.COMMS.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	IF(mySamsungDisplay.COMMS.ID != $FE){ fnPoll() }
}
DEFINE_FUNCTION fnInit(){
	IF(mySamsungDisplay.COMMS.ID != $FE){
		fnAddToQueue($8A,"")
	}
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue($00,"")
}

/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!mySamsungDisplay.COMMS.DISABLED){
			IF(mySamsungDisplay.COMMS.isIP){
				mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(mySamsungDisplay.COMMS.isIP && !mySamsungDisplay.COMMS.DISABLED){
			mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_OFFLINE
		}
	}
	ONERROR:{
		IF(mySamsungDisplay.COMMS.isIP && !mySamsungDisplay.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					mySamsungDisplay.COMMS.CONN_STATE = CONN_STATE_OFFLINE
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
			fnDebug(TRUE,"'Samsung IP Error:[',mySamsungDisplay.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!mySamsungDisplay.COMMS.DISABLED){
			fnDebugHex(DEBUG_DEV,'RAW->', DATA.TEXT)
			IF(LENGTH_ARRAY(mySamsungDisplay.COMMS.Rx)){
				// Clean off possible Garbage until $AA Found
				WHILE(FIND_STRING(mySamsungDisplay.COMMS.Rx,"$AA",1) && mySamsungDisplay.COMMS.Rx[1] != $AA){
					fnDebug(DEBUG_DEV,'WHILE', "'EAT GARBAGE:',ITOHEX(GET_BUFFER_CHAR(mySamsungDisplay.COMMS.Rx))")
				}
				// While there is enough data in the buffer to be a command
				WHILE(LENGTH_ARRAY(mySamsungDisplay.COMMS.Rx)){
					STACK_VAR INTEGER pDataLength
					fnDebug(DEBUG_DEV,'DATA.TEXT|WHILE', "'RxLen=',ITOA(LENGTH_ARRAY(mySamsungDisplay.COMMS.Rx))")

					pDataLength = mySamsungDisplay.COMMS.Rx[4]
					fnDebug(DEBUG_DEV,'DATA.TEXT|WHILE', "'pDataLength=',ITOA(pDataLength)")

					IF(LENGTH_ARRAY(mySamsungDisplay.COMMS.Rx) >= pDataLength + 4){
						STACK_VAR INTEGER i;
						STACK_VAR INTEGER CHK;
						STACK_VAR CHAR pMSG[255]
						pMSG = GET_BUFFER_STRING(mySamsungDisplay.COMMS.Rx,pDataLength + 7)
						FOR (i = 2; i < LENGTH_ARRAY(pMSG); i++){
							CHK = CHK + pMSG[i]
						}
						CHK = HEXTOI(RIGHT_STRING(ITOHEX(CHK),2))
						IF(CHK == pMSG[LENGTH_ARRAY(pMSG)]){
							fnProcessFeedback(pMSG)
							mySamsungDisplay.COMMS.PEND = FALSE
							fnSendFromQueue()
						}
						ELSE{
							mySamsungDisplay.COMMS.Rx = ''
							fnDebug(DEBUG_DEV,'DATA.TEXT', "'Bad ChkSum[',ITOHEX(CHK),'vs',ITOHEX(pMSG[LENGTH_ARRAY(pMSG)])")
							BREAK
						}
					}
					ELSE{
						fnDebug(DEBUG_DEV,'DATA.TEXT', "'More Packet Expected'")
						BREAK
					}
				}
			}
		}
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	fnDebugHex(DEBUG_STD,'SAM->', pDATA)
	GET_BUFFER_CHAR(pDATA)	// Remove $AA
	GET_BUFFER_CHAR(pDATA)	// Remove $FF
	pDATA = fnStripCharsRight(pDATA,1)	// Remove CHKSUM
	IF(GET_BUFFER_CHAR(pDATA) == mySamsungDisplay.COMMS.ID){	// Get ID
		STACK_VAR INTEGER ERROR
		STACK_VAR CHAR	 	ERROR_TEXT[20]
		STACK_VAR INTEGER LEN
		LEN = GET_BUFFER_CHAR(pDATA)	// Remove Data Length
		ERROR = (GET_BUFFER_CHAR(pDATA) == 'N')
		IF(!ERROR){
			fnDebug(DEBUG_STD,'SAM ACK','')
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE $00:{	// Status Request
					fnDebug(DEBUG_STD,'SAM Response','Status Request')
					IF(LEN){
						mySamsungDisplay.POWER 	= pDATA[1]
						mySamsungDisplay.VOL 	= pDATA[2]
						mySamsungDisplay.MUTE 	= pDATA[3]
						IF(mySamsungDisplay.SOURCE != pDATA[4]){
							mySamsungDisplay.SOURCE = pDATA[4]
							mySamsungDisplay.SOURCE_NAME = fnGetSourceName(mySamsungDisplay.SOURCE)
						}
						IF(mySamsungDisplay.META_MODEL == ''){
							fnInit()
						}
					}
				}
				CASE $11:{
					fnDebug(DEBUG_STD,'SAM Response','Set power')
				}
				CASE $8A:{	// Model Name
					fnDebug(DEBUG_STD,'SAM Response','Model Name')
					IF(mySamsungDisplay.META_MODEL != pDATA){
						mySamsungDisplay.META_MODEL = pDATA
						SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',mySamsungDisplay.META_MODEL"
					}
					fnAddToQueue($0B,"")	// Get Serial Number
				}
				CASE $62:{	// Volume Inc/Dec Command
					fnDebug(DEBUG_STD,'SAM Response','Volume Set')
					fnAddToQueue($00,"")	// Get Status
				}
				CASE $0B:{	// Serial Number
					STACK_VAR CHAR pSN[255]
					fnDebug(DEBUG_STD,'SAM Response','Serial Number')
					pSN = GET_BUFFER_STRING(pDATA,14)
					IF(mySamsungDisplay.META_SN != pSN){
						mySamsungDisplay.META_SN = pSN
						SEND_STRING vdvControl,"'PROPERTY-META,SERIALNO,',mySamsungDisplay.META_SN"
					}
				}
			}
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		ELSE{
			fnDebug(DEBUG_STD,'SAM NAK',fnPadLeadingChars(ITOHEX(GET_BUFFER_CHAR(pDATA)),'0',2))
		}
	}
}
/******************************************************************************
	Virtual Device Events
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
							CASE 'SAMSUNG':
							CASE 'TRUE':mySamsungDisplay.COMMS.DISABLED = FALSE
							DEFAULT:		mySamsungDisplay.COMMS.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!mySamsungDisplay.COMMS.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'ALL':{
					SWITCH(DATA.TEXT){
						CASE 'ON': SEND_STRING dvDevice,fnBuildCommand(254,$11,"$01")
						CASE 'OFF':SEND_STRING dvDevice,fnBuildCommand(254,$11,"$00")
					}
				}
				CASE 'ACTION':{
					SWITCH(DATA.TEXT){
						CASE 'INIT':fnInit()
					}
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE':mySamsungDisplay.COMMS.DEBUG = DEBUG_STD
								CASE 'DEV':	mySamsungDisplay.COMMS.DEBUG = DEBUG_DEV
								DEFAULT:		mySamsungDisplay.COMMS.DEBUG = DEBUG_ERR
							}
						}
						CASE 'ID': 	  mySamsungDisplay.COMMS.ID 	= ATOI(DATA.TEXT);
						CASE 'IP':{
							mySamsungDisplay.COMMS.IP_HOST 	= DATA.TEXT
							mySamsungDisplay.COMMS.IP_PORT	= 1515
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
				CASE 'EXTERNALAUDIO':{
					STACK_VAR INTEGER HDMI
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'HDMI1':{ HDMI = 1 }
						CASE 'HDMI2':{ HDMI = 2 }
					}
					SWITCH(DATA.TEXT){
						CASE 'TRUE':{
							mySamsungDisplay.HDMI_AUD_EXT[HDMI] 		= TRUE
							mySamsungDisplay.HDMI_AUD_NATIVE[HDMI] 	= FALSE
						}
						CASE 'FALSE':{
							mySamsungDisplay.HDMI_AUD_EXT[HDMI] 		= FALSE
							mySamsungDisplay.HDMI_AUD_NATIVE[HDMI] 	= TRUE
						}
						CASE 'DEFAULT':{
							mySamsungDisplay.HDMI_AUD_EXT[HDMI] 		= FALSE
							mySamsungDisplay.HDMI_AUD_NATIVE[HDMI] 	= FALSE
						}
					}
				}
				CASE 'RAW':{
					fnAddToQueue(HEXTOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),"HEXTOI(DATA.TEXT)")
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'TOGGLE':{ mySamsungDisplay.POWER = !mySamsungDisplay.POWER }
						CASE 'ON':{  mySamsungDisplay.POWER = TRUE  }
						CASE 'OFF':{ mySamsungDisplay.POWER = FALSE }
					}
					SWITCH(mySamsungDisplay.POWER){
						CASE TRUE:{  fnAddToQueue($11,"$01") }
						CASE FALSE:{ fnAddToQueue($11,"$00") }
					}
				}
				CASE 'LOCK':{
					SWITCH(DATA.TEXT){
						CASE 'ON': { fnAddToQueue($5D,"$01");mySamsungDisplay.LOCKED = TRUE  }
						CASE 'OFF':{ fnAddToQueue($5D,"$00");mySamsungDisplay.LOCKED = FALSE }
					}
				}
				CASE 'NETWORKSTANDBY':{
					SWITCH(DATA.TEXT){
						CASE 'ON': { fnAddToQueue($B5,"$01")  }
						CASE 'OFF':{ fnAddToQueue($B5,"$00")  }
					}
				}
				CASE 'OSD':{
					SWITCH(DATA.TEXT){
						CASE 'ON':{  fnAddToQueue($70,"$01");mySamsungDisplay.OSD = TRUE  }
						CASE 'OFF':{ fnAddToQueue($70,"$00");mySamsungDisplay.OSD = FALSE }
					}
				}
				CASE 'INPUT':{
					mySamsungDisplay.desSOURCE = fnGetSourceCode(DATA.TEXT)
					IF(mySamsungDisplay.desSOURCE){
						fnAddToQueue($14,"mySamsungDisplay.desSOURCE")
						IF(TIMELINE_ACTIVE(TLID_INPUT))TIMELINE_KILL(TLID_INPUT)
						TIMELINE_CREATE(TLID_INPUT,TLT_Input,LENGTH_ARRAY(TLT_Input),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
				CASE 'ADJUST':{
					fnAddToQueue($3D,"$00")
				}
				CASE 'REMOTE':{
					SWITCH(DATA.TEXT){
						CASE 'MENU':	fnAddToQueue($B0,"$1A")
						CASE 'CUR_UP':	fnAddToQueue($B0,"$60")
						CASE 'CUR_DN':	fnAddToQueue($B0,"$61")
						CASE 'CUR_LT':	fnAddToQueue($B0,"$65")
						CASE 'CUR_RT':	fnAddToQueue($B0,"$62")
						CASE 'EXIT':	fnAddToQueue($B0,"$2D")
						CASE 'ENTER':	fnAddToQueue($B0,"$68")
						CASE 'RETURN': fnAddToQueue($B0,"$58")
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	mySamsungDisplay.MUTE = 1
						CASE 'OFF':	mySamsungDisplay.MUTE = 0
						CASE 'TOGGLE':mySamsungDisplay.MUTE = !mySamsungDisplay.MUTE
					}
					fnAddToQueue($13,"mySamsungDisplay.MUTE")
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						CASE 'INC':fnAddToQueue($62,"$00")
						CASE 'DEC':fnAddToQueue($62,"$01")
						DEFAULT:{
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								fnAddToQueue($12,"ATOI(DATA.TEXT)")
								mySamsungDisplay.VOL = ATOI(DATA.TEXT)
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								mySamsungDisplay.LAST_VOL = ATOI(DATA.TEXT)
								mySamsungDisplay.VOL_PEND = TRUE
							}
						}
					}
					mySamsungDisplay.MUTE = FALSE
				}
			}
		}
	}
}
/******************************************************************************
	Control Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(mySamsungDisplay.VOL_PEND){
		fnAddToQueue($12,"mySamsungDisplay.LAST_VOL")
		mySamsungDisplay.VOL = mySamsungDisplay.LAST_VOL
		mySamsungDisplay.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_INPUT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1:{ fnAddToQueue($11,"$01");mySamsungDisplay.POWER = TRUE }
		CASE 2:{ fnAddToQueue($14,"mySamsungDisplay.desSOURCE") }
	}
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION CHAR[255] fnGetSourceName(INTEGER pINPUT){
	SWITCH(pINPUT){
		CASE $14: RETURN 'PC'
		CASE $1E: RETURN 'BNC'
		CASE $18: RETURN 'DVI'
		CASE $0C: RETURN 'SOURCE'
		CASE $04: RETURN 'SVIDEO'
		CASE $08: RETURN 'COMPONENT'
		CASE $20: RETURN 'MAGICINFO'
		CASE $1F: RETURN 'DVI_VID'
		CASE $30: RETURN 'ATV'
		CASE $40: RETURN 'DTV'
		CASE $21: RETURN 'HDMI1'
		CASE $22: RETURN 'HDMI1PC'
		CASE $23: RETURN 'HDMI2'
		CASE $24: RETURN 'HDMI2PC'
		CASE $25: RETURN 'DPORT'
		CASE $64: RETURN 'IWB'
	}
}
DEFINE_FUNCTION INTEGER fnGetSourceCode(CHAR pINPUT[255]){
	SWITCH(pINPUT){
		CASE 'VGA':
		CASE 'PC': 				RETURN $14
		CASE 'BNC': 			RETURN $1E
		CASE 'DVI': 			RETURN $18
		CASE 'SOURCE': 		RETURN $0C
		CASE 'SVIDEO': 		RETURN $04
		CASE 'COMPONENT': 	RETURN $08
		CASE 'MAGICINFO': 	RETURN $20
		CASE 'DVI_VID': 		RETURN $1F
		CASE 'ATV': 			RETURN $30
		CASE 'DTV': 			RETURN $40
		CASE 'HDMI': 			RETURN $21
		CASE 'HDMI1': 			RETURN $21
		CASE 'HDMI1PC': 		RETURN $22
		CASE 'HDMI2': 			RETURN $23
		CASE 'HDMI2PC': 		RETURN $24
		CASE 'DPORT': 			RETURN $25
		CASE 'IWB': 			RETURN $64
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	IF(!mySamsungDisplay.COMMS.DISABLED){
		SEND_LEVEL vdvControl,1,mySamsungDisplay.VOL
		[vdvControl,199] = (mySamsungDisplay.MUTE)
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,255] = (mySamsungDisplay.POWER)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
