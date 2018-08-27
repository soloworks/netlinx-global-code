MODULE_NAME='mNECProjector'(DEV vdvControl,DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/13/2013  AT: 10:46:18        *)
(***********************************************************)
/******************************************************************************
	Generic NEC Control Module over IP or RS232
	Note: Different models seem to use identical commands,
	but vary in return data on Polling
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	System Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uNECProj{
	INTEGER DISABLED
	(** RAW Return Data **)
	INTEGER ID
	INTEGER MODEL
	INTEGER PROJ_TYPE[3]
	INTEGER INPUT_TERM[2]
	INTEGER STATUS[2]
	INTEGER VID_MUTE
	INTEGER AUD_MUTE
	INTEGER ALT_INPUTS
	(** Unit Details **)
	CHAR SERIALNO[20]
	CHAR SOFTWARE[20]
	CHAR MODEL_NAME[20]
	(** Desired State **)
	CHAR 		desInput[10]
	(** Current State **)
	CHAR 		INPUT[10]
	INTEGER 	FREEZE
	INTEGER 	POWER
	INTEGER	VOL
	INTEGER 	LAMP_REMAIN
	INTEGER 	LAMP_USAGE
	INTEGER 	FILTER_USAGE
	INTEGER 	PROJ_USAGE
	(** Status **)
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
	(** Comms **)
	INTEGER 	isIP
	INTEGER 	is1Way
	INTEGER 	PORT
	CHAR 	  	IP[128]
	INTEGER 	DEBUG
	INTEGER	LAST_POLL
	LONG		BAUD
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
	(** Projector Timings **)
INTEGER ProjectorTimeWarm = 45 // Time in Seconds {Warmup}
INTEGER ProjectorTimeCool = 20 // Time in Seconds {Cooldown}
	(** Timeline Constants **)
LONG TLID_BUSY 		= 1
LONG TLID_AUTOADJ 	= 2
LONG TLID_POLL 		= 3
LONG TLID_SEND			= 4
LONG TLID_TIMEOUT		= 5
LONG TLID_COMMS		= 6
LONG TLID_BOOT			= 7
LONG TLID_REPOLL		= 8
LONG TLID_VOL			= 9
	(** Channel Constants **)
INTEGER chnPicMute	= 211;
INTEGER chnFreeze		= 214;
INTEGER chnWARM		= 253;
INTEGER chnCOOL		= 254;
INTEGER chnPOWER		= 255;
	(** Default Values **)
INTEGER defPort		= 7142
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uNECProj myNECProj
	(** Comms Variables **)
#WARN 'Tidy up Comms Code into Standard'
VOLATILE INTEGER bConnOpen		= FALSE

VOLATILE CHAR cToSend[255]
VOLATILE CHAR cInBuffer[255]
	(** Projector State Variables **)
VOLATILE INTEGER bWarming	// Projector Warming Up
VOLATILE INTEGER bCooling	// Projector Cooling Down
	(** Timeline Times **)
LONG TLT_SECOND[] 	= {1000}		// One second for timer use
LONG TLT_AUTOADJUST[]= {3000}		// Autoadjust 3 seconds after input change
LONG TLT_TIMEOUT[]	= {5000}		// Close IP after 5 seconds of inactivity
LONG TLT_POLL[]		= {45000}	// Poll every 15 seconds
LONG TLT_COMMS[]		= {120000}	// Comms is dead if nothing recieved for 60s
LONG TLT_VOL[]			= {150}
LONG TLT_BOOT[]		= { 5000}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	myNECProj.isIP = (!dvDevice.NUMBER)
	CREATE_BUFFER dvDevice, cInBuffer
}
/******************************************************************************
	Utility Functions
******************************************************************************/
	(** Open a Network Connection **)
DEFINE_FUNCTION fnOpenConnection(){
	IF(!myNECProj.PORT){myNECProj.PORT = defPort}
	fnDebug("'TRY->NECP'","myNECProj.IP,':',ITOA(myNECProj.PORT)",FALSE)
	ip_client_open(dvDevice.port, myNECProj.IP, myNECProj.PORT, IP_TCP)
}
	(** Close a Network Connection **)
DEFINE_FUNCTION fnCloseConnection(){
	 ip_client_close(dvDevice.port)
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnPoll(){
	fnSendCommand("$00,$C0,$00,$00,$00")
}
	(** Send a command **)
DEFINE_FUNCTION fnSendCommand(CHAR cmd[50]){
	STACK_VAR INTEGER chk
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(cmd); x++){
		chk = chk + cmd[x]
	}
	cmd = "cmd,chk"
	IF(bConnOpen || !myNECProj.isIP){
		fnDebug('AMX->NECP',cmd,TRUE)
		SEND_STRING dvDevice, cmd
		fnInitPoll()
	}
	ELSE{
		cToSend = cmd
		fnOpenConnection()
	}
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){ TIMELINE_KILL(TLID_TIMEOUT) }
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
	(** Send Debug to terminal **)
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[150], INTEGER pDECODE){
	IF(myNECProj.DEBUG)	{
		IF(pDECODE){
			STACK_VAR CHAR readableMsgData[300]
			STACK_VAR CHAR copyMsgData[300]
			copyMsgData = MsgData
			WHILE(LENGTH_ARRAY(copyMsgData)){
				readableMsgData = "readableMsgData, fnPadLeadingChars(ITOHEX(GET_BUFFER_CHAR(copyMsgData)),'0',2),'H '"
				IF(LENGTH_ARRAY(readableMsgData) >= 40){
					SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', readableMsgData"
					readableMsgData = ''
				}
			}
			SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', readableMsgData"
		}
		ELSE{
			SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
		}
	}
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	IF(!myNECProj.is1Way){
		STACK_VAR CHAR pCMD[2]
		STACK_VAR INTEGER pID
		STACK_VAR INTEGER pMODEL
		STACK_VAR INTEGER pLEN
		pCMD 	 = GET_BUFFER_STRING(pDATA,2)	// Response Code
		pID 	 = GET_BUFFER_CHAR(pDATA)		// Projector ID
		pMODEL = GET_BUFFER_CHAR(pDATA)		// Model Code (affects responses sometimes)
		pLEN 	 = GET_BUFFER_CHAR(pDATA)
		IF(pCMD == "$20,$C0"){	// Status Response
			STACK_VAR INTEGER x
			fnDebug('STATUS LENGTH',ITOA(pLEN),FALSE)
			myNECProj.MODEL 	= pMODEL
			FOR(x = 1; x <= pLEN ; x++){
				fnDebug("'STATUS:',fnPadLeadingChars(ITOA(x),'0',2)",fnPadLeadingChars(ITOHEX(pDATA[x]),'0',2),FALSE)
				SWITCH(x){
					// Projector Model
					CASE 01:myNECProj.PROJ_TYPE[1] = pDATA[x]
					CASE 70:myNECProj.PROJ_TYPE[2] = pDATA[x]
					CASE 71:{
						myNECProj.PROJ_TYPE[3] = pDATA[x]
						IF(myNECProj.MODEL_NAME != fnGetModelName()){
							myNECProj.MODEL_NAME = fnGetModelName()
							SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myNECProj.MODEL_NAME"
						}
					}
					// Projector State
					CASE 04:myNECProj.STATUS[1]	= pDATA[x]
					CASE 69:{
						myNECProj.STATUS[2]	= pDATA[x]
						myNECProj.POWER = (myNECProj.STATUS[1] == $01 && myNECProj.STATUS[2] == $04)
					}
					CASE 29:myNECProj.VID_MUTE = pDATA[x]
					CASE 30:myNECProj.AUD_MUTE = pDATA[x]
					// Projector Input
					CASE 07:myNECProj.INPUT_TERM[1] = pDATA[x]
					CASE 08:{
						myNECProj.INPUT_TERM[2] = pDATA[x]
						IF(myNECProj.INPUT != fnGetInput()){
							myNECProj.INPUT = fnGetInput()
							SEND_STRING vdvControl,"'INPUT-',fnGetInput()"
						}
					}
				}
			}
			fnSendCommand("$03,$04,$00,$00,$03,$05,$00,$00")	// Request Volume Info
		}
		ELSE IF(pCMD == "$23,$04"){	// Volume Request
			STACK_VAR INTEGER x
			FOR(x = 1; x <= pLEN ; x++){
				SWITCH(x){
					// Projector Model
					CASE 08:myNECProj.VOL = pDATA[x]
				}
			}
			fnSendCommand("$00,$BF,$00,$00,$02,$01,$06")	// SERIALNO
		}
		ELSE IF(pCMD == "$20,$BF"){	// Information String Request
			STACK_VAR CHAR pINFO[2]
			pINFO = GET_BUFFER_STRING(pDATA,2)
			IF(FIND_STRING(pDATA,"$00",1)){
				pDATA = fnStripCharsRight(REMOVE_STRING(pDATA,"$00",1),1)
			}
			IF(pINFO == "$01,$06"){// SERIALNO
				IF(myNECProj.SERIALNO != pDATA){
					myNECProj.SERIALNO = pDATA
					SEND_STRING vdvControl, "'PROPERTY-META,SERIALNO,',myNECProj.SERIALNO"
				}
				fnSendCommand("$00,$BF,$00,$00,$02,$01,$00")	// VERSION
			}
			ELSE IF(pINFO == "$01,$00"){	// Version
				IF(myNECProj.SOFTWARE != pDATA){
					myNECProj.SOFTWARE = pDATA
					SEND_STRING vdvControl, "'PROPERTY-META,SOFTWARE,',myNECProj.SOFTWARE"
				}
			}
		}
	}
}
DEFINE_FUNCTION CHAR[20] fnGetModelName(){
	STACK_VAR CHAR pNAME[50]
	pNAME = 'UNKNOWN'
	SWITCH(myNECProj.PROJ_TYPE[1]){
		CASE $01:{
			SWITCH(myNECProj.PROJ_TYPE[2]){
				CASE $00:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $03:pNAME = 'MT106X'
					}
				}
			}
		}
		CASE $15:{
			SWITCH(myNECProj.PROJ_TYPE[2]){
				CASE $03:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $22:pNAME = 'NP-PA500U'
					}
				}
			}
		}
		CASE $20:{
			SWITCH(myNECProj.PROJ_TYPE[2]){
				CASE $03:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $11:pNAME = 'NP-UM351W'
					}
				}
			}
		}
		CASE $21:{
			SWITCH(myNECProj.PROJ_TYPE[2]){
				CASE $00:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $11:pNAME = 'NP-PA622U';myNECProj.ALT_INPUTS = TRUE
						CASE $12:pNAME = 'NP-PA551U+';myNECProj.ALT_INPUTS = TRUE
					}
				}
				CASE $01:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $10:pNAME = 'NP-PA521U';myNECProj.ALT_INPUTS = TRUE
						CASE $11:pNAME = 'NP-PA522U';myNECProj.ALT_INPUTS = TRUE
					}
				}
			}
		}
		CASE $22:{
			SWITCH(myNECProj.PROJ_TYPE[2]){
				CASE $00:{
					SWITCH(myNECProj.PROJ_TYPE[3]){
						CASE $00:pNAME = 'NP-M403H';myNECProj.ALT_INPUTS = TRUE
					}
				}
			}
		}
	}
	RETURN pNAME
}
DEFINE_FUNCTION CHAR[20] fnGetInput(){
	STACK_VAR CHAR pNAME[50]
	pNAME = 'UNKNOWN'
	SWITCH(myNECProj.INPUT_TERM[2]){
		CASE $01:{
			SWITCH(myNECProj.INPUT_TERM[1]){
				CASE $01:pNAME = 'RGB'
			}
		}
		CASE $06:{
			SWITCH(myNECProj.INPUT_TERM[1]){
				CASE $01:pNAME = 'HDMI1'
				CASE $02:pNAME = 'HDMI2'
			}
		}
		CASE $21:{
			SWITCH(myNECProj.INPUT_TERM[1]){
				CASE $01:pNAME = 'HDMI1'
				CASE $02:pNAME = 'HDMI2'
			}
		}
		CASE $22:{
			SWITCH(myNECProj.INPUT_TERM[1]){
				CASE $01:pNAME = 'DPORT'
			}
		}
	}
	RETURN pNAME
}
/******************************************************************************
	Physical Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myNECProj.DISABLED){
			IF(myNECProj.isIP){
				fnDebug('CONN->NECP',"myNECProj.IP,':',ITOA(myNECProj.PORT)",FALSE)
				bConnOpen 	= TRUE
				fnDebug('AMX->NECP',cToSend,TRUE)
				SEND_STRING dvDevice, cToSend
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(myNECProj.isIP && !myNECProj.DISABLED){
			bConnOpen = FALSE
			cToSend = ''
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
				TIMELINE_KILL(TLID_TIMEOUT)
			}
		}
	}
	ONERROR:{
		IF(myNECProj.isIP && !myNECProj.DISABLED){
			STACK_VAR CHAR MSG[50]

			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){
				TIMELINE_KILL(TLID_TIMEOUT)
			}
			fnDebug('NEC IP Error',ITOA(DATA.NUMBER),FALSE)
			SWITCH(DATA.NUMBER){
				CASE 2: {MSG = 'General Failure'}					//General Failure - Out Of Memory
				CASE 4: {MSG = 'Unknown Host'}						//Unknown Host
				CASE 6: {MSG = 'Conn Refused'}						//Connection Refused
				CASE 7: {MSG = 'Conn Timed Out'}					//Connection Timed Out
				CASE 8: {MSG = 'Unknown'}							//Unknown Connection Error
				CASE 9: {MSG = 'Already Closed'}					//Already Closed
				CASE 10:{MSG = 'Binding Error'} 					//Binding Error
				CASE 11:{MSG = 'Listening Error'} 				//Listening Error
				CASE 14:{MSG = 'Local Port Already Used'}		//Local Port Already Used
				CASE 15:{MSG = 'UDP Socket Already Listening'} //UDP socket already listening
				CASE 16:{MSG = 'Too many open Sockets'}			//Too many open sockets
				CASE 17:{MSG = 'Local port not Open'}			//Local Port Not Open
			}
			SWITCH(DATA.NUMBER){
				CASE 14:
				CASE 15:{}
				DEFAULT:{
					bConnOpen = FALSE
					cToSend = ''
				}
			}
			fnDebug('NEC Err',MSG,FALSE)
		}
	}
	STRING:{
		IF(!myNECProj.DISABLED){
			fnDebug('NEC->AMX',DATA.TEXT,TRUE)
			fnProcessFeedback(fnStripCharsRight(DATA.TEXT,1))
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
/******************************************************************************
	Virtual Device Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'NEC':
							CASE 'TRUE':myNECProj.DISABLED = FALSE
							DEFAULT:		myNECProj.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myNECProj.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'TEST':{
					STACK_VAR INTEGER p1
					STACK_VAR INTEGER p2
					p1 = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
					p2 = ATOI(DATA.TEXT)
					fnSendCommand("$00,$D0,$00,$00,$02,p1,p2")
				}
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							IF(myNECProj.isIP){
								myNECProj.IP = DATA.TEXT
								TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
						}
						CASE 'ID':{
							myNECProj.ID = ATOI(DATA.TEXT)
						}
						CASE 'BAUD':{
							myNECProj.BAUD = ATOI(DATA.TEXT)
						}
						CASE 'DEBUG':{ myNECProj.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE') }
						CASE '1WAY':{	myNECProj.is1Way = (DATA.TEXT == 'TRUE') }
					}
				}
				CASE 'CONNECT':{
					SWITCH(DATA.TEXT){
						CASE 'CLOSE':	fnCloseConnection()
						CASE 'OPEN':	fnOpenConnection()
					}
				}
				CASE 'VMUTE':{
					IF(myNECProj.POWER){
						SWITCH(DATA.TEXT){
							CASE 'ON':{	 myNECProj.VID_MUTE = TRUE }
							CASE 'OFF':{ myNECProj.VID_MUTE = FALSE; }
							CASE 'TOG':
							CASE 'TOGGLE':{myNECProj.VID_MUTE = !myNECProj.VID_MUTE}
						}
						SWITCH(myNECProj.VID_MUTE){
							CASE TRUE:{	 	fnSendCommand("$02,$10,$00,$00,$00") }
							CASE FALSE:{	fnSendCommand("$02,$11,$00,$00,$00") }
						}
					}
				}
				CASE 'FREEZE':{
					IF(myNECProj.POWER){
						SWITCH(myNECProj.FREEZE){
							CASE 'ON':{	 	myNECProj.FREEZE = TRUE; }
							CASE 'OFF':{	myNECProj.FREEZE = FALSE; }
							CASE 'TOG':
							CASE 'TOGGLE':{myNECProj.FREEZE = !myNECProj.FREEZE}
						}
						SWITCH(myNECProj.FREEZE){
							CASE TRUE:{	 fnSendCommand("$01,$98,$00,$00,$01,$01") }
							CASE FALSE:{ fnSendCommand("$01,$98,$00,$00,$01,$02") }
						}
					}
				}
				CASE 'OSD':{
					IF(DATA.TEXT = 'ON') 	fnSendCommand("$02,$14,$00,$00,$00")
					IF(DATA.TEXT = 'OFF') 	fnSendCommand("$02,$15,$00,$00,$00")
				}
				CASE 'ASPECT':{
					SWITCH(DATA.TEXT){
						CASE '4x3':		fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$00,$00")
						CASE '16x9':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$02,$00")
						CASE '15x9':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$0D,$00")
						CASE '16x10':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$0C,$00")
						CASE 'LETTER':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$01,$00")
						CASE 'AUTO':	fnSendCommand("$02,$0F,$00,$00,$03,$05,$00")
					}
				}
				CASE 'ADJUST':{
					SWITCH(DATA.TEXT){
						CASE 'AUTO':		fnSendCommand("$02,$0F,$00,$00,$02,$05,$00")
					}
				}
				CASE 'VOLUME':{
					SWITCH(DATA.TEXT){
						//CASE 'DEC':	fnSendCommand("$03,$10,$00,$00,$05,$05,$00,$01,5,$00")
						//CASE 'INC':	fnSendCommand("$03,$10,$00,$00,$05,$05,$00,$01,5,$00")
						DEFAULT:
							IF(!TIMELINE_ACTIVE(TLID_VOL)){
								myNECProj.VOL = ATOI(DATA.TEXT)
								fnSendCommand("$03,$10,$00,$00,$05,$05,$00,$00,myNECProj.VOL,$00")
								TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myNECProj.LAST_VOL = ATOI(DATA.TEXT)
								myNECProj.VOL_PEND = TRUE
							}
					}
				}
				CASE 'MUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON': 		myNECProj.AUD_MUTE = TRUE
						CASE 'OFF':		myNECProj.AUD_MUTE = FALSE
						CASE 'TOGGLE':	myNECProj.AUD_MUTE = !myNECProj.AUD_MUTE
					}
					SWITCH(myNECProj.AUD_MUTE){
						CASE TRUE:  fnSendCommand("$02,$12,$00,$00,$00,$14")
						CASE FALSE: fnSendCommand("$02,$13,$00,$00,$00,$15")
					}
				}
				CASE '3DMODE':{
					// Requires ID - third hex - to be 1 or more
					SWITCH(DATA.TEXT){
						CASE 'OFF':  	fnSendCommand("$03,$B1,myNECProj.ID,$10,$02,$CD,$00")
						CASE 'LEFT': 	fnSendCommand("$03,$B1,myNECProj.ID,$10,$02,$CD,$01")
						CASE 'RIGHT': 	fnSendCommand("$03,$B1,myNECProj.ID,$10,$02,$CD,$02")
					}
				}
				CASE 'INPUT':{
					myNECProj.desINPUT = DATA.TEXT
					IF(myNECProj.POWER){
						fnSendInputCommand(myNECProj.desINPUT)
						myNECProj.FREEZE = FALSE;
					}
					ELSE{
						fnSendInputCommand(myNECProj.desINPUT)
						WAIT 10{
							SEND_COMMAND vdvControl, 'POWER-ON'
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':{
							fnSendCommand("$02,$00,$00,$00,$00")
							IF(!myNECProj.POWER && !bWarming && !bCooling){
								bWarming = TRUE;
								TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
							}
						}
						CASE 'OFF':{
							fnSendCommand("$02,$01,$00,$00,$00")
							IF(myNECProj.POWER){
								myNECProj.POWER 	= FALSE;
								myNECProj.VID_MUTE 	= FALSE;
								myNECProj.FREEZE 	= FALSE;
								bCooling = TRUE;
								TIMELINE_CREATE(TLID_BUSY,TLT_SECOND,LENGTH_ARRAY(TLT_SECOND),TIMELINE_ABSOLUTE,TIMELINE_REPEAT);
							}
						}
						CASE 'TOGGLE':{
							myNECProj.POWER = !myNECProj.POWER
							SWITCH(myNECProj.POWER){
								CASE TRUE:	fnSendCommand("$02,$00,$00,$00,$00")
								CASE FALSE:	fnSendCommand("$02,$01,$00,$00,$00")
							}
						}
					}
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myNECProj.VOL_PEND){
		myNECProj.VOL = myNECProj.LAST_VOL
		fnSendCommand("$03,$10,$00,$00,$05,$05,$00,$00,myNECProj.VOL,$00")
		myNECProj.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_PROGRAM{
	IF(!myNECProj.DISABLED){
		SEND_LEVEL vdvControl,1,myNECProj.VOL
		[vdvControl,199] = ( myNECProj.AUD_MUTE )

		[vdvControl,251] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )
		[vdvControl,252] 	= ( TIMELINE_ACTIVE(TLID_COMMS) )

		[vdvControl,chnPOWER] 	= ( myNECProj.POWER )
		[vdvControl,chnCOOL]  	= ( bCooling )
		[vdvControl,chnWARM]  	= ( bWarming )
		[vdvControl,chnFreeze] 	= ( myNECProj.FREEZE )
		[vdvControl,chnPicMute] = ( myNECProj.VID_MUTE )
	}
}

/******************************************************************************
	Poll / Comms Timelines & Events
******************************************************************************/
	(** Activated on each Poll interval **)
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}
	(** Close connection after X amount of inactivity **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(bConnOpen){
		fnCloseConnection()
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myNECProj.DISABLED){
		IF(!myNECProj.isIP){
			SEND_COMMAND dvDevice,'SET MODE DATA'
			IF(!myNECProj.BAUD){myNECProj.BAUD = 38400}
			SEND_COMMAND dvDevice,"'SET BAUD ',ITOA(myNECProj.BAUD),' N,8,1 485 DISABLE'"
		}
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,VideoProjector'
		SEND_STRING vdvControl,'PROPERTY-META,MAKE,NEC'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2|DPORT|VGA1|VGA2'
		fnPoll()
		fnInitPoll()
	}
}
/******************************************************************************
	Projector Warming / Cooling
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BUSY]{
	IF(bWarming && (ProjectorTimeWarm == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
		myNECProj.POWER = TRUE;			// Power
		bWarming = FALSE;		// Warming Up
		IF(LENGTH_ARRAY(myNECProj.desINPUT)){
			fnSendInputCommand(myNECProj.desINPUT) // Send an Input Command if required
		}
	}
	ELSE IF(bCooling && (ProjectorTimeCool == TIMELINE.REPETITION) ){
		IF(TIMELINE_ACTIVE(TLID_BUSY)){ TIMELINE_KILL(TLID_BUSY); }
		bCooling = FALSE;		// Cooling Down
	}
	IF(!bWarming && !bCooling){
		SEND_STRING vdvControl, "'TIME-0:00'"
	}
	ELSE{
		STACK_VAR LONG RemainSecs;
		STACK_VAR LONG ElapsedSecs;
		STACK_VAR CHAR TextSecs[2];
		STACK_VAR INTEGER _TotalSecs

		IF(bWarming){ _TotalSecs = ProjectorTimeWarm }
		IF(bCooling){ _TotalSecs = ProjectorTimeCool }

		ElapsedSecs = TIMELINE.REPETITION;
		RemainSecs = _TotalSecs - ElapsedSecs;

		TextSecs = ITOA(RemainSecs % 60)
		IF(LENGTH_ARRAY(TextSecs) = 1) TextSecs = "'0',Textsecs"

		SEND_STRING vdvControl, "'TIME_RAW-',ITOA(RemainSecs),':',ITOA(_TotalSecs)"
		SEND_STRING vdvControl, "'TIME-',ITOA(RemainSecs / 60),':',TextSecs"
	}
}

/******************************************************************************
	Input Control Code
	Projectors change HDMI sources between A1 and 1A model depending,
	Logic not yet worked out
******************************************************************************/
DEFINE_FUNCTION fnSendInputCommand(CHAR pINPUT[]){
	SWITCH(pINPUT){
		CASE 'VGA1':			fnSendCommand("$02,$03,$00,$00,$02,$01,$01")
		CASE 'VGA2':			fnSendCommand("$02,$03,$00,$00,$02,$01,$02")
		CASE 'VIDEO':			fnSendCommand("$02,$03,$00,$00,$02,$01,$06")
		CASE 'SVIDEO':			fnSendCommand("$02,$03,$00,$00,$02,$01,$0B")
		CASE 'VIEWER':			fnSendCommand("$02,$03,$00,$00,$02,$01,$1F")
		CASE 'NETWORK':		fnSendCommand("$02,$03,$00,$00,$02,$01,$20")
		CASE 'USB':				fnSendCommand("$02,$03,$00,$00,$02,$01,$22")
	}
	SWITCH(myNECProj.ALT_INPUTS){
		CASE TRUE:{
			SWITCH(pINPUT){
				CASE 'HDMI':
				CASE 'HDMI1':			fnSendCommand("$02,$03,$00,$00,$02,$01,$A1")
				CASE 'HDMI2':			fnSendCommand("$02,$03,$00,$00,$02,$01,$A2")
				CASE 'DPORT':			fnSendCommand("$02,$03,$00,$00,$02,$01,$A6")
			}
		}
		CASE FALSE:{
			SWITCH(pINPUT){
				CASE 'HDMI':
				CASE 'HDMI1':			fnSendCommand("$02,$03,$00,$00,$02,$01,$1A")
				CASE 'HDMI2':			fnSendCommand("$02,$03,$00,$00,$02,$01,$1B")
			}
		}
	}
	SWITCH(pINPUT){
		CASE 'VGA1':
		CASE 'VGA2':{
			IF(TIMELINE_ACTIVE(TLID_AUTOADJ)){TIMELINE_KILL(TLID_AUTOADJ)}
			TIMELINE_CREATE(TLID_AUTOADJ,TLT_AUTOADJUST,LENGTH_ARRAY(TLT_AUTOADJUST),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
	(** Auto Adjust input after source change **)
DEFINE_EVENT TIMELINE_EVENT[TLID_AUTOADJ]{
	fnSendCommand("$02,$0F,$00,$00,$02,$05,$00")
}
/******************************************************************************
	EoF
******************************************************************************/
