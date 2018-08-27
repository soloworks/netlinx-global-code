MODULE_NAME='mTVOneCORIO'(DEV vdvControl, DEV dvRS232)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Extron RS232 Module - RMS Enabled
******************************************************************************/
DEFINE_TYPE STRUCTURE uCORIO{
	CHAR RX[1000]
	INTEGER DEBUG
	INTEGER PRESET
}
DEFINE_CONSTANT
LONG TLID_COMMS = 1
LONG TLID_POLL	 = 2
DEFINE_VARIABLE
LONG TLT_COMMS[] = {60000} 
LONG TLT_POLL[]  = {15000}

uCORIO myCORIO
/******************************************************************************
	Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(myCORIO.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pDATA[255]){
	STACK_VAR CHAR toSend[255]
	toSend = "pData,$0D"
	SEND_STRING dvRS232, toSend
	fnInitPoll()
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	//SEND_STRING dvRS232,"'routing.preset.Read',$0D"
	SEND_STRING dvRS232,"'system.comms.ethernet.IP_Address',$0D"
}
/******************************************************************************
	Device Events
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232,myCORIO.RX
}
DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 115200 N 8 1 485 DISABLE'
		fnPoll()
		fnInitPoll()
	}
	STRING:{
		WHILE(FIND_STRING(myCORIO.RX,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myCORIO.RX,"$0D,$0A",1),2))
		}
	}
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug('CORIO->', pDATA);
	IF(FIND_STRING(pDATA,'Not Logged In',1)){
		//fnSendCommand('login(admin,adminpw)')
		fnSendCommand('login(user4,user4pw)')
	}
	ELSE IF(LEFT_STRING(pDATA,5) == '!Info'){
	
	}
	ELSE{
		SWITCH(REMOVE_STRING(pDATA,'=',1)){
			CASE 'routing.preset.Read =':{
				IF(myCORIO.PRESET != ATOI(pDATA)){
					//myCORIO.PRESET = ATOI(pDATA)
					//SEND_STRING vdvControl, "'PRESET-',ITOA(myCORIO.PRESET)"
				}
			}
		}
	}
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG': myCORIO.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');
				}
			}
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'SYNC':{
						SEND_STRING vdvControl, "'PRESET-',ITOA(myCORIO.PRESET)"
					}
				}
			}
			CASE 'PRESET':{
				fnSendCommand("'copypreset(',DATA.TEXT,',0)'")
				myCORIO.PRESET = ATOI(DATA.TEXT)
				IF([vdvControl,251]){
					SEND_STRING vdvControl, "'PRESET-',ITOA(myCORIO.PRESET)"
				}
			}
			CASE 'RAW':		fnSendCommand(DATA.TEXT)
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}