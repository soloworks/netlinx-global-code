MODULE_NAME='mApartConcept1'(DEV vdvControl,DEV dvRS232)
/******************************************************************************
	Set up for basic control - not zoned
******************************************************************************/
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uApartC1{
	// COMMS
	CHAR RX[200]
	INTEGER VOL_STEP
	CHAR NEW_SOURCE[1]
	// STATE
	INTEGER MULTIZONE			//
	SINTEGER MSCLVL			// Current Music Level
	SINTEGER MICLVL			// Current Mic Level
	SINTEGER MAXMSCLVL		// Max Music Level
	SINTEGER MAXMICLVL		// Min Music Level
	CHAR 	  SOURCE[1]
	INTEGER POWER
	INTEGER MUTE
	// META
	CHAR SERIAL[20]
	CHAR HWVRSN[20]
	CHAR SWVRSN[20]
}

DEFINE_CONSTANT
LONG TLID_COMMS 	= 1
LONG TLID_POLL	 	= 2
LONG TLID_STANDBY	= 3

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= {120000}
LONG TLT_POLL[]  		= { 25000}
LONG TLT_STANDBY[]  	= { 10000}

uApartC1 myApartC1
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[], CHAR pATT[],CHAR pVAL[]){
	STACK_VAR CHAR pSEND[50]
	pSEND = "pCMD,' ',pATT"
	IF(LENGTH_ARRAY(pVAL)){
		pSEND = "pSEND,' ',pVAL"
		fnInitPoll()	// is not a query
	}
	SEND_STRING dvRS232, "pSEND,$0D"
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	fnSendCommand('GET','INFO','')	// STANDBY Query
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232,myApartC1.RX
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, "'SET BAUD 19200 N 8 1 485 DISABLE'"
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(myApartC1.RX,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myApartC1.RX,"$0D,$0A",1),2))
			IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	// Check Message Type
	SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,' ',1),1)){
		CASE 'STANDBY':{
			myApartC1.POWER = (pDATA == 'OFF')
			IF(myApartC1.POWER && myApartC1.NEW_SOURCE != ''){
				fnSendCommand('SET','SELECT',"myApartC1.NEW_SOURCE")
				myApartC1.NEW_SOURCE = ''
			}
		}
		CASE 'MULTIZONE':{	//
			myApartC1.MULTIZONE = (pDATA == 'ON')
			myApartC1.POWER = TRUE
		}
		CASE 'MSCLVL':{	// Music Level
			IF(!myApartC1.MUTE){
				SWITCH(pDATA == 'OFF'){
					CASE 'OFF':	myApartC1.MSCLVL = -80
					DEFAULT:		myApartC1.MSCLVL = ATOI(pDATA)
				}
			}
		}
		CASE 'MICLVL':{	// Music Level
			SWITCH(pDATA == 'OFF'){
				CASE 'OFF':	myApartC1.MICLVL = -80
				DEFAULT:		myApartC1.MICLVL = ATOI(pDATA)
			}
		}
		CASE 'SELECT':{
			myApartC1.SOURCE = pDATA[1]
		}
		CASE 'MAXMSCLVL':{
			myApartC1.MAXMSCLVL = ATOI(pDATA)
		}
		CASE 'MAXMICLVL':{
			myApartC1.MAXMICLVL = ATOI(pDATA)
		}
		CASE 'EQTREB':{
			IF(myApartC1.SERIAL == ''){
				//fnSendCommand('GET','SERIAL','')	// SerialNo
			}
		}
		CASE 'SERIAL':{
			myApartC1.SERIAL = pDATA
			fnSendCommand('GET','HWVRSN','')	// SerialNo
		}
		CASE 'HWVRSN':{
			myApartC1.HWVRSN = pDATA
			fnSendCommand('GET','HWVRSN','')	// SerialNo
		}
		CASE 'SWVRSN':{
			myApartC1.SWVRSN = pDATA
			fnSendCommand('GET','SWVRSN','')	// SerialNo
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'RAW':{
				SEND_STRING dvRS232,"DATA.TEXT,$0D"
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myApartC1.POWER = TRUE
					CASE 'OFF':		myApartC1.POWER = FALSE
					CASE 'TOGGLE':	myApartC1.POWER = !myApartC1.POWER
				}
				SWITCH(myApartC1.POWER){
					CASE TRUE: fnSendCommand('SET','STANDBY','OFF')
					CASE FALSE:{
						fnSendCommand('SET','MSCLVL','-30')
						fnSendCommand('SET','MICLVL','-30')
						fnSendCommand('SET','STANDBY','ON')
					}
				}
			}
			CASE 'INPUT':{
				IF(myApartC1.POWER){
					fnSendCommand('SET','SELECT',DATA.TEXT)
				}
				ELSE{
					myApartC1.NEW_SOURCE = DATA.TEXT
					fnSendCommand('SET','STANDBY','OFF')	// STANDBY On
				}
			}
			CASE 'VOLUME':{
				SWITCH(DATA.TEXT){
					CASE 'INC':fnSendCommand('INC','MSCLVL','2')
					CASE 'DEC':fnSendCommand('DEC','MSCLVL','2')
					DEFAULT:	  fnSendCommand('SET','MSCLVL',DATA.TEXT)
				}
			}
			CASE 'MUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON':		myApartC1.MUTE = TRUE
					CASE 'OFF':		myApartC1.MUTE = FALSE
					CASE 'TOGGLE':	myApartC1.MUTE = !myApartC1.MUTE
				}
				SWITCH(myApartC1.MUTE){
					CASE TRUE:	fnSendCommand('SET','MSCLVL','OFF')
					CASE FALSE:	fnSendCommand('SET','MSCLVL',ITOA(myApartC1.MSCLVL))
				}
			}
		}
	}
}


DEFINE_PROGRAM{
	SEND_LEVEL vdvControl,1,myApartC1.MSCLVL
	SEND_LEVEL vdvControl,2,myApartC1.MICLVL
	[vdvControl,199] = (myApartC1.MUTE)
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myApartC1.POWER)
}