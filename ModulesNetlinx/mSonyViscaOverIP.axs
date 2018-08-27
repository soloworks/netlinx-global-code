MODULE_NAME='mSonyViscaOverIP'(DEV vdvCamera[],DEV ipCAM[], DEV ipFB, DEV ipMC)
#INCLUDE 'CustomFunctions'
/******************************************************************************
	Sony Visca Over IP

	Uses Multicast to discover and configure camera via MAC Address

	Set MAC address using: 	PROPERTY-MAC,xx-xx-xx-xx-xx-xx
	Set IP address using:	PROPERTY-IP,xxx.xxx.xxx.xxx[:port]

	Module will set IP address on auto discovery
******************************************************************************/
/******************************************************************************
	Types
******************************************************************************/
DEFINE_TYPE STRUCTURE uCam{
	INTEGER	CONN_ONLINE
	CHAR 		MAC_ADD[20]
	CHAR 		IP_HOST[15]
	CHAR		GATEWAY[30]
	CHAR		SUBNET[30]
	INTEGER	SEQUENCE

	INTEGER	SPEED_PAN
	INTEGER	SPEED_TILT

	// Meta
	INTEGER  VENDOR_ID
	CHAR     VENDOR[20]
	INTEGER  MODEL_ID
	CHAR		MODEL[20]

	// Status
	INTEGER	POWER
}
DEFINE_TYPE STRUCTURE uSonyCams{
	INTEGER	DEBUG
	INTEGER	IP_PORT_MC
	INTEGER	IP_PORT_FB

	uCam		CAMS[5]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER DEBUG_ERR	= 0
INTEGER DEBUG_STD	= 1
INTEGER DEBUG_DEV	= 2

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
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
VOLATILE uSonyCams mySonyCams

LONG TLT_POLL_MC[] 	= {  30000 }
LONG TLT_POLL_FB[] 	= {  15000 }
LONG TLT_COMMS[]   	= {  90000 }
LONG TLT_TIMEOUT[]   = {   2000 }
/******************************************************************************
	General Utilities
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDEBUG, CHAR Msg[], CHAR MsgData[]){
	IF(mySonyCams.DEBUG >= pDEBUG){
		SEND_STRING 0:0:0, "ITOA(vdvCamera[1].Number),':',Msg, ':', MsgData"
	}
}
/******************************************************************************
	Connection Utilities
******************************************************************************/
DEFINE_FUNCTION fnOpenClientConnection(INTEGER pCAM){

	IF(!LENGTH_ARRAY(mySonyCams.CAMS[pCAM].MAC_ADD)){
		fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'MAC ADDRESS NOT CONFIGURED')
		RETURN
	}

	IF(!LENGTH_ARRAY(mySonyCams.CAMS[pCAM].IP_HOST)){
		fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP ADDRESS NOT CONFIGURED')
		RETURN
	}

	IF(!LENGTH_ARRAY(mySonyCams.CAMS[pCAM].SUBNET)){
		fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP SUBNET NOT CONFIGURED')
		RETURN
	}

	IF(!LENGTH_ARRAY(mySonyCams.CAMS[pCAM].GATEWAY)){
		fnDebug(DEBUG_ERR,"'SONY CAM',FORMAT('%02d',pCAM),' ERROR'",'IP GATEWAY NOT CONFIGURED')
		RETURN
	}

	// Start Unicast Client
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Client (Unicast UDP 2WAY)')
	IP_CLIENT_OPEN(ipCAM[pCAM].PORT,mySonyCams.CAMS[pCAM].IP_HOST,mySonyCams.IP_PORT_FB,IP_UDP_2WAY)

}

DEFINE_FUNCTION fnCloseConnection(INTEGER pCAM){
	IP_CLIENT_CLOSE(ipCAM[pCAM].PORT)
}

DEFINE_FUNCTION fnSendQuery(INTEGER pCAM, CHAR pDATA[]){
	pDATA = "$01,$10,$00,$02+LENGTH_ARRAY(pDATA),$00,$00,$00,mySonyCams.CAMS[pCAM].SEQUENCE,$81,pDATA,$FF"
	fnDebug(DEBUG_DEV,"'->CAM',FORMAT('%02d',pCAM)",fnBytesToString(pDATA))
	// Send Command to Device
	SEND_STRING ipCAM[pCAM],pDATA
	mySonyCams.CAMS[pCAM].SEQUENCE++
	fnInitTimeoutSequence(pCAM)
}
DEFINE_FUNCTION fnSendCommand(INTEGER pCAM, CHAR pDATA[]){
	// Build command
	pDATA = "$01,$10,$00,$02+LENGTH_ARRAY(pDATA),$00,$00,$00,mySonyCams.CAMS[pCAM].SEQUENCE,$81,pDATA,$FF"
	fnDebug(DEBUG_DEV,"'->CAM',FORMAT('%02d',pCAM)",fnBytesToString(pDATA))
	// Send Command to Device
	SEND_STRING ipCAM[pCAM],pDATA
	mySonyCams.CAMS[pCAM].SEQUENCE++
	fnInitTimeoutSequence(pCAM)
	fnInitPoll_FB(pCAM)
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
	IF(mySonyCams.CAMS[pCam].VENDOR_ID){
		fnSendCommand(pCAM,"$09,$00,$02")	// Vesion Enquiry
	}
	ELSE{
		fnSendCommand(pCAM,"$09,$04,$00")	// Power State Enquiry
		fnSendCommand(pCAM,"$09,$06,$12")	// PanTilt Pos Enquiry
		fnSendCommand(pCAM,"$09,$04,$47")	// Zoom Pos Enquiry
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
	fnDebug(DEBUG_DEV,"'->CAM',FORMAT('%02d',pCAM)",fnBytesToString(toSend))
	SEND_STRING ipCAM[pCAM],toSend
	mySonyCams.CAMS[pCAM].SEQUENCE = 1
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
					IF(pCHUNK == mySonyCams.CAMS[x].MAC_ADD){
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
			IF(MAC_ADD == mySonyCams.CAMS[x].MAC_ADD){
				fnDebug(DEBUG_DEV,'fnProcessMulticast()','MAC_ADD == myCamera.MAC_ADD')

				IF(IP_HOST != mySonyCams.CAMS[x].IP_HOST || SUBNET != mySonyCams.CAMS[x].SUBNET || GATEWAY != mySonyCams.CAMS[x].GATEWAY){
					STACK_VAR CHAR pSetNetwork[255]
					fnDebug(DEBUG_DEV,'fnProcessMulticast()','Configure Network Settings')
					pSetNetwork = "'MAC:',mySonyCams.CAMS[x].MAC_ADD,$FF"
					pSetNetwork = "pSetNetwork,'IPADR:',mySonyCams.CAMS[x].IP_HOST,$FF"
					pSetNetwork = "pSetNetwork,'MASK:',mySonyCams.CAMS[x].SUBNET,$FF"
					pSetNetwork = "pSetNetwork,'GATEWAY:',mySonyCams.CAMS[x].GATEWAY,$FF"
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
			CASE '$02,$01':{}
			CASE '$01,$11':{
				fnDebug(DEBUG_DEV,"'fnProcessUnicast() Visca Reply'",fnBytesToString(pDATA))
				GET_BUFFER_STRING(pDATA,2)	// Eat Length Values
				GET_BUFFER_STRING(pDATA,4)	// Eat Sequence Number
				pDATA = fnStripCharsRight(pDATA,1)
				// Actual Response is here
				GET_BUFFER_CHAR(pDATA)	// Address (Locked)
				SWITCH(GET_BUFFER_CHAR(pDATA)){
					CASE $50:{	// VersionInq
						STACK_VAR INTEGER VENDOR_ID
						STACK_VAR INTEGER MODEL_ID
						fnDebug(DEBUG_DEV,"'fnProcessUnicast() VersionInq Reply'",fnBytesToString(pDATA))

						VENDOR_ID = (GET_BUFFER_CHAR(pDATA) * 256) + GET_BUFFER_CHAR(pDATA)	// Vender ID
						MODEL_ID  = (GET_BUFFER_CHAR(pDATA) * 256) + GET_BUFFER_CHAR(pDATA)	// Model ID

						IF(mySonyCams.CAMS[pCam].VENDOR_ID != VENDOR_ID){

							mySonyCams.CAMS[pCam].VENDOR_ID =  VENDOR_ID
							mySonyCams.CAMS[pCam].MODEL_ID  =  MODEL_ID

							SEND_STRING vdvCamera[pCam],'PROPERTY-META,TYPE,Camera'

							SWITCH(VENDOR_ID){
								CASE 1:{	// Sony

									mySonyCams.CAMS[pCam].VENDOR = 'Sony'

									SWITCH(MODEL_ID){
										CASE 1299:{	// SRG-300H
											mySonyCams.CAMS[pCam].MODEL = 'SRG-300H'
										}
									}
								}
							}

							SEND_STRING vdvCamera[pCam],"'PROPERTY-META,MAKE,',mySonyCams.CAMS[pCAM].VENDOR"
							SEND_STRING vdvCamera[pCam],"'PROPERTY-META,MODEL,',mySonyCams.CAMS[pCAM].MODEL"

						}
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
		mySonyCams.CAMS[GET_LAST(ipCAM)].CONN_ONLINE = TRUE
		fnPoll_FB(GET_LAST(ipCAM))
		fnInitPoll_FB(GET_LAST(ipCAM))
	}
	STRING:{
		fnDebug(DEBUG_DEV,"'CAM',FORMAT('%02d',GET_LAST(ipCam)),'->'",fnBytesToString(DATA.TEXT))
	}
	OFFLINE:{
		fnDebug(DEBUG_DEV,"'DATA_EVENT[ipCAM',FORMAT('%02d',GET_LAST(ipCam)),']'",'OFFLINE')
		mySonyCams.CAMS[GET_LAST(ipCAM)].CONN_ONLINE = FALSE
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
			IF(mySonyCams.CAMS[x].IP_HOST == pIP){
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
		IF(!mySonyCams.CAMS[GET_LAST(vdvCamera)].SPEED_PAN){
			mySonyCams.CAMS[GET_LAST(vdvCamera)].SPEED_PAN = $08
		}
		IF(!mySonyCams.CAMS[GET_LAST(vdvCamera)].SPEED_TILT){
			mySonyCams.CAMS[GET_LAST(vdvCamera)].SPEED_TILT = $08
		}
		mySonyCams.CAMS[GET_LAST(vdvCamera)].SEQUENCE = 1
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
							CASE 'TRUE':mySonyCams.DEBUG = DEBUG_STD
							CASE 'DEV':	mySonyCams.DEBUG = DEBUG_DEV
							DEFAULT:		mySonyCams.DEBUG = DEBUG_ERR
						}
					}
					CASE 'NETWORK':{
						mySonyCams.CAMS[pCAM].MAC_ADD 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						mySonyCams.CAMS[pCAM].IP_HOST 	= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						mySonyCams.CAMS[pCAM].SUBNET 		= fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						mySonyCams.CAMS[pCAM].GATEWAY 	= DATA.TEXT
						SWITCH(mySonyCams.CAMS[pCAM].CONN_ONLINE){
							CASE TRUE: 	fnCloseConnection(pCam)
							CASE FALSE:	fnOpenClientConnection(pCam)
						}
					}
				}
			}
			CASE 'PRESET':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'RECALL':fnSendCommand(pCAM,"$01,$04,$3F,$02,ATOI(DATA.TEXT)-1")
					CASE 'STORE': fnSendCommand(pCAM,"$01,$04,$3F,$01,ATOI(DATA.TEXT)-1")
				}
			}
			CASE 'CONTROL':{
				STACK_VAR INTEGER x
				STACK_VAR INTEGER y
				x = mySonyCams.CAMS[pCAM].SPEED_PAN
				y = mySonyCams.CAMS[pCAM].SPEED_TILT
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'PAN':{
						SWITCH(DATA.TEXT){
							CASE 'LEFT':	fnSendCommand(pCAM,"$01,$06,$01,x,y,$01,$03")
							CASE 'RIGHT':	fnSendCommand(pCAM,"$01,$06,$01,x,y,$02,$03")
							CASE 'STOP':	fnSendCommand(pCAM,"$01,$06,$01,x,y,$03,$03")
						}
					}
					CASE 'TILT':{
						SWITCH(DATA.TEXT){
							CASE 'UP':	fnSendCommand(pCAM,"$01,$06,$01,x,y,$03,$01")
							CASE 'DOWN':fnSendCommand(pCAM,"$01,$06,$01,x,y,$03,$02")
							CASE 'STOP':fnSendCommand(pCAM,"$01,$06,$01,x,y,$03,$03")
						}
					}
					CASE 'ZOOM':{
						SWITCH(DATA.TEXT){
							CASE 'IN':  fnSendCommand(pCAM,"$01,$04,$07,$02")
							CASE 'OUT': fnSendCommand(pCAM,"$01,$04,$07,$03")
							CASE 'STOP':fnSendCommand(pCAM,"$01,$04,$07,$00")
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
	mySonyCams.IP_PORT_MC = 52380
	mySonyCams.IP_PORT_FB = 52381
	// Start Multicast Client/Server
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Client (Multicast UDP 2WAY)')
	IP_CLIENT_OPEN(ipMC.PORT,'255.255.255.255',mySonyCams.IP_PORT_MC,IP_UDP_2WAY)
	// Start Feedback Server
	fnDebug(DEBUG_DEV,'DEFINE_START','Opening UDP Server (Feedback)')
	IP_SERVER_OPEN(ipFB.PORT,mySonyCams.IP_PORT_FB,IP_UDP)

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