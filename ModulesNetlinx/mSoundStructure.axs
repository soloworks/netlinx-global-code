MODULE_NAME='mSoundStructure'(DEV vdvControl, DEV vdvObjects[], DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 10/02/2013  AT: 21:53:09        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Polycom Soundstructure Module
	By Solo Control Ltd (www.solocontrol.co.uk)
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER _MAX_OBJECTS = 25
INTEGER _MAX_DEVICES = 8
// Object Types
INTEGER OBJ_TYPE_FADER			= 1
INTEGER OBJ_TYPE_POTS			= 2
INTEGER OBJ_TYPE_VOIP			= 3
// Object States
INTEGER OBJ_STATE_MUTE_FADER	= 1	// Object Mute State
INTEGER OBJ_STATE_MUTE_MIC		= 2	// Object Mute State
INTEGER OBJ_STATE_HOOK			= 3	// Phone OnHook
INTEGER OBJ_STATE_RING			= 4	// Phone is Ringing
// Object Level
INTEGER OBJ_LEVEL_GAIN			= 1	// Object Gain Value
INTEGER OBJ_LEVEL_STEP			= 2	// Object Step value for VOL changes
INTEGER OBJ_LEVEL_GAIN_255		= 3	// Object Gain Value
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
// Generic Object
DEFINE_TYPE STRUCTURE uObject{
	INTEGER	TYPE
	CHAR 		ID_1[255]		// Main Reference Tag
	CHAR 		ID_2[255]		// Optional Reference Tag (e.g. Phone In & Out)
	SINTEGER LEV[8]			// Object Levels (Indexed Above)
	INTEGER  STATE[10]		// Object States (Indexed Above)
	SINTEGER	LEV_MAX[8]		// Object Level Max Value
	SINTEGER LEV_MIN[8]		// Object Level Min Value
	(** Status **)
	INTEGER 	VOL_PEND			// Is a Volume Update pending
	SINTEGER	LAST_VOL			// Volume to Send
}

DEFINE_TYPE STRUCTURE uDevice{
	CHAR 		SW_VER[20]		// Software Versions (Per connected unit)
	CHAR 		TYPE[10]			// Device Type
	CHAR 		HW_REV[32]		// Hardware Version
	CHAR 		FW_REV[24]		// Firmware Version
	CHAR 		BOOT_VER[24]	// Bootloader Version
	CHAR 		TEMP[3][10]		// Temperature (3x Sensors)
	CHAR 		UPTIME[30]		// Device Uptime
	CHAR 		STATUS[20]		// Device Status
	CHAR 		IP_MODE[10]		// Reported IP Mode
	CHAR 		IP_ADD[15]		// Reported IP Address
}

DEFINE_TYPE STRUCTURE uSS{
	// Comms
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER	isIP
	INTEGER 	DEBUG							// Debugging
	CHAR		BAUD[10]			// Current Baud Rate for RS232
	// State
	CHAR 		SYS_NAME[255]				// System Name
	uDevice	DEVICE[_MAX_DEVICES]
	uObject  OBJECT[_MAX_OBJECTS]
	// CrossPoints
	CHAR 		XPOINT_REF[30][30]		// CrossPoint Reference
	INTEGER 	XPOINT_VAL[30]				// State of above CrossPoint
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_RING		= 2
LONG TLID_RETRY	= 3
LONG TLID_INIT		= 4

LONG TLID_COMMS_00	= 100
LONG TLID_COMMS_01	= 101
LONG TLID_COMMS_02	= 102
LONG TLID_COMMS_03	= 103
LONG TLID_COMMS_04	= 104
LONG TLID_COMMS_05	= 105
LONG TLID_COMMS_06	= 106
LONG TLID_COMMS_07	= 107
LONG TLID_COMMS_08	= 108
LONG TLID_COMMS_09	= 109
LONG TLID_COMMS_10	= 110
LONG TLID_COMMS_11	= 111
LONG TLID_COMMS_12	= 112
LONG TLID_COMMS_13	= 113
LONG TLID_COMMS_14	= 114
LONG TLID_COMMS_15	= 115
LONG TLID_COMMS_16	= 116
LONG TLID_COMMS_17	= 117
LONG TLID_COMMS_18	= 118
LONG TLID_COMMS_19	= 119
LONG TLID_COMMS_20	= 120
LONG TLID_COMMS_21	= 121
LONG TLID_COMMS_22	= 122
LONG TLID_COMMS_23	= 123
LONG TLID_COMMS_24	= 124
LONG TLID_COMMS_25	= 125

LONG TLID_VOL_00		= 200
LONG TLID_VOL_01		= 201
LONG TLID_VOL_02		= 202
LONG TLID_VOL_03		= 203
LONG TLID_VOL_04		= 204
LONG TLID_VOL_05		= 205
LONG TLID_VOL_06		= 206
LONG TLID_VOL_07		= 207
LONG TLID_VOL_08		= 208
LONG TLID_VOL_09		= 209
LONG TLID_VOL_10		= 210
LONG TLID_VOL_11		= 211
LONG TLID_VOL_12		= 212
LONG TLID_VOL_13		= 213
LONG TLID_VOL_14		= 214
LONG TLID_VOL_15		= 215
LONG TLID_VOL_16		= 216
LONG TLID_VOL_17		= 217
LONG TLID_VOL_18		= 218
LONG TLID_VOL_19		= 219
LONG TLID_VOL_20		= 220
LONG TLID_VOL_21		= 221
LONG TLID_VOL_22		= 222
LONG TLID_VOL_23		= 223
LONG TLID_VOL_24		= 224
LONG TLID_VOL_25		= 225

LONG TLID_RING_00		= 300
LONG TLID_RING_01		= 301
LONG TLID_RING_02		= 302
LONG TLID_RING_03		= 303
LONG TLID_RING_04		= 304
LONG TLID_RING_05		= 305
LONG TLID_RING_06		= 306
LONG TLID_RING_07		= 307
LONG TLID_RING_08		= 308
LONG TLID_RING_09		= 309
LONG TLID_RING_10		= 310
LONG TLID_RING_11		= 311
LONG TLID_RING_12		= 312
LONG TLID_RING_13		= 313
LONG TLID_RING_14		= 314
LONG TLID_RING_15		= 315
LONG TLID_RING_16		= 316
LONG TLID_RING_17		= 317
LONG TLID_RING_18		= 318
LONG TLID_RING_19		= 319
LONG TLID_RING_20		= 320
LONG TLID_RING_21		= 321
LONG TLID_RING_22		= 322
LONG TLID_RING_23		= 323
LONG TLID_RING_24		= 324
LONG TLID_RING_25		= 325
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uSS		mySS

LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
LONG 		TLT_INIT[]	= {	2500 }
LONG 		TLT_RING[]	= {	4000 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	mySS.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, mySS.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pType[], CHAR pCMD[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pType,' ',pCMD,$0D"
	IF(mySS.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->SS',toSend)
		SEND_STRING dvDevice, toSend
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(mySS.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(mySS.IP_HOST == ''){
		fnDebug(TRUE,'SS IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to SS on ',"mySS.IP_HOST,':',ITOA(mySS.IP_PORT)")
		mySS.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, mySS.IP_HOST, mySS.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

	STACK_VAR CHAR pID[50]
	STACK_VAR INTEGER x

	fnDebug(FALSE,'SS->',pDATA)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'val':{
			SELECT{
				ACTIVE(LEFT_STRING(pDATA,8) == 'sys_name'):{
					GET_BUFFER_STRING(pDATA,9)
					mySS.SYS_NAME = fnRemoveQuotes(pDATA)
					SEND_STRING vdvControl, "'PROPERTY-META,TYPE,DSP'"
					SEND_STRING vdvControl, "'PROPERTY-META,MAKE,Polycom'"
					SEND_STRING vdvControl, "'PROPERTY-META,MODEL,SoundStructure'"
					SEND_STRING vdvControl, "'PROPERTY-SYS_NAME,',mySS.SYS_NAME"
					fnRefreshObjects(TRUE)
				}
				ACTIVE(LEFT_STRING(pDATA,10) == 'sys_sw_ver'):{
					GET_BUFFER_STRING(pDATA,11)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].SW_VER != fnRemoveQuotes(pDATA)){
						mySS.DEVICE[ATOI(pID)].SW_VER = fnRemoveQuotes(pDATA)
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_SW_VER,',mySS.DEVICE[ATOI(pID)].SW_VER"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,8) == 'dev_type'):{
					GET_BUFFER_STRING(pDATA,9)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].TYPE != pDATA){
						mySS.DEVICE[ATOI(pID)].TYPE = pDATA

						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_TYPE,',UPPER_STRING(mySS.DEVICE[ATOI(pID)].TYPE)"

						fnSendCommand('get', "'sys_sw_ver ',pID")			// Software Version
						fnSendCommand('get', "'dev_hw_rev ',pID")			// Hardware Revision
						fnSendCommand('get', "'dev_firmware_ver ',pID")	// Firmware Revision
						fnSendCommand('get', "'dev_bootloader_ver ',pID")	// Firmware Revision
					}
				}
				ACTIVE(LEFT_STRING(pDATA,10) == 'dev_hw_rev'):{
					GET_BUFFER_STRING(pDATA,11)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].HW_REV != pDATA){
						mySS.DEVICE[ATOI(pID)].HW_REV = pDATA
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_HW_REV,',mySS.DEVICE[ATOI(pID)].HW_REV"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,16) == 'dev_firmware_ver'):{
					GET_BUFFER_STRING(pDATA,17)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].FW_REV != pDATA){
						mySS.DEVICE[ATOI(pID)].FW_REV = pDATA
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_FW_REV,',mySS.DEVICE[ATOI(pID)].FW_REV"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,18) == 'dev_bootloader_ver'):{
					GET_BUFFER_STRING(pDATA,19)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].BOOT_VER != pDATA){
						mySS.DEVICE[ATOI(pID)].BOOT_VER = pDATA
						//SEND_STRING vdvControl, "'PROPERTY-META,DEV_BOOT_REV_,',FORMAT('%02d',pID),',',mySS.DEVICE[ATOI(pID)].FW_REV"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,10) == 'dev_status'):{
					GET_BUFFER_STRING(pDATA,11)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].STATUS != pDATA){
						mySS.DEVICE[ATOI(pID)].STATUS = pDATA
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_STATE,',mySS.DEVICE[ATOI(pID)].STATUS"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,10) == 'dev_uptime'):{
					GET_BUFFER_STRING(pDATA,11)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					IF(mySS.DEVICE[ATOI(pID)].UPTIME != pDATA){
						mySS.DEVICE[ATOI(pID)].UPTIME = pDATA
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_UPTIME,',mySS.DEVICE[ATOI(pID)].UPTIME"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,8) == 'dev_temp'):{
					STACK_VAR INTEGER t
					GET_BUFFER_STRING(pDATA,9)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
					t = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
					IF(!COMPARE_STRING(mySS.DEVICE[ATOI(pID)].TEMP[t],pDATA)){
						mySS.DEVICE[ATOI(pID)].TEMP[t] = pDATA
						SWITCH(t){
							CASE 1:SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_TEMP_REAR,',  mySS.DEVICE[ATOI(pID)].TEMP[t]"
							CASE 2:SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_TEMP_CENTRE,',mySS.DEVICE[ATOI(pID)].TEMP[t]"
							CASE 3:SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_TEMP_FRONT,', mySS.DEVICE[ATOI(pID)].TEMP[t]"
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,12) == 'eth_settings'):{
					STACK_VAR CHAR pMODE[50]
					STACK_VAR CHAR pIP[50]
					GET_BUFFER_STRING(pDATA,13)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

					REMOVE_STRING(pDATA,'mode=',1)
					pMODE = fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))

					REMOVE_STRING(pDATA,'addr=',1)
					pIP = fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))

					IF(mySS.DEVICE[ATOI(pID)].IP_MODE != pMODE || mySS.DEVICE[ATOI(pID)].IP_ADD != pIP){
						mySS.DEVICE[ATOI(pID)].IP_MODE = pMODE
						mySS.DEVICE[ATOI(pID)].IP_ADD  = pIP
						SEND_STRING vdvControl, "'PROPERTY-META,DEV_',FORMAT('%02d',ATOI(pID)),'_IP,',pMODE,':',pIP"
					}
				}
				ACTIVE(LEFT_STRING(pDATA,9) == 'fader min'):{
					GET_BUFFER_STRING(pDATA,10)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_FADER:
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									mySS.OBJECT[x].LEV_MIN[OBJ_LEVEL_GAIN] = ATOI(pDATA)
								}
							}
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,9) == 'fader max'):{
					GET_BUFFER_STRING(pDATA,10)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_FADER:
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									mySS.OBJECT[x].LEV_MAX[OBJ_LEVEL_GAIN] = ATOI(pDATA)
									SEND_STRING vdvObjects[x],"'RANGE-',ITOA(mySS.OBJECT[x].LEV_MIN[OBJ_LEVEL_GAIN]),',',ITOA(mySS.OBJECT[x].LEV_MAX[OBJ_LEVEL_GAIN])"
								}
							}
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,5) == 'fader'):{
					GET_BUFFER_STRING(pDATA,6)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_FADER:
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									mySS.OBJECT[x].LEV[OBJ_LEVEL_GAIN] = ATOI(pDATA)
									IF(1){
										STACK_VAR SLONG myVal
										myVal = fnScaleRange(ATOI(pDATA),mySS.OBJECT[x].LEV_MIN[OBJ_LEVEL_GAIN],mySS.OBJECT[x].LEV_MAX[OBJ_LEVEL_GAIN],0,255)
										mySS.OBJECT[x].LEV[OBJ_LEVEL_GAIN_255] = ATOI(FTOA(myVal))
									}
									fnCommsRecieved(x)
								}
							}
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,4) == 'mute'):{
					GET_BUFFER_STRING(pDATA,5)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_FADER:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_FADER] = ATOI(pDATA)
									fnCommsRecieved(x)
								}
							}
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_FADER] = ATOI(pDATA)
									fnCommsRecieved(x)
								}
								IF(mySS.OBJECT[x].ID_2 == pID){
									mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_MIC] = ATOI(pDATA)
									fnCommsRecieved(x)
								}
							}
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,10) == 'phone_ring'):{
					GET_BUFFER_STRING(pDATA,11)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_1 == pID){
									IF(ATOI(pDATA)){
										mySS.OBJECT[x].STATE[OBJ_STATE_RING] = TRUE
										IF(TIMELINE_ACTIVE(TLID_RING_00+x)){TIMELINE_KILL(TLID_RING_00+x)}
										TIMELINE_CREATE(TLID_RING_00+x,TLT_RING,LENGTH_ARRAY(TLT_RING),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
									}
									fnCommsRecieved(x)
								}
							}
						}
					}
				}
				ACTIVE(LEFT_STRING(pDATA,13) == 'phone_connect'):{
					GET_BUFFER_STRING(pDATA,14)
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',2),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
						SWITCH(mySS.OBJECT[x].TYPE){
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								IF(mySS.OBJECT[x].ID_2 == pID){
									mySS.OBJECT[x].STATE[OBJ_STATE_HOOK] = !ATOI(pDATA)
									IF(mySS.OBJECT[x].STATE[OBJ_STATE_HOOK]){
										mySS.OBJECT[x].STATE[OBJ_STATE_RING] = FALSE
									}
									fnCommsRecieved(x)
								}
							}
						}
					}
				}
			}
		}
		CASE 'ran':{
			SEND_STRING vdvControl, "'PRESET-',fnRemoveQuotes(pDATA)"
			fnRefreshObjects(FALSE)
		}
		CASE 'error':{
			SEND_STRING vdvControl, "'ERROR-',pDATA"
			fnDebug(TRUE,'SoundStructure API Error:',pDATA)
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS_00)){TIMELINE_KILL(TLID_COMMS_00)}
	TIMELINE_CREATE(TLID_COMMS_00,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_RING_01]
TIMELINE_EVENT[TLID_RING_02]
TIMELINE_EVENT[TLID_RING_03]
TIMELINE_EVENT[TLID_RING_04]
TIMELINE_EVENT[TLID_RING_05]
TIMELINE_EVENT[TLID_RING_06]
TIMELINE_EVENT[TLID_RING_07]
TIMELINE_EVENT[TLID_RING_08]
TIMELINE_EVENT[TLID_RING_09]
TIMELINE_EVENT[TLID_RING_10]
TIMELINE_EVENT[TLID_RING_11]
TIMELINE_EVENT[TLID_RING_12]
TIMELINE_EVENT[TLID_RING_13]
TIMELINE_EVENT[TLID_RING_14]
TIMELINE_EVENT[TLID_RING_15]
TIMELINE_EVENT[TLID_RING_16]
TIMELINE_EVENT[TLID_RING_17]
TIMELINE_EVENT[TLID_RING_18]
TIMELINE_EVENT[TLID_RING_19]
TIMELINE_EVENT[TLID_RING_20]
TIMELINE_EVENT[TLID_RING_21]
TIMELINE_EVENT[TLID_RING_22]
TIMELINE_EVENT[TLID_RING_23]
TIMELINE_EVENT[TLID_RING_24]
TIMELINE_EVENT[TLID_RING_25]{
	mySS.OBJECT[TIMELINE.ID-TLID_RING_00].STATE[OBJ_STATE_RING] = FALSE
}

DEFINE_FUNCTION fnCommsRecieved(INTEGER x){
	IF(TIMELINE_ACTIVE(TLID_COMMS_00+x)){TIMELINE_KILL(TLID_COMMS_00+x)}
	TIMELINE_CREATE(TLID_COMMS_00+x,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnInitComms(){
	IF(TIMELINE_ACTIVE(TLID_INIT)){TIMELINE_KILL(TLID_INIT)}
	TIMELINE_CREATE(TLID_INIT,TLT_INIT,LENGTH_ARRAY(TLT_INIT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_INIT]{
	STACK_VAR INTEGER x;
	fnSendCommand('get', 'sys_name')
	FOR(x = 1; x <= _MAX_DEVICES; x++){
		fnSendCommand('get', "'dev_type ',ITOA(x)")				// Device Type
	}
}

DEFINE_FUNCTION fnRefreshObjects(INTEGER pFULL_SYNC){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(mySS.OBJECT[x].TYPE){
			CASE OBJ_TYPE_FADER:{
				fnSendCommand('get',"'mute "',mySS.OBJECT[x].ID_1,'"'")
				IF(pFULL_SYNC){
					fnSendCommand('get',"'fader min "',mySS.OBJECT[x].ID_1,'"'")
					fnSendCommand('get',"'fader max "',mySS.OBJECT[x].ID_1,'"'")
				}
				fnSendCommand('get',"'fader "',mySS.OBJECT[x].ID_1,'"'")
			}
			CASE OBJ_TYPE_POTS:
			CASE OBJ_TYPE_VOIP:{
				fnSendCommand('get',"'mute "',mySS.OBJECT[x].ID_2,'"'")
				IF(pFULL_SYNC){
					fnSendCommand('get',"'phone_connect "',mySS.OBJECT[x].ID_2,'"'");
					fnSendCommand('get',"'phone_ring "',mySS.OBJECT[x].ID_1,'"'");
				}
			}
		}
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	STACK_VAR INTEGER x
	IF(!LENGTH_ARRAY(mySS.SYS_NAME)){
		fnInitComms()
	}
	ELSE{
		FOR(x = 1; x <= _MAX_DEVICES; x++){
			IF(LENGTH_ARRAY(mySS.DEVICE[x].TYPE)){
				fnSendCommand('get', "'dev_status ',ITOA(x)")		// Device Uptime
				fnSendCommand('get', "'dev_uptime ',ITOA(x)")		// Device Uptime
				fnSendCommand('get', "'dev_temp ',ITOA(x),' 1'")	// Temp @ Back Right
				fnSendCommand('get', "'dev_temp ',ITOA(x),' 2'")	// Temp @ Centre
				fnSendCommand('get', "'dev_temp ',ITOA(x),' 3'")	// Temp @ Front Right
				fnSendCommand('get', "'eth_settings ',ITOA(x)")		// IP Settings
			}
		}
		FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
			SWITCH(mySS.OBJECT[x].TYPE){
				CASE OBJ_TYPE_FADER:{
					fnSendCommand('get',"'mute "',mySS.OBJECT[x].ID_1,'"'")
				}
				CASE OBJ_TYPE_POTS:
				CASE OBJ_TYPE_VOIP:{
					fnSendCommand('get',"'phone_ring "',mySS.OBJECT[x].ID_1,'"'");
				}
			}
		}
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_RING_01]
TIMELINE_EVENT[TLID_RING_02]
TIMELINE_EVENT[TLID_RING_03]
TIMELINE_EVENT[TLID_RING_04]
TIMELINE_EVENT[TLID_RING_05]
TIMELINE_EVENT[TLID_RING_06]
TIMELINE_EVENT[TLID_RING_07]
TIMELINE_EVENT[TLID_RING_08]
TIMELINE_EVENT[TLID_RING_09]
TIMELINE_EVENT[TLID_RING_10]
TIMELINE_EVENT[TLID_RING_11]
TIMELINE_EVENT[TLID_RING_12]
TIMELINE_EVENT[TLID_RING_13]
TIMELINE_EVENT[TLID_RING_14]
TIMELINE_EVENT[TLID_RING_15]
TIMELINE_EVENT[TLID_RING_16]
TIMELINE_EVENT[TLID_RING_17]
TIMELINE_EVENT[TLID_RING_18]
TIMELINE_EVENT[TLID_RING_19]
TIMELINE_EVENT[TLID_RING_20]
TIMELINE_EVENT[TLID_RING_21]
TIMELINE_EVENT[TLID_RING_22]
TIMELINE_EVENT[TLID_RING_23]
TIMELINE_EVENT[TLID_RING_24]
TIMELINE_EVENT[TLID_RING_25]{
	mySS.OBJECT[TIMELINE.ID-TLID_COMMS_00].STATE[OBJ_STATE_RING] = FALSE
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		mySS.IP_STATE	= IP_STATE_CONNECTED
		IF(!mySS.isIP){
			IF(LENGTH_ARRAY(mySS.BAUD) == 0){mySS.BAUD = '57600'}
			SEND_COMMAND dvDevice,"'SET BAUD ',mySS.BAUD,' N,8,1 485 DISABLE'"
		}
		fnInitComms()
	}
	OFFLINE:{
		IF(mySS.isIP){
			mySS.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(mySS.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					mySS.IP_STATE = IP_STATE_OFFLINE
					SWITCH(DATA.NUMBER){
						CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
						CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
						CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
						CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
						CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
						CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
						CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
						CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
						CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
						CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
						CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
					}
					fnRetryConnection()
				}
			}
			fnDebug(TRUE,"'SS IP Error:[',mySS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		WHILE(FIND_STRING(mySS.RX,"$0D",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(mySS.RX,"$0D",1),1))
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':fnInitComms()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						mySS.BAUD = DATA.TEXT
						SEND_COMMAND dvDevice,"'SET BAUD ',mySS.BAUD,' N,8,1 485 DISABLE'"
						fnInitComms()
					}
					CASE 'DEBUG': mySS.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'XPOINT':{
						mySS.XPOINT_REF[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							mySS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							mySS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							mySS.IP_HOST = DATA.TEXT
							mySS.IP_PORT = 52774
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'PRESET':{
				fnSendCommand('run',"'"',DATA.TEXT,'"'")
			}
			CASE 'RAW':{	// Format "RAW-cmd,data"
				fnSendCommand(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1),DATA.TEXT)
			}
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvObjects]{
	COMMAND:{
		INTEGER o
		o = GET_LAST(vdvObjects)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':{
						// Get Type
						SWITCH(fnGetCSV(DATA.TEXT,1)){
							CASE 'FADER':	mySS.OBJECT[o].TYPE = OBJ_TYPE_FADER
							CASE 'POTS':	mySS.OBJECT[o].TYPE = OBJ_TYPE_POTS
							CASE 'VOIP':	mySS.OBJECT[o].TYPE = OBJ_TYPE_VOIP
						}
						// Get ID_1 & ID_2
						mySS.OBJECT[o].ID_1 	= fnGetCSV(DATA.TEXT,2)
						mySS.OBJECT[o].ID_2 	= fnGetCSV(DATA.TEXT,3)
					}
					CASE 'STEP':mySS.OBJECT[o].LEV[OBJ_LEVEL_STEP] = ATOI(DATA.TEXT)
				}
			}
			CASE 'DIAL':{
				SWITCH(mySS.OBJECT[o].TYPE){
					CASE OBJ_TYPE_POTS:
					CASE OBJ_TYPE_VOIP:{
						SWITCH(DATA.TEXT){
							CASE 'OFFHOOK':fnSendCommand('set',"'phone_connect "',mySS.OBJECT[o].ID_2,'" 1'");
							CASE 'HANGUP': fnSendCommand('set',"'phone_connect "',mySS.OBJECT[o].ID_2,'" 0'");
							DEFAULT:{
								fnSendCommand('set',"'phone_connect "',mySS.OBJECT[o].ID_2,'" 1'")
								fnSendCommand('set',"'phone_dial "',mySS.OBJECT[o].ID_2,'" "',DATA.TEXT,'"'")
							}
						}
					}
				}
			}
			CASE 'MICMUTE':{
				SWITCH(mySS.OBJECT[o].TYPE){
					CASE OBJ_TYPE_POTS:
					CASE OBJ_TYPE_VOIP:{
						SWITCH(DATA.TEXT){
							CASE 'ON': 	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_MIC] = TRUE
							CASE 'OFF':	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_MIC] = FALSE
							CASE 'TOGGLE':
							CASE 'TOG':	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_MIC] = !mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_MIC]
						}
						SWITCH(mySS.OBJECT[o].TYPE){
							CASE OBJ_TYPE_POTS:
							CASE OBJ_TYPE_VOIP:{
								fnSendCommand('set',"'mute "',mySS.OBJECT[o].ID_2,'" ',ITOA(mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_MIC])");
							}
						}
					}
				}

			}
			CASE 'MUTE':{
				SWITCH(mySS.OBJECT[o].TYPE){
					CASE OBJ_TYPE_VOIP:
					CASE OBJ_TYPE_POTS:
					CASE OBJ_TYPE_FADER:{
						SWITCH(DATA.TEXT){
							CASE 'ON': 	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_FADER] = TRUE
							CASE 'OFF':	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_FADER] = FALSE
							CASE 'TOGGLE':
							CASE 'TOG':	mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_FADER] = !mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_FADER]
						}
						fnSendCommand('set',"'mute "',mySS.OBJECT[o].ID_1,'" ',ITOA(mySS.OBJECT[o].STATE[OBJ_STATE_MUTE_FADER])");
					}
				}
			}
			CASE 'VOLUME':{
				SWITCH(mySS.OBJECT[o].TYPE){
					CASE OBJ_TYPE_FADER:{
						IF(!mySS.OBJECT[o].LEV[OBJ_LEVEL_STEP]){mySS.OBJECT[o].LEV[OBJ_LEVEL_STEP] = 1}
						SWITCH(DATA.TEXT){
							CASE 'INC':	fnSendCommand('inc',"'fader "',mySS.OBJECT[o].ID_1,'" ',ITOA(mySS.OBJECT[o].LEV[OBJ_LEVEL_STEP])");
							CASE 'DEC':	fnSendCommand('dec',"'fader "',mySS.OBJECT[o].ID_1,'" ',ITOA(mySS.OBJECT[o].LEV[OBJ_LEVEL_STEP])");
							DEFAULT:{
								IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
									fnSendCommand('set',"'fader "',mySS.OBJECT[o].ID_1,'" ',DATA.TEXT")
									TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									mySS.OBJECT[o].LAST_VOL = ATOI(DATA.TEXT)
									mySS.OBJECT[o].VOL_PEND = TRUE
								}
							}
						}
					}
				}
			}
		}
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_VOL_01]
TIMELINE_EVENT[TLID_VOL_02]
TIMELINE_EVENT[TLID_VOL_03]
TIMELINE_EVENT[TLID_VOL_04]
TIMELINE_EVENT[TLID_VOL_05]
TIMELINE_EVENT[TLID_VOL_06]
TIMELINE_EVENT[TLID_VOL_07]
TIMELINE_EVENT[TLID_VOL_08]
TIMELINE_EVENT[TLID_VOL_09]
TIMELINE_EVENT[TLID_VOL_10]
TIMELINE_EVENT[TLID_VOL_11]
TIMELINE_EVENT[TLID_VOL_12]
TIMELINE_EVENT[TLID_VOL_13]
TIMELINE_EVENT[TLID_VOL_14]
TIMELINE_EVENT[TLID_VOL_15]
TIMELINE_EVENT[TLID_VOL_16]
TIMELINE_EVENT[TLID_VOL_17]
TIMELINE_EVENT[TLID_VOL_18]
TIMELINE_EVENT[TLID_VOL_19]
TIMELINE_EVENT[TLID_VOL_20]
TIMELINE_EVENT[TLID_VOL_21]
TIMELINE_EVENT[TLID_VOL_22]
TIMELINE_EVENT[TLID_VOL_23]
TIMELINE_EVENT[TLID_VOL_24]
TIMELINE_EVENT[TLID_VOL_25]{
	STACK_VAR INTEGER g
	g = TIMELINE.ID - TLID_VOL_00
	IF(mySS.OBJECT[g].VOL_PEND){
		fnSendCommand('set',"'fader "',mySS.OBJECT[g].ID_1,'" ',ITOA(mySS.OBJECT[g].LAST_VOL)")
		mySS.OBJECT[g].VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Event Trigger Force
******************************************************************************/
DEFINE_EVENT CHANNEL_EVENT[vdvObjects,0]{
	ON:{}
	OFF:{}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(mySS.OBJECT[x].TYPE){
			CASE OBJ_TYPE_FADER:{
				[vdvObjects[x],199] 	= ( mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_FADER])
			}
			CASE OBJ_TYPE_POTS:
			CASE OBJ_TYPE_VOIP:{
				[vdvObjects[x],198] 	= ( mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_MIC])
				[vdvObjects[x],199] 	= ( mySS.OBJECT[x].STATE[OBJ_STATE_MUTE_FADER])
				[vdvObjects[x],236] 	= ( mySS.OBJECT[x].STATE[OBJ_STATE_RING])
				[vdvObjects[x],238] 	= (!mySS.OBJECT[x].STATE[OBJ_STATE_HOOK] && TIMELINE_ACTIVE(TLID_COMMS_00+x))
			}
		}
		IF(mySS.OBJECT[x].TYPE){
			[vdvObjects[x],251] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
			[vdvObjects[x],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
		}
	}
	// Send level states
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		IF(mySS.OBJECT[x].TYPE){
			STACK_VAR INTEGER y
			FOR(y = 1; y <= 8; y++){
				SEND_LEVEL vdvObjects[x],y,mySS.OBJECT[x].LEV[y]
			}
		}
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS_00))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS_00))
}