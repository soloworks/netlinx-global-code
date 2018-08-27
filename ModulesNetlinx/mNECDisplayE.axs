MODULE_NAME='mNECDisplayE'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
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
/******************************************************************************
	System Structures / Constants / Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uNECDisplayE{
	INTEGER 	DEBUG
	CHAR 		Rx[500]
	CHAR 		Tx[500]
	INTEGER	lastPOLL
	
	INTEGER	INPUT
	INTEGER	POWER
	INTEGER	MUTE
}

DEFINE_CONSTANT
LONG TLID_BUSY 		= 1
LONG TLID_INPUT	 	= 2
LONG TLID_SEND			= 3
LONG TLID_COMMS		= 4

INTEGER INPUT_VGA		= 1
INTEGER INPUT_HDMI1	= 2
INTEGER INPUT_HDMI2	= 3
INTEGER INPUT_HDMI3	= 4

DEFINE_VARIABLE
LONG TLT_POLL[] 		= {10000}
LONG TLT_COMMS[]		= {90000}
LONG TLT_INPUT[]		= {0,1000,10000 }
uNECDisplayE myNECDisplayE

/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myNECDisplayE.DEBUG)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
		SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600 N,8,1 485 DISABLE'
	}
	STRING:{

	}
}



DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						myNECDisplayE.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'RAW':{
				SEND_STRING dvRS232,DATA.TEXT
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'VGA':  myNECDisplayE.INPUT = INPUT_VGA
					CASE 'HDMI1':myNECDisplayE.INPUT = INPUT_HDMI1
					CASE 'HDMI2':myNECDisplayE.INPUT = INPUT_HDMI2
					CASE 'HDMI3':myNECDisplayE.INPUT = INPUT_HDMI3
				}
				IF(TIMELINE_ACTIVE(TLID_INPUT)){TIMELINE_KILL(TLID_INPUT)}
				TIMELINE_CREATE(TLID_INPUT,TLT_INPUT,LENGTH_ARRAY(TLT_INPUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			CASE 'POWER':{
				myNECDisplayE.POWER = (DATA.TEXT == 'ON')
				SWITCH(myNECDisplayE.POWER){
					CASE TRUE: SEND_STRING dvRS232, "$01,$30,$41,$30,$41,$30,$43,$02,$43,$32,$30,$33,$44,$36,$30,$30,$30,$31,$03,$73,$0D"
					CASE FALSE:SEND_STRING dvRS232, "$01,$30,$41,$30,$41,$30,$43,$02,$43,$32,$30,$33,$44,$36,$30,$30,$30,$34,$03,$76,$0D"
				}
				IF(!myNECDisplayE.POWER){
					myNECDisplayE.MUTE = FALSE
				}
			}
			CASE 'VOLUME':{
				myNECDisplayE.MUTE = FALSE
				SWITCH(DATA.TEXT){
					CASE 'INC': SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$31,$30,$41,$44,$30,$30,$30,$31,$03,$71,$0D"
					CASE 'DEC': SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$31,$30,$41,$44,$30,$30,$30,$32,$03,$72,$0D"
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myNECDisplayE.MUTE = TRUE
					CASE 'OFF':		myNECDisplayE.MUTE = FALSE
					CASE 'TOGGLE':	myNECDisplayE.MUTE = !myNECDisplayE.MUTE
				}
				SWITCH(myNECDisplayE.MUTE){
					CASE TRUE: 	SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$31,$30,$38,$44,$30,$30,$30,$31,$03,$09,$0D"
					CASE FALSE: SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$31,$30,$38,$44,$30,$30,$30,$32,$03,$0A,$0D"
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_INPUT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 2:{
			myNECDisplayE.POWER = TRUE
			SEND_STRING dvRS232, "$01,$30,$41,$30,$41,$30,$43,$02,$43,$32,$30,$33,$44,$36,$30,$30,$30,$31,$03,$73,$0D"
		}
		DEFAULT:{
			SWITCH(myNECDisplayE.INPUT){
				CASE INPUT_VGA:   SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$30,$30,$36,$30,$30,$30,$30,$31,$03,$73,$0D"
				CASE INPUT_HDMI1: SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$30,$30,$36,$30,$30,$30,$31,$31,$03,$72,$0D"
				CASE INPUT_HDMI2: SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$30,$30,$36,$30,$30,$30,$31,$32,$03,$71,$0D"
				CASE INPUT_HDMI3: SEND_STRING dvRS232, "$01,$30,$41,$30,$45,$30,$41,$02,$30,$30,$36,$30,$30,$30,$31,$33,$03,$70,$0D"
			}
		}
	}
}
/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,199] = (myNECDisplayE.MUTE)
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
