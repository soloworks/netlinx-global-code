MODULE_NAME='mOptimaProj'(DEV vdvControl, DEV dvDevice)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 06/25/2013  AT: 11:13:18        *)
(***********************************************************)
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uOptomaProj{
	INTEGER	ID
	INTEGER	PEND
	CHAR		Tx[1000]
	CHAR 		Rx[1000]
	CHAR	 	LAST_SENT[20]

	INTEGER 	DES_SOURCE

	INTEGER	POWER
	INTEGER 	SOURCE_NO
	CHAR		SOURCE_NAME[10]
}

DEFINE_CONSTANT
LONG TLID_COMMS	= 1
LONG TLID_POLL		= 2
LONG TLID_TIMEOUT	= 3

INTEGER POLL_POWER	= 1
INTEGER POLL_SOURCE	= 2

DEFINE_VARIABLE
VOLATILE uOptomaProj myOptomaProj
LONG TLT_COMMS[] 		= {90000}
LONG TLT_POLL[]		= {15000}
LONG TLT_TIMEOUT[]	= { 5000}

DEFINE_FUNCTION fnSendCommand(CHAR pCODE[], CHAR pPARAM[],INTEGER isQuery){
	fnAddToQueue("pCODE,' ',pPARAM")
	IF(!isQuery){ fnInitPoll() }
}

DEFINE_FUNCTION fnAddToQueue(CHAR pCMD[]){
	IF(myOptomaProj.ID == 0){myOptomaProj.ID = 1}
	myOptomaProj.Tx = "'~',fnPadLeadingChars(ITOA(myOptomaProj.ID),'0',2),pCMD,$0D"
	fnSendFromQueue()
}

DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myOptomaProj.PEND){
		STACK_VAR CHAR toSend[20]
		toSend = REMOVE_STRING(myOptomaProj.Tx,"$0D",1)
		myOptomaProj.LAST_SENT = fnStripCharsRight(toSend,1)
		SEND_STRING dvDevice,toSend
		myOptomaProj.PEND = TRUE
		IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
		TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myOptomaProj.Tx = ''
	myOptomaProj.PEND = FALSE
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand('150','1',TRUE)
}

DEFINE_START{
	//CREATE_BUFFER dvDevice,myOptomaProj.Rx
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND dvDevice, 'SET MODE DATA'
		SEND_COMMAND dvDevice, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnSendCommand('150','1',FALSE)
	}
	STRING:{
		STACK_VAR INTEGER pIsResponse
		IF(FIND_STRING(DATA.TEXT,'OK',1)){
			GET_BUFFER_STRING(DATA.TEXT,2)	// Strip 'OK'
			myOptomaProj.POWER 			= ATOI("GET_BUFFER_CHAR(DATA.TEXT)")
			//myOptomaProj.LAMP_HOURS 	= GET_BUFFER_STRING(DATA.TEXT,5)
			//myOptomaProj.SOURCE_NO 		= ATOI(GET_BUFFER_STRING(DATA.TEXT,2))
			//myOptomaProj.META_FIRMWARE = GET_BUFFER_STRING(DATA.TEXT,4)
			//pIsResponse = TRUE
			
			IF(myOptomaProj.DES_SOURCE != 0 && myOptomaProj.POWER){
				fnSendCommand('12',ITOA(myOptomaProj.DES_SOURCE),FALSE)
				myOptomaProj.DES_SOURCE = 0
			}
		}
		ELSE IF(DATA.TEXT[1] == 'P' || DATA.TEXT[1] == 'F'){
			pIsResponse = TRUE
		}
		
		IF(pIsResponse){	
			myOptomaProj.PEND = FALSE
			fnSendFromQueue()
		}
		
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'ADJUST':{
				SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnSendCommand('01','1',FALSE)
				}
			}
			CASE 'INPUT':{
				SWITCH(DATA.TEXT){
					CASE 'VGA1':myOptomaProj.DES_SOURCE = 5
					CASE 'VGA2':myOptomaProj.DES_SOURCE = 6
					CASE 'VIDEO':myOptomaProj.DES_SOURCE = 10
					CASE 'HDMI1':myOptomaProj.DES_SOURCE = 1
					CASE 'HDMI2':myOptomaProj.DES_SOURCE = 15
				}
				SWITCH(myOptomaProj.POWER){
					CASE TRUE: fnSendCommand('12',ITOA(myOptomaProj.DES_SOURCE),FALSE)
					CASE FALSE:fnSendCommand('00','1',FALSE)
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnSendCommand('00','1',FALSE)
					CASE 'OFF':	fnSendCommand('00','0',FALSE)
				}
			}
		}
	}
}


DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	
	[vdvControl,255] = (myOptomaProj.POWER)
}