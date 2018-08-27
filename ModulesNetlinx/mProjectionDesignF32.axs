MODULE_NAME='mProjectionDesignF32'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'
#WARN 'Improve Module and add IP Control'
/***********************************************************
Projection Design Inputs
VGA
S-Video
DVI
Composite
Component
RGB
HDMI
BNC
XP2
********************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL 			= 1
LONG TLID_COMMS			= 2
LONG TLT_COMMS[]		= {90000}

INTEGER chnFreeze	= 241
INTEGER chnBLANK	= 240
INTEGER chnPOWER	= 255

DEFINE_TYPE STRUCTURE uF32Proj{

	CHAR		Rx[500]
	CHAR		Tx[500]
	INTEGER	DEBUG

	INTEGER	POWER
	INTEGER	VidMUTE
	INTEGER	INPUT[10]
}

DEFINE_VARIABLE
VOLATILE uF32Proj myF32Proj

LONG TLT_POLL[] 	= {30000}


DEFINE_START{
	CREATE_BUFFER dvDevice, myF32Proj.Rx
	TIMELINE_CREATE(TLID_POLL,TLT_POLL, LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		SEND_COMMAND dvDevice,'SET MODE DATA'
		SEND_COMMAND dvDevice,'SET BAUD 19200 N,8,1 485 DISABLE'
		fnSendQuery()
	}
	STRING:{
		fnDebug('RAW->',DATA.TEXT)
		WHILE(FIND_STRING(myF32Proj.Rx,"$0D,$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myF32Proj.Rx,"$0D,$0D,$0A",1),3))
		}
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_COMMS]{
	myF32Proj.POWER = FALSE
	myF32Proj.VidMUTE = FALSE
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	fnDebug('F32->',pDATA)
	GET_BUFFER_STRING(pDATA,5)
	SWITCH(GET_BUFFER_STRING(pDATA,5)){
		CASE 'SHUT ': myF32Proj.VidMUTE 	= ATOI(pDATA)
		CASE 'POWR ': myF32Proj.POWER 	= ATOI(pDATA)
	}

	// Set Timeout
	IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
	TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)

}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendQuery()
}
DEFINE_FUNCTION fnSendQuery(){
	SEND_STRING dvDevice, "':POWR?',$0D"
	SEND_STRING dvDevice, "':SHUT?',$0D"
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{

					}
					CASE 'DEBUG':{
						myF32Proj.DEBUG = (DATA.TEXT == 'TRUE')
					}
				}
			}
			CASE 'RAW':fnSendCommand(DATA.TEXT)
			CASE 'INPUT':{
				SWITCH(myF32Proj.POWER){
					CASE TRUE: fnSendCommand("'I',fnGetInputString(DATA.TEXT)")
					CASE FALSE:fnSendCommand("'POWR1'")
				}
			}
			CASE 'BLANK':{
				IF(myF32Proj.POWER){
					SWITCH(DATA.TEXT){
						CASE 'ON':	fnSendCommand("'SHUT1'")
						CASE 'OFF':	fnSendCommand("'SHUT0'")
						CASE 'TOGGLE':{
							SWITCH(myF32Proj.VidMUTE){
								CASE TRUE:  fnSendCommand("'SHUT0'")
								CASE FALSE:	fnSendCommand("'SHUT1'")
							}
						}
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':	fnSendCommand("'POWR1'")
					CASE 'OFF':	fnSendCommand("'POWR0'")
				}
			}
		}
	}
}


DEFINE_FUNCTION CHAR[10] fnGetInputString(CHAR pINP[]){
	SWITCH(pINP){
		CASE 'VGA':			RETURN 'VGA'
		CASE 'S-VIDEO':	RETURN 'SVI'
		CASE 'DVI':			RETURN 'DVI'
		CASE 'COMPOSITE':	RETURN 'CVI'
		CASE 'COMPONENT':	RETURN 'YPP'
		CASE 'RGB':			RETURN 'RGS'
		CASE 'HDMI':		RETURN 'HDM'
		CASE 'BNC':			RETURN 'BNC'
		CASE 'XP2':			RETURN 'XP2'
	}
}


DEFINE_FUNCTION fnSendCommand(CHAR cmd[10]){
	fnDebug('->F32',"':0 ',cmd,$0D")
	SEND_STRING dvDevice, "':0 ',cmd,$0D"
}


DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myF32Proj.DEBUG)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))

	[vdvControl,chnBLANK] = (myF32Proj.VidMUTE)
}