MODULE_NAME='mViscaOverIP'(DEV vdvCamera[],DEV ipCAM[], DEV ipFB, DEV ipMC)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Visca Over IP (Developed and tested on Sony)

	For Discovery & Assign:
	PROPERTY-NETWORK,MAC,IP,SUBNET,GATEWAY
	
	For Static Set IP:
	PROPERTY-IP,xxx
	PROPERTY-MODE,STATIC

	Module will set IP address on auto discovery, or set static IP
******************************************************************************/
DEFINE_CONSTANT
INTEGER QUEUE_LENGTH = 10
/******************************************************************************
	Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uCam{
	INTEGER	CONN_ONLINE
	CHAR 		MAC_ADD[20]
	CHAR 		IP_HOST[15]
	CHAR		GATEWAY[30]
	CHAR		SUBNET[30]
	INTEGER  MODE
	INTEGER	SEQUENCE
	CHAR     TxLast[10]
	CHAR     TxCmd[QUEUE_LENGTH][10]
	CHAR     TxQry[QUEUE_LENGTH][10]

	INTEGER	SPEED_PAN
	INTEGER	SPEED_TILT

	// Meta
	CHAR     VENDOR[20]
	CHAR		MODEL[20]

	// Status
	INTEGER	POWER
}
DEFINE_TYPE STRUCTURE uVisca{
	INTEGER	DEBUG
	INTEGER	IP_PORT_MC
	INTEGER	IP_PORT_FB

	uCam		CAM[5]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

INTEGER MODE_AUTO   = 0
INTEGER MODE_STATIC = 1

LONG TLID_POLL_MC	= 1

LONG TLID_POLL_FB_00	= 10
LONG TLID_POLL_FB_01	= 11
LONG TLID_POLL_FB_02	= 12
LONG TLID_POLL_FB_03	= 13
LONG TLID_POLL_FB_04	= 14
LONG TLID_POLL_FB_05	= 15

LONG TLID_COMMS00	= 20
LONG TLID_COMMS01	= 21
LONG TLID_COMMS02	= 22
LONG TLID_COMMS03	= 23
LONG TLID_COMMS04	= 24
LONG TLID_COMMS05	= 25

LONG TLID_TIMEOUT00	= 30
LONG TLID_TIMEOUT01	= 31
LONG TLID_TIMEOUT02	= 32
LONG TLID_TIMEOUT03	= 33
LONG TLID_TIMEOUT04	= 34
LONG TLID_TIMEOUT05	= 35

LONG TLID_SEND00	= 40
LONG TLID_SEND01	= 41
LONG TLID_SEND02	= 42
LONG TLID_SEND03	= 43
LONG TLID_SEND04	= 44
LONG TLID_SEND05	= 45
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uVisca myViscaIP

LONG TLT_POLL_MC[] 	= {  30000 }
LONG TLT_POLL_FB[] 	= {  15000 }
LONG TLT_COMMS[]   	= {  90000 }
LONG TLT_TIMEOUT[]   = {   2000 }
LONG TLT_SEND[]   	= {    100 }
/******************************************************************************
	General Utilities
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(myViscaIP.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvCamera[1].Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Connection Utilities
******************************************************************************/
DEFINE_FUNCTION fnOpenClientConnection(INTEGER pCAM){

	IF(!LENGTH_ARRAY(myViscaIP.CAM[pCAM].IP_HOST)){
		fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP ADDRESS NOT CONFIGURED')
		RETURN
	}
	
	IF(myViscaIP.CAM[pCAM].MODE == MODE_AUTO){
		IF(!LENGTH_ARRAY(myViscaIP.CAM[pCAM].MAC_ADD)){
			fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'MAC ADDRESS NOT CONFIGURED')
			RETURN
		}


		IF(!LENGTH_ARRAY(myViscaIP.CAM[pCAM].SUBNET)){
			fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP SUBNET NOT CONFIGURED')
			RETURN
		}

		IF(!LENGTH_ARRAY(myViscaIP.CAM[pCAM].GATEWAY)){
			fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP GATEWAY NOT CONFIGURED')
			RETURN
		}
	}

	// Start Unicast Client
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Client (Unicast UDP 2WAY)')
	IP_CLIENT_OPEN(ipCAM[pCAM].PORT,myViscaIP.CAM[pCAM].IP_HOST,myViscaIP.IP_PORT_FB,IP_UDP_2WAY)

}

DEFINE_FUNCTION fnCloseConnection(INTEGER pCAM){
	IP_CLIENT_CLOSE(ipCAM[pCAM].PORT)
}

DEFINE_FUNCTION fnAddToQueue(INTEGER pCAM,CHAR pData[],INTEGER isQuery){
	STACK_VAR INTEGER x
	fnDebug(DEBUG_STD,'pData Length',LENGTH_ARRAY(pData))
	fnDebug(DEBUG_STD,'pData Value',pData)
	fnDebug(DEBUG_STD,'pData Length',LENGTH_ARRAY(pData))
	
	SWITCH(isQuery){
		CASE TRUE:{
			FOR(x = 1; x <= QUEUE_LENGTH; x++){
				IF(myViscaIP.CAM[pCAM].TxQry[x] == ''){
					myViscaIP.CAM[pCAM].TxQry[x] = pDATA
					BREAK
				}
				
			}
		}
		CASE FALSE:{
			FOR(x = 1; x <= QUEUE_LENGTH; x++){
				IF(myViscaIP.CAM[pCAM].TxCmd[x] == ''){
					myViscaIP.CAM[pCAM].TxCmd[x] = pDATA
					BREAK
				}
			}
		}
	}
	fnSendFromQueue(pCAM)
}

DEFINE_FUNCTION fnSendFromQueue(INTEGER pCAM){
	IF(!TIMELINE_ACTIVE(TLID_SEND00+pCAM)){
		STACK_VAR CHAR pDATA[50]
		STACK_VAR INTEGER x
		SELECT{
			ACTIVE(LENGTH_ARRAY(myViscaIP.CAM[pCAM].TxQry[1])):{
				pDATA = myViscaIP.CAM[pCAM].TxQry[1]
				FOR(x = 1; x < QUEUE_LENGTH; x++){
					myViscaIP.CAM[pCAM].TxQry[x] = myViscaIP.CAM[pCAM].TxQry[x+1]
				}
				myViscaIP.CAM[pCAM].TxQry[QUEUE_LENGTH] = ''
			}
			ACTIVE(LENGTH_ARRAY(myViscaIP.CAM[pCAM].TxCmd[1])):{
				pDATA = myViscaIP.CAM[pCAM].TxCmd[1]
				FOR(x = 1; x < QUEUE_LENGTH; x++){
					myViscaIP.CAM[pCAM].TxCmd[x] = myViscaIP.CAM[pCAM].TxCmd[x+1]
				}
				myViscaIP.CAM[pCAM].TxCmd[QUEUE_LENGTH] = ''
			}
		}
		IF(LENGTH_ARRAY(pDATA)){
			STACK_VAR CHAR toSend[200]
			myViscaIP.CAM[pCAM].SEQUENCE++
			myViscaIP.CAM[pCAm].TxLast = pDATA
			toSend = "$01,$10,$00,$02+LENGTH_ARRAY(pDATA),$00,$00,$00,myViscaIP.CAM[pCAM].SEQUENCE,$81,pDATA,$FF"
			SEND_STRING ipCAM[pCAM],toSend
			fnDebug(DEBUG_STD,"'->CAM',FORMAT('%02d',pCAM)",fnBytesToString(toSend))
			fnInitTimeoutSequence(pCAM)
			fnInitPoll_FB(pCAM)
			TIMELINE_CREATE(TLID_SEND00+pCAM,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_SEND01]
TIMELINE_EVENT[TLID_SEND02]
TIMELINE_EVENT[TLID_SEND03]
TIMELINE_EVENT[TLID_SEND04]
TIMELINE_EVENT[TLID_SEND05]{
	fnSendFromQueue(TIMELINE.ID-TLID_SEND00)
}

/******************************************************************************
	Polling Utilities
******************************************************************************/
DEFINE_FUNCTION fnInitPoll_FB(INTEGER pCAM){
	// Kill Current Polling if timeline active
	IF(TIMELINE_ACTIVE(TLID_POLL_FB_00+pCAM)){TIMELINE_KILL(TLID_POLL_FB_00+pCAM)}
	// Start polling
	TIMELINE_CREATE(TLID_POLL_FB_00+pCAM,TLT_POLL_FB,LENGTH_ARRAY(TLT_POLL_FB),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT
TIMELINE_EVENT[TLID_POLL_FB_01]
TIMELINE_EVENT[TLID_POLL_FB_02]
TIMELINE_EVENT[TLID_POLL_FB_03]
TIMELINE_EVENT[TLID_POLL_FB_04]
TIMELINE_EVENT[TLID_POLL_FB_05]{
	fnPoll_FB(TIMELINE.ID - TLID_POLL_FB_00)
}
DEFINE_FUNCTION fnPoll_FB(INTEGER pCAM){
	// Poll out
	IF(myViscaIP.CAM[pCam].VENDOR = ''){
		fnAddToQueue(pCAM,"$09,$00,$02",TRUE)	// Vesion Enquiry
	}
	ELSE{
		fnAddToQueue(pCAM,"$09,$04,$00",TRUE)	// Power State Enquiry
		fnAddToQueue(pCAM,"$09,$06,$12",TRUE)	// PanTilt Pos Enquiry
		fnAddToQueue(pCAM,"$09,$04,$47",TRUE)		// Zoom Pos Enquiry
	}
}

DEFINE_FUNCTION fnInitPoll_MC(){
	// Kill Current Polling if timeline active
	IF(TIMELINE_ACTIVE(TLID_POLL_MC)){TIMELINE_KILL(TLID_POLL_MC)}
	// Start polling
	TIMELINE_CREATE(TLID_POLL_MC,TLT_POLL_MC,LENGTH_ARRAY(TLT_POLL_MC),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_EVENT TIMELINE_EVENT[TLID_POLL_MC]{
	fnPoll_MC()
}

DEFINE_FUNCTION fnPoll_MC(){
	STACK_VAR CHAR toSend[255]
	toSend = "$02,'ENQ:network',$FF,$03"
	fnDebug(DEBUG_DEV,'->CAMMC',toSend)
	SEND_STRING ipMC,toSend
}
DEFINE_FUNCTION fnInitTimeoutSequence(INTEGER pCAM){
	// Kill Current Polling if timeline active
	IF(TIMELINE_ACTIVE(TLID_TIMEOUT00+pCAM)){TIMELINE_KILL(TLID_TIMEOUT00+pCAM)}
	// Start polling
	TIMELINE_CREATE(TLID_TIMEOUT00+pCAM,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}
DEFINE_EVENT
TIMELINE_EVENT[TLID_TIMEOUT01]
TIMELINE_EVENT[TLID_TIMEOUT02]
TIMELINE_EVENT[TLID_TIMEOUT03]
TIMELINE_EVENT[TLID_TIMEOUT04]
TIMELINE_EVENT[TLID_TIMEOUT05]{
	STACK_VAR CHAR toSend[255]
	STACK_VAR INTEGER pCAM
	pCAM = TIMELINE.ID - TLID_TIMEOUT00
	toSend = "$02,$00,$00,$01,$00,$00,$00,$01,$01"
	fnDebug(DEBUG_STD,"'->CAM',FORMAT('%02d',pCAM)",fnBytesToString(toSend))
	SEND_STRING ipCAM[pCAM],toSend
	myViscaIP.CAM[pCAM].SEQUENCE = 0
}
/******************************************************************************
	Feedback Handlers
******************************************************************************/
DEFINE_FUNCTION fnProcessMulticast(CHAR pDATA[]){
	STACK_VAR CHAR MAC_ADD[50]
	STACK_VAR CHAR IP_HOST[50]
	STACK_VAR CHAR INFO[50]
	STACK_VAR CHAR GATEWAY[50]
	STACK_VAR CHAR SUBNET[50]
	STACK_VAR CHAR NAME[50]
	// Debug
	fnDebug(DEBUG_DEV,'fnProcessMulticast()',pDATA)
	// Strip Delims
	GET_BUFFER_CHAR(pDATA)
	pDATA = fnStripCharsRight(pDATA,1)
	WHILE(FIND_STRING(pDATA,"$FF",1)){
		STACK_VAR CHAR pCHUNK[255]
		pCHUNK = fnStripCharsRight(REMOVE_STRING(pDATA,"$FF",1),1)
		SWITCH(fnStripCharsRight(REMOVE_STRING(pCHUNK,':',1),1)){
			CASE 'INFO':	INFO 		= pCHUNK
			CASE 'MAC':		MAC_ADD 	= pCHUNK
			CASE 'IPADR':	IP_HOST 	= pCHUNK
			CASE 'MASK':	SUBNET 	= pCHUNK
			CASE 'GATEWAY':GATEWAY 	= pCHUNK
			CASE 'NAME':	NAME 		= pCHUNK
			CASE 'ACK':{
				STACK_VAR INTEGER x
				// Camera Configured
				FOR(x = 1; x <= LENGTH_ARRAY(vdvCamera); x++){
					IF(pCHUNK == myViscaIP.CAM[x].MAC_ADD){
						fnDebug(DEBUG_STD,"'Camera ',ITOA(x)",'Configured')
					}
				}
			}
		}
	}

	// Report out for configuration
	fnDebug(DEBUG_STD,'MC INFO',INFO)
	fnDebug(DEBUG_STD,'MC MAC',MAC_ADD)
	fnDebug(DEBUG_STD,'MC IPADR',IP_HOST)
	fnDebug(DEBUG_STD,'MC MASK',SUBNET)
	fnDebug(DEBUG_STD,'MC GATEWAY',GATEWAY)
	fnDebug(DEBUG_STD,'MC NAME',NAME)

	// Process on Data
	IF(INFO == 'network'){
		STACK_VAR INTEGER x
		fnDebug(DEBUG_DEV,'fnProcessMulticast()','INFO == network')
		FOR(x = 1; x <= LENGTH_ARRAY(vdvCamera); x++){
			IF(MAC_ADD == myViscaIP.CAM[x].MAC_ADD){
				fnDebug(DEBUG_DEV,'fnProcessMulticast()','MAC_ADD == myCamera.MAC_ADD')

				IF(IP_HOST != myViscaIP.CAM[x].IP_HOST || SUBNET != myViscaIP.CAM[x].SUBNET || GATEWAY != myViscaIP.CAM[x].GATEWAY){
					STACK_VAR CHAR pSetNetwork[255]
					fnDebug(DEBUG_DEV,'fnProcessMulticast()','Configure Network Settings')
					pSetNetwork = "'MAC:',myViscaIP.CAM[x].MAC_ADD,$FF"
					pSetNetwork = "pSetNetwork,'IPADR:',myViscaIP.CAM[x].IP_HOST,$FF"
					pSetNetwork = "pSetNetwork,'MASK:',myViscaIP.CAM[x].SUBNET,$FF"
					pSetNetwork = "pSetNetwork,'GATEWAY:',myViscaIP.CAM[x].GATEWAY,$FF"
					pSetNetwork = "pSetNetwork,'NAME:',NAME,$FF"
					pSetNetwork = "$02,pSetNetwork,$03"
					fnDebug(DEBUG_DEV,'->CAMMC',pSetNetwork)
					SEND_STRING ipMC,pSetNetwork
				}
				ELSE{
					fnDebug(DEBUG_DEV,'fnProcessMulticast()','Device Correctly Configured')
					IF(TIMELINE_ACTIVE(TLID_COMMS00+x)){TIMELINE_KILL(TLID_COMMS00+x)}
					TIMELINE_CREATE(TLID_COMMS00+x,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
			}
		}
	}
}

DEFINE_FUNCTION fnProcessUnicast(INTEGER pCam,CHAR pDATA[]){
	// Debug
	fnDebug(DEBUG_DEV,"'fnProcessUnicast(',ITOA(pCam),',',fnBytesToString(pData),')'",'')

	IF(1){
		STACK_VAR CHAR PAYLOAD_TYPE[2]
		PAYLOAD_TYPE = GET_BUFFER_STRING(pDATA,2)
		fnDebug(DEBUG_DEV,"'fnProcessUnicast() PAYLOAD_TYPE'",fnBytesToString(PAYLOAD_TYPE))
		// Get Visca Payload Type
		SWITCH(fnBytesToString(PAYLOAD_TYPE)){
			CASE '$02,$01':{
				fnDebug(DEBUG_DEV,"'Control Reply'",fnBytesToString(pDATA))
				// Control Reply
			}
			CASE '$01,$11':{
				STACK_VAR INTEGER LEN
				STACK_VAR INTEGER SEQ
				STACK_VAR INTEGER ADD
				
				fnDebug(DEBUG_DEV,"'Visca Reply Data'",fnBytesToString(pDATA))
				// Extract and calculate Length
				LEN = GET_BUFFER_CHAR(pDATA)*GET_BUFFER_CHAR(pDATA)
				fnDebug(DEBUG_DEV,"'Visca Reply Len '",ITOA(LEN))
				// Extract and calculate Sequence
				SEQ = GET_BUFFER_CHAR(pDATA)*GET_BUFFER_CHAR(pDATA)*GET_BUFFER_CHAR(pDATA)*GET_BUFFER_CHAR(pDATA)
				fnDebug(DEBUG_DEV,"'Visca Reply Seq '",ITOA(SEQ))
				// Extract the Address
				ADD = GET_BUFFER_CHAR(pDATA)
				fnDebug(DEBUG_DEV,"'Visca Reply Add '",ITOA(ADD))
				
				// Remove Return Marker char (these are standard matched on command/query
				GET_BUFFER_STRING(pDATA,1)
				// Remove the end $FF
				SET_LENGTH_ARRAY(pDATA,LENGTH_ARRAY(pDATA)-1)
				
				// Process Response based on last sent 
				SELECT{
					ACTIVE("$09,$00,$02" == myViscaIP.CAM[pCAM].TxLast):{	// VersionInq
						STACK_VAR CHAR VENDOR_ID[2]
						STACK_VAR CHAR MODEL_CODE[2]
						fnDebug(DEBUG_DEV,"'Visca VersionInq Reply'",fnBytesToString(pDATA))

						VENDOR_ID   = GET_BUFFER_STRING(pDATA,2)
						MODEL_CODE  = GET_BUFFER_STRING(pDATA,2)

						IF(myViscaIP.CAM[pCam].VENDOR = ''){
							SELECT{
								ACTIVE(VENDOR_ID == "$00,$01"):{	// Sony
									myViscaIP.CAM[pCam].VENDOR = 'Sony'
									SELECT{
										ACTIVE(MODEL_CODE == "$05,$13"):{	// SRG-300H
											myViscaIP.CAM[pCam].MODEL = 'SRG-300H'
										}
										ACTIVE(MODEL_CODE == "$05,$19"):{	// BRC-X1000
											myViscaIP.CAM[pCam].MODEL = 'BRC-X1000'
										}
									}
								}
								ACTIVE(1):{
									myViscaIP.CAM[pCam].VENDOR = "'Unknown: ',fnHexToString(VENDOR_ID)"
									myViscaIP.CAM[pCam].MODEL = "'Unknown: ',fnHexToString(MODEL_CODE)"
								}
							}
							SEND_STRING vdvCamera[pCam], 'PROPERTY-META,TYPE,Camera'
							SEND_STRING vdvCamera[pCam],"'PROPERTY-META,MAKE,',myViscaIP.CAM[pCAM].VENDOR"
							SEND_STRING vdvCamera[pCam],"'PROPERTY-META,MODEL,',myViscaIP.CAM[pCAM].MODEL"
						}
					}
					ACTIVE("$09,$04,$00" == myViscaIP.CAM[pCAM].TxLast):{	// Power Query
						myViscaIP.CAM[pCAM].POWER = pDATA[1] == 02
						IF(TIMELINE_ACTIVE(TLID_COMMS00+pCam)){TIMELINE_KILL(TLID_COMMS00+pCam)}
						TIMELINE_CREATE(TLID_COMMS00+pCam,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
				}
			}
		}
	}
}
/******************************************************************************
	IP Data Events - Camera Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipCAM]{
	ONLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT[ipCAM',FORMAT('%02d',GET_LAST(ipCam)),']'",'ONLINE')
		myViscaIP.CAM[GET_LAST(ipCAM)].CONN_ONLINE = TRUE
		fnPoll_FB(GET_LAST(ipCAM))
		fnInitPoll_FB(GET_LAST(ipCAM))
	}
	STRING:{
		fnDebug(DEBUG_DEV,"'CAM',FORMAT('%02d',GET_LAST(ipCam)),'->'",fnBytesToString(DATA.TEXT))
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT[ipCAM',FORMAT('%02d',GET_LAST(ipCam)),']'",'OFFLINE')
		myViscaIP.CAM[GET_LAST(ipCAM)].CONN_ONLINE = FALSE
		fnOpenClientConnection(GET_LAST(ipCam))
	}
}
/******************************************************************************
	IP Data Events - Camera Feedback
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipFB]{
	ONLINE:{
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipFB]','ONLINE')
	}
	STRING:{
		STACK_VAR INTEGER x
		STACK_VAR CHAR pIP[100]
		fnDebug(DEBUG_STD,'CAMFB->',fnBytesToString(DATA.TEXT))

		pIP = DATA.SOURCEIP
		REMOVE_STRING(pIP,':',1)
		REMOVE_STRING(pIP,':',1)
		REMOVE_STRING(pIP,':',1)
		FOR(x =1 ; x<=LENGTH_ARRAY(vdvCamera);x++){
			IF(myViscaIP.CAM[x].IP_HOST == pIP){
				fnProcessUnicast(x,DATA.TEXT)
			}
		}
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipFB]','OFFLINE')
	}
}
/******************************************************************************
	IP Data Events - Multicast Feedback
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipMC]{
	ONLINE:{
		fnDebug(DEBUG_DEV,'DATA_EVENT[ipMC]','ONLINE')
		fnPoll_MC()
		fnInitPoll_MC()
	}
	STRING:{
		fnDebug(DEBUG_DEV,'CAMMC->',DATA.TEXT)
		fnProcessMulticast(DATA.TEXT)
	}
}
/******************************************************************************
	Virtual Data Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvCamera]{
	ONLINE:{
		IF(!myViscaIP.CAM[GET_LAST(vdvCamera)].SPEED_PAN){
			myViscaIP.CAM[GET_LAST(vdvCamera)].SPEED_PAN = $08
		}
		IF(!myViscaIP.CAM[GET_LAST(vdvCamera)].SPEED_TILT){
			myViscaIP.CAM[GET_LAST(vdvCamera)].SPEED_TILT = $08
		}
		myViscaIP.CAM[GET_LAST(vdvCamera)].SEQUENCE = 1
	}
	COMMAND:{
		STACK_VAR INTEGER pCAM
		pCAM = GET_LAST(vdvCamera)
		
		fnDebug(DEBUG_STD,"'DATA_EVENT[vdvCamera[',ITOA(pCam),']]'",DATA.TEXT)
		
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':myViscaIP.DEBUG = DEBUG_STD
							CASE 'DEV':	myViscaIP.DEBUG = DEBUG_DEV
							DEFAULT:		myViscaIP.DEBUG = DEBUG_ERR
						}
					}
					CASE 'MODE':{
						SWITCH(DATA.TEXT){
							CASE 'STATIC': myViscaIP.CAM[pCAM].MODE = MODE_STATIC
							DEFAULT:       myViscaIP.CAM[pCAM].MODE = MODE_AUTO
						}
					}
					CASE 'IP':{
						myViscaIP.CAM[pCAM].IP_HOST = DATA.TEXT
						SWITCH(myViscaIP.CAM[pCAM].CONN_ONLINE){
							CASE TRUE: 	fnCloseConnection(pCam)
							CASE FALSE:	fnOpenClientConnection(pCam)
						}
					}
					CASE 'NETWORK':{
						myViscaIP.CAM[pCAM].MAC_ADD 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myViscaIP.CAM[pCAM].IP_HOST 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myViscaIP.CAM[pCAM].SUBNET 		= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						myViscaIP.CAM[pCAM].GATEWAY 	= DATA.TEXT
						SWITCH(myViscaIP.CAM[pCAM].CONN_ONLINE){
							CASE TRUE: 	fnCloseConnection(pCam)
							CASE FALSE:	fnOpenClientConnection(pCam)
						}
					}
				}
			}
			CASE 'PRESET':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'RECALL':fnAddToQueue(pCAM,"$01,$04,$3F,$02,ATOI(DATA.TEXT)-1",FALSE)
					CASE 'STORE': fnAddToQueue(pCAM,"$01,$04,$3F,$01,ATOI(DATA.TEXT)-1",FALSE)
				}
			}
			CASE 'CONTROL':{
				STACK_VAR INTEGER x
				STACK_VAR INTEGER y
				x = myViscaIP.CAM[pCAM].SPEED_PAN
				y = myViscaIP.CAM[pCAM].SPEED_TILT
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'PAN':{
						SWITCH(DATA.TEXT){
							CASE 'LEFT':	fnAddToQueue(pCAM,"$01,$06,$01,x,y,$01,$03",FALSE)
							CASE 'RIGHT':	fnAddToQueue(pCAM,"$01,$06,$01,x,y,$02,$03",FALSE)
							CASE 'STOP':	fnAddToQueue(pCAM,"$01,$06,$01,x,y,$03,$03",FALSE)
						}
					}
					CASE 'TILT':{
						SWITCH(DATA.TEXT){
							CASE 'UP':	fnAddToQueue(pCAM,"$01,$06,$01,x,y,$03,$01",FALSE)
							CASE 'DOWN':fnAddToQueue(pCAM,"$01,$06,$01,x,y,$03,$02",FALSE)
							CASE 'STOP':fnAddToQueue(pCAM,"$01,$06,$01,x,y,$03,$03",FALSE)
						}
					}
					CASE 'ZOOM':{
						SWITCH(DATA.TEXT){
							CASE 'IN':  fnAddToQueue(pCAM,"$01,$04,$07,$02",FALSE)
							CASE 'OUT': fnAddToQueue(pCAM,"$01,$04,$07,$03",FALSE)
							CASE 'STOP':fnAddToQueue(pCAM,"$01,$04,$07,$00",FALSE)
						}
					}
				}
			}
		}
	}
}
/******************************************************************************
	Module Startup
******************************************************************************/
DEFINE_START{
	// Set Default Ports
	myViscaIP.IP_PORT_MC = 52380
	myViscaIP.IP_PORT_FB = 52381
	// Start Multicast Client/Server
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Client (Multicast UDP 2WAY)')
	IP_CLIENT_OPEN(ipMC.PORT,'255.255.255.255',myViscaIP.IP_PORT_MC,IP_UDP_2WAY)
	// Start Feedback Server
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Server (Feedback)')
	IP_SERVER_OPEN(ipFB.PORT,myViscaIP.IP_PORT_FB,IP_UDP)

}
/******************************************************************************
	Module Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCamera); x++){
		[vdvCamera[x],251] = TIMELINE_ACTIVE(TLID_COMMS00+x)
		[vdvCamera[x],252] = TIMELINE_ACTIVE(TLID_COMMS00+x)
	}
}
/******************************************************************************
	EoF
******************************************************************************/