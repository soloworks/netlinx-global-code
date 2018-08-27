MODULE_NAME='mTVOne1TMV'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic IP Control Module for Allen & Heath IDR Matrix
******************************************************************************/
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timeline IDs **)
LONG TLID_RETRY	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 3
LONG TLID_SEND    = 4
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uTVOneScaler{
	INTEGER DEBUG
	(** COMMS **)
	INTEGER 	isIP
	INTEGER 	TRYING
	INTEGER 	CONNECTED
	CHAR 		Rx[500]
	CHAR     Tx[500]
	CHAR 		IP_ADD[15]
	INTEGER 	IP_PORT
	INTEGER  VOLUME
	INTEGER  MUTE
}
DEFINE_VARIABLE
(** Network / Comms **)
LONG TLT_RETRY[]				= {10000}	
LONG TLT_POLL[]				= {15000}	
LONG TLT_COMMS[]				= {30000}	
LONG TLT_SEND[] = {200}	

(** General **)
uTVOneScaler myTVOneScaler
/******************************************************************************
	Init
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myTVOneScaler.Rx
	myTVOneScaler.isIP = !(dvDEVICE.NUMBER)
}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Try to open a connection **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myTVOneScaler.IP_ADD)){
		fnDebug(TRUE,'TVOne Address Not Set','')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to TVOne on Port ',ITOA(myTVOneScaler.IP_PORT),' on '",myTVOneScaler.IP_ADD)
		myTVOneScaler.TRYING = TRUE
		ip_client_open(dvDevice.port, myTVOneScaler.IP_ADD, myTVOneScaler.IP_PORT, IP_TCP) 
	}
} 
(** Force connection Closed **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
(** Delay and try a new connection **)
DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
(** Generic Debug Routine **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myTVOneScaler.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
(** Standard Send Function **)
DEFINE_FUNCTION fnAddToQueue(CHAR cmd[]){
	myTVOneScaler.Tx = "myTVOneScaler.Tx,cmd,$0D"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && FIND_STRING(myTVOneScaler.TX,"$0D",1)){
		STACK_VAR CHAR toSend[100]
		toSend = REMOVE_STRING(myTVOneScaler.TX,"$0D",1)
		fnDebug(FALSE,'AMX->TVOne',toSend)
		SEND_STRING dvDevice, toSend
		fnInitPoll()
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	fnSendFromQueue()
}

(** Process Feedback Packet **)
DEFINE_FUNCTION fnProcessFeedback(CHAR ThisResponse[]){
}

(** Actviate / Reactivate Polling **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}
(** Send Heartbeat / Poll **)
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('ATM 08 CSW_VER W')	// Request Software Version
}
/******************************************************************************
	Data Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myTVOneScaler.isIP){
			myTVOneScaler.TRYING 	= FALSE;
			myTVOneScaler.CONNECTED = TRUE;
		}
		ELSE{
			SEND_COMMAND dvDevice, 'SET MODE DATA' 
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		IF(myTVOneScaler.isIP){
			myTVOneScaler.CONNECTED = FALSE;
			myTVOneScaler.TRYING 	= FALSE;
			fnTryConnection();
		}
	}
	ONERROR:{
		STACK_VAR INTEGER bFORCE;
		STACK_VAR CHAR cMESSAGE[255];
		myTVOneScaler.CONNECTED = FALSE;
		myTVOneScaler.TRYING 	= FALSE;
		SWITCH(DATA.NUMBER){
			CASE 2:{ bFORCE = FALSE; cMessage = 'General Failure'}					//General Failure - Out Of Memory
			CASE 4:{ bFORCE = TRUE;  cMessage = 'Unknown Host'}						//Unknown Host
			CASE 6:{ bFORCE = FALSE; cMessage = 'Conn Refused'}						//Connection Refused
			CASE 7:{ bFORCE = TRUE;  cMessage = 'Conn Timed Out'}						//Connection Timed Out
			CASE 8:{ bFORCE = FALSE; cMessage = 'Unknown'}								//Unknown Connection Error
			CASE 9:{ bFORCE = FALSE; cMessage = 'Already Closed'}						//Already Closed
			CASE 10:{bFORCE = FALSE; cMessage = 'Binding Error'} 					//Binding Error
			CASE 11:{bFORCE = FALSE; cMessage = 'Listening Error'} 					//Listening Error
			CASE 14:{bFORCE = FALSE; cMessage = 'Local Port Already Used'}		//Local Port Already Used
			CASE 15:{bFORCE = FALSE; cMessage = 'UDP Socket Already Listening'} //UDP socket already listening
			CASE 16:{bFORCE = FALSE; cMessage = 'Too many open Sockets'}			//Too many open sockets
			CASE 17:{bFORCE = FALSE; cMESSAGE = 'Local port not Open'}				//Local Port Not Open
		}
		fnDebug(bFORCE,"'TVOne IP Error:[',myTVOneScaler.IP_ADD,']:'","'[',ITOA(DATA.NUMBER),']',cMESSAGE")
		fnTryConnection();
	}
	STRING:{
		fnDebug(FALSE,'TVOne->AMX',"DATA.TEXT")
		
		WHILE(FIND_STRING(myTVOneScaler.Rx,"$0D,$0A",1) > 0){
			IF(LEFT_STRING(myTVOneScaler.Rx,2) = "$0D,$0A") GET_BUFFER_STRING(myTVOneScaler.Rx,2)
			ELSE fnProcessFeedback(REMOVE_STRING(myTVOneScaler.Rx,"$0D,$0A",1));
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		SEND_STRING  vdvControl, 'RANGE-0,10'
		SEND_STRING  vdvControl, 'PROPERTY-GAIN,RANGE,0,10'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{ 
						myTVOneScaler.IP_ADD		= DATA.TEXT;
						myTVOneScaler.IP_PORT	= 23
						IF(myTVOneScaler.CONNECTED){
							fnCloseTCPConnection();
						}
						fnTryConnection();
					}
					CASE 'DEBUG':{ myTVOneScaler.DEBUG = (DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'CONNECTION':{
				SWITCH(DATA.TEXT){
					CASE 'BREAK':fnCloseTCPConnection();
					CASE 'MAKE': fnOpenTCPConnection();
				}
			}
			CASE 'RAW':fnAddToQueue(DATA.TEXT)
			CASE 'VOLUME':{
				myTVOneScaler.VOLUME = ATOI(DATA.TEXT)
				fnAddToQueue("'ATM 09 VOL_CRL W ',FORMAT('%01X',myTVOneScaler.VOLUME)")
				myTVOneScaler.MUTE = FALSE
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	  myTVOneScaler.MUTE = TRUE
					CASE 'OFF':	  myTVOneScaler.MUTE = FALSE
					CASE 'TOGGLE':myTVOneScaler.MUTE = !myTVOneScaler.MUTE
				}
				SWITCH(myTVOneScaler.MUTE){
					CASE TRUE:  fnAddToQueue("'ATM 09 AUD_MUT W 0'")
					CASE FALSE: fnAddToQueue("'ATM 09 AUD_MUT W F'")
				}
			}
			CASE 'LAYOUT':{
				fnAddToQueue("'ATM 0A TVO_LYT W ',FORMAT('%02d',ATOI(DATA.TEXT))")
			}
			CASE 'VMATRIX':{
				STACK_VAR INTEGER I
				STACK_VAR INTEGER O
				I = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				O = ATOI(DATA.TEXT)
				fnAddToQueue("'ATM 0A VDO_IPT W ',ITOA(O),' ',ITOA(I)")
			}
			CASE 'AMATRIX':{
				STACK_VAR INTEGER I
				STACK_VAR INTEGER O
				I = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				O = ATOI(DATA.TEXT)
				fnAddToQueue("'ATM 0A ADO_IPT W ',ITOA(I)")
			}
		}
	}
}

/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myTVOneScaler.VOLUME
	[vdvControl,199] = (myTVOneScaler.MUTE)
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}