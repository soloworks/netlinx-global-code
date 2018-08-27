MODULE_NAME='mSIPDoorEntry'(DEV vdvControl, DEV tp[])
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Solo Control wrapper module for AMX SIP Java module
	
	Handles touch panel interfaces, uses device 42000 internally
	
	Feedback Levels:
	1 - Call State (0:Idle,1:Dialling,2:Ringing,3;Connected)
	
	Feedback Channels:
	1-15	= Panel that currently is handling the call
	51-65	= Panel is currently in DnD mode
	
	201	= System in DnD Mode
	
	236	= Incoming Call
	237	= Dialling Out
	238	= Call Connected
	
	251	= Online & Registered
	252	= Online & Registered
	
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_PANELS = 20

DEFINE_DEVICE
dvMaster		= 0:1:0
vdvSIPJava 	= 42000:1:0
DEFINE_MODULE 'sipdoorphone_dr1_0_0' mdlSIP(vdvSIPJAVA)
/******************************************************************************
	uSIPSysSettings Structure
	Holds settings per system that are applied on startup
******************************************************************************/
DEFINE_TYPE STRUCTURE uSIPSysSettings{
	CHAR 		DOMAIN[20]		// Authentication Realm
	CHAR 		VIDEO[10]		// H.264 Video stream Format
	CHAR 		AUDIO[10]		// Audio Stream Format
	CHAR 		DTMF[10]			// DTMF Format
	INTEGER 	RE_REG_TIME		// Time in seconds of Sip heartbeat re-register with sip server 
	INTEGER 	REG_LIVE_TIME	// Time in seconds of delay following Resgister Command before a non-response causes a re-try
	INTEGER 	SIP_PORT			// SIP Host Port
}
DEFINE_CONSTANT
INTEGER SYS_URMET 	= 1
INTEGER SYS_BPT 		= 2
INTEGER SYS_COMLIT	= 3

DEFINE_VARIABLE 
VOLATILE uSIPSysSettings mySIPSysSettings[3]

DEFINE_START{
	// URMET Settings
	mySIPSysSettings[SYS_URMET].DOMAIN 				= 'docking'
	mySIPSysSettings[SYS_URMET].VIDEO 				= '105'
	mySIPSysSettings[SYS_URMET].AUDIO 				= '0 101'
	mySIPSysSettings[SYS_URMET].DTMF 				= 'SIP'
	mySIPSysSettings[SYS_URMET].RE_REG_TIME 		= 60
	mySIPSysSettings[SYS_URMET].REG_LIVE_TIME 	= 10
	mySIPSysSettings[SYS_URMET].SIP_PORT 			= 5060
	// BPT Settings
	mySIPSysSettings[SYS_BPT].DOMAIN 				= 'asterisk'
	mySIPSysSettings[SYS_BPT].VIDEO 					= '103'
	mySIPSysSettings[SYS_BPT].AUDIO 					= '0 101'
	mySIPSysSettings[SYS_BPT].DTMF 					= 'RTP'
	mySIPSysSettings[SYS_BPT].RE_REG_TIME 			= 60
	mySIPSysSettings[SYS_BPT].REG_LIVE_TIME 		= 10
	mySIPSysSettings[SYS_BPT].SIP_PORT 				= 5060
	// COMLIT Settings
	mySIPSysSettings[SYS_COMLIT].DOMAIN 			= ''
	mySIPSysSettings[SYS_COMLIT].VIDEO 				= ''
	mySIPSysSettings[SYS_COMLIT].AUDIO 				= '0 101'
	mySIPSysSettings[SYS_COMLIT].DTMF 				= 'SIPDIGITS'
	mySIPSysSettings[SYS_COMLIT].RE_REG_TIME 		= 60
	mySIPSysSettings[SYS_COMLIT].REG_LIVE_TIME 	= 10
	mySIPSysSettings[SYS_COMLIT].SIP_PORT 			= 5061
}
/******************************************************************************
	uSIPControl Structure
	Main module variables
******************************************************************************/
DEFINE_CONSTANT
INTEGER CALL_STATE_IDLE			= 0
INTEGER CALL_STATE_RINGING		= 1
INTEGER CALL_STATE_DIALLING	= 2
INTEGER CALL_STATE_CONNECTED	= 3
DEFINE_TYPE STRUCTURE uSpeedDial{
	CHAR		NAME[20]
	CHAR 		ADDRESS[50]
}
DEFINE_TYPE STRUCTURE uSIPControl{
	INTEGER	SYSTEM_TYPE
	uSIPSysSettings SYSTEM_SETTINGS
	// Site Settings
	CHAR 		PROXY[255]			// SIP Proxy or Server
	CHAR 		CONTACT_ADD[255]	// IP address of source IP Streams (Normally SIP add)
	CHAR		CONTACT_ID[255]
	CHAR		CONTACT_NUM[255]
	CHAR 		USERNAME[20]		// SIP Username
	CHAR 		PASSWORD[20]		// SIP Password
	INTEGER	DEBUG
	INTEGER	EMULATE				// Emulate End Device (for offsite testing)
	INTEGER	REGISTERED			// Sip is Registered
	// Call Settings
	INTEGER 	AUD_RX_PORT			// Audio Port on Server for active call
	INTEGER 	VID_TX_PORT			// Audio Port on Server for active call
	INTEGER	CALL_STATE
	// Speed Dials
	uSpeedDial SPEED_DIAL[5]
	// General Settings
	INTEGER	DnD					// System Do Not Disturb mode
	INTEGER 	LIVE_PANEL			// This panel is the current panel a call is linked to
}
DEFINE_VARIABLE 
VOLATILE uSIPControl mySipControl
VOLATILE LONG TLT_RING[] = {5000}
/******************************************************************************
	uSIPPanel Structure
	Control of TouchPanels
******************************************************************************/
DEFINE_TYPE STRUCTURE uSIPPanel{
	INTEGER 				VID_RX_PORT	// Port on Panel Recieving Video
	INTEGER 				AUD_TX_PORT	// Port on Panel transmitting Audio
	IP_ADDRESS_STRUCT	IP				// Panel IP Address
	INTEGER				INACTIVE		// Panel Not In Entry Pool
}
DEFINE_VARIABLE
VOLATILE uSIPPanel mySIPPanel[MAX_PANELS]
DEFINE_EVENT DATA_EVENT [tp]{
	ONLINE:{
		GET_IP_ADDRESS(DATA.DEVICE,mySIPPanel[GET_LAST(tp)].IP)
		mySIPPanel[GET_LAST(tp)].VID_RX_PORT = 8900
		mySIPPanel[GET_LAST(tp)].AUD_TX_PORT = 8000
	}
}
/******************************************************************************
	Constants - Interface Addresses
******************************************************************************/
DEFINE_CONSTANT
INTEGER addVideoStream	=  21
INTEGER addCallerID		= 	22
INTEGER addCallerNum		=  23

INTEGER btnCallAnswer 	= 101
INTEGER btnCallHangup 	= 102
INTEGER btnOpenDoor	 	= 103
INTEGER btnInactive  	= 104
INTEGER btnDnD_House		= 105
INTEGER btnTalk			= 106
INTEGER btnTalkFB			= 107

INTEGER btnSpeedDial[]	= {
	151,152,153,154,155
}
/******************************************************************************
	System Helpers - Debugging
******************************************************************************/
DEFINE_CONSTANT
INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG,CHAR Msg[], CHAR MsgData[]){
	 IF(pDEBUG <= mySipControl.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	System Helpers - Call Handlers
******************************************************************************/
DEFINE_FUNCTION fnDial(INTEGER p,CHAR pContact[]){
	STACK_VAR CHAR pCMD[500]
	
	mySipControl.LIVE_PANEL = p
	
	pCMD = 'Call|'													// Command (Call)
	pCMD = "pCMD,mySIPPanel[p].IP.IPADDRESS,','"			// Origin IP
	pCMD = "pCMD,ITOA(mySIPPanel[p].AUD_TX_PORT),','"	// Audio TX Port
	pCMD = "pCMD,ITOA(mySIPPanel[p].VID_RX_PORT),','"	// Video Rx Port
	pCMD = "pCMD,pContact,','"									// Number to Call
	pCMD = "pCMD,mySipControl.PROXY"							// Proxy IP
	SEND_COMMAND vdvSIPJAVA,pCMD
	SEND_STRING vdvControl,"'CALLER_NUM-',pContact"
	
	IF(mySipControl.EMULATE){
		mySipControl.CALL_STATE = CALL_STATE_DIALLING
		TIMELINE_CREATE(CALL_STATE_DIALLING,TLT_RING,LENGTH_ARRAY(TLT_RING),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[CALL_STATE_DIALLING]{
	mySipControl.CALL_STATE = CALL_STATE_CONNECTED
}
DEFINE_FUNCTION fnAnswer(INTEGER p){
	STACK_VAR CHAR pCMD[500]
	
	mySipControl.LIVE_PANEL = p
	// Answer Sip Call in Sip Module
	pCMD = 'Answer|'												// Command (Answer)
	pCMD = "pCMD,mySIPPanel[p].IP.IPADDRESS,','"			// Origin IP
	pCMD = "pCMD,ITOA(mySIPPanel[p].AUD_TX_PORT),','"	// Audio TX Port
	pCMD = "pCMD,ITOA(mySIPPanel[p].VID_RX_PORT)"	// Video Rx Port
	SEND_COMMAND vdvSIPJAVA,pCMD
	mySipControl.CALL_STATE = CALL_STATE_CONNECTED
	
	// Enable Panel Video
	pCMD = '^SDM-'													// Command (Streaming Listen)
	pCMD = "pCMD,ITOA(addVideoStream),',0,'"				// Video Stream Button address
	pCMD = "pCMD,'rtp://0.0.0.0:'"							// rtp URI
	pCMD = "pCMD,ITOA(mySIPPanel[p].VID_RX_PORT)"			// Video Rx Port (On Panel)
	SEND_COMMAND tp[p],pCMD
	
	// Enable Panel Audio
	pCMD = '^ICS-'													// Command (Intercom Start)
	pCMD = "pCMD,mySipControl.CONTACT_ADD,','"			// Contact Address
	pCMD = "pCMD,ITOA(mySipControl.AUD_RX_PORT),','"	// Audio Rx Port (On Server)
	pCMD = "pCMD,ITOA(mySIPPanel[p].AUD_TX_PORT),','"	// Audio TX Port (On Panel)
	pCMD = "pCMD,'2'"												// Start in Both Mode (0 = Listen, 1 = Talk, 2 = Both)
	SEND_COMMAND tp[p],pCMD
	
	// Mute Mic on Connect
	SEND_COMMAND tp[p],'^ICM-TALK'
	//SEND_COMMAND tp[p],'^ICM-MUTEMIC,1'
	
	IF(mySipControl.EMULATE){
		IF(TIMELINE_ACTIVE(CALL_STATE_RINGING)){ TIMELINE_KILL(CALL_STATE_RINGING) }
		mySipControl.CALL_STATE = CALL_STATE_CONNECTED
	}
}
DEFINE_FUNCTION fnHangup(){
	IF(mySipControl.LIVE_PANEL){
		//SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^VCE'"
		SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^ICE'"
		SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^SDM-',ITOA(addVideoStream),',0,none'"
	}
	mySipControl.LIVE_PANEL = 0
	
	SEND_COMMAND vdvSIPJAVA,'Hangup'							// End SIP Session
	SEND_STRING vdvControl,"'CALLER_ID-'"
	SEND_STRING vdvControl,"'CALLER_NUM-'"
	SEND_COMMAND tp,"'^TXT-',ITOA(addCallerId),',0,'"
	SEND_COMMAND tp,"'^TXT-',ITOA(addCallerNum),',0,'"
	mySipControl.CALL_STATE = CALL_STATE_IDLE
	
	IF(mySipControl.EMULATE){
		IF(TIMELINE_ACTIVE(CALL_STATE_DIALLING)){ TIMELINE_KILL(CALL_STATE_DIALLING) }
		IF(TIMELINE_ACTIVE(CALL_STATE_RINGING)) { TIMELINE_KILL(CALL_STATE_RINGING)  }
		mySipControl.CALL_STATE = CALL_STATE_IDLE
	}
}
DEFINE_EVENT TIMELINE_EVENT[CALL_STATE_RINGING]{
	mySipControl.CALL_STATE = CALL_STATE_IDLE
}
/******************************************************************************
	Virtual Netlinx Control Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'EMULATE':		mySipControl.EMULATE = (DATA.TEXT == 'TRUE')
					CASE 'IP':				mySipControl.PROXY = DATA.TEXT
					CASE 'USERNAME':		mySipControl.USERNAME = DATA.TEXT
					CASE 'PASSWORD':		mySipControl.PASSWORD = DATA.TEXT
					CASE 'SPEEDDIAL':{
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						mySipControl.SPEED_DIAL[x].NAME 		= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						mySipControl.SPEED_DIAL[x].ADDRESS 	= DATA.TEXT
					}
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':mySipControl.DEBUG = DEBUG_STD
							CASE 'DEV':	mySipControl.DEBUG = DEBUG_DEV
							DEFAULT:		mySipControl.DEBUG = DEBUG_ERR
						}
					}
					CASE 'SYSTEM':{
						SWITCH(DATA.TEXT){
							CASE 'BPT': 	mySipControl.SYSTEM_TYPE = SYS_BPT
							CASE 'COMLIT': mySipControl.SYSTEM_TYPE = SYS_COMLIT
							CASE 'URMET': 	mySipControl.SYSTEM_TYPE = SYS_URMET
						}
						mySipControl.SYSTEM_SETTINGS = mySIPSysSettings[mySipControl.SYSTEM_TYPE]
					}
				}
			}
			CASE 'TEST':{
				IF(DATA.TEXT == 'INCOMING'){
					IF(mySipControl.EMULATE){
						mySipControl.CALL_STATE = CALL_STATE_RINGING
						TIMELINE_CREATE(CALL_STATE_RINGING,TLT_RING,LENGTH_ARRAY(TLT_RING),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
				ELSE{
					SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
						CASE 'OUTGOING':{
							fnDial(ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)),DATA.TEXT)
						}
					}
				}
			}
		}
	}
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		[vdvControl,p] 		= (mySipControl.LIVE_PANEL == p)
		[vdvControl,p+50]		= (mySIPPanel[p].INACTIVE)
	}
	[vdvControl,201] = (mySipControl.DnD)
	[vdvControl,236] = (mySipControl.CALL_STATE == CALL_STATE_RINGING)
	[vdvControl,237] = (mySipControl.CALL_STATE == CALL_STATE_DIALLING)
	[vdvControl,238] = (mySipControl.CALL_STATE == CALL_STATE_CONNECTED)

	[vdvControl,251] = mySipControl.REGISTERED // SIP Registered
	[vdvControl,252] = mySipControl.REGISTERED // SIP Registered
	
	SEND_LEVEL vdvControl,1,mySipControl.CALL_STATE
}
/******************************************************************************
	Virtual Java Control Device Control
******************************************************************************/
DEFINE_CONSTANT 
LONG TLID_REGISTER = 101
DEFINE_VARIABLE
LONG TLT_REGISTER[] = {30000}
DEFINE_EVENT TIMELINE_EVENT[TLID_REGISTER]{
	SEND_COMMAND vdvSIPJava,"'Register'"
}
DEFINE_EVENT DATA_EVENT[vdvSIPJava]{
	ONLINE:{
		STACK_VAR IP_ADDRESS_STRUCT myIP
		GET_IP_ADDRESS(0:0:0,myIP)
		SWITCH(mySipControl.DEBUG){
			CASE DEBUG_STD:	SEND_COMMAND vdvSIPJAVA,"'SetDebugLevel|Normal'"
			CASE DEBUG_DEV:	SEND_COMMAND vdvSIPJAVA,"'SetDebugLevel|Full'"
			CASE DEBUG_ERR:	SEND_COMMAND vdvSIPJAVA,"'SetDebugLevel|Off'"
		}
		SEND_COMMAND DATA.DEVICE,"'SetFromIP|',myIP.IPADDRESS"

		SEND_COMMAND DATA.DEVICE,"'SetUser|',mySipControl.USERNAME" 
		SEND_COMMAND DATA.DEVICE,"'SetPass|',mySipControl.PASSWORD"
		SEND_COMMAND DATA.DEVICE,"'SetSipProxy|',mySipControl.PROXY"
		
		SEND_COMMAND DATA.DEVICE,"'SetDomain|',mySipControl.SYSTEM_SETTINGS.DOMAIN"
		SEND_COMMAND DATA.DEVICE,"'SetVideoType|',mySipControl.SYSTEM_SETTINGS.VIDEO"
		SEND_COMMAND DATA.DEVICE,"'SetAudioType|',mySipControl.SYSTEM_SETTINGS.AUDIO"
		SEND_COMMAND DATA.DEVICE,"'SetDTMFType|',mySipControl.SYSTEM_SETTINGS.DTMF"
		SEND_COMMAND DATA.DEVICE,"'SetReRegisterTime|',ITOA(mySipControl.SYSTEM_SETTINGS.RE_REG_TIME)"
		SEND_COMMAND DATA.DEVICE,"'SetRegisterLiveTime|',ITOA(mySipControl.SYSTEM_SETTINGS.REG_LIVE_TIME)"
		SEND_COMMAND DATA.DEVICE,"'SetHostPort|',ITOA(mySipControl.SYSTEM_SETTINGS.SIP_PORT)"
		
		SEND_COMMAND DATA.DEVICE,"'Listen|On'"
		SEND_COMMAND DATA.DEVICE,"'Version?'"
		SEND_COMMAND DATA.DEVICE,"'Register'"
		TIMELINE_CREATE(TLID_REGISTER,TLT_REGISTER,LENGTH_ARRAY(TLT_REGISTER),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
		//SEND_COMMAND DATA.DEVICE,"'RegisterLoop'"
	}
	STRING:{
		STACK_VAR CHAR pCMD[100]
		STACK_VAR CHAR pDATA[6][50]
		STACK_VAR CHAR pDataIndex
		pCMD	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'|',1),1)
		pDataIndex = 1
		WHILE(FIND_STRING(DATA.TEXT,',',1)){
			pDATA[pDataIndex] = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
			pDataIndex++
		}
		pDATA[pDataIndex] = DATA.TEXT
		SWITCH(pCMD){
			CASE 'Ringing':{
				mySipControl.CONTACT_ADD 	= pDATA[1]
				mySipControl.CONTACT_ID 	= pDATA[2]
				mySipControl.CONTACT_NUM 	= pDATA[3]
				mySipControl.AUD_RX_PORT 	= ATOI(pDATA[5])
				mySipControl.CALL_STATE  	= CALL_STATE_RINGING
				SEND_STRING vdvControl,"'CALLER_ID-',mySipControl.CONTACT_ID"
				SEND_STRING vdvControl,"'CALLER_NUM-',mySipControl.CONTACT_NUM"
				SEND_COMMAND tp,"'^TXT-',ITOA(addCallerId),',0,',mySipControl.CONTACT_ID"
				SEND_COMMAND tp,"'^TXT-',ITOA(addCallerNum),',0,',mySipControl.CONTACT_NUM"
			}
			CASE 'Register':{
				SWITCH(pDATA[1]){
					CASE 'Ok':	mySipControl.REGISTERED = TRUE
					DEFAULT:		mySipControl.REGISTERED = FALSE	
				}
			}
			CASE 'CallRefused':{
				fnDebug(DEBUG_STD,'SIP CallRefused',pDATA[1])
				mySipControl.CONTACT_ADD = ''
				mySipControl.AUD_RX_PORT = 0
				mySipControl.VID_TX_PORT = 0
				mySipControl.CALL_STATE  = CALL_STATE_IDLE
			}
			CASE 'CallAccepted':{
				mySipControl.CONTACT_ADD = pDATA[1]
				mySipControl.AUD_RX_PORT = ATOI(pDATA[2])
				mySipControl.VID_TX_PORT = ATOI(pDATA[3])
				mySipControl.CALL_STATE  = CALL_STATE_CONNECTED
			}
			CASE 'Version':{
				fnDebug(DEBUG_STD,'SIP Version',pDATA[1])
			}
			DEFAULT:{
				// No '|' present
				SWITCH(DATA.TEXT){
					CASE 'Hangup':{
						mySipControl.CONTACT_ADD = ''
						mySipControl.AUD_RX_PORT = 0
						mySipControl.VID_TX_PORT = 0
						mySipControl.CALL_STATE  = CALL_STATE_IDLE
						IF(mySipControl.LIVE_PANEL){
							//SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^VCE'"
							SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^ICE'"
							SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^SDM-',ITOA(addVideoStream),',0,none'"
						}
						mySipControl.LIVE_PANEL = 0
					}
					CASE 'Timeout':{
						fnDebug(DEBUG_STD,'SIP Timeout','')
					}
				}
			}
		}
	}
	COMMAND:{
		// No '|' present
		SWITCH(DATA.TEXT){
			CASE 'Hangup':{
				mySipControl.CONTACT_ADD = ''
				mySipControl.AUD_RX_PORT = 0
				mySipControl.VID_TX_PORT = 0
				mySipControl.CALL_STATE  = CALL_STATE_IDLE
				IF(mySipControl.LIVE_PANEL){
					//SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^VCE'"
					SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^ICE'"
					SEND_COMMAND tp[mySipControl.LIVE_PANEL],"'^SDM-',ITOA(addVideoStream),',0,none'"
				}
				mySipControl.LIVE_PANEL = 0
			}
			CASE 'Timeout':{
				fnDebug(DEBUG_STD,'SIP Timeout','')
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvControl,236]{
	ON:{
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
			IF(!mySipControl.DnD && !mySIPPanel[p].INACTIVE){
				SEND_COMMAND tp[p],"'@SOU-DoorEntry.mp3'" 
			}
		}
	}
}
/******************************************************************************
	Touch Panel Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	OFFLINE:{
		IF(mySipControl.LIVE_PANEL == GET_LAST(tp)){
			fnHangup()
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnDnD_House]{
	PUSH:{
		mySipControl.DnD = !mySipControl.DnD
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnInactive]{
	PUSH:{
		mySIPPanel[GET_LAST(tp)].INACTIVE = !mySIPPanel[GET_LAST(tp)].INACTIVE
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCallAnswer]{
	RELEASE:{
		fnAnswer(GET_LAST(tp))
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnCallHangup]{
	RELEASE:{
		fnHangup()
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnOpenDoor]{
	RELEASE:{
		SWITCH(mySipControl.SYSTEM_TYPE){
			CASE SYS_BPT:		SEND_COMMAND vdvSIPJava,"'SendDTMF|*50'"
			CASE SYS_COMLIT:	SEND_COMMAND vdvSIPJava,"'SendDTMF|111'"
			CASE SYS_URMET:	SEND_COMMAND vdvSIPJava,"'SendDTMF|1'"
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnTalk]{
	PUSH:{
		//SEND_COMMAND BUTTON.INPUT.DEVICE,'^ICM-TALK'
		SEND_COMMAND BUTTON.INPUT.DEVICE,'^ICM-MUTEMIC,0'
		TO[BUTTON.INPUT.DEVICE,btnTalkFB]
	}
	RELEASE:	SEND_COMMAND BUTTON.INPUT.DEVICE,'^ICM-MUTEMIC,1'
}
DEFINE_EVENT BUTTON_EVENT[tp,btnSpeedDial]{
	RELEASE:{
		fnDial(GET_LAST(tp),mySipControl.SPEED_DIAL[GET_LAST(btnSpeedDial)].ADDRESS)
	}
}
/******************************************************************************
	Touch Panel Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		[tp[p],btnInactive] = (mySIPPanel[p].INACTIVE)
	}
	[tp,addVideoStream] = (mySipControl.EMULATE)
	[tp,btnDnD_House] = (mySipControl.DnD)
}
/******************************************************************************
	EoF
******************************************************************************/

