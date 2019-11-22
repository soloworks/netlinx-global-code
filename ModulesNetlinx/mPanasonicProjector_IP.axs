MODULE_NAME='mPanasonicProjector_IP'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'md5'
/******************************************************************************
	Basic control of Panasonic Projector
	Verify model against functions

	vdvControl Commands
	DEBUG-X 				= Debugging Off (Default)
	INPUT-XXX 			= Go to Input, power on if required
		[VIDEO|SVIDEO|RGB1|RGB2|AUX|DVI]
	POWER-ON|OFF 		= Send input X to ouput Y
	FREEZE-ON|OFF		= Picture Freeze
	BLANK-ON|OFF		= Video Mute

******************************************************************************/
/******************************************************************************
	Module Constants
******************************************************************************/
//#DEFINE __TESTING__ 'TRUE'

DEFINE_CONSTANT
#IF_NOT_DEFINED __TESTING__
	INTEGER ProjectorTimeWarm = 45 // Time in Seconds {Warmup}
	INTEGER ProjectorTimeCool = 90 // Time in Seconds {Cooldown}
#ELSE
	#WARN 'TEMP SETTINGS IN PLACE!!!'
	INTEGER ProjectorTimeWarm = 5 // Time in Seconds {Warmup}
	INTEGER ProjectorTimeCool = 10 // Time in Seconds {Cooldown}
#END_IF
	(** Timeline Constants **)
INTEGER TLID_BUSY 	= 1;		// Warm / Cool Timeline
INTEGER TLID_AUTOADJ = 2;		// AutoAdjust Timeline
LONG TLID_POLL 		= 3		// Polling Timeline
LONG TLID_SEND			= 4		// Staggered Sending Timeline
LONG TLID_COMMS		= 5		// Comms Timeout Timeline
LONG TLID_BOOT			= 6;
LONG TLID_REPOLL		= 7;
LONG TLID_TIMEOUT		= 8;
	(** Channel Constants **)
INTEGER chnPicMute	= 211;
INTEGER chnFreeze		= 214;
INTEGER chnBUSY		= 250;
INTEGER chnCOMMS		= 251;
INTEGER chnWARM		= 253;
INTEGER chnCOOL		= 254;
INTEGER chnPOWER		= 255;
	(** POLLING **)
INTEGER pollPOWER		= 1
INTEGER pollSOURCE	= 2
INTEGER pollSHUTTER	= 3
INTEGER pollFREEZE	= 4
INTEGER pollASPECT	= 5
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
	(** Comms Variables **)
INTEGER _PORT			= 1024
char _IP[20]			= '000.NOT.SET.000'
INTEGER bConnOpen		= FALSE
INTEGER bResponsePending
INTEGER bTryingConn
CHAR cTxBuffer[1000]
CHAR cRxBuffer[1000]
CHAR cHASH[255]
CHAR cUSER[255] = 'admin1'
CHAR cPASS[255] = 'panasonic'
INTEGER lastPOLLED
	(** Debug Active / Inactive **)
INTEGER DEBUG 			= FALSE
	(** Input Cycling Variables **)
CHAR doINPUT[25]
CHAR cCurSource[3]
	(** Projector State Variables **)
INTEGER bPower		// Projector Power
INTEGER bFreeze	// Image Freeze
INTEGER bMute		// Picture Mute
INTEGER bWarming	// Projector Warming Up
INTEGER bCooling	// Projector Cooling Down
INTEGER iAspect	// Current Aspect as per Protocol
	(** Timeline Times **)
LONG TLT_SECOND[] 	= {1000};	// One second for timer use
LONG TLT_AUTOADJ[]	= {3000};	// Autoadjust 3 seconds after input change
LONG TLT_POLL[]		= {30000};	// Poll every 15 seconds
LONG TLT_COMMS[]		= {90000};	// Comms is dead if nothing recieved for 60s
LONG TLT_BOOT[]		= {10000};	// Give it 10 seconds for Boot to finish
LONG TLT_REPOLL[]		= {2000};	// Delay by 2 seconds, then start polling
LONG TLT_TIMEOUT[]	= {10000};	// Delay by 2 seconds, then start polling
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, cRxBuffer
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	fnDebug(FALSE,"'Opening TCP to Pana Proj Port ',ITOA(_PORT),' on'",_IP)
	bTryingConn = TRUE;
	ip_client_open(ipDevice.port, _IP, _PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(ipDevice.port);
	bConnOpen = FALSE;
}
	(** Start up the Polling Function **)
DEFINE_FUNCTION fnStartPolling(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}
DEFINE_FUNCTION fnRestartPoll(){
	IF(TIMELINE_ACTIVE(TLID_REPOLL)){ TIMELINE_KILL(TLID_REPOLL); }
	TIMELINE_CREATE(TLID_REPOLL,TLT_REPOLL,LENGTH_ARRAY(TLT_REPOLL),TIMELINE_ABSOLUTE,TIMELINE_ONCE);
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnSendQuery(){
	lastPOLLED = pollPOWER;
	fnSendCommand('QPW','');
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(INTEGER pFORCE, CHAR Msg[], CHAR MsgData[]){
	IF(DEBUG = 1 || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pPacket[]){
	(** COMMS **)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		TIMELINE_KILL(TLID_COMMS)
	}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	(** Do Data **)
	IF(LEFT_STRING(pPacket,9) == 'NTCONTROL'){
		GET_BUFFER_STRING(pPacket,12);
		fnDebug(FALSE,'CODE',pPacket)
		cHASH = fnEncryptToMD5("cUSER,':',cPASS,':',pPacket");
		bConnOpen = TRUE;
	}
	ELSE{
		SWITCH(lastPOLLED){
			CASE pollPOWER:{
				bPower = ATOI(pPacket);
				IF(bPower){
					lastPOLLED = pollSOURCE;
					fnSendCommand('QIN','');
				}
				ELSE{
					lastPOLLED = 0;
				}
			}
			CASE pollSOURCE:{
				cCurSource = RIGHT_STRING(pPacket,3);
				lastPOLLED = pollSHUTTER;
				fnSendCommand('QSH','');
			}
			CASE pollSHUTTER:{
				bMute = ATOI(pPacket);
				lastPOLLED = pollFREEZE;
				fnSendCommand('QFZ','');
			}
			CASE pollFREEZE:{
				bFreeze = ATOI(pPacket);
				lastPOLLED = pollASPECT;
				fnSendCommand('QSE','');
			}
			CASE pollASPECT:{
				iAspect = ATOI(pPacket);
				lastPOLLED = 0;
			}
		}
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR ThisCommand[], CHAR Param[]){
	STACK_VAR CHAR _ToSend[255];
	_ToSend = "'00','ADZZ;',ThisCommand";
	IF(LENGTH_ARRAY(Param)){ _ToSend = "_ToSend,':', Param" }
	_ToSend = "_ToSend,$0D";				//ETX
	cTxBuffer = "cTxBuffer,_ToSend"
	IF(bConnOpen && !bTryingConn){
		IF(!bResponsePending){
			fnSendCommand_INT();
		}
	}
	ELSE IF(!bTryingConn){
		fnOpenConnection()
	}
}
DEFINE_FUNCTION fnSendCommand_INT(){
	STACK_VAR CHAR _ToSend[255]
	_ToSend = "cHASH,REMOVE_STRING(cTxBuffer,"$0D",1)"
	fnDebug(FALSE,'AMX->Pana Proj',"_ToSend")
	SEND_STRING ipDevice, _ToSend;
	bResponsePending = TRUE;
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	OFFLINE:{
		bConnOpen = FALSE;
		bResponsePending = FALSE;
		bTryingConn = FALSE;
		cTxBuffer = ''
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
			TIMELINE_KILL(TLID_TIMEOUT)
		}
	}
	ONLINE:{
		bTryingConn = FALSE;
		fnDebug(FALSE,"'Connected to Pana Proj Port ',ITOA(_PORT),' on '",_IP)
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		bConnOpen = FALSE
		bResponsePending = FALSE
		bTryingConn = FALSE
		cTxBuffer = ''
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
			TIMELINE_KILL(TLID_TIMEOUT)
		}
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
		fnDebug(TRUE,"'Pana IP Error:[',_IP,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'Pana->AMX',DATA.TEXT);
		WHILE(FIND_STRING(cRxBuffer,"$0D",1)){
			bResponsePending = FALSE;
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cRxBuffer,"$0D",1),1));
		}
		IF(!bResponsePending && FIND_STRING(cTxBuffer,"$0D",1)){
			fnSendCommand_INT();
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		TIMELINE_CREATE(TLID_BOOT, TLT_BOOT, LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE);
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							_IP   = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							_IP   = DATA.TEXT
							_PORT = 1024
						}
						fnCloseConnection()
					}
					CASE 'DEBUG':{ DEBUG = ATOI(DATA.TEXT) }
				}
			}
			CASE 'CONNECT':{
				SWITCH(DATA.TEXT){
					CASE 'CLOSE':	fnCloseConnection()
					CASE 'OPEN':	fnOpenConnection()
				}
			}
			CASE 'AUTO':{
				SWITCH(DATA.TEXT){
					CASE 'ADJUST':		fnSendCommand('OAS','');
				}
			}
			CASE 'INPUT':{
				doINPUT = DATA.TEXT
				IF(bPower){
					fnSendInputCommand()
				}
				ELSE{
					SEND_COMMAND vdvControl, 'POWER-ON'
				}
			}
			CASE 'BLANK':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	bMute = TRUE;
					CASE 'OFF':	bMute = FALSE;
					CASE 'TOGGLE':	bMute = !bMute;
				}
				fnSendCommand('OSH',ITOA(bMUTE))
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnSendCommand('PON','');
						IF(!bPOWER && !bWarming && !bCooling){
							bWarming = TRUE;	// Warming Up
							TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
					CASE 'OFF':{
						fnSendCommand('POF','')
						IF(bPOWER){
							bPOWER 	= FALSE;
							bMute 	= FALSE;
							bFreeze 	= FALSE;
							bCooling = TRUE;
							TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,chnCOMMS] 	= ( TIMELINE_ACTIVE(TLID_COMMS) );
	[vdvControl,chnPOWER] 	= ( bPOWER );
	[vdvControl,chnCOOL]  	= ( bCooling );
	[vdvControl,chnWARM]  	= ( bWarming );
	[vdvControl,chnFreeze] 	= ( bFreeze );
	[vdvControl,chnPicMute] = ( bMute );
}
/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendQuery();
}
	(** Close connection after X amount of inactivity **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(bConnOpen){
		fnCloseConnection()
	}
}
	(** Boot Finished **)
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	fnSendQuery();
	fnStartPolling();
}
	(** Re-Poll Delay Elapsed **)
DEFINE_EVENT TIMELINE_EVENT[TLID_REPOLL]{
	fnStartPolling();
}
	(** Comms Timeout **)
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	bPower = FALSE;
}
/******************************************************************************
	Projector Warming / Cooling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	IF(bWarming && (ProjectorTimeWarm == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
		bPOWER = TRUE;			// Power
		bWarming = FALSE;		// Warming Up
		fnSendInputCommand() // Send an Input Command if required
	}
	ELSE IF(bCooling && (ProjectorTimeCool == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
		bCooling = FALSE;		// Cooling Down
	}
	IF(!bWarming && !bCooling){
		SEND_STRING vdvControl, "'TIME-0:00'"
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF(bWarming){ _TotalSecs = ProjectorTimeWarm }
		IF(bCooling){ _TotalSecs = ProjectorTimeCool }

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;

		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"

		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

/******************************************************************************
	Input Control Code
******************************************************************************/
DEFINE_FUNCTION fnSendInputCommand(){
	SWITCH(doINPUT){
		  CASE 'VIDEO':	fnSendCommand('IIS','VID');
		  CASE 'SVIDEO':	fnSendCommand('IIS','SVD');
		  CASE 'VGA1':		fnSendCommand('IIS','RG1');
		  CASE 'VGA2':		fnSendCommand('IIS','RG2');
		  CASE 'AUX':		fnSendCommand('IIS','AUX');
		  CASE 'DVI1':		fnSendCommand('IIS','DVI');
		  CASE 'HDMI1':		fnSendCommand('IIS','HD1');
	}
	IF(TIMELINE_ACTIVE(TLID_AUTOADJ)){TIMELINE_KILL(TLID_AUTOADJ)}
	SWITCH(doINPUT){
		CASE 'RGB1':
		CASE 'RGB2':{
			TIMELINE_CREATE(TLID_AUTOADJ,TLT_AUTOADJ,LENGTH_ARRAY(TLT_AUTOADJ),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	doINPUT = ''
}
	(** Auto Adjust input after source change **)
DEFINE_EVENT TIMELINE_EVENT[TLT_AUTOADJ]{
	SEND_COMMAND vdvControl, 'AUTO-ADJUST'
}

