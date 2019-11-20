MODULE_NAME='mSanyoProjLegacy'(DEV vdvControl, DEV dvRS232)
/******************************************************************************
	Basic control of Sanyo Generic Projector
	Verify model against functions

	vdvControl Commands
	DEBUG-X 				= Debugging Off (Default)
	INPUT-XXX 			= Go to Input, power on if required
		[PC1|PC2|VID]
	POWER-ON|OFF 		= Send input X to ouput Y
	FREEZE-ON|OFF		= Picture Freeze
	BLANK-ON|OFF		= Video Mute

	Feedback Channels:

	211 = Picture Freeze
	214 = Video Mute

	251 = Communicating
	252 = Busy
	253 = Warming
	254 = Cooling
	255 = Power

******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/
//#DEFINE __TESTING__ 'TRUE'		// Used for module testing

DEFINE_CONSTANT
#IF_NOT_DEFINED __TESTING__
	INTEGER iTimeWarm = 40 		// Time in Seconds {Warm - Test}
	INTEGER iTimeCool = 120 	// Time in Seconds {Cool - Test}
#ELSE
	#WARN 'TEMP SETTINGS IN PLACE!!!'
	INTEGER iTimeWarm = 5 		// Time in Seconds {Warm - Test}
	INTEGER iTimeCool = 10 		// Time in Seconds {Cool - Test}
#END_IF

INTEGER TLID_BUSY 	= 1;		// Warm / Cool Timeline
INTEGER TLID_ADJ 		= 2;		// AutoAdjust Timeline
LONG TLID_POLL 		= 3		// Polling Timeline
LONG TLID_SEND			= 4		// Staggered Sending Timeline
LONG TLID_COMMS		= 5		// Comms Timeout Timeline
LONG TLT_SEND[] 		= {100}	// Stagger Send - 100ms between commands
LONG TLT_COMMS[]		= {60000}// Comms Timeout - 60s
LONG TLT_POLL[] 		= {15000}	// Poll Time
LONG TLT_ADJ[] 		= {3000}	// Auto Adjust Delay

INTEGER chnFreeze		= 211		// Picture Freeze Feedback
INTEGER chnBLANK		= 214		// Picture Mute Feedback
INTEGER chnCOMMS		= 251		// Device Comms Feedback
INTEGER chnWARM		= 253		// Proj Warming Feedback
INTEGER chnCOOL		= 254		// Proj Cooling Feedback
INTEGER chnPOWER		= 255		// Proj Power Feedback

/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
INTEGER DEBUG 					= 0
LONG _1s[] 						= {1000};
INTEGER _CYCLE_INDEX 		= 1
CHAR cPrevInput[10]
CHAR _INPUT[25]
CHAR _CYCLE_INPUTS[10][25]
CHAR cInBuffer[255]
CHAR cOutBuffer[1000]
INTEGER bDesiredPower
INTEGER bPollSent
/******************************************************************************
	Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR _PACKET[]){
	IF(bPollSent){
		SWITCH(_PACKET){
			CASE '00':ON[vdvControl,chnPOWER]
			CASE '80':OFF[vdvControl,chnPOWER]
		}
		bPollSent = FALSE
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}

}
DEFINE_FUNCTION fnSendCommand(CHAR cmd[255]){
	fnDebug('AMX->Sanyo Proj',"cmd,$0D")
	SEND_STRING dvRS232, "cmd,$0D"
	fnInitPoll()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnDebug('AMX->Sanyo Proj',"'CR0',$0D")
	SEND_STRING dvRS232, "'CR0',$0D"
	bPollSent = TRUE
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(DEBUG = 1)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendInputCommand(){
	IF(_INPUT != 'PREVIOUS'){
		cPrevInput = _INPUT
	}
	SWITCH(_INPUT){
		CASE 'PREVIOUS':	SEND_COMMAND vdvControl,"'INPUT-',cPrevInput"
		CASE 'PC1':			fnSendCommand("'C50'")
		CASE 'PC2':			fnSendCommand("'C25'")
		CASE 'VID':			fnSendCommand("'C33'")
	}

	SWITCH(_INPUT){
		CASE '1':
		CASE '2':{
			IF(TIMELINE_ACTIVE(TLID_ADJ)){TIMELINE_KILL(TLID_ADJ)}
			TIMELINE_CREATE(TLID_ADJ,TLT_ADJ,LENGTH_ARRAY(TLT_ADJ),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}

	_INPUT = ''
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{		// RS232 Port Online
	ONLINE:{
		SEND_COMMAND dvRS232,'SET MODE DATA'
		SEND_COMMAND dvRS232,'SET BAUD 19200 N,8,1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		fnDebug('SANYO->AMX',DATA.TEXT)
		WHILE(FIND_STRING(DATA.TEXT,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,"$0D",1),1))
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{	// Control Events
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': DEBUG = ATOI(DATA.TEXT)
				}
			}
			CASE 'RAW':fnSendCommand(DATA.TEXT)
			CASE 'SET_INP_CYCLE':{
				_CYCLE_INPUTS[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT
			}
			CASE 'AUTO':{
				SWITCH(DATA.TEXT){
					CASE 'ADJUST':		fnSendCommand('C89')
				}
			}
			CASE 'INPUT':{
				IF(DATA.TEXT == 'CYCLE'){
					IF(_CYCLE_INPUTS[1] != ''){
						SEND_COMMAND vdvControl, "'INPUT-',_CYCLE_INPUTS[_CYCLE_INDEX]"
					}
				}
				ELSE{
					(** Code for cycling inputs **)
					STACK_VAR INTEGER _COUNT
					_CYCLE_INDEX = 1
					FOR(_COUNT = 1;_COUNT <= 10;_COUNT++){
						IF(_CYCLE_INPUTS[_COUNT] == DATA.TEXT){
							_CYCLE_INDEX = _COUNT+1
							IF(_CYCLE_INPUTS[_CYCLE_INDEX] == ''){
								_CYCLE_INDEX = 1
							}
						}
					}
					(** Code for Actual Input **)
					_INPUT = DATA.TEXT
					IF([vdvControl,chnPOWER]){
						fnSendInputCommand()
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
							fnSendCommand('C0D')
							ON[vdvControl,chnBLANK]

						}
						CASE 'OFF':{
							fnSendCommand('C0E')
							OFF[vdvControl,chnBLANK]
							OFF[vdvControl,chnFreeze]
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
							fnSendCommand("'C43'")
							ON[vdvControl,chnFreeze]
						}
						CASE 'OFF':{
							fnSendCommand("'C44'")
							OFF[vdvControl,chnFreeze]
							OFF[vdvControl,chnBLANK]
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
						fnSendCommand("'C00'")
						bDesiredPower = TRUE
						IF(![vdvControl,chnPOWER] && !TIMELINE_ACTIVE(TLID_BUSY)){
							ON[vdvControl,chnWARM]	// Warming Up
							TIMELINE_CREATE(TLID_BUSY,_1s,LENGTH_ARRAY(_1s),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
					CASE 'OFF':{
						fnSendCommand("'C01'")
						bDesiredPower = FALSE
						OFF[vdvControl,chnFreeze]
						OFF[vdvControl,chnBLANK]
						IF([vdvControl,chnPOWER]){
							ON[vdvControl,chnCOOL]	// Cooling Down
							TIMELINE_CREATE(TLID_BUSY,_1s,LENGTH_ARRAY(_1s),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{	// Comms Timeout
	OFF[vdvControl,chnCOMMS]
	OFF[vdvControl,chnPOWER]
	OFF[vdvControl,chnFreeze]
	OFF[vdvControl,chnBLANK]
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	STACK_VAR LONG _REPS
	_REPS = TIMELINE.REPETITION
	IF( (iTimeWarm == _REPS && [vdvControl,chnWARM]) || ( iTimeCool == _REPS && [vdvControl,chnCOOL]) ){
		SEND_STRING vdvControl, "'TIME-0:00'"
		SWITCH([vdvControl,chnWARM]){
			CASE TRUE:  ON [vdvControl, chnPOWER]
			CASE FALSE: OFF[vdvControl, chnPOWER]
		}
		TIMELINE_KILL(TLID_BUSY);
		OFF[vdvControl,chnWARM]		// Warming Up
		OFF[vdvControl,chnCOOL]		// Cooling Down
		IF(bDesiredPower != [vdvControl, chnPOWER]){
			SWITCH(bDesiredPower){
				CASE TRUE:	SEND_COMMAND vdvControl, 'POWER-ON'
				CASE FALSE:	SEND_COMMAND vdvControl, 'POWER-OFF'
			}
		}
		ELSE IF([vdvControl,chnPOWER]){
			fnSendInputCommand()
		}
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF([vdvControl,chnWARM]){ _TotalSecs = iTimeWarm }
		IF([vdvControl,chnCOOL]){ _TotalSecs = iTimeCool }

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;

		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"

		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_ADJ]{
	SEND_COMMAND vdvControl, 'AUTO-ADJUST'
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
