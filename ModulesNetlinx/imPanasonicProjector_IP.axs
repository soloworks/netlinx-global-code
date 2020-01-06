MODULE_NAME='imPanasonicProjector_IP'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
INCLUDE 'md5'
/******************************************************************************
	Basic control of Panasonic Projector
	Verify model against functions

	vdvControl Commands
	DEBUG-X 				= Debugging Off (Default)
	INPUT-XXX 			= Go to Input, power on if required
		[VIDEO|SVIDEO|VGA1|VGA2|AUX|DVI|HDMI]
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
LONG TLID_BUSY 		= 1		// Warm / Cool Timeline
LONG TLID_AUTOADJ 	= 2		// AutoAdjust Timeline
LONG TLID_POLL 		= 3		// Polling Timeline
LONG TLID_SEND			= 4		// Staggered Sending Timeline
LONG TLID_COMMS		= 5		// Comms Timeout Timeline
LONG TLID_BOOT			= 6
LONG TLID_REPOLL		= 7
LONG TLID_TIMEOUT		= 8
LONG TLID_LOCKOUT		= 9
	(** Channel Constants **)
INTEGER chnPicMute	= 211
INTEGER chnFreeze		= 214
INTEGER chnBUSY		= 250
INTEGER chnCOMMS		= 251
INTEGER chnWARM		= 253
INTEGER chnCOOL		= 254
INTEGER chnPOWER		= 255
	(** POLLING **)
INTEGER qPOWER			= 1
INTEGER qINPUT			= 2
INTEGER qMODEL			= 3
INTEGER qSERIAL		= 4
INTEGER qFW				= 5
INTEGER qSHUTTER		= 6
INTEGER qFREEZE		= 7
INTEGER qASPECT		= 8
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uPanaProj{
	// Projector State Variables
	INTEGER POWER				// Projector Power
	CHAR    reqINPUT[25]		// Requested Input
	CHAR    curINPUT[3]		// Current Input ID
	CHAR    inputNAME[25]	// Current Input NAME
	INTEGER FREEZE				// Image Freeze
	INTEGER MUTE				// Picture Mute
	INTEGER WARMING			// Projector Warming Up
	INTEGER COOLING			// Projector Cooling Down
	INTEGER timeWARM			// Projector Warming Up Time
	INTEGER timeCOOL			// Projector Cooling Down Time
	INTEGER ASPECT				// Current Aspect as per Protocol
	// Projector Details Variables
	CHAR    MODEL[32]			// Projector Model Name
	CHAR    SERIAL[32]		// Projector Serial Number
	CHAR    FIRMWARE[32]		// Projector Main Firmware Version
	// Comms Variables
	CHAR    HOST[128]			// Projector Host / IP Address
	INTEGER PORT				// Projector IP Port
	INTEGER ConnOpen			//
	INTEGER RxPending			//
	INTEGER TryingConn		//
	CHAR    HASH[255]			//
	INTEGER lastPOLLED		//
	INTEGER errCODE			//
	CHAR    USER[32]			// Projector Login User Name
	CHAR    PASSWORD[32]		// Projector Login Password
	// Debug Status
	INTEGER DEBUG				// Debug Active / Inactive
}
DEFINE_VARIABLE
VOLATILE uPanaProj myProj
VOLATILE CHAR cTxBuffer[1000]
VOLATILE CHAR cRxBuffer[1000]
PERSISTENT INTEGER nProjTimeWarm	// Time in Seconds {Warmup}
PERSISTENT INTEGER nProjTimeCool	// Time in Seconds {Cooldown}

// Timeline Times
LONG TLT_SECOND[] 	= {  1000}	// One second for timer use
LONG TLT_AUTOADJ[]	= {  3000}	// Autoadjust 3 seconds after input change
LONG TLT_POLL[]		= { 30000}	// Poll every 30 seconds
LONG TLT_COMMS[]		= { 90000}	// Comms is dead if nothing recieved for 90s
LONG TLT_BOOT[]		= { 10000}	// Give it 10 seconds for Boot to finish
LONG TLT_REPOLL[]		= {  2000}	// Delay by 2 seconds, then start polling
LONG TLT_TIMEOUT[]	= { 10000}	// Give it 10 seconds then kill comms
LONG TLT_LOCKOUT[]	= {180000}	// Give it 3 minutes before re-atempting login comms
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myProj.HOST     = '000.NOT.SET.000'
	myProj.PORT     = 1024
	myProj.USER     = 'admin1'
	myProj.PASSWORD = 'panasonic'
	myProj.MODEL    = 'Panasonic Projector'
	myProj.SERIAL   = 'n/a'
	myProj.FIRMWARE = 'n/a'
	IF(!nProjTimeWarm){
		nProjTimeWarm = ProjectorTimeWarm
	}
	IF(!nProjTimeCool){
		nProjTimeCool = ProjectorTimeCool
	}
	myProj.timeWARM = nProjTimeWarm
	myProj.timeCOOL = nProjTimeCool
	CREATE_BUFFER ipDevice, cRxBuffer
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	fnDebug(FALSE,"'Opening TCP to Pana Proj Port ',ITOA(myProj.PORT),' on'",myProj.HOST)
	myProj.TryingConn = TRUE
	//ip_client_open(ipDevice.port, _IP, _PORT, IP_TCP)
	ip_client_open(ipDevice.port, myProj.HOST, myProj.PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(ipDevice.port)
	myProj.ConnOpen = FALSE
}
	(** Start up the Polling Function **)
DEFINE_FUNCTION fnStartPolling(){
	fnSendQuery(qPOWER)
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnRestartPoll(){
	IF(TIMELINE_ACTIVE(TLID_REPOLL)){ TIMELINE_KILL(TLID_REPOLL) }
	TIMELINE_CREATE(TLID_REPOLL,TLT_REPOLL,LENGTH_ARRAY(TLT_REPOLL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
// Send Poll Command
DEFINE_FUNCTION fnSendQuery(INTEGER pQUERY){
	myProj.lastPOLLED = pQUERY
	SWITCH(myProj.lastPOLLED){
		CASE qPOWER:	fnSendCommand('QPW','')
		CASE qINPUT:	fnSendCommand('QIN','')
		CASE qMODEL:	fnSendCommand('QID','')
		CASE qSERIAL:	fnSendCommand('QSN','')
		CASE qFW:		fnSendCommand('QVX','SVRS0')
		CASE qSHUTTER:	fnSendCommand('QSH','')
		CASE qFREEZE:	fnSendCommand('QFZ','')
		CASE qASPECT:	fnSendCommand('QSE','')
	}
}
// Send Debug to terminal
DEFINE_FUNCTION fnDebug(INTEGER pFORCE, CHAR Msg[], CHAR MsgData[]){
	IF(myProj.DEBUG = 1 || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION CHAR[20] fnGetInput(){
	myProj.inputNAME = 'UNKNOWN'
	SWITCH(myProj.curINPUT){
		CASE 'VID': myProj.inputNAME = 'VIDEO'
		CASE 'SVD': myProj.inputNAME = 'SVIDEO'
		CASE 'RG1': myProj.inputNAME = 'VGA1'
		CASE 'RG2': myProj.inputNAME = 'VGA2'
		CASE 'AUX': myProj.inputNAME = 'AUX'
		CASE 'DVI': myProj.inputNAME = 'DVI1'
		CASE 'HD1': myProj.inputNAME = 'HDMI1'
		CASE 'HD2': myProj.inputNAME = 'HDMI2'
		CASE 'NWP': myProj.inputNAME = 'NETWORK / USB'
		CASE 'PA1': myProj.inputNAME = 'PANASONIC APP'
		CASE 'MC1': myProj.inputNAME = 'MIRACAST'
		CASE 'MV1': myProj.inputNAME = 'MEMORY VIEWER'
		CASE 'DL1': myProj.inputNAME = 'DIGITAL LINK'
	}
	RETURN myProj.inputNAME
}
// Process Feedback from Projector
DEFINE_FUNCTION fnProcessFeedback(CHAR pPacket[]){
	fnDebug(FALSE,'ProcessFeedback',pPacket)
	(** COMMS **)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		TIMELINE_KILL(TLID_COMMS)
	}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	(** Do Data **)
	IF(LEFT_STRING(pPacket,9) == 'NTCONTROL'){
		STACK_VAR INTEGER pSTATUS
		GET_BUFFER_STRING(pPacket,10)
		pSTATUS = ATOI(GET_BUFFER_STRING(pPacket,2))
		IF(pSTATUS){
			fnDebug(FALSE,'CODE',pPacket)
			myProj.HASH = fnEncryptToMD5("myProj.USER,':',myProj.PASSWORD,':',pPacket")
		}
		ELSE{
			myProj.HASH = ''
		}
		myProj.ConnOpen = TRUE
	}
	ELSE{
		myProj.errCODE = 0
		SWITCH(LEFT_STRING(pPacket,2)){
			CASE '00':{
				GET_BUFFER_STRING(pPacket,2)
				SWITCH(LEFT_STRING(pPacket,2)){
					CASE 'ER':{//Errors
						SWITCH(pPacket){
							CASE 'ERRA':{
								fnDebug(FALSE,'INCORRECT LOGIN',pPacket)
								myProj.errCODE = 1010
								IF(TIMELINE_ACTIVE(TLID_POLL))	{TIMELINE_KILL(TLID_POLL)   }
								IF(TIMELINE_ACTIVE(TLID_REPOLL))	{TIMELINE_KILL(TLID_REPOLL) }
								IF(TIMELINE_ACTIVE(TLID_LOCKOUT)){TIMELINE_KILL(TLID_LOCKOUT)}
								TIMELINE_CREATE(TLID_LOCKOUT,TLT_LOCKOUT,LENGTH_ARRAY(TLT_LOCKOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							DEFAULT:{
								myProj.errCODE = ATOI(pPacket)
								fnDebug(FALSE,'ERROR',pPacket)
							}
						}
					}
					DEFAULT:{
						fnDebug(FALSE,'DEFAULT FB',pPacket)
						SWITCH(myProj.lastPOLLED){
							CASE qPOWER:{
								myProj.POWER = ATOI(pPacket)
								IF(myProj.POWER){
									fnSendQuery(qINPUT)
								}
								ELSE{
									myProj.lastPOLLED = 0
									//fnRestartPoll()
								}
							}
							CASE qINPUT:{
								IF(myProj.curINPUT != pPacket){
									myProj.curINPUT = RIGHT_STRING(pPacket,3)
									SEND_STRING vdvControl,"'INPUT-',fnGetInput()"
								}
								fnSendQuery(qMODEL)
							}
							CASE qMODEL:{
								IF(myProj.MODEL != pPacket){
									myProj.MODEL = pPacket
									SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myProj.MODEL"
								}
								fnSendQuery(qSERIAL)
							}
							CASE qSERIAL:{
								IF(myProj.SERIAL != pPacket){
									myProj.SERIAL = pPacket
									SEND_STRING vdvControl,"'PROPERTY-META,SERIALNO,',myProj.SERIAL"
								}
								fnSendQuery(qFW)
							}
							CASE qFW:{
								IF(myProj.FIRMWARE != pPacket){
									myProj.FIRMWARE = pPacket
									SEND_STRING vdvControl,"'PROPERTY-META,FIRMWARE,',myProj.FIRMWARE"
								}
								fnSendQuery(qSHUTTER)
							}
							CASE qSHUTTER:{
								myProj.MUTE = ATOI(pPacket)
								fnSendQuery(qFREEZE)
							}
							CASE qFREEZE:{
								myProj.FREEZE = ATOI(pPacket)
								fnSendQuery(qASPECT)
							}
							CASE qASPECT:{
								myProj.ASPECT = ATOI(pPacket)
								myProj.lastPOLLED = 0
							}
						}
					}
				}
			}
			DEFAULT:{
				fnDebug(TRUE,'UNKOWN RESPONSE',pPacket)
			}
		}
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR ThisCommand[], CHAR Param[]){
	STACK_VAR CHAR _ToSend[255]
	_ToSend = "'00','ADZZ',ThisCommand"
	IF(LENGTH_ARRAY(Param)){ _ToSend = "_ToSend,':', Param" }
	_ToSend = "_ToSend,$0D"				//ETX
	cTxBuffer = "cTxBuffer,_ToSend"
	IF(myProj.ConnOpen && !myProj.TryingConn){
		IF(!myProj.RxPending){
			fnSendCommand_INT()
		}
	}
	ELSE IF(!myProj.TryingConn){
		fnOpenConnection()
	}
}
DEFINE_FUNCTION fnSendCommand_INT(){
	STACK_VAR CHAR _ToSend[255]
	_ToSend = "myProj.HASH,REMOVE_STRING(cTxBuffer,"$0D",1)"
	fnDebug(FALSE,'AMX->Pana Proj :: ',"_ToSend")
	SEND_STRING ipDevice, _ToSend
	myProj.RxPending = TRUE
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	OFFLINE:{
		myProj.ConnOpen = FALSE
		myProj.RxPending = FALSE
		myProj.TryingConn = FALSE
		cTxBuffer = ''
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
			TIMELINE_KILL(TLID_TIMEOUT)
		}
	}
	ONLINE:{
		myProj.TryingConn = FALSE
		fnDebug(FALSE,"'Connected to Pana Proj Port ',ITOA(myProj.PORT),' on '",myProj.HOST)
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myProj.ConnOpen = FALSE
		myProj.RxPending = FALSE
		myProj.TryingConn = FALSE
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
		fnDebug(TRUE,"'Pana IP Error:[',myProj.HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		SWITCH(DATA.NUMBER){
			CASE 6:
			CASE 14:
			CASE 15:
			CASE 16:{myProj.ConnOpen = TRUE}// This is so that the connection can be closed before retrying.
		}
	}
	STRING:{
		fnDebug(FALSE,'Pana->D.T :: ',DATA.TEXT)
		fnDebug(FALSE,'Pana->AMX :: ',cRxBuffer)
		WHILE(FIND_STRING(cRxBuffer,"$0D",1)){
			myProj.RxPending = FALSE
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cRxBuffer,"$0D",1),1))
		}
		IF(!myProj.RxPending && FIND_STRING(cTxBuffer,"$0D",1)){
			fnSendCommand_INT()
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		TIMELINE_CREATE(TLID_BOOT, TLT_BOOT, LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myProj.HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myProj.PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myProj.HOST = DATA.TEXT
							myProj.PORT = 1024
						}
						fnCloseConnection()
					}
					CASE 'DEBUG'	:{ myProj.DEBUG    = ATOI(DATA.TEXT) }
					CASE 'USERNAME':{ myProj.USER     = DATA.TEXT }
					CASE 'PASSWORD':{ myProj.PASSWORD = DATA.TEXT }
					CASE 'TIMES':   {
						nProjTimeWarm = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1))
						nProjTimeCool = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'QUERY':{
				SWITCH(DATA.TEXT){
					CASE 'POWER':	fnSendQuery(qPOWER)
					CASE 'INPUT':	fnSendQuery(qINPUT)
					CASE 'MODEL':	fnSendQuery(qMODEL)
					CASE 'SERIAL':	fnSendQuery(qSERIAL)
					CASE 'FW':		fnSendQuery(qFW)
					CASE 'SHUTTER':fnSendQuery(qSHUTTER)
					CASE 'FREEZE':	fnSendQuery(qFREEZE)
					CASE 'ASPECT':	fnSendQuery(qASPECT)
				}
			}
			CASE 'POLL':{
				SWITCH(DATA.TEXT){
					CASE 'START':	fnStartPolling()
					CASE 'RESTART':fnRestartPoll()
					CASE 'KILL':{
						IF(TIMELINE_ACTIVE(TLID_POLL))	{TIMELINE_KILL(TLID_POLL)}
						IF(TIMELINE_ACTIVE(TLID_REPOLL))	{TIMELINE_KILL(TLID_REPOLL)}
					}
					CASE 'KILLALL':{
						STACK_VAR INTEGER TLID
						FOR(TLID = TLID_BUSY; TLID <= TLID_LOCKOUT; TLID++){
							IF(TIMELINE_ACTIVE(TLID))		{TIMELINE_KILL(TLID)}
						}
					}
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
					CASE 'ADJUST':	fnSendCommand('OAS','')
				}
			}
			CASE 'INPUT':{
				myProj.reqINPUT = DATA.TEXT
				IF(myProj.POWER){
					fnSendInputCommand()
				}
				ELSE{
					SEND_COMMAND vdvControl, 'POWER-ON'
				}
			}
			CASE 'BLANK':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	   myProj.MUTE = TRUE
					CASE 'OFF':	   myProj.MUTE = FALSE
					CASE 'TOGGLE':	myProj.MUTE = !myProj.MUTE
				}
				fnSendCommand('OSH',ITOA(myProj.MUTE))
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnSendCommand('PON','')
						IF(!myProj.POWER && !myProj.WARMING && !myProj.COOLING){
							myProj.WARMING = TRUE	// Warming Up
							TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
						}
					}
					CASE 'OFF':{
						fnSendCommand('POF','')
						IF(myProj.POWER){
							myProj.POWER 	= FALSE
							myProj.MUTE 	= FALSE
							myProj.FREEZE 	= FALSE
							myProj.COOLING = TRUE
							TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
						}
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,chnCOMMS] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,chnPOWER] 	= ( myProj.POWER )
	[vdvControl,chnCOOL]  	= ( myProj.COOLING )
	[vdvControl,chnWARM]  	= ( myProj.WARMING )
	[vdvControl,chnFreeze] 	= ( myProj.FREEZE )
	[vdvControl,chnPicMute] = ( myProj.MUTE )
	IF(myProj.timeWARM != nProjTimeWarm){
		myProj.timeWARM = nProjTimeWarm
	}
	IF(myProj.timeCOOL != nProjTimeCool){
		myProj.timeCOOL = nProjTimeCool
	}
}
/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendQuery(qPOWER)
}
	(** Close connection after X amount of inactivity **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(myProj.ConnOpen){
		fnCloseConnection()
	}
}
	(** Boot Finished **)
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	fnStartPolling()
}
	(** Re-Poll Delay Elapsed **)
DEFINE_EVENT TIMELINE_EVENT[TLID_REPOLL]{
	fnStartPolling()
}
	(** Comms Timeout **)
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	myProj.POWER = FALSE
}
	(** Login Lockout Time Expired **)
DEFINE_EVENT TIMELINE_EVENT[TLID_LOCKOUT]{
	fnStartPolling()
}
/******************************************************************************
	Projector Warming / Cooling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	IF(myProj.Warming && (myProj.timeWARM == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY) }
		myProj.POWER = TRUE		// Power
		myProj.Warming = FALSE	// Warming Up
		fnSendInputCommand()		// Send an Input Command if required
	}
	ELSE IF(myProj.COOLING && (myProj.timeCOOL == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY) }
		myProj.COOLING = FALSE	// Cooling Down
	}
	IF(!myProj.WARMING && !myProj.COOLING){
		SEND_STRING vdvControl, "'TIME-0:00'"
	}
	ELSE{
		STACK_VAR LONG RemainSecs
		STACK_VAR LONG ElapsedSecs
		STACK_VAR CHAR TextSecs[2]
		STACK_VAR INTEGER _TotalSecs

		IF(myProj.WARMING){ _TotalSecs = myProj.timeWARM }
		IF(myProj.COOLING){ _TotalSecs = myProj.timeCOOL }

		ElapsedSecs = TIMELINE.REPETITION
		RemainSecs = _TotalSecs - ElapsedSecs

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
	SWITCH(myProj.reqINPUT){
		CASE 'VIDEO':		fnSendCommand('IIS','VID')
		CASE 'SVIDEO':		fnSendCommand('IIS','SVD')
		CASE 'VGA1':		fnSendCommand('IIS','RG1')
		CASE 'VGA2':		fnSendCommand('IIS','RG2')
		CASE 'AUX':			fnSendCommand('IIS','AUX')
		CASE 'DVI1':		fnSendCommand('IIS','DVI')
		CASE 'HDMI1':		fnSendCommand('IIS','HD1')
		CASE 'HDMI2':		fnSendCommand('IIS','HD2')
		CASE 'NETWORK':	fnSendCommand('IIS','NWP')
		CASE 'PANA-APP':	fnSendCommand('IIS','PA1')
		CASE 'MIRACAST':	fnSendCommand('IIS','MC1')
		CASE 'MEMORY':		fnSendCommand('IIS','MV1')
		CASE 'DIGITAL':	fnSendCommand('IIS','DL1')
	}
	IF(TIMELINE_ACTIVE(TLID_AUTOADJ)){TIMELINE_KILL(TLID_AUTOADJ)}
	SWITCH(myProj.reqINPUT){
		CASE 'VGA1':
		CASE 'VGA2':{
			TIMELINE_CREATE(TLID_AUTOADJ,TLT_AUTOADJ,LENGTH_ARRAY(TLT_AUTOADJ),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	myProj.reqINPUT = ''
}
	(** Auto Adjust Input after source change **)
DEFINE_EVENT TIMELINE_EVENT[TLT_AUTOADJ]{
	SEND_COMMAND vdvControl, 'AUTO-ADJUST'
}

