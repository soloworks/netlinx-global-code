MODULE_NAME='Pioneer BDP-LX UI'(DEV tp[], DEV vdvControl[], INTEGER ActiveLink[])
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 07/19/2013  AT: 14:47:10        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
BUTTON_REFS
PLAY 			- 1
STOP 			- 2
PAUSE 		- 3
NEXT			- 4
PREVIOUS		- 5
SFWD 			- 6
SREV 			- 7
MENU 			- 44
MENU UP		- 45
MENU DN 		- 46
MENU LT		- 47
MENU RT		- 48
MENU SEL		- 49
DISPLAY  	- 99
SUBTITLE		- 100
RETURN 		- 104
TITLE(Home) - 114
TOP MENU 	- 115

RED			= 200
GREEN			= 201
YELLOW		= 202
BLUE			= 203


******************************************************************************/

DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		STACK_VAR INTEGER iTP
		STACK_VAR INTEGER iBP
		LOCAL_VAR INTEGER UTC
		iTP = GET_LAST(tp)
		iBP = Activelink[iTP]
		IF(iBP != 0){
			SWITCH(BUTTON.INPUT.CHANNEL){
				CASE 1:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-PLAY'
				CASE 2:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-STOP'
				CASE 3:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-PAUSE'
				CASE 4:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-SKIP+'
				CASE 5:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-SKIP-'
				CASE 6:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-SCAN+'
				CASE 7:		SEND_COMMAND vdvControl[iBP], 'TRANSPORT-SCAN-'
				CASE 44:		SEND_COMMAND vdvControl[iBP], 'MENU-POPUP'
				CASE 45:		SEND_COMMAND vdvControl[iBP], 'MENU-UP'
				CASE 46:		SEND_COMMAND vdvControl[iBP], 'MENU-DOWN'
				CASE 47:		SEND_COMMAND vdvControl[iBP], 'MENU-LEFT'
				CASE 48:		SEND_COMMAND vdvControl[iBP], 'MENU-RIGHT'
				CASE 49:		SEND_COMMAND vdvControl[iBP], 'MENU-ENTER'
				CASE 99:		SEND_COMMAND vdvControl[iBP], 'MENU-DISPLAY'
				CASE 100:	SEND_COMMAND vdvControl[iBP], 'MENU-SUBTITLE'
				CASE 104:	SEND_COMMAND vdvControl[iBP], 'MENU-RETURN'
				CASE 114:	SEND_COMMAND vdvControl[iBP], 'MENU-HOME'
				CASE 115:	SEND_COMMAND vdvControl[iBP], 'MENU-TOP'
				CASE 201:	SEND_COMMAND vdvControl[iBP], 'MENU-RED'
				CASE 202:	SEND_COMMAND vdvControl[iBP], 'MENU-GREEN'
				CASE 203:	SEND_COMMAND vdvControl[iBP], 'MENU-YELLOW'
				CASE 204:	SEND_COMMAND vdvControl[iBP], 'MENU-BLUE'
				CASE 501:	{
					SWITCH(UTC){
						CASE 0:SEND_COMMAND vdvControl[iBP], 'TIME-ELAPSE'
						CASE 1:SEND_COMMAND vdvControl[iBP], 'TIME-REMAIN'
					}
					UTC = !UTC
				}
			}
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	STRING:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'TIME':{
				STACK_VAR INTEGER p
				FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
					IF(GET_LAST(vdvControl) == Activelink[p]){
						SEND_COMMAND tp[p],"'^TXT-1,0,',DATA.TEXT"
					}
				}
			}
		}
	}
}