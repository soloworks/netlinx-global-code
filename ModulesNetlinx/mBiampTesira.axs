MODULE_NAME='mBiAmpTesira'(DEV vdvControl, DEV vdvObjects[], DEV dvBiAmp)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/30/2013  AT: 13:27:49        *)
(***********************************************************)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Structures for Object Data
******************************************************************************/
DEFINE_CONSTANT
INTEGER OBJ_CONTROL_LEVEL 	= 1
INTEGER OBJ_CONTROL_MUTE	= 2
INTEGER OBJ_MIXER_MATRIX	= 3
INTEGER OBJ_IO_VOIP			= 4
INTEGER OBJ_IO_POTS			= 5
INTEGER OBJ_LOGIC_STATE 	= 6
INTEGER OBJ_LOGIC_METER 	= 7

INTEGER LVL_VOL_RAW = 1
INTEGER LVL_VOL_100 = 2
INTEGER LVL_VOL_255 = 3

// IP States
INTEGER IP_STATE_OFFLINE		= 0
INTEGER IP_STATE_CONNECTING	= 1
INTEGER IP_STATE_NEGOTIATING	= 2
INTEGER IP_STATE_CONNECTED		= 3

INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV		= 2

INTEGER STATE_MUTE		= 1
INTEGER STATE_HOOK		= 2
INTEGER STATE_LOGIC		= 3

DEFINE_TYPE STRUCTURE uBiAmp{
	(** Comms Variables **)
	CHAR 		Rx[5000]
	CHAR 		TxPoll[5000]
	CHAR 		TxCmd[5000]
	INTEGER 	DEBUG
	CHAR		TxPend[500]
	(** RS232 Properties **)
	CHAR 		BAUD[10]
	(** IP Properties **)
	INTEGER 	IP_PORT
	CHAR 		IP_HOST[255]
	INTEGER	IP_STATE
	INTEGER	isIP
	(** State Variables **)
	CHAR		META_SN[20]
	CHAR		META_IP[15]
	CHAR		META_VER[20]
	(** State Variables **)
}
DEFINE_TYPE STRUCTURE uObject{
	(** Universal Properties **)
	CHAR 		TAG1[50]	// Base Object Tag
	CHAR 		TAG2[50]	// Secondary Object Tag
	CHAR		INDEX1[20]	// Attribute Index 1
	CHAR		INDEX2[20]	// Attribute Index 2
	INTEGER  TYPE
	(** Object Properties **)
	INTEGER 	STEP			// Level Step
	SINTEGER VAL_LEVEL	// Volume
	SINTEGER VAL_MAX		// Volume Max
	SINTEGER VAL_MIN		// Volume Min
	// STATES: 1=Mute/Logic, 2=AutoAnswer/Logic, 3-16=Logic
	INTEGER 	VAL_STATE[16]
	INTEGER 	VOL_PEND
	CHAR 		LAST_VOL[10]
	CHAR 		CALLSTATE[6][25]
	CHAR 		SDLABEL[16][25]
	CHAR 		SDNUMBER[16][25]
	(** Matrix Object Properties **)
	CHAR		MTX_TYPE
	(** Phone Object Properties **)
	CHAR 		TRIG_RING[25]
	CHAR 		TRIG_OFFHOOK[25]
	CHAR 		TRIG_ONHOOK[25]
	INTEGER 	ON_HOOK
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
VOLATILE uObject  myObjects[30]
(** Ethernet Comms **)
DEFINE_CONSTANT
LONG TLID_RETRY 				= 1
LONG TLID_POLL					= 2
LONG TLID_TIMEOUT		 		= 3
LONG TLID_HOOK_Q_DELAY 		= 4
LONG TLID_COMMS				= 5

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

DEFINE_VARIABLE
LONG TLT_RETRY[]				= { 5000}
LONG TLT_POLL[]				= {45000}
LONG TLT_HOOK_Q_DELAY[] 	= {  500}
LONG TLT_TIMEOUT[]		 	= { 5000}
LONG TLT_COMMS[]				= {90000}
LONG TLT_VOL[]	  				= {  200}
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
	Module Functions
******************************************************************************/
DEFINE_FUNCTION fnSendAttributeCommand(INTEGER isQuery,CHAR pTAG[],CHAR pCMD[],CHAR pATT[],CHAR pINDEX1[],CHAR pINDEX2[],CHAR pVAL[]){
	STACK_VAR CHAR toSend[255]
	STACK_VAR INTEGER x
	toSend = "'"',pTAG,'" ',pCMD,' ',pATT"
	IF(LENGTH_ARRAY(pINDEX1)){ toSend = "toSend,' "',pINDEX1,'"'" }
	IF(LENGTH_ARRAY(pINDEX2)){ toSend = "toSend,' "',pINDEX2,'"'" }
	IF(LENGTH_ARRAY(pVAL)){ toSend = "toSend,' "',pVAL,'"'" }
	fnAddToQueue(isQuery,toSend)
}

DEFINE_FUNCTION fnSendServiceCommand(INTEGER isQuery,CHAR pTAG[],CHAR pCODE[],CHAR pINDEX1[],CHAR pINDEX2[],CHAR pVAL[]){
	STACK_VAR CHAR toSend[255]
	STACK_VAR INTEGER x
	toSend = "'"',pTAG,'" ',pCODE"
	IF(LENGTH_ARRAY(pINDEX1)){ toSend = "toSend,' "',pINDEX1,'"'" }
	IF(LENGTH_ARRAY(pINDEX2)){ toSend = "toSend,' "',pINDEX2,'"'" }
	IF(LENGTH_ARRAY(pVAL)){ toSend = "toSend,' "',pVAL,'"'" }
	fnAddToQueue(isQuery,toSend)
}

DEFINE_FUNCTION fnAddToQueue(INTEGER isQuery,CHAR cCMD[]){
	SWITCH(isQuery){
		CASE TRUE:	myBiAmp.TxPoll = "myBiAmp.TxPoll,cCMD,$0A"
		CASE FALSE:	myBiAmp.TxCmd  = "myBiAmp.TxCmd,cCMD,$0A"
	}
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	fnDebug(DEBUG_DEV,'fnSendFromQueue','')
	// If the system is connected and there is no command currently pending a response
	IF(myBiAmp.IP_STATE == IP_STATE_CONNECTED && !LENGTH_ARRAY(myBiAmp.TxPend)){
		STACK_VAR CHAR toSend[255]
		// Grab a command if present, else grab a poll
		SELECT{
			ACTIVE(FIND_STRING(myBiAmp.TxCmd,"$0A",1)):{ toSend = REMOVE_STRING(myBiAmp.TxCmd,"$0A",1) }
			ACTIVE(FIND_STRING(myBiAmp.TxPoll,"$0A",1)):{toSend = REMOVE_STRING(myBiAmp.TxPoll,"$0A",1)}
		}
		// If a command was actually found
		IF(LENGTH_ARRAY(toSend)){
			fnDebug(DEBUG_STD,'->BiAmp',"toSend")
			SEND_STRING dvBiAmp,"toSend"
			// Store the last sent command
			myBiAmp.TxPend = fnStripCharsRight(toSend,1)
			// Set a timeout to reset the system
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			// Re-init the polling timeline
			fnInitPoll()
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myBiAmp.TxPend = ''
	myBiAmp.TxCmd 	= ''
	myBiAmp.TxPoll = ''
	IF(myBiAmp.isIP){
		fnCloseTCPConnection()
	}
}

/******************************************************************************
	Polling Functions
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR INTEGER o
	fnAddToQueue(TRUE,'DEVICE get networkStatus')
	fnAddToQueue(TRUE,'DEVICE get serialNumber')
	fnAddToQueue(TRUE,'DEVICE get version')
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		(** Logic State Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_LOGIC_STATE:{
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','state',myObjects[o].INDEX1,'','')
			}
			CASE OBJ_LOGIC_METER:{
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'subscribe','states','',"myObjects[o].TAG1,'LM'",'')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','states','','','')
			}
		}
		(** Mute Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_CONTROL_LEVEL:
			CASE OBJ_CONTROL_MUTE:{
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'subscribe','mute',myObjects[o].INDEX1,"myObjects[o].TAG1,'M',myObjects[o].INDEX1",'')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','mute',myObjects[o].INDEX1,'','')
			}
		}
		(** Level Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_CONTROL_LEVEL:{
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'subscribe','level',myObjects[o].INDEX1,"myObjects[o].TAG1,'V',myObjects[o].INDEX1",'')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','level',myObjects[o].INDEX1,'','')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','minLevel',myObjects[o].INDEX1,'','')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','maxLevel',myObjects[o].INDEX1,'','')
			}
		}
		(** VOIP Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_IO_VOIP:{
				STACK_VAR INTEGER x
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'subscribe','callState',"myObjects[o].TAG1,'CS'",'','')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','callState','','','')
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','autoAnswer',myObjects[o].INDEX1,'','')
				IF(LENGTH_ARRAY(myObjects[o].TAG2)){
					FOR(x = 1; x <= 16; x++){
						fnSendAttributeCommand(TRUE,myObjects[o].TAG2,'get','speedDialLabel',myObjects[o].INDEX1,ITOA(x),'')
						fnSendAttributeCommand(TRUE,myObjects[o].TAG2,'get','speedDialNum',myObjects[o].INDEX1,ITOA(x),'')
					}
				}
			}
		}
		(** POTS Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_IO_POTS:{
				STACK_VAR INTEGER x
				IF(myObjects[o].INDEX1 == '1'){
					fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'subscribe','callState',"myObjects[o].TAG1,'CS'",'','')
					fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','callState','','','')
				}
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','autoAnswer','','','')
				IF(LENGTH_ARRAY(myObjects[o].TAG2)){
					FOR(x = 1; x <= 16; x++){
						fnSendAttributeCommand(TRUE,myObjects[o].TAG2,'get','speedDialLabel','',ITOA(x),'')
						fnSendAttributeCommand(TRUE,myObjects[o].TAG2,'get','speedDialNum','',ITOA(x),'')
					}
				}
			}
		}
	}
}
DEFINE_FUNCTION fnPollnonSubscriptions(){

	STACK_VAR INTEGER o
	FOR(o = 1; o <= LENGTH_ARRAY(vdvObjects); o++){
		(** Logic State Subscriptions **)
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_LOGIC_STATE:{
				fnSendAttributeCommand(TRUE,myObjects[o].TAG1,'get','state',myObjects[o].INDEX1,'','')
			}
		}
	}
}

/******************************************************************************
	Feedback Processing Functions
******************************************************************************/
DEFINE_FUNCTION fnProcessFeedback(CHAR pFBData[4000]){
	fnDebug(DEBUG_DEV,'fnProcessFeedback',"'1:LENGTH_ARRAY(pDATA)=',ITOA(LENGTH_ARRAY(pFBData))")
	fnDebug(DEBUG_STD,'BiAmp->',pFBData)
	IF(FIND_STRING(pFBData,'Welcome',1)){
		myBiAmp.IP_STATE = IP_STATE_CONNECTED
		fnPoll()
		fnInitPoll()
		RETURN
	}
	// Unsolicited Subscription Response
	IF(LEFT_STRING(pFBData,16) == '! "publishToken"'){
		STACK_VAR INTEGER o
		STACK_VAR CHAR TOKEN[50]
		fnDebug(DEBUG_DEV,'fnProcessFeedback','Token Response')
		REMOVE_STRING(pFBData,':"',1)
		TOKEN = fnRemoveQuotes(fnStripCharsRight(REMOVE_STRING(pFBData,'"',1),1))

		FOR(o=1; o<=LENGTH_ARRAY(vdvObjects); o++){
			STACK_VAR CHAR pDATA[4000]
			pDATA = pFBData
			IF(TOKEN == "myObjects[o].TAG1,'V',myObjects[o].INDEX1"){
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_CONTROL_LEVEL:{
						REMOVE_STRING(pDATA,'"value":',1)
						myObjects[o].VAL_LEVEL = ATOI(pDATA)
					}
				}
			}
			ELSE IF(TOKEN == "myObjects[o].TAG1,'L',myObjects[o].INDEX1"){
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_LOGIC_STATE:{
						REMOVE_STRING(pDATA,'"value":',1)
						myObjects[o].VAL_STATE[01] = (pDATA == 'true')
					}
				}
			}
			ELSE IF(TOKEN == "myObjects[o].TAG1,'M',myObjects[o].INDEX1"){
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_CONTROL_MUTE:
					CASE OBJ_CONTROL_LEVEL:{
						REMOVE_STRING(pDATA,'"value":',1)
						myObjects[o].VAL_STATE[01] = (pDATA == 'true')
					}
				}
			}
			ELSE IF(TOKEN == "myObjects[o].TAG1,'AA'"){
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_IO_POTS:
					CASE OBJ_IO_VOIP:{
						REMOVE_STRING(pDATA,'"value":',1)
						myObjects[o].VAL_STATE[02] = (pDATA == 'true')
					}
				}
			}
			ELSE IF(TOKEN == "myObjects[o].TAG1,'LM'"){		// Logic Meter
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_LOGIC_METER:{
						STACK_VAR INTEGER x
						REMOVE_STRING(pDATA,'"value":',1)
						GET_BUFFER_CHAR(pDATA)		// Remove '['
						pDATA = fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1)	// Remove ']'
						x = 1
						WHILE(FIND_STRING(pDATA,' ',1)){
							myObjects[o].VAL_STATE[x] = (fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1) == 'true')
							x++
						}
						// pDATA should now be [xxxx xxxx]
						myObjects[o].VAL_STATE[x] = (pDATA == 'true')
					}
				}
			}
			ELSE IF(TOKEN == "myObjects[o].TAG1,'CS'"){
				fnDebug(DEBUG_DEV,'fnProcessFeedback','callState Response')
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_IO_VOIP:{
						REMOVE_STRING(pDATA,'"value":',1)
						WHILE(FIND_STRING(pDATA,"'callId'",1)){
							STACK_VAR CHAR pSTATE[255]
							STACK_VAR INTEGER pLINEID
							STACK_VAR INTEGER pCALLID
							REMOVE_STRING(pDATA,'state":',1)
							pSTATE = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
							REMOVE_STRING(pDATA,'lineId":',1)
							pLINEID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
							REMOVE_STRING(pDATA,'callId":',1)
							pCALLID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'state::',pSTATE")
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'lineId::',ITOA(pLINEID)")
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'callId::',ITOA(pCALLID)")
							IF(myObjects[o].INDEX1 == ITOA(pLINEID)){
								myObjects[o].CALLSTATE[pCALLID] = pSTATE
							}
						}
					}
					CASE OBJ_IO_POTS:{
						REMOVE_STRING(pDATA,'"value":',1)
						WHILE(FIND_STRING(pDATA,"'callId'",1)){
							STACK_VAR CHAR pSTATE[255]
							STACK_VAR INTEGER pLINEID
							STACK_VAR INTEGER pCALLID
							REMOVE_STRING(pDATA,'state":',1)
							pSTATE = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
							REMOVE_STRING(pDATA,'lineId":',1)
							pLINEID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
							REMOVE_STRING(pDATA,'callId":',1)
							pCALLID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'state::',pSTATE")
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'lineId::',ITOA(pLINEID)")
							fnDebug(DEBUG_DEV,"'callState-',ITOA(o)","'callId::',ITOA(pCALLID)")
							IF(myObjects[o].INDEX1 == ITOA(pLINEID)){
								myObjects[o].CALLSTATE[pCALLID] = pSTATE
							}
						}
					}
				}
			}
		}
	}
	ELSE{
		fnDebug(DEBUG_DEV,'fnProcessFeedback','Command Response')
		IF(pFBData == myBiAmp.TxPend){
			RETURN// Do nothing - Command Echo
		}
		ELSE IF(pFBData == '+OK'){
			// Probably a Preset has been called, poll
			fnPollnonSubscriptions()
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
		}
		ELSE IF(LEFT_STRING(pFBData,4) == '+OK '){
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			REMOVE_STRING(pFBData,' ',1)
			SWITCH(myBiAmp.TxPend){
				CASE 'DEVICE get serialNumber':{
					STACK_VAR CHAR myChunk[500]
					REMOVE_STRING(pFBData,'"value":',1)
					myChunk = fnRemoveQuotes(REMOVE_STRING(pFBData,'"',2))
					IF(myBiAmp.META_SN != myChunk){
						myBiAmp.META_SN = myChunk
						SEND_STRING vdvControl,"'PROPERTY-META,SERIALNO,',myChunk"
					}
				}
				CASE 'DEVICE get version':{
					STACK_VAR CHAR myChunk[500]
					REMOVE_STRING(pFBData,'"value":',1)
					myChunk = fnRemoveQuotes(REMOVE_STRING(pFBData,'"',2))
					IF(myBiAmp.META_VER != myChunk){
						myBiAmp.META_VER = myChunk
						SEND_STRING vdvControl,"'PROPERTY-META,FIRMWARE,',myChunk"
					}
				}
				CASE 'DEVICE get networkStatus':{
					STACK_VAR CHAR myChunk[500]
					REMOVE_STRING(pFBData,'"ip":',1)
					myChunk = fnRemoveQuotes(REMOVE_STRING(pFBData,'"',2))
					IF(myBiAmp.META_IP != myChunk){
						myBiAmp.META_IP = myChunk
						SEND_STRING vdvControl,"'PROPERTY-STATE,NET_IP,',myChunk"
					}
				}
				DEFAULT:{
					STACK_VAR INTEGER o
					LOCAL_VAR SINTEGER NEW_RANGE_LOW
					fnDebug(DEBUG_DEV,'fnProcessFeedback',"'myBiAmp.TxPend::',myBiAmp.TxPend")
					FOR(o=1; o<=LENGTH_ARRAY(vdvObjects); o++){
						STACK_VAR CHAR pDATA[4000]
						pDATA = pFBData
						SWITCH(myObjects[o].TYPE){
							CASE OBJ_LOGIC_METER:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get states "',myObjects[o].INDEX1,'"'"){
									STACK_VAR INTEGER x
									REMOVE_STRING(pDATA,'"value":',1)
									GET_BUFFER_CHAR(pDATA)		// Remove '['
									pDATA = fnStripCharsRight(REMOVE_STRING(pDATA,']',1),1)	// Remove ']'
									x = 1
									WHILE(FIND_STRING(pDATA,' ',1)){
										myObjects[o].VAL_STATE[x] = (fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1) == 'true')
										x++
									}
									// pDATA should now be [xxxx xxxx]
									myObjects[o].VAL_STATE[x] = (pDATA == 'true')
								}
							}
							CASE OBJ_LOGIC_STATE:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get state "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_STATE[01] = (pDATA == 'true')
								}
							}
							CASE OBJ_CONTROL_LEVEL:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get mute "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_STATE[01] = (pDATA == 'true')
								}
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get level "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_LEVEL = ATOI(pDATA)
								}
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get minLevel "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									//myObjects[o].VAL_MIN = ATOI(pDATA)
									NEW_RANGE_LOW = ATOI(pDATA)
								}
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get maxLevel "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									IF(myObjects[o].VAL_MIN != NEW_RANGE_LOW || myObjects[o].VAL_MAX != ATOI(pDATA)){
										myObjects[o].VAL_MIN = NEW_RANGE_LOW
										myObjects[o].VAL_MAX = ATOI(pDATA)
										SEND_STRING vdvObjects[o],"'RANGE-',ITOA(myObjects[o].VAL_MIN),',',ITOA(myObjects[o].VAL_MAX)"
									}
								}
							}
							CASE OBJ_CONTROL_MUTE:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get mute "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_STATE[01] = (pDATA == 'true')
								}
							}
							CASE OBJ_IO_POTS:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get callState'"){
								fnDebug(DEBUG_DEV,'fnProcessFeedback','get callState Response')
									REMOVE_STRING(pDATA,'"value":',1)
									WHILE(FIND_STRING(pDATA,"'callId'",1)){
										STACK_VAR CHAR pSTATE[255]
										STACK_VAR INTEGER pLINEID
										STACK_VAR INTEGER pCALLID
										REMOVE_STRING(pDATA,'state":',1)
										pSTATE = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
										REMOVE_STRING(pDATA,'lineId":',1)
										pLINEID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
										REMOVE_STRING(pDATA,'callId":',1)
										pCALLID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
										IF(myObjects[o].INDEX1 == ITOA(pLINEID)){
											myObjects[o].CALLSTATE[pCALLID] = pSTATE
										}
									}
								}
								ELSE IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get autoAnswer "','','"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_STATE[02] = (pDATA == 'true')
								}
								ELSE{
									IF(FIND_STRING(myBiAmp.TxPend,'speedDialLabel',1) || FIND_STRING(myBiAmp.TxPend,'speedDialNum',1)){
										STACK_VAR INTEGER x
										FOR(x = 1; x <= 16; x++){
											IF(myBiAmp.TxPend == "'"',myObjects[o].TAG2,'" get speedDialLabel "','','" "',ITOA(x),'"'"){
												REMOVE_STRING(pDATA,'"value":',1)
												myObjects[o].SDLABEL[x] = fnRemoveQuotes(pDATA)
											}
											ELSE IF(myBiAmp.TxPend == "'"',myObjects[o].TAG2,'" get speedDialNum "','','" "',ITOA(x),'"'"){
												REMOVE_STRING(pDATA,'"value":',1)
												myObjects[o].SDNUMBER[x] = fnRemoveQuotes(pDATA)
												SEND_COMMAND vdvObjects[o],"'SPEEDDIAL-',ITOA(x),',',myObjects[o].SDLABEL[x],',',myObjects[o].SDNUMBER[x]"
											}
										}
									}
								}
							}
							CASE OBJ_IO_VOIP:{
								IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get callState'"){
								fnDebug(DEBUG_DEV,'fnProcessFeedback','get callState Response')
									REMOVE_STRING(pDATA,'"value":',1)
									WHILE(FIND_STRING(pDATA,"'callId'",1)){
										STACK_VAR CHAR pSTATE[255]
										STACK_VAR INTEGER pLINEID
										STACK_VAR INTEGER pCALLID
										REMOVE_STRING(pDATA,'state":',1)
										pSTATE = fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)
										REMOVE_STRING(pDATA,'lineId":',1)
										pLINEID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
										REMOVE_STRING(pDATA,'callId":',1)
										pCALLID = ATOI(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)) + 1
										IF(myObjects[o].INDEX1 == ITOA(pLINEID)){
											myObjects[o].CALLSTATE[pCALLID] = pSTATE
										}
									}
								}
								ELSE IF(myBiAmp.TxPend == "'"',myObjects[o].TAG1,'" get autoAnswer "',myObjects[o].INDEX1,'"'"){
									REMOVE_STRING(pDATA,'"value":',1)
									myObjects[o].VAL_STATE[02] = (pDATA == 'true')
								}
								ELSE{
									IF(FIND_STRING(myBiAmp.TxPend,'speedDialLabel',1) || FIND_STRING(myBiAmp.TxPend,'speedDialNum',1)){
										STACK_VAR INTEGER x
										FOR(x = 1; x <= 16; x++){
											IF(myBiAmp.TxPend == "'"',myObjects[o].TAG2,'" get speedDialLabel "',myObjects[o].INDEX1,'" "',ITOA(x),'"'"){
												REMOVE_STRING(pDATA,'"value":',1)
												myObjects[o].SDLABEL[x] = fnRemoveQuotes(pDATA)
											}
											ELSE IF(myBiAmp.TxPend == "'"',myObjects[o].TAG2,'" get speedDialNum "',myObjects[o].INDEX1,'" "',ITOA(x),'"'"){
												REMOVE_STRING(pDATA,'"value":',1)
												myObjects[o].SDNUMBER[x] = fnRemoveQuotes(pDATA)
												SEND_COMMAND vdvObjects[o],"'SPEEDDIAL-',ITOA(x),',',myObjects[o].SDLABEL[x],',',myObjects[o].SDNUMBER[x]"
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
		ELSE IF(LEFT_STRING(pFBDAta,4) == '-ERR'){
			fnDebug(DEBUG_DEV,'fnProcessFeedback','Section 3')
			IF(pFBData != '-ERR ALREADY_SUBSCRIBED'){
				fnDebug(DEBUG_ERR,'ERROR',pFBDAta)
			}
		}
		myBiAmp.TxPend = ''
		fnSendFromQueue()
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Debugging Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLevel, CHAR Msg[], CHAR MsgData[]){
	IF(myBiAmp.DEBUG >= pLevel)	{
		STACK_VAR CHAR pCOPY[5000]
		pCOPY = MsgData
		WHILE(LENGTH_ARRAY(pCOPY)){
			SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', GET_BUFFER_STRING(pCOPY,150)"
		}
	}
}
/******************************************************************************
	Communications
******************************************************************************/
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myBiAmp.IP_HOST == ''){
		fnDebug(DEBUG_ERR,'Biamp Address Not Set','')
	}
	ELSE IF(myBiAmp.IP_STATE == IP_STATE_OFFLINE){
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
			myBiAmp.IP_STATE = IP_STATE_NEGOTIATING
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
		ELSE{
			(** RS232 Communications **)
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
		IF(myBiAmp.isIP){
			WHILE(myBiAmp.Rx[1] == $FF && LENGTH_ARRAY(myBiAmp.Rx) >= 3){
				STACK_VAR CHAR NEG_PACKET[3]
				NEG_PACKET = GET_BUFFER_STRING(myBiAmp.Rx,3)
				fnDebug(DEBUG_DEV,'BiAmp.Telnet->',NEG_PACKET)
				SWITCH(NEG_PACKET[2]){
					CASE $FB:
					CASE $FC:NEG_PACKET[2] = $FE
					CASE $FD:
					CASE $FE:NEG_PACKET[2] = $FC
				}
				fnDebug(DEBUG_DEV,'->BiAmp.Telnet',NEG_PACKET)
				SEND_STRING DATA.DEVICE,NEG_PACKET
			}
		}
		WHILE(FIND_STRING(myBiAmp.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myBiAmp.Rx,"$0D,$0A",1),2))
		}
	}
	OFFLINE:{
		(** Ethernet Communications **)
		IF(myBiAmp.isIP){
			myBiAmp.IP_STATE = IP_STATE_OFFLINE
			myBiAmp.TxCmd = ''
			myBiAmp.TxPoll = ''
			myBiAmp.TXPend = ''
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
			fnDebug(DEBUG_ERR,"'IP Error:[',myBiAmp.IP_HOST,':',ITOA(myBiAmp.IP_PORT),']'","'[',ITOA(DATA.NUMBER),'-',MSG,']'")
			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myBiAmp.IP_STATE = IP_STATE_OFFLINE
					fnTryConnection()
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
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'GETNAMES': 	SEND_STRING dvBiAmp, "'SESSION get aliases',$0A"
					CASE 'REBOOT':		SEND_STRING dvBiAmp, "'DEVICE reboot',$0A"
					CASE 'INIT': 		fnPoll()
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'BAUD':{
						IF(!myBiAmp.isIP){
							myBiAmp.BAUD = DATA.TEXT
							SEND_COMMAND dvBiAmp, "'SET BAUD ',myBiAmp.BAUD,' N 8 1 485 DISABLE'"
						}
					}
					CASE 'IP':{
						IF(myBiAmp.isIP){
							myBiAmp.IP_HOST = DATA.TEXT;
							fnTryConnection()
						}
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myBiAmp.DEBUG = DEBUG_STD
							CASE 'DEV':	myBiAmp.DEBUG = DEBUG_DEV
							DEFAULT:    myBiAmp.DEBUG = DEBUG_ERR
						}
					}
				}
			}
			CASE 'RAW':{
				fnAddToQueue(FALSE,DATA.TEXT)
			}
			CASE 'PRESET':{
				IF(FIND_STRING(DATA.TEXT,',',1)){
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'ID':fnSendServiceCommand(FALSE,'DEVICE','recallPreset','','',DATA.TEXT)
						CASE 'NAME':fnSendServiceCommand(FALSE,'DEVICE','recallPresetByName','','',DATA.TEXT)
					}
				}
				ELSE{
					fnSendServiceCommand(FALSE,'DEVICE','recallPreset','','',DATA.TEXT)
				}
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
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'TAG':
					CASE 'TAG1':	myObjects[o].TAG1 = DATA.TEXT
					CASE 'TAG2':	myObjects[o].TAG2 = DATA.TEXT
					CASE 'INDEX1': myObjects[o].INDEX1 = DATA.TEXT
					CASE 'INDEX2': myObjects[o].INDEX2 = DATA.TEXT
					CASE 'STEP': 	myObjects[o].STEP = ATOI(DATA.TEXT)
					CASE 'TYPE':{
						SWITCH(DATA.TEXT){
							CASE 'CONTROL_LEVEL':myObjects[o].TYPE = OBJ_CONTROL_LEVEL
							CASE 'CONTROL_MUTE':	myObjects[o].TYPE = OBJ_CONTROL_MUTE
							CASE 'LOGIC_STATE':	myObjects[o].TYPE = OBJ_LOGIC_STATE
							CASE 'LOGIC_METER':	myObjects[o].TYPE = OBJ_LOGIC_METER
							CASE 'MIXER_MATRIX':	myObjects[o].TYPE = OBJ_MIXER_MATRIX
							CASE 'IO_POTS':		myObjects[o].TYPE = OBJ_IO_POTS
							CASE 'IO_VOIP':		myObjects[o].TYPE = OBJ_IO_VOIP
						}
						SWITCH(DATA.TEXT){
							CASE 'CONTROL_LEVEL':IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
							CASE 'CONTROL_MUTE':	IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
							CASE 'LOGIC_STATE':	IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
							CASE 'MIXER_MATRIX':	IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
							CASE 'IO_POTS':		IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
							CASE 'IO_VOIP':{
								IF(myObjects[o].INDEX1 = ''){ myObjects[o].INDEX1 = '1' }
								IF(myObjects[o].INDEX2 = ''){ myObjects[o].INDEX2 = '1' }
							}
						}
						SWITCH(DATA.TEXT){
							CASE 'CONTROL_LEVEL':IF(!myObjects[o].STEP){ myObjects[o].STEP = DEF_VOL_STEP }
						}
					}
					CASE 'RING':	 myObjects[o].TRIG_RING    = DATA.TEXT
					CASE 'ONHOOK':	 myObjects[o].TRIG_ONHOOK  = DATA.TEXT
					CASE 'OFFHOOK': myObjects[o].TRIG_OFFHOOK = DATA.TEXT
				}
			}
			CASE 'STATE':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_LOGIC_STATE:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	myObjects[o].VAL_STATE[01] = TRUE
							CASE 'OFF':
							CASE 'FALSE':	myObjects[o].VAL_STATE[01] = FALSE
							CASE 'TOGGLE':	myObjects[o].VAL_STATE[01] = !myObjects[o].VAL_STATE[01]
						}
						SWITCH(myObjects[o].VAL_STATE[01]){
							CASE TRUE: 	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','state',myObjects[o].INDEX1,'','true')
							CASE FALSE:	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','state',myObjects[o].INDEX1,'','false')
						}
					}
				}
			}
			CASE 'MUTE':
			CASE 'MICMUTE':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_CONTROL_LEVEL:
					CASE OBJ_CONTROL_MUTE:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','mute',myObjects[o].INDEX1,'','true')
							CASE 'OFF':
							CASE 'FALSE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','mute',myObjects[o].INDEX1,'','false')
							CASE 'TOGGLE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'toggle','mute',myObjects[o].INDEX1,'','')
						}
					}
					CASE OBJ_LOGIC_STATE:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	myObjects[o].VAL_STATE[01] = TRUE
							CASE 'OFF':
							CASE 'FALSE':	myObjects[o].VAL_STATE[01] = FALSE
							CASE 'TOGGLE':	myObjects[o].VAL_STATE[01] = !myObjects[o].VAL_STATE[01]
						}
						SWITCH(myObjects[o].VAL_STATE[01]){
							CASE TRUE: 	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','state',myObjects[o].INDEX1,'','true')
							CASE FALSE:	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','state',myObjects[o].INDEX1,'','false')
						}
					}
				}
			}
			CASE 'AUTOANSWER':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_IO_POTS:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','autoAnswer','','','true')
							CASE 'OFF':
							CASE 'FALSE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','autoAnswer','','','false')
							CASE 'TOGGLE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'toggle','autoAnswer','','','')
						}
					}
					CASE OBJ_IO_VOIP:{
						SWITCH(DATA.TEXT){
							CASE 'ON':
							CASE 'TRUE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','autoAnswer',myObjects[o].INDEX1,'','true')
							CASE 'OFF':
							CASE 'FALSE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','autoAnswer',myObjects[o].INDEX1,'','false')
							CASE 'TOGGLE':	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'toggle','autoAnswer',myObjects[o].INDEX1,'','')
						}
					}
				}
				fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'get','autoAnswer',myObjects[o].INDEX1,'','')
			}
			CASE 'VOLUME':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_CONTROL_LEVEL:{
						// Unmute
						IF(myObjects[o].VAL_STATE[01]){
							myObjects[o].VAL_STATE[01] = FALSE
							fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','mute',myObjects[o].INDEX1,'','false')
						}
						// Do Volume
						SWITCH(DATA.TEXT){
							CASE 'INC':		fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'increment','level',myObjects[o].INDEX1,'',ITOA(myObjects[o].STEP) )
							CASE 'DEC':  	fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'decrement','level',myObjects[o].INDEX1,'',ITOA(myObjects[o].STEP) )
							DEFAULT:{
								IF(!TIMELINE_ACTIVE(TLID_VOL_00+o)){
									fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','level',myObjects[o].INDEX1,'',DATA.TEXT)
									TIMELINE_CREATE(TLID_VOL_00+o,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
								}
								ELSE{
									myObjects[o].LAST_VOL = DATA.TEXT
									myObjects[o].VOL_PEND = TRUE
								}
							}
						}
					}
				}
			}
			CASE 'DIAL':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_IO_POTS:{
						SWITCH(DATA.TEXT){
							CASE 'ANSWER':{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'answer','','','')
							}
							CASE 'HANGUP':{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end','','','')
								myObjects[o].ON_HOOK = TRUE;
							}
							DEFAULT:{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'dial','','',DATA.TEXT)
							}
						}
					}
					CASE OBJ_IO_VOIP:{
						SWITCH(DATA.TEXT){
							CASE 'ANSWER':{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'answer',myObjects[o].INDEX1,myObjects[o].INDEX2,'')
							}
							CASE 'HANGUP':{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'1','')
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'2','')
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'3','')
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'4','')
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'5','')
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'end',myObjects[o].INDEX1,'6','')
								myObjects[o].ON_HOOK = TRUE;
							}
							DEFAULT:{
								fnSendServiceCommand(FALSE,myObjects[o].TAG1,'dial',myObjects[o].INDEX1,myObjects[o].INDEX2,DATA.TEXT)
							}
						}
					}
				}
			}
			CASE 'DTMF':{
				SWITCH(myObjects[o].TYPE){
					CASE OBJ_IO_POTS:{
						fnSendServiceCommand(FALSE,myObjects[o].TAG1,'dtmf','','',DATA.TEXT)
					}
					CASE OBJ_IO_VOIP:{
						fnSendServiceCommand(FALSE,myObjects[o].TAG1,'dtmf',myObjects[o].INDEX1,'',DATA.TEXT)
					}
				}
			}
		}
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
TIMELINE_EVENT[TLID_VOL_20]
TIMELINE_EVENT[TLID_VOL_21]
TIMELINE_EVENT[TLID_VOL_22]
TIMELINE_EVENT[TLID_VOL_23]
TIMELINE_EVENT[TLID_VOL_24]
TIMELINE_EVENT[TLID_VOL_25]
TIMELINE_EVENT[TLID_VOL_26]
TIMELINE_EVENT[TLID_VOL_27]
TIMELINE_EVENT[TLID_VOL_28]
TIMELINE_EVENT[TLID_VOL_29]
TIMELINE_EVENT[TLID_VOL_30]{
	STACK_VAR INTEGER o
	o = TIMELINE.ID - TLID_VOL_00
	IF(myObjects[o].VOL_PEND){
		fnSendAttributeCommand(FALSE,myObjects[o].TAG1,'set','level',myObjects[o].INDEX1,'',myObjects[o].LAST_VOL)
		myObjects[o].VOL_PEND = FALSE
		TIMELINE_CREATE(TIMELINE.ID,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_EVENT
CHANNEL_EVENT[vdvObjects,0]{
	ON:{}
	OFF:{}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER o
	FOR(o=1; o<=LENGTH_ARRAY(vdvObjects); o++){
		SWITCH(myObjects[o].TYPE){
			CASE OBJ_CONTROL_LEVEL:{
				[vdvObjects[o],198] = myObjects[o].VAL_STATE[01]
				[vdvObjects[o],199] = myObjects[o].VAL_STATE[01]
				SEND_LEVEL vdvObjects[o],LVL_VOL_RAW,myObjects[o].VAL_LEVEL
				IF(myObjects[o].VAL_MIN != myObjects[o].VAL_MAX){
					SEND_LEVEL vdvObjects[o],LVL_VOL_100,fnScaleRange(myObjects[o].VAL_LEVEL,myObjects[o].VAL_MIN,myObjects[o].VAL_MAX,0,100)
					SEND_LEVEL vdvObjects[o],LVL_VOL_255,fnScaleRange(myObjects[o].VAL_LEVEL,myObjects[o].VAL_MIN,myObjects[o].VAL_MAX,0,255)
				}
			}
			CASE OBJ_CONTROL_MUTE:{
				[vdvObjects[o],198] = myObjects[o].VAL_STATE[01]
				[vdvObjects[o],199] = myObjects[o].VAL_STATE[01]
			}
			CASE OBJ_LOGIC_STATE:{
				[vdvObjects[o],1] 	= myObjects[o].VAL_STATE[01]
				[vdvObjects[o],198] 	= myObjects[o].VAL_STATE[01]
				[vdvObjects[o],199] 	= myObjects[o].VAL_STATE[01]
			}
			CASE OBJ_LOGIC_METER:{
				STACK_VAR INTEGER x
				FOR(x = 1; x <= 16; x++){
					[vdvObjects[o],x] 	= myObjects[o].VAL_STATE[x]
				}
			}
			CASE OBJ_IO_POTS:{
				[vdvObjects[o],235] 	= 	( myObjects[o].VAL_STATE[02])
				[vdvObjects[o],236]	= 	( myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_RINGING' )
				[vdvObjects[o],238]	= 	(
													myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_DIALING' ||
													myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_RINGBACK' ||
													myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_BUSY_TONE' ||
													myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_CONNECTED' ||
													myObjects[o].CALLSTATE[1] == 'TI_CALL_STATE_DROPPED'
												)
			}
			CASE OBJ_IO_VOIP:{
				STACK_VAR INTEGER c
				STACK_VAR INTEGER CALL_ACTIVE

				FOR(c = 1; c <= 6; c++){
					CALL_ACTIVE = CALL_ACTIVE || (
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_INVALID_NUMBER' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_DIALTONE' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_SILENT' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_DIALING' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_RINGBACK' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_BUSY' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_ACTIVE' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_ACTIVE_MUTED' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_ON_HOLD' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_CONF_ACTIVE' ||
						myObjects[o].CALLSTATE[c] == 'VOIP_CALL_STATE_CONF_HOLD'
					)
				}

				[vdvObjects[o],235] 	= 	( myObjects[o].VAL_STATE[02])
				[vdvObjects[o],236]	= 	( myObjects[o].CALLSTATE[1] == 'VOIP_CALL_STATE_RINGING' )
				[vdvObjects[o],238]	= 	CALL_ACTIVE
			}
		}
	}

	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}