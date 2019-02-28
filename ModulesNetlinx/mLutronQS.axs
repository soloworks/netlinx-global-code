MODULE_NAME='mLutronQS'(DEV vdvControl[], DEV dvLutron)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Lutron QS Protocol Module

******************************************************************************/

/******************************************************************************
	Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER _MAX_GROUPS = 24

DEFINE_TYPE STRUCTURE uGroup{
	INTEGER  ID
	INTEGER  STATE
}

DEFINE_TYPE STRUCTURE uDevice{
	// Integration Data
	CHAR 		INTEGRATIONID[20]
	CHAR 		SERIAL_NUMBER[20]
	CHAR		ID[20]
	INTEGER	TYPE
	// State Data
	INTEGER 	VALUE_INT
	FLOAT 	VALUE_FLOAT
	INTEGER	LED[20]
	INTEGER	BTN[20]
	INTEGER  AREA
	uGroup   GROUP[_MAX_GROUPS]
}

DEFINE_TYPE STRUCTURE uLutronQS{
	// Communications
	CHAR 		TX[2000]				// Receieve Buffer
	CHAR 		RX[2000]				// Receieve Buffer
	INTEGER 	IP_PORT				//
	CHAR		IP_HOST[255]		//
	INTEGER 	IP_STATE				//
	INTEGER	isIP					//
	CHAR     USERNAME[20]
	CHAR     PASSWORD[20]
	INTEGER  LOGIN_ATTEMPT
	INTEGER 	DEBUG					// Debuging ON/OFF
	CHAR		BAUD[10]
	INTEGER	USE_SN_AS_ID
	// State
	uDevice 	DEVICE[50]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL	 	= 1
LONG TLID_RETRY	= 2
LONG TLID_BOOT    = 3
LONG TLID_TIMEOUT = 4

LONG TLID_COMMS_00 	= 100
LONG TLID_COMMS_01 	= 101
LONG TLID_COMMS_02 	= 102
LONG TLID_COMMS_03 	= 103
LONG TLID_COMMS_04 	= 104
LONG TLID_COMMS_05 	= 105
LONG TLID_COMMS_06 	= 106
LONG TLID_COMMS_07 	= 107
LONG TLID_COMMS_08 	= 108
LONG TLID_COMMS_09 	= 109
LONG TLID_COMMS_10 	= 110
LONG TLID_COMMS_11 	= 111
LONG TLID_COMMS_12 	= 112
LONG TLID_COMMS_13 	= 113
LONG TLID_COMMS_14 	= 114
LONG TLID_COMMS_15 	= 115
LONG TLID_COMMS_16 	= 116
LONG TLID_COMMS_17 	= 117
LONG TLID_COMMS_18 	= 118
LONG TLID_COMMS_19 	= 119
LONG TLID_COMMS_20 	= 120
LONG TLID_COMMS_21 	= 121
LONG TLID_COMMS_22 	= 122
LONG TLID_COMMS_23 	= 123
LONG TLID_COMMS_24 	= 124
LONG TLID_COMMS_25 	= 125
LONG TLID_COMMS_26 	= 126
LONG TLID_COMMS_27 	= 127
LONG TLID_COMMS_28 	= 128
LONG TLID_COMMS_29 	= 129
LONG TLID_COMMS_30 	= 130
LONG TLID_COMMS_31 	= 131
LONG TLID_COMMS_32 	= 132
LONG TLID_COMMS_33 	= 133
LONG TLID_COMMS_34 	= 134
LONG TLID_COMMS_35 	= 135
LONG TLID_COMMS_36 	= 136
LONG TLID_COMMS_37 	= 137
LONG TLID_COMMS_38 	= 138
LONG TLID_COMMS_39 	= 139
LONG TLID_COMMS_40 	= 140
LONG TLID_COMMS_41 	= 141
LONG TLID_COMMS_42 	= 142
LONG TLID_COMMS_43 	= 143
LONG TLID_COMMS_44 	= 144
LONG TLID_COMMS_45 	= 145
LONG TLID_COMMS_46 	= 146
LONG TLID_COMMS_47 	= 147
LONG TLID_COMMS_48 	= 148
LONG TLID_COMMS_49 	= 149
LONG TLID_COMMS_50 	= 150
// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_SECURITY		= 2
INTEGER IP_STATE_CONNECTED		= 3
// Debug Constants
INTEGER DEBUG_ERR			= 0
INTEGER DEBUG_STD			= 1
INTEGER DEBUG_DEV			= 2
// Types of Device
INTEGER TYPE_TIMECLOCK	= 1
INTEGER TYPE_DEVICE		= 2
INTEGER TYPE_OUTPUT		= 3
INTEGER TYPE_GROUPS		= 4
INTEGER TYPE_AREA			= 5
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] 	= { 90000 }
LONG TLT_POLL[]  	= { 15000 }
LONG TLT_RETRY[]	= {  5000 }
LONG TLT_BOOT[]   = { 5000 }
LONG TLT_TIMEOUT[]= { 2000 }

VOLATILE uLutronQS myLutronQS
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	myLutronQS.isIP = !(dvLutron.NUMBER)
	CREATE_BUFFER dvLutron, myLutronQS.RX
}
/******************************************************************************
	IP Connection Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myLutronQS.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'ERROR','LutronQS IP Not Set')
	}
	ELSE{
		fnDebug(DEBUG_STD,'Connecting to LutronQS on ',"myLutronQS.IP_HOST,':',ITOA(myLutronQS.IP_PORT)")
		myLutronQS.IP_STATE = IP_STATE_CONNECTING
		ip_client_open(dvLutron.port, myLutronQS.IP_HOST, myLutronQS.IP_PORT, IP_TCP)
	}
}
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvLutron.port)
}
DEFINE_FUNCTION fnRetryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR Msg[], CHAR MsgData[]){
	 IF(pDEBUG <= myLutronQS.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl[1].Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnSendAreaCommand(CHAR pID[10], INTEGER pAction, CHAR _param[]){
	STACK_VAR CHAR cmd[100]
	cmd = "'#AREA,',pID,',',ITOA(pAction),',',_param"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendAreaQuery(INTEGER pID, INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?AREA,',ITOA(pID),',',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendDeviceCommand(CHAR pID[10], INTEGER pNumber, INTEGER pAction, CHAR _param[]){
	STACK_VAR CHAR cmd[100]
	cmd = "'#DEVICE,',pID,',',ITOA(pNumber),',',ITOA(pAction)"
	IF(_param <> ''){cmd = "cmd,',',_PARAM"}
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendDeviceQuery(CHAR pID[10], INTEGER pNumber, INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?DEVICE,',pID,',',ITOA(pNumber),',',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendOutputCommand(CHAR pID[10], INTEGER pAction, CHAR _param[]){
	STACK_VAR CHAR cmd[100]
	cmd = "'#OUTPUT,',pID,',',ITOA(pAction)"
	IF(_param <> ''){cmd = "cmd,',',_PARAM"}
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendTimeclockQuery(CHAR pID[10], INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?TIMECLOCK,',pID,',',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendIntegrationIDQuery(CHAR pID[10], INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?INTEGRATIONID,',ITOA(pAction),',',pID"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendGroupQuery(INTEGER pID, INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?GROUP,',ITOA(pID),',',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendSystemQuery(INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?SYSTEM,',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnSendEthernetQuery(INTEGER pAction){
	STACK_VAR CHAR cmd[100]
	cmd = "'?ETHERNET,',ITOA(pAction)"
	fnAddToQueue(cmd)
}
DEFINE_FUNCTION fnAddToQueue(CHAR pToSend[255]){
	myLutronQS.Tx = "myLutronQS.Tx,pToSend,$0D,$0A"
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myLutronQS.IP_STATE == IP_STATE_CONNECTED && FIND_STRING(myLutronQS.Tx,"$0D,$0A",1)){
		STACK_VAR CHAR pToSend[255]
		pToSend = REMOVE_STRING(myLutronQS.Tx,"$0D,$0A",1)
		fnDebug(DEBUG_STD,'->QS',pToSend)
		SEND_STRING dvLutron,pToSend
		fnInitPoll()
	}
}
/******************************************************************************
	Protocol Helpers
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug(DEBUG_DEV,'fnProcessFeedback',pDATA)
	fnDebug(DEBUG_STD,'QS->',pDATA)
	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE '~':{
			SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)){
				CASE 'INTEGRATIONID':{
					SWITCH(ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))){
						CASE 3:{
							STACK_VAR INTEGER x
							STACK_VAR CHAR ID[20]
							ID = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
							FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
								IF(myLutronQS.DEVICE[x].ID == ID){
									STACK_VAR CHAR pTYPE[20]
									IF(FIND_STRING(pDATA,',',1)){
										pTYPE = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
									}
									ELSE{
										pTYPE = pDATA
									}
									SWITCH(pTYPE){
										CASE 'TIMECLOCK':	myLutronQS.DEVICE[x].TYPE = TYPE_TIMECLOCK
										CASE 'OUTPUT':		myLutronQS.DEVICE[x].TYPE = TYPE_OUTPUT
										CASE 'DEVICE':		myLutronQS.DEVICE[x].TYPE = TYPE_DEVICE
									}
									SWITCH(pTYPE){
										CASE 'DEVICE':{
											GET_BUFFER_STRING(pDATA,2)	// Strip
											IF(myLutronQS.DEVICE[x].SERIAL_NUMBER != pDATA){
												STACK_VAR INTEGER pLED
												myLutronQS.DEVICE[x].SERIAL_NUMBER = pDATA
												SEND_STRING vdvControl[x],"'PROPERTY-META_SN,',myLutronQS.DEVICE[x].SERIAL_NUMBER"
												FOR(pLED = 1; pLED <= 10; pLED++){
													//fnSendDeviceQuery(myLutronQS.DEVICE[x].ID,80+pLED,9)
												}
											}
										}
									}
									IF(TIMELINE_ACTIVE(TLID_COMMS_00+x)){TIMELINE_KILL(TLID_COMMS_00+x)}
									TIMELINE_CREATE(TLID_COMMS_00+x,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
							}
						}
					}
				}
				CASE 'DEVICE':{
					STACK_VAR INTEGER x
					STACK_VAR CHAR ID[20]
					ID = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
					FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
						IF(myLutronQS.DEVICE[x].ID == ID){
							STACK_VAR INTEGER pCompNo
							STACK_VAR INTEGER pActNo
							pCompNo = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
							
							IF(FIND_STRING(pDATA,',',1)){
								pActNo = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
							}
							ELSE{
								pActNo = ATOI(pDATA)
							}
							SEND_STRING 0,"ID,':',ITOA(pCompNo),':',ITOA(pActNo)"
							SWITCH(pActNo){
								CASE 3:{	// Push Event
									myLutronQS.DEVICE[x].BTN[pCompNo] = TRUE
								}
								CASE 4:	// Release Event
								CASE 6:{	// Multi-Tap
									// Force On (some devices dont' register Press
									[vdvControl[x],pCompNo] = TRUE
									myLutronQS.DEVICE[x].BTN[pCompNo] = FALSE
								}
								CASE 9:{	// LED State
									myLutronQS.DEVICE[x].LED[pCompNo-80] = ATOI(pDATA)
								}
							}
						}
					}
				}
				CASE 'OUTPUT':{
					STACK_VAR pID[20]
					STACK_VAR INTEGER d
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
					FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
						IF(myLutronQS.DEVICE[d].SERIAL_NUMBER == pID || myLutronQS.DEVICE[d].INTEGRATIONID == pID){
							SWITCH(ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))){
								CASE 1:{
									IF(!(FIND_STRING(pDATA,':',1))){
										myLutronQS.DEVICE[d].VALUE_FLOAT = ATOF(pDATA)
										myLutronQS.DEVICE[d].VALUE_INT 	= ATOI(pDATA)
									}
								}
							}
						}
					}
				}
				CASE 'GROUP':{
					STACK_VAR INTEGER pID
					STACK_VAR INTEGER pActNo
					STACK_VAR INTEGER d
					pID    = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
					pActNo = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))
					FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
						IF(myLutronQS.DEVICE[d].TYPE == TYPE_GROUPS){
							STACK_VAR INTEGER g
							FOR(g = 1; g <= _MAX_GROUPS; g++){
								IF(myLutronQS.DEVICE[d].GROUP[g].ID == pID){
									SWITCH(pActNo){
										CASE 3:{
											SWITCH(ATOI(pDATA)){
												CASE 3:myLutronQS.DEVICE[d].GROUP[g].STATE = TRUE
												CASE 4:myLutronQS.DEVICE[d].GROUP[g].STATE = FALSE
											}
										}
									}
								}
							}
						}
					}
				}
				CASE 'ETHERNET':{
					STACK_VAR INTEGER d
					FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
						SWITCH(myLutronQS.DEVICE[d].TYPE){
							CASE TYPE_GROUPS:{
								IF(TIMELINE_ACTIVE(TLID_COMMS_00+d)){TIMELINE_KILL(TLID_COMMS_00+d)}
								TIMELINE_CREATE(TLID_COMMS_00+d,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
						}
					}
				}
				CASE 'AREA':{
					STACK_VAR pID[20]
					STACK_VAR INTEGER d
					pID = fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1)
					FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
						IF(myLutronQS.DEVICE[d].AREA == pID){
							SWITCH(ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,',',1),1))){
								CASE 6:{
									// Scene
								}
								CASE 8:{
									// Occupancy State
								}
							}
							IF(TIMELINE_ACTIVE(TLID_COMMS_00+d)){TIMELINE_KILL(TLID_COMMS_00+d)}
							TIMELINE_CREATE(TLID_COMMS_00+d,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Polling  Helpers
******************************************************************************/
DEFINE_FUNCTION fnInitData(){
	STACK_VAR INTEGER d
	fnDebug(DEBUG_DEV,'fnInitData','Called')
	fnPoll()
	FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
		SWITCH(myLutronQS.DEVICE[d].TYPE){
			CASE TYPE_GROUPS:{
				STACK_VAR INTEGER x
				FOR(x = 1; x <= _MAX_GROUPS; x++){
					IF(myLutronQS.DEVICE[d].GROUP[x].ID){
						fnSendGroupQuery(myLutronQS.DEVICE[d].GROUP[x].ID,3)
					}
				}
			}
		}
	}
	fnInitPoll()
}

DEFINE_FUNCTION fnInitPoll(){
	fnDebug(DEBUG_DEV,'fnInitPoll','Called')
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnDebug(DEBUG_DEV,'TIMELINE_EVENT','TLID_POLL')
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	STACK_VAR INTEGER x
	fnDebug(DEBUG_DEV,'fnPoll','Called')
	FOR(x = 1; x <= LENGTH_ARRAY(vdvControl); x++){
		IF(LENGTH_ARRAY(myLutronQS.DEVICE[x].ID)){
			SWITCH(myLutronQS.USE_SN_AS_ID){
				CASE TRUE:	fnSendIntegrationIDQuery(myLutronQS.DEVICE[x].ID,1)
				CASE FALSE:	fnSendIntegrationIDQuery(myLutronQS.DEVICE[x].ID,3)
			}
		}
		ELSE IF(myLutronQS.DEVICE[x].TYPE == TYPE_GROUPS){
			fnSendEthernetQuery(1)
		}
		ELSE IF(myLutronQS.DEVICE[x].TYPE == TYPE_AREA){
			fnSendAreaQuery(myLutronQS.DEVICE[x].AREA,6)
			fnSendAreaQuery(myLutronQS.DEVICE[x].AREA,8)
		}
	}
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvLutron]{
	ONLINE:{
		myLutronQS.IP_STATE	= IP_STATE_SECURITY
		IF(!myLutronQS.isIP){
			IF(!LENGTH_ARRAY(myLutronQS.BAUD)){myLutronQS.BAUD = '9600'}
		   SEND_COMMAND dvLutron,  'SET MODE DATA'
		   SEND_COMMAND dvLutron, "'SET BAUD ',myLutronQS.BAUD,' N 8 1 485 DISABLE'"
		   SEND_COMMAND dvLutron,  'SET FAULT DETECT OFF'
			fnInitData()
		}
	}
	OFFLINE:{
		IF(myLutronQS.isIP){
			myLutronQS.IP_STATE	= IP_STATE_OFFLINE
			myLutronQS.LOGIN_ATTEMPT = 0
			fnRetryConnection()
		}
	}
	ONERROR:{
		IF(myLutronQS.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myLutronQS.IP_STATE = IP_STATE_OFFLINE
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
			fnDebug(DEBUG_STD,"'QS IP Error:[',myLutronQS.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		//STACK_VAR INTEGER x
		//FOR(x = 1; x <= LENGTH_ARRAY(DATA.TEXT); x++){
		//	SEND_STRING 0, "fnPadLeadingChars(ITOHEX(DATA.TEXT[x]),'0',2),'--',ITOA(DATA.TEXT[x]),'--',DATA.TEXT[x]"
		//}
		fnDebug(DEBUG_DEV,"'->RAW[',ITOA(LENGTH_ARRAY(DATA.TEXT)),']'",DATA.TEXT)

		IF(FIND_STRING(myLutronQS.Rx,'login:',1)) {
			IF(myLutronQS.USERNAME = ''){
				myLutronQS.LOGIN_ATTEMPT = myLutronQS.LOGIN_ATTEMPT + 1
				SWITCH(myLutronQS.LOGIN_ATTEMPT){
					CASE 1:{
						fnDebug(DEBUG_DEV,'RAW->',"'lutron',$0D,$0A")
						SEND_STRING dvLutron,"'lutron',$0D,$0A"
					}
					CASE 2:{
						fnDebug(DEBUG_DEV,'RAW->',"'nwk',$0D,$0A")
						SEND_STRING dvLutron,"'nwk',$0D,$0A"
					}
					CASE 3:{
						fnDebug(DEBUG_DEV,'RAW->',"'',$0D,$0A")
						SEND_STRING dvLutron,"'',$0D,$0A"
					}
				}
			}
			ELSE{
				fnDebug(DEBUG_DEV,'RAW->',"myLutronQS.USERNAME,$0D,$0A")
				SEND_STRING dvLutron,"myLutronQS.USERNAME,$0D,$0A"
			}
			myLutronQS.RX = ''
		}
		ELSE IF(FIND_STRING(myLutronQS.Rx,'password:',1)) {
			fnDebug(DEBUG_DEV,'RAW->',"'lutron',$0D,$0A")
			SEND_STRING dvLutron,"'lutron',$0D,$0A"
			myLutronQS.RX = ''
		}
		ELSE IF(FIND_STRING(myLutronQS.Rx,'connection established',1)) {
			fnDebug(DEBUG_DEV,'RAW->',"$0D,$0A")
			SEND_STRING dvLutron,"$0D,$0A"
			myLutronQS.RX = ''
			fnInitConnection()
		}
		ELSE IF(FIND_STRING(myLutronQS.Rx,'QNET> ',1) && myLutronQS.IP_STATE != IP_STATE_CONNECTED) {
			REMOVE_STRING(myLutronQS.Rx,"'QNET> '",1)
			fnInitConnection()
		}
		IF(myLutronQS.IP_STATE == IP_STATE_CONNECTED){
			WHILE(FIND_STRING(myLutronQS.Rx,"$0D,$0A",1) || FIND_STRING(myLutronQS.Rx,"'QNET> '",1) || FIND_STRING(myLutronQS.Rx,"'QSE>'",1)){
				STACK_VAR INTEGER pPacketLOC
				STACK_VAR INTEGER pReadyLOC

				pPacketLOC 	= FIND_STRING(myLutronQS.Rx,"$0D,$0A",1)

				IF(FIND_STRING(myLutronQS.Rx,"'QNET> '",1)){
					REMOVE_STRING(myLutronQS.Rx,"'QNET> '",1)
				}
				ELSE IF(FIND_STRING(myLutronQS.Rx,"'QSE>'",1)){
					REMOVE_STRING(myLutronQS.Rx,"'QSE>'",1)
				}
				ELSE IF(FIND_STRING(myLutronQS.RX,"$0D,$0A",1)){
					fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myLutronQS.RX,"$0D,$0A",1),2))
				}
				fnSendFromQueue()
			}
		}
	}
}

DEFINE_FUNCTION fnInitConnection(){
	IF(TIMELINE_ACTIVE(TLID_BOOT)){TIMELINE_KILL(TLID_BOOT)}
	TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	myLutronQS.IP_STATE = IP_STATE_CONNECTED
	myLutronQS.RX = ''		// Clears occasional $00 (on initial connect)
	fnInitData()
	fnSendFromQueue()
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR INTEGER d;
		d = GET_LAST(vdvControl)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':	myLutronQS.DEBUG = DEBUG_DEV
							CASE 'TRUE':myLutronQS.DEBUG = DEBUG_STD
							DEFAULT:		myLutronQS.DEBUG = DEBUG_ERR
						}
					}
					CASE 'ID_MODE':{
						SWITCH(DATA.TEXT){
							CASE 'SERIAL_NUMBER':myLutronQS.USE_SN_AS_ID = TRUE
							CASE 'INTEGRATIONID':myLutronQS.USE_SN_AS_ID = FALSE
						}
					}
					CASE 'ID':{
						myLutronQS.DEVICE[d].ID = DATA.TEXT
						SWITCH(myLutronQS.USE_SN_AS_ID){
							CASE TRUE:	myLutronQS.DEVICE[d].SERIAL_NUMBER = myLutronQS.DEVICE[d].ID
							CASE FALSE:	myLutronQS.DEVICE[d].INTEGRATIONID = myLutronQS.DEVICE[d].ID
						}
					}
					CASE 'BAUD':{
						myLutronQS.BAUD = DATA.TEXT
						SEND_COMMAND dvLutron,  'SET MODE DATA'
						SEND_COMMAND dvLutron, "'SET BAUD ',myLutronQS.BAUD,' N 8 1 485 DISABLE'"
						SEND_COMMAND dvLutron,  'SET FAULT DETECT OFF'
					}
					CASE 'IP':{
						myLutronQS.IP_HOST = DATA.TEXT
						myLutronQS.IP_PORT = 23
						fnOpenTCPConnection()
					}
					CASE 'USERNAME':{
						myLutronQS.USERNAME = DATA.TEXT
					}
					CASE 'PASSWORD':{
						myLutronQS.PASSWORD = DATA.TEXT
					}
					CASE 'TYPE':{
						SWITCH(DATA.TEXT){
							CASE 'GROUPS':myLutronQS.DEVICE[d].TYPE = TYPE_GROUPS
							CASE 'AREA':  myLutronQS.DEVICE[d].TYPE = TYPE_AREA
						}
					}
					CASE 'AREA':{
						myLutronQS.DEVICE[d].TYPE = TYPE_AREA
						myLutronQS.DEVICE[d].AREA = ATOI(DATA.TEXT)
					}
					CASE 'GROUPS':{
						STACK_VAR INTEGER pGroupID
						STACK_VAR INTEGER pGroupIndex
						WHILE(FIND_STRING(DATA.TEXT,',',1)){
							pGroupID = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
							pGroupIndex++
							IF(pGroupIndex <= _MAX_GROUPS){
								myLutronQS.DEVICE[d].GROUP[pGroupIndex].ID = pGroupID
							}
						}
						pGroupIndex++
						myLutronQS.DEVICE[d].GROUP[pGroupIndex].ID = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'SCENE':{
				IF(myLutronQS.DEVICE[d].ID){
					fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,141,7,DATA.TEXT)
				}
				ELSE IF(myLutronQS.DEVICE[d].AREA){
					fnSendAreaCommand(ITOA(myLutronQS.DEVICE[d].AREA),6,DATA.TEXT)
				}
			}
			CASE 'LEVEL':
			CASE 'SHADE':{
				SWITCH(DATA.TEXT){
					CASE 'RAISE':	fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,0,18,'')
					CASE 'LOWER':	fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,0,19,'')
					CASE 'STOP':	fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,0,20,'')
					DEFAULT:			fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,0,14,DATA.TEXT)
				}
			}
			CASE 'PRESS':	fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,ATOI(DATA.TEXT),3,'')
			CASE 'RELEASE':fnSendDeviceCommand(myLutronQS.DEVICE[d].ID,ATOI(DATA.TEXT),4,'')
			CASE 'RAW':{
				fnDebug(DEBUG_STD,'->QS',"DATA.TEXT,$0D,$0A")
				SEND_STRING dvLutron, "DATA.TEXT,$0D,$0A"
			}
		}
	}
}
/******************************************************************************
	Virtual Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER d
	FOR(d = 1; d <= LENGTH_ARRAY(vdvControl); d++){
		STACK_VAR INTEGER b
		SWITCH(myLutronQS.DEVICE[d].TYPE){
			CASE TYPE_DEVICE:{
				FOR(b = 1; b <= 20; b++){	// LED Feedback
					[vdvControl[d],80+b] = (myLutronQS.DEVICE[d].LED[b])
				}
				FOR(b = 1; b <= 20; b++){	// Button Feedback
					[vdvControl[d],b] = (myLutronQS.DEVICE[d].BTN[b])
				}
			}
			CASE TYPE_GROUPS:{
				FOR(b = 1; b <= _MAX_GROUPS; b++){	// State Feedback
					IF(myLutronQS.DEVICE[d].GROUP[b].ID){
						[vdvControl[d],b] = (myLutronQS.DEVICE[d].GROUP[b].STATE)
					}
				}
			}
		}
		[vdvControl[d],251] = (myLutronQS.IP_STATE == IP_STATE_CONNECTED)
		[vdvControl[d],252] = (TIMELINE_ACTIVE(TLID_COMMS_00+d))
	}
}
/******************************************************************************
	EoF
******************************************************************************/



