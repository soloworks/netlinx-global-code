MODULE_NAME='mMicrosoftSurfaceHub'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module for RS232 control
******************************************************************************/
DEFINE_TYPE STRUCTURE uSurface{

	INTEGER 	DISABLED
	
	CHAR    Rx[500]

	INTEGER DEBUG
	INTEGER POWER
	INTEGER SOURCE
	INTEGER SOURCE_NEW
}

DEFINE_CONSTANT

INTEGER POWER_STATE_OFF   = 0
INTEGER POWER_STATE_WARM  = 1
INTEGER POWER_STATE_SLEEP = 2
INTEGER POWER_STATE_READY = 5

INTEGER SOURCE_PC    = 0
INTEGER SOURCE_DPORT = 1
INTEGER SOURCE_HDMI  = 2
INTEGER SOURCE_VGA   = 3
INTEGER SOURCE_NULL  = 999

LONG TLID_POLL  = 1
LONG TLID_COMMS = 2
LONG TLID_BOOT  = 3

DEFINE_VARIABLE
LONG TLT_POLL[]  = {10000}
LONG TLT_COMMS[] = {45000}
LONG TLT_BOOT[]  = { 5000};	// Give it 5 seconds for Boot to finish
VOLATILE uSurface mySurface
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, mySurface.Rx
}
/******************************************************************************
	Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!mySurface.DISABLED){
		mySurface.SOURCE_NEW = SOURCE_NULL
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Microsoft'
		SEND_STRING vdvControl,'PROPERTY-META,MODEL,Surface Hub'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI|DPORT|PC|VGA'
		SEND_COMMAND dvRS232, 'SET MODE DATA'
      SEND_COMMAND dvRS232, 'SET BAUD 115200,N,8,1 485 DISABLE'
		fnPoll()
	}
}
/******************************************************************************
	Polling Routines
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('Power?')	// Device Power Query
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
/******************************************************************************
	Data Send Routine
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(mySurface.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pToSend[]){
	fnDebug('->SURFACE',"pToSend,$0A")
   SEND_STRING dvRS232, "pToSend,$0A"
	fnInitPoll()
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug('SURFACE->',DATA.TEXT)
	SWITCH(fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1))){
		CASE 'Power':{	// Power Response
			mySurface.POWER = ATOI(pDATA)
			IF(mySurface.POWER == POWER_STATE_READY){
				fnSendCommand('Source?')
			}

			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		CASE 'Source':{
			// Store Current Value
			IF(mySurface.SOURCE != ATOI(pDATA)){
				mySurface.SOURCE = ATOI(pDATA)
				SWITCH(mySurface.SOURCE){
					CASE SOURCE_PC:    SEND_STRING vdvControl,"'PROPERTY-META,INPUT,PC'"
					CASE SOURCE_DPORT: SEND_STRING vdvControl,"'PROPERTY-META,INPUT,DPORT'"
					CASE SOURCE_HDMI:  SEND_STRING vdvControl,"'PROPERTY-META,INPUT,HDMI'"
					CASE SOURCE_VGA:   SEND_STRING vdvControl,"'PROPERTY-META,INPUT,VGA'"
				}
			}
			// Check if current source was last requested
			IF(mySurface.SOURCE_NEW != SOURCE_NULL){
				IF(mySurface.SOURCE_NEW == mySurface.SOURCE){
					mySurface.SOURCE_NEW = SOURCE_NULL
				}
				ELSE{
					fnSendCommand("'Source=',ITOA(mySurface.SOURCE_NEW)")
				}
			}
		}
	}
}
/******************************************************************************
	Physical Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
   ONLINE:{
		TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
   }
	STRING:{
		IF(!mySurface.DISABLED){
			fnDebug('SURFACE_RAW->',DATA.TEXT)
			WHILE(FIND_STRING(mySurface.Rx,"$0A",1)){
				STACK_VAR CHAR pDATA[200]
				pDATA = REMOVE_STRING(mySurface.Rx,"$0A",1)
				IF(FIND_STRING(pDATA,"$0D,$0A",1)){
					fnProcessFeedback(fnStripCharsRight(pDATA,2))
				}
			}
		}
	}
}
/******************************************************************************
	Virtual Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
   COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'SURFACE_RS232':
							CASE 'TRUE':mySurface.DISABLED = FALSE
							DEFAULT:		mySurface.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!mySurface.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG':{
							mySurface.DEBUG = (DATA.TEXT == 'TRUE')
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON': 	 fnSendCommand('PowerOn')
						CASE 'OFF':	 fnSendCommand('PowerOff')
					}
				}
				CASE 'INPUT':{
					SWITCH(DATA.TEXT){
						CASE 'HDMI': mySurface.SOURCE_NEW = SOURCE_HDMI
						CASE 'PC':   mySurface.SOURCE_NEW = SOURCE_PC
						CASE 'DPORT':mySurface.SOURCE_NEW = SOURCE_DPORT
						CASE 'VGA':  mySurface.SOURCE_NEW = SOURCE_VGA
					}
					SWITCH(mySurface.POWER){
						CASE POWER_STATE_READY: fnSendCommand("'Source=',ITOA(mySurface.SOURCE_NEW)")
						DEFAULT:                fnSendCommand('PowerOn')
					}
				}
			}
		}
   }
}

DEFINE_PROGRAM{
	IF(!mySurface.DISABLED){
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,255] = (mySurface.POWER == POWER_STATE_READY)
	}
}
/******************************************************************************
	EoF
******************************************************************************/
