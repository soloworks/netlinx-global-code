PROGRAM_NAME='StandardCodeAudioControl'
/******************************************************************************
	Standard Audio - Local Variables
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_PANEL_VOLUME00	= 10000
LONG TLID_PANEL_VOLUME01	= 10001
LONG TLID_PANEL_VOLUME02	= 10002
LONG TLID_PANEL_VOLUME03	= 10003
LONG TLID_PANEL_VOLUME04	= 10004
LONG TLID_PANEL_VOLUME05	= 10005
LONG TLID_PANEL_VOLUME06	= 10006
LONG TLID_PANEL_VOLUME07	= 10007
LONG TLID_PANEL_VOLUME08	= 10008
LONG TLID_PANEL_VOLUME09	= 10009
LONG TLID_PANEL_VOLUME10	= 10010

DEFINE_TYPE STRUCTURE uGain{
	SINTEGER VALUE
	SINTEGER VALUE_100
	SINTEGER VALUE_255
	SINTEGER RANGE[2]
	CHAR     NAME[30]
	INTEGER  MASTER			// If set, this gain should follow what it's master does
}
DEFINE_TYPE STRUCTURE uAudioPanel{
	INTEGER	GAIN_UNDER_CONTROL		// High when User is controlling Audio Value
	INTEGER  GAIN_OBJECT_LINK[60]			// Which Gain object each button controls - defaults to numerical order
}

DEFINE_VARIABLE
VOLATILE uGain 		myGains[60]
VOLATILE uAudioPanel myAudioPanels[10]
VOLATILE LONG 			TLT_PANEL_VOLUME[]  = {500}
/******************************************************************************
	Standard Audio - Setup
******************************************************************************/
DEFINE_START{
	STACK_VAR INTEGER g
	FOR(g = 1; g <= LENGTH_ARRAY(vdvGains); g++){
		CREATE_LEVEL vdvGains[g],1,myGains[g].VALUE
		CREATE_LEVEL vdvGains[g],2,myGains[g].VALUE_100
		CREATE_LEVEL vdvGains[g],3,myGains[g].VALUE_255
	}
	#IF_DEFINED lvlGain
		FOR(g = 1; g <= LENGTH_ARRAY(lvlGain); g++){
			STACK_VAR INTEGER p
			FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
				myAudioPanels[p].GAIN_OBJECT_LINK[g] = g
			}
		}
	#END_IF
}

/******************************************************************************
	Standard Audio - Utility Function
******************************************************************************/
DEFINE_FUNCTION INTEGER fnGetLinkedObject(INTEGER pPanel,INTEGER pLevel){
	RETURN myAudioPanels[pPanel].GAIN_OBJECT_LINK[pLevel]
}
DEFINE_FUNCTION fnLinkAudioObject(INTEGER pPanel,INTEGER pLvl, INTEGER pGain){
	myAudioPanels[pPanel].GAIN_OBJECT_LINK[pLvl] = pGain
	fnSetGainScales(pPanel,pGain)
	fnSetGainNames(pPanel,pGain)
}
/******************************************************************************
	Standard Audio - Sending values to Panels
******************************************************************************/
DEFINE_FUNCTION fnSetGainScales(INTEGER pPanel, INTEGER pGain){
	IF(pPanel == 0){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
			fnSetGainScales(p,pGain)
		}
		RETURN
	}
	IF(pGain == 0){
		STACK_VAR INTEGER g
		FOR(g = 1; g <= LENGTH_ARRAY(vdvGains); g++){
			fnSetGainScales(pPanel,g)
		}
		RETURN
	}
	#IF_DEFINED lvlGain
		IF(myGains[pGain].RANGE[1] != myGains[pGain].RANGE[2] ){
			STACK_VAR INTEGER l
			FOR(l = 1; l <= LENGTH_ARRAY(lvlGain); l++){
				IF(myAudioPanels[pPanel].GAIN_OBJECT_LINK[l] == pGain){
					SEND_COMMAND tpMain[pPanel],"'^BMF-',ITOA(lvlGain[l]),',0,%GL',ITOA(myGains[pGain].RANGE[1]),'%GH',ITOA(myGains[pGain].RANGE[2])"
				}
			}
		}
	#END_IF
}

DEFINE_FUNCTION fnSetGainNames(INTEGER pPanel, INTEGER pGain){
	IF(pPanel == 0){
		STACK_VAR INTEGER p
		FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
			fnSetGainNames(p,pGain)
		}
		RETURN
	}
	IF(pGain == 0){
		STACK_VAR INTEGER g
		FOR(g = 1; g <= LENGTH_ARRAY(vdvGains); g++){
			fnSetGainNames(pPanel,g)
		}
		RETURN
	}

	#IF_DEFINED addGainName
	IF(1){
		STACK_VAR INTEGER l
		FOR(l = 1; l <= LENGTH_ARRAY(addGainName); l++){
			IF(myAudioPanels[pPanel].GAIN_OBJECT_LINK[l] == pGain){
				IF(LENGTH_ARRAY(myGains[pGain].NAME)){
					SEND_COMMAND tpMain[pPanel],"'^TXT-',ITOA(addGainName[l]),',0,',myGains[pGain].NAME"
				}
			}
		}
	}
	#ELSE
		#WARN 'StandardCodeAudioControl - addGainName Not Declared'
	#END_IF
}

DEFINE_EVENT DATA_EVENT[tpMain]{
	ONLINE:{
		fnSetGainScales(GET_LAST(tpMain),0)
		fnSetGainNames(GET_LAST(tpMain),0)
	}
	OFFLINE:{
		myAudioPanels[GET_LAST(tpMain)].GAIN_UNDER_CONTROL = FALSE
	}
}

DEFINE_EVENT DATA_EVENT[vdvGains]{
	STRING:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'RANGE':{
				STACK_VAR INTEGER g

				myGains[GET_LAST(vdvGains)].RANGE[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				myGains[GET_LAST(vdvGains)].RANGE[2] = ATOI(DATA.TEXT)

				fnSetGainScales(0,GET_LAST(vdvGains))
			}
		}
	}
}
/******************************************************************************
	Standard Audio - Level Bar Handling
******************************************************************************/
#IF_DEFINED lvlGain
DEFINE_EVENT BUTTON_EVENT[tpMain,lvlGain]{
	PUSH:{
		STACK_VAR INTEGER p
		p = GET_LAST(tpMain)
		IF(TIMELINE_ACTIVE(TLID_PANEL_VOLUME00+p)){TIMELINE_KILL(TLID_PANEL_VOLUME00+p)}
		myAudioPanels[p].GAIN_UNDER_CONTROL = TRUE
	}
	RELEASE:{
		STACK_VAR INTEGER p
		p = GET_LAST(tpMain)
		TIMELINE_CREATE(TLID_PANEL_VOLUME00+p,TLT_PANEL_VOLUME,LENGTH_ARRAY(TLT_PANEL_VOLUME),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_PANEL_VOLUME01]
TIMELINE_EVENT[TLID_PANEL_VOLUME02]
TIMELINE_EVENT[TLID_PANEL_VOLUME03]
TIMELINE_EVENT[TLID_PANEL_VOLUME04]
TIMELINE_EVENT[TLID_PANEL_VOLUME05]
TIMELINE_EVENT[TLID_PANEL_VOLUME06]
TIMELINE_EVENT[TLID_PANEL_VOLUME07]
TIMELINE_EVENT[TLID_PANEL_VOLUME08]
TIMELINE_EVENT[TLID_PANEL_VOLUME09]
TIMELINE_EVENT[TLID_PANEL_VOLUME10]{
	STACK_VAR INTEGER p
	p = TIMELINE.ID - TLID_PANEL_VOLUME00
	myAudioPanels[p].GAIN_UNDER_CONTROL = FALSE
}

DEFINE_EVENT LEVEL_EVENT[tpMain,lvlGain]{
	STACK_VAR INTEGER p
	p = GET_LAST(tpMain)
	IF(myAudioPanels[p].GAIN_UNDER_CONTROL && fnGetLinkedObject(p,GET_LAST(lvlGain))){
		SEND_COMMAND vdvGains[fnGetLinkedObject(p,GET_LAST(lvlGain))],"'VOLUME-',ITOA(LEVEL.VALUE)"
	}
}
#ELSE
	#WARN 'StandardCodeAudioControl - lvlGain Not Declared'
#END_IF
/******************************************************************************
	Standard Audio - Buttons Handling
******************************************************************************/
#IF_DEFINED btnGainINC
DEFINE_EVENT BUTTON_EVENT[tpMain,btnGainINC]{
	PUSH:{
		SEND_COMMAND vdvGains[fnGetLinkedObject(GET_LAST(tpMain),GET_LAST(btnGainINC))],'VOLUME-INC'
	}
	HOLD[2,REPEAT]:{
		SEND_COMMAND vdvGains[fnGetLinkedObject(GET_LAST(tpMain),GET_LAST(btnGainINC))],'VOLUME-INC'
	}
}
#ELSE
	#WARN 'StandardCodeAudioControl - btnGainINC Not Declared'
#END_IF

#IF_DEFINED btnGainDEC
DEFINE_EVENT BUTTON_EVENT[tpMain,btnGainDEC]{
	PUSH:{
		SEND_COMMAND vdvGains[fnGetLinkedObject(GET_LAST(tpMain),GET_LAST(btnGainDEC))],'VOLUME-DEC'
	}
	HOLD[2,REPEAT]:{
		SEND_COMMAND vdvGains[fnGetLinkedObject(GET_LAST(tpMain),GET_LAST(btnGainDEC))],'VOLUME-DEC'
	}
}
#ELSE
	#WARN 'StandardCodeAudioControl - btnGainDEC Not Declared'
#END_IF

#IF_DEFINED btnGainMute
DEFINE_EVENT BUTTON_EVENT[tpMain,btnGainMute]{
	PUSH:{
		SEND_COMMAND vdvGains[fnGetLinkedObject(GET_LAST(tpMain),GET_LAST(btnGainMute))],'MUTE-TOGGLE'
	}
}
#ELSE
	#WARN 'StandardCodeAudioControl - btnGainMute Not Declared'
#END_IF

/******************************************************************************
	Standard Audio - Set Gain to follow another
******************************************************************************/
DEFINE_FUNCTION fnGainChase(DEV vdvSlave, DEV vdvMaster){
	myGains[fnGetGainIndex(vdvSlave)].MASTER = fnGetGainIndex(vdvMaster)
}

DEFINE_FUNCTION INTEGER fnGetGainIndex(DEV vdvGain){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvGains); x++){
		IF(vdvGains[x] == vdvGain){RETURN x}
	}
}

DEFINE_EVENT LEVEL_EVENT[vdvGains,1]{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvGains); x++){
		IF(myGains[x].MASTER == GET_LAST(vdvGains)){
			SEND_COMMAND vdvGains[x],"'VOLUME-',ITOA(LEVEL.VALUE)"
		}
	}
}

DEFINE_EVENT
CHANNEL_EVENT[vdvGains,199]
CHANNEL_EVENT[vdvGains,198]{
	ON:{
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(vdvGains); x++){
			IF(myGains[x].MASTER == GET_LAST(vdvGains)){
				SWITCH(CHANNEL.CHANNEL){
					CASE 198:SEND_COMMAND vdvGains[x],"'MICMUTE-ON'"
					CASE 199:SEND_COMMAND vdvGains[x],"'MUTE-ON'"
				}
			}
		}
	}
	OFF:{
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(vdvGains); x++){
			IF(myGains[x].MASTER == GET_LAST(vdvGains)){
				SWITCH(CHANNEL.CHANNEL){
					CASE 198:SEND_COMMAND vdvGains[x],"'MICMUTE-OFF'"
					CASE 199:SEND_COMMAND vdvGains[x],"'MUTE-OFF'"
				}
			}
		}
	}
}
/******************************************************************************
	Standard Audio - Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tpMain); p++){
		STACK_VAR INTEGER g
		#IF_DEFINED lvlGain
			FOR(g = 1; g <= LENGTH_ARRAY(lvlGain); g++){
				IF(fnGetLinkedObject(p,g) && g <= LENGTH_ARRAY(vdvGains)){
					IF(!myAudioPanels[p].GAIN_UNDER_CONTROL){
						SEND_LEVEL tpMain[p],lvlGain[g],myGains[fnGetLinkedObject(p,g)].VALUE
					}
				}
			}
		#END_IF
		#IF_DEFINED btnGainMute
			FOR(g = 1; g <= LENGTH_ARRAY(btnGainMute); g++){
				IF(fnGetLinkedObject(p,g) && g <= LENGTH_ARRAY(vdvGains)){
					[tpMain[p],btnGainMute[g]] 			= [vdvGains[fnGetLinkedObject(p,g)],199]
				}
			}
		#END_IF
	}
}
/******************************************************************************
	EoF
******************************************************************************/