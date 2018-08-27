MODULE_NAME='mRako'(DEV vdvControl, DEV dvRS232)

INCLUDE 'CustomFunctions'
DEFINE_CONSTANT
LONG TL_ID_Send  = 1
LONG TLT_Send[]  = {200}

DEFINE_VARIABLE
CHAR cSendBuffer[400]
CHAR cHouse[5] 	= ''
CHAR cRoom[5] 		= ''
CHAR cChannel[5] 	= ''

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:SEND_COMMAND DATA.DEVICE,'SET BAUD 9600 N 8 1 485 DISABLE'
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight( REMOVE_STRING(DATA.TEXT,'-',1), 1)){
			CASE 'HOUSE':	fnSendCommand('HO',DATA.TEXT)
			CASE 'ROOM':	fnSendCommand('RO',DATA.TEXT)
			CASE 'CHANNEL':fnSendCommand('CH',DATA.TEXT)
			CASE 'SCENE':{
				SWITCH(DATA.TEXT){
					CASE '0':fnSendCommand('OF','')
					DEFAULT: fnSendCommand('SC',DATA.TEXT)
				}
			}
			CASE 'RAISE':{
				fnSendCommand('CH',DATA.TEXT)
				fnSendCommand('CO','1')
			}
			CASE 'LOWER':{
				fnSendCommand('CH',DATA.TEXT)
				fnSendCommand('CO','2')
			}
			CASE 'STOP':{
				fnSendCommand('CH',DATA.TEXT)
				fnSendCommand('CO','15')
			}
			CASE 'SET':{
				fnSendCommand('CH',fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				fnSendCommand('LE',DATA.TEXT)
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TL_ID_Send]{
	IF(FIND_STRING(cSendBuffer,"$0D",1) > 0){
		SEND_STRING dvRS232, REMOVE_STRING(cSendBuffer,"$0D",1)
		TIMELINE_CREATE(TL_ID_Send,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnSendCommand_INT(CHAR _CMD[],CHAR _VALUE[]){
	cSendBuffer = "cSendBuffer,_CMD"
	IF(LENGTH_ARRAY(_VALUE)){ cSendBuffer = "cSendBuffer,':',_VALUE"}
	cSendBuffer = "cSendBuffer,$0D"
	IF(!TIMELINE_ACTIVE(TL_ID_Send)){
		SEND_STRING dvRS232, REMOVE_STRING(cSendBuffer,"$0D",1)
		TIMELINE_CREATE(TL_ID_Send,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR _CMD[],CHAR _VALUE[]){
	SWITCH(_CMD){
		CASE 'HO':{
			IF(cHouse != _VALUE){
				cHouse = _VALUE
				fnSendCommand_INT(_CMD,_VALUE)
			}
		}
		CASE 'RO':{
			IF(cRoom != _VALUE){
				cRoom = _VALUE
				fnSendCommand_INT(_CMD,_VALUE)
			}
		}
		CASE 'CH':{
			IF(cChannel != _VALUE){
				cChannel = _VALUE
				fnSendCommand_INT(_CMD,_VALUE)
			}
		}
		DEFAULT:{
				fnSendCommand_INT(_CMD,_VALUE)
		}
	}
}