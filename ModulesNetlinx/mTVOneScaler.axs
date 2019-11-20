MODULE_NAME='mTVOneScaler'(DEV vdvControl, DEV dvDevice)
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
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uTVOneScaler{
	INTEGER DEBUG
	(** COMMS **)
	INTEGER 	isIP
	INTEGER 	TRYING
	INTEGER 	CONNECTED
	CHAR 		Rx[3000]
	CHAR 		IP_ADD[15]
	INTEGER 	IP_PORT
}
DEFINE_VARIABLE
(** Network / Comms **)
LONG TLT_RETRY[]				= {10000}
LONG TLT_POLL[]				= {15000}
LONG TLT_COMMS[]				= {30000}

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
DEFINE_FUNCTION fnSendCommand(CHAR cmd[]){
	fnDebug(FALSE,'AMX->TVOne',"cmd,$0D")
	SEND_STRING dvDevice, "cmd,$0D"
	fnInitPoll();
}
DEFINE_FUNCTION fnSendCommand_NEW( CHAR pCHAN[2],CHAR pWIN[2], CHAR pOUT[2], CHAR pFUNC[2], CHAR pVAL[6]){
	STACK_VAR CHAR _BYTES[8][2]
	STACK_VAR INTEGER _CS
	STACK_VAR INTEGER x
	STACK_VAR CHAR ToSend[255]
	pVAL = fnPadLeadingChars(pVAL,'0',6)
	_BYTES[1] = '04';
	_BYTES[2] = pCHAN;
	_BYTES[3] = pWIN;
	_BYTES[4] = pOUT;
	_BYTES[5] = pFUNC;
	_BYTES[6] = LEFT_STRING(pVAL,2);
	_BYTES[7] = MID_STRING(pVAL,3,2);
	_BYTES[8] = RIGHT_STRING(pVAL,2);
	FOR(x = 1; x<=8; x++){
		_CS = _CS + HEXTOI(_BYTES[x])
	}
	ToSend =  "'F',_BYTES[1],pCHAN,pWIN,pOUT,pFUNC,pVAL,RIGHT_STRING(ITOHEX(_CS),2),$0D"
	fnDebug(FALSE,'AMX->TVOne',ToSend)
	SEND_STRING dvDevice, ToSend;
	fnInitPoll();
}
DEFINE_FUNCTION fnSendQuery(CHAR pCHAN[],CHAR pWIN[], CHAR pOUT[], CHAR pFUNC[]){
	STACK_VAR CHAR _BYTES[5][2]
	STACK_VAR INTEGER _CS
	STACK_VAR INTEGER x
	STACK_VAR CHAR ToSend[255]
	_BYTES[1] = '84';
	_BYTES[2] = pCHAN;
	_BYTES[3] = pWIN;
	_BYTES[4] = pOUT;
	_BYTES[5] = pFUNC;
	FOR(x = 1; x<=5; x++){
		_CS = _CS + HEXTOI(_BYTES[x])
	}
	//ToSend =  "'F',_BYTES[1],pCHAN,pWIN,pOUT,pFUNC,RIGHT_STRING(ITOHEX(_CS),2),$0D"
	ToSend =  "'F',_BYTES[1],pCHAN,pWIN,pOUT,pFUNC,'??',$0D"
	fnDebug(FALSE,'AMX->TVOne',ToSend)
	SEND_STRING dvDevice, ToSend;
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
	fnSendQuery('00','41','00','C4')
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
			SEND_COMMAND dvDevice, 'SET BAUD 57600 N 8 1 485 DISABLE'
		}
		fnPoll()
		fnInitPoll()
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

	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myTVOneScaler.IP_ADD		= DATA.TEXT;
						myTVOneScaler.IP_PORT	= 10001
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
			CASE 'PRESET':{
				SWITCH(DATA.TEXT){
					CASE '10':fnSendCommand("'F04104102250000108C'")
					CASE '1': fnSendCommand("'F04104102250000017D'")
					CASE '2': fnSendCommand("'F04104102250000027E'")
					CASE '3': fnSendCommand("'F04104102250000037F'")
					CASE '4': fnSendCommand("'F041041022500000480'")
					CASE '5': fnSendCommand("'F041041022500000581'")
					CASE '6': fnSendCommand("'F041041022500000682'")
					CASE '7': fnSendCommand("'F041041022500000783'")
					CASE '8': fnSendCommand("'F041041022500000884'")
					CASE '9': fnSendCommand("'F041041022500000985'")
				}
				WAIT 5{
					fnSendCommand("'F04104102260000017E'")
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'DVI1':fnSendCommand_NEW('00','41','00','82','000010')
					CASE 'DVI2':fnSendCommand_NEW('00','41','00','82','000011')
					CASE 'YC1': fnSendCommand_NEW('00','41','00','82','000040')
					CASE 'YV2': fnSendCommand_NEW('00','41','00','82','000041')
				}
			}
			CASE 'RGBTYPE':{
				STACK_VAR CHAR CHAN[2];
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DVI1':CHAN = '10'
					CASE 'DVI2':CHAN = '11'
				}
				IF(DATA.TEXT == '?'){
					fnSendQuery(CHAN,'41','00','C1');
				}
				ELSE{
					STACK_VAR INTEGER TYPE;
					SWITCH(DATA.TEXT){
						CASE 'AUTO':  TYPE = 8
						CASE 'D-RGB': TYPE = 6
						CASE 'D-YUV': TYPE = 11
						CASE 'A-RGB': TYPE = 10
						CASE 'A-YUV': TYPE = 12
						CASE 'CV/YC': TYPE = 5
						CASE 'A-CV':  TYPE = 13
						CASE 'A-YV':  TYPE = 14
						CASE 'B-RGB': TYPE = 15
						CASE 'B-YUV': TYPE = 16
						CASE 'B-CV':  TYPE = 17
						CASE 'B-YC':  TYPE = 18
					}
					IF(LENGTH_ARRAY(CHAN) && TYPE){
						fnSendCommand_NEW(CHAN,'41','00','C1',ITOHEX(TYPE))
					}
				}
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