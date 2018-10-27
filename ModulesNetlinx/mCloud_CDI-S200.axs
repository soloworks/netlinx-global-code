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
	SLONG   MUSIC_LVL
	CHAR    MUSIC_LVL_PEND[5]
	INTEGER MUSIC_MUTE
	INTEGER SOURCE
	INTEGER MIC_MUTE[2]
}

DEFINE_TYPE STRUCTURE uSystem{
	uZone   ZONE[3]
	INTEGER DEBUG
	INTEGER LEVEL_STEP
	CHAR    Rx[500]
}

DEFINE_CONSTANT
LONG TLID_POLL     = 1
LONG TLID_COMMS    = 2
LONG TLID_GAIN_00	 = 10
LONG TLID_GAIN_01	 = 11
LONG TLID_GAIN_02	 = 12
LONG TLID_GAIN_03	 = 13

DEFINE_VARIABLE
LONG TLT_POLL[]  = { 15000 }
LONG TLT_COMMS[] = { 40000 }
LONG TLT_GAIN[]  = {   150 }
uSystem myCDI
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myCDI.DEBUG == 1)	{
		SEND_STRING 0:0:0, "ITOA(vdvUnit.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR dest[],CHAR subDest[], CHAR cmdID[],CHAR cmdMod[],CHAR cmdVal[]){
	STACK_VAR CHAR toSend[100]
	toSend = "'<',dest"
	IF(LENGTH_ARRAY(subDest)){
		toSend = "toSend,'.',subDest"
	}
	toSend = "toSend,',',cmdID,cmdMOD,cmdVal,'/>'"
	SEND_STRING dvRS232, toSend
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}


DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	STACK_VAR CHAR dest[10]
	STACK_VAR CHAR subDest[5]
	STACK_VAR CHAR cmdID
	STACK_VAR CHAR cmdMOD
	STACK_VAR CHAR cmdVAL[5]
	
	dest = fnStripCharsRight(REMOVE_STRING(pData,',',1),1)
	IF(FIND_STRING(dest,'.',1)){
		STACK_VAR CHAR d[5]
		d = fnStripCharsRight(REMOVE_STRING(dest,'.',1),1)
		subDest = dest
		dest = d
	}
	
	cmdID = GET_BUFFER_CHAR(pData)
	
	// Act on the destination
	SWITCH(LOWER_STRING(dest)){
		CASE 'Z1':
		CASE 'Z2':
		CASE 'Z3':
		CASE 'Z':{
			STACK_VAR INTEGER z
			IF(LENGTH_ARRAY(dest) == 2){
				z = ATOI(dest[2])
			}
			
			SWITCH(subDest){
				CASE 'mu':{
					SWITCH(cmdID){
						CASE 'l':{
							cmdMOD = GET_BUFFER_CHAR(pData)
							cmdVAL = pData
							SWITCH(cmdMOD){
								CASE 'a':{
									STACK_VAR FLOAT _fVol
									STACK_VAR INTEGER _iVol
									GET_BUFFER_CHAR(cmdVAL)
									_fVol = 180 - ATOF(cmdVAL)
									fnDebug('_fVol',"FTOA(_fVol)")
									IF(_fVol <= 90){
										//
									}
									ELSE{
										_fVol = 90 + (((_fVol-90) / 90)*165)
										//_fVol = 90 + ((_fVol / 165)*255)
									}
									fnDebug('_fVol',"FTOA(_fVol)")
									IF(z){
										myCDI.ZONE[z].MUSIC_LVL = math_round(_fVol)
									}
									ELSE{
										myCDI.ZONE[1].MUSIC_LVL = math_round(_fVol)
										myCDI.ZONE[2].MUSIC_LVL = math_round(_fVol)
										myCDI.ZONE[3].MUSIC_LVL = math_round(_fVol)
									}
								}
							}
						}
						CASE 's':{
							SWITCH(cmdMOD){
								CASE 'a':{
									IF(z){
										myCDI.ZONE[z].SOURCE = ATOI(cmdVAL)
									}
									ELSE{
										myCDI.ZONE[1].SOURCE = ATOI(cmdVAL)
										myCDI.ZONE[2].SOURCE = ATOI(cmdVAL)
										myCDI.ZONE[3].SOURCE = ATOI(cmdVAL)
									}
								}
							}
						}
						CASE 'm':{
							IF(z){
								myCDI.ZONE[z].MUSIC_MUTE = TRUE
							}
							ELSE{
								myCDI.ZONE[1].MUSIC_MUTE = TRUE
								myCDI.ZONE[2].MUSIC_MUTE = TRUE
								myCDI.ZONE[3].MUSIC_MUTE = TRUE
							}
						}
						CASE 'o':{
							IF(z){
								myCDI.ZONE[z].MUSIC_MUTE = FALSE
							}
							ELSE{
								myCDI.ZONE[1].MUSIC_MUTE = FALSE
								myCDI.ZONE[2].MUSIC_MUTE = FALSE
								myCDI.ZONE[3].MUSIC_MUTE = FALSE
							}
						}
					}
				}
			}
		}
	}
}

/******************************************************************************
	Polling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand('Z1','MU','L','U','0')
	fnSendCommand('Z2','MU','L','U','0')
	fnSendCommand('Z3','MU','L','U','0')
}

/******************************************************************************
	Virtual Device - Main Unit
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvUnit]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'STEP':myCDI.LEVEL_STEP = ATOI(DATA.TEXT)
				}
			}
			CASE 'RAW':SEND_STRING dvRS232,"'<',fnGetCSV(DATA.TEXT,1),',',fnGetCSV(DATA.TEXT,2),'/>'"
		}
	}
}

/******************************************************************************
	Virtual Device - Zones
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvZone]{
	COMMAND:{
		STACK_VAR INTEGER z
		z = GET_LAST(vdvZone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':		fnSendCommand("'Z',ITOA(z)",'MU','L','U',ITOA(myCDI.LEVEL_STEP))
					CASE 'DEC':		fnSendCommand("'Z',ITOA(z)",'MU','L','D',ITOA(myCDI.LEVEL_STEP))
					DEFAULT:{
						IF(!TIMELINE_ACTIVE(TLID_GAIN_00+z)){
							fnSendCommand("'Z',ITOA(z)",'MU','L','A',DATA.TEXT)
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
					CASE TRUE:		fnSendCommand("'Z',ITOA(z)",'MU','M','','')
					CASE FALSE:		fnSendCommand("'Z',ITOA(z)",'MU','O','','')
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
					CASE TRUE:		fnSendCommand("'Z',ITOA(z)","'M',ITOA(m)",'M','','')
					CASE FALSE:		fnSendCommand("'Z',ITOA(z)","'M',ITOA(m)",'O','','')
				}
			}
			CASE 'INPUT':{
				fnSendCommand("'Z',ITOA(z)",'MU','S','A',DATA.TEXT)
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
		fnSendCommand("'Z',ITOA(z)",'MU','L','A',myCDI.ZONE[z].MUSIC_LVL_PEND)
		myCDI.ZONE[z].MUSIC_LVL_PEND = ''
		TIMELINE_CREATE(TLID_GAIN_00+z,TLT_GAIN,LENGTH_ARRAY(TLT_GAIN),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Physical Device
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232,myCDI.Rx
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
	}
	STRING:{
		// Eat up garbage
		WHILE(myCDI.Rx[1] == 'H'){GET_BUFFER_CHAR(myCDI.Rx)}
		// Process a packet
		WHILE(FIND_STRING(DATA.TEXT,"'>'",1) > 0){
			// Clear any other garbage
			REMOVE_STRING(DATA.TEXT,"'<'",1)
			// Process
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,"'/>'",1),2))
		}
	}
}

/******************************************************************************
	EoF
******************************************************************************/
