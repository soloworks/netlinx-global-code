MODULE_NAME='mQConnect'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_TYPE STRUCTURE uInterface{
	// Communications
	CHAR Tx[500]
	INTEGER DEBUG					// Debuging ON/OFF
	INTEGER DISABLED				// Disable Module
	INTEGER PEND
	// MetaData
	CHAR META_PRODUCT_INFO[20]	// Product Info
}

DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_TIMEOUT	= 3

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= {90000}
LONG TLT_POLL[]  		= {40000}
LONG TLT_TIMEOUT[]  	= {5000}
VOLATILE uInterface myInterface
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(myInterface.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnSendCommand(INTEGER pCommandID,INTEGER pBridgeID,INTEGER pChanID,INTEGER pButtonCode) {
	STACK_VAR CHAR pToSend[10]
	STACK_VAR INTEGER pChkSum
	STACK_VAR INTEGER x

	pToSend = "$00,pCommandID,pBridgeID,pChanID,pButtonCode,$00"
	pToSend = "LENGTH_ARRAY(pToSend)+1,pToSend"

	pChkSum = $FF
	FOR(x = 1; x <= LENGTH_ARRAY(pToSend); x++){
		pChkSum = pChkSum BXOR pToSend[x]
	}

	myInterface.Tx = "$01,pToSend,pChkSum,':::'"
	fnSendFromQueue()

}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myInterface.PEND && FIND_STRING(myInterface.Tx,':::',1)){
		myInterface.PEND = TRUE
		SEND_STRING dvDevice,fnStripCharsRight(REMOVE_STRING(myInterface.Tx,':::',1),3)
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		fnInitPoll()
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myInterface.Tx = ''
	myInterface.PEND = FALSE
	fnInitPoll()
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	fnSendCommand($01,$01,$00,$00)	// Get Product Info
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND dvDevice, 'SET MODE DATA'
		SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		IF(!myInterface.DISABLED){
			fnDebug('QM->', DATA.TEXT)
			myInterface.PEND = FALSE
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			fnSendFromQueue()
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		// Enable / Disable Module
		SWITCH(DATA.TEXT){
			CASE 'PROPERTY-ENABLED,FALSE':myInterface.DISABLED = TRUE
			CASE 'PROPERTY-ENABLED,TRUE': myInterface.DISABLED = FALSE
		}
		IF(!myInterface.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'DEBUG': 		myInterface.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
					}
				}
				CASE 'ACTION':{
					STACK_VAR INTEGER InterfaceID
					STACK_VAR INTEGER ChannelID
					STACK_VAR INTEGER ButtonCode
					InterfaceID = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
					ChannelID 	= ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
					SWITCH(DATA.TEXT){
						CASE 'UP':				ButtonCode = $01
						CASE 'DOWN':			ButtonCode = $02
						CASE 'SETPOINT_A':	ButtonCode = $03
						CASE 'PRESET_1':		ButtonCode = $06
						CASE 'PRESET_2':		ButtonCode = $07
						CASE 'SETPOINT_B':	ButtonCode = $08
						CASE 'PRESET_3':		ButtonCode = $09
						CASE 'PRESET_4':		ButtonCode = $0A
						CASE 'PRESET_5':		ButtonCode = $0B
						CASE 'SETPOINT_C':	ButtonCode = $0C
						CASE 'PRESET_6':		ButtonCode = $0D
						CASE 'PRESET_7':		ButtonCode = $0E
					}
					fnSendCommand($05,InterfaceID,ChannelID,ButtonCode)
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	IF(!myInterface.DISABLED){
		[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	}
}
