MODULE_NAME='mVbrick'(DEV vdvControl, DEV ipConn)
/******************************************************************************
	VBrick Basic Control Module
	COMMANDS:
	ACTION-CLEAR
	ACTION-BEGIN
	ACTION-QUIT
	
	Where x = ID 1-4:
	STREAM-x,APPLY
	STREAM-x,START
	STREAM-x,STOP
	
******************************************************************************/
INCLUDE 'CustomFunctions'
/******************************************************************************
	Module Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uTCP{
	(** Comms **)
	INTEGER PORT
	CHAR IP[128]
	INTEGER DEBUG
	INTEGER CONN_STATE
	CHAR Tx[1000]
	CHAR Rx[2000]
	CHAR Username[30]
	CHAR Password[30]
}

DEFINE_CONSTANT
LONG TLID_BOOT		= 1
LONG TLID_RETRY	= 2

INTEGER CONN_OFFLINE 	= 0
INTEGER CONN_TRYING		= 1
INTEGER CONN_NEGOTIATE	= 2
INTEGER CONN_SECURITY	= 3
INTEGER CONN_CONNECTED	= 4

DEFINE_VARIABLE
LONG TLT_BOOT[] 		= { 10000 }
LONG TLT_RETRY[] 		= {  5000 }
uTCP myTCP

/******************************************************************************
	Module Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(CHAR pCmd[]){
	IF(myTCP.CONN_STATE == CONN_CONNECTED){
		SEND_STRING ipConn,"pCmd,$0D"
		fnDebug(FALSE,'->VBRICK',"pCmd,$0D")
	}
}

DEFINE_FUNCTION fnDebug(INTEGER bForce, CHAR Msg[], CHAR MsgData[]){
	IF(myTCP.DEBUG || bForce){
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnOpenTCPConnection(){
	fnDebug(FALSE,'Connecting to Vbrick on ',"myTCP.IP,':',ITOA(myTCP.PORT)")
	myTCP.CONN_STATE = CONN_TRYING
	ip_client_open(ipConn.port, myTCP.IP, myTCP.PORT, IP_TCP) 
} 
 
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipConn.port)
}

DEFINE_FUNCTION fnTryConnection(){
	IF(!TIMELINE_ACTIVE(TLID_RETRY)){
		TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}
/******************************************************************************
	Device Control
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipCONN,myTCP.Rx
}

DEFINE_EVENT DATA_EVENT[ipCONN]{
	ONLINE:{
		myTCP.CONN_STATE = CONN_NEGOTIATE
	}
	OFFLINE:{
		myTCP.CONN_STATE = CONN_OFFLINE
		myTCP.Rx = ''
		myTCP.Tx = ''
		fnTryConnection()
	}
	ONERROR:{
		myTCP.CONN_STATE = CONN_OFFLINE
		myTCP.Rx = ''
		myTCP.Tx = ''
		SWITCH(DATA.NUMBER){
			CASE 2:{ fnDebug(FALSE, "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']General Failure'")}					//General Failure - Out Of Memory
			CASE 4:{ fnDebug(TRUE,  "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown Host'")}						//Unknown Host
			CASE 6:{ fnDebug(FALSE, "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Refused'")}						//Connection Refused
			CASE 7:{ fnDebug(TRUE,  "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Conn Timed Out'")}						//Connection Timed Out
			CASE 8:{ fnDebug(FALSE, "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Unknown'")}								//Unknown Connection Error
			CASE 9:{ fnDebug(FALSE, "'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Already Closed'")}						//Already Closed
			CASE 10:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Binding Error'")} 					//Binding Error
			CASE 11:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Listening Error'")} 					//Listening Error
			CASE 14:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Local Port Already Used'")}		//Local Port Already Used
			CASE 15:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']UDP Socket Already Listening'")} //UDP socket already listening
			CASE 16:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Too many open Sockets'")}			//Too many open sockets
			CASE 17:{fnDebug(FALSE,"'TCP_MOD IP Error:[',myTCP.IP,']:'","'[',ITOA(DATA.NUMBER),']Local port not Open'")}				//Local Port Not Open
		}
		fnTryConnection()
	}
	STRING:{
		fnDebug(FALSE,'->VBrickRAW',DATA.TEXT)
		// Telnet Negotiation
		WHILE(myTCP.Rx[1] == $FF && LENGTH_ARRAY(myTCP.Rx)){
			STACK_VAR CHAR NEG_PACKET[3]
			NEG_PACKET = GET_BUFFER_STRING(myTCP.Rx,3)
			SWITCH(NEG_PACKET[2]){
				CASE $FB:
				CASE $FC:NEG_PACKET[2] = $FE
				CASE $FD:
				CASE $FE:NEG_PACKET[2] = $FC
			}
			fnDebug(FALSE,'->VBrickNEG',NEG_PACKET)
			SEND_STRING DATA.DEVICE,NEG_PACKET
		}
		// Security Negotiation
		IF(FIND_STRING(myTCP.Rx,'Login:',1)){
			myTCP.CONN_STATE = CONN_SECURITY
			fnDebug(FALSE,'SX->',myTCP.Rx)
			myTCP.Rx = ''
			IF(myTCP.Username == ''){myTCP.Username = 'admin'}
			fnDebug(FALSE,'->SX',"myTCP.Username,$0D")
			SEND_STRING ipConn, "myTCP.Username,$0D"
		}
		ELSE IF(FIND_STRING(myTCP.Rx,'Password:',1)){
			fnDebug(FALSE,'SX->',myTCP.Rx)
			myTCP.Rx = ''
			IF(myTCP.Password == ''){myTCP.Password = 'admin'}
			fnDebug(FALSE,'->SX',"myTCP.Password,$0D")
			SEND_STRING ipConn, "myTCP.Password,$0D"
		}
		ELSE{
			WHILE(FIND_STRING(myTCP.Rx,"$0D,$0A",1)){
				REMOVE_STRING(myTCP.Rx,"$0D,$0A",1)
			}
			IF(FIND_STRING(myTCP.RX,'VBrick# ',1)){
				myTCP.CONN_STATE = CONN_CONNECTED
				myTCP.Rx = ''
			}
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{ 
						myTCP.IP = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
						myTCP.PORT = ATOI(DATA.TEXT)
						IF(TIMELINE_ACTIVE(TLID_BOOT)){TIMELINE_KILL(TLID_BOOT)}
						TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
					CASE 'DEBUG': myTCP.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE');	
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			// Listed as "Stream_Clear, Stream_Begin, Stream_Quit"
			CASE 'ACTION':{
				SWITCH(DATA.TEXT){
					CASE 'CLEAR':fnSendCommand('EE')
					CASE 'BEGIN':fnSendCommand('BE')
					CASE 'QUIT': fnSendCommand('QUIT')
				}
			}
			// Actual Stream Control?
			CASE 'STREAM':{
				STACK_VAR INTEGER pID
				pID = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				SWITCH(DATA.TEXT){
					CASE 'APPLY':fnSendCommand("'svar vbrickProgramArchiverApplySet.',ITOA(pID),'=1'")
					CASE 'START':fnSendCommand("'svar vbrickProgramArchiverControl.',ITOA(pID),'=2'")
					CASE 'STOP': fnSendCommand("'svar vbrickProgramArchiverControl.',ITOA(pID),'=3'")
				}
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	IP_CLIENT_OPEN(ipConn.PORT,myTCP.IP,myTCP.PORT,IP_TCP)
}