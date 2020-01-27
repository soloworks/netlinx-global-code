MODULE_NAME='mDenonDN-V500BD'(DEV vdvControl,DEV dvDevice)
/******************************************************************************
	Set up for basic control - not zoned
******************************************************************************/
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	INTEGER 	DISABLED
	CHAR 	   Tx[200]
	CHAR 	   Rx[200]
	INTEGER	PEND
	INTEGER 	CONN_STATE
	INTEGER 	IP_PORT						// IP Address
	CHAR		IP_HOST[255]				//	IP Port
	INTEGER 	IP_STATE						// Connection State
	INTEGER	isIP							// Device is IP driven
	CHAR     BAUD_RATE[255]          // Serial Baud rate
	INTEGER 	DEBUG							// Debugging
}

DEFINE_TYPE STRUCTURE uDenonBR{
	uComms   COMMS
	// State
	INTEGER  POWER
	CHAR     desCOMMAND

	// Feedback
	CHAR     ANSWER_CODE[16]
	CHAR     DISC_TYPE[16]
	CHAR     AUDIO_FORMAT[16]
	CHAR     AUDIO_CHANNEL[16]
	CHAR     DIALOGUE[16]
	CHAR     SUBTITLE[16]
	CHAR     STATUS_CODE[32]
	CHAR     PLAY_MODE[16]
	CHAR     TIME_MODE[16]
	CHAR     TIME_FB[12][16]
	// RMS
	CHAR 		META_SN[14]
	CHAR		META_MODEL[50]
	CHAR     META_MAKE[50]
}

DEFINE_CONSTANT
// Timelines
LONG TLID_COMMS 	= 1
LONG TLID_RETRY	= 2
LONG TLID_POLL		= 3
LONG TLID_TIMEOUT	= 4
LONG TLID_BOOT		= 5

// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

// POWER States
INTEGER P_ON  = 1
INTEGER P_OFF = 2

// DEBUG States
INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= { 120000 }
LONG TLT_RETRY[]		= {   5000 }
LONG TLT_POLL[]  		= {  25000 }
LONG TLT_TIMEOUT[]	= {   1500 }
LONG TLT_BOOT[]		= {   5000 }

VOLATILE uDenonBR myDenonBR

/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myDenonBR.COMMS.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myDenonBR.COMMS.Rx
}
/******************************************************************************
	Helper Functions
******************************************************************************/
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myDenonBR.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Bluray IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to Bluray on ',"myDenonBR.COMMS.IP_HOST,':',ITOA(myDenonBR.COMMS.IP_PORT)")
		myDenonBR.COMMS.IP_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myDenonBR.COMMS.IP_HOST, myDenonBR.COMMS.IP_PORT, IP_TCP)
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

DEFINE_FUNCTION CHAR[25] fnBuildCommand(CHAR pCMD[], CHAR pDATA[]){

	STACK_VAR CHAR 	myPacket[25]
	STACK_VAR INTEGER CHK_SUM
	STACK_VAR CHAR    CHK_SUM_HI[2]
	STACK_VAR CHAR    CHK_SUM_LO[2]
	STACK_VAR INTEGER x

	myPacket = "pCMD,pDATA,"$00","$00","$00","$00",$03"
	FOR (x = 1; x <=LENGTH_ARRAY(myPacket); x++){
		CHK_SUM = CHK_SUM + myPacket[x];
	}
	CHK_SUM_HI = ITOHEX( ATOI(  LEFT_STRING(ITOHEX(CHK_SUM),1) ) )
	CHK_SUM_LO = ITOHEX( ATOI( RIGHT_STRING(ITOHEX(CHK_SUM),1) ) )

	RETURN "$02,myPacket,CHK_SUM_HI,CHK_SUM_LO"
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[], CHAR pDATA[]){

	STACK_VAR CHAR myMessage[255]

	myMessage = fnBuildCommand(pCMD,pDATA)

	myDenonBR.COMMS.Tx = "myDenonBR.COMMS.Tx,myMessage,'||'"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myDenonBR.COMMS.PEND && myDenonBR.COMMS.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myDenonBR.COMMS.Tx,'||',1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(myDenonBR.COMMS.Tx,'||',1),2)
		fnDebugHex(DEBUG_STD,'->Bluray ',toSend)
		SEND_STRING dvDevice,toSend
		myDenonBR.COMMS.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(myDenonBR.COMMS.isIP && myDenonBR.COMMS.CONN_STATE == CONN_STATE_OFFLINE && FIND_STRING(myDenonBR.COMMS.Tx,'||',1)){
		fnOpenTCPConnection()
	}
	fnInitPoll()
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myDenonBR.COMMS.PEND = FALSE
	myDenonBR.COMMS.Tx = ''
	IF(myDenonBR.COMMS.isIP && myDenonBR.COMMS.CONN_STATE = CONN_STATE_CONNECTED){
		fnCloseTCPConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myDenonBR.COMMS.DISABLED){
		IF(!myDenonBR.COMMS.isIP){
			IF(myDenonBR.COMMS.BAUD_RATE = ''){
				myDenonBR.COMMS.BAUD_RATE = '9600 E 8 1 485 DISABLE'
			}
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice,"'SET BAUD ',myDenonBR.COMMS.BAUD_RATE"
			SEND_COMMAND dvDevice, 'GET BAUD'
			myDenonBR.COMMS.CONN_STATE = CONN_STATE_CONNECTED
		}
		myDenonBR.META_MAKE  = 'Denon'
		myDenonBR.META_MODEL = 'DN-V500BD'
		myDenonBR.META_SN    = 'N/A'
		SEND_STRING vdvControl, 'PROPERTY-META,TYPE,Bluray'
		SEND_STRING vdvControl,"'PROPERTY-META,MAKE,', myDenonBR.META_MAKE"
		SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myDenonBR.META_MODEL"
		SEND_STRING vdvControl,"'PROPERTY-META,SN,',   myDenonBR.META_SN"
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR Msg[], CHAR MsgData[]){
	IF(myDenonBR.COMMS.DEBUG >= pDEBUG){
		IF(myDenonBR.COMMS.DEBUG == DEBUG_DEV){
			SEND_COMMAND dvDevice,
							"ITOA(vdvControl.Number),':',Msg,' [', MsgData,']'"
		}
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg,' [', MsgData,']'"
	}
}
DEFINE_FUNCTION fnDebugHex(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myDenonBR.COMMS.DEBUG >= pDEBUG){
		STACK_VAR CHAR pHEX[1000]
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(MsgData); x++){
			pHEX = "pHEX,'$',fnPadLeadingChars(ITOHEX(MsgData[x]),'0',2)"
		}
		IF(myDenonBR.COMMS.DEBUG == DEBUG_DEV){
			SEND_COMMAND dvDevice,
							"ITOA(vdvControl.Number),':',Msg,' [', MsgData,']'"
			SEND_COMMAND dvDevice,
							"ITOA(vdvControl.Number),':',Msg,' [', pHEX,']'"
		}
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg,' [', pHEX,']'"
	}
}

/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	SEND_COMMAND vdvControl,'QUERY-STATUS'
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myDenonBR.COMMS.DISABLED){
			IF(myDenonBR.COMMS.isIP){
				myDenonBR.COMMS.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		IF(myDenonBR.COMMS.isIP && !myDenonBR.COMMS.DISABLED){
			myDenonBR.COMMS.CONN_STATE = CONN_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myDenonBR.COMMS.isIP && !myDenonBR.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myDenonBR.COMMS.IP_STATE = CONN_STATE_OFFLINE
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
			fnDebug(TRUE,"'Bluray IP Error:[',myDenonBR.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'RAW->',DATA.TEXT)
		// Strip any Garbage (ACK/NACKs)
		IF(DATA.TEXT == 'ack'){
			REMOVE_STRING(DATA.TEXT,'ack',1)
		}
		IF(DATA.TEXT == "$06"){// Ack in Hex
			REMOVE_STRING(DATA.TEXT,"$06",1)
		}
		IF(DATA.TEXT == 'nack'){
			REMOVE_STRING(DATA.TEXT,'nack',1)
		}
		IF(DATA.TEXT == "$15"){// Nack in Hex
			REMOVE_STRING(DATA.TEXT,"$15",1)
		}
		WHILE(FIND_STRING(myDenonBR.COMMS.RX,"$03",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myDenonBR.COMMS.RX,"$03",1),1))
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	STACK_VAR INTEGER pPOWER
	STACK_VAR INTEGER pTIME
	REMOVE_STRING(pDATA,"$02",1)
	fnDebug(DEBUG_STD,'Bluray-> ',pDATA)
	SWITCH(fnRemoveWhiteSpace(pDATA)){
		CASE 'DBP2010':{
			pPOWER = P_ON
		}
		CASE '!':{
			pPOWER = P_OFF
		}
		DEFAULT:{
			SWITCH(pDATA[1]){
				CASE '0':{
					SWITCH(pDATA[3]){
						CASE '1': myDenonBR.DISC_TYPE = 'DVD VIDEO'
						CASE '2': myDenonBR.DISC_TYPE = 'DVD AUDIO'
						CASE '3': myDenonBR.DISC_TYPE = 'VCD'
						CASE '4': myDenonBR.DISC_TYPE = 'CD-DA'
						CASE '5': myDenonBR.DISC_TYPE = 'CD-ROM'
						CASE '6': myDenonBR.DISC_TYPE = 'UNKNOWN'
						CASE '7': myDenonBR.DISC_TYPE = 'SACD'
						CASE '8': myDenonBR.DISC_TYPE = 'DVD VR'
						CASE '9': myDenonBR.DISC_TYPE = 'BDMV'
						CASE ':': myDenonBR.DISC_TYPE = 'BDAV'
					}
					SWITCH(pDATA[4]){
						CASE '1': myDenonBR.AUDIO_FORMAT = 'DOLBY DIGITAL'
						CASE '2': myDenonBR.AUDIO_FORMAT = 'DTS'
						CASE '3': myDenonBR.AUDIO_FORMAT = 'MPEG'
						CASE '4': myDenonBR.AUDIO_FORMAT = 'LPCM'
						CASE '5': myDenonBR.AUDIO_FORMAT = 'PPCM'
						CASE '6': myDenonBR.AUDIO_FORMAT = 'UNKNOWN'
						CASE '7': myDenonBR.AUDIO_FORMAT = 'DSD'
						CASE '8': myDenonBR.AUDIO_FORMAT = 'DD+'
						CASE '9': myDenonBR.AUDIO_FORMAT = 'DTS-HD'
						CASE ':': myDenonBR.AUDIO_FORMAT = 'DOLBY TrueHD'
						CASE ';': myDenonBR.AUDIO_FORMAT = 'MP3'
						CASE '<': myDenonBR.AUDIO_FORMAT = 'AAC'
						CASE '=': myDenonBR.AUDIO_FORMAT = 'WMA'
					}
					SWITCH(pDATA[5]){
						CASE '1': myDenonBR.AUDIO_CHANNEL = '1 Ch'
						CASE '2': myDenonBR.AUDIO_CHANNEL = '2 Ch'
						CASE '3': myDenonBR.AUDIO_CHANNEL = '2.1 Ch'
						CASE '4': myDenonBR.AUDIO_CHANNEL = '3 Ch'
						CASE '5': myDenonBR.AUDIO_CHANNEL = '3.1 Ch'
						CASE '6': myDenonBR.AUDIO_CHANNEL = '4 Ch'
						CASE '7': myDenonBR.AUDIO_CHANNEL = '4.1 Ch'
						CASE '8': myDenonBR.AUDIO_CHANNEL = '5 Ch'
						CASE '9': myDenonBR.AUDIO_CHANNEL = '5.1 Ch'
						CASE ':': myDenonBR.AUDIO_CHANNEL = '6 Ch'
						CASE ';': myDenonBR.AUDIO_CHANNEL = 'L /R (CD/VCD/MP3)'
						CASE '<': myDenonBR.AUDIO_CHANNEL = 'R (CD/VCD)'
						CASE '=': myDenonBR.AUDIO_CHANNEL = 'L (CD/VCD)'
						CASE '>': myDenonBR.AUDIO_CHANNEL = 'UNKNOWN'
						CASE '?': myDenonBR.AUDIO_CHANNEL = '6.1 Ch'
						CASE '@': myDenonBR.AUDIO_CHANNEL = '7 Ch'
						CASE 'A': myDenonBR.AUDIO_CHANNEL = '7.1 Ch'
						CASE 'B': myDenonBR.AUDIO_CHANNEL = '8 Ch'
					}
					SWITCH(pDATA[6]){
						CASE '1': myDenonBR.DIALOGUE = 'JPN'
						CASE '2': myDenonBR.DIALOGUE = 'ENG'
						CASE '3': myDenonBR.DIALOGUE = 'FRA'
						CASE '4': myDenonBR.DIALOGUE = 'DEU'
						CASE '5': myDenonBR.DIALOGUE = 'ITA'
						CASE '6': myDenonBR.DIALOGUE = 'ESP'
						CASE '7': myDenonBR.DIALOGUE = 'NLD'
						CASE '8': myDenonBR.DIALOGUE = 'CHI'
						CASE '9': myDenonBR.DIALOGUE = 'RUS'
						CASE ':': myDenonBR.DIALOGUE = 'KOR'
						CASE ';': myDenonBR.DIALOGUE = 'UNKNOWN'
					}
					SWITCH(pDATA[7]){
						CASE '1': myDenonBR.SUBTITLE = 'JPN'
						CASE '2': myDenonBR.SUBTITLE = 'ENG'
						CASE '3': myDenonBR.SUBTITLE = 'FRA'
						CASE '4': myDenonBR.SUBTITLE = 'DEU'
						CASE '5': myDenonBR.SUBTITLE = 'ITA'
						CASE '6': myDenonBR.SUBTITLE = 'ESP'
						CASE '7': myDenonBR.SUBTITLE = 'NLD'
						CASE '8': myDenonBR.SUBTITLE = 'CHI'
						CASE '9': myDenonBR.SUBTITLE = 'RUS'
						CASE ':': myDenonBR.SUBTITLE = 'KOR'
						CASE ';': myDenonBR.SUBTITLE = 'UNKNOWN'
					}
					SWITCH(pDATA[9]){
						CASE '0': { myDenonBR.STATUS_CODE = 'STANDBY'							pPOWER = P_OFF }
						CASE '1': { myDenonBR.STATUS_CODE = 'DISC LOADING'						pPOWER = P_ON  }
						CASE '2': { myDenonBR.STATUS_CODE = 'DISC LOADING COPMPLETE'		pPOWER = P_ON  }
						CASE '3': { myDenonBR.STATUS_CODE = 'TRAY OPEN'							pPOWER = P_ON  }
						CASE '4': { myDenonBR.STATUS_CODE = 'TRAY CLOSE'						pPOWER = P_ON  }
						CASE 'A': { myDenonBR.STATUS_CODE = 'DISC NOT PRESENT'				pPOWER = P_ON  }
						CASE 'B': { myDenonBR.STATUS_CODE = 'STOP'								pPOWER = P_ON  }
						CASE 'C': { myDenonBR.STATUS_CODE = 'DISC PLAYING'						pPOWER = P_ON  }
						CASE 'D': { myDenonBR.STATUS_CODE = 'PLAYBACK IN PROCESS'			pPOWER = P_ON  }
						CASE 'E': { myDenonBR.STATUS_CODE = 'SCANNING IN PROCESS'			pPOWER = P_ON  }
						CASE 'F': { myDenonBR.STATUS_CODE = 'SLOW SCANNING IN PROCESS'		pPOWER = P_ON  }
						CASE 'G': { myDenonBR.STATUS_CODE = 'SETUP MODE'						pPOWER = P_ON  }
						CASE 'H': { myDenonBR.STATUS_CODE = 'PLAY BACK CONTROL SCANNING'	pPOWER = P_ON  }
						CASE 'I': { myDenonBR.STATUS_CODE = 'RESUME STOP'						pPOWER = P_ON  }
						CASE 'J': { myDenonBR.STATUS_CODE = 'DVD MENU PLAYBACK'				pPOWER = P_ON  }
						DEFAULT:  { myDenonBR.STATUS_CODE = "pDATA[9]"							pPOWER = P_ON  }
					}
					SWITCH(pDATA[10]){
						CASE '1': myDenonBR.PLAY_MODE = 'NORMAL'
						CASE '2': myDenonBR.PLAY_MODE = 'PROGRAM'
						CASE '3': myDenonBR.PLAY_MODE = 'RANDOM'
					}
					SWITCH(pDATA[18]){
						CASE '1': { myDenonBR.TIME_MODE = 'SINGLE ELAPSED'		pTIME =  1 }
						CASE '2': { myDenonBR.TIME_MODE = 'SINGLE REMAIN'		pTIME =  2 }
						CASE '3': { myDenonBR.TIME_MODE = 'TOTAL ELAPSED'		pTIME =  3 }
						CASE '4': { myDenonBR.TIME_MODE = 'TOTAL REMAIN'		pTIME =  4 }
						CASE '5': { myDenonBR.TIME_MODE = 'CHAPTER ELAPSED'	pTIME =  5 }
						CASE '6': { myDenonBR.TIME_MODE = 'CHAPTER REMAIN'		pTIME =  6 }
						CASE '7': { myDenonBR.TIME_MODE = 'TITLE ELAPSED'		pTIME =  7 }
						CASE '8': { myDenonBR.TIME_MODE = 'TITLE REMAIN'		pTIME =  8 }
						CASE '9': { myDenonBR.TIME_MODE = 'TRACK ELAPSED'		pTIME =  9 }
						CASE ':': { myDenonBR.TIME_MODE = 'TRACK REMAIN'		pTIME = 10 }
						CASE ';': { myDenonBR.TIME_MODE = 'GROUP ELAPSED'		pTIME = 11 }
						CASE '<': { myDenonBR.TIME_MODE = 'GROUP REMAIN'		pTIME = 12 }
					}
					myDenonBR.TIME_FB[pTIME] = "MID_STRING(pDATA,19,2),':',MID_STRING(pDATA,21,2),':',MID_STRING(pDATA,23,2)"
				}
				DEFAULT:{
					SWITCH(pDATA[2]){
						DEFAULT:  myDenonBR.ANSWER_CODE = "pDATA[2]"
					}
				}
			}
		}
		IF(myDenonBR.POWER <> pPOWER){
			SWITCH(pPOWER){
				CASE P_ON:{
					TLT_POLL[1] = 5000
					TIMELINE_RELOAD(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_COMMS))
				}
				DEFAULT:{
					TLT_POLL[1] = 25000
					TIMELINE_RELOAD(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_COMMS))
				}
			}
			myDenonBR.POWER = pPOWER
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'FALSE': { myDenonBR.COMMS.DEBUG = DEBUG_ERR }
							CASE 'TRUE':  { myDenonBR.COMMS.DEBUG = DEBUG_STD }
							CASE 'DEV':   { myDenonBR.COMMS.DEBUG = DEBUG_DEV }
							DEFAULT:      { myDenonBR.COMMS.DEBUG = ATOI(DATA.TEXT) }
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myDenonBR.COMMS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myDenonBR.COMMS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myDenonBR.COMMS.IP_HOST = DATA.TEXT
							myDenonBR.COMMS.IP_PORT = 9030
						}
						fnRetryConnection()
					}
					CASE 'BAUD':{
						IF(FIND_STRING(DATA.TEXT,' ',1)){
							myDenonBR.COMMS.BAUD_RATE = DATA.TEXT
						}
						ELSE{
							myDenonBR.COMMS.BAUD_RATE = "DATA.TEXT,' N 8 1 485 DISABLE'"
						}
						SEND_COMMAND dvDevice, 'SET MODE DATA'
						SEND_COMMAND dvDevice,"'SET BAUD ',myDenonBR.COMMS.BAUD_RATE"
						SEND_COMMAND dvDevice, 'GET BAUD'
						fnPoll()
						fnInitPoll()
					}
				}
			}
			CASE 'RAW':{
				myDenonBR.COMMS.Tx = "myDenonBR.COMMS.Tx,DATA.TEXT,'||'"
				fnSendFromQueue()
			}
			CASE 'SEND':{
				fnAddToQueue(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),DATA.TEXT)
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON'			:fnAddToQueue(' ',"$00")
					CASE 'OFF'			:fnAddToQueue('!',"$00")
				}
			}
			CASE 'QUERY':{
				SWITCH(DATA.TEXT){
					CASE 'STATUS'		:fnAddToQueue('0',"$00")
					CASE 'CPU'			:fnAddToQueue('1',"$00")
				}
			}
			CASE 'CONTROL':
			CASE 'CTRL':
			CASE 'PUSH':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY'			:fnAddToQueue('@',"$00")
					CASE 'STOP'			:fnAddToQueue('A',"$00")
					CASE 'PAUSE'		:fnAddToQueue('B',"$00")
					CASE 'SKIP+'		:fnAddToQueue('C','+')
					CASE 'SKIP-'		:fnAddToQueue('C','-')
					CASE 'FASTFORWARD':fnAddToQueue('D','+')
					CASE 'REWIND'		:fnAddToQueue('D','-')
					CASE 'LEFT'			:fnAddToQueue('M','1')
					CASE 'RIGHT'		:fnAddToQueue('M','3')
					CASE 'UP'			:fnAddToQueue('M','2')
					CASE 'DOWN'			:fnAddToQueue('M','4')
					CASE 'SELECT'		:fnAddToQueue('N',"$00")
					CASE 'RED'			:fnAddToQueue('r','1')
					CASE 'GREEN'		:fnAddToQueue('r','2')
					CASE 'BLUE'			:fnAddToQueue('r','3')
					CASE 'YELLOW'		:fnAddToQueue('r','4')
					CASE 'SETUP'		:fnAddToQueue('E',"$00")
					CASE 'TOP MENU'	:fnAddToQueue('F',"$00")
					CASE 'MENU'			:fnAddToQueue('G',"$00")
					CASE 'POPUP MENU'	:fnAddToQueue('t',"$00")
					CASE 'RETURN'		:fnAddToQueue('H',"$00")
					CASE 'MODE'			:fnAddToQueue('t',"$00")
					CASE 'DISPLAY'		:fnAddToQueue('h',"$00")
				}
				fnPoll()
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myDenonBR.POWER)
}
/******************************************************************************
	EoF
******************************************************************************/