PROGRAM_NAME='StandardCodePanels'
/******************************************************************************
	Standard Panels - Variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_PANELS = 10

INTEGER addPincode = 3200
INTEGER btnPincode[] = {
	3201,3202,3203,3204,3205,3206,3207,3208,3209,3210,
	3211
}

DEFINE_CONSTANT
// Timeline IDs for Panel Reset Timeout
LONG TLID_OVERLAY_TIMEOUT00	= 20000
LONG TLID_OVERLAY_TIMEOUT01	= 20001
LONG TLID_OVERLAY_TIMEOUT02	= 20002
LONG TLID_OVERLAY_TIMEOUT03	= 20003
LONG TLID_OVERLAY_TIMEOUT04	= 20004
LONG TLID_OVERLAY_TIMEOUT05	= 20005
LONG TLID_OVERLAY_TIMEOUT06	= 20006
LONG TLID_OVERLAY_TIMEOUT07	= 20007
LONG TLID_OVERLAY_TIMEOUT08	= 20008
LONG TLID_OVERLAY_TIMEOUT09	= 20009
LONG TLID_OVERLAY_TIMEOUT10	= 20010

// Timeline IDs for Panel Lockout Timeout
LONG TLID_MENU_TIMEOUT_00 		= 20100
LONG TLID_MENU_TIMEOUT_01		= 20101
LONG TLID_MENU_TIMEOUT_02 		= 20102
LONG TLID_MENU_TIMEOUT_03 		= 20103
LONG TLID_MENU_TIMEOUT_04 		= 20104
LONG TLID_MENU_TIMEOUT_05 		= 20105
LONG TLID_MENU_TIMEOUT_06 		= 20106
LONG TLID_MENU_TIMEOUT_07 		= 20107
LONG TLID_MENU_TIMEOUT_08 		= 20108
LONG TLID_MENU_TIMEOUT_09 		= 20109
LONG TLID_MENU_TIMEOUT_10 		= 20110

// Timeline IDs for Panel Reset Timeout
LONG TLID_PINCODE_TIMEOUT00	= 20200
LONG TLID_PINCODE_TIMEOUT01	= 20201
LONG TLID_PINCODE_TIMEOUT02	= 20202
LONG TLID_PINCODE_TIMEOUT03	= 20203
LONG TLID_PINCODE_TIMEOUT04	= 20204
LONG TLID_PINCODE_TIMEOUT05	= 20205
LONG TLID_PINCODE_TIMEOUT06	= 20206
LONG TLID_PINCODE_TIMEOUT07	= 20207
LONG TLID_PINCODE_TIMEOUT08	= 20208
LONG TLID_PINCODE_TIMEOUT09	= 20209
LONG TLID_PINCODE_TIMEOUT10	= 20210

DEFINE_TYPE STRUCTURE uStandardCodePanels{

	LONG 		TLT_MENU_TIMEOUT[MAX_PANELS][1]
	// Unlock Panel Varibales
	INTEGER  UNLOCK_REQUIRED[MAX_PANELS]
	CHAR     CODE_ENTER[MAX_PANELS][6]
	CHAR     CODE_UNLOCK[6]
	// User Level Login Handling
	INTEGER	USER_LEVEL[MAX_PANELS]
	CHAR     CODE_LOGIN[3][6]
}

DEFINE_VARIABLE
VOLATILE uStandardCodePanels myStandardCodePanels
VOLATILE LONG TLT_OVERLAY_TIMEOUT[MAX_PANELS][1]
VOLATILE LONG TLT_PINCODE_TIMEOUT[] = {  1250 }
/******************************************************************************
	Standard Panels - Include Setup Functions
******************************************************************************/
DEFINE_FUNCTION fnSetupPanelLock(INTEGER pPanel, INTEGER pMins, INTEGER pLockEnabled){
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= MAX_PANELS; p++){
			fnSetupPanelLock(p,pMins, pLockEnabled)
		}
		RETURN
	}
	// Set the Unlock Timeout
	myStandardCodePanels.TLT_MENU_TIMEOUT[pPanel][1] = 1000*60*pMins
	// Set the Enabled flag
	myStandardCodePanels.UNLOCK_REQUIRED[pPanel] = pLockEnabled
}
/******************************************************************************
	Standard Panels - Timeouts
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tpMain,0]{
	PUSH:{
		IF(mySystem.PANEL[GET_LAST(tpMain)].OVERLAY){
			fnResetPanelTimeout(GET_LAST(tpMain),TRUE)
		}
	}
}

DEFINE_FUNCTION fnSetOverlayTimeout(INTEGER pPanel, INTEGER pMins){
	IF(!pPanel){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= MAX_PANELS; p++){
			fnSetOverlayTimeout(p,pMins)
		}
		RETURN
	}
	TLT_OVERLAY_TIMEOUT[pPanel][1] = pMins*1000*60
}

DEFINE_FUNCTION fnResetPanelTimeout(INTEGER pPanel, INTEGER pACTIVE){
	// Get local TLID for ease
	STACK_VAR LONG TLID
	TLID = pPanel+TLID_OVERLAY_TIMEOUT00
	IF(TIMELINE_ACTIVE(TLID)){ TIMELINE_KILL(TLID) }
	// Restart Timer
	IF(pACTIVE && TLT_OVERLAY_TIMEOUT[pPanel][1]){
		TIMELINE_CREATE(TLID,TLT_OVERLAY_TIMEOUT[pPanel],1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT01]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT02]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT03]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT04]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT05]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT06]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT07]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT08]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT09]
TIMELINE_EVENT[TLID_OVERLAY_TIMEOUT10]{
	fnSetupOverlay(TIMELINE.ID-TLID_OVERLAY_TIMEOUT00,OVERLAY_NONE)
}
/******************************************************************************
	Standard Panels - Data Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tpMain]{
	ONLINE:{
		fnInitPanel(GET_LAST(tpMain))
		fnInitMenuTimeout(GET_LAST(tpMain),FALSE)
	}
}
/******************************************************************************
	Interface Control - Unlock
******************************************************************************/
// Function to set menu up as function
DEFINE_FUNCTION fnSetMainMenu(INTEGER pPanel, INTEGER pMenu){
	STACK_VAR INTEGER p
	// Loop through all panels if pPanel is empty
	IF(!pPanel){
		FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
			fnSetMainMenu(p,pMenu)
		}
		RETURN
	}

	mySystem.PANEL[pPanel].MENU = pMENU
	#IF_DEFINED fnMainMenuChangeCallback
	IF(!fnMainMenuChangeCallback(pPanel)){
		fnSetupPanel(pPanel)
	}
	#END_IF
}

DEFINE_FUNCTION fnInitMenuTimeout(INTEGER pPanel,INTEGER pActive){
	IF(TIMELINE_ACTIVE(TLID_MENU_TIMEOUT_00+pPanel)){TIMELINE_KILL(TLID_MENU_TIMEOUT_00+pPanel)}

	IF(pActive && myStandardCodePanels.TLT_MENU_TIMEOUT[pPanel][1]){
		TIMELINE_CREATE(TLID_MENU_TIMEOUT_00+pPanel,myStandardCodePanels.TLT_MENU_TIMEOUT[pPanel],1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_MENU_TIMEOUT_01]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_02]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_03]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_04]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_05]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_06]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_07]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_08]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_09]
TIMELINE_EVENT[TLID_MENU_TIMEOUT_10]{
	fnInitPanel(TIMELINE.ID - TLID_MENU_TIMEOUT_00)
}

/******************************************************************************
	Standard Panels - Navigation Buttons
******************************************************************************/
DEFINE_EVENT BUTTON_EVENT[tpMain,btnMainMenu]{
	PUSH:{
		IF(mySystem.PANEL[GET_LAST(tpMain)].MENU == 0 && LENGTH_ARRAY(myStandardCodePanels.CODE_UNLOCK) && myStandardCodePanels.UNLOCK_REQUIRED[GET_LAST(tpMain)]){
			fnInitPinCode(GET_LAST(tpMain))
			#IF_DEFINED OVERLAY_UNLOCK
				fnSetupOverlay(GET_LAST(tpMain),OVERLAY_UNLOCK)
			#ELSE
				SEND_STRING 0, 'StandardCodePanels:: ERROR - OVERLAY_UNLOCK NOT DEFINED'
			#END_IF
		}
		ELSE{
			fnSetMainMenu(GET_LAST(tpMain),GET_LAST(btnMainMenu)-1)
		}

		fnInitMenuTimeout(GET_LAST(tpMain),TRUE)
	}
}

DEFINE_EVENT BUTTON_EVENT[tpMain,btnOverlayClose]{
	RELEASE:{
		fnSetupOverlay(GET_LAST(tpMain),OVERLAY_NONE)
		fnResetPanelTimeout(GET_LAST(tpMain),FALSE)
	}
}

DEFINE_EVENT BUTTON_EVENT[tpMain,btnOverlaySelect]{
	PUSH:{
		#IF_DEFINED OVERLAY_LOGIN
			IF(GET_LAST(btnOverlaySelect) == OVERLAY_LOGIN){
				IF(myStandardCodePanels.USER_LEVEL[GET_LAST(tpMain)]){
					myStandardCodePanels.USER_LEVEL[GET_LAST(tpMain)] = 0
					fnSetupPanel(GET_LAST(tpMain))
				}
				ELSE{
					fnInitPinCode(GET_LAST(tpMain))
					fnSetupOverlay(GET_LAST(tpMain),GET_LAST(btnOverlaySelect))
					fnResetPanelTimeout(GET_LAST(tpMain),TRUE)
				}
			}
			ELSE{
				fnSetupOverlay(GET_LAST(tpMain),GET_LAST(btnOverlaySelect))
				fnResetPanelTimeout(GET_LAST(tpMain),TRUE)
			}
		#END_IF

		#IF_NOT_DEFINED OVERLAY_LOGIN
			fnSetupOverlay(GET_LAST(tpMain),GET_LAST(btnOverlaySelect))
			fnResetPanelTimeout(GET_LAST(tpMain),TRUE)
		#END_IF
	}
}
/******************************************************************************
	Standard Panels - PinCode Handling
******************************************************************************/
DEFINE_FUNCTION fnSetUnlockCode(CHAR pCODE[]){
	myStandardCodePanels.CODE_UNLOCK = pCODE
}

DEFINE_FUNCTION fnSetLoginCode(CHAR pCODE[], INTEGER pLEVEL){
	myStandardCodePanels.CODE_LOGIN[pLEVEL] = pCODE
}
DEFINE_FUNCTION fnInitPinCode(INTEGER pPanel){
	myStandardCodePanels.CODE_ENTER[pPanel] = ''
	fnUpdatePinCode(pPanel)
}
DEFINE_FUNCTION INTEGER fnGetLoginLevel(INTEGER pPanel){
	RETURN myStandardCodePanels.USER_LEVEL[pPanel]
}
DEFINE_FUNCTION fnUpdatePinCode(INTEGER pPanel){
	SEND_COMMAND tpMain[pPanel],"'^TXT-',ITOA(addPincode),',0,',fnPadLeadingChars('','*',LENGTH_ARRAY(myStandardCodePanels.CODE_ENTER[pPanel]))"
}

DEFINE_EVENT BUTTON_EVENT[tpMain,btnPincode]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tpMain)
		IF(!TIMELINE_ACTIVE(TLID_PINCODE_TIMEOUT00+p)){
			SWITCH(GET_LAST(btnPincode)){
				CASE 10: myStandardCodePanels.CODE_ENTER[p] = "myStandardCodePanels.CODE_ENTER[p],'0'"
				CASE 11: myStandardCodePanels.CODE_ENTER[p] = fnStripCharsRight(myStandardCodePanels.CODE_ENTER[p],1)
				DEFAULT: myStandardCodePanels.CODE_ENTER[p] = "myStandardCodePanels.CODE_ENTER[p],ITOA(GET_LAST(btnPincode))"
			}

			fnUpdatePinCode(p)

			#IF_DEFINED OVERLAY_LOGIN
				IF(mySystem.PANEL[p].OVERLAY == OVERLAY_LOGIN){
					IF(LENGTH_ARRAY(myStandardCodePanels.CODE_ENTER[p])){
						STACK_VAR INTEGER x
						FOR(x = 1; x <= 3; x++){
							IF(myStandardCodePanels.CODE_ENTER[p] == myStandardCodePanels.CODE_LOGIN[x]){
								myStandardCodePanels.USER_LEVEL[p] = x
								SEND_COMMAND tpMain[p],"'^TXT-',ITOA(addPincode),',0,Logged In'"
								fnInitPinCodeTimeout(p)
							}
						}
						IF(!TIMELINE_ACTIVE(TLID_PINCODE_TIMEOUT00+p) && LENGTH_ARRAY(myStandardCodePanels.CODE_ENTER[p]) == 6){
							SEND_COMMAND tpMain[p],"'^TXT-',ITOA(addPincode),',0,Not Found'"
							fnInitPinCodeTimeout(p)
						}
					}
				}
			#END_IF


			#IF_DEFINED OVERLAY_UNLOCK
				IF(mySystem.PANEL[p].OVERLAY == OVERLAY_UNLOCK){
					IF(LENGTH_ARRAY(myStandardCodePanels.CODE_ENTER[p])){
						IF(myStandardCodePanels.CODE_ENTER[p] == myStandardCodePanels.CODE_UNLOCK){
							mySystem.PANEL[p].MENU = 1
							SEND_COMMAND tpMain[p],"'^TXT-',ITOA(addPincode),',0,Unlocked'"
							fnInitPinCodeTimeout(p)
						}

						IF(!TIMELINE_ACTIVE(TLID_PINCODE_TIMEOUT00+p) && LENGTH_ARRAY(myStandardCodePanels.CODE_ENTER[p]) == 6){
							SEND_COMMAND tpMain[p],"'^TXT-',ITOA(addPincode),',0,Error'"
							fnInitPinCodeTimeout(p)
						}
					}
				}
			#END_IF
		}
	}
}

DEFINE_FUNCTION fnInitPinCodeTimeout(INTEGER pPanel){
	IF(TIMELINE_ACTIVE(TLID_PINCODE_TIMEOUT00+pPanel)){TIMELINE_KILL(TLID_PINCODE_TIMEOUT00+pPanel)}
	TIMELINE_CREATE(TLID_PINCODE_TIMEOUT00+pPanel,TLT_PINCODE_TIMEOUT,LENGTH_ARRAY(TLT_PINCODE_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT01]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT02]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT03]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT04]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT05]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT06]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT07]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT08]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT09]
TIMELINE_EVENT[TLID_PINCODE_TIMEOUT10]{
	fnSetupPanel(TIMELINE.ID - TLID_PINCODE_TIMEOUT00)
}
/******************************************************************************
	Standard Panels - Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
		STACK_VAR INTEGER b
		// Overlay Feedback
		FOR(b = 1; b <= LENGTH_ARRAY(btnOverlaySelect); b++){
			STACK_VAR INTEGER bState

			bState = (mySystem.PANEL[p].OVERLAY == b)

			#IF_DEFINED OVERLAY_LOGIN
				IF(b == OVERLAY_LOGIN){
					bState = myStandardCodePanels.USER_LEVEL[p]
				}
			#END_IF

			[tpMain[p],btnOverlaySelect[b]] = bState
		}
		// Menu Feeback
		FOR(b = 1; b <= LENGTH_ARRAY(btnMainMenu); b++){
			[tpMain[p],btnMainMenu[b]] = (mySystem.PANEL[p].MENU == b-1)
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/