MODULE_NAME='mZeeVee'(DEV vdvServer, DEV vdvDevice[], DEV dvIP)
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
	CHAR     MODEL[25]
	CHAR     MAC[17]
	CHAR     NAME[30]
	INTEGER  STATE
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
}
DEFINE_TYPE STRUCTURE uZeeVee{
	// Communications
	CHAR 		Rx[2000]						// Receieve Buffer
	CHAR     TxCmd[2000]					// Send Buffer - Commands
	CHAR     TxQry[2000]					// Send Buffer - Queries
	INTEGER 	IP_PORT						// Telnet Port 23
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER  RESPONSE_PENDING        // True if waiting on a response
	INTEGER	DEBUG
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
	CHAR     MODEL[20]
	CHAR     UPTIME[20]
	FLOAT    TEMPERATURE
	CHAR     SERIAL_NO[25]
	uServer  SERVER
	uDevice  DEVICE[125]
	uDevice  ProcessingDevice
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_RETRY	= 3

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
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 			= { 90000 }
LONG TLT_POLL[] 			= { 45000 }
LONG TLT_RETRY[]			= {  5000 }
VOLATILE uZeeVee myZeeVee
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
	IF(myZeeVee.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'ZeeVee IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to ZeeVee on ',"myZeeVee.IP_HOST,':',ITOA(myZeeVee.IP_PORT)")
		myZeeVee.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvIP.port, myZeeVee.IP_HOST, myZeeVee.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvIP.port)
}
DEFINE_FUNCTION fnAddToQueue(CHAR pDATA[],CHAR IsCmd){
	SWITCH(IsCmd){
		CASE TRUE:  myZeeVee.TxCmd = "myZeeVee.TxCmd,pDATA,$0D,$0A"
		CASE FALSE: myZeeVee.TxQry = "myZeeVee.TxQry,pDATA,$0D,$0A"
	}
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myZeeVee.IP_STATE == IP_STATE_CONNECTED && !myZeeVee.RESPONSE_PENDING){
		STACK_VAR CHAR toSend[250]
		SELECT{
			ACTIVE(LENGTH_ARRAY(myZeeVee.TxCmd)):{
				toSend = REMOVE_STRING(myZeeVee.TxCmd,"$0D,$0A",1)
			}
			ACTIVE(LENGTH_ARRAY(myZeeVee.TxQry)):{
				toSend = REMOVE_STRING(myZeeVee.TxQry,"$0D,$0A",1)
				fnDebug(DEBUG_STD,'Sending Query',toSend)
			}
		}
		IF(LENGTH_ARRAY(toSend)){
			fnDebug(DEBUG_STD,'->ZV', "toSend");
			SEND_STRING dvIP, "toSend"
			myZeeVee.RESPONSE_PENDING = TRUE
		}
	}
}
/******************************************************************************
	Helper Functions - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('show server info',FALSE)
	fnAddToQueue('show device status encoders',FALSE)
	fnAddToQueue('show device status decoders',FALSE)
}
/******************************************************************************
	Helper Functions - Debug
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DEBUG_TYPE,CHAR Msg[], CHAR MsgData[]){
	IF(myZeeVee.DEBUG >= DEBUG_TYPE){
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
	CREATE_BUFFER dvIP, myZeeVee.Rx
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvIP]{
	ONLINE:{
		myZeeVee.IP_STATE	= IP_STATE_NEGOTIATE
		fnPoll()
	}
	OFFLINE:{
		myZeeVee.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myZeeVee.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'ZeeVee IP Error:[',myZeeVee.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(DEBUG_DEV,'ZV_RAW->',DATA.TEXT)
		
		// Telnet Negotiation
		WHILE(myZeeVee.Rx[1] == $FF && LENGTH_ARRAY(myZeeVee.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myZeeVee.Rx,3)
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
		WHILE(FIND_STRING(myZeeVee.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myZeeVee.Rx,"$0D,$0A",1),2))
		}	
		
		// Connection Established
		IF(FIND_STRING(myZeeVee.Rx,'Zyper$ ',1)){
			REMOVE_STRING(myZeeVee.Rx,'Zyper$ ',1)
			myZeeVee.IP_STATE = IP_STATE_CONNECTED
			fnSendFromQueue()
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_FUNCTION fnStoreProcessingDevice(){
	// Store Device if processing one
	IF(myZeeVee.ProcessingDevice.TYPE){
		STACK_VAR INTEGER d
		STACK_VAR INTEGER Found
		// Find and Store 
		fnDebug(DEBUG_DEV,'Storing Device',ITOA(myZeeVee.ProcessingDevice.NAME))
		FOR(d = 1; d <= LENGTH_ARRAY(vdvDevice); d++){
			IF(LENGTH_ARRAY(myZeeVee.DEVICE[d].NAME) && myZeeVee.DEVICE[d].NAME == myZeeVee.ProcessingDevice.NAME){
				myZeeVee.DEVICE[d] = myZeeVee.ProcessingDevice
				Found = TRUE
			}
		}
		// Report devices we aren't handling
		IF(!Found){
			fnDebug(DEBUG_ERR,'ZeeVee Unhandled Device:',"myZeeVee.ProcessingDevice.MAC,' (',myZeeVee.ProcessingDevice.NAME,')'")
		}
	}
	// Clear Out Device
	IF(1){
		STACK_VAR uDevice blankDevice
		myZeeVee.ProcessingDevice = blankDevice
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	
	fnDebug(DEBUG_STD,'ZV->',"'[',pDATA,']'")

	SELECT{
		ACTIVE('Success' = pDATA):{
			fnDebug(DEBUG_STD,'Response Ended',pDATA)
			// Store Device if processing
			fnStoreProcessingDevice()
			// Send next command
			myZeeVee.RESPONSE_PENDING = FALSE
			fnSendFromQueue()
		}
		ACTIVE(fnComparePrefix(pDATA,'Error')):{
			REMOVE_STRING(pDATA,':',1)
			SEND_STRING vdvServer,"'ERROR-',pDATA"
			// Send next command
			myZeeVee.RESPONSE_PENDING = FALSE
			fnSendFromQueue()
		}
		ACTIVE(1):{
			// Get Line Header
			STACK_VAR CHAR HEAD[50]
			HEAD = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,';',1),1))
			SELECT{
				ACTIVE(fnComparePrefix(HEAD,'server(')):{
					fnDebug(DEBUG_DEV,'Response Started',HEAD)
					IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
					TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
				ACTIVE(fnComparePrefix(HEAD,'device(')):{
					fnDebug(DEBUG_DEV,'Response Started',HEAD)
					// Store device if processing
					fnStoreProcessingDevice()
					// Do new device
					REMOVE_STRING(HEAD,'(',1)
					myZeeVee.ProcessingDevice.MAC = fnStripCharsRight(REMOVE_STRING(HEAD,')',1),1)
				}
				ACTIVE(1):{
					fnDebug(DEBUG_DEV,'Response Segment',HEAD)
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
						fnDebug(DEBUG_DEV,'Response Pair',"KEY,'=',VAL")
						SWITCH(HEAD){
							CASE 'server.gen':{
								SWITCH(KEY){
									CASE 'hostname':     myZeeVee.SERVER.HOST_NAME   = VAL
									CASE 'macAddress':   myZeeVee.SERVER.MAC_ADDRESS = VAL
									CASE 'serialNumber': myZeeVee.SERVER.SERIAL_NO   = VAL
									CASE 'uptime':       myZeeVee.SERVER.UPTIME      = VAL
									CASE 'version':      myZeeVee.SERVER.VERSION     = VAL
								}
							}
							CASE 'server.license':{
								SWITCH(KEY){
									CASE 'productID':    myZeeVee.SERVER.productID   = VAL
								}
							}
							CASE 'device.gen':{
								SWITCH(KEY){
									CASE 'type':{
										SWITCH(VAL){
											CASE 'encoder':myZeeVee.ProcessingDevice.TYPE = DEVICE_TYPE_ENCODER
											CASE 'decoder':myZeeVee.ProcessingDevice.TYPE = DEVICE_TYPE_DECODER
										}
									}
									CASE 'state':{
										SWITCH(VAL){
											CASE 'Down':myZeeVee.ProcessingDevice.STATE  = DEVICE_STATE_DOWN
											CASE 'Up':  myZeeVee.ProcessingDevice.STATE  = DEVICE_STATE_UP
										}
									}
									CASE 'model':     myZeeVee.ProcessingDevice.MODEL  = VAL
									CASE 'name':      myZeeVee.ProcessingDevice.NAME   = VAL
									CASE 'uptime':    myZeeVee.ProcessingDevice.UPTIME = VAL
								}
							}
							CASE 'device.temperature':{
								SWITCH(KEY){
									CASE 'main':		myZeeVee.ProcessingDevice.TEMPERATURE = ATOF(fnStripCharsRight(VAL,1))
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
							CASE 'TRUE':myZeeVee.DEBUG = DEBUG_STD
							CASE 'DEV': myZeeVee.DEBUG = DEBUG_DEV
							DEFAULT:		myZeeVee.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myZeeVee.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myZeeVee.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myZeeVee.IP_HOST = DATA.TEXT
							myZeeVee.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(DATA.TEXT,TRUE)
			}
			CASE 'JOIN':{
				// fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' fast-switched'",TRUE)
				fnAddToQueue("'join ',fnGetCSV(DATA.TEXT,1),' ',fnGetCSV(DATA.TEXT,2),' genlocked'",TRUE)
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
		name = myZeeVee.DEVICE[e].NAME
		// Enable / Disable Module
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':{
						myZeeVee.DEVICE[e].NAME = DATA.TEXT
					}
					CASE 'RS232':{
						fnAddToQueue("'set device ',name,' rs232 ',DATA.TEXT",TRUE)
					}
				}
			}
			CASE 'CHAN':{
				SWITCH(DATA.TEXT){
					CASE 'ENC':{
						STACK_VAR INTEGER x
						FOR(x = 1; x <= LENGTH_ARRAY(vdvDevice); x++){
							IF(DEVTOA(vdvDevice[x]) == DATA.TEXT){
								fnAddToQueue("'join ',myZeeVee.DEVICE[x].NAME,' ',name,' fast-switched'",TRUE)
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
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER d
	// Endpoints
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		FOR(d = 1; d <= LENGTH_ARRAY(vdvDevice); d++){
			[vdvDevice[d],251] = (myZeeVee.DEVICE[d].STATE == DEVICE_STATE_UP)
			[vdvDevice[d],252] = (myZeeVee.DEVICE[d].STATE == DEVICE_STATE_UP)
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

