MODULE_NAME='mPJLink'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	PJLink Implementation
******************************************************************************/

/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uComms{
	(** IP Comms Control **)
	INTEGER DISABLED
	INTEGER CONN_STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	(** General Comms Control **)
	CHAR 	  Tx[1000]
	CHAR 	  Rx[1000]
	INTEGER PEND
	INTEGER DEBUG
}
DEFINE_TYPE STRUCTURE uPJLink{
	// Meta Data
	CHAR 	  	INF0[20]
	CHAR 	  	INF1[20]
	CHAR 	  	INF2[20]
	CHAR	  	CLSS[20]
	CHAR	  	INST[50]
	CHAR	  	NAME[50]
	// State
	INTEGER POWR
	INTEGER INPT
	INTEGER AMUTE
	INTEGER VMUTE
	// Desired Values
	INTEGER newINPT
	INTEGER newPOWR
	INTEGER newAMUTE
	INTEGER newVMUTE
	// Comms Sertings
	uComms	COMMS
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL 		= 1		// Polling Timeline
LONG TLID_COMMS		= 2		// Comms Timeout Timeline
LONG TLID_BOOT			= 3
LONG TLID_TIMEOUT		= 4

INTEGER CONN_STATE_OFFLINE			= 0
INTEGER CONN_STATE_CONNECTING		= 1
INTEGER CONN_STATE_NEGOTIATING	= 1
INTEGER CONN_STATE_CONNECTED		= 2

INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2

INTEGER DESIRED_NONE  = 0
INTEGER DESIRED_OFF   = 1
INTEGER DESIRED_ON    = 2
/******************************************************************************
	Module Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uPJLink myPJLink

LONG TLT_POLL[]		= {15000}	// Poll every 15 seconds
LONG TLT_COMMS[]		= {90000}	// Comms is dead if nothing recieved for 60s
LONG TLT_BOOT[]		= { 5000}	// Give it 10 seconds for Boot to finish
LONG TLT_TIMEOUT[]	= { 8000}
/******************************************************************************
	Startup Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice, myPJLink.COMMS.Rx
}
/******************************************************************************
	Connection Utility Functions
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IF(!myPJLink.COMMS.DISABLED){
		SEND_STRING vdvControl,'PROPERTY-META,TYPE,Display'
		fnPoll()
	}
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(DEBUG_STD,"'Connecting to PJLink on '","myPJLink.COMMS.IP_HOST,':',ITOA(myPJLink.COMMS.IP_PORT)")
	myPJLink.COMMS.CONN_STATE = CONN_STATE_CONNECTING
	ip_client_open(ipDevice.port, myPJLink.COMMS.IP_HOST, myPJLink.COMMS.IP_PORT, IP_TCP)
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	ip_client_close(ipDevice.port);
}

// Connection Close Timeout
DEFINE_FUNCTION fnInitTimeout(){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	IF(myPJLink.COMMS.CONN_STATE != CONN_STATE_OFFLINE){
		fnCloseTCPConnection()
	}
}
/******************************************************************************
	Communication Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[],CHAR pVALUE[]){
	myPJLink.COMMS.Tx = "myPJLink.COMMS.Tx,'%1',pCMD,' ',pVALUE,$0D"
	fnSendFromQueue()
	fnInitPoll()
}
(** Send with Delays between messages **)
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myPJLink.COMMS.CONN_STATE == CONN_STATE_CONNECTED && !myPJLink.COMMS.PEND){
		IF(FIND_STRING(myPJLink.COMMS.Tx,"$0D",1)){
			STACK_VAR CHAR toSend[20]
			toSend = REMOVE_STRING(myPJLink.COMMS.Tx,"$0D",1)
			fnDebug(DEBUG_STD,'AMX->PJL',toSend)
			myPJLink.COMMS.PEND = TRUE
			SEND_STRING ipDevice, toSend
			fnInitTimeout()
		}
	}
	ELSE IF(myPJLink.COMMS.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection();
	}
}

	(** Start up the Polling Function **)
DEFINE_FUNCTION fnInitPoll(){
	IF(!myPJLink.COMMS.DISABLED){
		IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL); }
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
	(** Send Poll Command **)
DEFINE_FUNCTION fnPoll(){
	fnAddToQueue('POWR','?')
	fnAddToQueue('INPT','?')
	fnAddToQueue('AVMT','?')
	IF(!LENGTH_ARRAY(myPJLink.INF0)){ fnAddToQueue('INF0','?') }
	IF(!LENGTH_ARRAY(myPJLink.INF1)){ fnAddToQueue('INF1','?') }
	IF(!LENGTH_ARRAY(myPJLink.INF2)){ fnAddToQueue('INF2','?') }
	IF(!LENGTH_ARRAY(myPJLink.CLSS)){ fnAddToQueue('CLSS','?') }
	IF(!LENGTH_ARRAY(myPJLink.INST)){ fnAddToQueue('INST','?') }
	IF(!LENGTH_ARRAY(myPJLink.NAME)){ fnAddToQueue('NAME','?') }
}
	(** Process Feedback from Projector **)
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

	fnDebug(DEBUG_STD,'PJL->AMX',pDATA)

	IF(LEFT_STRING(pDATA,6) == 'PJLINK'){
		GET_BUFFER_STRING(pDATA,7)
		SWITCH(pDATA[1]){
			CASE '0':{
				myPJLink.COMMS.CONN_STATE = CONN_STATE_CONNECTED
			}
			CASE '1':{
				myPJLink.COMMS.CONN_STATE = CONN_STATE_NEGOTIATING
			}
			CASE 'E':{
				//fnCloseTCPConnection()
				//RETURN
			}
		}
	}
	ELSE IF(LEFT_STRING(pDATA,2) == '%1'){
		GET_BUFFER_STRING(pDATA,2)
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)){
			CASE 'INF0':myPJLink.INF0 = pDATA
			CASE 'INF1':{
				myPJLink.INF1 = pDATA
				SEND_STRING vdvControl,"'PROPERTY-META,MAKE,',myPJLink.INF1"
			}
			CASE 'INF2':{
				myPJLink.INF2 = pDATA
				SEND_STRING vdvControl,"'PROPERTY-META,MODEL,',myPJLink.INF1"
			}
			CASE 'CLSS':myPJLink.CLSS = pDATA
			CASE 'INST':myPJLink.INST = pDATA
			CASE 'NAME':myPJLink.NAME = pDATA
			CASE 'POWR':{
				IF(pDATA != 'OK'){
					myPJLink.POWR = ATOI(pDATA)
					IF(myPJLink.newPOWR != DESIRED_NONE){
						SELECT{
							ACTIVE(myPJLink.POWR == myPJLink.newPOWR-1):{myPJLink.newPOWR = DESIRED_NONE}
							ACTIVE(myPJLink.POWR == TRUE  &&  myPJLink.newPOWR == DESIRED_OFF):{ fnAddToQueue('POWR','0') }
							ACTIVE(myPJLink.POWR == FALSE &&  myPJLink.newPOWR == DESIRED_ON):{  fnAddToQueue('POWR','1')}
						}
					}
				}
				IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			CASE 'AVMT':{
				IF(pDATA != 'OK'){
					SELECT{
						ACTIVE(pDATA[1] == '1' || pDATA[1] == '3'):{ myPJLink.VMUTE = ATOI("pDATA[2]") }
						ACTIVE(pDATA[1] == '2' || pDATA[1] == '3'):{ myPJLink.AMUTE = ATOI("pDATA[2]") }
					}
					IF(myPJLink.newAMUTE != DESIRED_NONE){
						SELECT{
							ACTIVE(myPJLink.AMUTE == myPJLink.newAMUTE-1):{myPJLink.newAMUTE = DESIRED_NONE}
							ACTIVE(myPJLink.AMUTE == TRUE  &&  myPJLink.newAMUTE == DESIRED_OFF):{ fnAddToQueue('AVMT',FORMAT('%02d',myPJLink.VMUTE*10+20+0)) }
							ACTIVE(myPJLink.AMUTE == FALSE &&  myPJLink.newAMUTE == DESIRED_ON):{  fnAddToQueue('AVMT',FORMAT('%02d',myPJLink.VMUTE*10+20+1)) }
						}
					}
					IF(myPJLink.newVMUTE != DESIRED_NONE){
						SELECT{
							ACTIVE(myPJLink.VMUTE == myPJLink.newVMUTE-1):{myPJLink.newVMUTE = DESIRED_NONE}
							ACTIVE(myPJLink.VMUTE == TRUE  &&  myPJLink.newVMUTE == DESIRED_OFF):{ fnAddToQueue('AVMT',FORMAT('%02d',myPJLink.AMUTE*20+10+0)) }
							ACTIVE(myPJLink.VMUTE == FALSE &&  myPJLink.newVMUTE == DESIRED_ON):{  fnAddToQueue('AVMT',FORMAT('%02d',myPJLink.AMUTE*20+10+1)) }
						}
					}
				}
			}
			CASE 'INPT':{
				IF(pDATA == 'OK'){
					fnAddToQueue('INPT','?')
				}
				ELSE{
					myPJLink.INPT = ATOI(pDATA)
					IF(myPJLink.newINPT && myPJLink.INPT != myPJLink.newINPT){
						fnAddToQueue('INPT',ITOA(myPJLink.newINPT))
					}
					ELSE{
						myPJLink.newINPT = 0
					}
				}
			}
		}
		myPJLink.COMMS.PEND = FALSE
	}
	fnSendFromQueue()
}

/******************************************************************************
	Helper Functions - Debugging
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pLEVEL, CHAR pMSG[], CHAR pDATA[]){
	IF(myPJLink.COMMS.DEBUG >= pLEVEL)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',pMSG, ':', pDATA"
	}
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipDevice]{
	ONLINE:{

	}
	OFFLINE:{
		IF(!myPJLink.COMMS.DISABLED){
			myPJLink.COMMS.CONN_STATE 	= CONN_STATE_OFFLINE
			myPJLink.COMMS.Rx 		= ''
			myPJLink.COMMS.Tx 		= ''
			myPJLink.COMMS.PEND 	= FALSE
		}
	}
	ONERROR:{
		IF(!myPJLink.COMMS.DISABLED){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
				CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
				CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
				CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
				CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
				CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
				CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
				CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
				CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
				CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
				CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
				CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
			}
			fnDebug(DEBUG_ERR,"'PJLink IP Error:[',myPJLink.COMMS.IP_HOST,':',ITOA(myPJLink.COMMS.IP_PORT),']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
			SWITCH(DATA.NUMBER){
				CASE 14:{}
				DEFAULT:{
					myPJLink.COMMS.CONN_STATE 	= CONN_STATE_OFFLINE
					myPJLink.COMMS.Rx 		= ''
					myPJLink.COMMS.Tx 		= ''
					myPJLink.COMMS.PEND 	= FALSE
				}
			}
		}
	}
	STRING:{
		IF(!myPJLink.COMMS.DISABLED){
			WHILE(FIND_STRING(myPJLink.COMMS.Rx,"$0D",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myPJLink.COMMS.Rx,"$0D",1),1));
			}
		}
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
							CASE 'PJLINK':
							CASE 'TRUE':myPJLink.COMMS.DISABLED = FALSE
							DEFAULT:		myPJLink.COMMS.DISABLED = TRUE
						}
					}
				}
			}
		}
		IF(!myPJLink.COMMS.DISABLED){
			SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
				CASE 'PROPERTY':{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'IP': {
							IF(LENGTH_ARRAY(DATA.TEXT)){
								myPJLink.COMMS.IP_HOST = DATA.TEXT
								myPJLink.COMMS.IP_PORT = 4352
									TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
							}
							ELSE{
								myPJLink.COMMS.DISABLED = TRUE
							}
						}
						CASE 'DEBUG':{
							SWITCH(DATA.TEXT){
								CASE 'TRUE': myPJLink.COMMS.DEBUG = DEBUG_STD
								CASE 'DEV':  myPJLink.COMMS.DEBUG = DEBUG_DEV
								DEFAULT: 	 myPJLink.COMMS.DEBUG = DEBUG_ERR
							}
						}
					}
				}
				CASE 'INPUT':{
					myPJLink.newINPT = fnTextToInput(DATA.TEXT)
					IF(myPJLink.newINPT){
						SWITCH(myPJLink.POWR){
							CASE 1: fnAddToQueue('INPT',ITOA(myPJLink.newINPT))
							CASE 0: fnAddToQueue('POWR','1')
						}
					}
				}
				CASE 'POWER':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	myPJLink.newPOWR = DESIRED_ON
						CASE 'OFF': myPJLink.newPOWR = DESIRED_OFF
					}
					myPJLink.POWR = myPJLink.newPOWR-1
					fnAddToQueue('POWR',ITOA(myPJLink.POWR))
				}
				CASE 'VMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	myPJLink.newVMUTE = DESIRED_ON
						CASE 'OFF': myPJLink.newVMUTE = DESIRED_OFF
					}
					myPJLink.VMUTE = myPJLink.newVMUTE-1
					fnAddToQueue('AVMT',FORMAT('%02d',(myPJLink.AMUTE*20)+10+myPJLink.VMUTE))
				}
				CASE 'MUTE':
				CASE 'AMUTE':{
					SWITCH(DATA.TEXT){
						CASE 'ON':	myPJLink.newAMUTE = DESIRED_ON
						CASE 'OFF': myPJLink.newAMUTE = DESIRED_OFF
					}
					myPJLink.AMUTE = myPJLink.newAMUTE-1
					fnAddToQueue('AVMT',FORMAT('%02d',(myPJLink.VMUTE*10)+20+myPJLink.AMUTE))
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	IF(!myPJLink.COMMS.DISABLED){
		[vdvControl, 199] = ( myPJLink.AMUTE )
		[vdvControl, 211] = ( myPJLink.VMUTE )
		[vdvControl, 251] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 252] = (TIMELINE_ACTIVE(TLID_COMMS))
		[vdvControl, 255] = ( myPJLink.POWR )
	}
}

/******************************************************************************
	Conversion Functions
******************************************************************************/
DEFINE_FUNCTION INTEGER fnTextToInput(CHAR pInput[]){
	SWITCH(pINPUT){
		CASE 'DVI-D': 	RETURN 30
		CASE 'HDMI1': 	RETURN 31
		CASE 'HDMI2': 	RETURN 32
	}
}
DEFINE_FUNCTION CHAR[10] fnInputToText(INTEGER pInput){
	SWITCH(pINPUT){
		CASE 30:RETURN 'DVI-D'
		CASE 31:RETURN 'HDMI1'
		CASE 32:RETURN 'HDMI2'
	}
}
/******************************************************************************
	EoF
******************************************************************************/
