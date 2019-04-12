MODULE_NAME='mIiyamaDisplayRS232'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	RS232 Control only module for Iiyama Screens with poor protocol
******************************************************************************/
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uIiyamaRS232{
	INTEGER 	DISABLED
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_BOOT = 1
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uIiyamaRS232 myIiyamaRS232

LONG 		TLT_BOOT[]		= { 5000};	// Give it 5 seconds for Boot to finish

/******************************************************************************
	Timelines
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myIiyamaRS232.DISABLED){
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,Iiyama'
		SEND_STRING vdvControl,'PROPERTY-META,MODEL,RS232 OneWay'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1'
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 19200 N 8 1 485 DISABLE'
	}
}
/******************************************************************************
	Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		IF(!TIMELINE_ACTIVE(TLID_BOOT)){
			TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	STRING:{

	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'IIYAMA_RS232':
							CASE 'TRUE':myIiyamaRS232.DISABLED = FALSE
							DEFAULT:		myIiyamaRS232.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myIiyamaRS232.DISABLED){
			SWITCH(fnStripCharsRight( REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	SEND_STRING dvRS232, "$BE,$EF,$03,$19,$00,$00,$00,$01,$00,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC"
						CASE 'OFF':{
							SEND_STRING dvRS232, "$BE,$EF,$03,$19,$00,$00,$00,$01,$00,$02,$01,$00,$00,$00,$00,$00,$04,$00,$00,$00,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC"
							WAIT 10{
								SEND_STRING dvRS232, "$BE,$EF,$03,$19,$00,$00,$00,$01,$00,$02,$01,$00,$00,$00,$00,$00,$04,$00,$00,$00,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC"
							}
						}
					}
				}
				CASE 'INPUT':{
					SWITCH(DATA.TEXT){
						CASE 'HDMI1':SEND_STRING dvRS232, "$BE,$EF,$03,$19,$00,$00,$00,$01,$00,$02,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC"
					}
				}
				CASE 'RAW':		SEND_STRING dvRS232, "DATA.TEXT"
			}
		}
	}
}
DEFINE_PROGRAM{
	IF(!myIiyamaRS232.DISABLED){
		[vdvControl,251] = TRUE
		[vdvControl,252] = TRUE
	}
}
/******************************************************************************
	EoF
******************************************************************************/
