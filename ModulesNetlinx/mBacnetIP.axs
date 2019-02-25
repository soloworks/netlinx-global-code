MODULE_NAME='mBacnetIP'(DEV vdvControl,DEV vdvZone[],DEV tp[],DEV ipUDP)
#INCLUDE 'CustomFunctions'
#INCLUDE 'IEEE754'
/******************************************************************************
	// Command for Who Is - not working once direct connection is set
	// fnSendCommand("$81,$0B,$00,$0C,$01,$20,$FF,$FF,$00,$FF,$10,$08")
	STACK_VAR uBACnetMSG myBACnetMSG
	myBACnetMSG.BVLC_MSG_TYPE 			= BVLC_ORIGINAL_BROADCAST
	myBACnetMSG.NPDU_DNET 				= 65535
	myBACnetMSG.APDU_REQUEST_TYPE 	= APDU_REQUEST_UNCONFIRMED
	myBACnetMSG.APDU_SERVICE_CHOICE 	= APDU_SERVICE_CHOICE_WHOIS
	fnSendCommand(myBACnetMSG)
	
	Module expects main instance ID to be 1
	
	
******************************************************************************/
/******************************************************************************
	Structures
******************************************************************************/

DEFINE_TYPE STRUCTURE uPanel{
	INTEGER ZONE
}
DEFINE_TYPE STRUCTURE uObject{
	LONG  	TYPE
	LONG 		INSTANCE_NO
	FLOAT		PRESENT_MIN
	INTEGER	PRESENT_MIN_CHANGED
	FLOAT		PRESENT_MAX
	FLOAT		PRESENT_VALUE
	INTEGER	PRESENT_VALUE_TYPE
	INTEGER 	UNITS
	CHAR		UNITS_CHAR[5]
	CHAR 		PROP_NAME[255]
}
DEFINE_TYPE STRUCTURE uBACnetIP{
	CHAR 		IP_HOST[255]
	INTEGER 	IP_PORT
	INTEGER 	DEBUG
	CHAR		TxPoll[5000]
	CHAR		TxCmd[5000]
	INTEGER	InvokeID
	INTEGER	PendID
	uObject 	PROCESSOR
}

DEFINE_CONSTANT 
INTEGER MAX_OBJECTS = 8
DEFINE_TYPE STRUCTURE uBACnetZone{
	uObject	OBJ_INSTANCE[MAX_OBJECTS]
}
(******************************************)
//	NPDU Flag made up by adding following:
//	$80 if Network Layer Message, APDU if not
// $20 if DNET DLEN DADR are present (Destination Details) - Added by Function
// $08 if SNET SLEN SADR are present (Source Details) - Added by Function
// $04 if expecting reply
// Priority: $03 if Life, $02 if Critical, $01 if Urgent
(******************************************)
DEFINE_TYPE STRUCTURE uBACnetMSG{
	// BVLC Section
	INTEGER 	BVLC_MSG_TYPE
	// NPDU Section
	INTEGER 	NPDU_IS_NETWORK_LAYER_MESSAGE
	INTEGER 	NPDU_EXPECT_REPLY
	INTEGER 	NPDU_DNET
	CHAR 		NPDU_DADR[4]
	INTEGER 	NPDU_SNET
	CHAR 		NPDU_SADR[4]
	INTEGER 	NPDU_PRIORITY
	// APDU Section
	INTEGER	APDU_REQUEST_TYPE
	INTEGER	APDU_SERVICE_CHOICE
	INTEGER	APDU_PROPERTY_ID
	LONG 		APDU_OBJ_INST_NO
	LONG   	APDU_OBJ_TYPE
	INTEGER	APDU_VALUE_TYPE
	CHAR		APDU_VALUE[255]
	CHAR		APDU_TO_READ[10]
}
/******************************************************************************
	Constants
******************************************************************************/
DEFINE_CONSTANT

INTEGER BVLC_ORIGINAL_UNICAST 	= $0A	// DEFAULT
INTEGER BVLC_ORIGINAL_BROADCAST 	= $0B

INTEGER NPDU_PRIORITY_LIFE 		= $03
INTEGER NPDU_PRIORITY_CRITICAL 	= $02
INTEGER NPDU_PRIORITY_URGENT 		= $01
INTEGER NPDU_PRIORITY_NORMAL 		= $00

INTEGER APDU_REQUEST_UNCONFIRMED		= $10
INTEGER APDU_REQUEST_CONFIRMED		= $00
// Unconfirmed Service Choices
INTEGER APDU_SERVICE_CHOICE_WHOIS		= $08
// Confirmed Service Choices
INTEGER APDU_SERVICE_CHOICE_SUBSCRIBECOV	= 05
INTEGER APDU_SERVICE_CHOICE_READPROP		= 12
INTEGER APDU_SERVICE_CHOICE_READPROPMULTI	= 14
INTEGER APDU_SERVICE_CHOICE_WRITEPROP		= 15
// Property Identifier
INTEGER APDU_PROPERTY_ALL			 			= 08
INTEGER APDU_PROPERTY_ID_OBJ_LIST 			= 76
INTEGER APDU_PROPERTY_ID_OBJ_NAME 			= 77
INTEGER APDU_PROPERTY_ID_PRES_VALUE_MIN 	= 69
INTEGER APDU_PROPERTY_ID_PRES_VALUE_MAX 	= 65
INTEGER APDU_PROPERTY_ID_PRES_VALUE 		= 85
INTEGER APDU_PROPERTY_ID_NO_OF_STATES 		= 74
INTEGER APDU_PROPERTY_ID_UNITS	 			= 117
INTEGER APDU_PROPERTY_ID_DB_REV				= 155

INTEGER APDU_OBJ_TYPE_ANALOG_INPUT 		= 0
INTEGER APDU_OBJ_TYPE_ANALOG_OUTPUT		= 1
INTEGER APDU_OBJ_TYPE_ANALOG_VALUE 		= 2
INTEGER APDU_OBJ_TYPE_BINARY_INPUT	 	= 3
INTEGER APDU_OBJ_TYPE_BINARY_OUTPUT 	= 4
INTEGER APDU_OBJ_TYPE_BINARY_VALUE	 	= 5
INTEGER APDU_OBJ_TYPE_DEVICE			 	= 8
INTEGER APDU_OBJ_TYPE_MULTISTATE_INPUT	= 13
INTEGER APDU_OBJ_TYPE_MULTISTATE_OUTPUT= 14
INTEGER APDU_OBJ_TYPE_MULTISTATE_VALUE	= 19
INTEGER APDU_OBJ_TYPE_UNDEFINED	 	= 999

INTEGER UNITS_TYPE_DEGREES_CELCIUS		= 62
INTEGER UNITS_TYPE_UNDEFINED			= 999

//CHAR APDU_SERVICE_I_AM[2]		= {$10,$00}
//CHAR APDU_SERVICE_I_AHAVE[2]	= {$10,$01}
//CHAR APDU_SERVICE_WHO_HAS[2]	= {$10,$07}
//CHAR APDU_SERVICE_WHO_IS[2]	= {$10,$08}

LONG TLID_DISCOVER	= 1
LONG TLID_POLL			= 2
LONG TLID_BOOT			= 3
LONG TLID_TIMEOUT		= 4

LONG TLID_COMMS_000	= 1000000

INTEGER DEBUG_OFF		= 0
INTEGER DEBUG_STD		= 1
INTEGER DEBUG_DEV		= 2

/******************************************************************************
	GUI Interface Constants
******************************************************************************/
DEFINE_CONSTANT
INTEGER addHVACValueRaw[] = {
	21,22,23,24,25,26,27,28
}
INTEGER addHVACValue[] = {
	31,32,33,34,35,36,37,38
}
INTEGER btnHVACToggle[] = {
	101,102,103,104,105,106,107,108
}
INTEGER btnHVACDec[] = {
	111,112,113,114,115,116,117,118
}
INTEGER btnHVACInc[] = {
	121,122,123,124,125,126,127,128
}
INTEGER btnZoneDeSelect = 200
INTEGER btnZoneSelect[] = {
	201,202,203,204,205,206,207,208,209,210,
	211,212,213,214,215,216,217,218,219,220
}
/******************************************************************************
	Variables
******************************************************************************/
DEFINE_VARIABLE
LONG TLT_POLL[]		= {  45000}
LONG TLT_COMMS[]		= { 120000}
LONG TLT_TIMEOUT[]	= {   2500}
VOLATILE uBACnetIP 	myBACnetIP
VOLATILE uBACnetZone	myBACnetZone[20]
VOLATILE uPanel		myBACnetPanel[20]
/******************************************************************************
	Communication Helpers
******************************************************************************/
DEFINE_FUNCTION fnDebug(INTEGER pDebug,CHAR pMSG[]){	
	IF(pDebug <= myBACnetIP.DEBUG){
		STACK_VAR CHAR pMSG_COPY[10000]
		pMSG_COPY = pMSG
		WHILE(LENGTH_ARRAY(pMSG_COPY)){
			SEND_STRING 0, "ITOA(vdvControl.NUMBER),':',GET_BUFFER_STRING(pMSG_COPY,150)"
		}
	}
}

DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[10000]){
	STACK_VAR INTEGER BVLC_TYPE
	STACK_VAR INTEGER BVLC_FUNCTION
	STACK_VAR INTEGER BVLC_LENGTH
	
	STACK_VAR INTEGER NPDU_VERSION
	STACK_VAR INTEGER NPDU_CONTROL
	STACK_VAR INTEGER NPDU_ADDRESS
	STACK_VAR INTEGER NPDU_MAC
	STACK_VAR INTEGER NPDU_HOPS
	
	STACK_VAR LONG    APDU_TYPE
	STACK_VAR INTEGER APDU_SERVICE
	STACK_VAR INTEGER APDU_INVOKE_ID
	STACK_VAR LONG    APDU_OBJ_TYPE
	STACK_VAR LONG 	APDU_OBJ_INST_NO
	STACK_VAR LONG 	APDU_PROPERTY_ID
	
	// BVLC Section
	BVLC_TYPE 		= GET_BUFFER_CHAR(pDATA)
	BVLC_FUNCTION 	= GET_BUFFER_CHAR(pDATA)
	BVLC_LENGTH		= (256*GET_BUFFER_CHAR(pDATA))+GET_BUFFER_CHAR(pDATA)
	fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackBVLC::','TYPE[',ITOA(BVLC_TYPE),'] FUNCTION[',ITOA(BVLC_FUNCTION),'] LENGTH[',ITOA(BVLC_LENGTH),']'")
	
	// NPDU Section
	NPDU_VERSION 	= GET_BUFFER_CHAR(pDATA)
	NPDU_CONTROL 	= GET_BUFFER_CHAR(pDATA)
	// IF(DEST/SRC Present from control flags...)
	//NPDU_ADDRESS	= (256*GET_BUFFER_CHAR(pDATA))+GET_BUFFER_CHAR(pDATA)
	//NPDU_MAC 		= GET_BUFFER_CHAR(pDATA)
	//NPDU_HOPS 		= GET_BUFFER_CHAR(pDATA)
	
	// APDU Section
	APDU_TYPE 		= GET_BUFFER_CHAR(pDATA)
	
	SWITCH(APDU_TYPE){
		CASE $00:{
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::ConfirmedReq'")
		}
		CASE $10:{	// Unconfirmed Req
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::UnconfirmedReq'")
			SWITCH(GET_BUFFER_CHAR(pDATA)){
				CASE $02:{	// UnconfirmedCOVNotification
					GET_BUFFER_STRING(pDATA,2)		// Remove Process Identifier
					GET_BUFFER_CHAR(pDATA)		// Remove Object Identifer Context Tag (Processor)
					GET_BUFFER_STRING(pDATA,4)	// Remove Object Identifer (Processor)
					IF(1){
						STACK_VAR CHAR pObjIdent[4]
						GET_BUFFER_CHAR(pDATA)		// Remove Object Identifer Context Tag
						pObjIdent = GET_BUFFER_STRING(pDATA,4)
						APDU_OBJ_TYPE 		= fnGetObjectTypeFromIdentifier(pObjIdent)
						APDU_OBJ_INST_NO 	= fnGetObjectInstNoFromIdentifier(pObjIdent)
						fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_PRES_VALUE,pDATA)
					}
					IF(1){
						STACK_VAR INTEGER z
						FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
							STACK_VAR INTEGER o
							FOR(o = 1; o <= MAX_OBJECTS; o++){
								IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == APDU_OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == APDU_OBJ_INST_NO){
									fnDebug(DEBUG_STD,"'UnconfirmedCOVNotification [',ITOA(z),':',ITOA(o),']',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME")
									fnInitCommsTimeout(z,o)
								}
							}
						}
					}
					fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackAPDU::','TYPE[',ITOA(APDU_TYPE),'] SERVICE[',ITOA(APDU_SERVICE),'] OBJ_TYPE[',ITOA(APDU_OBJ_TYPE),'] INST_NO[',ITOA(APDU_OBJ_INST_NO),']'")
				}
			}
		}
		CASE $20:{	// Simple Ack
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::SimpleAck'")
			APDU_INVOKE_ID	= GET_BUFFER_CHAR(pDATA)
			APDU_SERVICE	= GET_BUFFER_CHAR(pDATA)
		}
		CASE $30:{	// Complex Ack
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::ComplexAck'")
			APDU_INVOKE_ID	= GET_BUFFER_CHAR(pDATA)
			APDU_SERVICE	= GET_BUFFER_CHAR(pDATA)
			IF(1){
				STACK_VAR CHAR pObjIdent[4]
				GET_BUFFER_CHAR(pDATA)		// Remove Object Identifer Context Tag
				pObjIdent = GET_BUFFER_STRING(pDATA,4)
				APDU_OBJ_TYPE 		= fnGetObjectTypeFromIdentifier(pObjIdent)
				APDU_OBJ_INST_NO 	= fnGetObjectInstNoFromIdentifier(pObjIdent)
			}
			IF(1){
				STACK_VAR INTEGER z
				FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
					STACK_VAR INTEGER o
					FOR(o = 1; o <= MAX_OBJECTS; o++){
						IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == APDU_OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == APDU_OBJ_INST_NO){
							fnDebug(DEBUG_STD,"'ComplexAck [',ITOA(z),':',ITOA(o),']',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME")
							fnInitCommsTimeout(z,o)
						}
					}
				}
			}
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackAPDU::','TYPE[',ITOA(APDU_TYPE),'] SERVICE[',ITOA(APDU_SERVICE),'] OBJ_TYPE[',ITOA(APDU_OBJ_TYPE),'] INST_NO[',ITOA(APDU_OBJ_INST_NO),']'")
				
			SWITCH(APDU_SERVICE){
				CASE 12:{	// Read Property Response
					//GET_BUFFER_CHAR(pDATA)	// Remove Context Flag
					//APDU_PROPERTY_ID = GET_BUFFER_CHAR(pDATA)
					//fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_OBJ_NAME,pDATA)
				}
				CASE 14:{	// Read Property Multi Response
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_OBJ_NAME,pDATA)
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_PRES_VALUE_MIN,pDATA)
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_PRES_VALUE_MAX,pDATA)
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_UNITS,pDATA)
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_PRES_VALUE,pDATA)
					fnProcessProperty(APDU_OBJ_TYPE,APDU_OBJ_INST_NO,APDU_PROPERTY_ID_NO_OF_STATES,pDATA)
				}
			}
		}
		CASE $40:{
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::SegmentAck'")
		}
		CASE $50:{
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:FeedBackType::Error'")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:Error:InvokeID:',ITOHEX(GET_BUFFER_CHAR(pDATA))")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:Error:   Class:',ITOHEX(GET_BUFFER_CHAR(pDATA))")
			fnDebug(DEBUG_DEV,"'fnProcessFeedback:Error:    Code:',ITOHEX(GET_BUFFER_CHAR(pDATA))")
		}
		CASE $60:{
			fnDebug(DEBUG_STD,"'fnProcessFeedback:FeedBackType::Reject'")
		}
		CASE $70:{
			fnDebug(DEBUG_STD,"'fnProcessFeedback:FeedBackType::Abort'")
		}
		DEFAULT:{
			fnDebug(DEBUG_STD,"'fnProcessFeedback:FeedBackType::Unhandled (Code $',ITOHEX(APDU_TYPE),')'")
		}
	}
	// Is a response to something we sent, so unpend
	SWITCH(APDU_TYPE){
		CASE $20:
		CASE $30:{
			IF(myBACnetIP.PendID == APDU_INVOKE_ID){
				fnDebug(DEBUG_STD,"'Pending::Reseting ',ITOA(myBACnetIP.PendID)")
				myBACnetIP.PendID = 0
				IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
				fnSendFromQueue()
			}
		}
	}
}

DEFINE_FUNCTION fnProcessProperty(LONG OBJ_TYPE,LONG INST_NO, INTEGER PROP_ID, CHAR pDATA[]){
	// See if this property is present in the data
	IF(FIND_STRING(pDATA,"$29,PROP_ID",1) || FIND_STRING(pDATA,"$09,PROP_ID",1)){
		STACK_VAR INTEGER pPropertyDataStart
		pPropertyDataStart = FIND_STRING(pDATA,"$29,PROP_ID",1)
		IF(!pPropertyDataStart){
			pPropertyDataStart = FIND_STRING(pDATA,"$09,PROP_ID",1)
		}
		fnDebug(DEBUG_DEV,"'fnProcessProperty:Found:','OBJ_TYPE[',ITOA(OBJ_TYPE),'] INST_NO[',ITOA(INST_NO),'] PROP_ID[',ITOA(PROP_ID),']'")
		//fnDebug(DEBUG_DEV,"'fnProcessProperty::','Property Found at ',ITOA(pPropertyDataStart)")
		SWITCH(PROP_ID){
			CASE APDU_PROPERTY_ID_DB_REV:{
				fnDebug(DEBUG_DEV,"'fnProcessProperty:DB_REVISION:UnHandled'")
			}
			CASE APDU_PROPERTY_ID_OBJ_NAME:{	// Object-Name
				STACK_VAR CHAR pOBJ_NAME[255]
				pOBJ_NAME = fnGetStringFromPropertyData(pDATA,pPropertyDataStart)
				fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Found:VALUE[',pOBJ_NAME,']'")
				IF(myBACnetIP.PROCESSOR.TYPE == OBJ_TYPE && INST_NO == myBACnetIP.PROCESSOR.INSTANCE_NO){
					fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Is System'")
		
					IF(myBACnetIP.PROCESSOR.PROP_NAME != pOBJ_NAME){
						fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Processing'")
						myBACnetIP.PROCESSOR.PROP_NAME  = pOBJ_NAME
						SEND_STRING vdvControl,"'PROPERTY-META,SYSNAME,',myBACnetIP.PROCESSOR.PROP_NAME"
						
						// Init a new Poll
						fnPoll()
					}
					ELSE{
						fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:NoChange'")
					}
					
					// IP Link is UP, reset comms flag
					fnInitCommsTimeout(0,0)
				}
				ELSE{
					STACK_VAR INTEGER z
					fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Is Probably An Object'")
					FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
						STACK_VAR INTEGER o
						FOR(o = 1; o <= MAX_OBJECTS; o++){
							IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
								fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Found Object:Zone ',ITOA(z),':Obj ',ITOA(o)")
								IF(myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME != pOBJ_NAME){
									fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:Processing'")
									myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME  = pOBJ_NAME
									SEND_STRING vdvZone[z],"'PROPERTY-META,',ITOA(o),',OBJNAME,',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME"
								}
								ELSE{
									fnDebug(DEBUG_DEV,"'fnProcessProperty:OBJ_NAME:NoChange'")
								}
							}
						}
					}
				}
			}
			CASE APDU_PROPERTY_ID_PRES_VALUE:{	// Present-Value
				STACK_VAR FLOAT VAL
				STACK_VAR INTEGER z
				VAL = ATOF(FORMAT('%1.1f',fnGetFloatFromPropertyData(pDATA,pPropertyDataStart)))
				fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE:Found:VALUE[',FTOA(VAL),']'")
				FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
					STACK_VAR INTEGER o
					FOR(o = 1; o <= MAX_OBJECTS; o++){
						IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
							fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE:Found Object:Zone ',ITOA(z),':Obj ',ITOA(o)")
							myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE_TYPE = pDATA[pPropertyDataStart+3]
							fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE:DataType $',ITOHEX(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE_TYPE)")
							IF(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE != VAL){
								fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE:New Val [',FTOA(VAL),']'")
								myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE = VAL
								SWITCH(myBACnetZone[z].OBJ_INSTANCE[o].TYPE){
									CASE APDU_OBJ_TYPE_ANALOG_INPUT:
									CASE APDU_OBJ_TYPE_ANALOG_OUTPUT:
									CASE APDU_OBJ_TYPE_ANALOG_VALUE:{
										STACK_VAR INTEGER p
										SEND_STRING vdvZone[z],"'VALUE-',ITOA(o),',',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE)"
										FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
											IF(myBACnetPanel[p].ZONE == z){
												SEND_COMMAND tp[p],"'^TXT-',ITOA(addHVACValueRaw[o]),',0,',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE)"
												SEND_COMMAND tp[p],"'^TXT-',ITOA(addHVACValue[o]),',0,',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE),myBACnetZone[z].OBJ_INSTANCE[o].UNITS_CHAR"
											}
										}
									}
								}
							}
							ELSE{
								fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE:NoChange [',FTOA(VAL),']'")
							}
						}
					}
				}
			}
			CASE APDU_PROPERTY_ID_PRES_VALUE_MIN:{	// Present-Value-Min
				STACK_VAR FLOAT VAL
				STACK_VAR INTEGER z
				VAL = ATOF(FORMAT('%1.1f',fnGetFloatFromPropertyData(pDATA,pPropertyDataStart)))
				fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MIN:Found:VALUE[',FTOA(VAL),']'")
				IF(FTOA(VAL) != '-INF'){
					FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
						STACK_VAR INTEGER o
						FOR(o = 1; o <= MAX_OBJECTS; o++){
							IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
								fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MIN:Found Object:Zone ',ITOA(z),':Obj ',ITOA(o)")
								IF(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN != VAL){
									fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MIN:Processing [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
									myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN = VAL
									myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN_CHANGED = TRUE
								}
								ELSE{
									fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MIN:NoChange [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
								}
							}
						}
					}
				}
				ELSE{
					fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MIN:Ignoring:VALUE[',FTOA(VAL),']'")
				}
			}
			CASE APDU_PROPERTY_ID_PRES_VALUE_MAX:{	// Present-Value-Max
				STACK_VAR FLOAT VAL
				STACK_VAR INTEGER z
				VAL = ATOF(FORMAT('%1.1f',fnGetFloatFromPropertyData(pDATA,pPropertyDataStart)))
				fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MAX:Found:VALUE[',FTOA(VAL),']'")
				IF(FTOA(VAL) != 'INF'){
					FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
						STACK_VAR INTEGER o
						FOR(o = 1; o <= MAX_OBJECTS; o++){
							IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
								fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MAX:Found Object:Zone ',ITOA(z),':Obj ',ITOA(o)")
								IF(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX != VAL || myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN_CHANGED){
									fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MAX:Processing [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
									myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX = VAL
									myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN_CHANGED = FALSE
									SEND_STRING vdvZone[z],"'PROPERTY-RANGE,',ITOA(o),',',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN),',',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX)"
								}
								ELSE{
									fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MAX:NoChange [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
								}
							}
						}
					}
				}
				ELSE{
					fnDebug(DEBUG_DEV,"'fnProcessProperty:PRES_VALUE_MAX:Ignoring:VALUE[',FTOA(VAL),']'")
				}
			}
			CASE APDU_PROPERTY_ID_UNITS:{	// Units
				STACK_VAR INTEGER VAL
				STACK_VAR INTEGER z
				VAL = ATOI(FORMAT('%1.1f',fnGetFloatFromPropertyData(pDATA,pPropertyDataStart)))
				FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
				STACK_VAR INTEGER o
					FOR(o = 1; o <= MAX_OBJECTS; o++){
						IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
							IF(myBACnetZone[z].OBJ_INSTANCE[o].UNITS != VAL){
								myBACnetZone[z].OBJ_INSTANCE[o].UNITS  = VAL
								SWITCH(myBACnetZone[z].OBJ_INSTANCE[o].UNITS){
									CASE UNITS_TYPE_DEGREES_CELCIUS:myBACnetZone[z].OBJ_INSTANCE[o].UNITS_CHAR = '°'
								}
							}
						}
					}
				}
			}
			CASE APDU_PROPERTY_ID_NO_OF_STATES:{	// Number of States (Multi-Property)
				STACK_VAR FLOAT VAL
				STACK_VAR INTEGER z
				VAL = ATOI(FTOA(fnGetFloatFromPropertyData(pDATA,pPropertyDataStart)))
				fnDebug(DEBUG_DEV,"'fnProcessProperty:NO_OF_STATES:Found:VALUE[',FTOA(VAL),']'")
				FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
					STACK_VAR INTEGER o
					FOR(o = 1; o <= MAX_OBJECTS; o++){
						IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE == OBJ_TYPE && myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO == INST_NO){
							fnDebug(DEBUG_DEV,"'fnProcessProperty:NO_OF_STATES:Found Object:Zone ',ITOA(z),':Obj ',ITOA(o)")
							IF(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX != VAL){
								fnDebug(DEBUG_DEV,"'fnProcessProperty:NO_OF_STATES:Processing [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
								myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX  = VAL
							}
							ELSE{
								fnDebug(DEBUG_DEV,"'fnProcessProperty:NO_OF_STATES:NoChange [',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,']'")
							}
						}
					}
				}
			}
		}
	}
}
DEFINE_FUNCTION DOUBLE fnGetFloatFromPropertyData(CHAR pDATA[],INTEGER pStart){
	fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:START[',ITOA(pStart),']'")
	fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:pDATA[',fnBytesToString(pDATA),']'")
	SWITCH(pDATA[pStart+3]){
		CASE $44:{
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData::','Processing Data as Real IEEE-754'")
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:[',fnBytesToString(MID_STRING(pData,pStart+4,4)),']'")
			RETURN fnIEEE754ToFloat(MID_STRING(pData,pStart+4,4))
		}
		CASE $91:{
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData::','Processing Data as Enumerate'")
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:[',fnBytesToString(MID_STRING(pData,pStart+4,1)),']'")
			RETURN ATOF(ITOA(MID_STRING(pData,pStart+4,1)))
		}
		CASE $21:{
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData::','Processing Data as Unsigned Integer'")
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:[',fnBytesToString(MID_STRING(pData,pStart+4,1)),']'")
			RETURN ATOF(ITOA(pData[pStart+4]))
		}
		CASE $22:{
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData::','Processing Data as Unsigned Integer'")
			fnDebug(DEBUG_DEV,"'fnGetFloatFromPropertyData:[',fnBytesToString(MID_STRING(pData,pStart+4,2)),']'")
			RETURN ATOF(ITOA((pData[pStart+4] * 256) + pDATA[pStart+5]))
		}
	}
}

DEFINE_FUNCTION CHAR[255] fnGetStringFromPropertyData(CHAR pDATA[],INTEGER pStart){
	fnDebug(DEBUG_DEV,"'fnGetStringFromPropertyData:'")
	SWITCH(pDATA[pStart+3]){
		CASE $71:{
			fnDebug(DEBUG_DEV,"'fnGetStringFromPropertyData::','Processing As Empty String'")
			RETURN ''
		}
		CASE $75:{
			fnDebug(DEBUG_DEV,"'fnGetStringFromPropertyData::','Processing As String'")
			RETURN MID_STRING(pData,pStart+6,pData[pStart+4]-1)
		}
	}
}
/******************************************************************************
	Communication Helpers - Build and Send
******************************************************************************/
DEFINE_FUNCTION fnQueueCommand(uBACnetMSG pMSG, INTEGER isPolling){
	STACK_VAR CHAR toSend[3000]
	STACK_VAR INTEGER NPDU_CONTROL
	STACK_VAR INTEGER pLEN
	// Sort InvokeID
	myBACnetIP.InvokeID = myBACnetIP.InvokeID + 1
	IF(myBACnetIP.InvokeID == $00 || myBACnetIP.InvokeID == $FF){
		myBACnetIP.InvokeID = $01
	}
	// Build Message - Flags
	NPDU_CONTROL = NPDU_CONTROL + pMSG.NPDU_PRIORITY
	IF(pMSG.NPDU_IS_NETWORK_LAYER_MESSAGE){NPDU_CONTROL = NPDU_CONTROL + $80}
	IF(pMSG.NPDU_EXPECT_REPLY){NPDU_CONTROL = NPDU_CONTROL + $04}
	IF(pMSG.NPDU_DNET){NPDU_CONTROL = NPDU_CONTROL + $20}
	IF(pMSG.NPDU_SNET){NPDU_CONTROL = NPDU_CONTROL + $08}
	// Build NPDU MSG
	toSend = "$01"							// Version
	toSend = "toSend,NPDU_CONTROL"	// Flags
	IF(pMSG.NPDU_DNET){					// Add DNET Details
		STACK_VAR INTEGER pRemainder
		pRemainder = pMSG.NPDU_DNET MOD 256							
		toSend = "toSend,(pMSG.NPDU_DNET-pRemainder) / 256"	// DNET Part 1
		toSend = "toSend,pRemainder"									// DNET Part 2
		toSend = "toSend,LENGTH_ARRAY(pMSG.NPDU_DADR)"			// DADR Length
		toSend = "toSend,pMSG.NPDU_DADR"								// DADR
	}
	IF(pMSG.NPDU_SNET){					// Add SNET Details
		STACK_VAR INTEGER pRemainder
		pRemainder = pMSG.NPDU_SNET MOD 256							
		toSend = "toSend,(pMSG.NPDU_SNET-pRemainder) / 256"	// SNET Part 1
		toSend = "toSend,pRemainder"									// SNET Part 2
		toSend = "toSend,LENGTH_ARRAY(pMSG.NPDU_SADR)"			// SADR Length
		toSend = "toSend,pMSG.NPDU_SADR"								// SADR
	}
	IF(pMSG.NPDU_DNET){					// Add Hop Count
		toSend = "toSend,255"
	}
	// Build APDU MSG
	IF(!pMSG.NPDU_IS_NETWORK_LAYER_MESSAGE){
		SWITCH(pMSG.APDU_REQUEST_TYPE){
			CASE APDU_REQUEST_UNCONFIRMED:{
				toSend = "toSend,pMSG.APDU_REQUEST_TYPE"
				toSend = "toSend,pMSG.APDU_SERVICE_CHOICE"
			}
			CASE APDU_REQUEST_CONFIRMED:{
				// Add Segmentation Flags - "....000." where .... is Type, then SegmentedRequest|MoreSegmentsFollow|SegmentAccepted
				SWITCH(pMSG.APDU_SERVICE_CHOICE){
					CASE APDU_SERVICE_CHOICE_WRITEPROP:		toSend = "toSend,pMSG.APDU_REQUEST_TYPE+$00"	// Flags added to Request Type Byte
					CASE APDU_SERVICE_CHOICE_READPROP:
					CASE APDU_SERVICE_CHOICE_READPROPMULTI:
					CASE APDU_SERVICE_CHOICE_SUBSCRIBECOV:	toSend = "toSend,pMSG.APDU_REQUEST_TYPE+$00"	// Flags added to Request Type Byte
				}
				// Sizes
				SWITCH(pMSG.APDU_SERVICE_CHOICE){
					CASE APDU_SERVICE_CHOICE_WRITEPROP:		toSend = "toSend,$05"
					CASE APDU_SERVICE_CHOICE_READPROP:
					CASE APDU_SERVICE_CHOICE_READPROPMULTI:toSend = "toSend,$55"		// Sizes
					CASE APDU_SERVICE_CHOICE_SUBSCRIBECOV:	toSend = "toSend,$15"		// Sizes
				}
				// Invoke ID
				toSend = "toSend,myBACnetIP.InvokeID"	// Invoke ID
				// Service Choice
				toSend = "toSend,pMSG.APDU_SERVICE_CHOICE"
				
				
				SWITCH(pMSG.APDU_SERVICE_CHOICE){
					CASE APDU_SERVICE_CHOICE_WRITEPROP:
					CASE APDU_SERVICE_CHOICE_READPROP:
					CASE APDU_SERVICE_CHOICE_READPROPMULTI:toSend = "toSend,$0C"		// Context Tag
					CASE APDU_SERVICE_CHOICE_SUBSCRIBECOV:{
						toSend = "toSend,$09,$01"	// SubscriberID
						toSend = "toSend,$1C"		// Context Tag
					}
				}

				// Add Identifier to message
				toSend = "toSend,fnBuildObjectIdentifier(pMSG.APDU_OBJ_TYPE,pMSG.APDU_OBJ_INST_NO)"

				SWITCH(pMSG.APDU_SERVICE_CHOICE){
					CASE APDU_SERVICE_CHOICE_READPROPMULTI:{
						STACK_VAR INTEGER x
						STACK_VAR CHAR PROPS[50]
						FOR(x = 1; x <= LENGTH_ARRAY(pMSG.APDU_TO_READ); x++){
							IF(pMSG.APDU_TO_READ[x] != $00){
								PROPS = "PROPS,$09,pMSG.APDU_TO_READ[x]"
							}
						}
						toSend = "toSend,$1e,PROPS,$1f"
					}
					CASE APDU_SERVICE_CHOICE_READPROP:{
						toSend = "toSend,$19"	// context tag
						toSend = "toSend,pMSG.APDU_PROPERTY_ID"	// Property ID
					}
					CASE APDU_SERVICE_CHOICE_SUBSCRIBECOV:{
						toSend = "toSend,$29"	// Issue Confirmed Notifications
						toSend = "toSend,$00"	// False
						toSend = "toSend,$39"	// Time to Subscribe
						toSend = "toSend,$78"	// 120s
					}
					CASE APDU_SERVICE_CHOICE_WRITEPROP:{
						STACK_VAR CHAR newVal[10]
						toSend = "toSend,$19"	// context tag
						toSend = "toSend,pMSG.APDU_PROPERTY_ID"	// Property ID
						SWITCH(pMSG.APDU_VALUE_TYPE){
							CASE $91:newVal = "$91,ATOI(pMSG.APDU_VALUE)"
							CASE $44:newVal = "$44,fnFloatToIEEE754(ATOF(pMSG.APDU_VALUE))"
							#WARN 'only caters for 256 max'
							CASE $21:newVal = "$21,ATOI(pMSG.APDU_VALUE)"
							CASE $22:newVal = "$22,ATOI(pMSG.APDU_VALUE)"
						}
						toSend = "toSend,$3E,newVal,$3F"
					}
				}
			}
		}
	}
	// Build BVLC Headers
	// Calculate Length
	IF(1){
		STACK_VAR INTEGER pRemainder
		pRemainder = LENGTH_ARRAY(toSend)+4 MOD 256
		toSend = "pRemainder,toSend"											// DNET Part 2
		toSend = "(LENGTH_ARRAY(toSend)+4-pRemainder) / 256,toSend"	// DNET Part 1
	}
	IF(!pMSG.BVLC_MSG_TYPE){pMSG.BVLC_MSG_TYPE = BVLC_ORIGINAL_UNICAST}
	toSend = "pMSG.BVLC_MSG_TYPE,toSend"
	toSend = "$81,toSend"		// BACNetIP Identifier

	IF(isPolling){
		myBACnetIP.TxPoll = "myBACnetIP.TxPoll,toSend,'DELIMIT'"
	}
	ELSE{
		myBACnetIP.TxCmd = "myBACnetIP.TxCmd,toSend,'DELIMIT'"
	}
	
	fnSendFromQueue()
}
DEFINE_FUNCTION fnSendFromQueue(){
	IF(!myBACnetIP.PendID){
		// Send Message
		IF(FIND_STRING(myBACnetIP.TxPoll,'DELIMIT',1) || FIND_STRING(myBACnetIP.TxCmd,'DELIMIT',1)){
			STACK_VAR CHAR toSend[1000]
			IF(FIND_STRING(myBACnetIP.TxCmd,'DELIMIT',1)){
				toSend = REMOVE_STRING(myBACnetIP.TxCmd,'DELIMIT',1)
				fnDebug(DEBUG_STD,"'Sending from Cmd Queue'")
			}
			ELSE{
				toSend = REMOVE_STRING(myBACnetIP.TxPoll,'DELIMIT',1)
				fnDebug(DEBUG_STD,"'Sending from Poll Queue'")
			}
			toSend = fnStripCharsRight(toSend,7)
			
			myBACnetIP.PendID = toSend[9]
			fnDebug(DEBUG_STD,"'Pending::Activate ',ITOA(myBACnetIP.PendID)")
			
			fnDebug(DEBUG_DEV,"'->BacNET ',fnBytesToString(toSend)")
			SEND_STRING ipUDP,toSend
			
			IF(TIMELINE_ACTIVE(TLID_TIMEOUT)){TIMELINE_KILL(TLID_TIMEOUT)}
			TIMELINE_CREATE(TLID_TIMEOUT,TLT_TIMEOUT,LENGTH_ARRAY(TLT_TIMEOUT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_TIMEOUT]{
	fnDebug(DEBUG_STD,"'Pending::TimeOut ',ITOA(myBACnetIP.PendID)")
	myBACnetIP.PendID = 0
	//myBACnetIP.TxPoll = ''
	myBACnetIP.TxCmd = ''
	fnSendFromQueue()
}
/******************************************************************************
	Communication Helpers - Init
******************************************************************************/
DEFINE_START{
	// Assign NoData constants (as 0x00 is a value in Bacnet)
	STACK_VAR INTEGER z
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
		STACK_VAR INTEGER o
		FOR(o = 1; o <= MAX_OBJECTS; o++){
			myBACnetZone[z].OBJ_INSTANCE[o].UNITS = UNITS_TYPE_UNDEFINED
			myBACnetZone[z].OBJ_INSTANCE[o].TYPE  = APDU_OBJ_TYPE_UNDEFINED
		}
	}
}
DEFINE_FUNCTION fnInitSystem(){
	IF(myBACnetIP.PROCESSOR.INSTANCE_NO == 0){myBACnetIP.PROCESSOR.INSTANCE_NO = 1}
	myBACnetIP.PROCESSOR.TYPE = APDU_OBJ_TYPE_DEVICE
	// Get system properties
	fnPoll()
	fnInitPoll()
}
/******************************************************************************
	Communication Helpers - SetValue
******************************************************************************/
DEFINE_FUNCTION fnReadProperty(LONG OBJ_TYPE, LONG INST_NO, INTEGER PROP_ID){
	STACK_VAR uBACnetMSG myBACnetMSG
	myBACnetMSG.BVLC_MSG_TYPE 			= BVLC_ORIGINAL_UNICAST
	myBACnetMSG.NPDU_EXPECT_REPLY 	= TRUE
	myBACnetMSG.APDU_REQUEST_TYPE 	= APDU_REQUEST_CONFIRMED
	myBACnetMSG.APDU_SERVICE_CHOICE 	= APDU_SERVICE_CHOICE_READPROP
	myBACnetMSG.APDU_PROPERTY_ID		= PROP_ID
	myBACnetMSG.APDU_OBJ_INST_NO		= INST_NO
	myBACnetMSG.APDU_OBJ_TYPE			= OBJ_TYPE
	fnDebug(DEBUG_DEV,"'fnReadMultiProperty::OBJ_TYPE[',ITOA(OBJ_TYPE),']INST_NO[',ITOA(INST_NO),']PROP_ID[',ITOA(PROP_ID),']'")
	fnQueueCommand(myBACnetMSG,TRUE)
}

DEFINE_FUNCTION fnReadMultiProperty(LONG OBJ_TYPE, LONG INST_NO, CHAR PROPS[]){
	STACK_VAR uBACnetMSG myBACnetMSG
	STACK_VAR INTEGER x
	myBACnetMSG.BVLC_MSG_TYPE 			= BVLC_ORIGINAL_UNICAST
	myBACnetMSG.NPDU_EXPECT_REPLY 	= TRUE
	myBACnetMSG.APDU_REQUEST_TYPE 	= APDU_REQUEST_CONFIRMED
	myBACnetMSG.APDU_SERVICE_CHOICE 	= APDU_SERVICE_CHOICE_READPROPMULTI
	myBACnetMSG.APDU_OBJ_INST_NO		= INST_NO
	myBACnetMSG.APDU_OBJ_TYPE			= OBJ_TYPE
	FOR(x = 1; x <= LENGTH_ARRAY(PROPS); x++){
		IF(PROPS[x] != $00){
			myBACnetMSG.APDU_TO_READ = "myBACnetMSG.APDU_TO_READ,PROPS[x]"
		}
	}
	fnDebug(DEBUG_DEV,"'fnReadMultiProperty::OBJ_TYPE[',ITOA(OBJ_TYPE),']INST_NO[',ITOA(INST_NO),']PROPS[',fnBytesToString(PROPS),']'")
	fnQueueCommand(myBACnetMSG,TRUE)
}
DEFINE_FUNCTION fnSubscribeToObject(LONG OBJ_TYPE, LONG INST_NO){
	STACK_VAR uBACnetMSG myBACnetMSG
	myBACnetMSG.BVLC_MSG_TYPE 			= BVLC_ORIGINAL_UNICAST
	myBACnetMSG.NPDU_EXPECT_REPLY 	= TRUE
	myBACnetMSG.APDU_REQUEST_TYPE 	= APDU_REQUEST_CONFIRMED
	myBACnetMSG.APDU_SERVICE_CHOICE 	= APDU_SERVICE_CHOICE_SUBSCRIBECOV
	myBACnetMSG.APDU_OBJ_INST_NO		= INST_NO
	myBACnetMSG.APDU_OBJ_TYPE			= OBJ_TYPE
	fnDebug(DEBUG_DEV,"'fnSubscribeToObject::OBJ_TYPE[',ITOA(OBJ_TYPE),']INST_NO[',ITOA(INST_NO),']'")
	fnQueueCommand(myBACnetMSG,TRUE)
}
DEFINE_FUNCTION fnSetPresentValue(INTEGER z, INTEGER o,CHAR VAL[]){
	STACK_VAR uBACnetMSG myBACnetMSG
	myBACnetMSG.BVLC_MSG_TYPE 			= BVLC_ORIGINAL_UNICAST
	myBACnetMSG.NPDU_EXPECT_REPLY 	= TRUE
	myBACnetMSG.APDU_REQUEST_TYPE 	= APDU_REQUEST_CONFIRMED
	myBACnetMSG.APDU_SERVICE_CHOICE 	= APDU_SERVICE_CHOICE_WRITEPROP
	myBACnetMSG.APDU_OBJ_TYPE			= myBACnetZone[z].OBJ_INSTANCE[o].TYPE
	myBACnetMSG.APDU_OBJ_INST_NO		= myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO
	myBACnetMSG.APDU_PROPERTY_ID		= APDU_PROPERTY_ID_PRES_VALUE
	myBACnetMSG.APDU_VALUE_TYPE		= myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE_TYPE
	myBACnetMSG.APDU_VALUE				= VAL
	fnDebug(DEBUG_DEV,"'fnSetPresentValue::z[',ITOA(z),']o[',ITOA(o),']VAL[',VAL,']'")
	fnDebug(DEBUG_DEV,"'fnSetPresentValue::OBJ_TYPE[',ITOA(myBACnetMSG.APDU_OBJ_TYPE),']INST_NO[',ITOA(myBACnetMSG.APDU_OBJ_INST_NO),']'")
	fnQueueCommand(myBACnetMSG,FALSE)
}
/******************************************************************************
	Communication Helpers - Utils
******************************************************************************/
DEFINE_FUNCTION CHAR[4] fnBuildObjectIdentifier(LONG pTYPE,LONG pInstNo){
	// Variables
	STACK_VAR CHAR pTypeAsBin[10]
	STACK_VAR CHAR pInstAsBin[24]
	STACK_VAR CHAR pResult[4]
	STACK_VAR INTEGER x
	
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pTYPE[',ITOA(pTYPE),']pInstNo[',ITOA(pInstNo),']'")
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pInstAsBytes[',fnBytesToString(fnLongToByte(pInstNo,0)),']'")
	
	// Set Variables
	pTypeAsBin  = fnPadLeadingChars(fnBytesToBinary("pType"),'0',10)
	pInstAsBin  = fnPadLeadingChars(RIGHT_STRING(fnBytesToBinary(fnLongToByte(pInstNo,0)),22),'0',22)
	
	pResult = fnPadLeadingChars(fnBinaryToByte("pTypeAsBin,pInstAsBin"),$00,4)
	
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pTypeAsBin[',pTypeAsBin,']pInstAsBin[',pInstAsBin,']'")
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pFullBin[',pTypeAsBin,pInstAsBin,']'")
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pResultAsLong[',ITOA(fnBinaryToLong("pTypeAsBin,pInstAsBin")),']'")
	fnDebug(DEBUG_DEV,"'fnBuildObjectIdentifier::pResult[',fnBytesToString(pResult),']'")

	RETURN pResult
}

DEFINE_FUNCTION LONG fnGetObjectInstNoFromIdentifier(CHAR pIdent[4]){
	STACK_VAR CHAR pIdentAsBin[32]
	STACK_VAR CHAR pInstancePart[22]
	STACK_VAR LONG pReturn
	
	fnDebug(DEBUG_DEV,"'fnGetObjectInstNoFromIdentifier::pIdent[',fnBytesToString(pIdent),']'")

	pIdentAsBin = fnBytesToBinary(pIdent)
	pInstancePart = RIGHT_STRING(pIdentAsBin,22)
	pReturn = fnBinaryToLong(pInstancePart)
	
	fnDebug(DEBUG_DEV,"'fnGetObjectInstNoFromIdentifier::pIdentAsBin[',pIdentAsBin,']'")
	fnDebug(DEBUG_DEV,"'fnGetObjectInstNoFromIdentifier::pInstancePart[',pInstancePart,'] pReturn[',ITOA(pReturn),']'")
	
	RETURN pReturn
}

DEFINE_FUNCTION LONG fnGetObjectTypeFromIdentifier(CHAR pIdent[4]){
	STACK_VAR CHAR pIdentAsBin[32]
	STACK_VAR CHAR pTypePart[10]
	STACK_VAR LONG pReturn
	
	fnDebug(DEBUG_DEV,"'fnGetObjectTypeFromIdentifier::pIdent[',fnBytesToString(pIdent),']'")

	pIdentAsBin = fnBytesToBinary(pIdent)
	pTypePart = LEFT_STRING(pIdentAsBin,10)
	pReturn = fnBinaryToLong(pTypePart)
	
	fnDebug(DEBUG_DEV,"'fnGetObjectTypeFromIdentifier::pIdentAsBin[',pIdentAsBin,']'")
	fnDebug(DEBUG_DEV,"'fnGetObjectTypeFromIdentifier::pTypePart[',pTypePart,'] pReturn[',ITOA(pReturn),']'")
	
	RETURN pReturn
}
/******************************************************************************
	Communication Helpers - Polling
******************************************************************************/
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){TIMELINE_KILL(TLID_POLL)}
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}
DEFINE_FUNCTION fnPoll(){
	STACK_VAR CHAR PROPS[10]
	
	fnDebug(DEBUG_DEV,"'fnPoll::Called'")
	
	// Poll out the Processor name based on ID to check connection to correct system
	fnDebug(DEBUG_DEV,"'fnPoll::ProcessorNameNotDiscoveredYet'")
	PROPS = "PROPS,APDU_PROPERTY_ID_OBJ_NAME"
	fnDebug(DEBUG_STD,"'Queing Get Object Name Of Processor'")
	fnReadMultiProperty(myBACnetIP.PROCESSOR.TYPE,myBACnetIP.PROCESSOR.INSTANCE_NO,PROPS)

	// If processor name has been verifed then poll out all subscriptions
	IF(LENGTH_ARRAY(myBACnetIP.PROCESSOR.PROP_NAME)){
		STACK_VAR INTEGER z
		fnDebug(DEBUG_DEV,"'fnPoll::ProcessorNameDiscovered'")
		FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
			STACK_VAR INTEGER o
			FOR(o = 1; o <= MAX_OBJECTS; o++){
				IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE != APDU_OBJ_TYPE_UNDEFINED){
					IF(LENGTH_ARRAY(myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME)){
						fnDebug(DEBUG_STD,"'Queing Subscription To ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME")
						fnSubscribeToObject(myBACnetZone[z].OBJ_INSTANCE[o].TYPE,myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO)
					}
					ELSE{
						PROPS = "APDU_PROPERTY_ALL"
						fnDebug(DEBUG_STD,"'Queing Get All Properties Of Zone ',ITOA(z),' Obj ',ITOA(o)")
						fnReadMultiProperty(myBACnetZone[z].OBJ_INSTANCE[o].TYPE,myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO,PROPS)
					}
				}
			}
		}
	}
	
	fnDebug(DEBUG_STD,"'fnPoll::Ended'")
}
/******************************************************************************
	Device Events - Virtual Devices - Main 
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'TRUE':	myBACnetIP.DEBUG = DEBUG_STD
							CASE 'DEV':		myBACnetIP.DEBUG = DEBUG_DEV
							DEFAULT:			myBACnetIP.DEBUG = DEBUG_OFF
						}
					}
					CASE 'IP':{
						IF(FIND_STRING(DATA.TEXT,':',1)){
							myBACnetIP.IP_HOST = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,':',1),1)
							myBACnetIP.IP_PORT = ATOI(DATA.TEXT)
						}
						ELSE{
							myBACnetIP.IP_HOST = DATA.TEXT
							myBACnetIP.IP_PORT = 47808
						}
						// Open Sending UDP Port
						IP_BOUND_CLIENT_OPEN(ipUDP.PORT,myBACnetIP.IP_PORT,myBACnetIP.IP_HOST,myBACnetIP.IP_PORT,IP_UDP_2WAY)
					}
					CASE 'ID':{
						myBACnetIP.PROCESSOR.INSTANCE_NO = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'TEST':{
				SWITCH(DATA.TEXT){
					CASE 'INIT':{
						fnDebug(DEBUG_STD,"'Developer Command: Init System'")
						myBACnetIP.PROCESSOR.PROP_NAME = ''
						fnInitSystem()
					}
					CASE 'POLL': fnPoll()
					CASE 'SUB':  fnSubscribeToObject(myBACnetZone[1].OBJ_INSTANCE[1].TYPE,myBACnetZone[1].OBJ_INSTANCE[1].INSTANCE_NO)
					CASE 'BINARY':{
						SEND_STRING 0, "'FLOAT: ',fnIEEE754ToFloat("$00,$04,$10,$14")"
					}
				}
			}
		}
	}
}
/******************************************************************************
	Device Events - Virtual Devices - Zones 
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvZone]{
	COMMAND:{
		STACK_VAR INTEGER z
		z = GET_LAST(vdvZone)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'ID':{
						STACK_VAR INTEGER o
						o = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'ANALOG_INPUT':			myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_ANALOG_INPUT
							CASE 'ANALOG_OUTPUT':		myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_ANALOG_OUTPUT
							CASE 'ANALOG_VALUE':			myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_ANALOG_VALUE
							CASE 'BINARY_INPUT':			myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_BINARY_INPUT
							CASE 'BINARY_OUTPUT':		myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_BINARY_OUTPUT
							CASE 'BINARY_VALUE':			myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_BINARY_VALUE
							CASE 'MULTISTATE_INPUT':	myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_MULTISTATE_INPUT
							CASE 'MULTISTATE_OUTPUT':	myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_MULTISTATE_OUTPUT
							CASE 'MULTISTATE_VALUE':	myBACnetZone[z].OBJ_INSTANCE[o].TYPE = APDU_OBJ_TYPE_MULTISTATE_VALUE
						}
						myBACnetZone[z].OBJ_INSTANCE[o].INSTANCE_NO = ATOI(DATA.TEXT)
					}
					CASE 'RANGE':{
						STACK_VAR INTEGER o
						o = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'MIN':myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN = ATOF(DATA.TEXT)
							CASE 'MAX':myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX = ATOF(DATA.TEXT)
						}
					}
				}
			}
			CASE 'VALUE':{
				STACK_VAR INTEGER o
				STACK_VAR FLOAT newVal
				o = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				SWITCH(DATA.TEXT){
					CASE 'ON':{
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to 1'")
						fnSetPresentValue(z,o,ITOA(1))
					}
					CASE 'OFF':{
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to 0'")
						fnSetPresentValue(z,o,ITOA(0))
					}
					CASE 'TOGGLE':{
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to ',ITOA(!myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE)")
						fnSetPresentValue(z,o,ITOA(!myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE))
					}
					CASE 'INC':{
						newVal = myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE + 1
						IF(newVal >= myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX){
							newVal = myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MAX
						}
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to ',FTOA(newVal)")
						fnSetPresentValue(z,o,FTOA(newVal))
					}
					CASE 'DEC':{
						newVal = myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE - 1
						IF(newVal <= myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN){
							newVal = myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_MIN
						}
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to ',FTOA(newVal)")
						fnSetPresentValue(z,o,FTOA(newVal))
					}
					DEFAULT:{
						fnDebug(DEBUG_STD,"'Setting ',myBACnetZone[z].OBJ_INSTANCE[o].PROP_NAME,' to ',DATA.TEXT")
						fnSetPresentValue(z,o,DATA.TEXT)
					}
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER z
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
		STACK_VAR INTEGER o
		FOR(o = 1; o <= MAX_OBJECTS; o++){
			SWITCH(myBACnetZone[z].OBJ_INSTANCE[o].TYPE){
				CASE APDU_OBJ_TYPE_MULTISTATE_INPUT:
				CASE APDU_OBJ_TYPE_MULTISTATE_OUTPUT:
				CASE APDU_OBJ_TYPE_MULTISTATE_VALUE:
				CASE APDU_OBJ_TYPE_ANALOG_INPUT:
				CASE APDU_OBJ_TYPE_ANALOG_OUTPUT:
				CASE APDU_OBJ_TYPE_ANALOG_VALUE:{
					STACK_VAR INTEGER p
					FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
						IF(myBACnetPanel[p].ZONE == z){
							SEND_LEVEL tp[p],o,ATOI(FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE))
							[tp[p],btnHVACToggle[o]] = (myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE > 0)
						}
					}
					SEND_LEVEL vdvZone[z],o,ATOI(FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE))
				}
				CASE APDU_OBJ_TYPE_BINARY_INPUT:
				CASE APDU_OBJ_TYPE_BINARY_OUTPUT:
				CASE APDU_OBJ_TYPE_BINARY_VALUE:{
					STACK_VAR INTEGER p
					FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
						IF(myBACnetPanel[p].ZONE == z){
							[tp[p],btnHVACToggle[o]] = (myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE > 0)
						}
					}
					[vdvZone[z],o] = (myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE > 0)
				}
			}
		}
	}
}
/******************************************************************************
	Device Events - Actual Ethernet Messages
******************************************************************************/
DEFINE_EVENT DATA_EVENT[ipUDP]{
	ONLINE:{
		fnInitSystem()
	}
	STRING:{
		fnDebug(DEBUG_DEV, "'UDP From->',DATA.SOURCEIP,':',ITOA(DATA.SOURCEPORT)")
		fnDebug(DEBUG_DEV, "'BacNET-> ',fnBytesToString(DATA.TEXT)")
		fnProcessFeedback(DATA.TEXT)
	}
}

/******************************************************************************
	Communication Status Control
******************************************************************************/
DEFINE_FUNCTION fnInitCommsTimeout(INTEGER pZone,INTEGER pObject){
	STACK_VAR LONG TLID
	
	fnDebug(DEBUG_DEV,"'fnInitCommsTimeout::pZone=',ITOA(pZone),',pObject=',ITOA(pObject)")
	TLID = TLID_COMMS_000 + (pZone*1000) + pObject
	
	fnDebug(DEBUG_DEV,"'TIMELINE_CREATE::TLID_COMMS::',ITOA(TLID)")
	IF(TIMELINE_ACTIVE(TLID)){TIMELINE_KILL(TLID)}
	TIMELINE_CREATE(TLID,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER z
	STACK_VAR INTEGER o
	
	// Zone Comms Feedback
	FOR(z = 1; z <= LENGTH_ARRAY(vdvZone); z++){
		STACK_VAR INTEGER ZoneFaultFound
		FOR(o = 1; o <= MAX_OBJECTS; o++){
			STACK_VAR LONG TLID
			IF(myBACnetZone[z].OBJ_INSTANCE[o].TYPE != APDU_OBJ_TYPE_UNDEFINED){
				TLID = TLID_COMMS_000 + (z*1000) + o
				[vdvZone[z],240+o] = (TIMELINE_ACTIVE(TLID))
				ZoneFaultFound = ZoneFaultFound + !TIMELINE_ACTIVE(TLID)
			}
		}
		[vdvZone[z],251] = (!ZoneFaultFound)
		[vdvZone[z],252] = (!ZoneFaultFound)
	}
	
	// Module Comms Feedback
	[vdvControl,251] = (TIMELINE_ACTIVE(TLID_COMMS_000))
	[vdvControl,252] = (TIMELINE_ACTIVE(TLID_COMMS_000))
}

/******************************************************************************
	Interface Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:{
		myBACnetPanel[GET_LAST(tp)].ZONE = 0
		fnSetupPanel(GET_LAST(tp))
	}
}
DEFINE_FUNCTION fnSetupPanel(INTEGER pPanel){
	STACK_VAR INTEGER z
	STACK_VAR INTEGER o
	z = myBACnetPanel[pPanel].ZONE
	IF(z){
		FOR(o = 1; o <= MAX_OBJECTS; o++){
			SWITCH(myBACnetZone[z].OBJ_INSTANCE[o].TYPE){
				CASE APDU_OBJ_TYPE_MULTISTATE_INPUT:
				CASE APDU_OBJ_TYPE_MULTISTATE_OUTPUT:
				CASE APDU_OBJ_TYPE_MULTISTATE_VALUE:
				CASE APDU_OBJ_TYPE_ANALOG_INPUT:
				CASE APDU_OBJ_TYPE_ANALOG_OUTPUT:
				CASE APDU_OBJ_TYPE_ANALOG_VALUE:{
					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addHVACValueRaw[o]),',0,',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE)"
					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addHVACValue[o]),',0,',FTOA(myBACnetZone[z].OBJ_INSTANCE[o].PRESENT_VALUE),myBACnetZone[z].OBJ_INSTANCE[o].UNITS_CHAR"
				}
				DEFAULT:{
					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addHVACValueRaw[o]),',0,'"
					SEND_COMMAND tp[pPanel],"'^TXT-',ITOA(addHVACValue[o]),',0,'"
				}
			}
		}
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnHVACToggle]{
	PUSH:{
		SEND_COMMAND vdvZone[myBACnetPanel[GET_LAST(tp)].ZONE],"'VALUE-',ITOA(GET_LAST(btnHVACToggle)),',TOGGLE'"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnHVACDec]{
	PUSH:{
		SEND_COMMAND vdvZone[myBACnetPanel[GET_LAST(tp)].ZONE],"'VALUE-',ITOA(GET_LAST(btnHVACDec)),',DEC'"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnHVACInc]{
	PUSH:{
		SEND_COMMAND vdvZone[myBACnetPanel[GET_LAST(tp)].ZONE],"'VALUE-',ITOA(GET_LAST(btnHVACInc)),',INC'"
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnZoneDeSelect]{
	PUSH:{
		myBACnetPanel[GET_LAST(tp)].ZONE = 0
		fnSetupPanel(GET_LAST(tp))
	}
}
DEFINE_EVENT BUTTON_EVENT[tp,btnZoneSelect]{
	PUSH:{
		myBACnetPanel[GET_LAST(tp)].ZONE = GET_LAST(btnZoneSelect)
		fnSetupPanel(GET_LAST(tp))
	}
}
/******************************************************************************
	EoF
******************************************************************************/