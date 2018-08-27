MODULE_NAME='mSonyProj'(DEV vdvControl, DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 10/09/2014  AT: 13:45           *)
(***********************************************************)
INCLUDE 'CustomFunctions'
//#DEFINE __TESTING__ 'TRUE'

DEFINE_CONSTANT
LONG TL_BUSY = 1;
LONG TL_AUTOADJ = 2;
LONG TLID_POLL = 3
LONG TLID_COMMS = 4

DEFINE_VARIABLE
LONG TLT_POLL[] = {10000};
LONG TLT_COMMS[] = {30000};

INTEGER chnPOWER= 255

DEFINE_VARIABLE
CHAR _INPUT[25]

DEFINE_EVENT DATA_EVENT[dvRS232]{
    ONLINE:{
	    SEND_COMMAND dvRS232, 'SET MODE DATA'
	    SEND_COMMAND dvRS232, 'SET BAUD 38400 E 8 1 485 DISABLE'
		 fnSendCommand(TRUE,"$01,$02",'')
	    fnInitPoll()
    }
	 STRING:{
		IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	 }
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PICTUREMUTE':{
				//IF(DATA.TEXT = 'ON') 	fnSendCommand("$02,$10,$00,$00,$00,$12")
				//IF(DATA.TEXT = 'OFF') 	fnSendCommand("$02,$11,$00,$00,$00,$13")
			}
			CASE 'ONSCREENMUTE':{
				//IF(DATA.TEXT = 'ON') 	fnSendCommand("$02,$14,$00,$00,$00,$16")
				//IF(DATA.TEXT = 'OFF') 	fnSendCommand("$02,$15,$00,$00,$00,$17")
			}
			CASE 'ASPECT':{
				/*SWITCH(DATA.TEXT){
					CASE '4x3':		fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$00,$00,$30")
					CASE '16x9':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$02,$00,$32")
					CASE '15x9':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$0D,$00,$3D")
					CASE '16x10':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$0C,$00,$3C")
					CASE 'LETTER':	fnSendCommand("$03,$10,$00,$00,$05,$18,$00,$00,$01,$00,$31")
					CASE 'AUTO':	fnSendCommand("$02,$0F,$00,$00,$03,$05,$00,$18")
				}*/
			}
			CASE 'ADJUST':{
				/*SWITCH(DATA.TEXT){
					CASE 'AUTO':		fnSendCommand("$70,$30,$39")
				}*/
			}
			CASE 'INPUT':{
				_INPUT = DATA.TEXT
				IF([vdvControl,255]){
					fnSendInputCommand()
				}
				ELSE{
					SEND_COMMAND vdvControl, 'POWER-ON'
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':{
									  fnSendCommand(FALSE,"$17,$2E","$00,$00")
						WAIT (20){ fnSendCommand(FALSE,"$17,$2E","$00,$00") }
						WAIT (40){ fnSendCommand(FALSE,"$17,$2E","$00,$00") }
						ON[vdvControl,255]
					}
					CASE 'OFF':{
						fnSendCommand(FALSE,"$17,$2F","$00,$00")
						OFF[vdvControl,255]
					}
				}
			}
		}
	}
}

DEFINE_FUNCTION fnSendInputCommand(){
	SWITCH(_INPUT){
		CASE 'VIDEO':	fnSendCommand(FALSE,"$00,$01","$00,$00")
		CASE 'SVIDEO':	fnSendCommand(FALSE,"$00,$01","$00,$01")
		CASE 'A':		fnSendCommand(FALSE,"$00,$01","$00,$02")
		CASE 'B':		fnSendCommand(FALSE,"$00,$01","$00,$03")
		CASE 'C':		fnSendCommand(FALSE,"$00,$01","$00,$04")
		CASE 'D':		fnSendCommand(FALSE,"$00,$01","$00,$05")
		CASE 'E':		fnSendCommand(FALSE,"$00,$01","$00,$06")
	}
	_INPUT = ''
}

DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand(TRUE,"$01,$02",'')
}



DEFINE_FUNCTION fnSendCommand(INTEGER pQUERY, CHAR pITEM[2], CHAR pDATA[2]){
    STACK_VAR CHAR toSend[5]
    STACK_VAR INTEGER CHK
    STACK_VAR INTEGER x
    IF(pQUERY){
		toSend = "pITEM,pQUERY,$00,$00"
	 }
	 ELSE{
		toSend = "pITEM,pQUERY,pDATA"
		fnInitPoll()
	}
	//SEND_STRING 0, "'0 - ',ITOHEX(CHK)"
	FOR(x = 1; x <= 5; x++){
		CHK = CHK BOR toSend[x]
		//SEND_STRING 0, "ITOA(x),' - ',ITOHEX(CHK)"
    }
    
    SEND_STRING dvRS232,"$A9,toSend,CHK,$9A"
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}