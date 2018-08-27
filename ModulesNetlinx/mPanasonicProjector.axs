MODULE_NAME='mPanasonicProjector'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic control of Panasonic Projector
	Verify model against functions
	
	vdvControl Commands
	DEBUG-X 				= Debugging Off (Default)
	INPUT-XXX 			= Go to Input, power on if required
		[VIDEO|SVIDEO|RGB1|RGB2|AUX|DVI]
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
/******************************************************************************
	Module Constructs
******************************************************************************/
DEFINE_TYPE STRUCTURE uPanaProj{
	// Config Settings
	INTEGER 	TIME_WARM
	INTEGER 	TIME_COOL
	
	// Comms Settings
	INTEGER 	DEBUG
	CHAR 		BAUD[20]
	CHAR		Tx[1000]
	CHAR		Rx[1000]
	INTEGER 	isIP
	INTEGER	CONN_STATE
	INTEGER	IP_PORT
	CHAR		IP_HOST[255]
	CHAR		IP_USER[30]
	CHAR		IP_PASS[30]
	CHAR 		IP_HASH[255]
	INTEGER 	LAST_POLL
	CHAR	 	DES_INPUT[10]
	
	// State Values
	INTEGER	PROJ_STATE
	INTEGER 	FREEZE
	INTEGER 	PIC_MUTE
	INTEGER 	ASPECT_RATIO
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER PROJ_STATE_OFF	= 1
INTEGER PROJ_STATE_ON	= 2
INTEGER PROJ_STATE_WARM	= 3
INTEGER PROJ_STATE_COOL	= 4

INTEGER CONN_STATE_OFFLINE	= 0
INTEGER CONN_STATE_TRYING	= 1
INTEGER CONN_STATE_SECURITY= 2
INTEGER CONN_STATE_ONLINE	= 3

LONG TLID_BUSY 	= 1;		// Warm / Cool Timeline
LONG TLID_ADJ 		= 2;		// AutoAdjust Timeline
LONG TLID_POLL 		= 3		// Polling Timeline
LONG TLID_SEND			= 4		// Staggered Sending Timeline
LONG TLID_COMMS		= 5		// Comms Timeout Timeline


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
VOLATILE uPanaProj myPanaProj

LONG TLT_1s[] 			= {1000}
LONG TLT_SEND[] 		= {100}	// Stagger Send - 100ms between commands
LONG TLT_COMMS[]		= {60000}// Comms Timeout - 60s
LONG TLT_POLL[] 		= {15000}	// Poll Time
LONG TLT_ADJ[] 		= {3000}	// Auto Adjust Delay

/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice,  myPanaProj.Rx
	myPanaProj.isIP = (dvDevice.Number)
	myPanaProj.TIME_WARM = 30
	myPanaProj.TIME_COOL = 30
}

/******************************************************************************
	Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR _PACKET[]){
}
DEFINE_FUNCTION fnSendCommand(CHAR ThisCommand[], CHAR Param[]){
	 STACK_VAR CHAR ToSend[100];

	 ToSend = "$02";						//STX
	ToSend = "ToSend,'ADZZ;'";			//Device Address (ZZ = ALL)
	 ToSend = "ToSend,ThisCommand";	//Add Command

	 IF(LENGTH_ARRAY(Param) > 0) ToSend = "ToSend, ':', Param"

	 ToSend = "ToSend,$03";				//ETX

	 fnDebug('Sending Power Command',ThisCommand);
	 SEND_STRING dvDevice, "ToSend";
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myPanaProj.DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendInputCommand(){
	SWITCH(myPanaProj.DES_INPUT){
		  CASE 'VIDEO':	fnSendCommand('IIS','VID');
		  CASE 'SVIDEO':	fnSendCommand('IIS','SVD');
		  CASE 'RGB1':		fnSendCommand('IIS','RG1');
		  CASE 'RGB2':		fnSendCommand('IIS','RG2');
		  CASE 'AUX':		fnSendCommand('IIS','AUX');
		  CASE 'DVI':		fnSendCommand('IIS','DVI');
		  CASE 'HDMI1':
		  CASE 'HDMI':		fnSendCommand('IIS','HD1');
	}
	SWITCH(myPanaProj.DES_INPUT){
		CASE 'RGB1':
		CASE 'RGB2':{
			IF(TIMELINE_ACTIVE(TLID_ADJ)){TIMELINE_KILL(TLID_ADJ)}
			TIMELINE_CREATE(TLID_ADJ,TLT_ADJ,LENGTH_ARRAY(TLT_ADJ),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	myPanaProj.DES_INPUT = ''
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myPanaProj.BAUD = ''){myPanaProj.BAUD = '9600'}
		SEND_COMMAND dvDevice, "'SET MODE DATA'"
		SEND_COMMAND dvDevice, "'SET BAUD ',myPanaProj.BAUD,' N 8 1 485 DISABLE'"
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
		fnSendCommand('QPW','')
	}
	STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand('QPW','')
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'TIMER':{
						myPanaProj.TIME_WARM = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						myPanaProj.TIME_COOL = ATOI(DATA.TEXT)
					}
					CASE 'BAUD':{
						myPanaProj.BAUD = DATA.TEXT
						SEND_COMMAND dvDevice, "'SET MODE DATA'"
						SEND_COMMAND dvDevice, "'SET BAUD ',myPanaProj.BAUD,' N 8 1 485 DISABLE'"
						IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
						TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
						fnSendCommand('QPW','')
					}
				}
			}
			CASE 'RAWIN':{
				fnSendCommand(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1),DATA.TEXT)
			}
			CASE 'AUTO':{
				SWITCH(DATA.TEXT){
					CASE 'ADJUST':		fnSendCommand('OAS','');
				}
			}
			CASE 'INPUT':{
				myPanaProj.DES_INPUT = DATA.TEXT
				IF([vdvControl,chnPOWER]){
					fnSendInputCommand()
				}
				ELSE{
					SEND_COMMAND vdvControl, 'POWER-ON'
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnSendCommand('PON','');
						IF(![vdvControl,chnPOWER] && !TIMELINE_ACTIVE(TLID_BUSY)){
							ON[vdvControl,chnWARM]	// Warming Up
							TIMELINE_CREATE(TLID_BUSY,TLT_1s,LENGTH_ARRAY(TLT_1s),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
					CASE 'OFF':{
						fnSendCommand('POF','');
						OFF[vdvControl,chnFreeze]
						OFF[vdvControl,chnBLANK]
						IF([vdvControl,chnPOWER]){
							ON[vdvControl,chnCOOL]	// Cooling Down
							TIMELINE_CREATE(TLID_BUSY,TLT_1s,LENGTH_ARRAY(TLT_1s),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	STACK_VAR LONG _REPS
	_REPS = TIMELINE.REPETITION
	IF( (myPanaProj.TIME_WARM == _REPS && [vdvControl,chnWARM]) || ( myPanaProj.TIME_COOL == _REPS && [vdvControl,chnCOOL]) ){
		SEND_STRING vdvControl, "'TIME-0:00'"
		SWITCH([vdvControl,chnWARM]){
			CASE TRUE:  ON [vdvControl, chnPOWER]
			CASE FALSE: OFF[vdvControl, chnPOWER]
		}
		TIMELINE_KILL(TLID_BUSY);
		OFF[vdvControl,chnWARM]		// Warming Up
		OFF[vdvControl,chnCOOL]		// Cooling Down
		IF([vdvControl,chnPOWER]){
			fnSendInputCommand()
		}
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF([vdvControl,chnWARM]){ _TotalSecs = myPanaProj.TIME_WARM }
		IF([vdvControl,chnCOOL]){ _TotalSecs = myPanaProj.TIME_COOL }

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;
		  
		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"
		
		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLT_ADJ]{
	SEND_COMMAND vdvControl, 'AUTO-ADJUST'
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
