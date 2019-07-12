MODULE_NAME='mSoundWebLondon'(DEV vdvControl, DEV vdvObjects[], DEV dvDevice)
/******************************************************************************
		Module for control of Soundweb London
		Gains & Matrix covered
		20 of each hard coded - alter code for more
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Structures for Object Data
******************************************************************************/
DEFINE_CONSTANT 
INTEGER _MAX_OBJECTS_ = 50

DEFINE_TYPE STRUCTURE uObject{
	INTEGER	TYPE				// Object Type
	CHAR 		HiQ[12]			// HiQ ID - Debug Readable
	CHAR 		HiQ_REF[6]		// HiQ ID - In Bytes
	// Gain Setup
	INTEGER	GAIN_SV			// Index for Gain value on this HiQ
	INTEGER	MUTE_SV			// Index for Mute value on this HiQ
	SINTEGER	GAIN_STEP		// Increments to affect Gain changes
	// Gain State
	SINTEGER	GAIN_VALUE		// Current Gain value
	SLONG    GAIN_VALUE_255	// Gain Value in range 0-255
	INTEGER	MUTE_VALUE		// Current Mute value
	INTEGER 	NEW_GAIN_PEND	// Is new Gain value Pending?
	SINTEGER	NEW_GAIN_VALUE	// New gain value
	INTEGER  FADE_ACTIVE		// Is a fade active on a FadeGain?
	// Object Bounds
	INTEGER 	BOUNDS[2]		// X,Y Size of Matrix OR Min/Max of Gain
	// Matrix States
	INTEGER 	MTX_STATE[16][16]	// Current state of X,Y Crosspoint
}
DEFINE_TYPE STRUCTURE uComms{
	// Serial Comms
	LONG		BAUD				// Serial Baud Rate
	// IP Comms
	INTEGER 	isIP				// Is this device IP controlled?
	INTEGER 	CONN_STATE		// Current Connection State
	INTEGER 	IP_PORT			// IP Port for connection (BSS Default 1023)
	CHAR	  	IP_HOST[255]	// IP Host for connection
	// General Comms
	CHAR 	  	Tx[1000]			// Transmit Buffer
	CHAR 	  	Rx[1000]			// Recieve Buffer
}
DEFINE_TYPE STRUCTURE uBSS{
	INTEGER 	DEBUG				// Debug State
	uComms	COMMS
	uObject	OBJECT[_MAX_OBJECTS_]
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_RETRY 	= 1
LONG TLID_FADES 	= 2
LONG TLID_COMMS	= 3

LONG TLID_VOL_00	= 100
LONG TLID_VOL_01	= 101
LONG TLID_VOL_02	= 102
LONG TLID_VOL_03	= 103
LONG TLID_VOL_04	= 104
LONG TLID_VOL_05	= 105
LONG TLID_VOL_06	= 106
LONG TLID_VOL_07	= 107
LONG TLID_VOL_08	= 108
LONG TLID_VOL_09	= 109
LONG TLID_VOL_10	= 110
LONG TLID_VOL_11	= 111
LONG TLID_VOL_12	= 112
LONG TLID_VOL_13	= 113
LONG TLID_VOL_14	= 114
LONG TLID_VOL_15	= 115
LONG TLID_VOL_16	= 116
LONG TLID_VOL_17	= 117
LONG TLID_VOL_18	= 118
LONG TLID_VOL_19	= 119
LONG TLID_VOL_20	= 120
LONG TLID_VOL_21	= 121
LONG TLID_VOL_22	= 122
LONG TLID_VOL_23	= 123
LONG TLID_VOL_24	= 124
LONG TLID_VOL_25	= 125
LONG TLID_VOL_26	= 126
LONG TLID_VOL_27	= 127
LONG TLID_VOL_28	= 128
LONG TLID_VOL_29	= 129
LONG TLID_VOL_30	= 130
LONG TLID_VOL_31	= 131
LONG TLID_VOL_32	= 132
LONG TLID_VOL_33	= 133
LONG TLID_VOL_34	= 134
LONG TLID_VOL_35	= 135
LONG TLID_VOL_36	= 136
LONG TLID_VOL_37	= 137
LONG TLID_VOL_38	= 138
LONG TLID_VOL_39	= 139
LONG TLID_VOL_40	= 140

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

INTEGER CONN_STATE_OFFLINE 	= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED	= 2

INTEGER OBJ_TYPE_GAIN	= 1
INTEGER OBJ_TYPE_MATRIX	= 2
INTEGER OBJ_TYPE_VOIP	= 3
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uBSS	myBSS
LONG 		TLT_RETRY[] = { 5000 }
LONG 		TLT_FADES[] = { 3000 }
LONG 		TLT_VOL[]	= {  200 }
LONG		TLT_COMMS[]	= {90000 }
/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myBSS.COMMS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'BSS IP','Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,"'Connecting to BSS on '","myBSS.COMMS.IP_HOST,':', ITOA(myBSS.COMMS.IP_PORT)")
		myBSS.COMMS.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myBSS.COMMS.IP_HOST, myBSS.COMMS.IP_PORT, IP_TCP)
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

DEFINE_FUNCTION fnInitComms(){
	STACK_VAR INTEGER o
	// Initialise communications
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		IF(LENGTH_ARRAY(myBSS.OBJECT[o].HiQ_REF)){
			SWITCH(myBSS.OBJECT[o].TYPE){
				CASE OBJ_TYPE_GAIN:{
					fnSubscribePercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV)
					fnSubscribe(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].MUTE_SV)
				}
				CASE OBJ_TYPE_MATRIX:{
					STACK_VAR INTEGER y
					FOR(y = 1; y <= myBSS.OBJECT[o].BOUNDS[2]; y++){
						STACK_VAR INTEGER x
						FOR(x = 1; x <= myBSS.OBJECT[o].BOUNDS[1] ; x++){
							STACK_VAR INTEGER MTX_XPOINT_pID
							IF(y == 1) {MTX_XPOINT_pID = 0} ELSE{ MTX_XPOINT_pID = (y-1) * 128 }
							MTX_XPOINT_pID = MTX_XPOINT_pID+x-1
							fnSubscribe(myBSS.OBJECT[o].HiQ_REF,MTX_XPOINT_pID)
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
Debug Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER DebugType, CHAR Msg[], CHAR MsgData[]){
	IF(myBSS.DEBUG >= DebugType)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnHexDebug(CHAR Msg[]){
	STACK_VAR INTEGER i;
	STACK_VAR CHAR dbg[100]
	FOR(i = 1;i <= LENGTH_ARRAY(Msg);i++){
		dbg = "dbg,'0x',fnPadLeadingChars( ITOHEX(Msg[i]),'0',1),' '"
	}
	fnDebug(DEBUG_STD,"'BSS MSG [',ITOA( LENGTH_ARRAY(Msg)),']'",dbg)
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION CHAR fnGetChecksum(CHAR pMSG[]){
	 STACK_VAR INTEGER i;
	 STACK_VAR CHAR CheckSum;
	 FOR(i = 1; i <= LENGTH_ARRAY(pMSG); i++){
		  CheckSum = CheckSum BXOR pMSG[i]
	 }
	 RETURN CheckSum
}

DEFINE_FUNCTION CHAR[255] fnEncode(CHAR pMSG[]){
	STACK_VAR INTEGER i
	FOR(i = LENGTH_ARRAY(pMSG); i > 0 ; i--){
		IF (	pMSG[i] = $02 ||
				pMSG[i] = $03 ||
				pMSG[i] = $06 ||
				pMSG[i] = $15 ||
				pMSG[i] = $1B)
		{
			pMSG = "LEFT_STRING(pMSG,i-1),$1B,($80+pMSG[i]),MID_STRING(pMSG,i+1,50)"
		}
	}
	RETURN pMSG
}

DEFINE_FUNCTION CHAR[255] fnDecode(CHAR pMSG[]){
	STACK_VAR INTEGER i
	STACK_VAR CHAR RTN[255]
	FOR(i = 1; i <= LENGTH_ARRAY(pMSG); i++){
		IF(pMSG[i] == $1B){
			RTN = "RTN,pMSG[i+1]-$80"
			i++
		}
		ELSE{
			RTN = "RTN,pMSG[i]"
		}
	}
	RETURN RTN
}

/******************************************************************************
Command Sending Helpers
******************************************************************************/
DEFINE_FUNCTION fnRecallParamPreset(INTEGER PresetID){
	fnDebug(DEBUG_DEV,'fnRecallParamPreset',"'PresetID=',ITOA(PresetID)")
	fnSendCommand("$8C,$00,$00,$00,PresetID")
}

DEFINE_FUNCTION fnSetPercent(CHAR _ADD[],INTEGER _SV, SINTEGER _Percent){
	fnDebug(DEBUG_DEV,'fnSetPercent',"'_ADD=',fnBytesToString(_ADD),':_SV=',ITOA(_SV),':_Percent=',ITOA(_Percent)")
	fnSendCommand("$8D,fnGetHiQRef(_ADD,_SV),$00,_Percent,$00,$00")
}
DEFINE_FUNCTION fnSet(CHAR _ADD[],INTEGER _SV, INTEGER Value){
	fnDebug(DEBUG_DEV,'fnSet',"'_ADD=',fnBytesToString(_ADD),':_SV=',ITOA(_SV),':Value=',ITOA(Value)")
	fnSendCommand("$88,fnGetHiQRef(_ADD,_SV),$00,$00,$00,Value")
}
DEFINE_FUNCTION fnBumpPercent(CHAR _ADD[],INTEGER _SV, SINTEGER Value){
	IF(Value < 0){
		Value = $FF + Value
		fnSendCommand("$90,fnGetHiQRef(_ADD,_SV),$FF,Value,$00,$00")
	}
	ELSE{
		fnSendCommand("$90,fnGetHiQRef(_ADD,_SV),$00,Value,$00,$00")
	}
}
DEFINE_FUNCTION fnSubscribe(CHAR _ADD[],INTEGER _SV){
	fnDebug(DEBUG_DEV,'fnSubscribe',"'_ADD=',fnBytesToString(_ADD),':_SV=',ITOA(_SV)")
	fnSendCommand("$89,fnGetHiQRef(_ADD,_SV),$00,$00,$00,$00")
}
DEFINE_FUNCTION fnSubscribePercent(CHAR _ADD[],INTEGER _SV){
	fnDebug(DEBUG_DEV,'fnSubscribePercent',"'_ADD=',fnBytesToString(_ADD),':_SV=',ITOA(_SV)")
	fnSendCommand("$8E,fnGetHiQRef(_ADD,_SV),$00,$00,$00,$00")
}

DEFINE_FUNCTION INTEGER fnItoBase255_1(INTEGER pVal){
	STACK_VAR INTEGER iRTN[2]
	RETURN (pVal % 256)
}
DEFINE_FUNCTION INTEGER fnItoBase255_2(INTEGER pVal){
	STACK_VAR INTEGER iTemp
	iTemp = TYPE_CAST(pVal % 256)
	RETURN ((pVal - iTemp) / 256)
}

DEFINE_FUNCTION CHAR[255] fnGetHiQRef(CHAR pHiQ[], INTEGER pSV){
	//fnDebug(DEBUG_DEV,'fnGetHiQRef',"'RETURN=',fnBytesToString("pHiQ,fnItoBase255_2(pSV),fnItoBase255_1(pSV)")")
	RETURN "pHiQ,fnItoBase255_2(pSV),fnItoBase255_1(pSV)"
}

DEFINE_FUNCTION fnSendCommand(CHAR Body[]){
	 STACK_VAR CHAR Msg[255]
	 Msg = Body
	 Msg = "Msg,fnGetChecksum(Msg)"
	 Msg = fnEncode(Msg)
	 fnHexDebug(Msg)
	 fnDebug(DEBUG_STD,'->BSS:',"fnBytesToString("$02,Msg,$03")")
	 SEND_STRING dvDevice,"$02,Msg,$03"
}
/******************************************************************************
	Response Processing Helpers
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	// HiQ Address of this feedback
	STACK_VAR CHAR HiQ_Address[6]
	// ParamID of this feedback
	STACK_VAR CHAR ParamID[2]
	// Message Type of this feedback
	STACK_VAR INTEGER MSG_TYPE
	// Object Indexer
	STACK_VAR INTEGER o
	// Remove last two characters (Checksum & Delim $03)
	pDATA = fnStripCharsRight(pDATA,2)
	// Remove first character (Delim $02)
	GET_BUFFER_CHAR(pDATA)
	// Debug
	//fnHardDebug(pDATA)
	MSG_TYPE = GET_BUFFER_CHAR(pDATA)
	// Get the HiQ Address
	SWITCH(MSG_TYPE){
		CASE $88:	// Set Raw
		CASE $8D:	// Set Percent
		CASE $91:{	// Set String
			HiQ_Address = GET_BUFFER_STRING(pDATA,6)
			ParamID = GET_BUFFER_STRING(pDATA,2)
		}
	}
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'HiQ_Address=',fnBytesToString(HiQ_Address),':ParamID=',fnBytesToString(ParamID)")
	// Identify this Object
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		// Match the Object
		IF(myBSS.OBJECT[o].TYPE && HiQ_Address == myBSS.OBJECT[o].HiQ_REF){
			SWITCH(myBSS.OBJECT[o].TYPE){
				CASE OBJ_TYPE_GAIN:{
					SELECT{
						// Check for Gain Percent
						ACTIVE(MSG_TYPE == $8D && ParamID[2] == myBSS.OBJECT[o].GAIN_SV):{
							//#WARN 'Why 2? This needs breaking down'
							fnDebug(DEBUG_DEV,'GAIN VALS',"ITOA(pDATA[1]),',',ITOA(pDATA[2]),',',ITOA(pDATA[3]),',',ITOA(pDATA[4])")
							myBSS.OBJECT[o].GAIN_VALUE = pDATA[2]+1
							IF(myBSS.OBJECT[o].GAIN_VALUE = 101){myBSS.OBJECT[o].GAIN_VALUE = 100}
							// Set up 255 range
							myBSS.OBJECT[o].GAIN_VALUE_255 = fnScaleRange(myBSS.OBJECT[o].GAIN_VALUE,0,100,0,255)
						}
						// Check for Mute Set
						ACTIVE(MSG_TYPE == $88 && ParamID[2] == myBSS.OBJECT[o].MUTE_SV):{
							fnDebug(DEBUG_DEV,'MUTE VALS',"ITOA(pDATA[1]),',',ITOA(pDATA[2]),',',ITOA(pDATA[3]),',',ITOA(pDATA[4])")
							myBSS.OBJECT[o].MUTE_VALUE = pDATA[4]
						}
					}
				}
				CASE OBJ_TYPE_MATRIX:{
					SELECT{
						ACTIVE(MSG_TYPE == $88):{
							STACK_VAR INTEGER y
							FOR(y = 1; y <= myBSS.OBJECT[o].BOUNDS[2]; y++){
								STACK_VAR INTEGER x
								FOR(x = 1; x <= myBSS.OBJECT[o].BOUNDS[1]; x++){
									STACK_VAR INTEGER XPOINT_pID
									IF(y == 1) {XPOINT_pID = 0} ELSE{ XPOINT_pID = (y-1) * 128 }
									XPOINT_pID = XPOINT_pID+x-1
									IF(XPOINT_pID == ParamID){
										fnDebug(DEBUG_DEV,'XPOINT VALS',"ITOA(pDATA[1]),',',ITOA(pDATA[2]),',',ITOA(pDATA[3]),',',ITOA(pDATA[4])")
										myBSS.OBJECT[o].MTX_STATE[x][y] = pDATA[4]
									}
								}
							}
						}
					}
				}
			}
		}
	}

	// Trigger comms timeline
	IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myBSS.COMMS.isIP = !(dvDEVICE.NUMBER)
	CREATE_BUFFER dvDevice, myBSS.COMMS.Rx
	myBSS.COMMS.BAUD = 115200

}
/******************************************************************************
	Real Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		// Set Baud rate if applicable
		IF(!myBSS.COMMS.isIP){
			SEND_COMMAND dvDevice,"'SET BAUD ',ITOA(myBSS.COMMS.BAUD),' N,8,1 485 DISABLE'"
		}
		// Set connection state
		myBSS.COMMS.CONN_STATE = CONN_STATE_CONNECTED

		fnInitComms()
	}
	OFFLINE:{
		myBSS.COMMS.CONN_STATE = CONN_STATE_OFFLINE
		IF(myBSS.COMMS.isIP){
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myBSS.COMMS.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
				CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
				CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
				CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
				CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
				CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
				CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
				CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
				CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
				CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
				CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
				CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
			}
			fnDebug(DEBUG_ERR,"'BSS IP Error:[',myBSS.COMMS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
			SWITCH(DATA.NUMBER){
				CASE 14:
				CASE 15:{}
				DEFAULT:{
					myBSS.COMMS.CONN_STATE = CONN_STATE_OFFLINE
					myBSS.COMMS.Tx = ''
					fnRetryConnection()
				}
			}
		}
	}
	STRING:{
		fnDebug(DEBUG_STD,'BSS->',fnBytesToString(DATA.TEXT))
		WHILE(FIND_STRING(myBSS.COMMS.Rx,"$03",1)){
			fnProcessFeedback(fnDecode(REMOVE_STRING(myBSS.COMMS.Rx,"$03",1)))
		}
	}
}
/******************************************************************************
	Main Unit Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myBSS.DEBUG = DEBUG_STD
							CASE 'DEV':	myBSS.DEBUG = DEBUG_DEV
							DEFAULT:		myBSS.DEBUG = DEBUG_ERR
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myBSS.COMMS.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myBSS.COMMS.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myBSS.COMMS.IP_HOST = DATA.TEXT
							myBSS.COMMS.IP_PORT = 1023
						}
						IF(LENGTH_ARRAY(myBSS.COMMS.IP_HOST)){
							fnRetryConnection()
						}
					}
				}
			}
			CASE 'PRESET':{
				fnRecallParamPreset(ATOI(DATA.TEXT))
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':fnInitComms()
				}
			}
		}
	}
}
/******************************************************************************
	Object Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvObjects]{
	COMMAND:{
		STACK_VAR INTEGER o
		o = GET_LAST(vdvObjects)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'TYPE':{
						SWITCH(DATA.TEXT){
							CASE 'GAIN':	myBSS.OBJECT[o].TYPE = OBJ_TYPE_GAIN
							CASE 'MATRIX':	myBSS.OBJECT[o].TYPE = OBJ_TYPE_MATRIX
							CASE 'VOIP':	myBSS.OBJECT[o].TYPE = OBJ_TYPE_VOIP
						}
						SWITCH(myBSS.OBJECT[o].TYPE){
							CASE OBJ_TYPE_GAIN:{
								// Set Defaults
								myBSS.OBJECT[o].GAIN_STEP = 2
								myBSS.OBJECT[o].GAIN_SV = 0
								myBSS.OBJECT[o].MUTE_SV = 1
								myBSS.OBJECT[o].BOUNDS[1] = 0
								myBSS.OBJECT[o].BOUNDS[2] = 100
								// Return range
								SEND_STRING DATA.DEVICE,"'RANGE-',ITOA(myBSS.OBJECT[o].BOUNDS[1]),',',ITOA(myBSS.OBJECT[o].BOUNDS[2])"
							}
						}
					}
					CASE 'ID':{
						STACK_VAR INTEGER x
						fnDebug(DEBUG_DEV,'PROPERTY-ID,',DATA.TEXT)
						myBSS.OBJECT[o].HiQ_REF = ''
						myBSS.OBJECT[o].HiQ		= LEFT_STRING(DATA.TEXT,12)
						FOR(x = 1; x <= 6; x++){
							myBSS.OBJECT[o].HiQ_REF = "myBSS.OBJECT[o].HiQ_REF,HEXTOI(GET_BUFFER_STRING(DATA.TEXT,2))"
						}
						fnDebug(DEBUG_DEV,'PROPERTY-ID,','PROCESSED')
					}
					CASE 'BOUNDS':{
						SWITCH(myBSS.OBJECT[o].TYPE){
							CASE OBJ_TYPE_MATRIX:{
								myBSS.OBJECT[o].BOUNDS[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
								myBSS.OBJECT[o].BOUNDS[2] = ATOI(DATA.TEXT)
							}
							CASE OBJ_TYPE_GAIN:{
								myBSS.OBJECT[o].BOUNDS[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
								myBSS.OBJECT[o].BOUNDS[2] = ATOI(DATA.TEXT)
								SEND_STRING DATA.DEVICE,"'RANGE-',ITOA(myBSS.OBJECT[o].BOUNDS[1]),',',ITOA(myBSS.OBJECT[o].BOUNDS[2])"
							}
						}
					}
					// For N-Gain, set index or Master. For Gain, leave to Defaults
					CASE 'INDEX':{
						IF(DATA.TEXT == 'MASTER'){
							myBSS.OBJECT[o].GAIN_SV = 96
							myBSS.OBJECT[o].MUTE_SV = 97
						}
						ELSE{
							myBSS.OBJECT[o].GAIN_SV = ATOI(DATA.TEXT)-1
							myBSS.OBJECT[o].MUTE_SV = ATOI(DATA.TEXT)-1 + 32
						}
					}
					CASE 'STEP':{
						myBSS.OBJECT[o].GAIN_STEP = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': myBSS.OBJECT[o].MUTE_VALUE = TRUE
					CASE 'OFF':myBSS.OBJECT[o].MUTE_VALUE = FALSE
					CASE 'TOG':
					CASE 'TOGGLE':myBSS.OBJECT[o].MUTE_VALUE = !myBSS.OBJECT[o].MUTE_VALUE
				}
				fnSet(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].MUTE_SV,myBSS.OBJECT[o].MUTE_VALUE)
				fnSubscribe(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].MUTE_SV)
			}
			CASE 'FADE':{
				STACK_VAR INTEGER f
				SWITCH(DATA.TEXT){
					CASE '1':f = $13
					CASE '2':f = $23
					CASE '3':f = $33
					CASE '4':f = $43
				}
				fnSet(myBSS.OBJECT[o].HiQ_REF,f,$01)
				fnSet(myBSS.OBJECT[o].HiQ_REF,f,$00)
				myBSS.OBJECT[o].FADE_ACTIVE = TRUE
				IF(TIMELINE_ACTIVE(TLID_FADES)){TIMELINE_KILL(TLID_FADES)}
				TIMELINE_CREATE(TLID_FADES,TLT_FADES,LENGTH_ARRAY(TLT_FADES),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':{
						fnBumpPercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV,myBSS.OBJECT[o].GAIN_STEP)
						fnSubscribePercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV)
					}
					CASE 'DEC':{
						fnBumpPercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV,-myBSS.OBJECT[o].GAIN_STEP)
						fnSubscribePercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV)
					}
					DEFAULT: {
						IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
							fnSetPercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV,ATOI(DATA.TEXT))
							fnSubscribePercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV)
							TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						ELSE{
							myBSS.OBJECT[o].NEW_GAIN_VALUE = ATOI(DATA.TEXT)
							myBSS.OBJECT[o].NEW_GAIN_PEND = TRUE
						}
					}
				}
				IF(myBSS.OBJECT[o].MUTE_VALUE){
					SEND_COMMAND DATA.DEVICE,'MUTE-OFF'
				}
			}
			CASE 'MATRIX':{
				STACK_VAR INTEGER _IN
				_IN = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				fnSet(myBSS.OBJECT[o].HiQ_REF,ATOI(DATA.TEXT)-1,_IN)
			}
			CASE 'INPUT':{
				fnSet(myBSS.OBJECT[o].HiQ_REF,0,ATOI(DATA.TEXT))
			}
			CASE 'XPOINT':{
				STACK_VAR INTEGER x
				STACK_VAR INTEGER y
				STACK_VAR INTEGER pMTX_XPOINT_pID
				STACK_VAR INTEGER _bActive
				x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				y = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				// Action
				SWITCH(DATA.TEXT){
					CASE 'ON':		myBSS.OBJECT[o].MTX_STATE[x][y] = TRUE
					CASE 'OFF':		myBSS.OBJECT[o].MTX_STATE[x][y] = FALSE
					CASE 'TOGGLE':	myBSS.OBJECT[o].MTX_STATE[x][y] = !myBSS.OBJECT[o].MTX_STATE[x][y]
				}
				// Get BSS References

				IF(y == 1) {pMTX_XPOINT_pID = 0} ELSE{ pMTX_XPOINT_pID = (y-1) * 128 }
				pMTX_XPOINT_pID = pMTX_XPOINT_pID+x-1
				fnSet(myBSS.OBJECT[o].HiQ_REF,pMTX_XPOINT_pID,myBSS.OBJECT[o].MTX_STATE[x][y])
			}
		}
	}
}
/******************************************************************************
	Audio Handling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_FADES]{
	STACK_VAR INTEGER o;
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		IF(myBSS.OBJECT[o].FADE_ACTIVE){
			fnSet(myBSS.OBJECT[o].HiQ_REF,$04,$01)
			fnSet(myBSS.OBJECT[o].HiQ_REF,$04,$00)
			myBSS.OBJECT[o].FADE_ACTIVE = FALSE;
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
TIMELINE_EVENT[TLID_VOL_40]{
	STACK_VAR INTEGER o
	o = TIMELINE.ID - TLID_VOL_00
	IF(myBSS.OBJECT[o].NEW_GAIN_PEND){
		fnSetPercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV,myBSS.OBJECT[o].NEW_GAIN_VALUE)
		fnSubscribePercent(myBSS.OBJECT[o].HiQ_REF,myBSS.OBJECT[o].GAIN_SV)
		myBSS.OBJECT[o].NEW_GAIN_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER o
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		SWITCH(myBSS.OBJECT[o].TYPE){
			CASE OBJ_TYPE_GAIN:{
				SEND_LEVEL vdvObjects[o],1,myBSS.OBJECT[o].GAIN_VALUE
				SEND_LEVEL vdvObjects[o],3,myBSS.OBJECT[o].GAIN_VALUE_255
				[vdvObjects[o],199] = ( myBSS.OBJECT[o].MUTE_VALUE )
			}
			CASE OBJ_TYPE_MATRIX:{
				STACK_VAR INTEGER y
				FOR(y = 1; y <= myBSS.OBJECT[o].BOUNDS[2]; y++){
					STACK_VAR INTEGER x
					FOR(x = 1; x <= myBSS.OBJECT[o].BOUNDS[1] ; x++){
						[vdvObjects[o],((y*16)-16)+x] = myBSS.OBJECT[o].MTX_STATE[x][y]
					}
				}
			}
		}
	}
	// Comms Status
	[vdvControl,251] = (myBSS.COMMS.CONN_STATE == CONN_STATE_CONNECTED)
	[vdvControl,252] = (myBSS.COMMS.CONN_STATE == CONN_STATE_CONNECTED)
}
DEFINE_EVENT CHANNEL_EVENT[vdvObjects,199]{
	ON:{}
	OFF:{}
}
/******************************************************************************
	EoF
******************************************************************************/