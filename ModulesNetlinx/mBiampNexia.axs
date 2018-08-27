MODULE_NAME='mBiampNexia'(DEV vdvControl,DEV vdvObjects[], DEV dvBiAmp)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module based on Tesira code for Nexia
******************************************************************************/

/******************************************************************************
	Structures for Object Data
******************************************************************************/
DEFINE_CONSTANT
INTEGER _MAX_OBJECTS    = 30

INTEGER OBJ_FADER			= 01
INTEGER OBJ_OUTPUT		= 02
INTEGER OBJ_MUTE			= 03
INTEGER OBJ_MATRIX_STD	= 04
INTEGER OBJ_MATRIX_MIX	= 05
INTEGER OBJ_IO_VOIP		= 06
INTEGER OBJ_IO_POTS		= 07
INTEGER OBJ_ROUTER		= 08
INTEGER OBJ_INPUT			= 09
INTEGER OBJ_AECINPUT		= 10

INTEGER LVL_VOL_RAW = 1
INTEGER LVL_VOL_100 = 2
INTEGER LVL_VOL_255 = 3

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_NEGOTIATING	= 2
INTEGER IP_STATE_CONNECTED		= 3

INTEGER DEBUG_ERR			= 0
INTEGER DEBUG_STD			= 1
INTEGER DEBUG_DEV			= 2

INTEGER STATE_MUTE		= 1
INTEGER STATE_HOOK		= 2
INTEGER STATE_MICMUTE	= 3

DEFINE_TYPE STRUCTURE uObject{
	// Comms & ID
	CHAR 		DEVID[2]
	CHAR 		INSTID[3][32]
	INTEGER  INDEX
	INTEGER 	TYPE
	// Object Values
	INTEGER 	STEP
	SINTEGER VALUE[32]
	INTEGER 	STATE[32]
	INTEGER 	STRINGS[5][15]

	INTEGER 	VOL_PEND
	CHAR 		LAST_VOL[10]
}
DEFINE_TYPE STRUCTURE uBiAmp{
	CHAR 		Rx[1000]
	CHAR 		TX[2000]
	CHAR 		BAUD[6]
	INTEGER 	DEBUG
	CHAR 		META_IP_HOST[20]
	INTEGER 	isIP
	CHAR		IP_HOST[50]
	INTEGER 	IP_PORT
	INTEGER  IP_STATE

	uObject OBJECT[_MAX_OBJECTS]
}

/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER DEF_VOL_STEP = 3
/******************************************************************************
	Feedback Channels
******************************************************************************/
INTEGER chnOFFHOOK 	= 238
INTEGER chnRINGING	= 240
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uBiAmp	myBiAmp
/******************************************************************************
	Timeline Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_RETRY 			= 1
LONG TLID_HOOK_Q_DELAY 	= 2
LONG TLID_POLL				= 3
LONG TLID_COMMS			= 4

LONG TLID_VOL_00				= 100
LONG TLID_VOL_01				= 101
LONG TLID_VOL_02				= 102
LONG TLID_VOL_03				= 103
LONG TLID_VOL_04				= 104
LONG TLID_VOL_05				= 105
LONG TLID_VOL_06				= 106
LONG TLID_VOL_07				= 107
LONG TLID_VOL_08				= 108
LONG TLID_VOL_09				= 109
LONG TLID_VOL_10				= 110
LONG TLID_VOL_11				= 111
LONG TLID_VOL_12				= 112
LONG TLID_VOL_13				= 113
LONG TLID_VOL_14				= 114
LONG TLID_VOL_15				= 115
LONG TLID_VOL_16				= 116
LONG TLID_VOL_17				= 117
LONG TLID_VOL_18				= 118
LONG TLID_VOL_19				= 119
LONG TLID_VOL_20				= 120
LONG TLID_VOL_21				= 121
LONG TLID_VOL_22				= 122
LONG TLID_VOL_23				= 123
LONG TLID_VOL_24				= 124
LONG TLID_VOL_25				= 125
LONG TLID_VOL_26				= 126
LONG TLID_VOL_27				= 127
LONG TLID_VOL_28				= 128
LONG TLID_VOL_29				= 129
LONG TLID_VOL_30				= 130

/******************************************************************************
	Timeline Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_RETRY[]			= { 5000}
LONG TLT_HOOK_Q_DELAY[] = {500}
LONG TLT_POLL[]			= {45000}
LONG TLT_COMMS[]			= {90000}
LONG TLT_VOL[]	  			= {  200}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myBiAmp.isIP = !(dvBiAmp.NUMBER)
	CREATE_BUFFER dvBiAmp, myBiAmp.Rx
	myBiAmp.BAUD = '38400'		// Default Baud Rate
	myBiAmp.IP_PORT = 23			// Default IP Port (Telnet)
}

/******************************************************************************
	Command Sending Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR cCMD[]){
	fnDebug(DEBUG_STD,'->BiAmp',cCMD)
	SEND_STRING dvBiAmp,"cCMD,$0A"
	fnInitPoll()
}
DEFINE_FUNCTION fnSendQuery(CHAR cCMD[]){
	fnDebug(DEBUG_STD,'->BiAmp',cCMD)
	SEND_STRING dvBiAmp,"cCMD,$0A"
}

DEFINE_FUNCTION fnBuildCommand(CHAR _cmd[5],CHAR _DevID[5],CHAR _att[25],CHAR _instID[5],CHAR _index1[5],CHAR _index2[5], CHAR _val[255]){
	STACK_VAR CHAR _SendCmd[255]
	IF(_cmd != '')		_SendCmd = "_SendCmd,_cmd,' '"
	IF(_DevID != '') 	_SendCmd = "_SendCmd,_DevID,' '"
	IF(_att != '') 	_SendCmd = "_SendCmd,_att,' '"
	IF(_instID != '') _SendCmd = "_SendCmd,_instID,' '"
	IF(_index1 != '') _SendCmd = "_SendCmd,_index1,' '"
	IF(_index2 != '') _SendCmd = "_SendCmd,_index2,' '"
	IF(_val != '') 	_SendCmd = "_SendCmd,_val"
	IF(RIGHT_STRING(_SendCmd,1) == ' '){
		_SendCmd = fnStripCharsRight(_SendCmd,1)
	}
	fnSendCommand(_SendCmd)
}
/******************************************************************************
	Polling Functions
******************************************************************************/
DEFINE_FUNCTION fnInit(){
	STACK_VAR INTEGER o
	FOR(o = 1; o <= _MAX_OBJECTS; o++){
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_FADER:{
				IF(!myBiAmp.OBJECT[o].INDEX){myBiAmp.OBJECT[o].INDEX = 1}
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'FDRLVL',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'FDRMUTE',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
			}
			CASE OBJ_IO_POTS:{
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'TIHOOKSTATE',myBiAmp.OBJECT[o].INSTID[1],'','','')
				IF(LENGTH_ARRAY(myBiAmp.OBJECT[o].INSTID[2])){
					fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'TITXMUTE',myBiAmp.OBJECT[o].INSTID[2],'','','1')
				}
				IF(LENGTH_ARRAY(myBiAmp.OBJECT[o].INSTID[3])){
					fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'TIRXMUTE',myBiAmp.OBJECT[o].INSTID[3],'','','1')
				}
			}
			CASE OBJ_OUTPUT:{
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'OUTMUTE',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
			}
			CASE OBJ_MUTE:{
				IF(!myBiAmp.OBJECT[o].INDEX){myBiAmp.OBJECT[o].INDEX = 1}
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'MBMUTE',myBiAmp.OBJECT[o].INSTID[1],'1','','')
			}
			CASE OBJ_MATRIX_MIX:
			CASE OBJ_MATRIX_STD:{
				fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,'SMLVLIN',myBiAmp.OBJECT[o].INSTID[1],'1','','')
			}
		}
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendQuery('GETD 0 IPADDR')
}

/******************************************************************************
	Feedback Processing Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	fnDebug(DEBUG_DEV, 'fnProcessFeedback',"'pDATA=',pDATA")
	fnDebug(DEBUG_STD, 'BiAMP->',"pDATA")
	SELECT{
		ACTIVE(pDATA[1] == '+'):{
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		ACTIVE(FIND_STRING(pDATA,'-ERR',1)):{
			fnDebug(DEBUG_ERR,'ERROR',pDATA)
		}
		ACTIVE(FIND_STRING(pData,'Biamp Telnet',1)):{
			myBiAmp.IP_STATE = IP_STATE_CONNECTED
			WAIT 10{
				SEND_STRING dvBiAmp,"$FF,$FE,$01"
				fnPoll()
				fnInitPoll()
			}
		}
		ACTIVE(pDATA[1] == '#'):{
			STACK_VAR CHAR 	_Cmd[10]
			STACK_VAR CHAR 	_DevID[2]
			STACK_VAR CHAR 	_Attrib[15]
			STACK_VAR CHAR 	_InstID[32]
			STACK_VAR CHAR    _Index1[50]
			STACK_VAR CHAR    _Index2[50]
			STACK_VAR CHAR 	_Value[50]

			_Cmd 		= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			_DevID 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			_Attrib 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

			IF(_Attrib == 'IPADDR'){
				IF(myBiAmp.META_IP_HOST != pData){
					myBiAmp.META_IP_HOST = pData
					fnInit()
				}
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				RETURN
			}

			_InstID 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

			_Index1 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)

			IF(RIGHT_STRING(pDATA,1) == ' '){ pDATA = fnStripCharsRight(pDATA,1) }

			IF(FIND_STRING(pDATA,' ',1)){
				_Index2 	= fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
			}

			_Value 	= pDATA

			fnDebug(DEBUG_DEV,'FB',"'1:',_Cmd,'|2:',_DevID,'|3:',_Attrib,'|4:',_InstID,'|5:',_Index1,'|6:',_Index2,'|7:',_Value")
			IF(1){
				STACK_VAR INTEGER o
				FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
					IF(myBiAmp.OBJECT[o].DEVID == _DevID && (myBiAmp.OBJECT[o].INSTID[1] == _InstID || myBiAmp.OBJECT[o].INSTID[2] == _InstID || myBiAmp.OBJECT[o].INSTID[3] == _InstID) && myBiAmp.OBJECT[o].INDEX == ATOI(_Index1) ){
						fnDebug(DEBUG_DEV,'Matched',ITOA(o))
						SWITCH(_Attrib){
							CASE 'OUTLVL':
							CASE 'FDRLVL':
							CASE 'SMLVLIN':{
								IF(_Value == '+OK'){
									myBiAmp.OBJECT[o].VALUE[LVL_VOL_RAW] = ATOI(_Index2)
									SEND_STRING vdvObjects[o], "'FADER-',ITOA(ATOI(_Index2))"
									SEND_STRING vdvObjects[o], "'RAWFADER-',_Index2"
								}
								ELSE{
									myBiAmp.OBJECT[o].VALUE[LVL_VOL_RAW] = ATOI(_Value)
									SEND_STRING vdvObjects[o], "'FADER-',ITOA(ATOI(_Value))"
									SEND_STRING vdvObjects[o], "'RAWFADER-',_Value"
								}
							}
							CASE 'FDRMUTE':
							CASE 'AECINPMUTE':
							CASE 'INPMUTE':
							CASE 'OUTMUTE':
							CASE 'MBMUTE':
							CASE 'SMMUTEIN':
							CASE 'MMMUTEIN':
							CASE 'TITXMUTE':{
								myBiAmp.OBJECT[o].STATE[STATE_MUTE] = ATOI(_Index2)
							}
							CASE 'TIHOOKSTATE':
							CASE 'VOIPHOOKSTATE':{
								myBiAmp.OBJECT[o].STATE[STATE_HOOK] = ATOI(_Value)
							}
						}
					}
				}
			}
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	fnDebug(DEBUG_DEV, 'fnProcessFeedback',"'Ended'")
}

/******************************************************************************
	Debugging Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myBiAmp.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myBiAmp.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Biamp Address Not Set','')
	}
	ELSE{
		fnDebug(DEBUG_STD,"'Connecting to Biamp Port ',ITOA(myBiAmp.IP_PORT),' on '",myBiAmp.IP_HOST)
		myBiAmp.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvBiamp.port, myBiAmp.IP_HOST, myBiAmp.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvBiamp.port)
}
DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvBiAmp]{
	ONLINE:{
		IF(myBiAmp.isIP){
			(** Ethernet Communications **)
			myBiAmp.IP_STATE = IP_STATE_NEGOTIATING;
		}
		ELSE{
			SEND_COMMAND dvBiAmp, "'SET BAUD ',myBiAmp.BAUD,' N 8 1 485 DISABLE'"
			myBiAmp.IP_STATE = IP_STATE_CONNECTED
			WAIT 50{
				fnPoll()
				fnInitPoll()
			}
		}
	}
	STRING:{
		//fnDebug(DEBUG_DEV,'RAW->',DATA.TEXT)
		// Telnet Negotiation
		WHILE(myBiAmp.Rx[1] == $FF && LENGTH_ARRAY(myBiAmp.Rx) >= 3){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myBiAmp.Rx,3)
			fnDebug(DEBUG_STD,'BiAmp.Telnet->',NEG_PACKET)
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(DEBUG_STD,'->BiAmp.Telnet',NEG_PACKET)
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}

		WHILE(FIND_STRING(myBiAmp.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myBiAmp.Rx,"$0D,$0A",1),2))
		}
	}
	OFFLINE:{
		(** Ethernet Communications **)
		IF(myBiAmp.isIP){
			myBiAmp.IP_STATE = IP_STATE_OFFLINE
			myBiAmp.TX = ''
			myBiAmp.Rx = ''
			fnTryConnection()
		}
	}
	ONERROR:{
		(** Ethernet Communications **)
		IF(myBiAmp.isIP){
			STACK_VAR CHAR MSG[50]
			SWITCH(DATA.NUMBER){
				CASE 2:{  MSG = 'General Failure'}					//  General Failure - Out Of Memory
				CASE 4:{  MSG = 'Unknown Host'}						//  Unknown Host
				CASE 6:{  MSG = 'Conn Refused'}						//  Connection Refused
				CASE 7:{  MSG = 'Conn Timed Out'}					//  Connection Timed Out
				CASE 8:{  MSG = 'Unknown'}								//  Unknown Connection Error
				CASE 9:{  MSG = 'Already Closed'}					//  Already Closed
				CASE 10:{ MSG = 'Binding Error'} 					//  Binding Error
				CASE 11:{ MSG = 'Listening Error'} 					//  Listening Error
				CASE 14:{ MSG = 'Local Port Already Used'}		//  Local Port Already Used
				CASE 15:{ MSG = 'UDP Socket Already Listening'} //  UDP socket already listening
				CASE 16:{ MSG = 'Too many open Sockets'}			//  Too many open sockets
				CASE 17:{ MSG = 'Local port not Open'}				//  Local Port Not Open
			}
			fnDebug(DEBUG_ERR,"'IP Error:[',myBiAmp.IP_HOST,':',ITOA(myBiAmp.IP_PORT),']'","'[',ITOA(DATA.NUMBER),MSG,']'")
			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myBiAmp.IP_STATE = IP_STATE_OFFLINE
					fnTryConnection();
				}
			}
		}
	}
}

/******************************************************************************
	Module Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						IF(!myBiAmp.isIP){
							myBiAmp.BAUD = DATA.TEXT
							SEND_COMMAND dvBiAmp, "'SET BAUD ',myBiAmp.BAUD,' N 8 1 485 DISABLE'"
						}
					}
					CASE 'IP':{
						myBiAmp.IP_HOST = DATA.TEXT
						IF(myBiAmp.isIP){
							ip_client_open(dvBiAmp.port, myBiAmp.IP_HOST, 23, IP_TCP)
						}
					}

					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV': myBiAmp.DEBUG = DEBUG_DEV
							CASE 'TRUE':myBiAmp.DEBUG = DEBUG_STD
							DEFAULT:    myBiAmp.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'PRESET':{
				fnSendCommand("'RECALL 0 PRESET ',DATA.TEXT");
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
		fnDebug(DEBUG_DEV, 'DATA_EVENT:COMMAND',"'vdvObject[',ITOA(o),'] DATA.TEXT[',DATA.TEXT,']'")
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':{
						STACK_VAR INTEGER x
						myBiAmp.OBJECT[o].DEVID = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						x = 1
						WHILE(FIND_STRING(DATA.TEXT,',',1)){
							myBiAmp.OBJECT[o].INSTID[x] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
							x++
						}
						myBiAmp.OBJECT[o].INSTID[x] = DATA.TEXT
					}
					CASE 'INDEX': myBiAmp.OBJECT[o].INDEX = ATOI(DATA.TEXT)
					CASE 'TYPE':{
						SWITCH(DATA.TEXT){
							CASE 'CONTROL_LEVEL':myBiAmp.OBJECT[o].TYPE = OBJ_FADER
							CASE 'CONTROL_MUTE':	myBiAmp.OBJECT[o].TYPE = OBJ_MUTE
							CASE 'MATRIX_MIX':	myBiAmp.OBJECT[o].TYPE = OBJ_MATRIX_MIX
							CASE 'MATRIX_STD':	myBiAmp.OBJECT[o].TYPE = OBJ_MATRIX_STD
							CASE 'OUTPUT':			myBiAmp.OBJECT[o].TYPE = OBJ_OUTPUT
							CASE 'INPUT':			myBiAmp.OBJECT[o].TYPE = OBJ_INPUT
							CASE 'AECINPUT':		myBiAmp.OBJECT[o].TYPE = OBJ_AECINPUT
							CASE 'IO_POTS':		myBiAmp.OBJECT[o].TYPE = OBJ_IO_POTS
							CASE 'IO_VOIP':		myBiAmp.OBJECT[o].TYPE = OBJ_IO_VOIP
							CASE 'ROUTER':			myBiAmp.OBJECT[o].TYPE = OBJ_ROUTER
						}
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_FADER:
							CASE OBJ_MUTE:
							CASE OBJ_IO_VOIP:IF(myBiAmp.OBJECT[o].INDEX = ''){ myBiAmp.OBJECT[o].INDEX = '1' }
						}
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_FADER:IF(myBiAmp.OBJECT[o].STEP = 0){ myBiAmp.OBJECT[o].STEP = 3 }
						}
					}
				}
			}
			CASE 'XP':{
				STACK_VAR CHAR _IN[2]
				STACK_VAR CHAR _OUT[2]
				_IN =  fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				_OUT = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
				SWITCH(myBiAmp.OBJECT[o].TYPE){
					CASE OBJ_MATRIX_MIX:{
						SWITCH(DATA.TEXT){
							CASE 'ON': fnBuildCommand('SET',myBiAmp.OBJECT[o].DEVID,'MMMUTEXP',myBiAmp.OBJECT[o].INSTID[1],_IN,_OUT,'1')
							CASE 'OFF':fnBuildCommand('SET',myBiAmp.OBJECT[o].DEVID,'MMMUTEXP',myBiAmp.OBJECT[o].INSTID[1],_IN,_OUT,'0')
							CASE '1':  fnBuildCommand('SET',myBiAmp.OBJECT[o].DEVID,'MMMUTEXP',myBiAmp.OBJECT[o].INSTID[1],_IN,_OUT,'1')
							CASE '0':  fnBuildCommand('SET',myBiAmp.OBJECT[o].DEVID,'MMMUTEXP',myBiAmp.OBJECT[o].INSTID[1],_IN,_OUT,'0')
						}
					}
				}
			}
			CASE 'MUTE':
			CASE 'MICMUTE':{
				SWITCH(myBiAmp.OBJECT[o].TYPE){
					CASE OBJ_FADER:
					CASE OBJ_MUTE:
					CASE OBJ_OUTPUT:
					CASE OBJ_INPUT:
					CASE OBJ_AECINPUT:
					CASE OBJ_IO_POTS:
					CASE OBJ_IO_VOIP:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	myBiAmp.OBJECT[o].STATE[STATE_MUTE] = TRUE
							CASE 'OFF':
							CASE 'FALSE':	myBiAmp.OBJECT[o].STATE[STATE_MUTE] = FALSE
							CASE 'TOGGLE':	myBiAmp.OBJECT[o].STATE[STATE_MUTE] = !myBiAmp.OBJECT[o].STATE[STATE_MUTE]
						}
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_MUTE:		fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'MBMUTE',  myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
							CASE OBJ_FADER:	fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'FDRMUTE', myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
							CASE OBJ_OUTPUT:	fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'OUTMUTE', myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
							CASE OBJ_INPUT:	fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'INPMUTE', myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
							CASE OBJ_AECINPUT:fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'AECINPMUTE', myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
							CASE OBJ_IO_POTS:	fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,	'TITXMUTE',myBiAmp.OBJECT[o].INSTID[1],'',					 '',ITOA(myBiAmp.OBJECT[o].STATE[STATE_MUTE]))
						}
					}
				}
			}
			CASE 'VOLUME':{
				SWITCH(myBiAmp.OBJECT[o].TYPE){
					CASE OBJ_FADER:
					CASE OBJ_OUTPUT:{
						STACK_VAR CHAR CMD[10]
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_FADER:	CMD = 'FDRLVL'
							CASE OBJ_OUTPUT:	CMD = 'OUTLVL'
						}
						SWITCH(DATA.TEXT){
							CASE 'INC':{
								fnBuildCommand('INC', myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STEP))
								fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
							}
							CASE 'DEC':{
								fnBuildCommand('DEC', myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',ITOA(myBiAmp.OBJECT[o].STEP))
								fnBuildCommand('GETD',myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
							}
							DEFAULT:{
								IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
									fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',DATA.TEXT)
									TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									myBiAmp.OBJECT[o].LAST_VOL = DATA.TEXT
									myBiAmp.OBJECT[o].VOL_PEND = TRUE
								}
							}
						}
					}
				}
			}
			CASE 'DIAL':{
				SWITCH(DATA.TEXT){
					CASE 'ANSWER':{
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_IO_POTS:fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,'TIHOOKSTATE',myBiAmp.OBJECT[o].INSTID[1],'','','0')
							CASE OBJ_IO_VOIP:fnBuildCommand('ANS',myBiAmp.OBJECT[o].DEVID,'VOIPCALL',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
						}
						myBiAmp.OBJECT[o].STATE[STATE_HOOK] = TRUE
					}
					CASE 'HANGUP':{
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_IO_POTS:fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,'TIHOOKSTATE',myBiAmp.OBJECT[o].INSTID[1],'','','1')
							CASE OBJ_IO_VOIP:fnBuildCommand('END',myBiAmp.OBJECT[o].DEVID,'VOIPCALL',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','')
						}
						myBiAmp.OBJECT[o].STATE[STATE_HOOK] = TRUE
					}
					DEFAULT:{
						SWITCH(myBiAmp.OBJECT[o].TYPE){
							CASE OBJ_IO_POTS:fnBuildCommand('DIAL',myBiAmp.OBJECT[o].DEVID,'TIPHONENUM',myBiAmp.OBJECT[o].INSTID[1],'','',DATA.TEXT)
							CASE OBJ_IO_VOIP:fnBuildCommand('DIAL',myBiAmp.OBJECT[o].DEVID,'VOIPPHONENUM',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',DATA.TEXT)
						}
						myBiAmp.OBJECT[o].STATE[STATE_HOOK] = FALSE
					}
				}
			}
			CASE 'DTMF':{
				SWITCH(myBiAmp.OBJECT[o].TYPE){
					CASE OBJ_IO_POTS:fnBuildCommand('DIAL',myBiAmp.OBJECT[o].DEVID,'TIPHONENUM',myBiAmp.OBJECT[o].INSTID[1],'','','#')
					CASE OBJ_IO_VOIP:fnBuildCommand('DIAL',myBiAmp.OBJECT[o].DEVID,'VOIPPHONENUM',myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'','#')
				}
			}
		}
		fnDebug(DEBUG_DEV, 'DATA_EVENT:COMMAND',"'Ended'")
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
	STACK_VAR INTEGER o
	o = TIMELINE.ID - TLID_VOL_00
	IF(myBiAmp.OBJECT[o].VOL_PEND){
		STACK_VAR CHAR CMD[10]
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_FADER:	CMD = 'FDRLVL'
			CASE OBJ_OUTPUT:	CMD = 'OUTLVL'
		}
		fnBuildCommand('SETD',myBiAmp.OBJECT[o].DEVID,CMD,myBiAmp.OBJECT[o].INSTID[1],ITOA(myBiAmp.OBJECT[o].INDEX),'',myBiAmp.OBJECT[o].LAST_VOL)
		myBiAmp.OBJECT[o].VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Device Feedback
******************************************************************************/
/******************************************************************************
	Channel Feedback Control
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER o
	FOR(o=1; o<=LENGTH_ARRAY(vdvObjects); o++){

		// Mute Feedback
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_FADER:
			CASE OBJ_MUTE:
			CASE OBJ_OUTPUT:
			CASE OBJ_IO_POTS:
			CASE OBJ_IO_VOIP:{
				[vdvObjects[o],199] = myBiAmp.OBJECT[o].STATE[STATE_MUTE]
			}
		}
		// MicMute Feedback
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_FADER:
			CASE OBJ_MUTE:
			CASE OBJ_OUTPUT:
			CASE OBJ_IO_POTS:
			CASE OBJ_IO_VOIP:{
				[vdvObjects[o],198] = myBiAmp.OBJECT[o].STATE[STATE_MICMUTE]
			}
		}

		// Level Feedback
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_FADER:
			CASE OBJ_OUTPUT:{
				SEND_LEVEL vdvObjects[o],1,myBiAmp.OBJECT[o].VALUE[LVL_VOL_RAW]
			}
		}

		// Hook State Feedback
		SWITCH(myBiAmp.OBJECT[o].TYPE){
			CASE OBJ_IO_POTS:
			CASE OBJ_IO_VOIP:{
				[vdvObjects[o],chnOFFHOOK] = !myBiAmp.OBJECT[o].STATE[STATE_HOOK]
			}
		}
	}
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}

/******************************************************************************
	EoF
******************************************************************************/