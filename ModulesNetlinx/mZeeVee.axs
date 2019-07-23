ODULE_NAME='mZeeVee'(DEV vdvServer, DEV vdvDevice[], DEV dvIP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Hushbutton Control Module
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uServer{
	CHAR     HOST_NAME[30]
	CHAR     VERSION[10]
	CHAR     MAC_ADDRESS[20]
	CHAR     SERIAL_NO[20]
	CHAR     UPTIME[20]
	CHAR     productID[50]
}
DEFINE_TYPE STRUCTURE uDevice{
	INTEGER  TYPE
	INTEGER  STATE
	CHAR     MODEL[25]
	CHAR     MAC[17]
	CHAR     NAME[30]
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
	INTEGER  RELAY_RS232
}
DEFINE_TYPE STRUCTURE uZeeVee{
	// Communications
	CHAR 		Rx[10000]			// Receieve Buffer
	CHAR     TxCmd[10000]		// Send Buffer - Commands
	CHAR     TxQry[1000]			// Send Buffer - Queries
	INTEGER 	IP_PORT				// Telnet Port 23
	CHAR		IP_HOST[255]		//
	INTEGER 	IP_STATE				//
	INTEGER  PENDING
	INTEGER  PROCESSING	      // True if waiting on a response

	INTEGER	DEBUG
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
	CHAR     MODEL[20]
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
	uServer  SERVER
	uDevice  ProcessingDevice
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	   = 1
LONG TLID_POLL_LONG	= 2
LONG TLID_POLL_SHORT	= 3
LONG TLID_RETRY	   = 4

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_NEGOTIATE  	= 1
INTEGER IP_STATE_CONNECTING	= 2
INTEGER IP_STATE_CONNECTED		= 3

// Debugggin Levels
INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

INTEGER DEVICE_TYPE_ENCODER = 1
INTEGER DEVICE_TYPE_DECODER = 2

INTEGER DEVICE_STATE_UNKNOWN = 0
INTEGER DEVICE_STATE_DOWN    = 1
INTEGER DEVICE_STATE_UP      = 2

INTEGER PROCESSING_SERVER_INFO   = 1
INTEGER PROCESSING_DEVICE_STATUS = 2
INTEGER PROCESSING_DATA_RELAYS   = 3
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 			= { 180000 }
LONG TLT_POLL_LONG[] 	= {  75000 }
LONG TLT_POLL_SHORT[] 	= {  2000, 2000, 15000, 15000 }
LONG TLT_RETRY[]			= {   5000 }
VOLATILE uZeeVee myZeeVeeServer
VOLATILE uDevice myZeeVeeDevice[125]
/******************************************************************************
	Helper Functions - Comms
******************************************************************************/
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myZeeVeeServer.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'ZeeVee IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to ZeeVee on ',"myZeeVeeServer.IP_HOST,':',ITOA(myZeeVeeServer.IP_PORT)")
		myZeeVeeServer.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myZeeVeeServer.IP_HOST, myZeeVeeServer.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIP.port)
}
DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[],INTEGER IsCmd){
	fnDebug(DEBUG_STD,'Queing',pDATA)
	SWITCH(IsCmd){
		CASE TRUE:  myZeeVeeServer.TxCmd = "myZeeVeeServer.TxCmd,pDATA,$0D,$0A"
		CASE FALSE: myZeeVeeServer.TxQry = "myZeeVeeServer.TxQry,pDATA,$0D,$0A"
	}
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug(DEBUG_DEV,'fnSendFromQueue()','')
	IF(myZeeVeeServer.IP_STATE == IP_STATE_CONNECTED && !myZeeVeeServer.PENDING){
		STACK_VAR CHAR toSend[250]
		SELECT{
			ACTIVE(LENGTH_ARRAY(myZeeVeeServer.TxCmd)):{
				toSend = REMOVE_STRING(myZeeVeeServer.TxCmd,"$0D,$0A",1)
			}
			ACTIVE(LENGTH_ARRAY(myZeeVeeServer.TxQry)):{
				toSend = REMOVE_STRING(myZeeVeeServer.TxQry,"$0D,$0A",1)
			}
		}
		fnDebug(DEBUG_DEV,'toSend',toSend)
		IF(LENGTH_ARRAY(toSend)){
			fnDebug(DEBUG_STD,'->ZV', "toSend");
			SEND_STRING dvIP, "toSend"
			myZeeVeeServer.PENDING = TRUE
		}
	}
}
/******************************************************************************
	Helper Functions - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL_LONG)){  TIMELINE_KILL(TLID_POLL_LONG) }
	TIMELINE_CREATE(TLID_POLL_LONG,TLT_POLL_LONG,LENGTH_ARRAY(TLT_POLL_LONG),TIMELINE_RELATIVE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL_LONG]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL_SHORT)){ TIMELINE_KILL(TLID_POLL_SHORT) }
	TIMELINE_CREATE(TLID_POLL_SHORT,TLT_POLL_SHORT,LENGTH_ARRAY(TLT_POLL_SHORT),TIMELINE_RELATIVE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL_SHORT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1:fnAddToQueue('show server info',FALSE)
		CASE 2:fnAddToQueue('show device status encoders',FALSE)
		CASE 3:fnAddToQueue('show device status decoders',FALSE)
		CASE 4:fnAddToQueue('show data-relays',FALSE)
	}
}
/******************************************************************************
	Helper Functions - Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myZeeVeeServer.DEBUG >= DEBUG_TYPE){
		STACK_VAR CHAR pCOPY[5000]
		pCOPY = MsgData
		WHILE(LENGTH_ARRAY(pCOPY)){
			SEND_STRING 0:0:0, "ITOA(vdvServer.Number),':',Msg, ':', GET_BUFFER_STRING(pCOPY,200)"
		}
	}
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvIP, myZeeVeeServer.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myZeeVeeServer.IP_STATE	= IP_STATE_NEGOTIATE
		fnAddToQueue('set server data-transfer-mode raw',TRUE)
		fnPoll()
	}
	OFFLINE:{
		myZeeVeeServer.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myZeeVeeServer.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'ZeeVee IP Error:[',myZeeVeeServer.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'ZV_RAW->',DATA.TEXT)

		// Telnet Negotiation
		WHILE(myZeeVeeServer.Rx[1] == $FF && LENGTH_ARRAY(myZeeVeeServer.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myZeeVeeServer.Rx,3)
			fnDebug(DEBUG_DEV,'ZV.Telnet->',fnHexToString(NEG_PACKET))
			SWITCH(NEG_PACKET[2]){
				CASE $FB:fnDebug(DEBUG_DEV,'ZV.Telnet->','WILL')
				CASE $FC:fnDebug(DEBUG_DEV,'ZV.Telnet->','WONT')
				CASE $FD:fnDebug(DEBUG_DEV,'ZV.Telnet->','DO')
				CASE $FE:fnDebug(DEBUG_DEV,'ZV.Telnet->','DONT')
			}
			fnDebug(DEBUG_DEV,'ZV.Telnet->',ITOA(NEG_PACKET[3]))
			SWITCH(NEG_PACKET[3]){
				CASE 01:fnDebug(DEBUG_DEV,'ZV.Telnet->','Echo')
			}
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(DEBUG_DEV,'->ZV.Telnet',fnHexToString(NEG_PACKET))
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}

		// Data Communication
		WHILE(FIND_STRING(myZeeVeeServer.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myZeeVeeServer.Rx,"$0D,$0A",1),2))
		}	
		// Connection Established
		IF(FIND_STRING(myZeeVeeServer.Rx,'Zyper$ ',1)){
			REMOVE_STRING(myZeeVeeServer.Rx,'Zyper$ ',1)
			myZeeVeeServer.IP_STATE = IP_STATE_CONNECTED
			fnSendFromQueue()
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnStoreProcessingDevice(){
	// Store Device if processing one
	STACK_VAR INTEGER d
	STACK_VAR INTEGER Found
	// Find and Store
	fnDebug(DEBUG_DEV,'Storing Device',ITOA(myZeeVeeServer.ProcessingDevice.NAME))
	FOR(d = 1; d <= LENGTH_ARRAY(vdvDevice); d++){
		IF(LENGTH_ARRAY(myZeeVeeDevice[d].NAME) && myZeeVeeDevice[d].NAME == myZeeVeeServer.ProcessingDevice.NAME){
			IF(myZeeVeeDevice[d].MAC != myZeeVeeServer.ProcessingDevice.MAC && myZeeVeeServer.ProcessingDevice.MAC != ''){
				myZeeVeeDevice[d].MAC = myZeeVeeServer.ProcessingDevice.MAC
			}
			IF(myZeeVeeDevice[d].MODEL != myZeeVeeServer.ProcessingDevice.MODEL && myZeeVeeServer.ProcessingDevice.MODEL != ''){
				myZeeVeeDevice[d].MODEL = myZeeVeeServer.ProcessingDevice.MODEL
			}
			IF(myZeeVeeDevice[d].RELAY_RS232 != myZeeVeeServer.ProcessingDevice.RELAY_RS232 && myZeeVeeServer.ProcessingDevice.RELAY_RS232 != 0){
				myZeeVeeDevice[d].RELAY_RS232 = myZeeVeeServer.ProcessingDevice.RELAY_RS232
				SEND_STRING vdvDevice[d],"'PROPERTY-RELAY,RS232,',ITOA(myZeeVeeDevice[d].RELAY_RS232)"
			}
			IF(myZeeVeeDevice[d].SERIAL_NO != myZeeVeeServer.ProcessingDevice.SERIAL_NO && myZeeVeeServer.ProcessingDevice.SERIAL_NO != ''){
				myZeeVeeDevice[d].SERIAL_NO = myZeeVeeServer.ProcessingDevice.SERIAL_NO
			}
			IF(myZeeVeeDevice[d].STATE != myZeeVeeServer.ProcessingDevice.STATE && myZeeVeeServer.ProcessingDevice.STATE != ''){
				myZeeVeeDevice[d].STATE = myZeeVeeServer.ProcessingDevice.STATE
			}
			IF(myZeeVeeDevice[d].TEMPERATURE != myZeeVeeServer.ProcessingDevice.TEMPERATURE && myZeeVeeServer.ProcessingDevice.TEMPERATURE != 0){
				myZeeVeeDevice[d].TEMPERATURE = myZeeVeeServer.ProcessingDevice.TEMPERATURE
			}
			IF(myZeeVeeDevice[d].UPTIME != myZeeVeeServer.ProcessingDevice.UPTIME && myZeeVeeServer.ProcessingDevice.UPTIME != ''){
				myZeeVeeDevice[d].UPTIME = myZeeVeeServer.ProcessingDevice.UPTIME
			}
			IF(myZeeVeeDevice[d].TYPE != myZeeVeeServer.ProcessingDevice.TYPE && myZeeVeeServer.ProcessingDevice.TYPE != 0){
				myZeeVeeDevice[d].TYPE = myZeeVeeServer.ProcessingDevice.TYPE
			}
			Found = TRUE
		}
	}
	// Report devices we aren't handling
	IF(!Found && myZeeVeeServer.ProcessingDevice.NAME != ''){
		fnDebug(DEBUG_ERR,'ZeeVee Unhandled Device:',"myZeeVeeServer.ProcessingDevice.MAC,' (',myZeeVeeServer.ProcessingDevice.NAME,')'")
	}
	// Clear Out Device
	IF(1){
		STACK_VAR uDevice blankDevice
		myZeeVeeServer.ProcessingDevice = blankDevice
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[1000]){

  fnDebug(DEBUG_DEV,'ZV->',"'[',pDATA,']'")

	SELECT{
		ACTIVE('Success' = pDATA):{
			fnDebug(DEBUG_STD,'Response Ended',pDATA)
			// Store Device if processing
			SWITCH(myZeeVeeServer.PROCESSING){
				CASE PROCESSING_DATA_RELAYS: 
				CASE PROCESSING_DEVICE_STATUS: fnStoreProcessingDevice()
			}
			// Send next command
			myZeeVeeServer.PROCESSING = FALSE
			myZeeVeeServer.PENDING = FALSE
			fnSendFromQueue()
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		ACTIVE(fnComparePrefix(pDATA,'Show')):{
			fnDebug(DEBUG_STD,'Echo',pDATA)
		}
		ACTIVE(fnComparePrefix(pDATA,'Error')):{
			fnDebug(DEBUG_STD,'Response Error',pDATA)
			REMOVE_STRING(pDATA,':',1)
			SEND_STRING vdvServer,"'ERROR-',pDATA"
			// Send next command
			myZeeVeeServer.PROCESSING = FALSE
			myZeeVeeServer.PENDING = FALSE
			fnSendFromQueue()
		}
		ACTIVE(fnComparePrefix(pDATA,'Warning')):{
			fnDebug(DEBUG_STD,'Response Warning',pDATA)
			REMOVE_STRING(pDATA,':',1)
			SEND_STRING vdvServer,"'WARNING-',pDATA"
			// Send next command
			myZeeVeeServer.PROCESSING = FALSE
			myZeeVeeServer.PENDING = FALSE
			fnSendFromQueue()
		}
		ACTIVE(fnComparePrefix(pDATA,'server(')):{
			fnDebug(DEBUG_STD,'Response Started',pDATA)
			myZeeVeeServer.PROCESSING = PROCESSING_SERVER_INFO
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		ACTIVE(fnComparePrefix(pDATA,'device(')):{
			// Store device if already processing one
			fnStoreProcessingDevice()
			// Start a new one
			fnDebug(DEBUG_STD,'Response Started',pDATA)
			myZeeVeeServer.PROCESSING = PROCESSING_DEVICE_STATUS
			// Do new device
			REMOVE_STRING(pDATA,'(',1)
			myZeeVeeServer.ProcessingDevice.MAC = fnStripCharsRight(REMOVE_STRING(pDATA,')',1),1)
		}
		ACTIVE(fnComparePrefix(pDATA,'data-sessions(')):{
			// Store device if processing
			fnStoreProcessingDevice()
			// Statr a new one
			fnDebug(DEBUG_STD,'Response Started',pDATA)
			myZeeVeeServer.PROCESSING = PROCESSING_DATA_RELAYS
		}
		ACTIVE(1):{
			// Get Line Header
			STACK_VAR CHAR HEAD[200]
			SELECT{
				ACTIVE(1):{
					SWITCH(myZeeVeeServer.PROCESSING){
						CASE PROCESSING_SERVER_INFO:
						CASE PROCESSING_DEVICE_STATUS: HEAD = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,';',1),1))
						CASE PROCESSING_DATA_RELAYS:   HEAD = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
					}
					fnDebug(DEBUG_DEV,'Response Head',HEAD)
					// Process KeyValue Pairs
					WHILE(LENGTH_ARRAY(pDATA)){
						STACK_VAR CHAR KEY[30]
						STACK_VAR CHAR VAL[50]
						KEY = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1))
						IF(FIND_STRING(pDATA,',',1)){
							VAL = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
						}
						ELSE{
							VAL = fnRemoveWhiteSpace(pDATA)
							pDATA = ''
						}
						fnDebug(DEBUG_DEV,'Response Data Pair',"KEY,'=',VAL")
						SWITCH(myZeeVeeServer.PROCESSING){
							CASE PROCESSING_SERVER_INFO:{
								SWITCH(HEAD){
									CASE 'server.gen':{
										SWITCH(KEY){
											CASE 'hostname':     myZeeVeeServer.SERVER.HOST_NAME   = VAL
											CASE 'macAddress':   myZeeVeeServer.SERVER.MAC_ADDRESS = VAL
											CASE 'serialNumber': myZeeVeeServer.SERVER.SERIAL_NO   = VAL
											CASE 'uptime':       myZeeVeeServer.SERVER.UPTIME      = VAL
											CASE 'version':      myZeeVeeServer.SERVER.VERSION     = VAL
										}
									}
									CASE 'server.license':{
										SWITCH(KEY){
											CASE 'productID':    myZeeVeeServer.SERVER.productID   = VAL
										}
									}
								}
							}
							CASE PROCESSING_DEVICE_STATUS:{
								SWITCH(HEAD){
									CASE 'device.gen':{
										SWITCH(KEY){
											CASE 'type':{
												SWITCH(VAL){
													CASE 'encoder':myZeeVeeServer.ProcessingDevice.TYPE = DEVICE_TYPE_ENCODER
													CASE 'decoder':myZeeVeeServer.ProcessingDevice.TYPE = DEVICE_TYPE_DECODER
												}
											}
											CASE 'state':{
												SWITCH(VAL){
													CASE 'Down':myZeeVeeServer.ProcessingDevice.STATE  = DEVICE_STATE_DOWN
													CASE 'Up':  myZeeVeeServer.ProcessingDevice.STATE  = DEVICE_STATE_UP
												}
											}
											CASE 'model':     myZeeVeeServer.ProcessingDevice.MODEL  = VAL
											CASE 'name':      myZeeVeeServer.ProcessingDevice.NAME   = VAL
											CASE 'uptime':    myZeeVeeServer.ProcessingDevice.UPTIME = VAL
										}
									}
									CASE 'device.temperature':{
										SWITCH(KEY){
											CASE 'main':		myZeeVeeServer.ProcessingDevice.TEMPERATURE = ATOF(fnStripCharsRight(VAL,1))
										}
									}
								}
							}
							CASE PROCESSING_DATA_RELAYS:{
								SWITCH(HEAD){
									CASE 'device':{
										SWITCH(KEY){
											CASE 'name':myZeeVeeServer.ProcessingDevice.NAME   = VAL
										}
									}
									CASE 'rs232-tcp':{
										SWITCH(KEY){
											CASE 'port':myZeeVeeServer.ProcessingDevice.RELAY_RS232   = ATOI(VAL)
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}


/******************************************************************************
	Control Events - Server
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvServer]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myZeeVeeServer.DEBUG = DEBUG_STD
							CASE 'DEV': myZeeVeeServer.DEBUG = DEBUG_DEV
							DEFAULT:		myZeeVeeServer.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myZeeVeeServer.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myZeeVeeServer.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myZeeVeeServer.IP_HOST = DATA.TEXT
							myZeeVeeServer.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(DATA.TEXT,TRUE)
			}
			CASE 'JOIN':{
				fnDebug(DEBUG_DEV,'Joining',"fnGetCSV(DATA.TEXT,1),' to ',fnGetCSV(DATA.TEXT,2)")
				// fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' fast-switched'",TRUE)
				fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' genlocked'",TRUE)
				fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' analog-audio'",TRUE)
				fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' hdmi-audio'",TRUE)
			}
		}
	}
}
/******************************************************************************
	Control Events - Endpoints
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvDevice]{
	COMMAND:{
		STACK_VAR INTEGER e
		STACK_VAR CHAR name[25]
		e = GET_LAST(vdvDevice)
		name = myZeeVeeDevice[e].NAME
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':{
						myZeeVeeDevice[e].NAME = DATA.TEXT
					}
					CASE 'RS232':{
						STACK_VAR CHAR s[100]
						s = "'set device ',name,' rs232'"
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE '9600':   s = "s,' 9600'"
							CASE '19200':  s = "s,' 19200'"
							CASE '38400':  s = "s,' 38400'"
							CASE '57600':  s = "s,' 57600'"
							CASE '115200': s = "s,' 115200'"
						}
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE '7': s = "s,' 7-bits'"
							CASE '8': s = "s,' 8-bits'"
						}
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE '1': s = "s,' 1-stop'"
							CASE '2': s = "s,' 2-stop'"
						}
						SWITCH(DATA.TEXT){
							CASE 'E': s = "s,' even'"
							CASE 'O': s = "s,' odd'"
							CASE 'N': s = "s,' none'"
						}
						fnAddToQueue(s,TRUE)
					}
					CASE 'RELAY':{
						SWITCH(DATA.TEXT){
							CASE 'RS232':{
								fnAddToQueue("'data-connect ',name,' server rs232'",TRUE)
							}
						}
					}
				}
			}
			CASE 'CHAN':{
				SWITCH(DATA.TEXT){
					CASE 'ENC':{
						STACK_VAR INTEGER x
						FOR(x = 1; x <= LENGTH_ARRAY(vdvDevice); x++){
							IF(DEVTOA(vdvDevice[x]) == DATA.TEXT){
								fnAddToQueue("'join ',myZeeVeeDevice[x].NAME,' ',name,' fast-switched'",TRUE)
								BREAK
							}
						}
					}
					CASE 'INC': fnAddToQueue("'channel up ',name",TRUE)
					CASE 'DEC': fnAddToQueue("'channel down ',name",TRUE)
					DEFAULT:    fnAddToQueue("'join ',DATA.TEXT,' ',name,' fast-switched'",TRUE)
				}
			}
			CASE 'RAW':{
				fnAddToQueue(DATA.TEXT,TRUE)
			}
			CASE 'RS232':{
				// In format with \n \r \t \\ \xnn
				fnAddToQueue("'send ',name,' rs232 ',DATA.TEXT",TRUE)
			}
			CASE 'CEC':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  fnAddToQueue("'send ',name,' cec on'",TRUE)
					CASE 'OFF': fnAddToQueue("'send ',name,' cec off'",TRUE)
				}
			}
		}
	}
}
/******************************************************************************
	Decoder Audio follow Video
******************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvDevice,251]{
	ON:{
		STACK_VAR INTEGER d
		d = GET_LAST(vdvDevice)
		IF(myZeeVeeDevice[d].TYPE == DEVICE_TYPE_DECODER){
			//fnAddToQueue("'join video-source ',myZeeVeeDevice[d].NAME,' hdmi-audio'",TRUE)
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER d
	// Endpoints
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		FOR(d = 1; d <= LENGTH_ARRAY(vdvDevice); d++){
			[vdvDevice[d],251] = (myZeeVeeDevice[d].STATE == DEVICE_STATE_UP)
			[vdvDevice[d],252] = (myZeeVeeDevice[d].STATE == DEVICE_STATE_UP)
		}
	}
	ELSE{
		[vdvDevice,251] = FALSE
		[vdvDevice,252] = FALSE
	}

	// Server
	[vdvServer,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvServer,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/

