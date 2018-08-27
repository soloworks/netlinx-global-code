MODULE_NAME='mIntuiLab'(DEV vdvControl, DEV ipHTTP)
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'
/******************************************************************************
	Rough and Ready implementation of Intuilab control triggers

	http://192.168.1.62:8000/intuifacepresentationplayer/presentation/currentspace/WorkroomBackdrop/Show

	http://192.168.1.62:8000/intuifacepresentationplayer/presentation/currentspace/WorkroomBackdrop/Hide
******************************************************************************/


/******************************************************************************
	Control Device Processing
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						HTTP.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
						IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
							HTTP.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
						}
					}
				}
			}
		}
	}
}

/******************************************************************************
	WebSocket Callback Events
******************************************************************************/
DEFINE_FUNCTION eventHTTPResponse(uHTTPResp r){

}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	//[vdvCarrier,251] = WS.CONN_STATE == CONN_STATE_CONNECTED
	//[vdvCarrier,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}
/******************************************************************************
	EoF
******************************************************************************/