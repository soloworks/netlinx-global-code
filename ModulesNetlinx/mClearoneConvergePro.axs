MODULE_NAME='mClearoneConvergePro'(DEV vdvControl[],DEV vdvObjects[],DEV dvDevice)
INCLUDE 'CustomFunctions'
/*********************************************************************
	Clearone Module, adapted from multi-module version
*********************************************************************/
/*********************************************************************
	Module Structures
*********************************************************************/
DEFINE_TYPE
STRUCTURE uDSPUnit{
	CHAR IP[40]
	CHAR ID[2]
	CHAR MODEL[30]
	CHAR VER[10]
}
STRUCTURE uDSPObj{
	INTEGER 	TYPE
	CHAR 		HOST[2]	// ID of host unit for this object
	CHAR 		GROUP		// Group ID for this object (Device Dependant)
	INTEGER 	CHAN		// Channel in the Group for this Object
	// MUTE
	INTEGER MUTE		// Current Mute

	// VOL Control
	SINTEGER	GAIN_RANGE[2]		// Object Level MIN/MAX Value
	INTEGER 	GAIN_PEND			// Is a Volume Update pending
	SINTEGER	GAIN_PEND_VAL		// Volume to Send
	SINTEGER GAIN_VAL				// Current Value
	INTEGER  GAIN_STEP

	// TELEPHONY
	INTEGER OFF_HOOK
}
STRUCTURE uClearOne{
	CHAR 		Rx[2000]
	CHAR 		Tx[2000]
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	isIP
	CHAR 		USERNAME[20]
	CHAR 		PASSWORD[20]
	CHAR		USERLEVEL[20]
	INTEGER 	DEBUG
	uDSPUnit	UNIT[6]
	uDSPObj	OBJECT[25]
}
DEFINE_CONSTANT
INTEGER OBJ_FADER 		= 1
INTEGER OBJ_FADER_MC		= 2
INTEGER OBJ_POTS_RX		= 3
INTEGER OBJ_POTS_TX		= 4
INTEGER OBJ_VOIP_RX		= 5
INTEGER OBJ_VOIP_TX		= 6
INTEGER OBJ_MATRIX 		= 7
INTEGER OBJ_BEAM_MUTE	= 8
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_NEGOTIATE		= 2
INTEGER IP_STATE_CONNECTED		= 3

LONG TLID_POLL  		= 1
LONG TLID_RETRY 		= 2
LONG TLID_SEND			= 3

LONG TLID_COMMS_00	= 100
LONG TLID_COMMS_01	= 101
LONG TLID_COMMS_02	= 102
LONG TLID_COMMS_03	= 103
LONG TLID_COMMS_04	= 104
LONG TLID_COMMS_05	= 105

LONG TLID_VOL_00		= 200
LONG TLID_VOL_01		= 201
LONG TLID_VOL_02		= 202
LONG TLID_VOL_03		= 203
LONG TLID_VOL_04		= 204
LONG TLID_VOL_05		= 205
LONG TLID_VOL_06		= 206
LONG TLID_VOL_07		= 207
LONG TLID_VOL_08		= 208
LONG TLID_VOL_09		= 209
LONG TLID_VOL_10		= 210
LONG TLID_VOL_11		= 211
LONG TLID_VOL_12		= 212
LONG TLID_VOL_13		= 213
LONG TLID_VOL_14		= 214
LONG TLID_VOL_15		= 215
LONG TLID_VOL_16		= 216
LONG TLID_VOL_17		= 217
LONG TLID_VOL_18		= 218
LONG TLID_VOL_19		= 219
LONG TLID_VOL_20		= 220

INTEGER DEBUG_ERR		= 0
INTEGER DEBUG_STD		= 1
INTEGER DEBUG_DEV		= 2
/*********************************************************************
	Module Variables
*********************************************************************/
DEFINE_VARIABLE
VOLATILE uClearOne  	myClearOne

LONG TLT_POLL[]  	= {  20000 }
LONG TLT_COMMS[] 	= {  60000 }
LONG TLT_RETRY[]	= {   5000 }
LONG TLT_VOL[]		= {	 200 }
LONG TLT_SEND[]	= {	  75 }
/*********************************************************************
	Module Setup
*********************************************************************/
DEFINE_START{
	myClearOne.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice,myClearOne.Rx
}
/*********************************************************************
	Utility Functions
*********************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR dest[], CHAR cmd[], CHAR values[]){
	IF(myClearOne.isIP){
		fnDebug(DEBUG_STD,"'->DSP'","'#',dest,' ',cmd,' ',values,$0D")
		SEND_STRING dvDevice, "'#',dest,' ',cmd,' ',values,$0D"
		fnInitPoll()
	}
	ELSE{
		IF(!TIMELINE_ACTIVE(TLID_SEND)){
			fnDebug(DEBUG_STD,"'Enqueue'","'#',dest,' ',cmd,' ',values,$0D")
			SEND_STRING dvDevice, "'#',dest,' ',cmd,' ',values,$0D"
		}
		ELSE{
			myClearOne.Tx = "myClearOne.Tx,'#',dest,' ',cmd,' ',values,$0D"
			TIMELINE_CREATE(TLID_SEND,TLT_SEND,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	IF(REMOVE_STRING(myClearOne.Tx,"$0D",1)){
		SEND_STRING dvDevice, REMOVE_STRING(myClearOne.Tx,"$0D",1)
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnDebug(INTEGER DebugLvl, CHAR Msg[], CHAR MsgData[]){
	IF(myClearOne.DEBUG >= DebugLvl){
		SEND_STRING 0, "ITOA(vdvControl[1].Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myClearOne.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Converge IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to Converge on ',"myClearOne.IP_HOST,':',ITOA(myClearOne.IP_PORT)")
		myClearOne.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myClearOne.IP_HOST, myClearOne.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	(** Routine Variables **)
	STACK_VAR INTEGER x;					// Counter Variable
	STACK_VAR INTEGER y;					// Counter Variable
	STACK_VAR CHAR _DEVICE[2]			// Device Type & ID
	STACK_VAR CHAR _COMMAND[50]		// Command
	STACK_VAR CHAR _VALUES[10][30]	// Array of Values
	(** Process Packet **)
	fnDebug(DEBUG_DEV,'fnProcessFeedback','Started')
	fnDebug(DEBUG_STD,'DSP->',pDATA)
	IF(LEFT_STRING(pDATA,4) == 'OK> '){GET_BUFFER_STRING(pDATA,4)}
	IF(LEFT_STRING(pDATA,2) == '> '){GET_BUFFER_STRING(pDATA,2)}
	GET_BUFFER_STRING(pDATA,1)					// Remove '#'
	_DEVICE =  fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)	// Extract Device Type & ID
	_COMMAND = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)	// Extract Command
	IF(_COMMAND == 'ERROR'){
		FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
			IF(_DEVICE == myClearOne.UNIT[x].ID){
				SEND_STRING vdvControl[x],"'ERROR-',pDATA"
			}
		}
		RETURN
	}
	x = 1;
	WHILE(FIND_STRING(pDATA,"' '",1)){
		_VALUES[x] = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
		x++
	}
	_VALUES[x] = pDATA
	fnDebug(DEBUG_DEV,'DEVICE',_DEVICE)
	fnDebug(DEBUG_DEV,'COMMAND',_COMMAND)
	FOR(x = 1; x <= 10; x++){
		IF(LENGTH_ARRAY(_VALUES[x])){
			fnDebug(DEBUG_DEV,"'VALUE ',ITOA(x)",_VALUES[x])
		}
	}
	(** Process Commands **)
	SWITCH(_COMMAND){
		CASE 'ENETADDR':{
			FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
				IF(_DEVICE == myClearOne.UNIT[x].ID){
					IF(myClearOne.UNIT[x].IP != _VALUES[1]){
						myClearOne.UNIT[x].IP = _VALUES[1]
					}
				}
			}
		}
		CASE 'VER':{
			FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
				IF(_DEVICE == myClearOne.UNIT[x].ID){
					IF(myClearOne.UNIT[x].VER != _VALUES[1]){
						myClearOne.UNIT[x].VER = _VALUES[1]
					}
					fnCommsRecieved(x)
				}
			}
		}
		DEFAULT:{
			// Rare Case
			IF(_COMMAND = 'TE' && _VALUES[3] = ''){
				_VALUES[3] = _VALUES[2]
				_VALUES[2] = 'R'
			}
			FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
				IF(ATOI(_VALUES[1]) == myClearOne.OBJECT[x].CHAN && _VALUES[2] == myClearOne.OBJECT[x].GROUP && _DEVICE == myClearOne.OBJECT[x].HOST){
					SWITCH(_COMMAND){
						CASE 'MCGAIN':
						CASE 'GAIN':{
							myClearOne.OBJECT[x].GAIN_VAL = ATOI(fnStripCharsRight(REMOVE_STRING(_VALUES[3],'.',1),1))
						}
						CASE 'MCMUTE':
						CASE 'MUTE':{
							myClearOne.OBJECT[x].MUTE = ATOI(_VALUES[3])
						}
						CASE 'MCMINMAX':
						CASE 'MINMAX':{
							myClearOne.OBJECT[x].GAIN_RANGE[1] = ATOI(_VALUES[3])
							myClearOne.OBJECT[x].GAIN_RANGE[2] = ATOI(_VALUES[4])
							SEND_STRING vdvObjects[x],"'RANGE-',ITOA(myClearOne.OBJECT[x].GAIN_RANGE[1]),',',ITOA(myClearOne.OBJECT[x].GAIN_RANGE[2])"
						}
						(** PHONE **)
						CASE 'RING':{
							[vdvObjects[x],236] = ATOI(_VALUES[3])
						}
						CASE 'TE':{
							myClearOne.OBJECT[x].OFF_HOOK = ATOI(_VALUES[3])
						}
						CASE 'XTE':{
							myClearOne.OBJECT[x].OFF_HOOK = ATOI(_VALUES[3])
						}
					}
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS_00)){TIMELINE_KILL(TLID_COMMS_00)}
	TIMELINE_CREATE(TLID_COMMS_00,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnCommsRecieved(INTEGER x){
	IF(TIMELINE_ACTIVE(TLID_COMMS_00+x)){TIMELINE_KILL(TLID_COMMS_00+x)}
	TIMELINE_CREATE(TLID_COMMS_00+x,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnInitComms(){
	fnPoll()
	fnRefresh()
	fnInitPoll()
}

DEFINE_FUNCTION fnRefresh(){
	STACK_VAR INTEGER o
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		STACK_VAR CHAR _CMD[255]
		SWITCH(myClearOne.OBJECT[o].TYPE){
			CASE OBJ_FADER_MC:
			CASE OBJ_FADER:{
				_CMD = 'GAIN'
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
				}
				fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP")
				_CMD = 'MINMAX'
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
				}
				fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP")
			}
		}
		SWITCH(myClearOne.OBJECT[o].TYPE){
			CASE OBJ_FADER:
			CASE OBJ_FADER_MC:
			CASE OBJ_VOIP_TX:
			CASE OBJ_POTS_TX:
			CASE OBJ_BEAM_MUTE:{
				_CMD = 'MUTE'
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
				}
				fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP")
			}
		}
		SWITCH(myClearOne.OBJECT[o].TYPE){
			CASE OBJ_VOIP_RX:
			CASE OBJ_POTS_RX:{
				fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP")
			}
		}
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand(,'**','VER','')
	fnSendCommand(,'**','ENETADDR','')
}


/*********************************************************************
	Device Events
*********************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myClearOne.isIP){
			myClearOne.IP_STATE	= IP_STATE_CONNECTED
			SEND_COMMAND dvDevice, 'SET BAUD 57600 N 8 1 485 DISABLE'
			WAIT 50{
				fnInitComms()
			}
		}
		ELSE{
			myClearOne.IP_STATE	= IP_STATE_NEGOTIATE
		}
	}
	OFFLINE:{
		IF(myClearOne.isIP){
			myClearOne.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myClearOne.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myClearOne.IP_STATE = IP_STATE_OFFLINE
					SWITCH(DATA.NUMBER){
						CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
						CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
						CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
						CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
						CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
						CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
						CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
						CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
						CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
						CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
						CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
					}
					fnRetryConnection()
				}
			}
			fnDebug(DEBUG_ERR,"'Converge IP Error:[',myClearOne.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		fnDebug(DEBUG_DEV,'RAW->',DATA.TEXT)
		IF(myClearOne.IP_STATE != IP_STATE_CONNECTED){
			IF(FIND_STRING(myClearOne.Rx,'user:',1)){
				IF(myClearOne.USERNAME = ''){myClearOne.USERNAME = 'clearone'}
				myClearOne.Rx = ''
				fnDebug(DEBUG_STD,'->DSP',"myClearOne.USERNAME,$0D")
				SEND_STRING dvDevice,"myClearOne.USERNAME,$0D"
			}
			IF(FIND_STRING(myClearOne.Rx,'pass:',1)){
				IF(myClearOne.PASSWORD = ''){myClearOne.PASSWORD = 'converge'}
				myClearOne.Rx = ''
				fnDebug(DEBUG_STD,'->DSP',"myClearOne.PASSWORD,$0D")
				SEND_STRING dvDevice,"myClearOne.PASSWORD,$0D"
			}
			IF(FIND_STRING(myClearOne.Rx,'Level: ',1)){
				REMOVE_STRING(myClearOne.Rx,'Level: ',1)
				myClearOne.USERLEVEL = fnStripCharsRight(REMOVE_STRING(myClearOne.Rx,"$0D,$0A",1),2)
				myClearOne.IP_STATE = IP_STATE_CONNECTED
				myClearOne.Rx = ''
				fnInitComms()
			}
		}
		ELSE{
			WHILE(FIND_STRING(myClearOne.Rx,"$0D,$0A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myClearOne.Rx,"$0D,$0A",1),2))
			}
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR INTEGER x
		x = GET_LAST(vdvControl)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myClearOne.DEBUG = DEBUG_STD
							CASE 'DEV': myClearOne.DEBUG = DEBUG_DEV
							DEFAULT:		myClearOne.DEBUG = DEBUG_ERR
						}
					}
					CASE 'ID':{
						myClearOne.UNIT[x].ID   = DATA.TEXT
						SWITCH(myClearOne.UNIT[x].ID[1]){
							CASE '1':myClearOne.UNIT[x].MODEL = '880'
							CASE '2':myClearOne.UNIT[x].MODEL = 'TH20'
							CASE 'E':myClearOne.UNIT[x].MODEL = 'VH20'
							CASE '3':myClearOne.UNIT[x].MODEL = '840T'
							CASE 'A':myClearOne.UNIT[x].MODEL = '8i'
							CASE 'D':myClearOne.UNIT[x].MODEL = '880T'
							CASE 'H':myClearOne.UNIT[x].MODEL = '880TA'
							CASE 'G':myClearOne.UNIT[x].MODEL = 'SR 1212'
							CASE 'I':myClearOne.UNIT[x].MODEL = 'SR 1212A'
							CASE 'N':myClearOne.UNIT[x].MODEL = 'Beamforming Mic Array'
							CASE 'P':myClearOne.UNIT[x].MODEL = 'CONNECT CobraNet'
							CASE 'S':myClearOne.UNIT[x].MODEL = 'CONNECT Dante'
						}
						SEND_STRING DATA.DEVICE,"'PROPERTY-META,MAKE,ClearOne'"
						SEND_STRING DATA.DEVICE,"'PROPERTY-META,MODEL,',myClearOne.UNIT[x].MODEL"
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myClearOne.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myClearOne.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myClearOne.IP_HOST = DATA.TEXT
							myClearOne.IP_PORT = 23
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'REFRESH':fnRefresh()
				}
			}
			CASE 'RAW':{
				fnSendCommand(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),DATA.TEXT)
			}
			CASE 'PRESET':{
				fnSendCommand("myClearOne.UNIT[x].ID",'PRESET',"DATA.TEXT,' 2'")
			}
			CASE 'MACRO':{
				fnSendCommand("myClearOne.UNIT[x].ID",'MACRO',DATA.TEXT)
			}
		}
	}
}
/*********************************************************************
	Object Control
*********************************************************************/
DEFINE_EVENT DATA_EVENT[vdvObjects]{
	COMMAND:{
		STACK_VAR INTEGER o;
		o = GET_LAST(vdvObjects)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			(** General Commands **)
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':{
						myClearOne.OBJECT[o].HOST  	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myClearOne.OBJECT[o].CHAN  	= ATOI(DATA.TEXT)
					}
					CASE 'STEP':	myClearOne.OBJECT[o].GAIN_STEP  	= ATOI(DATA.TEXT)
					CASE 'TYPE':{
						SWITCH(DATA.TEXT){
							CASE 'FADER':  	myClearOne.OBJECT[o].TYPE = OBJ_FADER;		myClearOne.OBJECT[o].GROUP = 'F';
							CASE 'FADER_MC':  myClearOne.OBJECT[o].TYPE = OBJ_FADER_MC;	myClearOne.OBJECT[o].GROUP = 'F';
							CASE 'MATRIX': 	myClearOne.OBJECT[o].TYPE = OBJ_MATRIX;		myClearOne.OBJECT[o].GROUP = 'X';
							CASE 'POTS_TX':   myClearOne.OBJECT[o].TYPE = OBJ_POTS_TX;		myClearOne.OBJECT[o].GROUP = 'T';
							CASE 'POTS_RX':   myClearOne.OBJECT[o].TYPE = OBJ_POTS_RX;		myClearOne.OBJECT[o].GROUP = 'R';
							CASE 'VOIP_TX':   myClearOne.OBJECT[o].TYPE = OBJ_VOIP_TX;		myClearOne.OBJECT[o].GROUP = 'K';
							CASE 'VOIP_RX':   myClearOne.OBJECT[o].TYPE = OBJ_VOIP_RX;		myClearOne.OBJECT[o].GROUP = 'Z';
							CASE 'BEAM_MIC':  myClearOne.OBJECT[o].TYPE = OBJ_BEAM_MUTE;	myClearOne.OBJECT[o].GROUP = 'V';
						}
					}
				}
			}
			(** POTS Commands **)
			CASE 'XPOINT':{
				fnSendCommand(myClearOne.OBJECT[o].HOST,'MTRX',"DATA.TEXT")
			}
			(** POTS Commands **)
			CASE 'HOOK':{
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_POTS_RX:
					CASE OBJ_VOIP_RX:{
						SWITCH(DATA.TEXT){
							CASE 'ON': fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' 0'")
							CASE 'OFF':fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' 1'")
						}
					}
				}
			}
			(** POTS Commands **)
			CASE 'CALL':{
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_POTS_RX:
					CASE OBJ_VOIP_RX:{
						SWITCH(DATA.TEXT){
							CASE 'END':		 fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' 0'")
							CASE 'ANSWER':  fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' 1'")
						}
					}
				}
			}
			CASE 'DIAL':{
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_POTS_RX:
					CASE OBJ_VOIP_RX:{
						SWITCH(DATA.TEXT){
							CASE 'HANGUP': fnSendCommand(myClearOne.OBJECT[o].HOST,'XTE',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' 0'")
							DEFAULT:			fnSendCommand(myClearOne.OBJECT[o].HOST,'XDIAL',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' ',DATA.TEXT")
						}
					}
				}
			}
			CASE 'DTMF':{
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_POTS_RX:
					CASE OBJ_VOIP_RX:{
						fnSendCommand(myClearOne.OBJECT[o].HOST,'XDIAL',"ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP,' ',DATA.TEXT")
					}
				}
			}
			(** Fader Commands **)
			CASE 'VOLUME':{
				STACK_VAR CHAR _CMD[255]
				STACK_VAR CHAR _PACKET[255]
				_CMD = 'GAIN'
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
				}
				IF(!myClearOne.OBJECT[o].GAIN_STEP){myClearOne.OBJECT[o].GAIN_STEP = 3}
				_PACKET = "ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP"
				SWITCH(DATA.TEXT){
					CASE 'INC':{fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"_PACKET,' ', ITOA(myClearOne.OBJECT[o].GAIN_STEP),' R'")}
					CASE 'DEC':{fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"_PACKET,' -',ITOA(myClearOne.OBJECT[o].GAIN_STEP),' R'")}
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
							fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"_PACKET,' ',DATA.TEXT,' A'")
							TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myClearOne.OBJECT[o].GAIN_PEND_VAL = ATOI(DATA.TEXT)
							myClearOne.OBJECT[o].GAIN_PEND = TRUE
						}
					}
				}
			}
			CASE 'MUTE':{
				STACK_VAR CHAR _CMD[255]
				STACK_VAR CHAR _PACKET[255]
				_CMD = 'MUTE'
				SWITCH(myClearOne.OBJECT[o].TYPE){
					CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
				}
				_PACKET = "ITOA(myClearOne.OBJECT[o].CHAN),' ',myClearOne.OBJECT[o].GROUP"
				SWITCH(DATA.TEXT){
					CASE 'OFF':{		myClearOne.OBJECT[o].MUTE = FALSE}
					CASE 'ON': {		myClearOne.OBJECT[o].MUTE = TRUE}
					CASE 'TOGGLE': {	myClearOne.OBJECT[o].MUTE = !myClearOne.OBJECT[o].MUTE}
				}
				fnSendCommand(myClearOne.OBJECT[o].HOST,_CMD,"_PACKET,' ',ITOA(myClearOne.OBJECT[o].MUTE)")
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL_01]
TIMELINE_EVENT[TLID_VOL_02]
TIMELINE_EVENT[TLID_VOL_03]
TIMELINE_EVENT[TLID_VOL_04]
TIMELINE_EVENT[TLID_VOL_05]
TIMELINE_EVENT[TLID_VOL_06]
TIMELINE_EVENT[TLID_VOL_07]
TIMELINE_EVENT[TLID_VOL_08]
TIMELINE_EVENT[TLID_VOL_09]
TIMELINE_EVENT[TLID_VOL_10]
TIMELINE_EVENT[TLID_VOL_11]
TIMELINE_EVENT[TLID_VOL_12]
TIMELINE_EVENT[TLID_VOL_13]
TIMELINE_EVENT[TLID_VOL_14]
TIMELINE_EVENT[TLID_VOL_15]
TIMELINE_EVENT[TLID_VOL_16]
TIMELINE_EVENT[TLID_VOL_17]
TIMELINE_EVENT[TLID_VOL_18]
TIMELINE_EVENT[TLID_VOL_19]
TIMELINE_EVENT[TLID_VOL_20]{
	STACK_VAR INTEGER g
	STACK_VAR CHAR _CMD[255]
	STACK_VAR CHAR _PACKET[255]
	g = TIMELINE.ID - TLID_VOL_00
	_CMD = 'GAIN'
	SWITCH(myClearOne.OBJECT[g].TYPE){
		CASE OBJ_FADER_MC:_CMD = "'MC',_CMD"
	}
	IF(!myClearOne.OBJECT[g].GAIN_STEP){myClearOne.OBJECT[g].GAIN_STEP = 3}
	_PACKET = "ITOA(myClearOne.OBJECT[g].CHAN),' ',myClearOne.OBJECT[g].GROUP"
	IF(myClearOne.OBJECT[g].GAIN_PEND){
		fnSendCommand(myClearOne.OBJECT[g].HOST,_CMD,"_PACKET,' ',ITOA(myClearOne.OBJECT[g].GAIN_PEND_VAL),' A'")
		myClearOne.OBJECT[g].GAIN_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/*********************************************************************
	Feedback
*********************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myClearOne.OBJECT[x].TYPE){
			CASE OBJ_FADER_MC:
			CASE OBJ_FADER:{
				[vdvObjects[x],198] = (myClearOne.OBJECT[x].MUTE)
				[vdvObjects[x],199] = (myClearOne.OBJECT[x].MUTE)
				SEND_LEVEL vdvObjects[x],1,myClearOne.OBJECT[x].GAIN_VAL
			}
			CASE OBJ_VOIP_RX:
			CASE OBJ_POTS_RX:{
				[vdvObjects[x],238] = (myClearOne.OBJECT[x].OFF_HOOK)
			}
			CASE OBJ_VOIP_TX:
			CASE OBJ_POTS_TX:{
				[vdvObjects[x],198] = (myClearOne.OBJECT[x].MUTE)
			}
		}
	}
	FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
		[vdvControl[x],251] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
		[vdvControl[x],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
	}
}
