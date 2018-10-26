MODULE_NAME='mCloud_CDI-S200'(DEV vdvUnit, DEV vdvZones[], DEV dvRS232)
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uZone{
	INTEGER MUSIC_LVL
	INTEGER SOURCE
	INTEGER MIC[2]
}

DEFINE_TYPE STRUCTURE uSystem{
	uZone   ZONE[3]
	INTEGER DEBUG
	INTEGER DEF_STEP
	CHAR    Rx
}

DEFINE_CONSTANT
LONG TLID_POLL  = 1
LONG TLID_COMMS = 2

DEFINE_VARIABLE
LONG TLT_POLL[]  = {15000}
LONG TLT_COMMS[] = {40000}
uSystem myCDI

DEFINE_START{
	CREATE_BUFFER dvRS232,myCDI.Rx
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR targ[], CHAR cmdID,CHAR cmdMod,CHAR cmdVal[]){
	SEND_STRING dvRS232, "'<',targ,',',cmdID,cmdMOD,cmdVal'/>'"
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand('Z1.MU','L','U','0')
	fnSendCommand('Z2.MU','L','U','0')
	fnSendCommand('Z3.MU','L','U','0')
}

DEFINE_EVENT DATA_EVENT[vdvUnit]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'RAW':fnSendCommand(fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2))
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvZones]{
	COMMAND:{
		STACK_VAR INTEGER iZone
		iZone = GET_LAST(vdvZones)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'STEP':STEP = ATOI(DATA.TEXT)
				}
			}
			CASE 'RAW':fnSendCommand(fnGetCSV(DATA.TEXT,1),fnGetCSV(DATA.TEXT,2))
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
						SWITCH([vdvZones[iZone],199]){
							CASE FALSE: SEND_COMMAND vdvZones[iZone], 'MUTE-ON'	
							CASE TRUE:	SEND_COMMAND vdvZones[iZone], 'MUTE-OFF'
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
		// Eat up garbage
		WHILE(myCDI.Rx[1] == 'H'){GET_BUFFER_CHAR(myCDI.Rx)}
		// Process a packet
		WHILE(FIND_STRING(DATA.TEXT,"'>'",1) > 0){
			// Clear any other garbage
			REMOVE_STRING(DATA.TEXT,"'<'",1)
			// Process
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,"'/>'",1),2))
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	STACK_VAR CHAR dest[10]
	STACK_VAR CHAR subDest
	STACK_VAR CHAR cmdID
	STACK_VAR CHAR cmdMOD
	STACK_VAR CHAR cmdVAL[5]
	
	dest = fnStripCharsRight(REMOVE_STRING(pData,',',1),1)
	IF(FIND_STRING(dest,'.',1)){
		STACK_VAR CHAR d[5]
		d = fnStripCharsRight(REMOVE_STRING(_DEST,'.',1),1) )
		subDest = dest
		dest = d
	}
	
	cmdID = GET_BUFFER_CHAR(pData)
		
	SWITCH(dest){
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
							SEND_LEVEL vdvZones[_ZONE], 1, math_round(_fVol)
						}
						ELSE{
							SEND_LEVEL vdvZones, 1, math_round(_fVol)
						}
					}
				}
				CASE 's':{
					IF(_PARAM[1] == 'a'){
						GET_BUFFER_CHAR(_PARAM)
						IF(_ZONE){
							ON[vdvZones[_ZONE], ATOI(_PARAM)]
						}
						ELSE{
							ON[vdvZones, ATOI(_PARAM)]
						}
					}
				}
				CASE 'm':{
					IF(_ZONE){
						ON[vdvZones[_ZONE],199]
					}
					ELSE{
						ON[vdvZones, 199]
					}
				}
				CASE 'o':{
					IF(_ZONE){
						OFF[vdvZones[_ZONE],199]
					}
					ELSE{
						OFF[vdvZones, 199]
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
		SEND_STRING 0:0:0, "ITOA(vdvUnit.Number),':',Msg, ':', MsgData"
	}
}
