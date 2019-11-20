MODULE_NAME='mExtronSMP'(DEV vdvControl,DEV tp[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron SMP Module - RMS Enabled
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uSMP{
	// Communications
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	isIP

	INTEGER	DEBUG					// Debuging ON/OFF
	CHAR		Rx[2000]						// Receieve Buffer
	CHAR		Tx[1000]				// Transmission Buffer
	CHAR	  	LAST_SENT[100]		// Last sent message for feedback handling
	INTEGER 	MODEL_ID				// Internal Model Constant
	// MetaData
	CHAR		META_FIRMWARE[20]		// Firmware Shorthand
	CHAR		META_FIRMWARE_FULL[20]// Firmware Longhand
	CHAR		META_PART_NUMBER[20]	// Part Number
	CHAR		META_MODEL[20]			// Extron Model (Programatically Set based on PN)
	CHAR		META_MAC[20]				// MAC Address (If Applicable)
	CHAR		META_IP[20]				// IP Address (If Applicable)
	// State
	INTEGER	RECORD_STATUS		// Internal Temperature

}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_SEND		= 3
LONG TLID_RETRY	= 4

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

INTEGER MODEL_SMP351			= 1
INTEGER MODEL_SMP351_3GSDI	= 2
INTEGER MODEL_SMP352			= 3
INTEGER MODEL_SMP352_3GSDI	= 4

INTEGER RECORD_STATUS_STOPPED 	= 0
INTEGER RECORD_STATUS_PAUSED		= 2
INTEGER RECORD_STATUS_RECORDING 	= 1
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 			= {90000}
LONG TLT_POLL[] 			= {5000}
LONG TLT_SEND[]			= {2000}
LONG TLT_GAIN[]			= {150}
LONG TLT_RETRY[]			= {   5000 }
VOLATILE uSMP mySMP
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	mySMP.isIP = !(dvDEVICE.NUMBER)
	//CREATE_BUFFER dvDevice, mySMP.RX
}

/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(mySMP.IP_HOST == ''){
		fnDebug(TRUE,'Extron IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Extron on ',"mySMP.IP_HOST,':',ITOA(mySMP.IP_PORT)")
		mySMP.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, mySMP.IP_HOST, mySMP.IP_PORT, IP_TCP)
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
	 IF(mySMP.DEBUG || FORCE){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[255], INTEGER isQuery){
	mySMP.Tx = "mySMP.Tx,pToSend,$FF"
	fnSendFromQueue()
	IF(!isQuery){
		fnInitPoll()
	}
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && LENGTH_ARRAY(mySMP.Tx)){
		mySMP.LAST_SENT = fnStripCharsRight(REMOVE_STRING(mySMP.Tx,"$FF",1),1)
		SEND_STRING dvDevice,mySMP.LAST_SENT
		fnDebug(FALSE,'->Extron', mySMP.LAST_SENT);
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	mySMP.LAST_SENT = ''
	mySMP.Tx = ''
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPollFull()
}

DEFINE_FUNCTION fnPollFull(){
	IF(!LENGTH_ARRAY(mySMP.META_PART_NUMBER)){
		fnAddToQueue('N',TRUE)		// Part Number
		fnAddToQueue('Q',TRUE)		// Firmware Version
		fnAddToQueue('*Q',TRUE)		// Full Firmware Version
		fnAddToQueue('99I',TRUE)	// Serial Number
		fnAddToQueue('98I',TRUE)	// MAC Address
	}
	ELSE{
		fnAddToQueue("$1B,'YRCDR',$0D",TRUE)	// Record Status
	}
}

/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		mySMP.IP_STATE	= IP_STATE_CONNECTED
		IF(!mySMP.isIP){
		   SEND_COMMAND dvDevice, 'SET MODE DATA'
		   SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		   SEND_COMMAND dvDevice, 'SET FAULT DETECT OFF'
		}
		WAIT 10{
			fnPollFull()
			fnInitPoll()
		}
	}
	OFFLINE:{
		IF(mySMP.isIP){
			mySMP.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(mySMP.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					mySMP.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'Extron IP Error:[',mySMP.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(FALSE,'Extron->', DATA.TEXT)
		IF(LEFT_STRING(DATA.TEXT,5) == "'RcdrY'"){
			mySMP.RECORD_STATUS = ATOI("DATA.TEXT[6]")
		}
		ELSE{
			SELECT{
				ACTIVE(mySMP.LAST_SENT == 'N'):{
					mySMP.META_PART_NUMBER = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(mySMP.META_PART_NUMBER,3) == 'Pno'){
						GET_BUFFER_STRING(mySMP.META_PART_NUMBER,3)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,MAKE,Extron'"
					SWITCH(mySMP.META_PART_NUMBER){
						CASE '60-1324-01':mySMP.MODEL_ID = MODEL_SMP351
						CASE '60-1324-02':mySMP.MODEL_ID = MODEL_SMP351_3GSDI
						CASE '60-1634-01':mySMP.MODEL_ID = MODEL_SMP352
						CASE '60-1634-02':mySMP.MODEL_ID = MODEL_SMP352_3GSDI
					}
					SEND_STRING vdvControl,"'PROPERTY-META,PART,',mySMP.META_PART_NUMBER"
					SWITCH(mySMP.MODEL_ID){
						CASE MODEL_SMP351:		mySMP.META_MODEL = 'SMP 351'
						CASE MODEL_SMP352:		mySMP.META_MODEL = 'SMP 352'
						CASE MODEL_SMP351_3GSDI:mySMP.META_MODEL = 'SMP 351 3G-SDI'
						CASE MODEL_SMP352_3GSDI:mySMP.META_MODEL = 'SMP 352 3G-SDI'
						DEFAULT:						mySMP.META_MODEL = 'NOT IMPLEMENTED'
					}
					SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',mySMP.META_MODEL"
				}
				ACTIVE(mySMP.LAST_SENT == 'Q'):{
					mySMP.META_FIRMWARE = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(mySMP.META_FIRMWARE,3) == 'Ver'){
						GET_BUFFER_STRING(mySMP.META_FIRMWARE,3)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,FW1,',mySMP.META_FIRMWARE"
				}
				ACTIVE(mySMP.LAST_SENT == '*Q'):{
					mySMP.META_FIRMWARE_FULL = fnStripCharsRight(DATA.TEXT,2)
					IF(LEFT_STRING(mySMP.META_FIRMWARE_FULL,3) == 'Bld'){
						GET_BUFFER_STRING(mySMP.META_FIRMWARE_FULL,3)
					}
					IF(LEFT_STRING(mySMP.META_FIRMWARE_FULL,6) == 'Ver*0 '){
						GET_BUFFER_STRING(mySMP.META_FIRMWARE_FULL,6)
					}
					SEND_STRING vdvControl,"'PROPERTY-META,FW2,',mySMP.META_FIRMWARE_FULL"
				}
				ACTIVE(mySMP.LAST_SENT == '98I'):{
					mySMP.META_MAC = fnStripCharsRight(DATA.TEXT,2)
					SEND_STRING vdvControl,"'PROPERTY-META,NET_MAC,',mySMP.META_MAC"
				}
				ACTIVE(mySMP.LAST_SENT == '99I'):{
					IF(mySMP.META_IP != fnStripCharsRight(DATA.TEXT,2)){
						mySMP.META_IP = fnStripCharsRight(DATA.TEXT,2)
						SEND_STRING vdvControl,"'PROPERTY-STATE,NET_IP,',mySMP.META_IP"
					}
				}
				ACTIVE(mySMP.LAST_SENT == "$1B,'YRCDR',$0D"):{
					mySMP.RECORD_STATUS = ATOI(fnStripCharsRight(DATA.TEXT,2))
				}
			}
			mySMP.LAST_SENT = ''
			IF(TIMELINE_ACTIVE(TLID_SEND)){TIMELINE_KILL(TLID_SEND)}
			fnSendFromQueue()
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	mySMP.LAST_SENT			= 0
	mySMP.META_FIRMWARE		= ''
	mySMP.META_FIRMWARE_FULL= ''
	mySMP.META_MAC				= ''
	mySMP.META_MODEL			= ''
	mySMP.META_PART_NUMBER	= ''
	mySMP.MODEL_ID 			= 0
	mySMP.Tx 					= ''
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': 		mySMP.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							mySMP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							mySMP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							mySMP.IP_HOST = DATA.TEXT
							mySMP.IP_PORT = 23
						}
						IF(mySMP.isIP){
							fnRetryConnection()
						}
					}
				}
			}
			CASE 'RECORD':{
				SWITCH(DATA.TEXT){
					CASE 'STOP': fnAddToQueue("$1B,'Y0RCDR',$0D",FALSE)	// Record Status
					CASE 'START':fnAddToQueue("$1B,'Y1RCDR',$0D",FALSE)	// Record Status
					CASE 'PAUSE':fnAddToQueue("$1B,'Y2RCDR',$0D",FALSE)	// Record Status
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,008] = (mySMP.RECORD_STATUS == RECORD_STATUS_RECORDING)	// Recording
	[vdvControl,002] = (mySMP.RECORD_STATUS == RECORD_STATUS_STOPPED)	// stop
	[vdvControl,003] = (mySMP.RECORD_STATUS == RECORD_STATUS_PAUSED)	// pause
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/