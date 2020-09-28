MODULE_NAME='mLightwareMatrix'(DEV vdvControl[], DEV dvDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	Basic Ligthware Matrix Module - RMS Enabled
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_INPUTS  = 8
INTEGER MAX_OUTPUTS = 8

DEFINE_TYPE STRUCTURE uInput{
	INTEGER  Signal
}
DEFINE_TYPE STRUCTURE uOutput{
	INTEGER  MUTE
	INTEGER  GAIN
	INTEGER  GAIN_PEND
	SINTEGER LAST_GAIN
}
DEFINE_TYPE STRUCTURE uConfig{
	INTEGER  HasAudio				// Does this switch have audio
}
DEFINE_TYPE STRUCTURE uMeta{
	// MetaData
	CHAR     CpuFirmware[20]		// Firmware
	CHAR     PartNumber[20]		// Model
	CHAR     ProductName[20]		// Model
	CHAR     SerialNumber[20]			// Serial Number
	CHAR     MAC[20]					// MAC Address
	CHAR     IP[20]					// IP Address
}
DEFINE_TYPE STRUCTURE uState{
	Float    Temperature		// Internal Temperature
	LONG     UpTime
	LONG     OperationTime
}

DEFINE_TYPE STRUCTURE uComms{
	// Communications
	INTEGER 	STATE						//	Current state of Comms
	CHAR	   Tx[2048]					// Transmission Buffer
	CHAR 		Rx[2048]					// Receieve Buffer
	INTEGER 	IP_PORT					//	IP Port for device
	CHAR		IP_HOST[255]			//	IP Host for device
	INTEGER	isIP						// Determines if using IP comms

	INTEGER  DISABLED					// Disable Module
	CHAR	   LAST_SENT[100]			// Last sent message for feedback handling

}
DEFINE_TYPE STRUCTURE uMatrix{
	uConfig Config
	uComms  Comms
	uMeta   MetaData
	uOutput Output[MAX_OUTPUTS]
	uInput  Input[MAX_INPUTS]
	uState  State
	uDebug  Debug						// Debuging ON/OFF
}

DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_SEND		= 3
LONG TLID_RETRY	= 5

LONG TLID_GAIN_00	 = 10
LONG TLID_GAIN_01	 = 11
LONG TLID_GAIN_02	 = 12
LONG TLID_GAIN_03	 = 13
LONG TLID_GAIN_04	 = 14
LONG TLID_GAIN_05	 = 15
LONG TLID_GAIN_06	 = 16
LONG TLID_GAIN_07	 = 17
LONG TLID_GAIN_08	 = 18

// IP States
INTEGER ConnStateOffline		= 0
INTEGER ConnStateConnecting	= 1
INTEGER ConnStateConnected		= 2

// Part Numbers
CHAR PN_MMX4x2HT200[]       = '91310035'
CHAR PN_MMX6x2HT220[]       = '91310030'
CHAR PN_MX28X8HDMI20AUDIO[] = '91310050'

// Mode Families
INTEGER MODEL_MMX = 0
INTEGER MODEL_MX2 = 1


DEFINE_VARIABLE
LONG TLT_COMMS[] 	= { 30000 }
LONG TLT_POLL[]  	= { 10000 }
LONG TLT_SEND[]	= {   100 }
LONG TLT_GAIN[]	= {   150 }
LONG TLT_RETRY[]	= {  5000 }
VOLATILE uMatrix myMatrix

DEFINE_FUNCTION INTEGER fnModel(){
	SWITCH(myMatrix.MetaData.PartNumber){
		CASE PN_MMX4x2HT200:
		CASE PN_MMX6x2HT220:       RETURN MODEL_MMX
		CASE PN_MX28X8HDMI20AUDIO: RETURN MODEL_MX2
	}
}
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myMatrix.Comms.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myMatrix.Comms.Rx
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myMatrix.Comms.IP_Host == ''){
		fnDebug(myMatrix.Debug,DEBUG_ERR,'Lightware Host Not Set')
	}
	ELSE{
		fnDebug(myMatrix.Debug,DEBUG_STD,"'Connecting to Lightware on ',myMatrix.Comms.IP_Host,':',ITOA(myMatrix.Comms.IP_Port)")
		myMatrix.Comms.State = ConnStateConnecting
		ip_client_open(dvDevice.port, myMatrix.Comms.IP_Host, myMatrix.Comms.IP_Port, IP_TCP)
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
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[256], CHAR pData[256]){
	myMatrix.Comms.Tx = "myMatrix.Comms.Tx,pCMD"
	IF(pData != ''){
		myMatrix.Comms.Tx = "myMatrix.Comms.Tx,' ',pData"
	}
	myMatrix.Comms.Tx = "myMatrix.Comms.Tx,$0D,$0A"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && LENGTH_ARRAY(myMatrix.Comms.Tx) && myMatrix.Comms.State == ConnStateConnected){
		STACK_VAR CHAR toSend[256]
		toSend = REMOVE_STRING(myMatrix.Comms.Tx,"$0D,$0A",1)
		fnDebug(myMatrix.Debug,DEBUG_STD,"'AMX->MTX::', toSend");
		SEND_STRING dvDevice,toSend
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	fnInitPoll()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	fnSendFromQueue()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(!myMatrix.Comms.Disabled){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	// Start Poll
	fnAddToQueue('GET', '/.*')
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	// Local Variables
	STACK_VAR CHAR pPath[256]
	STACK_VAR CHAR pFunc[256]
	STACK_VAR CHAR pVal[256]
	// Debug Out
	fnDebug(myMatrix.Debug,DEBUG_STD,"'MTX->AMX::', pData")
	// Get Components
	IF(FIND_STRING(pData,' ',1)){
		REMOVE_STRING(pData,' ',1)	// Remove CMD Type
	}
	pPath = fnStripCharsRight(REMOVE_STRING(pData,'.',1),1)
	pFunc = fnStripCharsRight(REMOVE_STRING(pData,'=',1),1)
	pVal  = pData
	// Process
	SELECT{
		ACTIVE(pPath == '/'):{
			SWITCH(pFunc){
				CASE 'PartNumber':{
					IF(myMatrix.MetaData.PartNumber != pVal){
						myMatrix.MetaData.PartNumber = pVal
						SWITCH(fnModel()){
							CASE MODEL_MMX:{
								// Get and Subscribe to System State Data
								fnAddToQueue('GET', '/MANAGEMENT/STATUS.*')
								fnAddToQueue('OPEN', '/MANAGEMENT/STATUS.*')
								// Get and Subscribe to Video Routing Data
								fnAddToQueue('GET', '/MEDIA/VIDEO/XP.*')
								fnAddToQueue('OPEN', '/MEDIA/VIDEO/XP.*')
							}
							CASE MODEL_MX2:{
								// Get and Subscribe to Video Routing Data
								fnAddToQueue('GET', '/MEDIA/XP/VIDEO.*')
								fnAddToQueue('OPEN', '/MEDIA/XP/VIDEO')
								fnAddToQueue('OPEN', '/MANAGEMENT/DATETIME')
							}
						}
					}
				}
				CASE 'SerialNumber': myMatrix.MetaData.SerialNumber = pVal
				CASE 'ProductName':  myMatrix.MetaData.ProductName = pVal
			}
		}
		ACTIVE(pPath == '/MANAGEMENT/STATUS'):{
			SWITCH(pFunc){
				CASE 'UpTime':{
					myMatrix.State.UpTime = ATOI(pVal)
					IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
					TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
				CASE 'OperationTime':   myMatrix.State.OperationTime = ATOI(pVal)
			}
		}
		// MMX Devices
		ACTIVE(pPath == '/MEDIA/VIDEO/XP'):{
			SWITCH(pFunc){
				CASE 'SourcePortStatus':{
					STACK_VAR INTEGER i
					FOR(i = 1; i <= MAX_INPUTS; i++){
						STACK_VAR CHAR pChunk[10]
						pChunk = fnGetSplitStringValue(pData,';',i)
						IF(pChunk != ''){
							myMatrix.Input[i].Signal = MID_STRING(pChunk,5,1) == 'F'
						}
						ELSE{BREAK}
					}
				}
			}
		}
		// MX2 Devices
		ACTIVE(pPath == '/MEDIA/XP/VIDEO'):{
			SWITCH(pFunc){
				CASE 'SourcePortStatus':{
					STACK_VAR INTEGER i
					FOR(i = 1; i <= MAX_INPUTS; i++){
						STACK_VAR CHAR pChunk[10]
						pChunk = fnGetSplitStringValue(pData,';',i)
						IF(pChunk != ''){
							myMatrix.Input[i].Signal = MID_STRING(pChunk,3,1) == 'F'
						}
						ELSE{BREAK}
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
		// Handle setup for RS232 Connection
		IF(!myMatrix.Comms.isIP){
		   SEND_COMMAND dvDevice, 'SET MODE DATA'
		   SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		   SEND_COMMAND dvDevice, 'SET FAULT DETECT OFF'
		}
		// Set state to connected (Both RS232 & IP is true)
		myMatrix.Comms.State	= ConnStateConnected
		// Init communications
		fnPoll()
	}
	OFFLINE:{
		IF(myMatrix.Comms.isIP){
			myMatrix.Comms.State	= ConnStateOffline
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myMatrix.Comms.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myMatrix.Comms.State = ConnStateOffline
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
			fnDebug(myMatrix.Debug,DEBUG_ERR,"'Lightware IP Error:[',myMatrix.Comms.IP_Host,'][',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myMatrix.Comms.Disabled){
			// Debug Out
			fnDebug(myMatrix.Debug,DEBUG_DEV,"'RAW->AMX::', DATA.TEXT")
			// Loop whilst a line is present in the buffer
			WHILE(FIND_STRING(myMatrix.Comms.Rx,"$0D,$0A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myMatrix.Comms.Rx,"$0D,$0A",1),2))
			}
			// Reset Comms Timer
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	// Local Variables
	STACK_VAR uInput  blankInput
	STACK_VAR uOutput blankOutput
	STACK_VAR uMeta   blankMeta
	STACK_VAR uState  blankState
	STACK_VAR INTEGER x

	// Reset Modules
	FOR(x = 1; x <= MAX_INPUTS; x++){
		myMatrix.Input[x]    = blankInput
	}
	FOR(x = 1; x <= MAX_OUTPUTS; x++){
		myMatrix.Output[x]    = blankOutput
	}
	myMatrix.MetaData = blankMeta
	myMatrix.State    = blankState

	myMatrix.Comms.Tx = ''
	myMatrix.Comms.Rx = ''
}
//

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING DATA.DEVICE, 'RANGE-0,100'
	}
	COMMAND:{
		// Local Variable
		STACK_VAR INTEGER i
		i = GET_LAST(vdvControl)
		// Enable / Disable Module
		SWITCH(DATA.TEXT){
			CASE 'PROPERTY-ENABLED,FALSE':myMatrix.Comms.Disabled = TRUE
			CASE 'PROPERTY-ENABLED,TRUE': myMatrix.Comms.Disabled = FALSE
		}
		IF(!myMatrix.Comms.Disabled){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE':myMatrix.Debug.LOG_LEVEL = DEBUG_STD
							}
						}
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myMatrix.Comms.IP_Host = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myMatrix.Comms.IP_Port = ATOI(DATA.TEXT)
							}
							ELSE{
								myMatrix.Comms.IP_Host = DATA.TEXT
								myMatrix.Comms.IP_Port = 6107
							}
							fnRetryConnection()
						}
					}
				}
				CASE 'RAW':fnAddToQueue(DATA.TEXT,'')
				CASE 'POLL':fnPoll()
				CASE 'AMATRIX': {}
				CASE 'VMATRIX': {}
				CASE 'MATRIX':{
					STACK_VAR CHAR pIN[3]
					pIN = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1)
					IF(pIN != '0'){pIN = "'I',pIN"}
					SWITCH(fnModel()){
						CASE MODEL_MMX:fnAddToQueue('CALL',"'/MEDIA/VIDEO/XP:switch(',pIN,':O',DATA.TEXT,')'")
						CASE MODEL_MX2:fnAddToQueue('CALL',"'/MEDIA/XP/VIDEO:switch(',pIN,':O',DATA.TEXT,')'")
					}
				}
				CASE 'INPUT':{
					STACK_VAR CHAR pIN[3]
					pIN = ITOA(ATOI(DATA.TEXT))
					IF(pIN != '0'){pIN = "'I',pIN"}
					SWITCH(fnModel()){
						CASE MODEL_MMX:fnAddToQueue('CALL',"'/MEDIA/VIDEO/XP:switch(',pIN,':O',ITOA(i),')'")
						CASE MODEL_MX2:fnAddToQueue('CALL',"'/MEDIA/XP/VIDEO:switch(',pIN,':O',ITOA(i),')'")
					}
				}
				//CASE 'VOLUME':{
//					IF(myMatrix.Config.HasAudio){
//						STACK_VAR INTEGER pOUTPUT
//						pOUTPUT = GET_LAST(vdvControl)
//						SWITCH(DATA.TEXT){
//							CASE 'INC':	fnAddToQueue("ITOA(pOUTPUT),'*+V'")
//							CASE 'DEC':	fnAddToQueue("ITOA(pOUTPUT),'*-V'")
//							DEFAULT:{
//								SINTEGER VOL
//								//VOL = -100
//								//VOL = VOL + ATOI(DATA.TEXT)
//								VOL = ATOI(DATA.TEXT)
//								IF(!TIMELINE_ACTIVE(TLID_GAIN_00+pOUTPUT)){
//									fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(VOL),'V'")
//									TIMELINE_CREATE(TLID_GAIN_00+pOUTPUT,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
//								}
//								ELSE{
//									myMatrix.Output[pOutput].LAST_GAIN = VOL
//									myMatrix.Output[pOutput].GAIN_PEND = TRUE
//								}
//							}
//						}
//					}
//				}
//				CASE 'MUTE':{
//					STACK_VAR INTEGER pOUTPUT
//					pOUTPUT = GET_LAST(vdvControl)
//					SWITCH(DATA.TEXT){
//						CASE 'ON':		myMatrix.Output[pOutput].MUTE = 6
//						CASE 'OFF':		myMatrix.Output[pOutput].MUTE = 0
//						CASE 'TOGGLE':{
//							SWITCH(myMatrix.Output[pOutput].MUTE){
//								CASE 0:	myMatrix.Output[pOutput].MUTE = 6
//								DEFAULT:	myMatrix.Output[pOutput].MUTE = 0
//							}
//						}
//					}
//					fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(myMatrix.Output[pOutput].MUTE),'Z'")
//				}
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
TIMELINE_EVENT[TLID_GAIN_08]{
	//STACK_VAR INTEGER pOUTPUT
//	pOUTPUT = TIMELINE.ID-TLID_GAIN_00
//	IF(myMatrix.Output[pOutput].GAIN_PEND){
//		fnAddToQueue("ITOA(pOUTPUT),'*',ITOA(myMatrix.Output[pOutput].LAST_GAIN),'V'")
//		myMatrix.Output[pOutput].LAST_GAIN = 0
//		myMatrix.Output[pOutput].GAIN_PEND = FALSE
//		TIMELINE_CREATE(TLID_GAIN_00+pOUTPUT,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
//	}
}
DEFINE_PROGRAM{
	IF(!myMatrix.Comms.Disabled){
		STACK_VAR INTEGER x
		IF(myMatrix.Config.HasAudio){
			FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
				[vdvControl[x],199] = (myMatrix.Output[x].MUTE)
				SEND_LEVEL vdvControl[x],1,myMatrix.Output[x].GAIN
			}
		}
		// Signal Detection
		FOR(x = 1; x <= MAX_INPUTS; x++){
			[vdvControl,x] = (myMatrix.Input[x].Signal)
		}
		// Comms Feedback
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	}
}
