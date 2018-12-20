MODULE_NAME='mDraperMotor'(DEV vdvControl,DEV dvDevice)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Draper Motor Control
	Tested against LVC-IV
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, 'SET MODE DATA'
		SEND_COMMAND DATA.DEVICE, 'SET BAUD 9600 N 8 1 485 DISABLE'
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'MOTOR':{
				SWITCH(DATA.TEXT){
					CASE 'UP':		SEND_STRING dvDevice, "$9A,$01,$01,$00,$0A,$DD,$D7"
					CASE 'DOWN':	SEND_STRING dvDevice, "$9A,$01,$01,$00,$0A,$CC,$C6"
					CASE 'STOP':	SEND_STRING dvDevice, "$9A,$01,$01,$00,$0A,$EE,$E4"
				}
			}
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/
