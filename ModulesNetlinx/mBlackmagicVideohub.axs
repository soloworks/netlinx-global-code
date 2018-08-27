MODULE_NAME='mBlackmagicVideohub'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic IP Control Module for Allen & Heath IDR Matrix
******************************************************************************/
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_TYPE STRUCTURE BMVidHub{
	(** COMMS **)	
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[255]
	CHAR 		Rx[3000]
	CHAR		TxVid[2000]
	CHAR		Tx[2000]
	INTEGER  TxPEND
	INTEGER 	CONN_STATE
	INTEGER	DEBUG
	INTEGER	RxFbType
	(** State **)
	CHAR		PROTOCOL_VER[10]
	CHAR		UID[30]
	CHAR		MODEL[50]
	INTEGER	SRC[40]
	INTEGER	IO[2]
}
DEFINE_CONSTANT
(** Timeline IDs **)
LONG TLID_RETRY	= 1
LONG TLID_POLL		= 2
LONG TLID_TIMEOUT	= 3
LONG TLID_COMMS	= 4

INTEGER CONN_STATE_OFFLINE 	= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER CMD_TYPE_VIDSWITCH	= 1
INTEGER CMD_TYPE_OTHER		= 2

DEFINE_CONSTANT
INTEGER FB_TYPE_ROUTE 		= 1
INTEGER FB_TYPE_META 		= 2
INTEGER FB_TYPE_PREAMBLE 	= 3
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
(** Network / Comms **)
VOLATILE BMVidHub myBMVidHub
LONG TLT_RETRY[]				= { 10000 }
LONG TLT_POLL[]				= { 30000 }
LONG TLT_TIMEOUT[]			= {  5000 }
LONG TLT_COMMS[]				= { 90000 }
/******************************************************************************
	Init
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, myBMVidHub.Rx
}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Try to open a connection **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'BM Connecting to ',"myBMVidHub.IP_HOST,':',ITOA(myBMVidHub.IP_PORT)")
	myBMVidHub.CONN_STATE = CONN_STATE_CONNECTING
	IP_CLIENT_OPEN(ipDevice.port, myBMVidHub.IP_HOST, myBMVidHub.IP_PORT, IP_TCP) 
} 
(** Force connection Closed **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
}

DEFINE_FUNCTION fnReTryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
(** Generic Debug Routine **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myBMVidHub.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}


DEFINE_FUNCTION fnAddToQueue(INTEGER pCMD,CHAR pDATA[]){
	SWITCH(pCMD){
		CASE CMD_TYPE_VIDSWITCH:	myBMVidHub.TxVid = "myBMVidHub.TxVid,pDATA,$0A"
		DEFAULT:							myBMVidHub.Tx = "myBMVidHub.Tx,pDATA,$0A"
	}
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(myBMVidHub.CONN_STATE == CONN_STATE_CONNECTED && !myBMVidHub.TxPend){
		STACK_VAR CHAR toSend[1000]
		SELECT{
			ACTIVE(LENGTH_ARRAY(myBMVidHub.TxVid)):{
				toSend = "'VIDEO OUTPUT ROUTING:',$0A"
				WHILE(FIND_STRING(myBMVidHub.TxVid,"$0A",1)){
					toSend = "toSend,REMOVE_STRING(myBMVidHub.TxVid,"$0A",1)"
					toSend = "toSend,$0A"
				}
			}
			ACTIVE(FIND_STRING(myBMVidHub.Tx,"$0A",1)):{
				toSend = "toSend,REMOVE_STRING(myBMVidHub.Tx,"$0A",1)"
				toSend = "toSend,$0A"
			}
		}
		IF(LENGTH_ARRAY(ToSend)){
			fnDebug(FALSE,'->BMV',ToSend)
			SEND_STRING ipDevice, ToSend
			myBMVidHub.TxPEND = TRUE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			fnInitPoll()
		}
	}
}


(** Process Feedback Packet **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){	
	// Debugging Feedback
	SWITCH(LENGTH_ARRAY(pDATA)){
		CASE 0:	fnDebug(FALSE,'BMV->','END MARKER')
		DEFAULT: fnDebug(FALSE,'BMV->',pDATA)
	}
	
	// Check if this is a header
	SWITCH(pDATA){
		CASE '':{
			myBMVidHub.RxFbType 	= FALSE
			myBMVidHub.TxPend		= FALSE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			fnSendFromQueue()
		}
		CASE 'VIDEO OUTPUT ROUTING:': myBMVidHub.RxFbType = FB_TYPE_ROUTE
		CASE 'PROTOCOL PREAMBLE:': 	myBMVidHub.RxFbType = FB_TYPE_PREAMBLE
		CASE 'VIDEOHUB DEVICE:':		myBMVidHub.RxFbType = FB_TYPE_META
		DEFAULT:{
			SWITCH(myBMVidHub.RxFbType){
				CASE FB_TYPE_PREAMBLE:{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
						CASE 'Version':myBMVidHub.PROTOCOL_VER = fnRemoveWhiteSpace(pDATA)
					}
				}
				CASE FB_TYPE_META:{
					SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
						CASE 'Unique ID':myBMVidHub.MODEL = fnRemoveWhiteSpace(pDATA)
						CASE 'Model Name':myBMVidHub.MODEL = fnRemoveWhiteSpace(pDATA)
						CASE 'Video inputs':myBMVidHub.IO[1] = ATOI(pDATA)
						CASE 'Video outputs':myBMVidHub.IO[2] = ATOI(pDATA)
					}
				}
				CASE FB_TYPE_ROUTE:{
					myBMVidHub.SRC[ATOI(REMOVE_STRING(pDATA,' ',1))+1] = ATOI(pDATA)
				}
			}
		}
	}
	
	// Start Communications Timer
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

(** Actviate / Reactivate Polling **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
(** Send Heartbeat / Poll **)
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue(CMD_TYPE_OTHER,'PING:')
}
/******************************************************************************
	Data Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		myBMVidHub.CONN_STATE 	= CONN_STATE_CONNECTED
	}
	OFFLINE:{
		myBMVidHub.CONN_STATE = CONN_STATE_OFFLINE
		myBMVidHub.TxPEND = FALSE
		myBMVidHub.Tx = ''
		myBMVidHub.TxVid = ''
		myBMVidHub.Rx = ''
		fnReTryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR pMsg[255];

		SWITCH(DATA.NUMBER){
			CASE 14:{pMsg = 'Local Port Already Used'}		//Local Port Already Used
			DEFAULT:{
				SWITCH(DATA.NUMBER){
					CASE 2:{ pMsg = 'General Failure'}					//General Failure - Out Of Memory
					CASE 4:{ pMsg = 'Unknown Host'}						//Unknown Host
					CASE 6:{ pMsg = 'Conn Refused'}						//Connection Refused
					CASE 7:{ pMsg = 'Conn Timed Out'}						//Connection Timed Out
					CASE 8:{ pMsg = 'Unknown'}								//Unknown Connection Error
					CASE 9:{ pMsg = 'Already Closed'}						//Already Closed
					CASE 10:{pMsg = 'Binding Error'} 					//Binding Error
					CASE 11:{pMsg = 'Listening Error'} 					//Listening Error
					CASE 15:{pMsg = 'UDP Socket Already Listening'} //UDP socket already listening
					CASE 16:{pMsg = 'Too many open Sockets'}			//Too many open sockets
					CASE 17:{pMsg = 'Local port not Open'}				//Local Port Not Open
				}
			}
		}
		fnDebug(TRUE,"'BMV IP Error:[',myBMVidHub.IP_HOST,']:'","'[',ITOA(DATA.NUMBER),']',pMSG")
		myBMVidHub.CONN_STATE = CONN_STATE_OFFLINE
		myBMVidHub.TxPEND = FALSE
		myBMVidHub.Tx = ''
		myBMVidHub.TxVid = ''
		myBMVidHub.Rx = ''
		fnReTryConnection()
	}
	STRING:{
		fnDebug(FALSE,'RAW->',"DATA.TEXT")
		WHILE(FIND_STRING(myBMVidHub.Rx,"$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myBMVidHub.Rx,"$0A",1),1))
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myBMVidHub.IP_HOST	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myBMVidHub.IP_PORT	= ATOI(DATA.TEXT)
						}
						ELSE{
							myBMVidHub.IP_HOST = DATA.TEXT
							myBMVidHub.IP_PORT = 9990
						}
						fnOpenTCPConnection()
						fnInitPoll()
					}
					CASE 'DEBUG':{
						myBMVidHub.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT = 'TRUE')
					}
				}
			}
			CASE 'VMATRIX':{
				STACK_VAR INTEGER pIn
				STACK_VAR INTEGER pOut
				pIn 	= ATOI( fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1) )
				pOut  = ATOI( DATA.TEXT )
				fnAddToQueue(CMD_TYPE_VIDSWITCH,"ITOA(pOut-1),' ',ITOA(pIn-1)")
			}
		}
	}
}

/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}