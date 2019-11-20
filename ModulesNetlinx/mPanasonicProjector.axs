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
	CHAR   	LAST_SENT[20]
	CHAR	 	DES_INPUT[10]
	INTEGER  DesVMUTE

	// State Values
	INTEGER	PROJ_STATE
	INTEGER 	FREEZE
	INTEGER 	VMUTE
	INTEGER 	ASPECT_RATIO
	INTEGER  POWER
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
INTEGER chnVMUTE	   = 214		// Picture Mute Feedback
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
}

/******************************************************************************
	Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){

	SWITCH(myPanaProj.LAST_SENT){
		CASE 'QPW':{
			myPanaProj.POWER = ATOI(pData)
			// Request Shutter Status
			fnSendCommand('QSH','')
		}

		CASE 'QSH':{
			myPanaProj.VMUTE = ATOI(pData)
			IF(myPanaProj.VMUTE != myPanaProj.DesVMUTE){
				SWITCH(myPanaProj.desVMute){
					CASE TRUE:  fnSendCommand('OSH','1')
					CASE FALSE: fnSendCommand('OSH','0')
				}
			}
		}
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pCmd[], CHAR pParam[]){
	STACK_VAR CHAR pPacket[100]

	// Build Command
	pPacket = "pCmd"
	IF(LENGTH_ARRAY(pParam)) pPacket = "pPacket, ':', pParam"

	// Store Command
	myPanaProj.LAST_SENT = pPacket

	// Add delims
	pPacket = "$02,'ADZZ;',pPacket,$03"

	// Send it out
	SEND_STRING dvDevice, pPacket

	// Reset Polling
	fnInitPoll()
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
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand('QPW','')
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(myPanaProj.BAUD = ''){myPanaProj.BAUD = '9600'}
		SEND_COMMAND dvDevice, "'SET MODE DATA'"
		SEND_COMMAND dvDevice, "'SET BAUD ',myPanaProj.BAUD,' N 8 1 485 DISABLE'"
		fnPoll()
	}
	STRING:{
		fnDebug('Pana->AMX',DATA.TEXT)
		WHILE(FIND_STRING(myPanaProj.Rx,"$03",1)){
			REMOVE_STRING(myPanaProj.Rx,"$02",1)
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPanaProj.Rx,"$03",1),1));
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						myPanaProj.BAUD = DATA.TEXT
						SEND_COMMAND dvDevice, "'SET MODE DATA'"
						SEND_COMMAND dvDevice, "'SET BAUD ',myPanaProj.BAUD,' N 8 1 485 DISABLE'"
						fnPoll()
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvDevice,"$02,DATA.TEXT,$03"
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
				myPanaProj.desVMute = FALSE
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnSendCommand('PON','');
					}
					CASE 'OFF':{
						fnSendCommand('POF','');
					}
				}
			}

			CASE 'VMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':     myPanaProj.desVMute = TRUE
					CASE 'OFF':    myPanaProj.desVMute = FALSE
					CASE 'TOGGLE': myPanaProj.desVMute = !myPanaProj.desVMute
				}
				SWITCH(myPanaProj.desVMute){
					CASE TRUE:  fnSendCommand('OSH','1')
					CASE FALSE: fnSendCommand('OSH','0')
				}
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLT_ADJ]{
	SEND_COMMAND vdvControl, 'AUTO-ADJUST'
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,chnPOWER] 	= ( myPanaProj.POWER)
	[vdvControl,chnFreeze] 	= ( myPanaProj.FREEZE )
	[vdvControl,chnVMUTE]   = ( myPanaProj.VMUTE )
}
