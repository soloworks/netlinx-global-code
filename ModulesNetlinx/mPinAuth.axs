MODULE_NAME='mPinAuth'(DEV vdvControl,DEV TP[])
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 09/04/2013  AT: 21:41:42        *)
(***********************************************************)
/******************************************************************************
	Pin Code Control module for touch panel lockout
	Provides custom interface and better feedback than AMX based
	password control
	
	vdvControl Commands (Control)
	PROPERTY-USER1,YYYY		- Changes PIN to YYYY for panel X
	PROPERTY-USER2,YYYY		- Changes PIN to YYYY for panel X
	PROPERTY-USER3,YYYY		- Changes PIN to YYYY for panel X
	PROPERTY-USER4,YYYY		- Changes PIN to YYYY for panel X
	PROPERTY-ADMIN,YYYYYY	- Changes ADMIN PIN to YYYY for panel X
	PROPERTY-POPUP,XYZXYZ	- Changes Popup name to XYZXYZ for panel X, Blank for No COntrol
	PROPERTY-PAGE,XYZXYZ	   - Changes Page name to XYZXYZ for panel X, Blank for No COntrol
	
	vdvControl Strings  (Feedback)
	PINOK-P,X		P = Panel,X = Pin OK
	PINOK-P,0		P = Panel,X = Pin Not Matched
	
	Address Numbers:
	50 - Entry Field
	51 - Admin Pin
	52 - User Pin 1
	53 - User Pin 2
	54 - User Pin 3
	55 - User Pin 4
	
	Button Numbers
	100..109 - Digits
	110 		- Delete
	121		- Start Pin Process
	131..134 - Change respective Pin
	
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_HIDE_00			= 10
LONG TLID_HIDE_01			= 11
LONG TLID_HIDE_02			= 12
LONG TLID_HIDE_03			= 13
LONG TLID_HIDE_04			= 14
LONG TLID_HIDE_05			= 15
LONG TLID_HIDE_06			= 16
LONG TLID_HIDE_07			= 17
LONG TLID_HIDE_08			= 18
LONG TLID_HIDE_09			= 19
LONG TLID_HIDE_10			= 20

LONG TLID_TIMEOUT_00		= 20
LONG TLID_TIMEOUT_01		= 21
LONG TLID_TIMEOUT_02		= 22
LONG TLID_TIMEOUT_03		= 23
LONG TLID_TIMEOUT_04		= 24
LONG TLID_TIMEOUT_05		= 25
LONG TLID_TIMEOUT_06		= 26
LONG TLID_TIMEOUT_07		= 27
LONG TLID_TIMEOUT_08		= 28
LONG TLID_TIMEOUT_09		= 29
LONG TLID_TIMEOUT_10		= 30

LONG TLT_HIDE[] 		   = { 900,1000}
LONG TLT_TIMEOUT[]      = { 30000 }

INTEGER _padPIN 		= 1
INTEGER _padADMIN		= 2
INTEGER _padNEW 		= 3
INTEGER _padCONFIRM 	= 4

/******************************************************************************
	Module Variables (Multiple lines for defaults
******************************************************************************/
DEFINE_TYPE STRUCTURE uGlobal{
	CHAR 		ADMIN_PIN[6]
	CHAR 		USER_PIN[4][4]
	CHAR 		POPUP_NAME[255]
	CHAR 		POPUP_PAGE[255]
}
DEFINE_TYPE STRUCTURE uPanel{
	CHAR CUR_ENTRY[6]
	CHAR NEW_PIN_ENTRY[4]
	INTEGER PIN_INDEX
	INTEGER KEYPAD_TYPE
}

DEFINE_VARIABLE
uGlobal myGlobal
uPanel myPinPanel[10]
DEFINE_START{
	myGlobal.ADMIN_PIN 	= '654321'
	myGlobal.USER_PIN[1] = '1988'
	myGlobal.USER_PIN[2] = ''
	myGlobal.USER_PIN[3] = ''
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnCloseKeypad(INTEGER pPanel){
	IF(TIMELINE_ACTIVE(pPanel)){ TIMELINE_KILL(pPanel+TLID_HIDE_00) }
	TIMELINE_CREATE(pPanel+TLID_HIDE_00,TLT_HIDE,LENGTH_ARRAY(TLT_HIDE),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
/******************************************************************************
	Touch Panel Keypad Events
******************************************************************************/
DEFINE_CONSTANT
INTEGER btnKeyPad[] 		= {100,101,102,103,104,105,106,107,108,109,110}
INTEGER btnClose			= 120
INTEGER btnEnterPin 		= 121
INTEGER btnChangePin[] 	= {131,132,133,134}

DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		fnTimeoutPanel(GET_LAST(tp),TRUE)
	}
}

DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
			SEND_COMMAND tp[GET_LAST(tp)], "'@PPF-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
		}
		SEND_COMMAND DATA.DEVICE,"'^TXT-51,0,',myGlobal.ADMIN_PIN"
		SEND_COMMAND DATA.DEVICE,"'^TXT-52,0,',myGlobal.USER_PIN[1]"
		SEND_COMMAND DATA.DEVICE,"'^TXT-53,0,',myGlobal.USER_PIN[2]"
		SEND_COMMAND DATA.DEVICE,"'^TXT-54,0,',myGlobal.USER_PIN[3]"
		SEND_COMMAND DATA.DEVICE,"'^TXT-55,0,',myGlobal.USER_PIN[4]"
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,btnKeyPad]{
	PUSH:{
		STACK_VAR INTEGER p 
		p = GET_LAST(tp)
		SWITCH(GET_LAST(btnKeyPad)-1){
			CASE 0:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'0'"
			CASE 1:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'1'"
			CASE 2:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'2'"
			CASE 3:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'3'"
			CASE 4:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'4'"
			CASE 5:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'5'"
			CASE 6:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'6'"
			CASE 7:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'7'"
			CASE 8:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'8'"
			CASE 9:  myPinPanel[p].CUR_ENTRY = "myPinPanel[p].CUR_ENTRY,'9'"
			CASE 10:{
				IF(LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY) >= 1){
					myPinPanel[p].CUR_ENTRY = fnStripCharsRight(myPinPanel[p].CUR_ENTRY,1)
				}
				ELSE{
					IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
						SEND_COMMAND BUTTON.INPUT.DEVICE, "'@PPF-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
						fnTimeoutPanel(GET_LAST(tp),FALSE)
					}
				}
			}
		}
		SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,',fnPadLeadingChars('','*',LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY))"
		SWITCH(myPinPanel[p].KEYPAD_TYPE){
			CASE _padPIN:{
				IF(LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY) == 4){
					SELECT{
						ACTIVE(myPinPanel[p].CUR_ENTRY == myGlobal.USER_PIN[1] && LENGTH_ARRAY(myGlobal.USER_PIN[1])):{
							SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,OK'"
							myPinPanel[p].PIN_INDEX = 1
						}
						ACTIVE(myPinPanel[p].CUR_ENTRY == myGlobal.USER_PIN[2] && LENGTH_ARRAY(myGlobal.USER_PIN[2])):{
							SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,OK'"
							myPinPanel[p].PIN_INDEX = 2
						}
						ACTIVE(myPinPanel[p].CUR_ENTRY == myGlobal.USER_PIN[3] && LENGTH_ARRAY(myGlobal.USER_PIN[3])):{
							SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,OK'"
							myPinPanel[p].PIN_INDEX = 3
						}
						ACTIVE(myPinPanel[p].CUR_ENTRY == myGlobal.USER_PIN[4] && LENGTH_ARRAY(myGlobal.USER_PIN[4])):{
							SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,OK'"
							myPinPanel[p].PIN_INDEX = 4
						}
						ACTIVE(1):{
							SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,INCORRECT'"
							myPinPanel[p].PIN_INDEX = 0
						}
					}
					fnCloseKeypad(p)
				}
			}
			CASE _padADMIN:{
				IF(LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY) == 6){
					IF(myPinPanel[p].CUR_ENTRY == myGlobal.ADMIN_PIN){
						SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,New Code:'"
						myPinPanel[p].CUR_ENTRY = ''
						myPinPanel[p].KEYPAD_TYPE = _padNEW
					}
					ELSE{
						SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,INCORRECT'"
						fnCloseKeypad(p)
					}
				}
			}
			CASE _padNEW:{
				IF(LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY) == 4){
					SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,Confirm:'"
					myPinPanel[p].NEW_PIN_ENTRY = myPinPanel[p].CUR_ENTRY
					myPinPanel[p].CUR_ENTRY = ''
					myPinPanel[p].KEYPAD_TYPE = _padCONFIRM
				}
			}
			CASE _padCONFIRM:{
				IF(LENGTH_ARRAY(myPinPanel[p].CUR_ENTRY) == 4){
					IF(myPinPanel[p].CUR_ENTRY == myPinPanel[p].NEW_PIN_ENTRY){
						myGlobal.USER_PIN[myPinPanel[p].PIN_INDEX] = myPinPanel[p].NEW_PIN_ENTRY
						SWITCH(myPinPanel[p].PIN_INDEX){
							CASE 1:{
								SEND_COMMAND tp[p],"'^TXT-52,0,',myGlobal.USER_PIN[1]"
								SEND_STRING vdvControl,"'PINCHANGED-1,',myGlobal.USER_PIN[1]"
							}
							CASE 2:{
								SEND_COMMAND tp[p],"'^TXT-53,0,',myGlobal.USER_PIN[2]"
								SEND_STRING vdvControl,"'PINCHANGED-2,',myGlobal.USER_PIN[2]"
							}
							CASE 3:{
								SEND_COMMAND tp[p],"'^TXT-54,0,',myGlobal.USER_PIN[3]"
								SEND_STRING vdvControl,"'PINCHANGED-3,',myGlobal.USER_PIN[3]"
							}
							CASE 4:{
								SEND_COMMAND tp[p],"'^TXT-55,0,',myGlobal.USER_PIN[4]"
								SEND_STRING vdvControl,"'PINCHANGED-4,',myGlobal.USER_PIN[4]"
							}
						}
						SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,SAVED'"
						
						fnCloseKeypad(p)
					}
					ELSE{
						SEND_COMMAND BUTTON.INPUT.DEVICE, "'^TXT-50,0,Mismatch'"
						fnCloseKeypad(p)
					}
					myPinPanel[p].CUR_ENTRY = ''
					myPinPanel[p].NEW_PIN_ENTRY = ''
					myPinPanel[p].PIN_INDEX = 0
				}
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnChangePin]{
	PUSH:{
		myPinPanel[GET_LAST(tp)].KEYPAD_TYPE = _padADMIN
		myPinPanel[GET_LAST(tp)].CUR_ENTRY = ''
		myPinPanel[GET_LAST(tp)].PIN_INDEX = GET_LAST(btnChangePin)
		SEND_COMMAND tp[GET_LAST(tp)], "'^TXT-50,0,Change Pin #',ITOA(myPinPanel[GET_LAST(tp)].PIN_INDEX)"
		IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
			SEND_COMMAND tp[GET_LAST(tp)], "'@PPN-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
			fnTimeoutPanel(GET_LAST(tp),TRUE)
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnEnterPin]{
	PUSH:{
		myPinPanel[GET_LAST(tp)].KEYPAD_TYPE = _padPIN
		myPinPanel[GET_LAST(tp)].CUR_ENTRY = ''
		SEND_COMMAND tp[GET_LAST(tp)], "'^TXT-50,0,Enter Code'"
		IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
			SEND_COMMAND tp[GET_LAST(tp)], "'@PPN-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
			fnTimeoutPanel(GET_LAST(tp),TRUE)
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnClose]{
	PUSH:{
		IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
			SEND_COMMAND tp[GET_LAST(tp)], "'@PPF-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
			fnTimeoutPanel(GET_LAST(tp),FALSE)
		}
	}
}
/******************************************************************************
	Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'USER1':		myGlobal.USER_PIN[1] = DATA.TEXT
					CASE 'USER2':		myGlobal.USER_PIN[2] = DATA.TEXT
					CASE 'USER3':		myGlobal.USER_PIN[3] = DATA.TEXT
					CASE 'USER4':		myGlobal.USER_PIN[4] = DATA.TEXT
					CASE 'ADMIN':		myGlobal.ADMIN_PIN 	= DATA.TEXT
					CASE 'POPUP':		myGlobal.POPUP_NAME 	= DATA.TEXT
					CASE 'PAGE':		myGlobal.POPUP_PAGE 	= DATA.TEXT
				}
			}
		}
	}
}

/******************************************************************************
	Timeline Events
	Each one declared due to Event Table crashing on Timeline Arrays
******************************************************************************/
DEFINE_EVENT
TIMELINE_EVENT[TLID_HIDE_01]
TIMELINE_EVENT[TLID_HIDE_02]
TIMELINE_EVENT[TLID_HIDE_03]
TIMELINE_EVENT[TLID_HIDE_04]
TIMELINE_EVENT[TLID_HIDE_05]
TIMELINE_EVENT[TLID_HIDE_06]
TIMELINE_EVENT[TLID_HIDE_07]
TIMELINE_EVENT[TLID_HIDE_08]
TIMELINE_EVENT[TLID_HIDE_09]
TIMELINE_EVENT[TLID_HIDE_10]{
	STACK_VAR INTEGER pPanel
	pPanel = TIMELINE.ID - TLID_HIDE_00
	SWITCH(TIMELINE.SEQUENCE){
		CASE 1:{
			SEND_STRING vdvControl, "'PINOK-',ITOA(pPanel),',',ITOA(myPinPanel[pPanel].PIN_INDEX)"
			myPinPanel[pPanel].PIN_INDEX = 0
		}
		CASE 2:{
			IF(LENGTH_ARRAY(myGlobal.POPUP_NAME) && LENGTH_ARRAY(myGlobal.POPUP_PAGE)){
				SEND_COMMAND tp[pPanel], "'@PPF-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
			}
		}
	}
}
/******************************************************************************
	Timeout
******************************************************************************/
DEFINE_FUNCTION fnTimeoutPanel(INTEGER pPanel, INTEGER pActive){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT_00+pPanel)){TIMELINE_KILL(TLID_TIMEOUT_00+pPanel)}
	IF(pActive){
		TIMELINE_CREATE(TLID_TIMEOUT_00+pPanel,TLT_TIMEOUT,1,TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_TIMEOUT_01]
TIMELINE_EVENT[TLID_TIMEOUT_02]
TIMELINE_EVENT[TLID_TIMEOUT_03]
TIMELINE_EVENT[TLID_TIMEOUT_04]
TIMELINE_EVENT[TLID_TIMEOUT_05]
TIMELINE_EVENT[TLID_TIMEOUT_06]
TIMELINE_EVENT[TLID_TIMEOUT_07]
TIMELINE_EVENT[TLID_TIMEOUT_08]
TIMELINE_EVENT[TLID_TIMEOUT_09]
TIMELINE_EVENT[TLID_TIMEOUT_10]{
	SEND_COMMAND tp[TIMELINE.ID-TLID_TIMEOUT_00], "'@PPF-',myGlobal.POPUP_NAME,';',myGlobal.POPUP_PAGE"
}
/******************************************************************************
	EoF
******************************************************************************/