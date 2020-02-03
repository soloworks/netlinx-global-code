MODULE_NAME='mQSYS'(DEV vdvControl, DEV vdvObjects[], DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Q-SYS Module
	By Solo Control Ltd (www.solocontrol.co.uk)
	
	Camera object looks for Named Controls in format:
	"~ID~[PanLeft|PanRight|TiltUp|TiltDown|ZoomIn|ZoomOut]"
******************************************************************************/
#WARN 'Use CSP instead of CSV for levels, as that is 0.000 to 1.000 of actual level range'
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER _MAX_OBJECTS          = 50
// Object Types
INTEGER OBJ_TYPE_LEVEL			= 1
INTEGER OBJ_TYPE_BUTTON       = 2
INTEGER OBJ_TYPE_CAMERA       = 3
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_CONNECTED		= 2
// Generic Object
DEFINE_TYPE STRUCTURE uObject{
	INTEGER	TYPE				// Object Type
	CHAR 		ID_1[255]		// Main Reference Tag (Level)
	CHAR 		ID_2[255]		// Secondary Reference Tag (Mute)
	SINTEGER VALUE_GAIN		// Object Levels (Indexed Above)
	INTEGER  VALUE_MUTE		// Object States (Indexed Above)
	SINTEGER	GAIN_LIMITS[2]	// Object Level Max Value

	INTEGER 	GAIN_PEND		// Is a Volume Update pending
	SINTEGER	LAST_GAIN		// Volume to Send
	INTEGER	GAIN_STEP		// Number by which to INC or DEC gain
}

DEFINE_TYPE STRUCTURE uQSys{
	// Comms
	CHAR 		RX[2000]						// Receieve Buffer
	INTEGER 	IP_PORT						//
	CHAR		IP_HOST[255]				//
	INTEGER 	IP_STATE						//
	INTEGER 	DEBUG							// Debugging Mode

	uObject  OBJECTS[_MAX_OBJECTS]
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
LONG TLID_COMMS_26	= 126
LONG TLID_COMMS_27	= 127
LONG TLID_COMMS_28	= 128
LONG TLID_COMMS_29	= 129
LONG TLID_COMMS_30	= 130
LONG TLID_COMMS_31	= 131
LONG TLID_COMMS_32	= 132
LONG TLID_COMMS_33	= 133
LONG TLID_COMMS_34	= 134
LONG TLID_COMMS_35	= 135
LONG TLID_COMMS_36	= 136
LONG TLID_COMMS_37	= 137
LONG TLID_COMMS_38	= 138
LONG TLID_COMMS_39	= 139
LONG TLID_COMMS_40	= 140
LONG TLID_COMMS_41	= 141
LONG TLID_COMMS_42	= 142
LONG TLID_COMMS_43	= 143
LONG TLID_COMMS_44	= 144
LONG TLID_COMMS_45	= 145
LONG TLID_COMMS_46	= 146
LONG TLID_COMMS_47	= 147
LONG TLID_COMMS_48	= 148
LONG TLID_COMMS_49	= 149
LONG TLID_COMMS_50	= 150

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
LONG TLID_VOL_26		= 226
LONG TLID_VOL_27		= 227
LONG TLID_VOL_28		= 228
LONG TLID_VOL_29		= 229
LONG TLID_VOL_30		= 230
LONG TLID_VOL_31		= 231
LONG TLID_VOL_32		= 232
LONG TLID_VOL_33		= 233
LONG TLID_VOL_34		= 234
LONG TLID_VOL_35		= 235
LONG TLID_VOL_36		= 236
LONG TLID_VOL_37		= 237
LONG TLID_VOL_38		= 238
LONG TLID_VOL_39		= 239
LONG TLID_VOL_40		= 240
LONG TLID_VOL_41		= 241
LONG TLID_VOL_42		= 242
LONG TLID_VOL_43		= 243
LONG TLID_VOL_44		= 244
LONG TLID_VOL_45		= 245
LONG TLID_VOL_46		= 246
LONG TLID_VOL_47		= 247
LONG TLID_VOL_48		= 248
LONG TLID_VOL_49		= 249
LONG TLID_VOL_50		= 250
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uQSys		myQSYS

LONG 		TLT_COMMS[] = { 120000 }
LONG 		TLT_POLL[]  = {  45000 }
LONG 		TLT_RETRY[]	= {   5000 }
LONG 		TLT_VOL[]	= {	 200 }
LONG 		TLT_INIT[]	= {	2500 }
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvDevice, myQSYS.RX
}
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendQuery(CHAR pControlID[]){
	STACK_VAR CHAR toSend[255]
	toSend = "'cg ',pControlID,$0A"
	IF(myQSYS.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->QSYS',toSend)
		SEND_STRING dvDevice, toSend
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[], CHAR pID[], CHAR pVal[]){
	STACK_VAR CHAR toSend[255]
	toSend = "pCMD,' ',pID"
	IF(LENGTH_ARRAY(pVal)){
		toSend = "toSend,' ',pVal"
	}
	toSend = "toSend,$0A"

	IF(myQSYS.IP_STATE == IP_STATE_CONNECTED){
		fnDebug(FALSE,'->QSYS',toSend)
		SEND_STRING dvDevice, toSend
		fnInitPoll()
	}
}

DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myQSYS.DEBUG || pFORCE){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myQSYS.IP_HOST == ''){
		fnDebug(TRUE,'QSYS Host','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to QSYS on ',"myQSYS.IP_HOST,':',ITOA(myQSYS.IP_PORT)")
		myQSYS.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvDevice.port, myQSYS.IP_HOST, myQSYS.IP_PORT, IP_TCP)
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

	STACK_VAR INTEGER x

	fnDebug(FALSE,'QSYS->',pDATA)
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'cv':{
			STACK_VAR pCONTROL_STRING[50]
			STACK_VAR pCONTROL_VALUE[50]
			STACK_VAR pCONTROL_POSITION[50]

			pCONTROL_STRING 	= fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
			pCONTROL_VALUE 	= fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1))
			pCONTROL_POSITION = fnRemoveQuotes(pDATA)

			FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
				SWITCH(myQSYS.OBJECTS[x].TYPE){
					CASE OBJ_TYPE_LEVEL:{
						//send_string 0,"'controlVal',pCONTROL_VALUE,' ',pCONTROL_POSITION"
						SELECT{
							ACTIVE(myQSYS.OBJECTS[x].ID_1 == pCONTROL_STRING):myQSYS.OBJECTS[x].VALUE_GAIN = ATOI(pCONTROL_VALUE)
							ACTIVE(myQSYS.OBJECTS[x].ID_2 == pCONTROL_STRING):myQSYS.OBJECTS[x].VALUE_MUTE = ATOI(pCONTROL_POSITION)
						}
						SELECT{
							ACTIVE(myQSYS.OBJECTS[x].ID_1 == pCONTROL_STRING):fnCommsRecieved(x)
							ACTIVE(myQSYS.OBJECTS[x].ID_2 == pCONTROL_STRING):fnCommsRecieved(x)
						}
					}
				}
			}
		}
		CASE 'sr':{
			IF(TIMELINE_ACTIVE(TLID_COMMS_00)){TIMELINE_KILL(TLID_COMMS_00)}
			TIMELINE_CREATE(TLID_COMMS_00,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

DEFINE_FUNCTION fnCommsRecieved(INTEGER x){
	IF(TIMELINE_ACTIVE(TLID_COMMS_00+x)){TIMELINE_KILL(TLID_COMMS_00+x)}
	TIMELINE_CREATE(TLID_COMMS_00+x,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('sg','','')
}
DEFINE_FUNCTION fnInitControlGroup(){
	STACK_VAR INTEGER x

	// Create Control Group
	fnSendCommand('cgc','1','')

	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myQSYS.OBJECTS[x].TYPE){
			CASE OBJ_TYPE_LEVEL:{
				IF(LENGTH_ARRAY(myQSYS.OBJECTS[x].ID_1)){
					fnSendCommand('cga','1',myQSYS.OBJECTS[x].ID_1)
				}
				IF(LENGTH_ARRAY(myQSYS.OBJECTS[x].ID_2)){
					fnSendCommand('cga','1',myQSYS.OBJECTS[x].ID_2)
				}
			}
		}
	}

	// Do A Poll For Values
	fnSendCommand('cgpna','1','')

	// Set Poll Time
	fnSendCommand('cgsna','1','250')
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		myQSYS.IP_STATE	= IP_STATE_CONNECTED
		fnInitPoll()
		fnPoll()
		fnInitControlGroup()
	}
	OFFLINE:{
		myQSYS.IP_STATE	= IP_STATE_OFFLINE
		fnRetryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		SWITCH(DATA.NUMBER){
			CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
			DEFAULT:{
				myQSYS.IP_STATE = IP_STATE_OFFLINE
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
		fnDebug(TRUE,"'QSYS IP Error:[',myQSYS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
	}
	STRING:{
		WHILE(FIND_STRING(myQSYS.RX,"$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myQSYS.RX,"$0A",1),1))
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
					CASE 'POLL':fnPoll()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myQSYS.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myQSYS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myQSYS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myQSYS.IP_HOST = DATA.TEXT
							myQSYS.IP_PORT = 1702
						}
						fnRetryConnection()
					}
				}
			}
			CASE 'PRESET':{
				fnSendCommand('ct',DATA.TEXT,'')
			}
			CASE 'SNAPSHOT':{
				STACK_VAR CHAR bankName[50]
				STACK_VAR INTEGER bankNo
				STACK_VAR FLOAT rampTime
				bankName = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				bankNo = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				rampTime = ATOF(DATA.TEXT)
				fnSendCommand('ssl',"'"',bankName,'" ',ITOA(bankNo)",FTOA(rampTime))
			}
			CASE 'RAW':{
				STACK_VAR CHAR toSend[255]
				toSend = "DATA.TEXT,$0A"
				IF(myQSYS.IP_STATE == IP_STATE_CONNECTED){
					fnDebug(FALSE,'->QSYS',toSend)
					SEND_STRING dvDevice, toSend
				}
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
					CASE 'STEP':{
						myQSYS.OBJECTS[o].GAIN_STEP = ATOI(DATA.TEXT)
					}
					CASE 'ID':{
						// Get Type
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'LEVEL':	myQSYS.OBJECTS[o].TYPE = OBJ_TYPE_LEVEL
							CASE 'BUTTON': myQSYS.OBJECTS[o].TYPE = OBJ_TYPE_BUTTON
							CASE 'CAMERA': myQSYS.OBJECTS[o].TYPE = OBJ_TYPE_CAMERA
						}
						// Get ID_1 & ID_2
						IF(FIND_STRING(DATA.TEXT,',',1)){
							myQSYS.OBJECTS[o].ID_1 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							myQSYS.OBJECTS[o].ID_2 	= DATA.TEXT
						}
						ELSE{
							myQSYS.OBJECTS[o].ID_1 	= DATA.TEXT
							myQSYS.OBJECTS[o].ID_2 	= ''
						}
					}
				}
			}
			CASE 'BUTTON':{
				SWITCH(myQSYS.OBJECTS[o].TYPE){
					CASE OBJ_TYPE_BUTTON:{
						SWITCH(DATA.TEXT){
							CASE 'PUSH': 		myQSYS.OBJECTS[o].VALUE_MUTE = TRUE
							CASE 'RELEASE':	myQSYS.OBJECTS[o].VALUE_MUTE = FALSE
						}
						fnSendCommand('csv',myQSYS.OBJECTS[o].ID_2,ITOA(myQSYS.OBJECTS[o].VALUE_MUTE))
					}
				}
			}
			CASE 'MUTE':
			CASE 'MICMUTE':{
				SWITCH(myQSYS.OBJECTS[o].TYPE){
					CASE OBJ_TYPE_LEVEL:{
						SWITCH(DATA.TEXT){
							CASE 'ON': 	myQSYS.OBJECTS[o].VALUE_MUTE = TRUE
							CASE 'OFF':	myQSYS.OBJECTS[o].VALUE_MUTE = FALSE
							CASE 'TOGGLE':
							CASE 'TOG':	myQSYS.OBJECTS[o].VALUE_MUTE = !myQSYS.OBJECTS[o].VALUE_MUTE
						}
						fnSendCommand('csv',myQSYS.OBJECTS[o].ID_2,ITOA(myQSYS.OBJECTS[o].VALUE_MUTE))
					}
				}
			}
			CASE 'VOLUME':{
				SWITCH(myQSYS.OBJECTS[o].TYPE){
					CASE OBJ_TYPE_LEVEL:{
						IF(!myQSYS.OBJECTS[o].GAIN_STEP){myQSYS.OBJECTS[o].GAIN_STEP = 1}
						SWITCH(DATA.TEXT){
							CASE 'INC':	fnSendCommand('csv',myQSYS.OBJECTS[o].ID_1,"ITOA(myQSYS.OBJECTS[o].VALUE_GAIN + TYPE_CAST(myQSYS.OBJECTS[o].GAIN_STEP)),'.0'")
							CASE 'DEC':	fnSendCommand('csv',myQSYS.OBJECTS[o].ID_1,"ITOA(myQSYS.OBJECTS[o].VALUE_GAIN - TYPE_CAST(myQSYS.OBJECTS[o].GAIN_STEP)),'.0'")
							DEFAULT:{
								IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
									fnSendCommand('csv', myQSYS.OBJECTS[o].ID_1,DATA.TEXT)
									TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									myQSYS.OBJECTS[o].LAST_GAIN = ATOI(DATA.TEXT)
									myQSYS.OBJECTS[o].GAIN_PEND = TRUE
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
TIMELINE_EVENT[TLID_VOL_25]
TIMELINE_EVENT[TLID_VOL_26]
TIMELINE_EVENT[TLID_VOL_27]
TIMELINE_EVENT[TLID_VOL_28]
TIMELINE_EVENT[TLID_VOL_29]
TIMELINE_EVENT[TLID_VOL_30]
TIMELINE_EVENT[TLID_VOL_31]
TIMELINE_EVENT[TLID_VOL_32]
TIMELINE_EVENT[TLID_VOL_33]
TIMELINE_EVENT[TLID_VOL_34]
TIMELINE_EVENT[TLID_VOL_35]
TIMELINE_EVENT[TLID_VOL_36]
TIMELINE_EVENT[TLID_VOL_37]
TIMELINE_EVENT[TLID_VOL_38]
TIMELINE_EVENT[TLID_VOL_39]
TIMELINE_EVENT[TLID_VOL_40]
TIMELINE_EVENT[TLID_VOL_41]
TIMELINE_EVENT[TLID_VOL_42]
TIMELINE_EVENT[TLID_VOL_43]
TIMELINE_EVENT[TLID_VOL_44]
TIMELINE_EVENT[TLID_VOL_45]
TIMELINE_EVENT[TLID_VOL_46]
TIMELINE_EVENT[TLID_VOL_47]
TIMELINE_EVENT[TLID_VOL_48]
TIMELINE_EVENT[TLID_VOL_49]
TIMELINE_EVENT[TLID_VOL_50]{
	STACK_VAR INTEGER o
	o = TIMELINE.ID - TLID_VOL_00
	IF(myQSYS.OBJECTS[o].GAIN_PEND){
		fnSendCommand('csv',myQSYS.OBJECTS[o].ID_1,ITOA(myQSYS.OBJECTS[o].LAST_GAIN))
		myQSYS.OBJECTS[o].GAIN_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myQSYS.OBJECTS[x].TYPE){
			CASE OBJ_TYPE_LEVEL:{
				[vdvObjects[x],198] 	= ( myQSYS.OBJECTS[x].VALUE_MUTE)
				[vdvObjects[x],199] 	= ( myQSYS.OBJECTS[x].VALUE_MUTE)
			}
		}
		IF(myQSYS.OBJECTS[x].TYPE){
			[vdvObjects[x],251] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
			[vdvObjects[x],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+x))
		}
	}
	// Send level states
	FOR(x = 1; x <= LENGTH_ARRAY(vdvObjects); x++){
		SWITCH(myQSYS.OBJECTS[x].TYPE){
			CASE OBJ_TYPE_LEVEL:SEND_LEVEL vdvObjects[x],1,myQSYS.OBJECTS[x].VALUE_GAIN
		}
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS_00))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS_00))
}
/******************************************************************************
	Camera Control
******************************************************************************/
DEFINE_CONSTANT
INTEGER chnPTZ[] = {132,133,134,135,158,159}
DEFINE_EVENT CHANNEL_EVENT[vdvObjects,chnPTZ]{
	ON:{
		STACK_VAR INTEGER o
		o = GET_LAST(vdvObjects)
		IF(myQSYS.OBJECTS[o].TYPE == OBJ_TYPE_CAMERA){
			SWITCH(CHANNEL.CHANNEL){
				CASE 132:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'TiltUp'",ITOA(1))
				CASE 133:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'TiltDown'",ITOA(1))
				CASE 134:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'PanLeft'",ITOA(1))
				CASE 135:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'PanRight'",ITOA(1))
				CASE 158:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'ZoomIn'",ITOA(1))
				CASE 159:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'ZoomOut'",ITOA(1))
			}
		}
	}
	OFF:{
		STACK_VAR INTEGER o
		o = GET_LAST(vdvObjects)
		IF(myQSYS.OBJECTS[o].TYPE == OBJ_TYPE_CAMERA){
			SWITCH(CHANNEL.CHANNEL){
				CASE 132:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'TiltUp'",ITOA(0))
				CASE 133:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'TiltDown'",ITOA(0))
				CASE 134:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'PanLeft'",ITOA(0))
				CASE 135:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'PanRight'",ITOA(0))
				CASE 158:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'ZoomIn'",ITOA(0))
				CASE 159:fnSendCommand('csv',"myQSYS.OBJECTS[o].ID_1,'ZoomOut'",ITOA(0))
			}
		}
	}
}
/******************************************************************************
	Channel Feedback
******************************************************************************/
DEFINE_EVENT
CHANNEL_EVENT[vdvObjects,198]
CHANNEL_EVENT[vdvObjects,199]{
	ON:{}
	OFF:{}
}
/******************************************************************************
	Device Feedback
******************************************************************************/