MODULE_NAME='mBoseESP'(DEV vdvControl, DEV vdvObjects[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Bose ESP Module
	By Solo Control Ltd (www.solocontrol.co.uk)	
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
// Object Types
INTEGER OBJ_TYPE_GAIN			= 1
// Object States
INTEGER OBJ_STATE_MUTE_GAIN	= 1	// Object Mute State
// Object Level 
INTEGER OBJ_LEVEL_GAIN			= 1	// Object Gain Value
INTEGER OBJ_LEVEL_STEP			= 2	// Object Step value for VOL changes
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
// Generic Object 
DEFINE_TYPE STRUCTURE uObject{
	INTEGER	TYPE
	CHAR 		ID[255]			// Main Reference Tag
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

DEFINE_TYPE STRUCTURE uESP{
	// Comms
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						// 
	CHAR		IP_HOST[255]				//	
	INTEGER 	IP_STATE						// 
	INTEGER	isIP					
	INTEGER 	DEBUG							// Debugging	
	CHAR		BAUD[10]						// Current Baud Rate for RS232
	// State
	CHAR 		SYS_NAME[255]				// System Name
	uDevice	DEVICE[8]
	// CrossPoints
	CHAR 		XPOINT_REF[30][30]		// CrossPoint Reference
	INTEGER 	XPOINT_VAL[30]				// State of above CrossPoint
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL		= 1
LONG TLID_RETRY	= 2
LONG TLID_INIT		= 3

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
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uESP		myESPUnit
VOLATILE uObject 	myESPObjs[20]

LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
LONG 		TLT_INIT[]	= {	2500 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myESPUnit.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myESPUnit.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pDATA,$0D"
	
	IF(myESPUnit.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->ESP',toSend)
		SEND_STRING dvDevice, toSend
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myESPUnit.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myESPUnit.IP_HOST == ''){
		fnDebug(TRUE,'ESP IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to ESP on ',"myESPUnit.IP_HOST,':',ITOA(myESPUnit.IP_PORT)")
		myESPUnit.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myESPUnit.IP_HOST, myESPUnit.IP_PORT, IP_TCP) 
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
	fnDebug(FALSE,'ESP->',pDATA)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)){
		CASE 'GA':{
			pID = fnStripCharsRight(REMOVE_STRING(pDATA,'"',1),1)
			FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
				IF(myESPObjs[x].TYPE){
					IF(myESPObjs[x].ID == pID){
						SWITCH(myESPObjs[x].TYPE){
							CASE OBJ_TYPE_GAIN:{
								GET_BUFFER_CHAR(pDATA) // STRIP '>'
								SWITCH(ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1))){
									CASE 1:myESPObjs[x].LEV[OBJ_LEVEL_GAIN] = ATOI(pDATA)
									CASE 2:{
										SWITCH(pDATA){
											CASE 'O':myESPObjs[x].STATE[OBJ_STATE_MUTE_GAIN] = TRUE
											CASE 'F':myESPObjs[x].STATE[OBJ_STATE_MUTE_GAIN] = FALSE
										}
									}
								}
							}
						}
						fnCommsRecieved(x)
					}
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS_00)){TIMELINE_KILL(TLID_COMMS_00)}
	TIMELINE_CREATE(TLID_COMMS_00,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
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
	fnSendCommand('IP')
	fnRefreshObjects()
}

DEFINE_FUNCTION fnRefreshObjects(){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myESPObjs[x].TYPE){
			CASE OBJ_TYPE_GAIN:{
				fnSendCommand("'GA"',myESPObjs[x].ID,'">1'")	// Get Gain Value
				fnSendCommand("'GA"',myESPObjs[x].ID,'">2'")	// Get Mute Value
			}
		}
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand('IP')
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myESPUnit.IP_STATE	= IP_STATE_CONNECTED
		IF(!myESPUnit.isIP){
			IF(LENGTH_ARRAY(myESPUnit.BAUD) == 0){myESPUnit.BAUD = '57600'}
			SEND_COMMAND dvDevice,"'SET BAUD ',myESPUnit.BAUD,' N,8,1 485 DISABLE'"
		}
		fnInitComms()
	}
	OFFLINE:{
		IF(myESPUnit.isIP){
			myESPUnit.IP_STATE	= IP_STATE_OFFLINE
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myESPUnit.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myESPUnit.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(TRUE,"'ESP IP Error:[',myESPUnit.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		WHILE(FIND_STRING(myESPUnit.RX,"$0D",1)){
			STACK_VAR CHAR myPacket[500]
			myPacket = fnStripCharsRight(REMOVE_STRING(myESPUnit.RX,"$0D",1),1)
			WHILE(FIND_STRING(myPacket,"';'",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPacket,"';'",1),1))
			}
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
						myESPUnit.BAUD = DATA.TEXT
						SEND_COMMAND dvDevice,"'SET BAUD ',myESPUnit.BAUD,' N,8,1 485 DISABLE'"
						fnInitComms()
					}
					CASE 'DEBUG': myESPUnit.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myESPUnit.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myESPUnit.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myESPUnit.IP_HOST = DATA.TEXT
							myESPUnit.IP_PORT = 10055 
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'PRESET':{
				fnSendCommand("'SS ',DATA.TEXT")
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
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
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'GAIN':	myESPObjs[o].TYPE = OBJ_TYPE_GAIN
						}
						myESPObjs[o].ID	= DATA.TEXT
					}
					CASE 'STEP':myESPObjs[o].LEV[OBJ_LEVEL_STEP] = ATOI(DATA.TEXT)
				}
			}
			CASE 'MUTE':{
				SWITCH(myESPObjs[o].TYPE){
					CASE OBJ_TYPE_GAIN:{
						SWITCH(DATA.TEXT){
							CASE 'ON': myESPObjs[o].STATE[OBJ_STATE_MUTE_GAIN] = TRUE
							CASE 'OFF':myESPObjs[o].STATE[OBJ_STATE_MUTE_GAIN] = FALSE
							DEFAULT:		myESPObjs[o].STATE[OBJ_STATE_MUTE_GAIN] = !myESPObjs[o].STATE[OBJ_STATE_MUTE_GAIN]
						}
						SWITCH(myESPObjs[o].STATE[OBJ_STATE_MUTE_GAIN]){
							CASE TRUE: 	fnSendCommand("'SA"',myESPObjs[o].ID,'">2=O'")
							CASE FALSE:	fnSendCommand("'SA"',myESPObjs[o].ID,'">2=F'")
						}
					}
				}
			}
			CASE 'VOLUME':{
				SWITCH(myESPObjs[o].TYPE){
					CASE OBJ_TYPE_GAIN:{
						IF(!myESPObjs[o].LEV[OBJ_LEVEL_STEP]){myESPObjs[o].LEV[OBJ_LEVEL_STEP] = 1}
						SWITCH(DATA.TEXT){
							//CASE 'INC':	fnSendCommand('inc',"'fader "',myESPObjs[o].ID_1,'" ',ITOA(myESPObjs[o].LEV[OBJ_LEVEL_STEP])");
							//CASE 'DEC':	fnSendCommand('dec',"'fader "',myESPObjs[o].ID_1,'" ',ITOA(myESPObjs[o].LEV[OBJ_LEVEL_STEP])");
							DEFAULT:{
								IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
									myESPObjs[o].LEV[OBJ_LEVEL_GAIN] = ATOI(DATA.TEXT)
									fnSendCommand("'SA"',myESPObjs[o].ID,'">1=',ITOA(myESPObjs[o].LEV[OBJ_LEVEL_GAIN])")
									TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									myESPObjs[o].LAST_VOL = ATOI(DATA.TEXT)
									myESPObjs[o].VOL_PEND = TRUE
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
TIMELINE_EVENT[TLID_VOL_20]{
	STACK_VAR INTEGER g
	g = TIMELINE.ID - TLID_VOL_00
	IF(myESPObjs[g].VOL_PEND){
		myESPObjs[g].LEV[OBJ_LEVEL_GAIN] = myESPObjs[g].LAST_VOL
		fnSendCommand("'SA"',myESPObjs[g].ID,'">1=',ITOA(myESPObjs[g].LAST_VOL)")
		myESPObjs[g].VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myESPObjs[x].TYPE){
			CASE OBJ_TYPE_GAIN:{
				[vdvObjects[x],199] 	= ( myESPObjs[x].STATE[OBJ_STATE_MUTE_GAIN])
			}
		}
		IF(myESPObjs[x].TYPE){
			[vdvObjects[x],251] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
			[vdvObjects[x],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
		}
	}
	// Send level states
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		IF(myESPObjs[x].TYPE){
			STACK_VAR INTEGER y
			FOR(y = 1; y <= 8; y++){
				SEND_LEVEL vdvObjects[x],y,myESPObjs[x].LEV[y]
			}
		}
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS_00))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS_00))
}