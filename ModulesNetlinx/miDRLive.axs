MODULE_NAME='miDRLive'(DEV vdvControl, DEV vdvFaders[], DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic IP Control Module for Allen & Heath IDR Matrix
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uFader{
	INTEGER  ID;
	INTEGER  ID2;
	INTEGER  bMUTE;
	SINTEGER iLEVEL;
	SINTEGER MIN;
	SINTEGER MAX;
	SINTEGER STEP;
	INTEGER  bFADEOUT;
	SINTEGER iFADELVL;
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timeline IDs **)
LONG TLID_RETRY	= 1
LONG TLID_POLL		= 2
LONG TLID_FADE		= 3
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
(** Network / Comms **)
LONG TLT_RETRY[]				= {10000}
LONG TLT_POLL[]				= {10000}
LONG TLT_FADE[]				= {100}
INTEGER 	iIP_TCP_PORT 		= 51325					// TCP Port
CHAR 		cIP_TCP_ADD[15] 	= '000.000.000.000'	// Target IP Address
CHAR 		cINCBuffer[3000]
INTEGER 	bConnected;
INTEGER 	bTryingTCP;
(** General **)
INTEGER	bDEBUG;
(** Structures **)
uFader myFaders[128]
/******************************************************************************
	Init
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, cINCBuffer
}
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Try to open a connection **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(cIP_TCP_ADD == '000.000.000.000'){
		fnDebug(TRUE,'IDR Address Not Set','')
	}
	ELSE{
		fnDebug(FALSE,"'Connecting to IDR on Port ',ITOA(iIP_TCP_PORT),' on '",cIP_TCP_ADD)
		bTryingTCP = TRUE
		ip_client_open(ipDevice.port, cIP_TCP_ADD, iIP_TCP_PORT, IP_TCP)
	}
}
(** Force connection Closed **)
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipDevice.port)
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
	IF(bDEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
(** Standard Send Function **)

DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	IF(bConnected){
		fnDebug(FALSE,'AMX->IDR',pDATA)
		SEND_STRING ipDevice,pDATA
	}
	ELSE{
		fnDebug(FALSE,'AMX->IDR','Not Connected')
	}
	fnInitPolling();
}
(** Actviate / Reactivate Polling **)
DEFINE_FUNCTION fnInitPolling(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){
		TIMELINE_KILL(TLID_POLL)
	}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
/******************************************************************************
	Data Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{
		bTryingTCP = FALSE;
		bConnected = TRUE;
	}
	OFFLINE:{
		bConnected = FALSE;
		bTryingTCP = FALSE;
		fnTryConnection();
	}
	ONERROR:{
		STACK_VAR INTEGER bFORCE;
		STACK_VAR CHAR cMESSAGE[255];
		bTryingTCP = FALSE
		bConnected = FALSE
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
		fnDebug(bFORCE,"'IDR IP Error:[',cIP_TCP_ADD,']:'","'[',ITOA(DATA.NUMBER),']',cMESSAGE")
		fnTryConnection();
	}
	STRING:{
		fnDebug(FALSE,'IDR->AMX',"DATA.TEXT")

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
						cIP_TCP_ADD	= DATA.TEXT;
						IF(bConnected){
							fnCloseTCPConnection();
						}
						fnTryConnection();
					}
					CASE 'DEBUG':{ bDEBUG = ATOI(DATA.TEXT) }
				}
			}
			CASE 'CONNECTION':{
				SWITCH(DATA.TEXT){
					CASE 'BREAK':fnCloseTCPConnection();
					CASE 'MAKE': fnOpenTCPConnection();
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'SETGAIN':{
				fnSendCommand("$B0,$63,HEXTOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),$62,$17,$06,ATOI(DATA.TEXT)")
			}
			CASE 'SCENE':{
				fnSendCommand("$B0,$00,(ATOI(DATA.TEXT) > 128),$C0,ATOI(DATA.TEXT)")
			}
		}
	}
}

/******************************************************************************
	Fader Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvFaders]{
	COMMAND:{
		STACK_VAR INTEGER f;
		f = GET_LAST(vdvFaders)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':  myFaders[GET_LAST(vdvFaders)].ID   = HEXTOI(DATA.TEXT);
					CASE 'ID2':  myFaders[GET_LAST(vdvFaders)].ID2 = HEXTOI(DATA.TEXT);
					CASE 'MIN': myFaders[GET_LAST(vdvFaders)].MIN = ATOI(DATA.TEXT);
					CASE 'MAX': myFaders[GET_LAST(vdvFaders)].MAX = ATOI(DATA.TEXT);
					CASE 'STEP':myFaders[GET_LAST(vdvFaders)].STEP = ATOI(DATA.TEXT);
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'TOGGLE':	myFaders[f].bMUTE = !myFaders[f].bMUTE;
					CASE 'OFF':		myFaders[f].bMUTE = FALSE;
					CASE 'ON':		myFaders[f].bMUTE = TRUE;
					CASE '0':		myFaders[f].bMUTE = FALSE;
					CASE '1':		myFaders[f].bMUTE = TRUE;
				}
				SWITCH(myFaders[f].bMUTE){
					CASE TRUE:{
						fnSendCommand("$90,myFaders[f].ID,$7F,myFaders[f].ID,$00")
						fnSendCommand("$90,myFaders[f].ID2,$7F,myFaders[f].ID,$00")
					}
					CASE FALSE:{
						fnSendCommand("$90,myFaders[f].ID,$3F,myFaders[f].ID,$00")
						fnSendCommand("$90,myFaders[f].ID2,$3F,myFaders[f].ID,$00")
					}
				}
			}
			CASE 'FADEOUT':{
				SWITCH(DATA.TEXT){
					CASE 'GO':{
						IF(myFaders[f].STEP == 0){myFaders[f].STEP = 5}
						myFaders[f].iFADELVL = myFaders[f].iLEVEL;
						myFaders[f].bFADEOUT = TRUE;
						IF(!TIMELINE_ACTIVE(TLID_FADE)){
							TIMELINE_CREATE(TLID_FADE,TLT_FADE,LENGTH_ARRAY(TLT_FADE),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
						}
					}
					CASE 'RESET':{
						myFaders[f].bFADEOUT = FALSE;
						fnSendCommand("$B0,$63,myFaders[f].ID,$62,$17,$06,myFaders[f].iLEVEL")
					}
				}
			}
			CASE 'VOLUME_VAL':{
				myFaders[f].iLEVEL = ATOI(DATA.TEXT)
				myFaders[f].iFADELVL = ATOI(DATA.TEXT)
			}
			CASE 'VOLUME':{
				IF(myFaders[f].STEP == 0){ myFaders[f].STEP = 5 }
				IF(myFaders[f].MAX == 0){ myFaders[f].MAX = 127 }
				SWITCH(DATA.TEXT){
					CASE 'INC': myFaders[f].iLEVEL = myFaders[f].iLEVEL + myFaders[f].STEP;
					CASE 'DEC': myFaders[f].iLEVEL = myFaders[f].iLEVEL - myFaders[f].STEP;
					DEFAULT:		myFaders[f].iLEVEL = ATOI(DATA.TEXT);
				}
				IF(myFaders[f].iLEVEL < myFaders[f].MIN){
					myFaders[f].iLEVEL = myFaders[f].MIN
				}

				IF(myFaders[f].iLEVEL > myFaders[f].MAX){
					myFaders[f].iLEVEL = myFaders[f].MAX
				}
				fnSendCommand("$B0,$63,myFaders[f].ID, $62,$17,$06,myFaders[f].iLEVEL")
				fnSendCommand("$B0,$63,myFaders[f].ID2,$62,$17,$06,myFaders[f].iLEVEL")
				SEND_LEVEL vdvFaders[f],1,myFaders[f].iLEVEL
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_FADE]{
	STACK_VAR INTEGER iFADER;
	STACK_VAR INTEGER bACTIVE;
	FOR(iFADER = 1; iFADER <= LENGTH_ARRAY(vdvFaders); iFADER++){
		IF(myFaders[iFADER].bFADEOUT){
			myFaders[iFADER].iFADELVL = myFaders[iFADER].iFADELVL - myFaders[iFADER].STEP
			IF(myFaders[iFADER].iFADELVL > 0){
				bACTIVE = TRUE;
				fnSendCommand("$B0,$63,myFaders[iFADER].ID,$62,$17,$06,myFaders[iFADER].iFADELVL")
			}
			ELSE IF(myFaders[iFADER].iFADELVL <= 0){
				myFaders[iFADER].iFADELVL = 0;
				myFaders[iFADER].bFADEOUT = FALSE;
				fnSendCommand("$B0,$63,myFaders[iFADER].ID,$62,$17,$06,$00")
			}
		}
	}
	IF(!bACTIVE){
		TIMELINE_KILL(TLID_FADE)
	}
}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER f;
	FOR(f = 1; f <= LENGTH_ARRAY(vdvFaders); f++){
		[vdvFaders[f],198] = (myFaders[f].iFADELVL == 0)
		[vdvFaders[f],199] = (myFaders[f].bMUTE)
	}
	[vdvControl,251] = (bConnected)
}