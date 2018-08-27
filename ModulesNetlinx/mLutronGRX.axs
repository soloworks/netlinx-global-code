MODULE_NAME='mLutronGRX'(DEV vdvControl[], DEV dvRS232)
INCLUDE 'CustomFunctions'

DEFINE_VARIABLE
CHAR cIncBuffer[500]

DEFINE_START{
	CREATE_BUFFER dvRS232, cIncBuffer
}

DEFINE_EVENT DATA_EVENT[dvRS232]{	
	ONLINE: SEND_COMMAND dvRS232, "'SET BAUD 9600, N, 8, 1 485 Disable'"
	STRING:{
		WHILE(FIND_STRING(cIncBuffer,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(cIncBuffer,"$0D,$0A",1),1))
		}
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		STACK_VAR CHAR _Unit[1]
		_Unit = ITOHEX(GET_LAST(vdvControl))
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'SCENE':SEND_STRING dvRS232, "':A',DATA.TEXT,_Unit,$0D"
			CASE 'RAMP':{
				SWITCH(DATA.TEXT){
					CASE 'UP':SEND_STRING dvRS232, "':B',_Unit,'12',$0D"
					CASE 'DN':SEND_STRING dvRS232, "':D',_Unit,'12',$0D"
					CASE 'STOPUP':SEND_STRING dvRS232, "':B',_Unit,$0D"
					CASE 'STOPDN':SEND_STRING dvRS232, "':D',_Unit,$0D"
				}
			}
		}
	}
}

(** Code specific to SubSea7 London, needs ammending to cover all possiblities **) 
DEFINE_FUNCTION fnProcessFeedback(CHAR pcCMD[255]){
	STACK_VAR INTEGER iROOM
	SWITCH(GET_BUFFER_CHAR(pcCMD)){
		CASE 'Q':iROOM = 1
		CASE 'I':iROOM = 2
	}
	SEND_STRING vdvControl[iROOM], "'KEYPAD-',ITOA(ATOI(DATA.TEXT))"
}