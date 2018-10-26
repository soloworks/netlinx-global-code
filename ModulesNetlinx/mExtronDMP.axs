MODULE_NAME='mExtronDMP'(DEV vdvControl,DEV vdvObjects[],DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Extron DMP 64/128
******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uObject{
	INTEGER 	TYPE				// Internal Constant dictating Type
	INTEGER 	ADDRESS			// Address of this Object
	SINTEGER MUTE_VALUE		// Current Value (Raw)
	SINTEGER GAIN_VALUE		// Current Value (Raw)
	SINTEGER LIMITS[2]		// Object Limits (Raw)
	FLOAT		GAIN_VALUE_dB			// Current Value (dB)
	FLOAT		LIMITS_dB[2]	// Object Limits (dB)
	INTEGER	GAIN_VALUE_255		// Current Value (0-255)
	INTEGER  STEP				// DB Step for Inc/Dec
	INTEGER 	NEW_GAIN_PEND	// Is new Gain value Pending?
	CHAR  	NEW_GAIN_VALUE[10]	// New gain value
}

DEFINE_TYPE STRUCTURE uDMP{
	// Communications
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	isIP
	INTEGER  DEBUG					// Debuging ON/OFF
	CHAR	   LAST_SENT[100]		// Last sent message for feedback handling
	CHAR	   Tx[1000]				// Transmission Buffer

	CHAR 		META_FIRMWARE[20]		// Firmware Shorthand
	CHAR 		META_PART_NUMBER[20]	// Part Number
	CHAR 		META_MODEL[20]			// Extron Model (Programatically Set based on PN)

	CHAR 	   Rx[500]

	uObject  OBJECTS[10]
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_COMMS	= 2
LONG TLID_SEND		= 3
LONG TLID_GAIN	 	= 4
LONG TLID_RETRY	= 5

LONG TLID_VOL_00	= 100
LONG TLID_VOL_01	= 101
LONG TLID_VOL_02	= 102
LONG TLID_VOL_03	= 103
LONG TLID_VOL_04	= 104
LONG TLID_VOL_05	= 105
LONG TLID_VOL_06	= 106
LONG TLID_VOL_07	= 107
LONG TLID_VOL_08	= 108
LONG TLID_VOL_09	= 109
LONG TLID_VOL_10	= 110
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

INTEGER OBJ_TYPE_GROUP = 1
INTEGER OBJ_TYPE_FADER = 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

DEFINE_VARIABLE
LONG TLT_COMMS[] 			= { 90000 }
LONG TLT_POLL[] 			= { 30000 }
LONG TLT_SEND[]			= {  2000 }
LONG TLT_GAIN[]			= {   150 }
LONG TLT_RETRY[]			= {  5000 }
LONG TLT_VOL[]				= {   200 }
VOLATILE uDMP   myDMP
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	// Set Device Comms Type
	myDMP.isIP = !(dvDEVICE.NUMBER)
	// Create RX Buffer
	CREATE_BUFFER dvDevice,myDMP.Rx
}
/******************************************************************************
	Connection Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myDMP.IP_HOST == ''){
		fnDebug(TRUE,'DMP IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to DMP on ',"myDMP.IP_HOST,':',ITOA(myDMP.IP_PORT)")
		myDMP.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myDMP.IP_HOST, myDMP.IP_PORT, IP_TCP)
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
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR pMSG[], CHAR pDATA[]){
	IF(myDMP.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMSG, ':', pDATA"
	}
}
DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[255], INTEGER isQuery){
	myDMP.Tx = "myDMP.Tx,pToSend,$FF"
	fnSendFromQueue()
	IF(!isQuery){
		fnInitPoll()
	}
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && LENGTH_ARRAY(myDMP.Tx)){
		myDMP.LAST_SENT = fnStripCharsRight(REMOVE_STRING(myDMP.Tx,"$FF",1),1)
		SEND_STRING dvDevice,myDMP.LAST_SENT
		fnDebug(DEBUG_STD,'->DMP', myDMP.LAST_SENT);
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	myDMP.LAST_SENT = ''
	myDMP.Tx = ''
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('N',TRUE)	// Part Number
	fnAddToQueue('Q',TRUE)	// Firmware Version
}
/******************************************************************************
	Helper Conversion Functions
******************************************************************************/
DEFINE_FUNCTION SINTEGER fnDB2SIS(FLOAT pDB){
	RETURN ATOI(FTOA((pDB*10)+2048))
}
DEFINE_FUNCTION FLOAT fnSIS2DB(SINTEGER pSIS){
	STACK_VAR FLOAT RetValue
	RetValue = pSIS - TYPE_CAST(2048)

	RETURN RetValue / 10
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myDMP.IP_STATE	= IP_STATE_CONNECTED
		IF(!myDMP.isIP){
		   SEND_COMMAND dvDevice, 'SET MODE DATA'
		   SEND_COMMAND dvDevice, 'SET BAUD 38400 N 8 1 485 DISABLE'
		   SEND_COMMAND dvDevice, 'SET FAULT DETECT OFF'
		}
		// Set Verbose mode for full responses
		fnAddToQueue("$1B,'3CV',$0D",FALSE)
		IF(1){
			STACK_VAR INTEGER o
			FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
				SWITCH(myDMP.OBJECTS[o].TYPE){
					CASE OBJ_TYPE_FADER:{
						fnAddToQueue("$1B,'G',ITOA(myDMP.OBJECTS[o].ADDRESS),'AU',$0D",TRUE)
						fnAddToQueue("$1B,'M',ITOA(myDMP.OBJECTS[o].ADDRESS),'AU',$0D",TRUE)
					}
				}
			}
		}
		// Do First Poll
		fnPoll()
		// Initialise Poll
		fnInitPoll()
	}
	OFFLINE:{
		IF(myDMP.isIP){
			myDMP.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myDMP.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myDMP.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'Extron IP Error:[',myDMP.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}

	STRING:{
		// Debug Out
		fnDebug(DEBUG_STD,'DMP->', DATA.TEXT);

		// Work through feedback
		WHILE(FIND_STRING(myDMP.Rx,"$0D,$0A",1)){
			STACK_VAR CHAR pFB[200]
			pFB = fnStripCharsRight(REMOVE_STRING(myDMP.Rx,"$0D,$0A",1),2)
			fnDebug(DEBUG_DEV,'pFB=', pFB);

			SELECT{

				// Part Number Requested
				ACTIVE(LEFT_STRING(pFB,3) == 'Pno'):{
					IF(myDMP.META_PART_NUMBER == ''){
						GET_BUFFER_STRING(pFB,3)
						myDMP.META_PART_NUMBER = pFB
						SEND_STRING vdvControl,"'PROPERTY-META,MAKE,Extron'"
						SEND_STRING vdvControl,"'PROPERTY-META,PART,',myDMP.META_PART_NUMBER"
					}
				}

				// Firmware Requested
				ACTIVE(LEFT_STRING(pFB,3) == 'Ver'):{
					IF(myDMP.META_FIRMWARE == ''){
						GET_BUFFER_STRING(pFB,3)
						myDMP.META_FIRMWARE = pFB
						SEND_STRING vdvControl,"'PROPERTY-META,FW1,',myDMP.META_FIRMWARE"
					}
				}

				// Change in Fader Value
				ACTIVE(LEFT_STRING(pFB,3) == 'DsG'):{
					STACK_VAR INTEGER o
					STACK_VAR INTEGER ADDRESS
					GET_BUFFER_STRING(pFB,3)
					ADDRESS = ATOI(fnStripCharsRight(REMOVE_STRING(pFB,'*',1),1))
					FOR(o=1; o<= LENGTH_ARRAY(vdvObjects); o++){
						IF(myDMP.OBJECTS[o].ADDRESS == ADDRESS){
							myDMP.OBJECTS[o].GAIN_VALUE = ATOI(pFB)
							myDMP.OBJECTS[o].GAIN_VALUE_dB = fnSIS2DB(myDMP.OBJECTS[o].GAIN_VALUE)
						}
					}
				}

				// Change in Mute Value
				ACTIVE(LEFT_STRING(pFB,3) == 'DsM'):{
					STACK_VAR INTEGER o
					STACK_VAR INTEGER ADDRESS
					GET_BUFFER_STRING(pFB,3)
					ADDRESS = ATOI(fnStripCharsRight(REMOVE_STRING(pFB,'*',1),1))
					FOR(o=1; o<= LENGTH_ARRAY(vdvObjects); o++){
						IF(myDMP.OBJECTS[o].ADDRESS == ADDRESS){
							myDMP.OBJECTS[o].MUTE_VALUE = ATOI(pFB)
						}
					}
				}

			}

			myDMP.LAST_SENT = ''
			IF(TIMELINE_ACTIVE(TLID_SEND)){TIMELINE_KILL(TLID_SEND)}
			fnSendFromQueue()
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

/******************************************************************************
	Main DSP Unit Device Feedback
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': myDMP.DEBUG = DEBUG_STD
							CASE 'DEV':  myDMP.DEBUG = DEBUG_DEV
							DEFAULT: 	 myDMP.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myDMP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myDMP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myDMP.IP_HOST = DATA.TEXT
							myDMP.IP_PORT = 23
						}
						IF(myDMP.isIP){
							fnRetryConnection()
						}
					}
				}
			}
			CASE 'PRESET':{
				fnAddToQueue("ITOA(ATOI(DATA.TEXT)),'.'",FALSE)
			}
		}
	}
}
/******************************************************************************
	Object Device Feedback
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvObjects]{
	COMMAND:{
		STACK_VAR INTEGER o
		o = GET_LAST(vdvObjects)

		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': 		myDMP.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'ID':{
						// Pull Object Type
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'GROUP': myDMP.OBJECTS[o].TYPE = OBJ_TYPE_GROUP
							CASE 'FADER': myDMP.OBJECTS[o].TYPE = OBJ_TYPE_FADER
						}

						// Set Address
						myDMP.OBJECTS[o].ADDRESS = ATOI(DATA.TEXT)

						// Set Default Step
						myDMP.OBJECTS[o].STEP = 3

						// Identifty Object Type
						SWITCH(myDMP.OBJECTS[o].TYPE){
							CASE OBJ_TYPE_GROUP:{
								// Request Limits
								fnAddToQueue("$1B,'L',FORMAT('%02d',myDMP.OBJECTS[o].ADDRESS),$0D",TRUE)
							}
							CASE OBJ_TYPE_FADER:{
								SELECT{
									ACTIVE(myDMP.OBJECTS[o].ADDRESS < 40100):{
										// Is a Input Gain Control
										myDMP.OBJECTS[o].LIMITS_dB[1] =  -18.0
										myDMP.OBJECTS[o].LIMITS_dB[2] =   80.0
									}
									ACTIVE(myDMP.OBJECTS[o].ADDRESS < 50000):{
										// Is a Pre-Mixer Gain
										myDMP.OBJECTS[o].LIMITS_dB[1] = -100.0
										myDMP.OBJECTS[o].LIMITS_dB[2] =   12.0
									}
									ACTIVE(myDMP.OBJECTS[o].ADDRESS < 60000):{
										// Is a Virtual Return Gain
										myDMP.OBJECTS[o].LIMITS_dB[1] = -100.0
										myDMP.OBJECTS[o].LIMITS_dB[2] =   12.0
									}
									ACTIVE(myDMP.OBJECTS[o].ADDRESS < 60100):{
										// Is a Volume Out Control
										myDMP.OBJECTS[o].LIMITS_dB[1] = -100.0
										myDMP.OBJECTS[o].LIMITS_dB[2] =    0.0
									}
									ACTIVE(myDMP.OBJECTS[o].ADDRESS < 70000):{
										// Is a Post Mixer Trim
										myDMP.OBJECTS[o].LIMITS_dB[1] =  -12.0
										myDMP.OBJECTS[o].LIMITS_dB[2] =   12.0
									}
								}

								// Set Ranges
								SEND_STRING DATA.DEVICE, "'RANGE-',ITOA(myDMP.OBJECTS[o].LIMITS_dB[1]),',',ITOA(myDMP.OBJECTS[o].LIMITS_dB[2]),''"

								// Set Normalised Limits
								myDMP.OBJECTS[o].LIMITS[1] = fnDB2SIS(myDMP.OBJECTS[o].LIMITS_dB[1])
								myDMP.OBJECTS[o].LIMITS[2] = fnDB2SIS(myDMP.OBJECTS[o].LIMITS_dB[2])
							}
						}
					}
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myDMP.OBJECTS[o].MUTE_VALUE = TRUE
					CASE 'OFF':		myDMP.OBJECTS[o].MUTE_VALUE = FALSE
					CASE 'TOGGLE':	myDMP.OBJECTS[o].MUTE_VALUE = !myDMP.OBJECTS[o].MUTE_VALUE
				}
				SWITCH(myDMP.OBJECTS[o].TYPE){
					CASE OBJ_TYPE_GROUP:fnAddToQueue("$1B,'D',FORMAT('%02d',myDMP.OBJECTS[o].ADDRESS),'*',ITOA(myDMP.OBJECTS[o].MUTE_VALUE),'GRPM',$0D",FALSE)
					CASE OBJ_TYPE_FADER:fnAddToQueue("$1B,'M',ITOA(myDMP.OBJECTS[o].ADDRESS),'*',ITOA(myDMP.OBJECTS[o].MUTE_VALUE),'AU',$0D",FALSE)
				}

			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':{
						SWITCH(myDMP.OBJECTS[o].TYPE){
							CASE OBJ_TYPE_GROUP:fnAddToQueue("$1B,'D',FORMAT('%02d',myDMP.OBJECTS[o].ADDRESS),'*',ITOA(myDMP.OBJECTS[o].STEP),'+GRPM',$0D",FALSE)
						}
					}
					CASE 'DEC':{
						SWITCH(myDMP.OBJECTS[o].TYPE){
							CASE OBJ_TYPE_GROUP:fnAddToQueue("$1B,'D',FORMAT('%02d',myDMP.OBJECTS[o].ADDRESS),'*',ITOA(myDMP.OBJECTS[o].STEP),'-GRPM',$0D",FALSE)
						}
					}
					DEFAULT:{
						myDMP.OBJECTS[o].NEW_GAIN_VALUE = "ITOA(fnDB2SIS(ATOI(DATA.TEXT))),'*'"
						IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
							SWITCH(myDMP.OBJECTS[o].TYPE){
								CASE OBJ_TYPE_GROUP:fnAddToQueue("$1B,'D',FORMAT('%02d',myDMP.OBJECTS[o].ADDRESS),'*',myDMP.OBJECTS[o].NEW_GAIN_VALUE,'GRPM',$0D",FALSE)
								CASE OBJ_TYPE_FADER:fnAddToQueue("$1B,'G',ITOA(myDMP.OBJECTS[o].ADDRESS),'*',myDMP.OBJECTS[o].NEW_GAIN_VALUE,'AU',$0D",FALSE)
							}
							TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myDMP.OBJECTS[o].NEW_GAIN_PEND = TRUE
						}
					}
				}
			}
		}
	}
}

/******************************************************************************
	Audio Handling
******************************************************************************/
DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL_01]
TIMELINE_EVENT[TLID_VOL_02]
TIMELINE_EVENT[TLID_VOL_03]
TIMELINE_EVENT[TLID_VOL_04]
TIMELINE_EVENT[TLID_VOL_05]
TIMELINE_EVENT[TLID_VOL_06]
TIMELINE_EVENT[TLID_VOL_07]
TIMELINE_EVENT[TLID_VOL_08]
TIMELINE_EVENT[TLID_VOL_09]
TIMELINE_EVENT[TLID_VOL_10]{
	STACK_VAR INTEGER o
	o = TIMELINE.ID - TLID_VOL_00
	IF(myDMP.OBJECTS[o].NEW_GAIN_PEND){
		SWITCH(myDMP.OBJECTS[o].TYPE){
			CASE OBJ_TYPE_GROUP:fnAddToQueue("$1B,'D',ITOA(myDMP.OBJECTS[o].ADDRESS),'*',myDMP.OBJECTS[o].NEW_GAIN_VALUE,'GRPM',$0D",FALSE)
			CASE OBJ_TYPE_FADER:fnAddToQueue("$1B,'G',ITOA(myDMP.OBJECTS[o].ADDRESS),'*',myDMP.OBJECTS[o].NEW_GAIN_VALUE,'AU',$0D",FALSE)
		}
		myDMP.OBJECTS[o].NEW_GAIN_VALUE = ''
		myDMP.OBJECTS[o].NEW_GAIN_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{

	STACK_VAR INTEGER o
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		SWITCH(myDMP.OBJECTS[o].TYPE){
			CASE OBJ_TYPE_GROUP:
			CASE OBJ_TYPE_FADER:{
				SEND_LEVEL vdvObjects[o],1,ATOI(FTOA(myDMP.OBJECTS[o].GAIN_VALUE_dB))
				SEND_LEVEL vdvObjects[o],3,myDMP.OBJECTS[o].GAIN_VALUE_255
				[vdvObjects[o],199] = myDMP.OBJECTS[o].MUTE_VALUE
			}
		}
	}

	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}

DEFINE_EVENT CHANNEL_EVENT[vdvObjects,199]{
	ON:{}
	OFF:{}
}

/******************************************************************************
	EoF
******************************************************************************/