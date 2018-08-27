MODULE_NAME='mAtlonaCLSO'(DEV vdvControl, DEV dvDevice)
INCLUDE 'CustomFunctions'

DEFINE_TYPE STRUCTURE uCLSO{
	// COMMS
	CHAR 		RX[500]
	CHAR 		TX[500]
	INTEGER	PEND
	INTEGER 	isIP
	CHAR		IP_HOST[255]
	INTEGER 	IP_PORT
	INTEGER 	CONN_STATE
	INTEGER 	DEBUG
	INTEGER	TYPE	// Model Type
	// META STATE
	CHAR 		MODEL[20]
	CHAR 		VER_MCU[20]
	CHAR 		VER_FPG[20]
	CHAR 		VER_OSD[20]
	CHAR 		VER_DSP[20]
	// STATE
	INTEGER POWER
	CHAR 		INPUT[6][15]
}
DEFINE_CONSTANT
INTEGER DEV_TYPE_CLSO_824		= 1
INTEGER DEV_TYPE_CLSO_612		= 2
INTEGER DEV_TYPE_PRO3_66M		= 3

INTEGER CONN_STATE_OFFLINE 	= 0
INTEGER CONN_STATE_TRYING		= 1
INTEGER CONN_STATE_CONNECTED	= 2

LONG TLID_COMMS				= 1
LONG TLID_POLL					= 2
LONG TLID_TIMEOUT				= 3

INTEGER PEND_COMMAND			= 1
INTEGER PEND_POLL_POWER		= 2
INTEGER PEND_POLL_TYPE		= 3
INTEGER PEND_POLL_VER_MCU	= 4
INTEGER PEND_POLL_VER_FPG	= 5
INTEGER PEND_POLL_VER_OSD	= 6
INTEGER PEND_POLL_VER_DSP	= 7
INTEGER PEND_POLL_STATUS	= 8

DEFINE_VARIABLE
LONG TLT_COMMS[] 		= { 90000 }
LONG TLT_POLL[] 		= { 15000 }
LONG TLT_TIMEOUT[]	= {  3000 }

VOLATILE uCLSO myCLSO

DEFINE_START{
	myCLSO.isIP = !(dvDEVICE.NUMBER)
	myCLSO.IP_PORT = 23
	CREATE_BUFFER dvDevice, myCLSO.RX
}

(** IP Connection Helpers **)
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myCLSO.IP_HOST == ''){
		fnDebug(TRUE,'CLSO IP','Not Set')
	}
	ELSE{
		fnDebug(FALSE,'Connecting to CLSO ',"myCLSO.IP_HOST,':',ITOA(myCLSO.IP_PORT)")
		myCLSO.CONN_STATE = CONN_STATE_TRYING
		ip_client_open(dvDevice.port, myCLSO.IP_HOST, myCLSO.IP_PORT, IP_TCP) 
	}
} 

DEFINE_FUNCTION fnInitTimeout(){
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
	TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	myCLSO.PEND = FALSE
	myCLSO.TX = ''
	fnCloseTCPConnection()
}

DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(dvDevice.port)
}

DEFINE_FUNCTION fnInitPoll(){	
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

DEFINE_FUNCTION fnPoll(){
	SWITCH(myCLSO.TYPE){
		CASE DEV_TYPE_PRO3_66M:
		CASE DEV_TYPE_CLSO_824:	
		CASE DEV_TYPE_CLSO_612:	fnSendQuery(PEND_POLL_POWER)
		
		DEFAULT:					fnSendQuery(PEND_POLL_TYPE)
	}
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'IP':{
						myCLSO.IP_HOST = DATA.TEXT
						fnPoll()
					}
					CASE 'DEBUG':myCLSO.DEBUG = (ATOI(DATA.TEXT) || DATA.TEXT == 'TRUE')
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'MATRIX':{
				SWITCH(myCLSO.TYPE){
					CASE DEV_TYPE_PRO3_66M:
					CASE DEV_TYPE_CLSO_824:{
						IF(myCLSO.POWER){
							fnSendCommand("'x',fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1),'AVx',DATA.TEXT")
						}
						ELSE{
							fnSendCommand('PWON')
							myCLSO.Tx = "'x',fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1),'AVx',DATA.TEXT"
						}
					}
				}
			}
			CASE 'INPUT':{
				SWITCH(myCLSO.TYPE){
					CASE DEV_TYPE_CLSO_612:{
						STACK_VAR CHAR TYPE[10]
						TYPE = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						IF(!myCLSO.POWER){ fnSendCommand('PWON') }
						fnSendCommand("'Input ',TYPE,' ',DATA.TEXT")
					}
				}
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'OFF':	fnSendCommand('PWOFF')
					CASE 'ON':	fnSendCommand('PWON')
				}
			}
		}
	}
}

DEFINE_FUNCTION fnSendCommand(CHAR pToSend[]){
	fnAddToQueue(PEND_COMMAND,pToSend)
}
DEFINE_FUNCTION fnSendQuery(INTEGER pPOLL){
	SWITCH(pPOLL){
		CASE PEND_POLL_POWER:	fnAddToQueue(pPOLL,'PWSTA')
		CASE PEND_POLL_STATUS:{
			SWITCH(myCLSO.TYPE){
				CASE DEV_TYPE_CLSO_612: fnAddToQueue(pPOLL,'Input sta')
				CASE DEV_TYPE_PRO3_66M:
				CASE DEV_TYPE_CLSO_824: fnAddToQueue(pPOLL,'Status')
			}
		}
		CASE PEND_POLL_TYPE:		fnAddToQueue(pPOLL,'Type')
		CASE PEND_POLL_VER_DSP:	fnAddToQueue(pPOLL,'VersionDSP')
		CASE PEND_POLL_VER_FPG:	fnAddToQueue(pPOLL,'VersionMCU')
		CASE PEND_POLL_VER_MCU:	fnAddToQueue(pPOLL,'VersionFPGA')
		CASE PEND_POLL_VER_OSD:	fnAddToQueue(pPOLL,'VersionOSD')
	}
}
DEFINE_FUNCTION fnAddToQueue(INTEGER pTYPE,CHAR pDATA[]){
	myCLSO.Tx = "myCLSO.Tx,pTYPE+$80,pDATA,$0D"
	fnSendFromQueue()
	fnInitPoll()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(myCLSO.isIP && myCLSO.CONN_STATE == CONN_STATE_OFFLINE){
		fnOpenTCPConnection()
		RETURN
	}
	IF(myCLSO.CONN_STATE == CONN_STATE_CONNECTED && !myCLSO.PEND && FIND_STRING(myCLSO.Tx,"$0D",1)){
		STACK_VAR CHAR toSend[50]
		myCLSO.PEND = GET_BUFFER_CHAR(myCLSO.Tx)-$80
		toSend = REMOVE_STRING(myCLSO.Tx,"$0D",1)
		fnDebug(FALSE,'->CLSO',toSend)
		SEND_STRING dvDevice, "toSend"
	}
	IF(myCLSO.isIP && myCLSO.CONN_STATE == CONN_STATE_CONNECTED){ 
		fnInitTimeout() 
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pData[]){
	
	fnDebug(FALSE,'CLSO->',pData)
	
	SWITCH(pData){
		CASE 'Command FAILED':{
			myCLSO.PEND = FALSE
			fnSendFromQueue()
		}
		CASE '':{}
		CASE 'Welcome to TELNET.':{
			myCLSO.CONN_STATE = CONN_STATE_CONNECTED
			fnSendFromQueue()
		}
		DEFAULT:{
			SWITCH(pData){
				CASE 'PWON':{
					myCLSO.POWER = TRUE
					IF(myCLSO.PEND == PEND_POLL_POWER){
						fnSendQuery(PEND_POLL_STATUS)
					}
				}
				CASE 'PWOFF':{
					myCLSO.POWER = TRUE
					WAIT 100{fnSendCommand('PWON')}
				}
				DEFAULT:{
					SWITCH(myCLSO.PEND){
						CASE PEND_POLL_STATUS:{
							SWITCH(myCLSO.TYPE){
								CASE DEV_TYPE_CLSO_612:{
									IF(myCLSO.INPUT[1] != pData){
										myCLSO.INPUT[1] = pDATA
										SEND_STRING vdvControl,"'INPUT-',myCLSO.INPUT[1]"
									}
								}
								CASE DEV_TYPE_PRO3_66M:
								CASE DEV_TYPE_CLSO_824:{
									IF(myCLSO.INPUT[1] != fnInputFromNumber(ATOI("pData[2]"))){
										myCLSO.INPUT[1] = fnInputFromNumber(ATOI("pData[2]"))
										SEND_STRING vdvControl,"'MATIRIX-',pData[2],'*1'"
										SEND_STRING vdvControl,"'INPUT-1,',myCLSO.INPUT[1]"
									}
									IF(myCLSO.INPUT[2] != fnInputFromNumber(ATOI("pData[9]"))){
										myCLSO.INPUT[2] = fnInputFromNumber(ATOI("pData[9]"))
										SEND_STRING vdvControl,"'MATIRIX-',pData[9],'*2'"
										SEND_STRING vdvControl,"'INPUT-2,',myCLSO.INPUT[2]"
									}
									SWITCH(myCLSO.TYPE){
										CASE DEV_TYPE_PRO3_66M:{
											IF(myCLSO.INPUT[3] != fnInputFromNumber(ATOI("pData[16]"))){
												myCLSO.INPUT[3] = fnInputFromNumber(ATOI("pData[16]"))
												SEND_STRING vdvControl,"'MATIRIX-',myCLSO.INPUT[3],'*3'"
												SEND_STRING vdvControl,"'INPUT-3,',myCLSO.INPUT[3]"
											}
											IF(myCLSO.INPUT[4] != fnInputFromNumber(ATOI("pData[23]"))){
												myCLSO.INPUT[4] = fnInputFromNumber(ATOI("pData[23]"))
												SEND_STRING vdvControl,"'MATIRIX-',myCLSO.INPUT[4],'*4'"
												SEND_STRING vdvControl,"'INPUT-4,',myCLSO.INPUT[4]"
											}
											IF(myCLSO.INPUT[5] != fnInputFromNumber(ATOI("pData[30]"))){
												myCLSO.INPUT[5] = fnInputFromNumber(ATOI("pData[30]"))
												SEND_STRING vdvControl,"'MATIRIX-',myCLSO.INPUT[5],'*5'"
												SEND_STRING vdvControl,"'INPUT-5,',myCLSO.INPUT[5]"
											}
											IF(myCLSO.INPUT[6] != fnInputFromNumber(ATOI("pData[37]"))){
												myCLSO.INPUT[6] = fnInputFromNumber(ATOI("pData[37]"))
												SEND_STRING vdvControl,"'MATIRIX-',myCLSO.INPUT[6],'*6'"
												SEND_STRING vdvControl,"'INPUT-6,',myCLSO.INPUT[6]"
											}
										}
									}
								}
							}
						}
						CASE PEND_POLL_TYPE:{
							myCLSO.MODEL = pData
							SWITCH(myCLSO.MODEL){
								CASE 'ATL-UHD-CLSO-824':	myCLSO.TYPE = DEV_TYPE_CLSO_824
								CASE 'AT-UHD-CLSO-612ED':
								CASE 'AT-UHD-CLSO-612':		myCLSO.TYPE = DEV_TYPE_CLSO_612
								CASE 'AT-UHD-PRO3-66M':		myCLSO.TYPE = DEV_TYPE_PRO3_66M
							}
							SWITCH(myCLSO.MODEL){
								CASE DEV_TYPE_CLSO_824:
								CASE DEV_TYPE_CLSO_612:{
									fnSendQuery(PEND_POLL_VER_DSP)
									fnSendQuery(PEND_POLL_VER_FPG)
									fnSendQuery(PEND_POLL_VER_MCU)
									fnSendQuery(PEND_POLL_VER_OSD)
								}
							}
							fnPoll()
						}
						CASE PEND_POLL_VER_DSP:{
							IF(myCLSO.VER_DSP != pDATA){
								myCLSO.VER_DSP = pDATA
								SEND_STRING vdvControl,"'PROPERTY-META,VER_DSP,',myCLSO.VER_DSP"
							}
						}
						CASE PEND_POLL_VER_FPG:{
							IF(myCLSO.VER_FPG != pDATA){
								myCLSO.VER_FPG = pDATA
								SEND_STRING vdvControl,"'PROPERTY-META,VER_FPG,',myCLSO.VER_FPG"
							}
						}
						CASE PEND_POLL_VER_MCU:{
							IF(myCLSO.VER_MCU != pDATA){
								myCLSO.VER_MCU = pDATA
								SEND_STRING vdvControl,"'PROPERTY-META,VER_MCU,',myCLSO.VER_MCU"
							}
						}
						CASE PEND_POLL_VER_OSD:{
							IF(myCLSO.VER_OSD != pDATA){
								myCLSO.VER_OSD = pDATA
								SEND_STRING vdvControl,"'PROPERTY-META,VER_OSD,',myCLSO.VER_OSD"
							}
						}
					}
				}
			}
			myCLSO.PEND = FALSE
			fnSendFromQueue()
		}
	}
}
DEFINE_FUNCTION CHAR[10] fnInputFromNumber(INTEGER pInput){
	SWITCH(pInput){
		CASE 1: RETURN 'HDBaseT 1'
		CASE 2: RETURN 'HDBaseT 2'
		CASE 3: RETURN 'HDBaseT 3'
		CASE 4: RETURN 'HDMI 1'
		CASE 5: RETURN 'HDMI 5'
		CASE 6: RETURN 'HDMI 6'
		CASE 7: RETURN 'HDMI 7'
		CASE 8: RETURN 'VGA 1'
	}
}
DEFINE_FUNCTION fnDebug(INTEGER pFORCE,CHAR Msg[], CHAR MsgData[]){
	IF(myCLSO.DEBUG || pFORCE)	{
		SEND_STRING 0:0:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
DEFINE_EVENT DATA_EVENT[dvDevice]{
	ONLINE:{
		IF(!myCLSO.isIP){
			SEND_COMMAND dvDevice,'SET BAUD 115200 N,8,1 485 DISABLE'
			myCLSO.CONN_STATE = CONN_STATE_CONNECTED
			fnInitPoll()
			fnPoll()
		}
	}
	OFFLINE:{
		IF(myCLSO.isIP){
			myCLSO.CONN_STATE 	= CONN_STATE_OFFLINE
			myCLSO.Tx = ''
		}
	}
	ONERROR:{
		IF(myCLSO.isIP){
			STACK_VAR CHAR _MSG[255]
			SWITCH(DATA.NUMBER){
				CASE 14:_MSG = 'Local Port Already Used'	// Local Port Already Used
				DEFAULT:{
					myCLSO.CONN_STATE = CONN_STATE_OFFLINE
					SWITCH(DATA.NUMBER){
						CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
						CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
						CASE 6:{ _MSG = 'Conn Refused'}						// Connection Refused
						CASE 7:{ _MSG = 'Conn Timed Out'}					// Connection Timed Out
						CASE 8:{ _MSG = 'Unknown'}								// Unknown Connection Error
						CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
						CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
						CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
						CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
						CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
						CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
					}
				}
			}
			fnDebug(TRUE,"'CLSO IP Error:[',myCLSO.IP_HOST,']'","'[',ITOA(DATA.NUMBER),'][',_MSG,']'")
			myCLSO.TX = ''
		}
	}
	STRING:{
		fnDebug(FALSE,'CLSORAW->',DATA.TEXT)
		IF(DATA.TEXT == "$0D"){
			myCLSO.PEND = FALSE
			fnSendCommand('PWON')
		}
		ELSE{
			WHILE(FIND_STRING(myCLSO.Rx,"$0D,$0A",1)){
				fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myCLSO.Rx,"$0D,$0A",1),2))
				IF(TIMELINE_ACTIVE(TLID_COMMS)){ TIMELINE_KILL(TLID_COMMS) }
				TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
			}
			IF(myCLSO.Rx[1] == '>'){
				GET_BUFFER_CHAR(myCLSO.RX)
			}
		}
	}
}
DEFINE_PROGRAM{
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvControl,255] = (myCLSO.POWER)
}