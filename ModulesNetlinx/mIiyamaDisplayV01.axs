MODULE_NAME='mIiyamaDisplayV01'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Control Ltd (www.solocontrol.co.uk)
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_CONSTANT
// IP States
INTEGER CONN_STATE_OFFLINE		= 0
INTEGER CONN_STATE_CONNECTING	= 1
INTEGER CONN_STATE_CONNECTED		= 2
//
DEFINE_TYPE STRUCTURE uScreen{
	// COMMS
	INTEGER DISABLED
	INTEGER isIP
	INTEGER CONN_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER DEBUG
	INTEGER TX_PEND
	(** MetaData **)
	INTEGER ID
	CHAR	  MAKE[20]
	CHAR 	  MODEL[20]
	CHAR 	  QMODEL[20]
	CHAR 	  SCALER_FW[20]
	CHAR 	  LAN_FW[20]
	CHAR	  SERIALNO[20]
	(** Status **)
	INTEGER POWER
	CHAR 	  INPUT[10]
	INTEGER MUTE
	INTEGER VOL
	(** Status **)
	INTEGER	VOL_PEND
	INTEGER	LAST_VOL
	(** Desired Values **)
	CHAR 		desINPUT[3]
	INTEGER  desPOWER_ON
	INTEGER  desPOWER_OFF
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
(** Timelines **)
LONG TLID_POLL			= 1
LONG TLID_POWER		= 2
LONG TLID_COMMS		= 3
LONG TLID_TIMEOUT		= 4
LONG TLID_AUTOADJ 	= 5
LONG TLID_VOL			= 6
LONG TLID_BOOT			= 7
(** Default Values **)
INTEGER 	defPORT 		= 7142					// TCP Port (Blu-Ray Default)
INTEGER 	defID			= 1
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_VARIABLE
(** General **)
VOLATILE uScreen myIiyamaDisplayV01
(** Timeline Times **)
LONG TLT_POWER[]		= { 20000}
LONG TLT_POLL[]		= { 30000}
LONG TLT_COMMS[]		= { 90000}
LONG TLT_TIMEOUT[]	= {  5000}
LONG TLT_AUTOADJ[]	= {  3000}
LONG TLT_VOL[]			= {150}
LONG TLT_BOOT[]		= { 5000}
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	myIiyamaDisplayV01.isIP = !(dvDEVICE.NUMBER)
	myIiyamaDisplayV01.ID = 1
	CREATE_BUFFER dvDevice, myIiyamaDisplayV01.Rx
}
(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myIiyamaDisplayV01.DISABLED){
			IF(myIiyamaDisplayV01.isIP){
				myIiyamaDisplayV01.CONN_STATE = CONN_STATE_CONNECTED
				fnSendFromQueue()
			}
			ELSE{
				TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
	OFFLINE:{
		IF(myIiyamaDisplayV01.isIP && !myIiyamaDisplayV01.DISABLED){
			myIiyamaDisplayV01.CONN_STATE 	= CONN_STATE_OFFLINE
			myIiyamaDisplayV01.Tx 			= ''
			myIiyamaDisplayV01.TX_PEND		= FALSE
		}
	}
	ONERROR:{
		IF(myIiyamaDisplayV01.isIP && !myIiyamaDisplayV01.DISABLED){
			STACK_VAR CHAR _MSG[255]
			myIiyamaDisplayV01.CONN_STATE 	= CONN_STATE_OFFLINE
			myIiyamaDisplayV01.Tx 				= ''
			SWITCH(DATA.NUMBER){
				CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
				DEFAULT:{
					SWITCH(DATA.NUMBER){
						CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
						CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
						CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
						CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
						CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
						CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
						CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
						CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
						CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
						CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
						CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
					}
					myIiyamaDisplayV01.Tx 			= ''
					myIiyamaDisplayV01.TX_PEND		= FALSE
				}
			}
			fnDebug(TRUE,"'Iiyama IP Error:[',myIiyamaDisplayV01.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
		}
	}
	STRING:{
		IF(!myIiyamaDisplayV01.DISABLED){
			fnDebug(FALSE,'Iiyama->',DATA.TEXT);
			WHILE(FIND_STRING(myIiyamaDisplayV01.Rx,"$0D",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myIiyamaDisplayV01.Rx,"$0D",1),1))
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
		}
	}
}
(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(!LENGTH_ARRAY(myIiyamaDisplayV01.IP_HOST)){
		fnDebug(TRUE,'Iiyama IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to Iiyama on ',"myIiyamaDisplayV01.IP_HOST,':',ITOA(myIiyamaDisplayV01.IP_PORT)")
		myIiyamaDisplayV01.CONN_STATE = CONN_STATE_CONNECTING
		ip_client_open(dvDevice.port, myIiyamaDisplayV01.IP_HOST, myIiyamaDisplayV01.IP_PORT, IP_TCP)
	}
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}
/******************************************************************************
	Comms Utility Functions
******************************************************************************/
(** Polling **)
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL, TLT_POLL, LENGTH_ARRAY(TLT_POLL), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)
}
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('g',$6C,"$00,$00,$00")	// Power Status Request
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll();
}


(** Send with Delays between messages **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myIiyamaDisplayV01.isIP && myIiyamaDisplayV01.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	IF(FIND_STRING(myIiyamaDisplayV01.Tx,"$0D",1) && !myIiyamaDisplayV01.TX_PEND){
		STACK_VAR CHAR _ToSend[255]
		_ToSend = REMOVE_STRING(myIiyamaDisplayV01.Tx,"$0D",1)
		fnDebug(FALSE,'->Iiyama',_ToSend);
		SEND_STRING dvDevice, _ToSend
		myIiyamaDisplayV01.TX_PEND = TRUE
		IF(myIiyamaDisplayV01.isIP){
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
	fnInitPoll()
}
(** Drop connection after X **)
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnCloseTCPConnection();
}
(** Message Building Routine **)
DEFINE_FUNCTION fnAddToQueue(CHAR pCmdType,INTEGER pCmdCode,CHAR pDATA[]){

	STACK_VAR CHAR 	pToSend[30]

	pToSend = "fnPadLeadingChars(ITOA(myIiyamaDisplayV01.ID),'0',2),pCmdType,pCmdCode,pDATA,$0D"
	pToSend= "LENGTH_ARRAY(pToSend)+$30,pToSend"

	myIiyamaDisplayV01.Tx = "myIiyamaDisplayV01.TX,pToSend"

	fnSendFromQueue()
}
(** Debugging Helper **)
DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myIiyamaDisplayV01.DEBUG = 1 || bForce)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
(** Input Translator **)
DEFINE_FUNCTION CHAR[3] fnTextToInput(CHAR pInput[]){
	SWITCH(pINPUT){
		CASE 'VGA': 	 	RETURN '000'
		CASE 'HDMI1':  	RETURN '001'
		CASE 'HDMI2':  	RETURN '002'
		CASE 'AV':  		RETURN '003'
		CASE 'RGB':  		RETURN '004'
		CASE 'SVIDEO':  	RETURN '005'
		CASE 'DVI':  		RETURN '006'
		CASE 'DPORT':  	RETURN '007'
		CASE 'SDI':  		RETURN '008'
		CASE 'MULTI':  	RETURN '009'
	}
}
DEFINE_FUNCTION CHAR[10] fnInputToText(CHAR pInput[3]){
	SWITCH(pInput){
		CASE '000': 	 	RETURN 'VGA'
		CASE '001':  		RETURN 'HDMI1'
		CASE '002':  		RETURN 'HDMI2'
		CASE '003':  		RETURN 'AV'
		CASE '004':  		RETURN 'RGB'
		CASE '005':  		RETURN 'SVIDEO'
		CASE '006':  		RETURN 'DVI'
		CASE '007':  		RETURN 'DPORT'
		CASE '008':  		RETURN 'SDI'
		CASE '009':  		RETURN 'MULTI'
	}
}

(** Feedback Helper **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

	// Remove $0D
	fnStripCharsRight(pDATA,1)
	// Remove Length
	GET_BUFFER_STRING(pDATA,3)

	SWITCH(GET_BUFFER_CHAR(pDATA)){
		CASE $72:{
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE $6C:{	// Power Response
					myIiyamaDisplayV01.POWER = ATOI(pDATA)
					IF(myIiyamaDisplayV01.POWER){
						fnAddToQueue('g',$6A,"$00,$00,$00")	// Input Status Request
						fnAddToQueue('g',$66,"$00,$00,$00")	// Volume Request
						fnAddToQueue('g',$67,"$00,$00,$00")	// Mute Status Request
					}
					IF(!LENGTH_ARRAY(myIiyamaDisplayV01.SERIALNO)){
						fnAddToQueue('g',$20,"$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request Customer Name
						fnAddToQueue('g',$20,"$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request Customer Model Name
						fnAddToQueue('g',$20,"$03,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request Qisda Model Name
						fnAddToQueue('g',$20,"$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request Scaler Firmware Ver
						fnAddToQueue('g',$20,"$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request LAN Firmware Ver
						fnAddToQueue('g',$20,"$06,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00")	// Request Serial Number
					}
				}
				CASE $20:{	// Model Info Response
					pDATA = LEFT_STRING(pDATA,FIND_STRING(pDATA,"$00",1)-1)
					SWITCH(GET_BUFFER_CHAR(pDATA)){
						CASE $01:{	// Display Make
							IF(myIiyamaDisplayV01.MAKE != pDATA){
								myIiyamaDisplayV01.MAKE = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,MAKE,',myIiyamaDisplayV01.MAKE"
							}
						}
						CASE $02:{	// Display Model
							IF(myIiyamaDisplayV01.MODEL != pDATA){
								myIiyamaDisplayV01.MODEL = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,MODEL,',myIiyamaDisplayV01.MODEL"
							}
						}
						CASE $03:{	// Qisa Model
							IF(myIiyamaDisplayV01.QMODEL != pDATA){
								myIiyamaDisplayV01.QMODEL = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,QMODEL,',myIiyamaDisplayV01.QMODEL"
							}
						}
						CASE $04:{	// Scaler Firmware
							IF(myIiyamaDisplayV01.SCALER_FW != pDATA){
								myIiyamaDisplayV01.SCALER_FW = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,SOFTWARE,',myIiyamaDisplayV01.SCALER_FW"
							}
						}
						CASE $05:{	// LAN Firmware
							IF(myIiyamaDisplayV01.LAN_FW != pDATA){
								myIiyamaDisplayV01.LAN_FW = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,LAN_FW,',myIiyamaDisplayV01.LAN_FW"
							}
						}
						CASE $06:{	// Serial Number
							IF(myIiyamaDisplayV01.SERIALNO != pDATA){
								myIiyamaDisplayV01.SERIALNO = pDATA
								SEND_STRING vdvControl, "'PROPERTY-META,SERIALNO,',myIiyamaDisplayV01.SERIALNO"
							}
						}
					}
				}
				CASE $6A:{	// Input Source
					IF(myIiyamaDisplayV01.INPUT != fnInputToText(pDATA)){
						myIiyamaDisplayV01.INPUT = fnInputToText(pDATA)
						SEND_STRING vdvControl, "'INPUT-',myIiyamaDisplayV01.INPUT"
					}
				}
				CASE $66:{	// Volume Request
					myIiyamaDisplayV01.VOL = ATOI(pDATA)
				}
				CASE $67:{	// Mute State
					myIiyamaDisplayV01.MUTE = ATOI(pDATA)
				}
			}
		}
	}

	myIiyamaDisplayV01.TX_PEND = FALSE
	fnSendFromQueue()

	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR DATA_COPY[255]
		DATA_COPY = DATA.TEXT
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA_COPY,',',1),1)){
					CASE 'ENABLED':{
						SWITCH(DATA_COPY){
							CASE 'IIYAMA':
							CASE 'TRUE':myIiyamaDisplayV01.DISABLED = FALSE
							DEFAULT:		myIiyamaDisplayV01.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myIiyamaDisplayV01.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP':{
							IF(FIND_STRING(DATA.TEXT,':',1)){
								myIiyamaDisplayV01.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
								myIiyamaDisplayV01.IP_PORT = ATOI(DATA.TEXT)
							}
							ELSE{
								myIiyamaDisplayV01.IP_HOST = DATA.TEXT
								myIiyamaDisplayV01.IP_PORT = 4660
							}
							TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
						CASE 'ID': {	myIiyamaDisplayV01.ID = ATOI(DATA.TEXT) }
						CASE 'DEBUG':{ myIiyamaDisplayV01.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')}
					}
				}
				CASE 'TEST':{

				}
				CASE 'INPUT':{
					IF(myIiyamaDisplayV01.POWER){
						IF(fnTextToInput(DATA.TEXT) != ''){
							fnAddToQueue('s',$22,fnTextToInput(DATA.TEXT))
						}
					}
					ELSE{
						fnAddToQueue('s',$21,'001')	// Power ON
						myIiyamaDisplayV01.desINPUT = fnTextToInput(DATA.TEXT)
						IF(!TIMELINE_ACTIVE(TLID_POWER)){
							TIMELINE_CREATE(TLID_POWER,TLT_POWER,LENGTH_ARRAY(TLT_POWER),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':{ fnAddToQueue('s',$21,'001') }
						CASE 'OFF':{fnAddToQueue('s',$21,'000') }
						CASE 'TOGGLE':{
							SWITCH(myIiyamaDisplayV01.POWER){
								CASE FALSE:{ fnAddToQueue('s',$21,'001') }
								CASE TRUE:{  fnAddToQueue('s',$21,'000') }
							}
						}
					}
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POWER]{
	fnAddToQueue('s',$22,myIiyamaDisplayV01.desINPUT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_VOL]{
	IF(myIiyamaDisplayV01.VOL_PEND){
		myIiyamaDisplayV01.VOL = myIiyamaDisplayV01.LAST_VOL
		//fnAddToQueue($8C,$00,$05,"$03,$01,myIiyamaDisplayV01.VOL")
		myIiyamaDisplayV01.VOL_PEND = FALSE
		TIMELINE_CREATE(TLID_VOL,TLT_VOL,LENGTH_ARRAY(TLT_VOL),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myIiyamaDisplayV01.DISABLED){
		IF(!myIiyamaDisplayV01.isIP){
			SEND_COMMAND dvDevice, 'SET MODE DATA'
			SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
			myIiyamaDisplayV01.CONN_STATE = CONN_STATE_CONNECTED
		}
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		SEND_STRING vdvControl,'PROPERTY-META,INPUTS,HDMI1|HDMI2|DPORT|DVI|VGA'
		fnInitPoll()
	}
}
(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM{
	IF(!myIiyamaDisplayV01.DISABLED){
		SEND_LEVEL vdvControl,1,myIiyamaDisplayV01.VOL
		[vdvControl, 199] = (myIiyamaDisplayV01.MUTE)
		[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 255] = (myIiyamaDisplayV01.POWER)
	}
}
