MODULE_NAME='mTimeEvents'(DEV vdvControl, DEV tp[])
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 07/22/2013  AT: 19:38:23        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Control Ltd (www.solocontrol.co.uk)
	
	Module for management of automatic events such as Shutdown
	Interface ports for adjusting values via interface if required
	Times in Mins
	Module capable of 20 independant events & Panels
	
	Commands to Control Device:
	SET-X,0:00	- X = EventID | 0:00 = Time
	GET-X			- Report current time for Event X as 'TIME'
	WARN-X,00	- Set warning event 00 before alarm
	TPLINK-Y,X	- Set TP Index Y to control EventID X
	PREVENT-X,0|1	- Disable Event for next occurance only
	ACTIVE-X,0|1- Activate / Deactivate

	Strings from Control Device:
	TIME-X,0:00,00	- X = EventID | 0:00 = Time | 00 = WARN TIME
	WARN-X		- Warning Event for EventID X
	EVENT-X		- EventID X Triggered
	
	Feedback Channels on Control Device:
	1-20			- Event Active/InActive
	21-40			- Prevent Active / Inactive
	Feedback Channels on Panel Device:
	1-20			- Current Controlled Event
	255			- Event Active
	
	
	
******************************************************************************/
/******************************************************************************
	Interface Addresses
******************************************************************************/
DEFINE_CONSTANT
INTEGER lblTime				= 1		// Shows Current Event Time
/******************************************************************************
	Interface Buttons
******************************************************************************/
DEFINE_CONSTANT
INTEGER btnActive 			= 50		// Auto Shutdown active - Toggle
INTEGER btnTimeINC 			= 51		// Button to Increase current Value
INTEGER btnTimeDEC			= 52		// Button to Decrease current Value
INTEGER btnSelMin 			= 53		// Button to select Mins as current Field
INTEGER btnSelHour			= 54		// Button to select Hours as current Field
INTEGER btnSetTime 			= 55		// Button to 'Pick' current time
/******************************************************************************
	Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uEVENT{
	CHAR 		tALARM[8]		// Current Set Event Time
	INTEGER 	bACTIVE			// Current Active State
	INTEGER  iWARN				// Mins for Alert (0 = No Alert)
	INTEGER	bPREVENT			// Don't trigger this time. Consume this.
	INTEGER	bTriggered		// Has been triggered 
	INTEGER  bWarned			// Has Warning Happened
}
DEFINE_TYPE STRUCTURE uPANEL{
	SINTEGER iHOUR				// Current Panel Hour Value
	SINTEGER iMIN				// Current Panel Min Value
	INTEGER bEditHours		// Which Field
	INTEGER iEVENT				// Current Linked Event
}
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER iEvents 	= 3;
INTEGER iPanels 	= 5;
LONG TLID_POLL		= 1;	// Timeline ID for Event Tester
/******************************************************************************
	Module Variables
	NOTE: Module variables don't act as Persistent so require main
	code to store & recall on startup
******************************************************************************/
DEFINE_VARIABLE
uEVENT myEVENTS[iEvents];
uPANEL myPANELS[iPanels];
INTEGER DEBUG 		= 0;
LONG TLT_POLL[] 	= {10000};			// Interval between tests (55 seconds)
/**************************************************************************
	Utility Functions
**************************************************************************/
DEFINE_FUNCTION fnInitPanel(INTEGER pPANEL){
	fnUpdatePanel(pPANEL);
	SEND_COMMAND tp[pPANEL], "'^TXT-',ITOA(lblTime),',0,',fnStripCharsRight(myEVENTS[myPANELS[pPANEL].iEVENT].tALARM,3)"
}
DEFINE_FUNCTION fnUpdatePanel(INTEGER pPANEL){
	SEND_COMMAND tp[pPANEL], "'^TXT-',ITOA(btnSelHour),',0,',fnPadLeadingChars(ITOA(myPANELS[pPANEL].iHOUR),'0',2)"
	SEND_COMMAND tp[pPANEL], "'^TXT-',ITOA(btnSelMin),',0,', fnPadLeadingChars(ITOA(myPANELS[pPANEL].iMIN),'0',2)"
}
DEFINE_FUNCTION fnEventUpdated(INTEGER pEVENT){	
	STACK_VAR INTEGER x;
	FOR(x = 1; x <= LENGTH_ARRAY(tp); x++){
		IF(myPANELS[x].iEVENT == pEVENT){
			SEND_COMMAND tp[x], "'^TXT-',ITOA(lblTime),',0,',fnStripCharsRight(myEVENTS[pEVENT].tALARM,3)"
		}
	}
}
DEFINE_FUNCTION fnAdjustTime(INTEGER pPANEL,SINTEGER pVAL, INTEGER bIsHours){
	SWITCH(bIsHours){
		CASE TRUE:  myPANELS[pPANEL].iHOUR = myPANELS[pPANEL].iHOUR + pVAL;
		CASE FALSE: myPANELS[pPANEL].iMIN  = myPANELS[pPANEL].iMIN  + pVAL;
	}
	IF(myPANELS[pPANEL].iHOUR > 23){ myPANELS[pPANEL].iHour = 0  }
	IF(myPANELS[pPANEL].iHOUR < 0) { myPANELS[pPANEL].iHour = 23 }
	IF(myPANELS[pPANEL].iMIN  > 59){ myPANELS[pPANEL].iMin = 0  }
	IF(myPANELS[pPANEL].iMIN  < 0) { myPANELS[pPANEL].iMin = 59 }
	fnUpdatePanel(pPANEL);
}
DEFINE_FUNCTION fnSendTime(INTEGER pEVENT){
	STACK_VAR CHAR _MSG[255];
	_MSG = "'TIME-',ITOA(pEVENT)";
	_MSG = "_MSG,',',LEFT_STRING(myEVENTS[pEVENT].tALARM,5)";
	_MSG = "_MSG,',',ITOA(myEVENTS[pEVENT].iWARN)";
	SEND_STRING vdvControl,"_MSG";
	fnEventUpdated(pEVENT)
}
/**************************************************************************
	Start / Setup Code
**************************************************************************/

/**************************************************************************
	Interface Control
**************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		STACK_VAR INTEGER p;
		p = GET_LAST(tp);
		IF(myPANELS[p].iEVENT == 0){myPANELS[p].iEVENT = 1}
		IF(myPANELS[p].iHOUR == 0) {myPANELS[p].iHOUR = 20}
		fnInitPanel(p);
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnSetTime]{
	PUSH:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		myEVENTS[myPANELS[p].iEVENT].tALARM =  fnTimeString(TYPE_CAST(myPANELS[p].iHOUR),TYPE_CAST(myPANELS[p].iMIN),0);
		myEVENTS[myPANELS[p].iEVENT].bTriggered 	= FALSE;
		myEVENTS[myPANELS[p].iEVENT].bWarned 		= FALSE;
		myEVENTS[myPANELS[p].iEVENT].bPREVENT 	= FALSE;
		fnEventUpdated(myPANELS[p].iEVENT);
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnSelMin]{
	PUSH:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		myPANELS[p].bEditHours = FALSE;
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnSelHour]{
	PUSH:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		myPANELS[p].bEditHours = TRUE;
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnTimeINC]{
	PUSH:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		fnAdjustTime(p, 1, myPANELS[p].bEditHours);
	}
	HOLD[5,REPEAT]:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		fnAdjustTime(p, 5, myPANELS[p].bEditHours);
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnTimeDEC]{
	PUSH:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		fnAdjustTime(p, -1, myPANELS[p].bEditHours);
	}
	HOLD[5,REPEAT]:{
		STACK_VAR INTEGER p; p = GET_LAST(tp);
		fnAdjustTime(p, -5, myPANELS[p].bEditHours);
	}
}	
(** Activate / DeActivate **)
DEFINE_EVENT BUTTON_EVENT[tp,btnActive]{
	PUSH:{
		myEVENTS[myPANELS[GET_LAST(tp)].iEVENT].bACTIVE = !myEVENTS[myPANELS[GET_LAST(tp)].iEVENT].bACTIVE;
	}
}
(** Feedback **)
DEFINE_PROGRAM{
	STACK_VAR INTEGER x;
	(** For each Touch Panel **)
	FOR(x = 1; x <= LENGTH_ARRAY(tp); x++){
		STACK_VAR INTEGER y;
		IF(myPANELS[x].iEVENT){
			FOR(y = 1; y <= iEvents; y++){
				[tp[x],y] = (y == myPANELS[x].iEVENT);
			}
			[tp[x],btnSelHour] =  myPANELS[x].bEditHours;
			[tp[x],btnSelMin]  = !myPANELS[x].bEditHours;
			[tp[x],btnActive]  =  myEVENTS[myPANELS[x].iEVENT].bACTIVE;
		}
	}
}
/**************************************************************************
	Device Control
**************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x;
	(** For each Event show status on Control Device **)
	FOR(x = 1; x <= iEvents; x++){
		[vdvControl,x] 	=  myEVENTS[x].bACTIVE;
		[vdvControl,x+20] =  myEVENTS[x].bPREVENT;
	}
}
/**************************************************************************
	 Handle events from Control Device
**************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	ONLINE:{
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SET':{
				STACK_VAR INTEGER i;
				i = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1));
				myEVENTS[i].tALARM 		= "DATA.TEXT,':00'";
				myEVENTS[i].bTriggered 	= FALSE;
				myEVENTS[i].bWarned 		= FALSE;
				myEVENTS[i].bPREVENT 	= FALSE;
				fnSendTime(i);
			}
			CASE 'GET':{
				fnSendTime(ATOI(DATA.TEXT));
			}
			CASE 'WARN':{
				STACK_VAR INTEGER i;
				i = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1));
				myEVENTS[i].iWARN = ATOI(DATA.TEXT);
				fnSendTime(i);
				
			}
			CASE 'TPLINK':{
				STACK_VAR INTEGER p;
				p = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1));
				myPANELS[p].iEVENT = ATOI(DATA.TEXT);
				SEND_COMMAND tp[p], "'^TXT-',ITOA(lblTime),',0,',myEVENTS[myPANELS[p].iEVENT].tALARM"
			}
			CASE 'PREVENT':{
				STACK_VAR INTEGER i;
				i = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1));
				SWITCH(DATA.TEXT){
					CASE 'TRUE': myEVENTS[i].bPREVENT = TRUE;
					CASE 'FALSE':myEVENTS[i].bPREVENT = FALSE;
					DEFAULT:		 myEVENTS[i].bPREVENT = ATOI(DATA.TEXT);
				}
			}
			CASE 'ACTIVE':{
				STACK_VAR INTEGER i;
				i = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1));
				SWITCH(DATA.TEXT){
					CASE 'TRUE': myEVENTS[i].bACTIVE = TRUE;
					CASE 'FALSE':myEVENTS[i].bACTIVE = FALSE;
					DEFAULT:		 myEVENTS[i].bACTIVE = ATOI(DATA.TEXT);
				}
			}
		}
	}
}
/******************************************************************************
	Time Event
******************************************************************************/
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	STACK_VAR INTEGER x;
	FOR(x = 1;x <= iEvents;x++){
		IF(myEVENTS[x].bACTIVE){
			IF(myEVENTS[x].iWARN){
				IF(fnTimeCompareToMin(fnSubtractSeconds(myEVENTS[x].tALARM,60*myEVENTS[x].iWARN),TIME) && (!myEVENTS[x].bWarned)){
					myEVENTS[x].bWarned = TRUE;
					SEND_STRING vdvControl, "'WARN-',ITOA(x)";
				}
			}
			IF(fnTimeCompareToMin(myEVENTS[x].tALARM,TIME) && (!myEVENTS[x].bTriggered)){
				myEVENTS[x].bTriggered = TRUE;
				IF(!myEVENTS[x].bPREVENT){
					SEND_STRING vdvControl, "'EVENT-',ITOA(x)";
				}
			}	
			IF(!fnTimeCompareToMin(myEVENTS[x].tALARM,TIME) && (myEVENTS[x].bTriggered)){
				myEVENTS[x].bTriggered 	= FALSE;
				myEVENTS[x].bPREVENT 	= FALSE;
				myEVENTS[x].bWarned 		= FALSE;
			}
		}
	}
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(DEBUG = 1){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}