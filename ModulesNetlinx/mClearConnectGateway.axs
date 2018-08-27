MODULE_NAME='mClearConnectGateway'(DEV vdvCCG, DEV dvCCG)
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uCCG{
	CHAR 		DEVICE_REF[31][25]
	INTEGER 	OCCUPIED[31]
}

DEFINE_CONSTANT
LONG TLID_SENSE	= 0

DEFINE_VARIABLE
uCCG myCCG
LONG TLT[] = {1800000}	// Default to 30 Mins

DEFINE_EVENT DATA_EVENT[dvCCG]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
			CASE '~DEVICE':{
				STACK_VAR INTEGER ID
				ID = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE '2':{
						SWITCH(DATA.TEXT){
							CASE '3':{
								// Occupied
								myCCG.OCCUPIED[ID] = TRUE
							}
							CASE '4':{
								IF(TIMELINE_ACTIVE(ID)){TIMELINE_KILL(ID)}
								TIMELINE_CREATE(ID,TLT,LENGTH_ARRAY(TLT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								// Unoccupied
								myCCG.OCCUPIED[ID] = FALSE							}
						}
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= 31; x++){
		[vdvCCG,x] = ( myCCG.OCCUPIED[x] || TIMELINE_ACTIVE(x) )
	}
	[vdvCCG,251] = ( DEVICE_ID(dvCCG) )
	[vdvCCG,252] = ( DEVICE_ID(dvCCG) )
}

