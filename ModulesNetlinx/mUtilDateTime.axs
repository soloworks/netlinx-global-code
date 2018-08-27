MODULE_NAME='mUtilDateTime'(DEV tp[])
INCLUDE 'CustomFunctions'
/******************************************************************************
	Interface Constants
******************************************************************************/
DEFINE_CONSTANT
(** Addresses for Interface **)
INTEGER lvlSplitMIN[]  	= {1,2}
INTEGER lvlSplitHOUR[] 	= {3,4}
INTEGER lvlSplitDATE[] 	= {5,6}
INTEGER lvlSplitMONTH[]	= {7,8}
INTEGER chnIsAM			= 9
INTEGER lvlMIN		 		= 10
INTEGER lvlHOUR			= 11
INTEGER lvlDATE			= 12
INTEGER lvlMONTH			= 13
(**  **)
LONG TLID_POLL	= 1
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
SINTEGER lastMIN
SINTEGER lastSplitMIN[2]
SINTEGER lastHOUR
SINTEGER lastSplitHOUR[2]
SINTEGER lastDATE
SINTEGER lastSplitDATE[2]
SINTEGER lastMONTH
SINTEGER lastSplitMONTH[2]

INTEGER bUse12Hr
LONG TLT_POLL[] = {15000}
/******************************************************************************
	Helpers
******************************************************************************/
DEFINE_FUNCTION fnSendMin(INTEGER pPanel){
	IF(pPanel){
		fnSendMin_INT(pPanel)
	}
	ELSE{
		STACK_VAR INTEGER p;
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendMin_INT(p)
		}
	}
}
DEFINE_FUNCTION fnSendMin_INT(INTEGER pPanel){
	SEND_LEVEL 	 tp[pPanel],lvlMIN,lastMIN
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlMin),',0,',ITOA(lastMin)"
	SEND_LEVEL   tp[pPanel],lvlSplitMIN[1],lastSplitMin[1]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitMIN[1]),',0,',ITOA(lastSplitMin[1])"
	SEND_LEVEL   tp[pPanel],lvlSplitMIN[2],lastSplitMin[2]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitMIN[2]),',0,',ITOA(lastSplitMin[2])"
}
DEFINE_FUNCTION fnSendHOUR(INTEGER pPanel){
	IF(pPanel){
		fnSendHOUR_INT(pPanel)
	}
	ELSE{
		STACK_VAR INTEGER p;
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendHOUR_INT(p)
		}
	}
}
DEFINE_FUNCTION fnSendHOUR_INT(INTEGER pPanel){
	SEND_LEVEL 	 tp[pPanel],lvlHOUR,lastHOUR
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlHOUR),',0,',ITOA(lastHOUR)"
	SEND_LEVEL   tp[pPanel],lvlSplitHOUR[1],lastSplitHOUR[1]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitHOUR[1]),',0,',ITOA(lastSplitHOUR[1])"
	SEND_LEVEL   tp[pPanel],lvlSplitHOUR[2],lastSplitHOUR[2]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitHOUR[2]),',0,',ITOA(lastSplitHOUR[2])"
}
DEFINE_FUNCTION fnSendDATE(INTEGER pPanel){
	IF(pPanel){
		fnSendDATE_INT(pPanel)
	}
	ELSE{
		STACK_VAR INTEGER p;
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendDATE_INT(p)
		}
	}
}
DEFINE_FUNCTION fnSendDATE_INT(INTEGER pPanel){
	SEND_LEVEL 	 tp[pPanel],lvlDATE,lastDATE
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlDATE),',0,',ITOA(lastDATE)"
	SEND_LEVEL   tp[pPanel],lvlSplitDATE[1],lastSplitDATE[1]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitDATE[1]),',0,',ITOA(lastSplitDATE[1])"
	SEND_LEVEL   tp[pPanel],lvlSplitDATE[2],lastSplitDATE[2]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitDATE[2]),',0,',ITOA(lastSplitDATE[2])"
}
DEFINE_FUNCTION fnSendMONTH(INTEGER pPanel){
	IF(pPanel){
		fnSendMONTH_INT(pPanel)
	}
	ELSE{
		STACK_VAR INTEGER p;
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			fnSendMONTH_INT(p)
		}
	}
}
DEFINE_FUNCTION fnSendMONTH_INT(INTEGER pPanel){
	SEND_LEVEL 	 tp[pPanel],lvlMONTH,lastMONTH
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlMONTH),',0,',ITOA(lastMONTH)"
	SEND_LEVEL   tp[pPanel],lvlSplitMONTH[1],lastSplitMONTH[1]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitMONTH[1]),',0,',ITOA(lastSplitMONTH[1])"
	SEND_LEVEL   tp[pPanel],lvlSplitMONTH[2],lastSplitMONTH[2]
	SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(lvlSplitMONTH[2]),',0,',ITOA(lastSplitMONTH[2])"
}
DEFINE_FUNCTION fnProcess(){
	STACK_VAR CHAR temp[2]
	IF(lastMIN != TIME_TO_MINUTE(TIME)){
		lastMIN = TIME_TO_MINUTE(TIME)
		temp = fnPadLeadingChars(ITOA(lastMin),'0',2)
		lastSplitMIN[1] = ATOI(LEFT_STRING(temp,1))
		lastSplitMIN[2] = ATOI(RIGHT_STRING(temp,1))
		fnSendMin(0)
	}
	IF(lastHOUR != TIME_TO_HOUR(TIME)){
		lastHOUR = TIME_TO_HOUR(TIME)
		IF(!bUse12Hr && lastHOUR > 12){
			lastHOUR = lastHOUR - 12
		}
		IF(!bUse12Hr && lastHOUR == 0){
			lastHOUR = 12
		}
		temp = fnPadLeadingChars(ITOA(lastHour),'0',2)
		lastSplitHour[1] = ATOI(LEFT_STRING(temp,1))
		lastSplitHour[2] = ATOI(RIGHT_STRING(temp,1))
		fnSendHour(0)
	}
	IF(lastDATE != DATE_TO_DAY(DATE)){
		lastDATE = DATE_TO_DAY(DATE)
		temp = fnPadLeadingChars(ITOA(lastDate),'0',2)
		lastSplitDate[1] = ATOI(LEFT_STRING(temp,1))
		lastSplitDate[2] = ATOI(RIGHT_STRING(temp,1))
		fnSendDate(0)
	}
	IF(lastMONTH != DATE_TO_MONTH(DATE)){
		lastMONTH = DATE_TO_MONTH(DATE)
		temp = fnPadLeadingChars(ITOA(lastMonth),'0',2)
		lastSplitMonth[1] = ATOI(LEFT_STRING(temp,1))
		lastSplitMonth[2] = ATOI(RIGHT_STRING(temp,1))
		fnSendMonth(0)
	}	
}
/******************************************************************************
	Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		fnSendMin(GET_LAST(tp))
		fnSendHour(GET_LAST(tp))
		fnSendDate(GET_LAST(tp))
		fnSendMonth(GET_LAST(tp))
	}
}
DEFINE_START{
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	fnProcess()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnProcess()
}
DEFINE_PROGRAM{
	[tp,chnIsAM] = (lastHOUR < 12 && bUse12Hr)
}