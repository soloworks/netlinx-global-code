MODULE_NAME='mZero88ChilliNet'(DEV vdvGroup[], DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Zero88 ChillNet Module
	vdvGroup defaults to Dimmer but can be Area
	PROPERTY-MODE,[DIMMER|AREA]
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uGroup{
	INTEGER iLEVEL[100]
	INTEGER iMEMORY
	INTEGER iSEQUENCE	
	INTEGER iCHANNELS
	CHAR 	  cMODE
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timelines **)
LONG TLID_POLL 	= 1;
LONG TLID_SEND		= 2;
LONG TLID_COMMS_0	= 100;
LONG TLID_COMMS_1	= 101;
LONG TLID_COMMS_2	= 102;
LONG TLID_COMMS_3	= 103;
LONG TLID_COMMS_4	= 104;
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
(** Timeline Times **)
LONG TLT_POLL[] 	= {45000}	// Poll every 45 Seconds
LONG TLT_COMMS[] 	= {120000}	// Timeout 2 mins
LONG TLT_SEND[] 	= {50}	// Timeout 2 mins
(** Module Control **)
uGroup myGroups[100]
CHAR 	  cRxBuffer[500]
CHAR 	  cTxBuffer[1000]
/******************************************************************************
	Utility Functions
******************************************************************************/
(** Actviate / Reactivate Polling **)
DEFINE_FUNCTION fnInitPolling(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){
		TIMELINE_KILL(TLID_POLL)
	}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnSendCommand(CHAR pPARAM1[4],CHAR pPARAM2[4],CHAR pPARAM3[4]){
	STACK_VAR CHAR _ToSend[255];
	_ToSend = '@';
	_ToSend = "_ToSend,pPARAM1"
	IF(LENGTH_ARRAY(pPARAM2)){
		_ToSend = "_ToSend,':',pPARAM2"
	}
	IF(LENGTH_ARRAY(pPARAM3)){
		_ToSend = "_ToSend,':',pPARAM3"
	}
	_ToSend = "_ToSend,$0D"
	IF(TIMELINE_ACTIVE(TLID_SEND)){
		cTxBuffer = "cTxBuffer,_ToSend"
	}
	ELSE{
		SEND_STRING dvRS232, _ToSend;
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	fnInitPolling();
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	IF(FIND_STRING(cTxBuffer,"$0D",1)){
		SEND_STRING dvRS232, REMOVE_STRING(cTxBuffer,"$0D",1)
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pPacket[]){
	STACK_VAR CHAR _CMD[2]
	STACK_VAR CHAR _P1[2]
	STACK_VAR CHAR _P2[5]
	STACK_VAR CHAR _P3[5]
	GET_BUFFER_CHAR(pPacket)	// Remove @
	_CMD = GET_BUFFER_STRING(pPacket,2)
	_P1 = fnStripCharsRight(REMOVE_STRING(pPacket,':',1),1)
	IF(FIND_STRING(pPacket,':',1)){
		_P2 = fnStripCharsRight(REMOVE_STRING(pPacket,':',1),1)
	}
	ELSE{
		_P2 = pPacket
	}
	GET_BUFFER_CHAR(_P2)
	_P3 = pPacket
	GET_BUFFER_CHAR(_P3)
	SWITCH(_CMD){
		CASE 'RL':{
			STACK_VAR INTEGER _GRP
			STACK_VAR INTEGER _CHAN
			STACK_VAR INTEGER _LVL
			_GRP = ATOI(_P2)
			_CHAN = ATOI(_P1)+1
			IF(_P3 == 'FF'){
				_LVL = 100
			}
			ELSE{
				_LVL = ATOI(_P3)
			}
			IF(_GRP <= LENGTH_ARRAY(vdvGroup)){
				IF(myGroups[_GRP].iCHANNELS <= _CHAN){
					myGroups[_GRP].iLEVEL[_CHAN] = _LVL;
					SEND_LEVEL vdvGroup[_GRP],_CHAN,_LVL
				}
			}
		}
		CASE 'RE':{
			STACK_VAR INTEGER _GRP;
			STACK_VAR INTEGER _MEM;
			_GRP = ATOI(_P2)
			_MEM = ATOI(_P1)
			IF(_GRP <= LENGTH_ARRAY(vdvGroup)){
				myGroups[_GRP].iMEMORY = _MEM;
				IF(TIMELINE_ACTIVE(TLID_COMMS_0+_GRP)){
					TIMELINE_KILL(TLID_COMMS_0+_GRP)
				}
				TIMELINE_CREATE(TLID_COMMS_0+_GRP,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, cRxBuffer
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE,'SET BAUD 9600,N,8,1 485 DISABLE'
		fnInitPolling();
	}
	STRING:{
		WHILE(FIND_STRING(cRxBuffer,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cRxBuffer,"$0D",1),1))
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvGroup]{
	COMMAND:{
		STACK_VAR INTEGER ID;ID = GET_LAST(vdvGroup);
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'CHANNELS':myGroups[ID].iCHANNELS = ATOI(DATA.TEXT);
					CASE 'MODE':{
						SWITCH(DATA.TEXT){
							CASE 'DIMMER':{myGroups[ID].cMODE = 'D'}
							CASE 'AREA':{	myGroups[ID].cMODE = 'A'}
						}
					}
				}
			}
			CASE 'SETCHAN':{
				STACK_VAR CHAR _CHAN[4]
				STACK_VAR CHAR _GRP[3]
				STACK_VAR CHAR _LVL[4]
				_CHAN = "'SC',fnPadLeadingChars(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),'0',2)"
				_GRP 	= "myGroups[ID].cMODE,fnPadLeadingChars(ITOA(ID),'0',2)"
				_LVL 	= "'L',fnPadLeadingChars(DATA.TEXT,'0',2)"
				IF(_LVL == 'L100'){_LVL = 'LFF'}
				fnSendCommand(_CHAN,_GRP,_LVL)
			}
			CASE 'MEMORY':{
				STACK_VAR CHAR _GRP[3]
				STACK_VAR CHAR _MEM[4]
				_MEM = "'PM',fnPadLeadingChars(DATA.TEXT,'0',2)"
				_GRP 	= "myGroups[ID].cMODE,fnPadLeadingChars(ITOA(ID),'0',2)"
				fnSendCommand(_MEM,_GRP,'F00')
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	STACK_VAR INTEGER g;
	FOR(g = 1; g <= LENGTH_ARRAY(vdvGroup); g++){
		SWITCH(myGroups[g].cMODE){
			CASE 'D':fnSendCommand("'DM',fnPadLeadingChars(ITOA(g),'0',2)",'','')
			CASE 'A':fnSendCommand("'RM',fnPadLeadingChars(ITOA(g),'0',2)",'','')
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER d;
	FOR(d = 1; d <= LENGTH_ARRAY(vdvGroup); d++){
		[vdvGroup[d],251] = (TIMELINE_ACTIVE(TLID_COMMS_0+d))
	}
}