MODULE_NAME='mSamsungVidWall'(DEV vdvControl, DEV vdvDisplays[], DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 06/07/2013  AT: 21:30:15        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
Samsung VideoWall Module - Basic use as single display
	vdvControl will control the whole wall via global commands
	vdvDisplay will provide detail on individual panel state
	No intelligence in control
	Assumption of ordered IDs starting from 1
******************************************************************************/
/******************************************************************************
	Module  Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uDisplay{
	INTEGER  POWER
	INTEGER  SOURCE
	CHAR	   SOURCE_NAME[20]
	INTEGER  LOCKED
	INTEGER  OSD

	CHAR 		META_SN[14]
	CHAR		META_MODEL[25]
	CHAR		META_SOFTWARE[25]
}
DEFINE_TYPE STRUCTURE uComms{
	(** General Comms Control **)
	CHAR 	   Tx[1000]
	CHAR 	   Rx[1000]
	INTEGER  DEBUG
	INTEGER  SOURCE
}
/******************************************************************************
	Module  Constants & Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_INPUT 	= 1
LONG TLID_POLL		= 2
LONG TLID_COMMS	= 100

DEFINE_VARIABLE
uComms   myComms
uDisplay myDisplay[16]
LONG TLT_INPUT[] 	= {0,100,8000}
LONG TLT_POLL[]	= {10000}
LONG TLT_COMMS[]	= {120000}
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myComms.Rx
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnInitPoll()
	}
	STRING:{
		IF(LENGTH_ARRAY(myComms.Rx)){
			// Clean off possible Garbage until $AA Found
			WHILE(FIND_STRING(myComms.Rx,"$AA",1) && myComms.Rx[1] != $AA){
				GET_BUFFER_CHAR(myComms.Rx)
			}
			WHILE(LENGTH_ARRAY(myComms.Rx)){	// Whilst there is Data & not flagged as incomplete
				IF(LENGTH_ARRAY(myComms.Rx) > 4){	// If the packet is large enough to have a Data Length
					STACK_VAR INTEGER _LEN
					_LEN = 4 + myComms.Rx[4] + 1
					IF(LENGTH_ARRAY(myComms.Rx) >= _LEN){	// Check there is a full packet here
						STACK_VAR INTEGER i;
						STACK_VAR INTEGER CHK;
						STACK_VAR CHAR PACKET[255]
						PACKET = GET_BUFFER_STRING(myComms.Rx,_LEN)
						FOR (i = 2; i < LENGTH_ARRAY(PACKET); i++){ CHK = CHK + PACKET[i]; }
						CHK = HEXTOI(RIGHT_STRING(ITOHEX(CHK),2))
						IF(CHK == PACKET[_LEN]){fnProcessFeedback(PACKET)}
						ELSE{ myComms.Rx = '';
							//SEND_STRING vdvDisplays, 'COMMS-ERROR';BREAK
						}
					}
					ELSE{ fnDebug('Full Packet', 'Not Found');BREAK}
				}
				ELSE{fnDebug('Data Length', 'Not Found');BREAK}
			}
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': 		myComms.DEBUG 	= (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{  fnSendCommand(0,$11,"$01") }
					CASE 'OFF':{ fnSendCommand(0,$11,"$00") }
				}
			}
			CASE 'LOCK':{
				SWITCH(DATA.TEXT){
					CASE 'ON': { fnSendCommand(0,$5D,"$01") }
					CASE 'OFF':{ fnSendCommand(0,$5D,"$00") }
				}
			}
			CASE 'OSD':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{  fnSendCommand(0,$70,"$01") }
					CASE 'OFF':{ fnSendCommand(0,$70,"$00") }
				}
			}
			CASE 'INPUT':{
				myComms.SOURCE = fnGetSourceCode(DATA.TEXT)
				IF(myComms.SOURCE){
					IF(TIMELINE_ACTIVE(TLID_INPUT))TIMELINE_KILL(TLID_INPUT)
					TIMELINE_CREATE(TLID_INPUT,TLT_Input,LENGTH_ARRAY(TLT_Input),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
			CASE 'ADJUST':{
				fnSendCommand(0,$3D,"$00")
			}
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_INPUT]{
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1:{ fnSendCommand(0,$14,"myComms.SOURCE") }
		CASE 2:{ fnSendCommand(0,$11,"$01") }
		CASE 3:{ fnSendCommand(0,$14,"myComms.SOURCE") }
	}
}

DEFINE_FUNCTION CHAR[255] fnGetSourceName(INTEGER pINPUT){
	SWITCH(pINPUT){
		CASE $14: RETURN 'PC'
		CASE $1E: RETURN 'BNC'
		CASE $18: RETURN 'DVI'
		CASE $0C: RETURN 'SOURCE'
		CASE $04: RETURN 'SVIDEO'
		CASE $08: RETURN 'COMPONENT'
		CASE $20: RETURN 'MAGICINFO'
		CASE $1F: RETURN 'DVI_VID'
		CASE $30: RETURN 'ATV'
		CASE $40: RETURN 'DTV'
		CASE $21: RETURN 'HDMI1'
		CASE $22: RETURN 'HDMI1PC'
		CASE $23: RETURN 'HDMI2'
		CASE $24: RETURN 'HDMI2PC'
		CASE $25: RETURN 'DPORT'
	}
}
DEFINE_FUNCTION INTEGER fnGetSourceCode(CHAR pINPUT[255]){
	SWITCH(pINPUT){
		CASE 'PC': 				RETURN $14
		CASE 'BNC': 			RETURN $1E
		CASE 'DVI': 			RETURN $18
		CASE 'SOURCE': 		RETURN $0C
		CASE 'SVIDEO': 		RETURN $04
		CASE 'COMPONENT': 	RETURN $08
		CASE 'MAGICINFO': 	RETURN $20
		CASE 'DVI_VID': 		RETURN $1F
		CASE 'ATV': 			RETURN $30
		CASE 'DTV': 			RETURN $40
		CASE 'HDMI': 			RETURN $21
		CASE 'HDMI1': 			RETURN $21
		CASE 'HDMI1PC': 		RETURN $22
		CASE 'HDMI2': 			RETURN $23
		CASE 'HDMI2PC': 		RETURN $24
		CASE 'DPORT': 			RETURN $25
	}
}

DEFINE_FUNCTION fnSendCommand(INTEGER pID,INTEGER cmd, CHAR par[]){
	STACK_VAR CHAR 	Packet[15];
	STACK_VAR INTEGER Check_Sum;
	STACK_VAR INTEGER x;
	IF(pID == 0){ pID = $FE }
	Packet = "cmd,pID,LENGTH_ARRAY(par),par"
	FOR (x = 1; x <=LENGTH_ARRAY(Packet); x++){
		Check_Sum = Check_Sum + Packet[x];
	}
	Check_Sum = HEXTOI(RIGHT_STRING(ITOHEX(Check_Sum),2))
	SEND_STRING dvRS232, "$AA,Packet,Check_Sum"
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myComms.DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvDisplays[1].Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[255]){
	STACK_VAR INTEGER pID
	STACK_VAR INTEGER pDataLength
	STACK_VAR INTEGER ERROR
	STACK_VAR CHAR	 	ERROR_TEXT[20]

	GET_BUFFER_CHAR(pDATA)						// Remove $AA
	GET_BUFFER_CHAR(pDATA)						// Remove $FF
	pDATA = fnStripCharsRight(pDATA,1)		// Remove CHKSUM
	pID = GET_BUFFER_CHAR(pDATA)				// Get ID
	pDataLength = GET_BUFFER_CHAR(pDATA)	// Get Data Length
	ERROR = (GET_BUFFER_CHAR(pDATA) != 'A')


	IF(!ERROR && pID && pDataLength){
		SWITCH(GET_BUFFER_CHAR(pDATA)){
			CASE $00:{	// Status Request
				myDisplay[pID].POWER 		= pDATA[1]
				IF(myDisplay[pID].SOURCE != pDATA[4]){
					myDisplay[pID].SOURCE 		= pDATA[4]
					myDisplay[pID].SOURCE_NAME = fnGetSourceName(myDisplay[pID].SOURCE)
					SEND_STRING vdvDisplays[pID],"'INPUT-',myDisplay[pID].SOURCE_NAME"
				}
				fnSendCommand(pID,$0B,"")	// Serial Number Request
			}
			CASE $0B:{	// Serial Number
				IF(myDisplay[pID].META_SN != pDATA){
					myDisplay[pID].META_SN = pDATA
					SEND_STRING vdvDisplays[pID],"'PROPERTY-META,SERIALNO,',myDisplay[pID].META_SN"
				}
				fnSendCommand(pID,$8A,"")	// Model Name
			}
			CASE $8A:{	// Model Name
				IF(myDisplay[pID].META_MODEL != pDATA){
					myDisplay[pID].META_MODEL = pDATA
					SEND_STRING vdvDisplays[pID],"'PROPERTY-META,TYPE,VideoWall'"
					SEND_STRING vdvDisplays[pID],"'PROPERTY-META,MAKE,Samsung'"
					SEND_STRING vdvDisplays[pID],"'PROPERTY-META,MODEL,',myDisplay[pID].META_MODEL"
				}
				fnSendCommand(pID,$0E,"")	// Software Version
			}
			CASE $0E:{	// Model Name
				IF(myDisplay[pID].META_SOFTWARE != pDATA){
					myDisplay[pID].META_SOFTWARE = pDATA
					SEND_STRING vdvDisplays[pID],"'PROPERTY-META,SOFTWARE,',myDisplay[pID].META_SOFTWARE"
				}
			}
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS+pID)){TIMELINE_KILL(TLID_COMMS+pID)}
		TIMELINE_CREATE(TLID_COMMS+pID,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ELSE{
		SWITCH(GET_BUFFER_CHAR(pDATA)){
			CASE $00:ERROR_TEXT = 'STATUS NAK'
		}
		SEND_STRING 0, "'Samsung Error:',ERROR_TEXT"
	}
}
/******************************************************************************
	Polling Code
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	LOCAL_VAR INTEGER x
	x++
	IF(x > LENGTH_ARRAY(vdvDisplays)){
		x = 1
	}
	fnPoll(x)
}
DEFINE_FUNCTION fnPoll(INTEGER x){
	fnSendCommand(x,$00,"")	// Power Status Request
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(vdvDisplays); p++){
		[vdvDisplays[p],251] = (TIMELINE_ACTIVE(TLID_COMMS+p))
		[vdvDisplays[p],252] = (TIMELINE_ACTIVE(TLID_COMMS+p))
		[vdvDisplays[p],255] = (myDisplay[p].POWER)
	}
}
