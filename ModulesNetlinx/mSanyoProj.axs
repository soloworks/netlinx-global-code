MODULE_NAME='mSanyoProj'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uSanyoProj{
	(** Current States **)
	INTEGER 	POWER				// Current Power State
	CHAR 	  	INPUT[10]		// Current Input State
	INTEGER 	MUTE				// Current Mute State
	INTEGER 	FREEZE			// Current Freeze State
	INTEGER 	LAMPHOURS		//
	INTEGER 	LAMPSERVICE		//
	(** Desired States **)
	INTEGER 	desPOWER			// Desired Power State
	CHAR 	  	desINPUT[10]	// Desired Input State
	INTEGER 	desMUTE			// Desired Mute State
	INTEGER 	desFreeze		// Desired Freeze State
	(** Comms **)
	INTEGER  isIP				// Is this IP or RS232 Controlled
	CHAR 		IP_HOST[128]	// Projector IP Address
	INTEGER 	IP_PORT
	CHAR 		Tx[256]			// Transmit Buffer
	CHAR 		Rx[256]			// Recieve Buffer
	INTEGER 	DEBUG				// Debug ON/OFF
	INTEGER 	CONN_STATE		// IP Connected
	INTEGER 	TxPEND			// Response Pending
	CHAR 		LAST_POLL[30]	// Last Polled Value
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
	(** Timeline Constants **)
LONG TLID_BUSY 		= 1
LONG TLID_AUTOADJ 	= 2
LONG TLID_POLL 		= 3
LONG TLID_COMMS		= 4
LONG TLID_REPOLL		= 5
LONG TLID_TIMEOUT		= 6
	(** Channel Constants **)
INTEGER chnVidMute	= 211
INTEGER chnFreeze		= 214
INTEGER chnPOWER		= 255
	(** Custom ON / OFF - avoids 0 as FALSE **)
INTEGER desON 			= 1
INTEGER desOFF			= 2

INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING = 1
INTEGER CONN_STATE_CONNECTED	= 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uSanyoProj mySanyoProj
	(** Timeline Times **)
LONG 		TLT_AUTOADJ[]	= {  5000 }	// Autoadjust 3 seconds after input change
LONG 		TLT_POLL[]		= { 60000 }	// Poll every 15 seconds
LONG 		TLT_REPOLL[]	= {  2000 }	// Delay by 2 seconds, then start polling
LONG 		TLT_COMMS[]		= { 90000 }	// Comms is dead if nothing recieved for 60s
LONG 		TLT_TIMEOUT[]	= { 10000 }	// Kill connection after timeout
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	mySanyoProj.isIP = !(dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, mySanyoProj.Rx
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	IF(mySanyoProj.CONN_STATE == CONN_STATE_OFFLINE){
		fnDebug(FALSE,"'Connecting Sanyo on'","mySanyoProj.IP_HOST,':',ITOA(mySanyoProj.IP_PORT)")
		mySanyoProj.CONN_STATE = CONN_STATE_CONNECTING;
		ip_client_open(dvDevice.port, mySanyoProj.IP_HOST, mySanyoProj.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseConnection(){
	ip_client_close(dvDevice.port);
}
	(** Start up the Polling Function **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnPoll(){
	fnAddQueryToQueue("'STATUS'");
	fnAddQueryToQueue("'INPUT'");
	fnAddQueryToQueue("'LAMPREPL'");
	fnAddQueryToQueue("'LAMPH'");
	fnAddQueryToQueue("'VMUTE'");
	fnAddQueryToQueue("'FREEZE'");
}
	(** Send a command **)
DEFINE_FUNCTION fnAddQueryToQueue(CHAR cmd[]){
	mySanyoProj.Tx = "mySanyoProj.Tx,'CR ',cmd,$0D,$0A"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnAddCommandToQueue(CHAR cmd[]){
	mySanyoProj.Tx = "mySanyoProj.Tx,cmd,$0D,$0A"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!mySanyoProj.TxPend && mySanyoProj.CONN_STATE == CONN_STATE_CONNECTED && FIND_STRING(mySanyoProj.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[255]
		toSend = REMOVE_STRING(mySanyoProj.Tx,"$0D,$0A",1)
		fnDebug(FALSE,'->Sanyo',"toSend")
		SEND_STRING dvDevice,toSend
		mySanyoProj.TxPend = TRUE
		IF(LEFT_STRING(toSend,2) == 'CR'){
			mySanyoProj.LAST_POLL = fnStripCharsRight(toSend,2)
		}
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE IF(FIND_STRING(mySanyoProj.Tx,"$0D,$0A",1) && mySanyoProj.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenConnection()
	}
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR pMsg[], CHAR pMsgData[]){
	IF(mySanyoProj.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(dvDevice.PORT),':',ITOA(vdvControl.Number),':',pMsg, ':', pMsgData"
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	IF(GET_BUFFER_STRING(pDATA,4) != '000 ' && LENGTH_ARRAY(mySanyoProj.LAST_POLL)){
		fnDebug(FALSE,'Sanyo Feedback Error',mySanyoProj.LAST_POLL)
	}
	ELSE{
		SWITCH(mySanyoProj.LAST_POLL){
			CASE 'CR STATUS':{
				SWITCH(pDATA){
					CASE '00': mySanyoProj.POWER = TRUE;
					CASE '80': mySanyoProj.POWER = FALSE;
				}
				SELECT{
					ACTIVE(mySanyoProj.POWER && mySanyoProj.desPOWER == desOFF):{ fnAddCommandToQueue('CF POWER OFF') }
					ACTIVE(!mySanyoProj.POWER && mySanyoProj.desPOWER == desON):{  fnAddCommandToQueue('CF POWER ON') }
					ACTIVE(1):{mySanyoProj.desPOWER = 0}
				}
			}
			CASE 'CR VMUTE':{
				SWITCH(pDATA){
					CASE 'ON':  mySanyoProj.MUTE = TRUE;
					CASE 'OFF': mySanyoProj.MUTE = FALSE;
				}
				SELECT{
					ACTIVE(mySanyoProj.MUTE && mySanyoProj.desMUTE == desOFF):{ fnAddCommandToQueue('CF VMUTE OFF') }
					ACTIVE(!mySanyoProj.MUTE && mySanyoProj.desMUTE == desON):{  fnAddCommandToQueue('CF VMUTE ON') }
					ACTIVE(1):{mySanyoProj.desMUTE = 0}
				}
			}
			CASE 'CR FREEZE':{
				SWITCH(pDATA){
					CASE 'ON':  mySanyoProj.FREEZE = TRUE;
					CASE 'OFF': mySanyoProj.FREEZE = FALSE;
				}
				SELECT{
					ACTIVE(mySanyoProj.FREEZE && mySanyoProj.desFREEZE == desOFF):{ fnAddCommandToQueue('CF FREEZE OFF') }
					ACTIVE(!mySanyoProj.FREEZE && mySanyoProj.desFREEZE == desON):{  fnAddCommandToQueue('CF FREEZE ON') }
					ACTIVE(1):{mySanyoProj.desFREEZE = 0}
				}
			}
			CASE 'CR LAMPREPL':{
				mySanyoProj.LAMPSERVICE = (FIND_STRING(pDATA,'Y',1))
			}
			CASE 'CR LAMPH':{
				IF(mySanyoProj.LAMPHOURS != ATOI(pDATA)){
					mySanyoProj.LAMPHOURS = ATOI(pDATA)
					SEND_STRING vdvControl,"'LAMPHOURS-',ITOA(mySanyoProj.LAMPHOURS)"
				}
			}
		}

		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	mySanyoProj.LAST_POLL = ''
	mySanyoProj.TxPend = FALSE
	fnSendFromQueue()
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	OFFLINE:{
		mySanyoProj.CONN_STATE = CONN_STATE_OFFLINE
		mySanyoProj.Tx = ''
		mySanyoProj.TxPend = FALSE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	}
	ONLINE:{
		IF(mySanyoProj.isIP){
			fnDebug(FALSE,'Connected to Sanyo on',"mySanyoProj.IP_HOST,':',ITOA(mySanyoProj.IP_PORT)")
		}
		ELSE{
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, "'SET BAUD 19200 N 8 1 485 DISABLE'"
			mySanyoProj.CONN_STATE = CONN_STATE_CONNECTED
			fnPoll()
			fnInitPoll()
		}
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		mySanyoProj.CONN_STATE = CONN_STATE_OFFLINE
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
		fnDebug(TRUE,"'Sayno IP ERR:[',mySanyoProj.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		fnDebug(FALSE,'Sanyo->AMX',DATA.TEXT);
		IF(FIND_STRING(mySanyoProj.Rx,'PASSWORD:',1)){
			mySanyoProj.Rx = ''
			fnDebug(FALSE,'AMX->Sanyo',"$0D,$0A");
			SEND_STRING dvDevice, "$0D,$0A"
		}
		IF(FIND_STRING(mySanyoProj.Rx,'Hello',1)){
			mySanyoProj.Rx = ''
			mySanyoProj.CONN_STATE = CONN_STATE_CONNECTED
			fnSendFromQueue()
		}
		ELSE{
			WHILE(FIND_STRING(mySanyoProj.Rx,"$0D",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySanyoProj.Rx,"$0D",1),1))
			}
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						mySanyoProj.IP_HOST 	= DATA.TEXT
						mySanyoProj.IP_PORT	= 10000
						fnPoll()
						fnInitPoll()
					}
					CASE 'DEBUG':{ mySanyoProj.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE') }
				}
			}
			CASE 'CONNECT':{
				SWITCH(DATA.TEXT){
					CASE 'CLOSE':	fnCloseConnection()
					CASE 'OPEN':	fnOpenConnection()
				}
			}
			CASE 'RAW':{
				fnAddCommandToQueue(DATA.TEXT)
			}
			CASE 'VIDMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{	 	fnAddCommandToQueue('CF VMUTE ON');  mySanyoProj.desMUTE = desON; mySanyoProj.MUTE = TRUE }
					CASE 'OFF':{	fnAddCommandToQueue('CF VMUTE OFF'); mySanyoProj.desMUTE = desOFF;mySanyoProj.MUTE = FALSE }
					CASE 'TOG':
					CASE 'TOGGLE':{
						IF(mySanyoProj.MUTE){ SEND_COMMAND vdvControl, 'VIDMUTE-OFF' }
						ELSE{		 				 SEND_COMMAND vdvControl, 'VIDMUTE-ON'  }
					}
				}
			}
			CASE 'FREEZE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{	 	fnAddCommandToQueue('CF FREEZE ON'); mySanyoProj.desFREEZE = desON; }
					CASE 'OFF':{	fnAddCommandToQueue('CF FREEZE OFF'); mySanyoProj.desFREEZE = desOFF; }
					CASE 'TOG':
					CASE 'TOGGLE':{
						IF(mySanyoProj.FREEZE){ SEND_COMMAND vdvControl, 'FREEZE-OFF' }
						ELSE{		 				 	SEND_COMMAND vdvControl, 'FREEZE-ON'  }
					}
				}
			}
			CASE 'ADJUST':{
				SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnAddCommandToQueue('KEY 4A');
				}
			}
			CASE 'INPUT':{
				IF(mySanyoProj.POWER){
					fnAddCommandToQueue("'C',fngetSourceCode(DATA.TEXT)")
				}
				ELSE{
					mySanyoProj.desINPUT = fngetSourceCode(DATA.TEXT);
					fnAddCommandToQueue('CF POWER ON');
				}
			}
			CASE 'POWER':{
				mySanyoProj.desMUTE 		= 0
				mySanyoProj.desFREEZE 	= 0
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnAddCommandToQueue('CF POWER ON');
					}
					CASE 'OFF':{
						fnAddCommandToQueue('CF POWER OFF')
						IF(mySanyoProj.POWER){
							mySanyoProj.POWER 	= FALSE;
							mySanyoProj.MUTE 		= FALSE;
							mySanyoProj.FREEZE 	= FALSE;
						}
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,chnPOWER] 	= ( mySanyoProj.POWER)
	[vdvControl,chnFreeze] 	= ( mySanyoProj.FREEZE )
	[vdvControl,chnVidMute] = ( mySanyoProj.MUTE )
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
	mySanyoProj.TxPend = FALSE
	mySanyoProj.Tx = ''
	IF(mySanyoProj.isIP){
		fnCloseConnection()
	}
}
	(** Comms Timeout **)
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	mySanyoProj.POWER  = FALSE;
	mySanyoProj.MUTE 	 = FALSE;
	mySanyoProj.FREEZE = FALSE;
}

/******************************************************************************
	Input Control Code
******************************************************************************/
DEFINE_FUNCTION fnSendInputCommand(){
	/*fnAddCommandToQueue("'SOURCE ',fnGetSourceCode(_INPUT)")
	IF(TIMELINE_ACTIVE(TLID_AUTOADJ)){TIMELINE_KILL(TLID_AUTOADJ)}
	SWITCH(_INPUT){
		CASE 'PC1':
		CASE 'PC2':{
			TIMELINE_CREATE(TLID_AUTOADJ,TLT_AUTOADJ,LENGTH_ARRAY(TLT_AUTOADJ),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	_INPUT = ''*/
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
DEFINE_FUNCTION CHAR[255] fngetSourceCode(CHAR pSRC[]){
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

