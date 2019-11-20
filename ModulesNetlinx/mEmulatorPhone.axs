MODULE_NAME='mEmulatorPhone'(DEV vdvPhone)
INCLUDE 'CustomFunctions'
DEFINE_TYPE STRUCTURE uPhone{
	INTEGER  IN_CALL
}

DEFINE_VARIABLE
VOLATILE uPhone myPhoneEm

DEFINE_EVENT DATA_EVENT[vdvPhone]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'DIAL':{
				SWITCH(DATA.TEXT){
					CASE 'HANGUP': myPhoneEm.IN_CALL = FALSE
					DEFAULT:			myPhoneEm.IN_CALL = TRUE
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvPhone,238] = (myPhoneEm.IN_CALL)
}