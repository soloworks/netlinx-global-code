MODULE_NAME='mPanasonicDisplay'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Two way monitored control module for Panasonic Screens
	NOTE: Set Property 'RxENABLE' FALSE for 1 way

Year Dependant Inputs:
SL1[A/B] for older
Newer:
SL1 - Slot
S1A - Slot 1A
S1B - Slot 1B
VD1 - Video
YP1 - Component
HM1 - HDMI
DV1 - DVI
PC1 - PC
******************************************************************************/
/******************************************************************************
	Module Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uPanaScreen{
	CHAR desINPUT[3]
	CHAR curINPUT[3]
	INTEGER curPOWER
}
/******************************************************************************
	System Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL = 2
/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_COMMS[] = {60000}
LONG TLT_POLL[]  = {10000}

INTEGER bRxENABLED = TRUE;
uPanaScreen myPanaScreen

CHAR 	cRxBuffer[1000]
INTEGER bDEBUG
/******************************************************************************
	System Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, cRxBuffer
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR cmd[]){
	SEND_STRING dvRS232, "$02,cmd,$03"
	fnInitPoll()
}
DEFINE_FUNCTION fnSendRaw(CHAR cmd[]){
	SEND_STRING dvRS232, "$02,cmd,$03"
}

DEFINE_FUNCTION fnSendQuery(){
	fnSendRaw('QPW')
}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(bDEBUG){
		SEND_STRING 0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	IF(pDATA == 'PON'){
		IF(LENGTH_ARRAY(myPanaScreen.desINPUT)){
			fnSendCommand("'IMS:',myPanaScreen.desINPUT")
		}
	}
	ELSE{
		SWITCH(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1)){
			CASE 'QPW':{
				myPanaScreen.curPOWER = ATOI(pDATA)
				IF(myPanaScreen.curPOWER){
					fnSendRaw('QMI')
				}
			}
			CASE 'QMI':{
				IF(myPanaScreen.curINPUT != pDATA){
					myPanaScreen.curINPUT = pDATA
					SEND_STRING vdvControl, "'INPUT-',myPanaScreen.curINPUT"
				}
				IF(LENGTH_ARRAY(myPanaScreen.desINPUT) && myPanaScreen.desINPUT != myPanaScreen.curINPUT){
					fnSendCommand("'IMS:',myPanaScreen.desINPUT")
				}
			}
		}
		IF(TIMELINE_ACTIVE(TLID_COMMS)){
			TIMELINE_KILL(TLID_COMMS)
		}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){
		TIMELINE_KILL(TLID_POLL)
	}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
/******************************************************************************
	Timeline Events
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendQuery();
}
DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	myPanaScreen.curPOWER = FALSE
}
/******************************************************************************
	System Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		fnSendQuery()
		IF(bRxENABLED){ fnInitPoll() }
	}
	STRING:{
		WHILE(FIND_STRING(cRxBuffer,"$03",1)){
			GET_BUFFER_CHAR(cRxBuffer)
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cRxBuffer,"$03",1),1))
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':bDEBUG = ATOI(DATA.TEXT)
					CASE 'RxENABLE':{
						bRxENABLED = (DATA.TEXT == 'TRUE')
						IF(bRxENABLED){
							fnInitPoll()
						}
						ELSE{
							IF(TIMELINE_ACTIVE(TLID_POLL)){
								TIMELINE_KILL(TLID_POLL)
							}
						}
					}
				}
			}
			CASE 'RAW':{SEND_STRING dvRS232, "$02,DATA.TEXT,$03"}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	myPanaScreen.curPOWER = TRUE;
					CASE 'OFF':	myPanaScreen.curPOWER = FALSE;
					CASE 'TOG':	myPanaScreen.curPOWER = !myPanaScreen.curPOWER
				}
				SWITCH(myPanaScreen.curPOWER){
					CASE TRUE:	fnSendCommand('PON')
					CASE FALSE:	fnSendCommand('POF')
				}
			}
			CASE 'SETUP':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'SIGTYPE':fnSendCommand("'SSU:CMP',DATA.TEXT")
				}
			}
			CASE 'OPTION':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'OSD':{
						SWITCH(DATA.TEXT){
							CASE TRUE:  fnSendCommand("'OSP:OSD1'")
							CASE FALSE: fnSendCommand("'OSP:OSD0'")
						}
					}
				}
			}
			CASE 'INPUT':{
				myPanaScreen.desINPUT = DATA.TEXT
				IF(myPanaScreen.curPOWER){
					fnSendCommand("'IMS:',myPanaScreen.desINPUT")
				}
				ELSE{
					IF(bRxENABLED){
						fnSendCommand('PON')
					}
					ELSE{
						fnSendCommand("'IMS:',myPanaScreen.desINPUT")
						WAIT 10{fnSendCommand('PON')}
						WAIT 70{fnSendCommand("'IMS:',myPanaScreen.desINPUT") }
					}
				}
			}
			CASE 'ASPECT':{
				IF(DATA.TEXT == 'TOGGLE'){
					fnSendCommand("'DAM'")
				}
				ELSE{
					fnSendCommand("'DAM:',DATA.TEXT")
				}
			}
			CASE 'AUTOSETUP':{
				SWITCH(DATA.TEXT){
					CASE 'TRUE':  fnSendCommand("'DGE:ASU1'")
					CASE 'FALSE': fnSendCommand("'DGE:ASU0'")
				}
			}
		}
	}
}
/******************************************************************************
	Feedback 
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myPanaScreen.curPOWER)
}
