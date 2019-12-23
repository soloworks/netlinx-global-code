MODULE_NAME='mExtronMatrix'(DEV vdvControl[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Extron Matrix Module - RMS Enabled

	For DSP enabled matrix under simple output gain control
	uses virtual DSP channels 1+ as gain & mute point
******************************************************************************/
DEFINE_TYPE STRUCTURE uAudio{
	INTEGER MUTE
	INTEGER GAIN
	INTEGER GAIN_PEND
	SINTEGER LAST_GAIN
}
DEFINE_TYPE STRUCTURE uMatrix{
	// Communications
	//CHAR 		RX[2000]			// Receieve Buffer
	INTEGER 	IP_PORT				//
	CHAR		IP_HOST[255]		//
	INTEGER 	IP_STATE				//
	INTEGER	isIP
	CHAR     PASSWORD[20]

	INTEGER DEBUG					// Debuging ON/OFF
	INTEGER DISABLED				// Disable Module
	CHAR	  Tx[1000]				// Transmission Buffer
	CHAR	  LAST_SENT[100]		// Last sent message for feedback handling
	INTEGER MODEL_ID				// Internal Model Constant
	INTEGER VID_MTX_SIZE[2]		// INPUT.OUTPUT count of video matrix
	INTEGER AUD_MTX_SIZE[2]		// INPUT.OUTPUT count of Audio matrix
	// MetaData
	CHAR META_FIRMWARE[20]		// Firmware Shorthand
	CHAR META_FIRMWARE_FULL[20]// Firmware Longhand
	CHAR META_PART_NUMBER[20]	// Part Number
	CHAR META_MODEL[20]			// Extron Model (Programatically Set based on PN)
	CHAR META_MAC[20]				// MAC Address (If Applicable)
	CHAR META_IP[20]				// IP Address (If Applicable)
	INTEGER HAS_NETWORK			// Does this switch have a network interface
	INTEGER HAS_AUDIO				// Does this switch have audio
	// State
	CHAR DIAG_INT_TEMP[20]		// Internal Temperature
	uAudio	AUDIO[8]
	INTEGER SIGNAL_PRESENT[16]		// Is a signal present on the input
}

DEFINE_CONSTANT
LONG TLID_COMMS 	 = 11
LONG TLID_POLL	 	 = 12
LONG TLID_SEND		 = 13
LONG TLID_RETRY	 = 15

LONG TLID_GAIN_00	 = 20
LONG TLID_GAIN_01	 = 21
LONG TLID_GAIN_02	 = 22
LONG TLID_GAIN_03	 = 23
LONG TLID_GAIN_04	 = 24
LONG TLID_GAIN_05	 = 25
LONG TLID_GAIN_06	 = 26
LONG TLID_GAIN_07	 = 27
LONG TLID_GAIN_08	 = 28
LONG TLID_GAIN_09	 = 29
LONG TLID_GAIN_10	 = 30
LONG TLID_GAIN_11	 = 31
LONG TLID_GAIN_12	 = 32
LONG TLID_GAIN_13	 = 33
LONG TLID_GAIN_14	 = 34
LONG TLID_GAIN_15	 = 35
LONG TLID_GAIN_16	 = 36

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

INTEGER MODEL_DXP44HD4K			= 01
INTEGER MODEL_DXP84HD4K			= 02
INTEGER MODEL_DXP88HD4K			= 03
INTEGER MODEL_DXP168HD4K		= 04
INTEGER MODEL_DXP1616HD4K		= 05
INTEGER MODEL_DTPCP844K			= 06
INTEGER MODEL_CROSSPOINT		= 07
INTEGER MODEL_DTPCP1084K    = 08
INTEGER MODEL_DTPCP864K     = 09
INTEGER MODEL_DTPCP824K     = 10

DEFINE_VARIABLE
LONG TLT_COMMS[] 	= { 90000 }
LONG TLT_POLL[]  	= {  2000 }
LONG TLT_SEND[]	= {  2000 }
LONG TLT_GAIN[]	= {   150 }
LONG TLT_RETRY[]	= {  5000 }
VOLATILE uMatrix myMatrix
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myMatrix.isIP = !(dvDEVICE.NUMBER)
	//CREATE_BUFFER dvDevice, myMatrix.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myMatrix.IP_HOST == ''){
		fnDebug(TRUE,'Extron IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Extron on ',"myMatrix.IP_HOST,':',ITOA(myMatrix.IP_PORT)")
		myMatrix.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myMatrix.IP_HOST, myMatrix.IP_PORT, IP_TCP)
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

DEFINE_FUNCTION fnDebug(INTEGER FORCE,CHAR Msg[], CHAR MsgData[]){
	 IF(myMatrix.DEBUG || FORCE){
		SEND_STRING 0:0:0, "ITOA(vdvControl[1].Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[255]){
	myMatrix.Tx = "myMatrix.Tx,pToSend,$FF"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && LENGTH_ARRAY(myMatrix.Tx) && myMatrix.IP_STATE == IP_STATE_CONNECTED){
		myMatrix.LAST_SENT = fnStripCharsRight(REMOVE_STRING(myMatrix.Tx,"$FF",1),1)
		fnDebug(FALSE,'AMX->Extron', myMatrix.LAST_SENT);
		SEND_STRING dvDevice,myMatrix.LAST_SENT
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	myMatrix.LAST_SENT = ''
	myMatrix.Tx = ''
}

DEFINE_FUNCTION fnInitPoll(){
	IF(!myMatrix.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{

	SWITCH(myMatrix.MODEL_ID){
		CASE MODEL_CROSSPOINT:	{}							// Do Nothing
		DEFAULT:						fnAddToQueue('0LS')	// Input Detected
	}

	IF(TIMELINE.REPETITION == 15){
		fnPoll()
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnPoll(){
	IF(!LENGTH_ARRAY(myMatrix.META_PART_NUMBER)){
		fnAddToQueue('N')
		fnAddToQueue('Q')
		fnAddToQueue('*Q')
		fnAddToQueue('I')
	}
	ELSE IF(myMatrix.HAS_NETWORK && !LENGTH_ARRAY(myMatrix.META_MAC)){
		fnAddToQueue("$1B,'CH',$0D")
	}
	ELSE{
		SWITCH(myMatrix.MODEL_ID){
			CASE MODEL_CROSSPOINT:	fnAddToQueue('I')
			DEFAULT:						fnAddToQueue('S')		// Status
		}

		IF(myMatrix.HAS_NETWORK){
			fnAddToQueue("$1B,'CI',$0D")
		}
		IF(myMatrix.HAS_AUDIO){
			STACK_VAR INTEGER x
			FOR(x = 1; x <= myMatrix.AUD_MTX_SIZE[2]; x++){
				SWITCH(myMatrix.MODEL_ID){
					CASE MODEL_DTPCP824K:{
						fnAddToQueue("$1B,'G',ITOA(50100+x-1),'AU',$0D")
					}
					DEFAULT:{
						fnAddToQueue("ITOA(x),'V'")
						fnAddToQueue("ITOA(x),'Z'")
					}
				}
			}
		}
	}
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myMatrix.IP_STATE	= IP_STATE_CONNECTED
		IF(!myMatrix.isIP){
		   SEND_COMMAND dvDevice, 'SET MODE DATA'
		   SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		   SEND_COMMAND dvDevice, 'SET FAULT DETECT OFF'
		}
		WAIT 10{
			// Set Verbose Mode
			#WARN 'Implement with Tagged Responses & Verbose = 3'
			//fnAddToQueue("$1B,'3CV',$0D")
			fnAddToQueue('I')
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		IF(myMatrix.isIP){
			myMatrix.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myMatrix.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myMatrix.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'Extron IP Error:[',myMatrix.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myMatrix.DISABLED){
			fnDebug(FALSE,'Extron->AMX', DATA.TEXT);
			SELECT{
				ACTIVE(DATA.TEXT == "$0D,$0A,'Password:'"):{
					SEND_STRING dvDevice,"myMatrix.PASSWORD,$0D"
				}
				ACTIVE(myMatrix.LAST_SENT == '0LS'):{
					STACK_VAR INTEGER x
					STACK_VAR CHAR States[16]
					States = fnStripCharsRight(DATA.TEXT,2)
					IF(!myMatrix.VID_MTX_SIZE[1]){
						fnAddToQueue('I')
					}
					ELSE{
						FOR(x = 1; x <= myMatrix.VID_MTX_SIZE[1]; x++){
							myMatrix.SIGNAL_PRESENT[x] = ATOI("States[x]")
							[vdvControl[1],x] = (myMatrix.SIGNAL_PRESENT[x])
							fnDebug(FALSE,'ACTIVE SOURCE FEEDBACK: ', "'[vdvControl[1],',ITOA(x),'] = (',ITOA(myMatrix.SIGNAL_PRESENT[x]),')'")
						}
					}
				}
				ACTIVE(myMatrix.LAST_SENT == 'N'):{
					myMatrix.META_PART_NUMBER = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(myMatrix.META_PART_NUMBER,3) == 'Pno'){
						GET_BUFFER_STRING(myMatrix.META_PART_NUMBER,3)
					}
					IF(LEFT_STRING(myMatrix.META_PART_NUMBER,1) == 'N'){
						GET_BUFFER_STRING(myMatrix.META_PART_NUMBER,1)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,TYPE,VideoMatrix'"
					SEND_STRING vdvControl,"'PROPERTY-META,MAKE,Extron'"
					SEND_STRING vdvControl,"'PROPERTY-META,PART,',myMatrix.META_PART_NUMBER"
					SWITCH(myMatrix.META_PART_NUMBER){
						CASE '60-1493-01':myMatrix.MODEL_ID = MODEL_DXP44HD4K
						CASE '60-1494-01':myMatrix.MODEL_ID = MODEL_DXP84HD4k
						CASE '60-1495-01':myMatrix.MODEL_ID = MODEL_DXP88HD4k
						CASE '60-1496-01':myMatrix.MODEL_ID = MODEL_DXP168HD4K
						CASE '60-1497-01':myMatrix.MODEL_ID = MODEL_DXP1616HD4K
						CASE '60-220-06': myMatrix.MODEL_ID = MODEL_CROSSPOINT
						CASE '60-1515-01':myMatrix.MODEL_ID = MODEL_DTPCP844K
						CASE '60-1381-01':myMatrix.MODEL_ID = MODEL_DTPCP1084K
						CASE '60-1382-01':myMatrix.MODEL_ID = MODEL_DTPCP864K
						CASE '60-1583-01':myMatrix.MODEL_ID = MODEL_DTPCP824K
					}
					SWITCH(myMatrix.MODEL_ID){
						CASE MODEL_DXP44HD4K:	myMatrix.META_MODEL = 'DXP44HD4K'
						CASE MODEL_DXP84HD4k:	myMatrix.META_MODEL = 'DXP84HD4K'
						CASE MODEL_DXP88HD4k:	myMatrix.META_MODEL = 'DXP88HD4K'
						CASE MODEL_DXP168HD4K:	myMatrix.META_MODEL = 'DXP168HD4K'
						CASE MODEL_DXP1616HD4K:	myMatrix.META_MODEL = 'DXP1616HD4K'
						CASE MODEL_CROSSPOINT:	myMatrix.META_MODEL = 'CROSSPOINT'
						CASE MODEL_DTPCP844K:	myMatrix.META_MODEL = 'DTPCP844K'
						CASE MODEL_DTPCP1084K:	myMatrix.META_MODEL = 'DTPCP1084K'
						CASE MODEL_DTPCP864K:	myMatrix.META_MODEL = 'DTPCP864K'
						CASE MODEL_DTPCP824K:	myMatrix.META_MODEL = 'DTPCP824K'
						DEFAULT:						myMatrix.META_MODEL = 'NOT IMPLEMENTED'
					}
					SWITCH(myMatrix.MODEL_ID){
						CASE MODEL_DXP44HD4K:
						CASE MODEL_DXP84HD4k:
						CASE MODEL_DXP88HD4k:
						CASE MODEL_DXP168HD4K:
						CASE MODEL_DXP1616HD4K:
						CASE MODEL_DTPCP844K:
						CASE MODEL_DTPCP1084K:
						CASE MODEL_DTPCP864K:
						CASE MODEL_DTPCP824K:	myMatrix.HAS_NETWORK = TRUE
						DEFAULT:				  		myMatrix.HAS_NETWORK = FALSE

					}
					SWITCH(myMatrix.MODEL_ID){
						CASE MODEL_DXP44HD4K:
						CASE MODEL_DXP84HD4k:
						CASE MODEL_DXP88HD4k:
						CASE MODEL_DXP168HD4K:
						CASE MODEL_DXP1616HD4K:
						CASE MODEL_DTPCP1084K:
						CASE MODEL_DTPCP864K:
						CASE MODEL_DTPCP824K:
						CASE MODEL_DTPCP844K:	myMatrix.HAS_AUDIO = TRUE
						DEFAULT:						myMatrix.HAS_AUDIO = FALSE
					}
					SWITCH(myMatrix.MODEL_ID){
						CASE MODEL_DTPCP824K:	SEND_STRING vdvControl, 'RANGE--100,12'
						DEFAULT:						SEND_STRING vdvControl, 'RANGE-0,100'
					}
					SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myMatrix.META_MODEL"
					IF(!myMatrix.HAS_NETWORK){
						SEND_STRING vdvControl,"'PROPERTY-META,NET_MAC,N/A'"
						SEND_STRING vdvControl,"'PROPERTY-STATE,NET_IP,N/A'"
					}
					fnPoll()
				}
				ACTIVE(myMatrix.LAST_SENT == 'Q'):{
					myMatrix.META_FIRMWARE = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(myMatrix.META_FIRMWARE,3) == 'Ver'){
						GET_BUFFER_STRING(myMatrix.META_FIRMWARE,3)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,FW1,',myMatrix.META_FIRMWARE"
				}
				ACTIVE(myMatrix.LAST_SENT == 'I'):{
					IF(FIND_STRING(DATA.TEXT,'DTPCP',1)){
						REMOVE_STRING(DATA.TEXT,'DTPCP',1)
						SWITCH(fnStripCharsRight(DATA.TEXT,2)){
							CASE '108':{
								myMatrix.VID_MTX_SIZE[1] = 10
								myMatrix.VID_MTX_SIZE[2] = 8
								myMatrix.AUD_MTX_SIZE[1] = 10
								myMatrix.AUD_MTX_SIZE[2] = 8
							}
							CASE '86':{
								myMatrix.VID_MTX_SIZE[1] = 8
								myMatrix.VID_MTX_SIZE[2] = 6
								myMatrix.AUD_MTX_SIZE[1] = 8
								myMatrix.AUD_MTX_SIZE[2] = 6
							}
						}
					}
					ELSE{
						GET_BUFFER_CHAR(DATA.TEXT)	// REMOVE 'V'
						myMatrix.VID_MTX_SIZE[1] = ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
						GET_BUFFER_CHAR(DATA.TEXT)	// REMOVE 'X'
						myMatrix.VID_MTX_SIZE[2] = ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
						GET_BUFFER_CHAR(DATA.TEXT)	// REMOVE ' '
						GET_BUFFER_CHAR(DATA.TEXT)	// REMOVE 'A'
						myMatrix.AUD_MTX_SIZE[1] = ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
						GET_BUFFER_CHAR(DATA.TEXT)	// REMOVE 'X'
						myMatrix.AUD_MTX_SIZE[2] = ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
					}
				}
				ACTIVE(myMatrix.LAST_SENT == 'S'):{
					// System Status Poll
				}
				ACTIVE(myMatrix.LAST_SENT[2] == 'V'):{
					myMatrix.AUDIO[ATOI("myMatrix.LAST_SENT[1]")].GAIN = ATOI(DATA.TEXT)
				}
				ACTIVE(myMatrix.LAST_SENT[2] == 'Z'):{
					myMatrix.AUDIO[ATOI("myMatrix.LAST_SENT[1]")].MUTE = ATOI("DATA.TEXT[1]")
				}
				ACTIVE(myMatrix.LAST_SENT == '*Q'):{
					myMatrix.META_FIRMWARE_FULL = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(myMatrix.META_FIRMWARE_FULL,3) == 'Bld'){
						GET_BUFFER_STRING(myMatrix.META_FIRMWARE_FULL,3)
					}
					IF(LEFT_STRING(myMatrix.META_FIRMWARE_FULL,6) == 'Ver*0 '){
						GET_BUFFER_STRING(myMatrix.META_FIRMWARE_FULL,6)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,FW2,',myMatrix.META_FIRMWARE_FULL"
				}
				ACTIVE(myMatrix.LAST_SENT == "$1B,'CH',$0D"):{
					myMatrix.META_MAC = fnStripCharsRight(DATA.TEXT,2)
					SEND_STRING vdvControl,"'PROPERTY-META,NET_MAC,',myMatrix.META_MAC"
					fnPoll()
				}
				ACTIVE(myMatrix.LAST_SENT == "$1B,'CI',$0D"):{
					IF(myMatrix.META_IP != fnStripCharsRight(DATA.TEXT,2)){
						myMatrix.META_IP = fnStripCharsRight(DATA.TEXT,2)
						SEND_STRING vdvControl,"'PROPERTY-STATE,NET_IP,',myMatrix.META_IP"
					}
				}
				ACTIVE(1):{	// Referenced Notifications
					SEND_COMMAND 0, "'ref==',DATA.TEXT"
					SELECT{
						ACTIVE(FIND_STRING(DATA.TEXT,'Vol',1)):{
							STACK_VAR INTEGER OUTPUT
							GET_BUFFER_STRING(DATA.TEXT,3)	// Remove 'Out'
							OUTPUT = ATOI(REMOVE_STRING(DATA.TEXT,' ',1))
							GET_BUFFER_STRING(DATA.TEXT,3)	// Remove 'Vol'
							myMatrix.AUDIO[OUTPUT].GAIN = ATOI(DATA.TEXT)
						}
						ACTIVE(LEFT_STRING(DATA.TEXT,3) == 'Amt'):{
							GET_BUFFER_STRING(DATA.TEXT,3)
							//myMatrix.MUTE = ATOI(DATA.TEXT)
						}
						ACTIVE(LEFT_STRING(DATA.TEXT,3) == 'DsG'):{
							STACK_VAR INTEGER o
							STACK_VAR CHAR v[10]
							//DsG50100*-730$0D$0A
							GET_BUFFER_STRING(DATA.TEXT,3)
							SEND_STRING 0, "'fb==',DATA.TEXT"
							o = ATOI(GET_BUFFER_STRING(DATA.TEXT,5))
							GET_BUFFER_CHAR(DATA.TEXT)
							v = DATA.TEXT
							SEND_STRING 0, "'v==',v"
							SET_LENGTH_ARRAY(v,LENGTH_ARRAY(v)-3)
							SEND_STRING 0, "'v==',v"
							SWITCH(o){
								CASE 50100:myMatrix.AUDIO[1].GAIN = ATOI(v)
								CASE 50200:myMatrix.AUDIO[2].GAIN = ATOI(v)
							}
							//myMatrix.MUTE = ATOI(DATA.TEXT)
						}
					}
				}
			}
			myMatrix.LAST_SENT = ''
			IF(TIMELINE_ACTIVE(TLID_SEND)){TIMELINE_KILL(TLID_SEND)}
			fnSendFromQueue()
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	STACK_VAR uAudio blankAudio
	STACK_VAR INTEGER x
	myMatrix.DIAG_INT_TEMP 		= ''
	myMatrix.HAS_AUDIO 			= FALSE
	myMatrix.HAS_NETWORK 		= FALSE
	myMatrix.LAST_SENT			= 0
	myMatrix.META_FIRMWARE		= ''
	myMatrix.META_FIRMWARE_FULL= ''
	myMatrix.META_IP				= ''
	myMatrix.META_MAC				= ''
	myMatrix.META_MODEL			= ''
	myMatrix.META_PART_NUMBER	= ''
	myMatrix.MODEL_ID 			= 0
	myMatrix.Tx 					= ''
	FOR(x = 1; x <= myMatrix.AUD_MTX_SIZE[2]; x++){
		myMatrix.AUDIO[x] = blankAudio
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
	}
	COMMAND:{// Enable / Disable Module
		SWITCH(DATA.TEXT){
			CASE 'PROPERTY-ENABLED,FALSE':myMatrix.DISABLED = TRUE
			CASE 'PROPERTY-ENABLED,TRUE': myMatrix.DISABLED = FALSE
		}
		IF(!myMatrix.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG': 		myMatrix.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
						CASE 'PASSWORD':  myMatrix.PASSWORD = DATA.TEXT
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myMatrix.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myMatrix.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myMatrix.IP_HOST = DATA.TEXT
								myMatrix.IP_PORT = 23
							}
							fnRetryConnection()
						}
					}
				}
				CASE 'AMATRIX': fnAddToQueue("DATA.TEXT,'$'")
				CASE 'VMATRIX': fnAddToQueue("DATA.TEXT,'%'")
				CASE 'MATRIX':  fnAddToQueue("DATA.TEXT,'!'")
				CASE 'INPUT':   fnAddToQueue("DATA.TEXT,'*',ITOA(GET_LAST(vdvControl)),'!'")
				CASE 'VOLUME':{
					// Get Output Number for ease
					STACK_VAR INTEGER pOUTPUT
					pOUTPUT = GET_LAST(vdvControl)
					// Only process if audio is on this model
					IF(myMatrix.HAS_AUDIO){
						SWITCH(DATA.TEXT){
							CASE 'INC':	fnAddToQueue("ITOA(pOUTPUT),'*+V'")
							CASE 'DEC':	fnAddToQueue("ITOA(pOUTPUT),'*-V'")
							DEFAULT:{
								SINTEGER VOL
								//VOL = -100
								//VOL = VOL + ATOI(DATA.TEXT)
								VOL = ATOI(DATA.TEXT)
								IF(!TIMELINE_ACTIVE(TLID_GAIN_00+pOUTPUT)){
									SWITCH(myMatrix.MODEL_ID){
										CASE MODEL_DTPCP824K:   fnAddToQueue("$1B,'G',ITOA(50100+pOUTPUT-1),'*',ITOA(VOL),'0AU',$0D")
										DEFAULT:						fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(VOL),'V'")
									}

									TIMELINE_CREATE(TLID_GAIN_00+pOUTPUT,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									myMatrix.AUDIO[pOUTPUT].LAST_GAIN = VOL
									myMatrix.AUDIO[pOUTPUT].GAIN_PEND = TRUE
								}
							}
						}
					}
				}
				CASE 'MUTE':{
					// Get Output Number for ease
					STACK_VAR INTEGER pOUTPUT
					pOUTPUT = GET_LAST(vdvControl)
					// Only process if audio is on this model
					IF(myMatrix.HAS_AUDIO){
						// Set Mute State Value (6 was original used
						SWITCH(DATA.TEXT){
							CASE 'ON':		myMatrix.AUDIO[pOUTPUT].MUTE = 6
							CASE 'OFF':		myMatrix.AUDIO[pOUTPUT].MUTE = 0
							CASE 'TOGGLE':{
								SWITCH(myMatrix.AUDIO[pOUTPUT].MUTE){
									CASE 0:	myMatrix.AUDIO[pOUTPUT].MUTE = 6
									DEFAULT:	myMatrix.AUDIO[pOUTPUT].MUTE = 0
								}
							}
						}
						// Correct Mute State Value for
						SWITCH(myMatrix.MODEL_ID){
							CASE MODEL_DTPCP824K:{
								IF(myMatrix.AUDIO[pOUTPUT].MUTE == 6){
									myMatrix.AUDIO[pOUTPUT].MUTE = 1
								}
							}
						}
						SWITCH(myMatrix.MODEL_ID){
							CASE MODEL_DTPCP824K:	fnAddToQueue("$1B,'M',ITOA(50100+pOUTPUT-1),'*',ITOA(myMatrix.AUDIO[pOUTPUT].MUTE),'AU',$0D")
							DEFAULT:						fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(myMatrix.AUDIO[pOUTPUT].MUTE),'Z'")
						}
					}
				}
				CASE 'RAW':{
					fnAddToQueue(DATA.TEXT)
				}
				CASE 'RAW2':{
					fnAddToQueue("$1B,DATA.TEXT,$0D")
				}
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_GAIN_01]
TIMELINE_EVENT[TLID_GAIN_02]
TIMELINE_EVENT[TLID_GAIN_03]
TIMELINE_EVENT[TLID_GAIN_04]
TIMELINE_EVENT[TLID_GAIN_05]
TIMELINE_EVENT[TLID_GAIN_06]
TIMELINE_EVENT[TLID_GAIN_07]
TIMELINE_EVENT[TLID_GAIN_08]
TIMELINE_EVENT[TLID_GAIN_09]
TIMELINE_EVENT[TLID_GAIN_10]
TIMELINE_EVENT[TLID_GAIN_11]
TIMELINE_EVENT[TLID_GAIN_12]
TIMELINE_EVENT[TLID_GAIN_13]
TIMELINE_EVENT[TLID_GAIN_14]
TIMELINE_EVENT[TLID_GAIN_15]
TIMELINE_EVENT[TLID_GAIN_16]{
	STACK_VAR INTEGER pOUTPUT
	pOUTPUT = TIMELINE.ID-TLID_GAIN_00
	IF(myMatrix.AUDIO[pOUTPUT].GAIN_PEND){
		SWITCH(myMatrix.MODEL_ID){
			CASE MODEL_DTPCP824K:   fnAddToQueue("$1B,'G',ITOA(50100+pOUTPUT-1),'*',ITOA(myMatrix.AUDIO[pOUTPUT].LAST_GAIN),'0AU',$0D")
			DEFAULT:						fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(myMatrix.AUDIO[pOUTPUT].LAST_GAIN),'V'")
		}
		myMatrix.AUDIO[pOUTPUT].LAST_GAIN = 0
		myMatrix.AUDIO[pOUTPUT].GAIN_PEND = FALSE
		TIMELINE_CREATE(TLID_GAIN_00+pOUTPUT,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_PROGRAM{
	IF(!myMatrix.DISABLED){
		STACK_VAR INTEGER x
		IF(myMatrix.HAS_AUDIO){
			FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
				[vdvControl[x],199] = (myMatrix.AUDIO[x].MUTE)
				SEND_LEVEL vdvControl[x],1,myMatrix.AUDIO[x].GAIN
			}
		}
		/* Now done on the receipt of the feedback from device
		// Signal Detection
		FOR(x = 1; x <= myMatrix.VID_MTX_SIZE[1]; x++){
			[vdvControl[1],x] = (myMatrix.SIGNAL_PRESENT[x])
			SEND_STRING 0, "'[vdvControl[1],',ITOA(x),'] = (',ITOA(myMatrix.SIGNAL_PRESENT[x]),')'"
		}
		*/
		[vdvControl[1],251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl[1],252] = (TIMELINE_ACTIVE(TLID_COMMS))
	}
}