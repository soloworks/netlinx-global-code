MODULE_NAME='mPlanarDisplay'(DEV vdvControl, DEV ipUDP)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Planar Control over UDP (Default port: 57)
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uPlanar{
	CHAR 		IP_HOST[255]
	INTEGER 	IP_PORT
	INTEGER 	DEBUG

	INTEGER  STATE
	INTEGER	APPLY_PRESET
}
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2

INTEGER DEBUG_OFF		= 0
INTEGER DEBUG_STD		= 1
INTEGER DEBUG_DEV		= 2

INTEGER STATE_OFF		= 0
INTEGER STATE_WARM	= 1
INTEGER STATE_ON		= 2
INTEGER STATE_COOL	= 3

DEFINE_VARIABLE
VOLATILE uPlanar myPlanar
LONG TLT_POLL[]		= {  2500 }
LONG TLT_COMMS[]		= { 90000 }
/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDebug,CHAR pMSG[]){
	IF(pDebug <= myPlanar.DEBUG){
		STACK_VAR CHAR pMSG_COPY[10000]
		pMSG_COPY = pMSG
		WHILE(LENGTH_ARRAY(pMSG_COPY)){
			SEND_STRING 0, "ITOA(vdvControl.NUMBER),':',GET_BUFFER_STRING(pMSG_COPY,150)"
		}
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	fnDebug(DEBUG_STD,"'->PLANAR ',pDATA")
	SEND_STRING ipUDP,"pDATA,$0D"
	fnInitPoll()
}

DEFINE_FUNCTION fnSendQuery(CHAR pDATA[]){
	fnDebug(DEBUG_STD,"'->PLANAR ',pDATA")
	SEND_STRING ipUDP,"pDATA,$0D"
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_FUNCTION fnPoll(){
	//fnSendQuery('display.power?')
	fnSendQuery('system.state?')
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	// Debug Out
	fnDebug(DEBUG_STD,"'PLANAR-> ',pDATA")

	// Process Data
	SWITCH(UPPER_STRING(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))){
		CASE 'DISPLAY.POWER':{
			fnPoll()
		}
		CASE 'SYSTEM.STATE':{
			SWITCH(UPPER_STRING(pDATA)){
				CASE 'STANDBY':		myPlanar.STATE = STATE_OFF
				CASE 'POWERING.ON':	myPlanar.STATE = STATE_WARM
				CASE 'ON':				myPlanar.STATE = STATE_ON
				CASE 'POWERING.DOWN':myPlanar.STATE = STATE_COOL
			}
		}
	}

	// Reset Timeout
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Device Events - Virtual Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	myPlanar.DEBUG = DEBUG_STD
							CASE 'DEV':		myPlanar.DEBUG = DEBUG_DEV
							DEFAULT:			myPlanar.DEBUG = DEBUG_OFF
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myPlanar.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myPlanar.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myPlanar.IP_HOST = DATA.TEXT
							myPlanar.IP_PORT = 57
						}
						// Open Sending UDP Port
						//IP_BOUND_CLIENT_OPEN(ipUDP.PORT,myBACnetIP.IP_PORT,myBACnetIP.IP_HOST,myBACnetIP.IP_PORT,IP_UDP_2WAY)
						IP_CLIENT_OPEN(ipUDP.PORT,myPlanar.IP_HOST,myPlanar.IP_PORT,IP_UDP_2WAY)
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': fnSendCommand('DISPLAY.POWER=ON')
					CASE 'OFF':fnSendCommand('DISPLAY.POWER=OFF')
				}
			}
			CASE 'PRESET':{
				IF(myPlanar.STATE == STATE_ON){
					fnSendCommand("'PRESET.RECALL(',DATA.TEXT,')'")
				}
				ELSE{
					fnSendCommand("'DISPLAY.POWER=ON'")
					myPlanar.APPLY_PRESET = ATOI(DATA.TEXT)
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	Device Events - Physical Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipUDP]{
	ONLINE:{
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		// Remove $0D
		fnProcessFeedback(fnStripCharsRight(DATA.TEXT,1))
	}
	OFFLINE:{
		// No idea why this would close, but if it does re-open it
		WAIT 10{
			IP_CLIENT_OPEN(ipUDP.PORT,myPlanar.IP_HOST,myPlanar.IP_PORT,IP_UDP_2WAY)
		}
	}
}
/******************************************************************************
	Device Events - Physical Device
******************************************************************************/
DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,2,myPlanar.STATE

	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))

	[vdvControl,255] = (myPlanar.STATE == STATE_ON)
}

DEFINE_EVENT CHANNEL_EVENT[vdvControl,255]{
	ON:{
		IF(myPlanar.APPLY_PRESET){
			fnSendCommand("'PRESET.RECALL(',ITOA(myPlanar.APPLY_PRESET),')'")
			myPlanar.APPLY_PRESET = 0
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/