MODULE_NAME='mEpsonProjector'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Generic Epson Control Module over IP using ESC/VP.net
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uEpsonProj{
	// Comms
	INTEGER 	DISABLED
	INTEGER	DEBUG
	INTEGER	isIP
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[255]
	INTEGER	PEND
	CHAR		Tx[1000]
	CHAR 		Rx[1000]
	INTEGER 	CONN_STATE
	// MetaData
	CHAR 		META_SN[50]
	INTEGER 	LAMP_HOURS
	// State
	INTEGER	POWER
	INTEGER	AVMUTE
	INTEGER	VOLUME
	CHAR		SOURCE_NO[2]
	CHAR		DES_SOURCE[20]
	CHAR		SOURCE_NAME[20]
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
	(** Timeline Constants **)
LONG TLID_BUSY 		= 1
LONG TLID_AUTOADJ 	= 2
LONG TLID_POLL 		= 3
LONG TLID_SEND			= 4
LONG TLID_COMMS		= 5
LONG TLID_BOOT			= 6
LONG TLID_SHORTPOLL	= 7
LONG TLID_TIMEOUT		= 8

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED		= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
	(** Comms Variables **)
VOLATILE uEpsonProj myEpsonProj

	(** Timeline Times **)
LONG 		TLT_SECOND[] 	= {1000};	// One second for timer use
LONG 		TLT_AUTOADJ[]	= {5000};	// Autoadjust 3 seconds after input change
LONG 		TLT_POLL[]		= {15000};	// Poll every 15 seconds
LONG 		TLT_COMMS[]		= {90000};	// Comms is dead if nothing recieved for 60s
LONG 		TLT_BOOT[]		= { 5000};	// Give it 5 seconds for Boot to finish
LONG 		TLT_SHORTPOLL[]= {2000};	// Delay by 2 seconds, then start polling
LONG 		TLT_TIMEOUT[]	= {5000};	// Delay by 2 seconds, then start polling
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myEpsonProj.Rx
	myEpsonProj.isIP = !dvDevice.NUMBER
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	fnDebug('Connecting to Epson',"myEpsonProj.IP_HOST,':',ITOA(myEpsonProj.IP_PORT)")
	myEpsonProj.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(dvDevice.port, myEpsonProj.IP_HOST, myEpsonProj.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(dvDevice.port);
}
	(** Start up the Polling Function **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}
DEFINE_FUNCTION fnShortPoll(){
	IF(TIMELINE_ACTIVE(TLID_SHORTPOLL)){ TIMELINE_KILL(TLID_SHORTPOLL); }
	TIMELINE_CREATE(TLID_SHORTPOLL,TLT_SHORTPOLL,LENGTH_ARRAY(TLT_SHORTPOLL),TIMELINE_ABSOLUTE,TIMELINE_ONCE);
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnPoll(){
	IF(!LENGTH_ARRAY(myEpsonProj.META_SN)){
		fnInit()
	}
	ELSE{
		fnAddToQueue("'PWR?'")
		fnAddToQueue("'LAMP?'")
	}
}
DEFINE_FUNCTION fnInit(){
	fnAddToQueue("'SNO?'")
	fnAddToQueue("'LAMP?'")
	fnAddToQueue("'PWR?'")
}

DEFINE_FUNCTION fnAddToQueue(CHAR cmd[]){
	myEpsonProj.Tx = "myEpsonProj.Tx,cmd,$0D"
	fnSendFromQueue()
}
	(** Send a command **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myEpsonProj.PEND){
		IF(myEpsonProj.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(myEpsonProj.Tx,"$0D",1)){
			STACK_VAR CHAR _ToSend[255]
			_ToSend = REMOVE_STRING(myEpsonProj.Tx,"$0D",1)
			fnDebug('->EPSON',"_ToSend")
			SEND_STRING dvDevice, _ToSend;
			myEpsonProj.PEND = TRUE;
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			//fnInitPoll()
			fnShortPoll()
		}
		ELSE IF(myEpsonProj.isIP && myEpsonProj.CONN_STATE == CONN_STATE_OFFLINE){
			fnOpenConnection()
		}
	}
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myEpsonProj.DEBUG)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	(** Do Data **)
	IF(RIGHT_STRING(pDATA,1) == "$0D"){
		pDATA = fnStripCharsRight(pDATA,1);
	}
	fnDebug('EpsonFB',pDATA);
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)){
		CASE 'SOURCE':{
			IF(myEpsonProj.SOURCE_NO != pDATA){
				myEpsonProj.SOURCE_NO = pDATA
				myEpsonProj.SOURCE_NAME = fnGetSourceName(myEpsonProj.SOURCE_NO)
				SEND_STRING vdvControl, "'INPUT-',myEpsonProj.SOURCE_NAME"
			}
			IF(myEpsonProj.SOURCE_NAME != myEpsonProj.DES_SOURCE && myEpsonProj.SOURCE_NAME != '' ){
				fnSendInputCommand()
			}
		}
		CASE 'MUTE':{
			myEpsonProj.AVMUTE = (pDATA == 'ON')
		}
		CASE 'VOL':{
			myEpsonProj.VOLUME = ATOI(pDATA)
		}
		CASE 'SNO':{
			IF(myEpsonProj.META_SN != pDATA){
				myEpsonProj.META_SN = pDATA
				SEND_STRING vdvControl, "'PROPERTY-META,SERIALNO,',myEpsonProj.META_SN"
			}
		}
		CASE 'LAMP':{
			IF(myEpsonProj.LAMP_HOURS != ATOI(pDATA)){
				myEpsonProj.LAMP_HOURS = ATOI(pDATA)
				SEND_STRING vdvControl, "'PROPERTY-LAMPHOURS,',ITOA(myEpsonProj.LAMP_HOURS)"
			}
		}
		CASE 'PWR':{
			SWITCH(pDATA){
				CASE '01':{
					IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
					myEpsonProj.POWER = TRUE;
					fnAddToQueue("'SOURCE?'")
					fnAddToQueue("'VOL?'")
					fnAddToQueue("'MUTE?'")
				}
				CASE '00':	// Network Interface OFF
				CASE '04':{	// Network Interface ON
					IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
					myEpsonProj.POWER = FALSE
					myEpsonProj.SOURCE_NO	= ''
				}
			}
		}
	}
		(** COMMS **)
	IF(TIMELINE_ACTIVE(TLID_COMMS)){
		TIMELINE_KILL(TLID_COMMS)
	}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)

}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myEpsonProj.DISABLED){
			IF(myEpsonProj.isIP){
				fnDebug('Connected to Epson on ',"myEpsonProj.IP_HOST,':',ITOA(myEpsonProj.IP_PORT)")
				fnDebug('->Epson',"'ESC/VP.net',$10,$03,$00,$00,$00,$00")
				SEND_STRING dvDevice, "'ESC/VP.net',$10,$03,$00,$00,$00,$00";
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(myEpsonProj.isIP && !myEpsonProj.DISABLED){
			myEpsonProj.CONN_STATE = CONN_STATE_OFFLINE
			myEpsonProj.PEND = FALSE;
			myEpsonProj.Tx = ''
			myEpsonProj.Rx = ''
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
				TIMELINE_KILL(TLID_TIMEOUT)
			}
		}
	}
	ONERROR:{
		IF(myEpsonProj.isIP && !myEpsonProj.DISABLED){
			STACK_VAR CHAR _MSG[255]
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
			fnDebug("'Epson IP Error:[',myEpsonProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
			fnResetModule()
		}
	}
	STRING:{
		IF(!myEpsonProj.DISABLED){
			fnDebug('Epson->',DATA.TEXT);
			IF(LEFT_STRING(DATA.TEXT,10) == "'ESC/VP.net'"){
				STACK_VAR CHAR _ToSend[255]
				myEpsonProj.CONN_STATE 	= CONN_STATE_CONNECTED;
				myEpsonProj.Rx = '';
				fnSendFromQueue()
			}
			ELSE{
				WHILE(FIND_STRING(myEpsonProj.Rx,"':'",1)){
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myEpsonProj.Rx,"':'",1),1))
					myEpsonProj.PEND = FALSE
				}
				fnSendFromQueue()
			}
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'EPSON':
							CASE 'TRUE':myEpsonProj.DISABLED = FALSE
							DEFAULT:		myEpsonProj.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myEpsonProj.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							myEpsonProj.IP_HOST 	= DATA.TEXT
							myEpsonProj.IP_PORT	= 3629
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						CASE 'DEBUG':{
							myEpsonProj.DEBUG = (DATA.TEXT == 'TRUE')
						}
					}
				}
				CASE 'CONNECT':{
					SWITCH(DATA.TEXT){
						CASE 'CLOSE':	fnCloseConnection()
						CASE 'OPEN':	fnOpenConnection()
					}
				}
				CASE 'RAW':{
					fnAddToQueue(DATA.TEXT)
				}
				CASE 'ADJUST':{
					SWITCH(DATA.TEXT){
						CASE 'AUTO':		fnAddToQueue('KEY 4A');
					}
				}
				CASE 'INPUT':{
					myEpsonProj.DES_SOURCE = DATA.TEXT;
					IF(myEpsonProj.POWER){
						fnSendInputCommand()
					}
					ELSE{
						fnAddToQueue('PWR ON');
					}
				}

				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':{
							fnAddToQueue('PWR ON');
						}
						CASE 'OFF':{
							fnAddToQueue('PWR OFF')
						}
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	IF(!myEpsonProj.DISABLED){
		[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) );
		[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) );
		[vdvControl,255] 	= ( myEpsonProj.POWER);
	}
}

/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}
	(** Close connection after X amount of inactivity **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnResetModule()
	IF(myEpsonProj.isIP && myEpsonProj.CONN_STATE == CONN_STATE_CONNECTED){
		fnCloseConnection()
	}
}
DEFINE_FUNCTION fnResetModule(){
	myEpsonProj.Tx = ''
	myEpsonProj.Rx = ''
	myEpsonProj.PEND = FALSE
}
	(** Boot Finished **)
DEFINE_EVENT
TIMELINE_EVENT[TLID_SHORTPOLL]{
	IF(!myEpsonProj.DISABLED){
		fnPoll();
		//fnInitPoll();
	}
}
	(** Comms Timeout **)
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	fnResetModule()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myEpsonProj.DISABLED){
		IF(!myEpsonProj.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			myEpsonProj.CONN_STATE = CONN_STATE_CONNECTED
		}
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Epson'
		SEND_STRING vdvControl,'PROPERTY-META,MODEL,Unknown'
		SEND_STRING vdvControl,'PROPERTY-META,LAMPLIFE,4000'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,VGA1|VGA2|RGB|HDMI1'
		fnPoll()
		fnInitPoll()
	}
}
/******************************************************************************
	Input Control Code
******************************************************************************/
DEFINE_FUNCTION fnSendInputCommand(){
	fnAddToQueue("'SOURCE ',fnGetSourceCode(myEpsonProj.DES_SOURCE)")
}
DEFINE_FUNCTION CHAR[255] fnGetSourceName(CHAR pSRC[]){
	SWITCH(pSRC){
		CASE '11':RETURN 'VGA1'
		CASE '21':RETURN 'VGA2'
		CASE '41':RETURN 'VIDEO'
		CASE '42':RETURN 'SVIDEO'
		CASE '24':RETURN 'RGB'
		CASE '30':RETURN 'HDMI1'
	}
}
DEFINE_FUNCTION CHAR[255] fnGetSourceCode(CHAR pSRC[]){
	SWITCH(pSRC){
		CASE 'VGA1':		RETURN '11';
		CASE 'VGA2':		RETURN '21';
		CASE 'VIDEO':		RETURN '41';
		CASE 'SVIDEO':		RETURN '42';
		CASE 'RGB':			RETURN '24';
		CASE 'HDMI1':		RETURN '30';
	}
}
	(** Auto Adjust input after source change **)
DEFINE_EVENT TIMELINE_EVENT[TLID_AUTOADJ]{
	SEND_COMMAND vdvControl, 'ADJUST-AUTO'
}

