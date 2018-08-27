MODULE_NAME='mChristieLSeries'(DEV vdvControl,DEV dvDEV)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/23/2013  AT: 23:39:05        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic module tested on the Christie 775G
	
******************************************************************************/
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uChristieL{
	(** Current State **)
	INTEGER POWER
	CHAR INPUT[2]
	INTEGER VMUTE
	INTEGER FREEZE
	INTEGER WARMING
	INTEGER COOLING
	(** Desired State **)
	CHAR 	  desINPUT[2]
	INTEGER desVMUTE
	INTEGER desFREEZE
	INTEGER desPOWER
	(** Comms **)
	INTEGER isIP
	INTEGER PORT
	CHAR IP[128]
	INTEGER TRYING
	INTEGER CONNECTED
	INTEGER DEBUG
	CHAR LASTPOLL[20]
	CHAR Tx[500]
	CHAR Rx[500]
}
DEFINE_CONSTANT
LONG TLID_POLL				= 1
LONG TLID_COMMS			= 2
LONG TLID_RETRY 			= 3
LONG TLID_SEND				= 4
LONG TLID_BUSY 			= 5
LONG TLID_AUTOADJ 		= 6
LONG TLID_TIMEOUT			= 7

INTEGER defPORT			= 23

INTEGER chnWARM		= 253
INTEGER chnCOOL		= 254

INTEGER desTRUE		= 2
INTEGER desFALSE		= 1

DEFINE_VARIABLE
uChristieL myChristieL
LONG TLT_POLL[]  	 = { 20000 }
LONG TLT_TIMEOUT[] = { 10000 }
LONG TLT_COMMS[] 	 = { 300000}
LONG TLT_RETRY[] 	 = { 10000 }
LONG time_SECOND[] = { 1000  }
LONG TLT_SEND[]	 = { 100   }

INTEGER ProjectorTimeWarm = 45 // Time in Seconds {Warmup}
INTEGER ProjectorTimeCool = 90 // Time in Seconds {Cooldown}

DEFINE_START{
	CREATE_BUFFER dvDEV, myChristieL.Rx
	myChristieL.isIP = !dvDEV.NUMBER
}
/******************************************************************************
	Utility Functions - Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!myChristieL.PORT){myChristieL.PORT = defPORT}
	fnDebug(FALSE,"'TRY','[',ITOA(dvDEV.PORT),']->CHR'","myChristieL.IP,':',ITOA(myChristieL.PORT)")
	myChristieL.TRYING = TRUE
	ip_client_open(dvDEV.port, myChristieL.IP, myChristieL.PORT, IP_TCP) 
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDEV.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnTryConnection()
}
DEFINE_FUNCTION fnInitTimeout(){	
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection()
}
/******************************************************************************
	Utility Functions - Data Sending
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCmd[]){
	myChristieL.Tx = "myChristieL.Tx,$BE,$EF,$03,$06,$00,pCmd,$0A,$0B,$0C"
	IF(!myChristieL.isIP || myChristieL.CONNECTED){ fnActualSend()}
	ELSE IF(!myChristieL.TRYING){ fnOpenTCPConnection() }
	fnInitPoll()
}
DEFINE_FUNCTION fnSendQuery(CHAR pCmd[]){
	myChristieL.Tx = "myChristieL.Tx,$BE,$EF,$03,$06,$00,pCmd,$0A,$0B,$0C"
	IF(!myChristieL.isIP || myChristieL.CONNECTED){ fnActualSend()}
	ELSE IF(!myChristieL.TRYING){ fnOpenTCPConnection() }
}
DEFINE_FUNCTION fnActualSend(){
	IF(!TIMELINE_ACTIVE(TLID_SEND) && FIND_STRING(myChristieL.Tx,"$0A,$0B,$0C",1)){
		STACK_VAR CHAR toSend[100]
		toSend = REMOVE_STRING(myChristieL.Tx,"$0A,$0B,$0C",1)
		toSend = fnStripCharsRight(toSend,3)
		IF(myChristieL.isIP){
			fnDebug(FALSE,'AMX->CHR',toSend)
			fnInitTimeout()
		}
		SEND_STRING dvDEV,toSend
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	fnActualSend()
}
/******************************************************************************
	Utility Functions - Data Recieve
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){	
	fnDebug(FALSE,'CHR->AMX',pData)
	IF(GET_BUFFER_CHAR(pDATA) == $1D){
		SWITCH(myChristieL.LASTPOLL){
			CASE 'POWER':{
				myChristieL.POWER = pData[1]
				IF(myChristieL.POWER){
					myChristieL.LASTPOLL = 'VMUTE'
					fnSendCommand("$C8,$D8,$02,$00,$20,$30,$00,$00")
				}
			}
			CASE 'VMUTE':myChristieL.VMUTE = pData[1]
		}
		myChristieL.LASTPOLL = ''
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	fnInitTimeout()
}
/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendInputCommand(){
	SWITCH(myChristieL.desINPUT){
		CASE 'PC1':		fnSendCommand("$FE,$D2,$01,$00,$00,$20,$00,$00")
		CASE 'PC2':		fnSendCommand("$3E,$D0,$01,$00,$00,$20,$04,$00")
		CASE 'HDMI1':	fnSendCommand("$0E,$D2,$01,$00,$00,$20,$03,$00")
		CASE 'HDMI2':	fnSendCommand("$6E,$D6,$01,$00,$00,$20,$0D,$00")
		CASE 'COMP':	fnSendCommand("$AE,$D1,$01,$00,$00,$20,$05,$00")
		CASE 'SVIDEO':	fnSendCommand("$9E,$D3,$01,$00,$00,$20,$02,$00")
		CASE 'VIDEO':	fnSendCommand("$6E,$D3,$01,$00,$00,$20,$01,$00")
	}
	SWITCH(myChristieL.desINPUT){
		CASE 'PC1':
		CASE 'PC2':{
			IF(TIMELINE_ACTIVE(TLID_AUTOADJ)){TIMELINE_KILL(TLID_AUTOADJ)}
			TIMELINE_CREATE(TLID_AUTOADJ,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
		}
	}
	myChristieL.desINPUT = ''
}

DEFINE_EVENT TIMELINE_EVENT[TLID_AUTOADJ]{
	IF(TIMELINE.REPETITION == 3){
		TIMELINE_KILL(TLID_AUTOADJ)
		SEND_COMMAND vdvControl, 'ADJUST-AUTO'
	}
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myChristieL.DEBUG || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

/******************************************************************************
	Polling Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	myChristieL.LASTPOLL = 'POWER'
	fnSendCommand("$19,$D3,$02,$00,$00,$60,$00,$00")
}
/******************************************************************************
	Physical Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDEV]{
	ONLINE:{
		IF(myChristieL.isIP){
			fnDebug(FALSE,"'CONN','[',ITOA(dvDEV.PORT),']->CHR'","myChristieL.IP,':',ITOA(myChristieL.PORT)")
			myChristieL.CONNECTED = TRUE
			myChristieL.TRYING = FALSE
			fnActualSend()
			fnInitTimeout()
		}
		ELSE{
			SEND_COMMAND dvDEV,'SET MODE DATA'
			SEND_COMMAND dvDEV,'SET BAUD 19200 N 8 1 485 DISABLE'
			fnPoll()
			fnInitPoll()
		}
	}
	OFFLINE:{
		myChristieL.CONNECTED = FALSE;
		myChristieL.TRYING = FALSE;
		myChristieL.Tx = ''
	}
	ONERROR:{
		myChristieL.CONNECTED = FALSE
		myChristieL.TRYING = FALSE
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}					//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}					//Already Closed
			CASE 10:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE, "'HIT IP Error:[',myChristieL.IP,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		myChristieL.Tx = ''
	}
	STRING:{
		fnProcessFeedback(DATA.TEXT);
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{		
						myChristieL.IP = DATA.TEXT
						fnPoll()
						fnInitPoll()
					}
					CASE 'PORT':{		
						myChristieL.PORT = ATOI(DATA.TEXT)
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG': 	myChristieL.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');	
				}
			}
			CASE 'ADJUST':{
				SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnSendCommand("$70,$30,$39")
				}
			}
			CASE 'INPUT':{
				myChristieL.desINPUT = DATA.TEXT
				IF(myChristieL.POWER){
					fnSendInputCommand()
				}
				ELSE{
					SEND_COMMAND vdvControl, 'POWER-ON'
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'MUTE':{	
				SWITCH(DATA.TEXT){
					CASE 'ON':	myChristieL.desVMUTE = desTRUE;  myChristieL.VMUTE = TRUE
					CASE 'OFF':	myChristieL.desVMUTE = desFALSE; myChristieL.VMUTE = FALSE
					CASE 'TOGGLE':{
						IF(myChristieL.desVMUTE){myChristieL.desVMUTE = (!myChristieL.desVMUTE-1)+1}
						ELSE{myChristieL.desVMUTE = (!myChristieL.VMUTE) + 1}
					}
				}
				SWITCH(myChristieL.desVMUTE){
					CASE desTRUE:  fnSendCommand("$6B,$D9,$01,$00,$20,$30,$01,$00")
					CASE desFALSE: fnSendCommand("$FB,$D8,$01,$00,$20,$30,$00,$00")
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						myChristieL.desPOWER = desTRUE
						fnSendCommand("$BA,$D2,$01,$00,$00,$60,$01,$00")
						IF(!myChristieL.POWER && !myChristieL.COOLING){
							myChristieL.WARMING = TRUE	// Warming Up
							TIMELINE_CREATE(TLID_BUSY,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
						}
					}
					CASE 'OFF':{
						myChristieL.desPOWER = desFALSE
						fnSendCommand("$2A,$D3,$01,$00,$00,$60,$00,$00")
						myChristieL.desVMUTE = 0
						IF(myChristieL.POWER){
							myChristieL.COOLING = TRUE	// Cooling Down
							TIMELINE_CREATE(TLID_BUSY,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	IF(myChristieL.WARMING && (ProjectorTimeWarm == TIMELINE.REPETITION) ){
		TIMELINE_KILL(TLID_BUSY);
		myChristieL.POWER = TRUE	// Power
		myChristieL.WARMING = FALSE
		fnSendInputCommand()
	}
	ELSE IF(myChristieL.COOLING && (ProjectorTimeCool == TIMELINE.REPETITION) ){
		TIMELINE_KILL(TLID_BUSY);
		myChristieL.POWER = FALSE
		myChristieL.COOLING = FALSE
	}
	IF(!myChristieL.COOLING && !myChristieL.WARMING){
		SEND_STRING vdvControl, "'TIME-0:00'"
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF(myChristieL.WARMING){
			_TotalSecs = ProjectorTimeWarm
		}
		IF(myChristieL.COOLING){
			_TotalSecs = ProjectorTimeCool
		}

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;
		  
		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"
		
		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

DEFINE_PROGRAM{
	[vdvControl,211] = (myChristieL.VMUTE)
	[vdvControl,214] = (myChristieL.FREEZE)
	[vdvControl,251] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,252] = TIMELINE_ACTIVE(TLID_COMMS)
	[vdvControl,253] = (myChristieL.WARMING)
	[vdvControl,254] = (myChristieL.COOLING)
	[vdvControl,255] = (myChristieL.POWER)
}