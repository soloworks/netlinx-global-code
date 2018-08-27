MODULE_NAME='mCasioProjector'(DEV vdvControl, DEV dvRS232)
#WARN 'Bring Module up to date, add RMS Hooks'
/***********************************************************
CASIO Inputs
 - RGB
 - Component
 - Video
 - USB
 - Auto
 - HDMI
 - Wireless
********************************************************************/

INCLUDE 'CustomFunctions'
//#DEFINE __TESTING__ 'TRUE'

DEFINE_CONSTANT
#IF_NOT_DEFINED __TESTING__
	INTEGER ProjectorTimeWarm = 10 // Time in Seconds {Warmup}
	INTEGER ProjectorTimeCool = 10 // Time in Seconds {Cooldown}
#ELSE
	#WARN 'TEMP SETTINGS IN PLACE!!!'
	INTEGER ProjectorTimeWarm = 5 // Time in Seconds {Warmup}
	INTEGER ProjectorTimeCool = 10 // Time in Seconds {Cooldown}
#END_IF

INTEGER TL_BUSY 		= 1;
INTEGER TL_AUTOADJ 	= 2;
LONG TL_POLL 			= 3
LONG TL_SEND			= 4
LONG TL_COMMS			= 5
LONG TLT_SEND[] 		= {100}
LONG TLT_COMMS[]		= {60000}

INTEGER chnPOWER	= 255
INTEGER chnBUSY	= 254
INTEGER chnCOOL	= 253
INTEGER chnWARM	= 252

INTEGER chnCOMMS	= 251

INTEGER chnFreeze	= 241
INTEGER chnBLANK	= 240

DEFINE_VARIABLE
INTEGER DEBUG = 0
LONG time_SECOND[] 	= {1000};
LONG TLT_POLL[] 	= {5000};
CHAR cPrevInput[10]

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
		SEND_COMMAND dvRS232,'SET BAUD 19200 N,8,1 485 DISABLE'
	}
	STRING:{
		fnDebug('CASIO->AMX',DATA.TEXT)
		fnProcessFeedback(DATA.TEXT)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TL_COMMS]{
	OFF[vdvControl,chnCOMMS]
	OFF[vdvControl,chnPOWER]
	OFF[vdvControl,chnFreeze]
	OFF[vdvControl,chnBLANK]
}

DEFINE_FUNCTION fnProcessFeedback(CHAR _PACKET[]){

}

DEFINE_VARIABLE
CHAR _INPUT[25]
CHAR _CYCLE_INPUTS[10][25]
INTEGER _CYCLE_INDEX = 1
CHAR cInBuffer[255]
CHAR cOutBuffer[1000]

DEFINE_START{
	//TIMELINE_CREATE(TL_POLL,TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	//TIMELINE_CREATE(TL_SEND,TLT_SEND, LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TL_POLL]{
	fnSendQuery()
}
DEFINE_FUNCTION fnSendQuery(){
	fnSendCommand('PWR','?')
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'POLLTIME':{
						TLT_POLL[1] = 1000 * ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvRS232,DATA.TEXT
			}
			CASE 'DEBUG':{
				DEBUG = ATOI(DATA.TEXT)
			}
			CASE 'SET_INP_CYCLE':{
				_CYCLE_INPUTS[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT
			}
			CASE 'PICTUREMUTE':{
				//IF(DATA.TEXT = 'ON') 	fnSendCommand("$02,$10,$00,$00,$00,$12")
				//IF(DATA.TEXT = 'OFF') 	fnSendCommand("$02,$11,$00,$00,$00,$13")
			}
			CASE 'ONSCREENMUTE':{
				//IF(DATA.TEXT = 'ON') 	fnSendCommand("$02,$14,$00,$00,$00,$16")
				//IF(DATA.TEXT = 'OFF') 	fnSendCommand("$02,$15,$00,$00,$00,$17")
			}
			CASE 'ASPECT':{
				SWITCH(DATA.TEXT){
					CASE 'Maintain':	fnSendCommand('ARZ','0')
					CASE '16x9':		fnSendCommand('ARZ','1')
					CASE '4x3':			fnSendCommand('ARZ','2')
					CASE 'LETTER':		fnSendCommand('ARZ','3')
					CASE 'FULL':		fnSendCommand('ARZ','4')
					CASE 'TRUE':		fnSendCommand('ARZ','5')
				}
			}
			CASE 'AUTO':{
				SWITCH(DATA.TEXT){
					CASE 'ADJUST':{}	//	fnSendCommand("$02,$0F,$00,$00,$02,$05,$00,$018")
				}
			}
			CASE 'INPUT':{
				IF(DATA.TEXT == 'CYCLE'){
					IF(_CYCLE_INPUTS[1] != ''){
						SEND_COMMAND vdvControl, "'INPUT-',_CYCLE_INPUTS[_CYCLE_INDEX]"
					}
				}
				ELSE{
					STACK_VAR INTEGER _COUNT
					_INPUT = DATA.TEXT
					_CYCLE_INDEX = 1
					FOR(_COUNT = 1;_COUNT <= 10;_COUNT++){
						IF(_CYCLE_INPUTS[_COUNT] == DATA.TEXT){
							_CYCLE_INDEX = _COUNT+1
							IF(_CYCLE_INPUTS[_CYCLE_INDEX] == ''){
								_CYCLE_INDEX = 1
							}
						}
					}
					IF([vdvControl,chnPOWER]){
						fnSendInputCommand()
						OFF[vdvControl,chnFreeze]
					}
					ELSE{
						SEND_COMMAND vdvControl, 'POWER-ON'
					}
				}
			}

			CASE 'BLANK':{
				IF([vdvControl,chnPOWER]){
					SWITCH(DATA.TEXT){
						CASE 'ON':{
							fnSendCommand('BLK','1')
							//fnSendQuery('MUTE')
						}
						CASE 'OFF':{
							fnSendCommand('BLK','0')
							//fnSendQuery('MUTE')
						}
						CASE 'TOGGLE':{
							IF([vdvControl,chnBLANK])  SEND_COMMAND vdvControl, 'BLANK-OFF'
							ELSE								SEND_COMMAND vdvControl, 'BLANK-ON'
						}
					}
				}
			}
			CASE 'FREEZE':{
				IF([vdvControl,chnPOWER]){
					SWITCH(DATA.TEXT){
						CASE 'ON':{
							//fnSendCommand("$01,$98,$00,$00,$01,$01,$9B")
							//fnSendQuery('FREEZE')
						}
						CASE 'OFF':{
							//fnSendCommand("$01,$98,$00,$00,$01,$02,$9C")
							//fnSendQuery('FREEZE')
						}
						CASE 'TOGGLE':{
							IF([vdvControl,chnFreeze]) SEND_COMMAND vdvControl, 'FREEZE-OFF'
							ELSE								SEND_COMMAND vdvControl, 'FREEZE-ON'
						}
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnSendCommand('PWR','1')
						IF(![vdvControl,255] && ![vdvControl,254]){
							ON[vdvControl,254]	// Busy
							ON[vdvControl,252]	// Warming Up
							TIMELINE_CREATE(TL_BUSY,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
					CASE 'OFF':{
						fnSendCommand('PWR','0')
						OFF[vdvControl,chnFreeze]
						OFF[vdvControl,chnBLANK]
						IF([vdvControl,255]){
							ON[vdvControl,254]	// Busy
							ON[vdvControl,253]	// Cooling Down
							TIMELINE_CREATE(TL_BUSY,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TL_BUSY]{
	IF([vdvControl,chnWARM] && (ProjectorTimeWarm == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TL_BUSY)){
			TIMELINE_KILL(TL_BUSY);
		}
		ON[vdvControl, chnPOWER]	// Power
		OFF[vdvControl,chnBUSY]	// Busy
		OFF[vdvControl,chnWARM]	// Warming Up
		fnSendInputCommand()
	}
	ELSE IF([vdvControl,chnCOOL] && (ProjectorTimeCool == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TL_BUSY)){
			TIMELINE_KILL(TL_BUSY);
		}
		OFF[vdvControl,chnPOWER]	// Power
		OFF[vdvControl,chnBUSY]	// Busy
		OFF[vdvControl,chnCOOL]	// Cooling Down
	}
	IF(![vdvControl,chnBUSY]){
		SEND_STRING vdvControl, "'TIME-0:00'"
		IF(TIMELINE_ACTIVE(TL_BUSY)){
			TIMELINE_KILL(TL_BUSY);
		}
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF([vdvControl,chnWARM]){
			_TotalSecs = ProjectorTimeWarm
		}
		IF([vdvControl,chnCOOL]){
			_TotalSecs = ProjectorTimeCool
		}

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;

		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"

		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

DEFINE_FUNCTION fnSendInputCommand(){
	IF(_INPUT != 'PREVIOUS'){
		cPrevInput = _INPUT
	}
	SWITCH(_INPUT){
		CASE 'PREVIOUS':	SEND_COMMAND vdvControl,"'INPUT-',cPrevInput"
		CASE '0':			fnSendCommand('SRC','0')
		CASE '1':			fnSendCommand('SRC','1')
		CASE '2':			fnSendCommand('SRC','2')
		CASE '5':			fnSendCommand('SRC','5')
		CASE '6':			fnSendCommand('SRC','6')
		CASE '7':			fnSendCommand('SRC','7')
		CASE '8':			fnSendCommand('SRC','8')
	}
	/*
	SWITCH(_INPUT){
		CASE 'PC1':
		CASE 'PC2':{
			IF(TIMELINE_ACTIVE(TL_AUTOADJ)){TIMELINE_KILL(TL_AUTOADJ)}
			TIMELINE_CREATE(TL_AUTOADJ,time_SECOND,LENGTH_ARRAY(time_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
		}
	}
	*/
	_INPUT = ''
}

DEFINE_EVENT TIMELINE_EVENT[TL_AUTOADJ]{
	IF(TIMELINE.REPETITION == 3){
		IF(TIMELINE_ACTIVE(TL_AUTOADJ)){
			TIMELINE_KILL(TL_AUTOADJ)
		}
		SEND_COMMAND vdvControl, 'AUTO-ADJUST'
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR cmd[], CHAR Val[]){
	fnDebug('AMX->CASIO',"'(',cmd,Val,')'")
	SEND_STRING dvRS232,"'(',cmd,Val,')'"
}


DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(DEBUG = 1)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
