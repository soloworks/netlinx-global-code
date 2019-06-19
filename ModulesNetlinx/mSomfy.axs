MODULE_NAME='mSomfy'(DEV dv485, DEV vdvControl)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Set ID to be DeviceID as specified on the unit
******************************************************************************/
DEFINE_TYPE STRUCTURE uSomfy{
	INTEGER DEBUG
	INTEGER ID[3]
}

DEFINE_VARIABLE
uSomfy mySomfy
LONG TLT_POLL[]		= {  10000 }
LONG TLT_COMMS[]		= {  30000 }

DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$A4,$0B","")
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR CMD[20]
		CMD = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)
		SWITCH(CMD){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':{
						mySomfy.ID[1] = HEXTOI(MID_STRING(DATA.TEXT,5,2))
						mySomfy.ID[2] = HEXTOI(MID_STRING(DATA.TEXT,3,2))
						mySomfy.ID[3] = HEXTOI(MID_STRING(DATA.TEXT,1,2))
					}
					CASE 'DEBUG':{
						mySomfy.DEBUG = (DATA.TEXT == 'TRUE')
					}
					CASE 'PAIR':{
						fnSendCommand("$97,$0C","ATOI(DATA.TEXT)")
					}
				}
			}
			CASE 'CONTROL_POSITION':
			CASE 'CONTROL_TILT':
			CASE 'CONTROL_DIM':{
				STACK_VAR INTEGER _CMD
				STACK_VAR INTEGER _CHAN
				STACK_VAR INTEGER _DIR
				_CHAN = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				SWITCH(DATA.TEXT){
					CASE 'PLUS':   _DIR = $00
					CASE 'MINUS':  _DIR = $01
					CASE 'UP':     _DIR = $01
					CASE 'DOWN':   _DIR = $02
					CASE 'STOP':   _DIR = $03
					CASE 'PRESET': _DIR = $04
				}
				
				SWITCH(CMD){
					CASE 'CONTROL_POSITION':fnSendCommand("$80,$0D","_CHAN,_DIR")
					CASE 'CONTROL_TILT':    fnSendCommand("$81,$0E","_CHAN,_DIR,$20")
					CASE 'CONTROL_DIM':     fnSendCommand("$82,$0E","_CHAN,_DIR,$20")
				}
				
			}
		}
	}
}

DEFINE_EVENT DATA_EVENT[dv485]{
	ONLINE:{
		SEND_COMMAND dv485, "'SET BAUD 4800 O 8 1 485 ENABLE'"
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		STACK_VAR INTEGER x
		STACK_VAR CHAR MSG[20]
		fnDebug('->ENC',fnBytesToString(DATA.TEXT))
		FOR(x = 1; x <= LENGTH_ARRAY(DATA.TEXT); x++){
			MSG = "MSG, DATA.TEXT[x] + $FF"
		}
		fnDebug('->MSG',fnBytesToString(MSG))
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR _CMD[], CHAR _PARAM[]){
	STACK_VAR CHAR _MSG[20]
	STACK_VAR INTEGER x
	STACK_VAR INTEGER _iCount
	STACK_VAR INTEGER _iChk
	STACK_VAR CHAR _cChk[4]

	_MSG = "_CMD,$05,$00,$FF,$FF"	// _CMD + _Reserved + NodeID Transmiter[3]
	//_MSG = "_MSG,$05,$89,$79"	// NodeID Reciever
	//_MSG = "_MSG,$11,$D7,$05"	// NodeID Reciever
	_MSG = "_MSG,mySomfy.ID[1],mySomfy.ID[2],mySomfy.ID[3]"// NodeID Reciever
	_MSG = "_MSG,_PARAM"
	fnDebug('MSG->',fnBytesToString(_MSG))
	FOR(_iCount = 1;_iCount <= LENGTH_ARRAY(_MSG);_iCount++){
		_MSG[_iCount] = $FF - _MSG[_iCount]
		_iChk = _iChk + _MSG[_iCount]
	}
	fnDebug('ENC->',fnBytesToString(_MSG))
	_iChk = _iChk
	_cChk = fnPadLeadingChars(ITOHEX(_iChk),'0',4)
	_MSG = "_MSG,HEXTOI(LEFT_STRING(_cChk,2)),HEXTOI(RIGHT_STRING(_cChk,2))"
	fnDebug('SND->',fnBytesToString(_MSG))
	
	
	SEND_STRING dv485,_MSG
	
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(mySomfy.DEBUG){
		STACK_VAR CHAR _Ch[100]
		STACK_VAR INTEGER _iCount
		FOR(_iCount = 1;_iCount <= LENGTH_ARRAY(MsgData);_iCount++){
			_Ch = "_Ch,ITOHEX(MsgData[_iCount])"
		}
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,25] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EOF
******************************************************************************/