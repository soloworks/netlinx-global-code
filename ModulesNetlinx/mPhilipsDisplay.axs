MODULE_NAME='mPhilipsDisplay'(DEV vdvControl, DEV dvDevice)
/******************************************************************************
	Basic control of Philips Projector
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uPhilipsDisplay{
	(** Current State **)
	INTEGER 	POWER
	INTEGER	INPUT
	CHAR		META_MODEL[20]
	CHAR		META_FW[20]
	(** Desired State **)
	INTEGER 	desINPUT
	INTEGER 	desPOWER
	(** Comms **)
	INTEGER	isIP
	INTEGER	IP_PORT
	CHAR 		IP_HOST[255]
	INTEGER	CONN_STATE
	INTEGER	DEBUG
	CHAR		Tx[500]
	INTEGER	TxPend
	CHAR		Rx[500]
}
DEFINE_CONSTANT
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2
LONG TLID_RETRY 			= 3
LONG TLID_TIMEOUT			= 4

DEFINE_VARIABLE

VOLATILE uPhilipsDisplay myPhilipsDisplay

LONG TLT_POLL[] 		= {15000}	// Poll Time
LONG TLT_COMMS[]		= {90000}	// Comms Timeout
LONG TLT_TIMEOUT[]	= {10000}	// Comms Timeout

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER chnFreeze		= 211		// Picture Freeze Feedback
INTEGER chnVidMute	= 214		// Picture Mute Feedback
INTEGER chnPOWER		= 255		// Proj Power Feedback
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myPhilipsDisplay.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, myPhilipsDisplay.Rx
}
/******************************************************************************
	Communication Helper Functions
******************************************************************************/
	(** Open a Network Connection **)	
DEFINE_FUNCTION fnOpenConnection(){  
	IF(myPhilipsDisplay.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(FALSE,"'Connecting Philips on'","myPhilipsDisplay.IP_HOST,':',ITOA(myPhilipsDisplay.IP_PORT)")
		myPhilipsDisplay.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myPhilipsDisplay.IP_HOST, myPhilipsDisplay.IP_PORT, IP_TCP) 
	}
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(dvDevice.port);
}

/******************************************************************************
	Polling Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}

DEFINE_FUNCTION fnPoll(){
	IF(!LENGTH_ARRAY(myPhilipsDisplay.META_MODEL)){
		fnAddToQueue("$A1,$00")	// Model Query
	}
	fnAddToQueue("$19")	// Power Query
	fnAddToQueue("$AD")	// Input Query
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{	// Poll Device
	fnPoll()
}
/******************************************************************************
	Communication Sending Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[255]){
	myPhilipsDisplay.Tx = "myPhilipsDisplay.Tx,pCMD,$0A,$0B,$0C"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myPhilipsDisplay.TxPend && myPhilipsDisplay.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myPhilipsDisplay.Tx,"$0A,$0B,$0C",1)){
		STACK_VAR CHAR toSend[255]
		toSend = fnStripCharsRight(REMOVE_STRING(myPhilipsDisplay.Tx,"$0A,$0B,$0C",1),3)
		// Add Group
		toSend = "$00,toSend"
		// Add MonitorID
		toSend = "$01,toSend"
		// Add Length - with checksum 
		toSend = "LENGTH_ARRAY(toSend)+2,toSend"
		IF(1){
			INTEGER chkSum
			INTEGER x
			chkSum = toSend[1]
			FOR(x = 2; x <= LENGTH_ARRAY(toSend); x++){
				chkSum = chkSum BXOR toSend[x]
			}
			toSend = "toSend,chkSum"
		}
		fnDebug(FALSE,'->PHI',"fnBytesToString(toSend)")
		SEND_STRING dvDevice,toSend
		myPhilipsDisplay.TxPend = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(FIND_STRING(myPhilipsDisplay.Tx,"$0A,$0B,$0C",1) && myPhilipsDisplay.CONN_STATE == CONN_STATE_OFFLINE && myPhilipsDisplay.isIP){
		fnOpenConnection()
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{	// Comms Timeout
	IF(myPhilipsDisplay.isIP){
		fnCloseConnection()
	}
	myPhilipsDisplay.Tx = ''
	myPhilipsDisplay.TxPend = FALSE
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myPhilipsDisplay.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION INTEGER fnGetInputByte(CHAR pInp[]){
	SWITCH(pInp){
		CASE 'HDMI1':	RETURN $0D
		CASE 'HDMI2':	RETURN $06
		CASE 'HDMI3':	RETURN $0F
		CASE 'VGA':		RETURN $05
	}
}
/******************************************************************************
	Feedback Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	
	STACK_VAR INTEGER pLEN

	fnDebug(FALSE,'PHI->',fnBytesToString(pDATA))
	
	pLEN = GET_BUFFER_CHAR(pDATA)		// Pull Off Length
	GET_BUFFER_CHAR(pDATA)				// Pull Off Control
	GET_BUFFER_CHAR(pDATA)				// Pull Off Group
	
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE $19:{	// Power Response
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE $01:myPhilipsDisplay.POWER = FALSE
				CASE $02:myPhilipsDisplay.POWER = TRUE
			}
		}
		CASE $A1:{	// Model
			myPhilipsDisplay.META_MODEL = fnStripCharsRight(pDATA,1)
		}
		CASE $AD:{	// Input
			IF(myPhilipsDisplay.INPUT != pDATA[1]){
				myPhilipsDisplay.INPUT = GET_BUFFER_CHAR(pDATA)
				IF(myPhilipsDisplay.INPUT != myPhilipsDisplay.desINPUT && myPhilipsDisplay.desINPUT != 0){
					fnAddToQueue("$AC,myPhilipsDisplay.desInput,$09,$01,$00")
					myPhilipsDisplay.desInput = 0
				}
			}
		}
	}
	
	// Set Timeout
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	
	myPhilipsDisplay.TxPend = FALSE
	fnSendFromQueue()

}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{   
	ONLINE:{
			myPhilipsDisplay.CONN_STATE = CONN_STATE_CONNECTED
		IF(myPhilipsDisplay.isIP){
			fnDebug(FALSE,'Connected to Philips on',"myPhilipsDisplay.IP_HOST,':',ITOA(myPhilipsDisplay.IP_PORT)")
			fnSendFromQueue()
		}
		ELSE{
			SEND_COMMAND DATA.DEVICE,'SET MODE DATA'
			SEND_COMMAND DATA.DEVICE,'SET BAUD 9600 N,8,2 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
		
	}   
	OFFLINE:{
		myPhilipsDisplay.CONN_STATE = CONN_STATE_OFFLINE
		myPhilipsDisplay.Tx = ''
		myPhilipsDisplay.TxPend = FALSE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	}  
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myPhilipsDisplay.CONN_STATE = CONN_STATE_OFFLINE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
		SWITCH(DATA.NUMBER){
			CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
			CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
			CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		fnDebug(TRUE,"'Philips IP ERR:[',myPhilipsDisplay.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'RAW->',fnBytesToString(myPhilipsDisplay.Rx))
		fnProcessFeedback(GET_BUFFER_STRING(myPhilipsDisplay.RX,myPhilipsDisplay.RX[1]))
		myPhilipsDisplay.Rx = ''
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{	// Control Events
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myPhilipsDisplay.IP_HOST 	= DATA.TEXT
						myPhilipsDisplay.IP_PORT	= 5000
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						myPhilipsDisplay.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'RAW':fnAddToQueue(DATA.TEXT)
			
			CASE 'INPUT':{
				myPhilipsDisplay.desInput = fnGetInputByte(DATA.TEXT)
				
				IF(myPhilipsDisplay.POWER){
					fnAddToQueue("$AC,myPhilipsDisplay.desInput,$09,$01,$00")
				}
				ELSE{
					fnAddToQueue("$18,$02")
				}
			}
			
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnAddToQueue("$18,$02")
					}
					CASE 'OFF':{
						fnAddToQueue("$18,$01")
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,chnPOWER] 	= ( myPhilipsDisplay.POWER)
}
/******************************************************************************
	EoF
******************************************************************************/


