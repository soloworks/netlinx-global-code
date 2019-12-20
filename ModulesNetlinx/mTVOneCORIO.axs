MODULE_NAME='mTVOneCORIO'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_TYPE STRUCTURE uGain{
	INTEGER  MUTE
	SINTEGER  GAIN
	INTEGER  GAIN_PEND
	SINTEGER LAST_GAIN
}
DEFINE_TYPE STRUCTURE uCORIO{
	// Communications
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	isIP
	CHAR     PASSWORD[20]
	CHAR     USERNAME[20]
	INTEGER  RxPend
	CHAR	   Rx[1000]				// Receive Buffer
	CHAR     Tx[1000]          // Transmit Queue
	INTEGER DEBUG
	INTEGER PRESET
	uGain   Gain
}
DEFINE_CONSTANT
LONG TLID_COMMS   = 1
LONG TLID_POLL	   = 2
LONG TLID_RETRY   = 3
LONG TLID_TIMEOUT = 4
LONG TLID_GAIN	= 10

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2

DEFINE_VARIABLE
LONG TLT_COMMS[]   = { 60000 }
LONG TLT_POLL[]    = { 15000 }
LONG TLT_TIMEOUT[] = {  5000 }
LONG TLT_GAIN[]	 = {   150 }
LONG TLT_RETRY[]	 = {  5000 }

uCORIO myCORIO
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myCorio.isIP = !(dvDEVICE.NUMBER)
}
/******************************************************************************
	IP Helper Functions
******************************************************************************/

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myCorio.IP_HOST == ''){
		fnDebug(TRUE,'Corio IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Corio on ',"myCorio.IP_HOST,':',ITOA(myCorio.IP_PORT)")
		myCorio.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myCorio.IP_HOST, myCorio.IP_PORT, IP_TCP)
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

/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER Error, CHAR Msg[], CHAR MsgData[]){
	 IF(myCORIO.DEBUG || Error){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnAddToQueue(CHAR pData[256]){
	// Add string to end of queue with delims
	myCORIO.Tx = "myCORIO.Tx,pData,$0D,$0A"
	// Send from Queue
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myCORIO.RxPend){
		STACK_VAR CHAR toSend[255]
		toSend = REMOVE_STRING(myCORIO.Tx,"$0D,$0A",1)
		SEND_STRING dvDevice, toSend
		fnDebug(FALSE,"'->CORIO::'","toSend")
		fnInitPoll()
		fnSetTimeout(TRUE)
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	//SEND_STRING dvDevice,"'routing.preset.Read',$0D"
	fnAddToQueue('system.comms.ethernet.IP_Address')
	fnAddToQueue('Canvas1.AudioVolume')
	fnAddToQueue('Canvas1.AudioMute')
}
DEFINE_FUNCTION fnSetTimeout(INTEGER pActive){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	IF(pActive){
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice,myCORIO.RX
}
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myCorio.isIP){
			myCorio.IP_STATE	= IP_STATE_CONNECTED
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 115200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		IF(myCorio.isIP){
			myCorio.IP_STATE	= IP_STATE_OFFLINE
			myCORIO.Rx = ''
			myCORIO.Tx = ''
			myCORIO.RxPend = FALSE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myCorio.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myCorio.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'Extron IP Error:[',myCorio.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(FALSE,'Corio->RAW', DATA.TEXT);
		WHILE(FIND_STRING(myCORIO.RX,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myCORIO.RX,"$0D,$0A",1),2))
		}
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(FALSE,'CORIO->::', pDATA);
	SELECT{
		ACTIVE(FIND_STRING(pDATA,'Not Logged In',1)):{
			//fnSendCommand('login(admin,adminpw)')
			fnAddToQueue('login(user4,user4pw)')
		}
		ACTIVE(FIND_STRING(pDATA,'Please login.',1)):{
			fnAddToQueue('login(admin,adminpw)')
		}
		ACTIVE(LEFT_STRING(pDATA,5) == '!Done'):{
			fnSetTimeout(FALSE)
		}
		ACTIVE(LEFT_STRING(pDATA,5) == '!Info'):{
			SELECT{
				ACTIVE(FIND_STRING(pData,'Logged In',1)):{
					myCORIO.IP_STATE = IP_STATE_CONNECTED
					fnPoll()
					fnInitPoll()
				}
			}
			fnSetTimeout(FALSE)
		}
		ACTIVE(1):{
			SWITCH(REMOVE_STRING(pDATA,'=',1)){
				CASE 'Canvas1.AudioVolume =':{
					myCORIO.Gain.GAIN = ATOI(pDATA)
				}
				CASE 'Canvas1.AudioMute =':{
					SWITCH(fnRemoveWhiteSpace(pDATA)){
						CASE 'Off': myCORIO.Gain.MUTE = FALSE
						CASE 'On':  myCORIO.Gain.MUTE = TRUE
					}
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myCORIO.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myCorio.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myCorio.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myCorio.IP_HOST = DATA.TEXT
							myCorio.IP_PORT = 10001
						}
						IF(myCorio.isIP){
							fnRetryConnection()
						}
					}
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'DISCONN':fnCloseTCPConnection()
				}
			}
			CASE 'PRESET':{
				// preset.take = x
				// Canvas1.AudioFollowWindow = x
				fnAddToQueue("'copypreset(',DATA.TEXT,',0)'")
				myCORIO.PRESET = ATOI(DATA.TEXT)
				IF([vdvControl,251]){
					SEND_STRING vdvControl, "'PRESET-',ITOA(myCORIO.PRESET)"
				}
			}
			CASE 'RAW':		fnAddToQueue(DATA.TEXT)
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	myCORIO.Gain.MUTE = TRUE
					CASE 'OFF':	myCORIO.Gain.MUTE = FALSE
					CASE 'TOGGLE':myCORIO.Gain.MUTE = !myCORIO.Gain.MUTE
				}
				SWITCH(myCORIO.Gain.Mute){
					CASE TRUE:  fnAddToQueue('Canvas1.AudioMute = On')
					CASE FALSE: fnAddToQueue('Canvas1.AudioMute = Off')
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':fnAddToQueue('Canvas1.AudioVolume = ')
					CASE 'DEC':fnAddToQueue('Canvas1.AudioVolume = ')
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_GAIN)){
							myCORIO.Gain.GAIN = ATOI(DATA.TEXT)
							fnAddToQueue("'Canvas1.AudioVolume = ',ITOA(myCORIO.Gain.GAIN)")
							TIMELINE_CREATE(TLID_GAIN,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myCORIO.Gain.LAST_GAIN = ATOI(DATA.TEXT)
							myCORIO.Gain.GAIN_PEND = TRUE
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_GAIN]{
	IF(myCORIO.Gain.GAIN_PEND){
		fnAddToQueue("'Canvas1.AudioVolume = ',ITOA(myCORIO.Gain.LAST_GAIN)")
		myCORIO.Gain.GAIN = myCORIO.Gain.LAST_GAIN
		myCORIO.Gain.GAIN_PEND = FALSE
		TIMELINE_CREATE(TLID_GAIN,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_PROGRAM{
	[vdvControl,199] = (myCorio.Gain.MUTE)
	SEND_LEVEL vdvControl,1,myCorio.Gain.GAIN
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/
