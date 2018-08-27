MODULE_NAME='mWakeOnLan'(DEV vdvControl, DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/25/2013  AT: 15:39:19        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		IP_CLIENT_OPEN(dvDevice.PORT, '255.255.255.255', 9, IP_UDP)
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'WOL':{
				STACK_VAR CHAR MAC_BYTES[6]
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BYTE':{
						MAC_BYTES = DATA.TEXT
					}
					CASE 'ASCII':{
						STACK_VAR INTEGER x
						IF(FIND_STRING(DATA.TEXT,':',1)){
							FOR(x = 1; x <= 6; x++){
								MAC_BYTES = "MAC_BYTES,HEXTOI(fnGetSplitStringValue(DATA.TEXT,':',x))"
							}
						}
						ELSE IF(FIND_STRING(DATA.TEXT,'-',1)){
							FOR(x = 1; x <= 6; x++){
								MAC_BYTES = "MAC_BYTES,HEXTOI(fnGetSplitStringValue(DATA.TEXT,'-',x))"
							}
						}
						ELSE{
							WHILE(LENGTH_ARRAY(DATA.TEXT)){
								MAC_BYTES = "MAC_BYTES,HEXTOI(GET_BUFFER_STRING(DATA.TEXT,2))"
							}
						}
					}
				}
				SEND_STRING dvDevice, "$FF,$FF,$FF,$FF,$FF,$FF,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES"
				SEND_STRING 0, fnBytesToString("$FF,$FF,$FF,$FF,$FF,$FF,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES,
					MAC_BYTES,MAC_BYTES,MAC_BYTES,MAC_BYTES")
			}
		}
	}
}