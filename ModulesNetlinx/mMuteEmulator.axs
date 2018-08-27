MODULE_NAME='mMuteEmulator'(DEV vdvControl)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Mute control emulator to allow central point for mute controls
	to replace utilising a single reference device which may fail
******************************************************************************/
DEFINE_TYPE STRUCTURE uMute{
	INTEGER MUTE_STATE
	INTEGER MIC_MUTE_STATE
}

DEFINE_CONSTANT
LONG TLID_DELAY = 1

DEFINE_VARIABLE
uMute myMute
LONG TLT_DELAY[] = {500}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myMute.MUTE_STATE = TRUE
					CASE 'OFF':		myMute.MUTE_STATE = FALSE
					CASE 'TOGGLE':	myMute.MUTE_STATE = !myMute.MUTE_STATE
				}
			}
			CASE 'MICMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myMute.MIC_MUTE_STATE = TRUE
					CASE 'OFF':		myMute.MIC_MUTE_STATE = FALSE
					CASE 'TOGGLE':	myMute.MIC_MUTE_STATE = !myMute.MIC_MUTE_STATE
				}
			}
		}
		IF(TIMELINE_ACTIVE(TLID_DELAY)){TIMELINE_KILL(TLID_DELAY)}
		TIMELINE_CREATE(TLID_DELAY,TLT_DELAY,LENGTH_ARRAY(TLT_DELAY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_PROGRAM{
	IF(!TIMELINE_ACTIVE(TLID_DELAY)){
		[vdvControl,198] = (myMute.MIC_MUTE_STATE)
		[vdvControl,199] = (myMute.MUTE_STATE)
	}
}