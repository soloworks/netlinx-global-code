MODULE_NAME='mDVX'(DEV vdvControl, DEV dvDVX, DEV ipServer[])
INCLUDE 'CustomFunctions'
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
// Device ID's of various DVX devices
INTEGER ID_DVX3150HD_SP																= 354;		// 0x0162
INTEGER ID_DVX3150HD_T																= 387;		// 0x0183
INTEGER ID_DVX3155HD_SP																= 388;		// 0x0184
INTEGER ID_DVX3155HD_T																= 389;		// 0x0185
INTEGER ID_DVX2150HD_SP																= 390;		// 0x0186
INTEGER ID_DVX2150HD_T																= 391;		// 0x0187
INTEGER ID_DVX2155HD_SP																= 392;		// 0x0188
INTEGER ID_DVX2155HD_T																= 393;		// 0x0189
INTEGER ID_DVX3156HD_SP																= 419;		// 0x01A3
INTEGER ID_DVX3156HD_T																= 420;		// 0x01A4
INTEGER ID_DVX2110HD_SP																= 427;		// 0x01AB
INTEGER ID_DVX2110HD_T																= 428;		// 0x01AC
INTEGER ID_DVX2210HD_SP																= 458;		// 0x01CA
INTEGER ID_DVX2210HD_T																= 459;		// 0x01CB
INTEGER ID_DVX3250HD_SP																= 438;      // 0x01B6
INTEGER ID_DVX3250HD_T																= 449;      // 0x01C1
INTEGER ID_DVX3255HD_SP																= 450;      // 0x01C2
INTEGER ID_DVX3255HD_T																= 451;      // 0x01C3
INTEGER ID_DVX2250HD_SP																= 452;      // 0x01C4
INTEGER ID_DVX2250HD_T																= 453;      // 0x01C5
INTEGER ID_DVX2255HD_SP																= 454;      // 0x01C6
INTEGER ID_DVX2255HD_T																= 455;      // 0x01C7
INTEGER ID_DVX3256HD_SP																= 456;      // 0x01C8
INTEGER ID_DVX3256HD_T																= 457;      // 0x01C9

INTEGER IP_STATE_READY		= 1
INTEGER IP_STATE_CONNECTED	= 2

/******************************************************************************
	Types
******************************************************************************/
// Device ID's of various DVX devices
DEFINE_TYPE STRUCTURE uMatrix{
	// Comms
	INTEGER 	PORT
	CHAR		Rx[5][500]
	INTEGER 	IP_STATE[5]
	// Meta
	DEV_INFO_STRUCT DevInfoDVX
	DEV_INFO_STRUCT DevInfoNX
	CHAR		MODEL_NAME[20]
	INTEGER	INPUTS
	INTEGER	OUTPUTS
	// State
	INTEGER	TEMPERATURE
	INTEGER	VOLUME
	INTEGER 	MUTE
	INTEGER	SOURCE[10]
	INTEGER	DETECTED[10]
}
/******************************************************************************
	Variables
******************************************************************************/
// Device ID's of various DVX devices
DEFINE_VARIABLE
VOLATILE uMatrix myMatrix

DEFINE_START{
	// Get Processor Info
	DEVICE_INFO(0:1:0, myMatrix.DevInfoNX)
	// Default port for server to listen on
	myMatrix.PORT = 20001
	// Buffer the Volume
	CREATE_LEVEL dvDVX,1,myMatrix.VOLUME
	// Buffer the Temperature
	//CREATE_LEVEL dvDVX,8,myMatrix.TEMPERATURE
	// Buffer the incoming requests
	CREATE_BUFFER ipServer[1],myMatrix.Rx[1]
	CREATE_BUFFER ipServer[2],myMatrix.Rx[2]
	CREATE_BUFFER ipServer[3],myMatrix.Rx[3]
	CREATE_BUFFER ipServer[4],myMatrix.Rx[4]
	CREATE_BUFFER ipServer[5],myMatrix.Rx[5]
}

DEFINE_FUNCTION fnConsoleMsg(CHAR pDATA[]){
	SEND_STRING 0, "'Raft Rooms Server: ',pDATA"
}
DEFINE_FUNCTION fnSendFeedback(INTEGER pINDEX,CHAR pDATA[]){
	IF(pINDEX == 0){
		STACK_VAR INTEGER x
		FOR(x = 1; x <= 5; x++){
			fnSendFeedback(x,pDATA)
		}
		SEND_STRING vdvControl,pDATA
		RETURN
	}
	IF(myMatrix.IP_STATE[pINDEX] == IP_STATE_CONNECTED){
		SEND_STRING ipServer[pINDEX],"pData,$0D,$0A"
	}
}

DEFINE_FUNCTION fnProcessCommand(CHAR pDATA[]){
	STACK_VAR CHAR pCMD[30]
	fnConsoleMsg("'Processing Command:',pDATA")
	pCMD = fnStripCharsRight(REMOVE_STRING(pDATA,'-',1),1)
	SWITCH(pCMD){
		CASE 'AMATRIX':
		CASE 'VMATRIX':
		CASE 'MATRIX':{
			STACK_VAR INTEGER pIN
			STACK_VAR INTEGER pOUT
			pIN  = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,'*',1),1))
			pOUT = ATOI(pDATA)
			SWITCH(pCMD){
				CASE 'AMATRIX':	SEND_COMMAND dvDVX,"'AI',ITOA(pIN),'O',ITOA(pOUT)"
				CASE 'VMATRIX':	SEND_COMMAND dvDVX,"'VI',ITOA(pIN),'O',ITOA(pOUT)"
				CASE 'MATRIX':		SEND_COMMAND dvDVX,"'CI',ITOA(pIN),'O',ITOA(pOUT)"
			}
			SWITCH(pCMD){
				CASE 'VMATRIX':
				CASE 'MATRIX':		SEND_COMMAND dvDVX.NUMBER:pOUT:0,'VIDOUT_ON-ON'
			}
		}
		CASE 'INPUT':{
			SEND_COMMAND dvDVX,"'CI',ITOA(ATOI(pDATA)),'O',ITOA(1)"
			SEND_COMMAND dvDVX,"'CI',ITOA(ATOI(pDATA)),'O',ITOA(2)"
			SEND_COMMAND dvDVX,"'CI',ITOA(ATOI(pDATA)),'O',ITOA(3)"
			SEND_COMMAND dvDVX,"'CI',ITOA(ATOI(pDATA)),'O',ITOA(4)"
		}
		CASE 'MUTE':{
			SWITCH(pDATA){
				CASE 'ON': 		[dvDVX,199] = TRUE
				CASE 'OFF':		[dvDVX,199] = FALSE
				CASE 'TOGGLE':	[dvDVX,199] = ![dvDVX,199]
			}

		}
		CASE 'VOLUME':{
			[dvDVX,199] = FALSE
			SEND_COMMAND dvDVX,"'AUDOUT_VOLUME-',pDATA"
		}
	}
}
/******************************************************************************
	DVX Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDVX]{
	ONLINE:{
		// Get DVX Info
		DEVICE_INFO(DATA.DEVICE, myMatrix.DevInfoDVX)
		// Populate based on DVX model
		SWITCH(myMatrix.DevInfoDVX.DEVICE_ID){
			CASE ID_DVX3150HD_SP:		// DVX-3150HD-SP
			CASE ID_DVX3150HD_T:			// DVX-3150HD-T
			CASE ID_DVX3155HD_SP:		// DVX-3155HD-SP
			CASE ID_DVX3155HD_T:			// DVX-3155HD-T
			CASE ID_DVX3250HD_SP:   	// DVX-3250HD-SP
			CASE ID_DVX3250HD_T:    	// DVX-3250HD-T
			CASE ID_DVX3255HD_SP:   	// DVX-3255HD-SP
			CASE ID_DVX3255HD_T:    	// DVX-3255HD-T
			CASE ID_DVX3156HD_SP:		// DVX-3156HD-SP
         CASE ID_DVX3156HD_T:			// DVX-3156HD-T
			CASE ID_DVX3256HD_SP:		// DVX-3256HD-SP
         CASE ID_DVX3256HD_T:{		// DVX-3256HD-T
				myMatrix.INPUTS = 10
				myMatrix.OUTPUTS = 4
			}
			CASE ID_DVX2150HD_SP:		// DVX-2150HD-SP
			CASE ID_DVX2150HD_T:			// DVX-2150HD-T
			CASE ID_DVX2155HD_SP:		// DVX-2155HD-SP
			CASE ID_DVX2155HD_T:			// DVX-2155HD-T
			CASE ID_DVX2250HD_SP:		// DVX-2250HD-SP
			CASE ID_DVX2250HD_T:			// DVX-2250HD-T
			CASE ID_DVX2255HD_SP:		// DVX-2255HD-SP
			CASE ID_DVX2255HD_T:{		// DVX-2255HD-T
				myMatrix.INPUTS = 6
				myMatrix.OUTPUTS = 3
			}
			CASE ID_DVX2110HD_SP:           // DVX-2110HD-SP
			CASE ID_DVX2110HD_T:            // DVX-2110HD-T
			CASE ID_DVX2210HD_SP:           // DVX-2210HD-SP
			CASE ID_DVX2210HD_T:{            // DVX-2210HD-T
				myMatrix.INPUTS = 4
				myMatrix.OUTPUTS = 2
			}
		}
		IF(1){
			STACK_VAR INTEGER x
			FOR(x = 1; x <= myMatrix.OUTPUTS; x++){
				SEND_COMMAND DATA.DEVICE,"'INPUT-VIDEO,',ITOA(x)"
			}
			// Request Temperature
			SEND_COMMAND DATA.DEVICE,'?TEMP'
		}
		// Start the server process
		WAIT 50{
			IP_SERVER_OPEN(ipServer[1].PORT,myMatrix.PORT,IP_TCP)
			myMatrix.IP_STATE[1] = IP_STATE_READY
			fnConsoleMsg("'Server1 Listening on port ',ITOA(myMatrix.PORT)")
			IP_SERVER_OPEN(ipServer[2].PORT,myMatrix.PORT,IP_TCP)
			myMatrix.IP_STATE[2] = IP_STATE_READY
			fnConsoleMsg("'Server2 Listening on port ',ITOA(myMatrix.PORT)")
			IP_SERVER_OPEN(ipServer[3].PORT,myMatrix.PORT,IP_TCP)
			myMatrix.IP_STATE[3] = IP_STATE_READY
			fnConsoleMsg("'Server3 Listening on port ',ITOA(myMatrix.PORT)")
			IP_SERVER_OPEN(ipServer[4].PORT,myMatrix.PORT,IP_TCP)
			myMatrix.IP_STATE[4] = IP_STATE_READY
			fnConsoleMsg("'Server4 Listening on port ',ITOA(myMatrix.PORT)")
			IP_SERVER_OPEN(ipServer[5].PORT,myMatrix.PORT,IP_TCP)
			myMatrix.IP_STATE[5] = IP_STATE_READY
			fnConsoleMsg("'Server5 Listening on port ',ITOA(myMatrix.PORT)")
		}
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SWITCH':{
				SWITCH(GET_BUFFER_STRING(DATA.TEXT,6)){
					CASE 'LVIDEO':{
						STACK_VAR INTEGER pIN
						STACK_VAR INTEGER pOUT
						GET_BUFFER_CHAR(DATA.TEXT)	// Remote 'I'
						pIN = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'O',1),1))
						pOUT = ATOI(DATA.TEXT)
						myMatrix.SOURCE[pOUT] = pIN
						fnSendFeedback(0,"'SOURCE-',ITOA(pOUT),',',ITOA(myMatrix.SOURCE[pOUT])")
					}
				}
			}
			CASE 'TEMP':{
				myMatrix.TEMPERATURE = ATOI(DATA.TEXT)
				fnSendFeedback(0,"'PROPERTY-TEMPERATURE,',ITOA(myMatrix.TEMPERATURE)")
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[dvDVX,199]{
	ON:	fnProcessMuteFB([dvDVX,199])
	OFF:	fnProcessMuteFB([dvDVX,199])
}
DEFINE_FUNCTION fnProcessMuteFB(INTEGER pSTATE){
	myMatrix.MUTE = pSTATE
	SWITCH(myMatrix.MUTE){
		CASE TRUE: fnSendFeedback(0,"'MUTE-ON'")
		CASE FALSE:fnSendFeedback(0,"'MUTE-OFF'")
	}
}
DEFINE_EVENT LEVEL_EVENT[dvDVX,1]{
	fnSendFeedback(0,"'VOLUME-',ITOA(myMatrix.VOLUME)")
}
DEFINE_EVENT LEVEL_EVENT[dvDVX,8]{
	fnSendFeedback(0,"'PROPERTY-TEMPERATURE,',ITOA(myMatrix.TEMPERATURE)")
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		fnProcessCommand(DATA.TEXT)
	}
}
DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myMatrix.VOLUME
	[vdvControl,199] = [dvDVX,199]
}
/******************************************************************************
	Server Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipServer]{
	ONLINE:{
		STACK_VAR INTEGER s
		s = GET_LAST(ipServer)
		myMatrix.IP_STATE[s] = IP_STATE_CONNECTED
		fnConsoleMsg("'Connection established from ',DATA.SOURCEIP")

		fnSendFeedback(s,'Welcome the the Raft Rooms DVX Daemon!')
		fnSendFeedback(s,"'Connection ',ITOA(s),' of 5'")
		IF(1){
			STACK_VAR CHAR pMODEL[50]
			pMODEL = myMatrix.DevInfoDVX.DEVICE_ID_STRING
			pMODEL = fnRemoveWhiteSpace(REMOVE_STRING(pMODEL,' ',1))
			fnSendFeedback(s,"'PROPERTY-META,MODEL,',pMODEL")
		}
		fnSendFeedback(s,"'PROPERTY-META,SN,',myMatrix.DevInfoNX.SERIAL_NUMBER")
		fnSendFeedback(s,"'PROPERTY-TEMPERATURE,',ITOA(myMatrix.TEMPERATURE)")
		fnSendFeedback(s,"'VOLUME-',ITOA(myMatrix.VOLUME)")
		SWITCH([dvDVX,199]){
			CASE TRUE: fnSendFeedback(s,"'MUTE-ON'")
			CASE FALSE:fnSendFeedback(s,"'MUTE-OFF'")
		}

		fnSendFeedback(s,"'SOURCE-1,',ITOA(myMatrix.SOURCE[1])")
		fnSendFeedback(s,"'SOURCE-2,',ITOA(myMatrix.SOURCE[2])")
		fnSendFeedback(s,"'SOURCE-3,',ITOA(myMatrix.SOURCE[3])")
		fnSendFeedback(s,"'SOURCE-4,',ITOA(myMatrix.SOURCE[4])")
	}
	OFFLINE:{
		fnConsoleMsg("'Server',ITOA(GET_LAST(ipServer)),'Ended'")
		// Start the server process
		IP_SERVER_OPEN(DATA.DEVICE.PORT,myMatrix.PORT,IP_TCP)
		myMatrix.IP_STATE[GET_LAST(ipServer)] = IP_STATE_READY
		fnConsoleMsg("'Server',ITOA(GET_LAST(ipServer)),' Listening on port ',ITOA(myMatrix.PORT)")
	}
	STRING:{
		WHILE(FIND_STRING(myMatrix.Rx[GET_LAST(ipServer)],"$0D,$0A",1)){
			fnProcessCommand(fnStripCharsRight(REMOVE_STRING(myMatrix.Rx[GET_LAST(ipServer)],"$0D,$0A",1),2))
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/