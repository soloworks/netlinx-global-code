MODULE_NAME='mCloud_CDI-S200'(DEV vdvControl[], DEV dvRS232)
INCLUDE 'CustomFunctions'

DEFINE_VARIABLE
INTEGER DEBUG 	= 1
INTEGER STEP	= 5

DEFINE_MUTUALLY_EXCLUSIVE
([vdvControl,1],[vdvControl,2],[vdvControl,3],[vdvControl,4],[vdvControl,5],[vdvControl,6] )

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		//SEND_COMMAND dvRS232, 'SET MODE DATA'
		//SEND_COMMAND dvRS232, 'SET MODE SERIAL'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
	}
}


DEFINE_FUNCTION fnSendCommand(CHAR targ[], CHAR cmd[]){
	SEND_STRING dvRS232, "'<',targ,',',cmd,'/>'"
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR INTEGER iZone
		iZone = GET_LAST(vdvControl)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'STEP':STEP = ATOI(DATA.TEXT)
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':		fnSendCommand("'Z',ITOA(iZone),'.MU'","'LU',ITOA(STEP)")
					CASE 'DEC':		fnSendCommand("'Z',ITOA(iZone),'.MU'","'LD',ITOA(STEP)")
					DEFAULT:			fnSendCommand("'Z',ITOA(iZone),'.MU'","'LA',DATA.TEXT")
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		fnSendCommand("'Z',ITOA(iZone),'.MU'","'M'")
					CASE 'OFF':		fnSendCommand("'Z',ITOA(iZone),'.MU'","'O'")
					CASE 'TOGGLE':{
						SWITCH([vdvControl[iZone],199]){
							CASE FALSE: SEND_COMMAND vdvControl[iZone], 'MUTE-ON'	
							CASE TRUE:	SEND_COMMAND vdvControl[iZone], 'MUTE-OFF'
						}
					}
				}
			}
			CASE 'INPUT':{fnSendCommand("'Z',ITOA(iZone),'.MU'","'SA',DATA.TEXT")}
		}
	}
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	STRING:{
		WHILE(FIND_STRING(DATA.TEXT,"'>'",1) > 0){
			fnProcessFeedback(REMOVE_STRING(DATA.TEXT,"'>'",1));
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR _Feedback[]){
	STACK_VAR CHAR _DEST[10]
	STACK_VAR CHAR _TYPE
	STACK_VAR CHAR _PARAM[5]
	STACK_VAR INTEGER _ZONE
	GET_BUFFER_CHAR(_Feedback)
	_DEST = fnStripCharsRight(REMOVE_STRING(_Feedback,',',1),1)
	_TYPE = GET_BUFFER_CHAR(_Feedback)
	_Param = fnStripCharsRight(REMOVE_STRING(_Feedback,'/>',1),2)
	IF(FIND_STRING(_DEST,'.',1)){
		GET_BUFFER_CHAR(_DEST)
		_ZONE =ATOI( fnStripCharsRight(REMOVE_STRING(_DEST,'.',1),1) )
	}
	SWITCH(_DEST){
		CASE 'mu':{
			SWITCH(_TYPE){
				CASE 'l':{
					IF(_PARAM[1] == 'a'){
						STACK_VAR FLOAT _fVol
						STACK_VAR INTEGER _iVol
						GET_BUFFER_CHAR(_PARAM)
						_fVol = 180 - ATOF(_PARAM)
						fnDebug('_fVol',"FTOA(_fVol)")
						IF(_fVol <= 90){
							//
						}
						ELSE{
							_fVol = 90 + (((_fVol-90) / 90)*165)
							//_fVol = 90 + ((_fVol / 165)*255)
						}
						fnDebug('_fVol',"FTOA(_fVol)")
						IF(_ZONE){
							SEND_LEVEL vdvControl[_ZONE], 1, math_round(_fVol)
						}
						ELSE{
							SEND_LEVEL vdvControl, 1, math_round(_fVol)
						}
					}
				}
				CASE 's':{
					IF(_PARAM[1] == 'a'){
						GET_BUFFER_CHAR(_PARAM)
						IF(_ZONE){
							ON[vdvControl[_ZONE], ATOI(_PARAM)]
						}
						ELSE{
							ON[vdvControl, ATOI(_PARAM)]
						}
					}
				}
				CASE 'm':{
					IF(_ZONE){
						ON[vdvControl[_ZONE],199]
					}
					ELSE{
						ON[vdvControl, 199]
					}
				}
				CASE 'o':{
					IF(_ZONE){
						OFF[vdvControl[_ZONE],199]
					}
					ELSE{
						OFF[vdvControl, 199]
					}
				}
			}
		}
	}
}

define_function char math_is_whole_number(double a) {
    stack_var slong wholeComponent
    wholeComponent = type_cast(a)
    return wholeComponent == a
}

define_function slong math_floor(double a) {
    if (a < 0 && !math_is_whole_number(a)) {
	return type_cast(a - 1.0)
    } else {
	return type_cast(a)
    }
}

define_function slong math_round(DOUBLE a) {
    return math_floor(a + 0.5)
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(DEBUG = 1)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl[1].Number),':',Msg, ':', MsgData"
	}
}
