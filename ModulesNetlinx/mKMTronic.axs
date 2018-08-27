MODULE_NAME='mKMTronic'(DEV vdvControl, DEV ipUDP)
INCLUDE 'CustomFunctions'
/******************************************************************************
	UDP Port 12345 being sent to 192.168.1.33 for feedback
	
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_POLL			= 1
LONG TLID_COMMS		= 2

DEFINE_TYPE STRUCTURE uKMTronic{
	INTEGER IP_PORT
	CHAR    IP_HOST[30]
	INTEGER IP_ONLINE
	INTEGER DEBUG
}

DEFINE_VARIABLE
VOLATILE uKMTronic myKMTronic
LONG TLT_POLL[]		= {15000}
LONG TLT_COMMS[]		= {60000}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myKMTronic.DEBUG = 1)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR pCMD[]){
	fnDebug('->KMT',pCMD)
	SEND_STRING ipUDP,pCMD
}
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnSendCommand('FF0000')
}
		
DEFINE_EVENT DATA_EVENT[ipUDP]{
	STRING:{
		fnDebug('KMT->',DATA.TEXT)
		IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
		TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	ONLINE:{
		fnSendCommand('FF0000')
		fnInitPoll()
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myKMTronic.IP_HOST	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myKMTronic.IP_PORT	= ATOI(DATA.TEXT)
						}
						ELSE{
							myKMTronic.IP_HOST = DATA.TEXT
							myKMTronic.IP_PORT = 12345
						}
						IP_CLIENT_OPEN(ipUDP.PORT, myKMTronic.IP_HOST, myKMTronic.IP_PORT, IP_UDP_2WAY)
					}
					CASE 'DEBUG':{
						myKMTronic.DEBUG = (DATA.TEXT == '1' || UPPER_STRING(DATA.TEXT) == 'TRUE')
					}
				}
			}
			CASE 'RAW':		fnSendCommand( DATA.TEXT )
			CASE 'RELAY':{
				SWITCH(DATA.TEXT){
					CASE '0,ON': fnSendCommand('FFE003')
					CASE '0,OFF':fnSendCommand('FFE000')
					CASE '1,ON': fnSendCommand('FF0101')
					CASE '1,OFF':fnSendCommand('FF0100')
					CASE '2,ON': fnSendCommand('FF0201')
					CASE '2,OFF':fnSendCommand('FF0200')
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
}