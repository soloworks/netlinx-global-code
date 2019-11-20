MODULE_NAME='mCloud_CDI-S200'(DEV vdvUnit, DEV vdvZone[], DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Cloud CDI-200 Control Module
	Initial startup Feedback limited to levels only
	NOTE: No Mic Level control via this device
******************************************************************************/

/******************************************************************************
	Structures, Constants and Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uZone{
	LONG    MUSIC_LVL
	CHAR    MUSIC_LVL_PEND[5]
	INTEGER MUSIC_MUTE
	INTEGER SOURCE
	INTEGER MIC_MUTE[2]
}

DEFINE_TYPE STRUCTURE uSystem{
	uZone   ZONE[3]
	CHAR    MUSIC_LVL_PEND[5]
	INTEGER DEBUG
	INTEGER LEVEL_STEP
}

DEFINE_CONSTANT
LONG TLID_POLL     = 1
LONG TLID_COMMS    = 2
LONG TLID_GAIN_00	 = 10
LONG TLID_GAIN_01	 = 11
LONG TLID_GAIN_02	 = 12
LONG TLID_GAIN_03	 = 13

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

DEFINE_VARIABLE
LONG TLT_POLL[]  = { 15000,1000,1000 }
LONG TLT_COMMS[] = { 40000 }
LONG TLT_GAIN[]  = {   150 }
uSystem myCDI

DEFINE_START{
	IF(!myCDI.LEVEL_STEP){myCDI.LEVEL_STEP = 5}
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR pMSG[], CHAR pDATA[]){
	IF(myCDI.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvUnit.Number),':',pMSG, ':', pDATA"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR dest[],CHAR subDest[], CHAR cmdID[],CHAR cmdMod[],CHAR cmdVal[],INTEGER isPoll){
	STACK_VAR CHAR toSend[100]
	toSend = "'<',dest"
	IF(LENGTH_ARRAY(subDest)){
		toSend = "toSend,'.',subDest"
	}
	toSend = "toSend,',',cmdID,cmdMOD,cmdVal,'/>'"
	fnDebug(DEBUG_STD,'->CDI',toSend)
	SEND_STRING dvRS232, toSend
	IF(!isPoll){
		IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
	}
}


DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	STACK_VAR CHAR dest[10]
	STACK_VAR CHAR subDest[5]
	STACK_VAR CHAR cmdID
	STACK_VAR CHAR cmdMOD
	STACK_VAR CHAR cmdVAL[5]

	fnDebug(DEBUG_STD,'CDI->',"pData")

	dest = fnStripCharsRight(REMOVE_STRING(pData,',',1),1)
	IF(FIND_STRING(dest,'.',1)){
		STACK_VAR CHAR d[5]
		d = fnStripCharsRight(REMOVE_STRING(dest,'.',1),1)
		subDest = dest
		dest = d
	}

	cmdID = GET_BUFFER_CHAR(pData)

	// Act on the destination
	SWITCH(dest){
		CASE 'z1':
		CASE 'z2':
		CASE 'z3':{
			STACK_VAR INTEGER z
			z = ATOI("dest[2]")

			SWITCH(subDest){
				CASE 'mu':{
					SWITCH(cmdID){
						CASE 'l':{
							cmdMOD = GET_BUFFER_CHAR(pData)
							cmdVAL = pData
							SWITCH(cmdMOD){
								CASE 'a': myCDI.ZONE[z].MUSIC_LVL = ATOI(cmdVAL)
							}
						}
						CASE 's':{
							cmdMOD = GET_BUFFER_CHAR(pData)
							cmdVAL = pData
							SWITCH(cmdMOD){
								CASE 'a': myCDI.ZONE[z].SOURCE = ATOI(cmdVAL)
							}
						}
						CASE 'm': myCDI.ZONE[z].MUSIC_MUTE = TRUE
						CASE 'o': myCDI.ZONE[z].MUSIC_MUTE = FALSE
					}
				}
			}
		}
		CASE 'mu':{
			SWITCH(cmdID){
				CASE 'l':{
					cmdMOD = GET_BUFFER_CHAR(pData)
					cmdVAL = pData
					SWITCH(cmdMOD){
						CASE 'a':{
							myCDI.ZONE[1].MUSIC_LVL = ATOI(cmdVAL)
							myCDI.ZONE[2].MUSIC_LVL = ATOI(cmdVAL)
							myCDI.ZONE[3].MUSIC_LVL = ATOI(cmdVAL)
						}
					}
				}
				CASE 's':{
					cmdMOD = GET_BUFFER_CHAR(pData)
					cmdVAL = pData
					SWITCH(cmdMOD){
						CASE 'a':{
							myCDI.ZONE[1].SOURCE = ATOI(cmdVAL)
							myCDI.ZONE[2].SOURCE = ATOI(cmdVAL)
							myCDI.ZONE[3].SOURCE = ATOI(cmdVAL)
						}
					}
				}
				CASE 'm':{
					myCDI.ZONE[1].MUSIC_MUTE = TRUE
					myCDI.ZONE[2].MUSIC_MUTE = TRUE
					myCDI.ZONE[3].MUSIC_MUTE = TRUE
				}
				CASE 'o':{
					myCDI.ZONE[1].MUSIC_MUTE = FALSE
					myCDI.ZONE[2].MUSIC_MUTE = FALSE
					myCDI.ZONE[3].MUSIC_MUTE = FALSE
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

/******************************************************************************
	Polling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll(TIMELINE.SEQUENCE)
}

DEFINE_FUNCTION fnPoll(INTEGER z){
	fnSendCommand("'Z',ITOA(z)",'MU','L','U','0',TRUE)
}

/******************************************************************************
	Virtual Device - Main Unit
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvUnit]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'RANGE-0,180'
		SEND_STRING DATA.DEVICE,'PROPERTY-RANGE,0,180'
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'STEP':myCDI.LEVEL_STEP = ATOI(DATA.TEXT)
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE': myCDI.DEBUG = DEBUG_STD
							CASE 'DEV':  myCDI.DEBUG = DEBUG_DEV
							DEFAULT: 	 myCDI.DEBUG = DEBUG_ERR
						}
						fnDebug(DEBUG_ERR,'DebugLVL Set->',ITOA(myCDI.DEBUG))
					}
				}
			}
			CASE 'RAW':SEND_STRING dvRS232,"'<',fnGetCSV(DATA.TEXT,1),',',fnGetCSV(DATA.TEXT,2),'/>'"
			CASE 'INPUT':{
				fnSendCommand('MU','','S','A',DATA.TEXT,FALSE)
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':		fnSendCommand('MU','','L','U',ITOA(myCDI.LEVEL_STEP),FALSE)
					CASE 'DEC':		fnSendCommand('MU','','L','D',ITOA(myCDI.LEVEL_STEP),FALSE)
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_GAIN_00)){
							fnSendCommand('MU','','L','A',DATA.TEXT,FALSE)
							TIMELINE_CREATE(TLID_GAIN_00,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myCDI.MUSIC_LVL_PEND = DATA.TEXT
						}
					}
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  	myCDI.ZONE[1].MUSIC_MUTE = TRUE
					CASE 'OFF': 	myCDI.ZONE[1].MUSIC_MUTE = FALSE
					CASE 'TOGGLE': myCDI.ZONE[1].MUSIC_MUTE = !myCDI.ZONE[1].MUSIC_MUTE
				}
				SWITCH(myCDI.ZONE[1].MUSIC_MUTE){
					CASE TRUE:		fnSendCommand('MU','','M','','',FALSE)
					CASE FALSE:		fnSendCommand('MU','','O','','',FALSE)
				}
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_GAIN_00]{
	IF(LENGTH_ARRAY(myCDI.MUSIC_LVL_PEND)){
		fnSendCommand('MU','','L','A',myCDI.MUSIC_LVL_PEND,FALSE)
		myCDI.MUSIC_LVL_PEND = ''
		TIMELINE_CREATE(TLID_GAIN_00,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_PROGRAM{
	SEND_LEVEL vdvUnit,1,myCDI.ZONE[1].MUSIC_LVL
	[vdvUnit,199] = (myCDI.ZONE[1].MUSIC_MUTE)
	[vdvUnit,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvUnit,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}

/******************************************************************************
	Virtual Device - Zones
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvZone]{
	ONLINE:{
		SEND_STRING DATA.DEVICE,'RANGE-0,180'
		SEND_STRING DATA.DEVICE,'PROPERTY-RANGE,0,180'
	}
	COMMAND:{
		STACK_VAR INTEGER z
		z = GET_LAST(vdvZone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'INPUT':{
				fnSendCommand("'Z',ITOA(z)",'MU','S','A',DATA.TEXT,FALSE)
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':		fnSendCommand("'Z',ITOA(z)",'MU','L','U',ITOA(myCDI.LEVEL_STEP),FALSE)
					CASE 'DEC':		fnSendCommand("'Z',ITOA(z)",'MU','L','D',ITOA(myCDI.LEVEL_STEP),FALSE)
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_GAIN_00+z)){
							fnSendCommand("'Z',ITOA(z)",'MU','L','A',DATA.TEXT,FALSE)
							TIMELINE_CREATE(TLID_GAIN_00+z,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myCDI.ZONE[z].MUSIC_LVL_PEND = DATA.TEXT
						}
					}
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':  	myCDI.ZONE[z].MUSIC_MUTE = TRUE
					CASE 'OFF': 	myCDI.ZONE[z].MUSIC_MUTE = FALSE
					CASE 'TOGGLE': myCDI.ZONE[z].MUSIC_MUTE = !myCDI.ZONE[z].MUSIC_MUTE
				}
				SWITCH(myCDI.ZONE[z].MUSIC_MUTE){
					CASE TRUE:		fnSendCommand("'Z',ITOA(z)",'MU','M','','',FALSE)
					CASE FALSE:		fnSendCommand("'Z',ITOA(z)",'MU','O','','',FALSE)
				}
			}
			CASE 'MICMUTE':{
				STACK_VAR INTEGER m
				m = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				SWITCH(DATA.TEXT){
					CASE 'ON':  	myCDI.ZONE[z].MIC_MUTE[m] = TRUE
					CASE 'OFF': 	myCDI.ZONE[z].MIC_MUTE[m] = FALSE
					CASE 'TOGGLE': myCDI.ZONE[z].MIC_MUTE[m] = !myCDI.ZONE[z].MIC_MUTE[m]
				}
				SWITCH(myCDI.ZONE[z].MIC_MUTE[m]){
					CASE TRUE:		fnSendCommand("'Z',ITOA(z)","'M',ITOA(m)",'M','','',FALSE)
					CASE FALSE:		fnSendCommand("'Z',ITOA(z)","'M',ITOA(m)",'O','','',FALSE)
				}
			}
		}
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_GAIN_01]
TIMELINE_EVENT[TLID_GAIN_02]
TIMELINE_EVENT[TLID_GAIN_03]{
	STACK_VAR INTEGER z
	z = TIMELINE.ID - TLID_GAIN_00
	IF(LENGTH_ARRAY(myCDI.ZONE[z].MUSIC_LVL_PEND)){
		fnSendCommand("'Z',ITOA(z)",'MU','L','A',myCDI.ZONE[z].MUSIC_LVL_PEND,FALSE)
		myCDI.ZONE[z].MUSIC_LVL_PEND = ''
		TIMELINE_CREATE(TLID_GAIN_00+z,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_PROGRAM{
	SEND_LEVEL vdvZone[1],1,myCDI.ZONE[1].MUSIC_LVL
	SEND_LEVEL vdvZone[2],1,myCDI.ZONE[2].MUSIC_LVL
	SEND_LEVEL vdvZone[3],1,myCDI.ZONE[3].MUSIC_LVL
	[vdvZone[1],199] = (myCDI.ZONE[1].MUSIC_MUTE)
	[vdvZone[2],199] = (myCDI.ZONE[2].MUSIC_MUTE)
	[vdvZone[3],199] = (myCDI.ZONE[3].MUSIC_MUTE)
}
/******************************************************************************
	Physical Device
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_RELATIVE,TIMELINE_REPEAT)
		fnPoll(1)
		WAIT 5{ fnPoll(2) }
		WAIT 10{ fnPoll(3) }
	}
	STRING:{
		fnDebug(DEBUG_DEV,'CDI->',"DATA.TEXT")
		// Eat up garbage
		WHILE(LENGTH_ARRAY(DATA.TEXT) && DATA.TEXT[1] != "'<'"){
			fnDebug(DEBUG_DEV,'Consuming Garbage',GET_BUFFER_CHAR(DATA.TEXT))
		}

		// Process a packet
		WHILE(FIND_STRING(DATA.TEXT,"'/>'",1)){
			// Clear any other garbage
			IF(FIND_STRING(DATA.TEXT,"'<'",1)){
				REMOVE_STRING(DATA.TEXT,"'<'",1)
			}
			// Process
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,"'/>'",1),2))
		}

	}
}

/******************************************************************************
	EoF
******************************************************************************/
