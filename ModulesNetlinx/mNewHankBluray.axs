MODULE_NAME='mNewHankBluray'(DEV vdvControl, DEV tp[], DEV dvRS232)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 07/19/2013  AT: 14:54:14        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Types & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uCOMMS{
	CHAR RX[500]
	INTEGER DEBUG
}

DEFINE_VARIABLE
uCOMMS  myNewHankComms
/******************************************************************************
	Comms Code
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER dvRS232, myNewHankComms.RX
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
	}
	STRING:{

	}
}
DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	SEND_STRING dvRS232, "'ID',pCMD"
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){

}
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myNewHankComms.DEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Device Control Code
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	 COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':myNewHankComms.DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
		}
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		STACK_VAR INTEGER iTP
		LOCAL_VAR INTEGER UTC
		iTP = GET_LAST(tp)
		SWITCH(BUTTON.INPUT.CHANNEL){
			CASE 1:	fnSendCommand('33')	// Play & Pause
			CASE 2:	fnSendCommand('34')	// Stop
			CASE 3:	fnSendCommand('33')	// Pause & Play
			CASE 4:	fnSendCommand('40')	// Next
			CASE 5:	fnSendCommand('39')	// Prev
			CASE 6:	fnSendCommand('38')	// FFwd
			CASE 7:	fnSendCommand('37')	// RWnd
			CASE 9:	fnSendCommand('49')	// Power
			CASE 44:	fnSendCommand('24')	// PopupMenu
			CASE 45:	fnSendCommand('26')	// UP
			CASE 46:	fnSendCommand('27')	// DOWN
			CASE 47:	fnSendCommand('28')	// LEFT
			CASE 48:	fnSendCommand('29')	// RIGHT
			CASE 49:	fnSendCommand('30')	// OK
			CASE 99:	fnSendCommand('32')	// OSD
			CASE 100:fnSendCommand('18')	// Subtitle
			CASE 104:fnSendCommand('31')	// Return
			CASE 114:fnSendCommand('22')	// Home
			CASE 115:fnSendCommand('23')	// Disc menu
			CASE 201:fnSendCommand('12')	// Red
			CASE 202:fnSendCommand('13')	// Green
			CASE 203:fnSendCommand('14')	// Yellow
			CASE 204:fnSendCommand('15')	// Blue
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{

}