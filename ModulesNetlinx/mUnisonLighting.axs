MODULE_NAME='mUnisonLighting'(DEV vdvControl, DEV ipClient, DEV ipServer)
INCLUDE 'CustomFunctions'
/******************************************************************************
	UDP Port 4704 being sent to 192.168.1.33 for feedback

******************************************************************************/

/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
CHAR MODULENAME[] = __FILE__;
INTEGER portSend 		= 4703
INTEGER portRecieve 	= 4704
LONG TLID_SEND			= 1
LONG TLID_POLL			= 2
LONG TLID_COMMS		= 3

/******************************************************************************
	Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uUnisonComms{
	INTEGER DEBUG
	CHAR IP[128]
	CHAR Tx[2000]
	INTEGER CONNECTED_Tx
	INTEGER CONNECTED_Rx
}
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_SEND[]		= {100}
LONG TLT_POLL[]		= {15000}
LONG TLT_COMMS[]		= {30000}
VOLATILE uUnisonComms myUnisonComms
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnOpenSendPort(){
	IP_CLIENT_OPEN(ipClient.PORT, myUnisonComms.IP, portSend, IP_UDP)
}

DEFINE_FUNCTION fnOpenRecievePort(){
	IP_SERVER_OPEN(ipServer.PORT, portRecieve, IP_UDP)
}
DEFINE_FUNCTION fnQueueSend(CHAR Cmd[]){
	myUnisonComms.Tx = "myUnisonComms.Tx,Cmd,$0D"
	IF(!TIMELINE_ACTIVE(TLID_SEND)){
		fnDoSend(REMOVE_STRING(myUnisonComms.Tx,"$0D",1))
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	IF(FIND_STRING(myUnisonComms.Tx,"$0D",1)){
		fnDoSend(REMOVE_STRING(myUnisonComms.Tx,"$0D",1))
		TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}
DEFINE_FUNCTION fnDoSend(CHAR _CMD[]){
	fnDebug('AMX->Unison',_CMD)
	SEND_STRING ipClient, "_CMD"
	fnInitPoll()
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myUnisonComms.DEBUG = 1)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnQueueSend('ping');
}
(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myUnisonComms.IP = DATA.TEXT
						fnOpenSendPort()
						fnOpenRecievePort()
					}
					CASE 'DEBUG':{myUnisonComms.DEBUG = (DATA.TEXT == '1' || UPPER_STRING(DATA.TEXT) == 'TRUE')}
				}
			}
			CASE 'RAW':		fnQueueSend( DATA.TEXT )
			CASE 'RECALL': fnQueueSend("'pst act ',DATA.TEXT")
			CASE 'CANCEL': fnQueueSend("'pst dact ',DATA.TEXT")
			CASE 'GET':		fnQueueSend("'pst get ',DATA.TEXT")
			CASE 'MACRO':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ON':  fnQueueSend("'macro on ', DATA.TEXT")
					CASE 'OFF': fnQueueSend("'macro off ', DATA.TEXT")
				}
			}
		}
	}
}

DATA_EVENT[ipClient]{
	ONLINE: {myUnisonComms.CONNECTED_Tx = TRUE}
	OFFLINE:{myUnisonComms.CONNECTED_Tx = FALSE}
	STRING: {}
	ONERROR:{
		SEND_STRING 0,"'IP Error:', ITOA(DATA.NUMBER), ' ', DATA.TEXT"
	}
}


DEFINE_EVENT DATA_EVENT[ipServer]{
	ONLINE: {
		myUnisonComms.CONNECTED_Rx = TRUE
		fnInitPoll()
	}
	OFFLINE:{myUnisonComms.CONNECTED_Rx = FALSE}
	STRING:{
		fnDebug('Unison->AMX',DATA.TEXT)
		IF(TIMELINE_ACTIVE(TLID_COMMS)){
			TIMELINE_KILL(TLID_COMMS);
		}
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
}

/******************************************************************************
	Feedback
******************************************************************************/
DEFINE_PROGRAM{
	[vdvControl,251] = ( TIMELINE_ACTIVE(TLID_COMMS) )
	[vdvControl,252] = ( TIMELINE_ACTIVE(TLID_COMMS) )
}