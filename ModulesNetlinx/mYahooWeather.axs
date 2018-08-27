MODULE_NAME='mYahooWeather'(DEV vdvControl, DEV tp[], DEV ipDevice) 
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic parsing module for Yahoo Weather, with UI
******************************************************************************/
/******************************************************************************
	System Structures
******************************************************************************/
DEFINE_TYPE STRUCTURE uCOMMS{
	CHAR cRxBuffer[20000]
	INTEGER bConnected
	INTEGER bTrying
	LONG 	  WOEID
	INTEGER DEBUG
	CHAR    UNITS
}
DEFINE_TYPE STRUCTURE uWeatherData{
	//Weather Information
	CHAR 		TITLE[100]
	CHAR 		CITY[100]
	CHAR 		REGION[100]
	CHAR 		COUNTRY[100]
	//Wind
	SINTEGER windCHILL
	INTEGER  windDEGREE
	INTEGER 	windSPEED
	//Atmosphere
	INTEGER 	atmosHUMIDITY
	INTEGER 	atmosVISIBILITY
	FLOAT 	atmosPRESSURE
	INTEGER 	atmosCHANGE
	//Astronomy
	CHAR 		SUNRISE[10]
	CHAR 		SUNSET[10]
	//Condition
	CHAR 		condTEXT[50]
	INTEGER 	condCODE
	SINTEGER condTEMP
	SINTEGER condTEMP_SPLIT[2]
	CHAR		condDATE[20]
	//Forecast
	CHAR 		forDAY[5][4]
	CHAR 		forDATE[5][20]
	SINTEGER forLOW[5]
	SINTEGER forHIGH[5]
	CHAR 		forTEXT[5][50]
	INTEGER 	forCODE[5]
}
/******************************************************************************
	System Constants
******************************************************************************/
DEFINE_CONSTANT
// Barometer Constants
CHAR cYWBaromArray[][8]={'steady','rising','falling'}
LONG TLID_POLL 	= 1
LONG TLID_COMMS	= 2
LONG TLID_BOOT		= 3
// Interface Addresses
INTEGER addTITLE 				= 1
INTEGER addCITY 				= 2
INTEGER addREGION				= 3
INTEGER addCOUNTRY 			= 4

INTEGER addwindCHILL			= 5
INTEGER addwindDIR			= 7
INTEGER addwindSPEED			= 8

INTEGER addatmosHUMIDITY	= 9
INTEGER addatmosVISIBILITY	= 10
INTEGER addatmosPRESSURE	= 11
INTEGER addatmosCHANGE		= 12

INTEGER addSUNRISE			= 13
INTEGER addSUNSET				= 14

INTEGER addcondTEXT			= 15
INTEGER addcondTEMP			= 16
INTEGER addcondDATE			= 17

INTEGER addcondTEMP_Split[2] = {18,19}

INTEGER lvlcondCODE			= 1
INTEGER lvlwindDEGREE		= 2

/******************************************************************************
	System Variables
******************************************************************************/
DEFINE_VARIABLE
// Comms
uCOMMS myCOMMS
LONG TLT_POLL[]  = {60000}
LONG TLT_COMMS[] = {180000}
LONG TLT_BOOT[]  = {10000}
// Offsets
INTEGER addOFFSET
INTEGER lvlOFFSET

// Data
uWeatherData curWeather
uWeatherData newWeather
/******************************************************************************
	Feedback Routines
******************************************************************************/
DEFINE_FUNCTION fnFeedbackNew(){
	IF(newWeather.TITLE != curWeather.TITLE){
		SEND_STRING vdvControl, "'TITLE-',newWeather.TITLE"
		SEND_COMMAND tp, "'^TXT-',ITOA(addTITLE+addOFFSET),',0,',newWeather.TITLE"
	}
	IF(newWeather.CITY != curWeather.CITY){
		SEND_STRING vdvControl, "'CITY-',newWeather.CITY"
		SEND_COMMAND tp, "'^TXT-',ITOA(addCITY+addOFFSET),',0,',newWeather.CITY"
	}
	IF(newWeather.COUNTRY != curWeather.COUNTRY){
		SEND_STRING vdvControl, "'COUNTRY-',newWeather.COUNTRY"
		SEND_COMMAND tp, "'^TXT-',ITOA(addCOUNTRY+addOFFSET),',0,',newWeather.COUNTRY"
	}
	IF(newWeather.REGION != curWeather.REGION){
		SEND_STRING vdvControl, "'REGION-',newWeather.REGION"
		SEND_COMMAND tp, "'^TXT-',ITOA(addREGION+addOFFSET),',0,',newWeather.REGION"
	}
	
	IF(newWeather.windCHILL != curWeather.windCHILL){
		SEND_STRING vdvControl, "'WIND-CHILL,',ITOA(newWeather.windCHILL)"
		SEND_COMMAND tp, "'^TXT-',ITOA(addwindCHILL+addOFFSET),',0,',ITOA(newWeather.windCHILL)"
	}
	IF(newWeather.windDEGREE != curWeather.windDEGREE){
		SEND_STRING vdvControl, "'WIND-DEGREE,',ITOA(newWeather.windDEGREE)"
		SEND_STRING vdvControl, "'WIND-DIR,',fnGetWindDir(newWeather.windDEGREE)"
		SEND_LEVEL tp,lvlwindDEGREE+lvlOFFSET, newWeather.windDEGREE
		SEND_COMMAND tp, "'^TXT-',ITOA(addwindDIR+addOFFSET),',0,',fnGetWindDir(newWeather.windDEGREE)"
	}
	IF(newWeather.windSPEED != curWeather.windSPEED){
		SEND_STRING vdvControl, "'WIND-SPEED,',ITOA(newWeather.windSPEED)"
		SEND_COMMAND tp, "'^TXT-',ITOA(addwindSPEED+addOFFSET),',0,',ITOA(newWeather.windSPEED)"
	}
	
	IF(newWeather.SUNRISE != curWeather.SUNRISE){
		SEND_STRING vdvControl, "'SUNRISE-',newWeather.SUNRISE"
		SEND_COMMAND tp, "'^TXT-',ITOA(addSUNRISE+addOFFSET),',0,',newWeather.SUNRISE"
	}
	IF(newWeather.SUNSET != curWeather.SUNSET){
		SEND_STRING vdvControl, "'SUNSET-',newWeather.SUNSET"
		SEND_COMMAND tp, "'^TXT-',ITOA(addSUNSET+addOFFSET),',0,',newWeather.SUNSET"
	}
	
	IF(newWeather.condTEXT != curWeather.condTEXT){
		SEND_STRING  vdvControl, "'CONDITION-TEXT,',newWeather.condTEXT"
		SEND_LEVEL   tp,lvlcondCODE+lvlOFFSET,newWeather.condCODE+1
		SEND_COMMAND tp, "'^TXT-',ITOA(addcondTEXT+addOFFSET),',0,',newWeather.condTEXT"
	}
	IF(newWeather.condTEMP != curWeather.condTEMP){
		IF(newWeather.condTEMP_SPLIT[1]){
			SEND_COMMAND tp, "'^TXT-',ITOA(addcondTEMP_Split[1]+addOFFSET),',0,',ITOA(newWeather.condTEMP_SPLIT[1])"
		}
		ELSE{
			SEND_COMMAND tp, "'^TXT-',ITOA(addcondTEMP_Split[1]+addOFFSET),',0,'"
		}
		SEND_COMMAND tp, "'^TXT-',ITOA(addcondTEMP_Split[2]+addOFFSET),',0,',ITOA(newWeather.condTEMP_SPLIT[2])"
		SEND_STRING vdvControl, "'CONDITION-TEMP,',ITOA(newWeather.condTEMP)"
		SEND_COMMAND tp, "'^TXT-',ITOA(addcondTEMP+addOFFSET),',0,',ITOA(newWeather.condTEMP)"
		
	}
	IF(newWeather.condDATE != curWeather.condDATE){
		SEND_STRING vdvControl, "'CONDITION-DATE,',newWeather.condDATE"
		SEND_COMMAND tp, "'^TXT-',ITOA(addcondDATE+addOFFSET),',0,',newWeather.condDATE"
	}
	curWeather = newWeather
}
DEFINE_FUNCTION fnRefreshPanel(INTEGER pPanel){
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addTITLE+addOFFSET),',0,',curWeather.TITLE"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addCITY+addOFFSET),',0,',curWeather.CITY"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addCOUNTRY+addOFFSET),',0,',curWeather.COUNTRY"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addREGION+addOFFSET),',0,',curWeather.REGION"
	
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addwindCHILL+addOFFSET),',0,',ITOA(curWeather.windCHILL)"
	SEND_LEVEL 	 tp[pPanel], lvlwindDEGREE+lvlOFFSET, curWeather.windDEGREE
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addwindDIR+addOFFSET),',0,',fnGetWindDir(curWeather.windDEGREE)"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addwindSPEED+addOFFSET),',0,',ITOA(curWeather.windSPEED)"
	
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addSUNRISE+addOFFSET),',0,',ITOA(curWeather.SUNRISE)"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addSUNSET+addOFFSET),',0,',ITOA(curWeather.SUNSET)"
	
	SEND_LEVEL   tp[pPanel], lvlcondCODE+lvlOFFSET, curWeather.condCODE+1
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondTEXT+addOFFSET),',0,',curWeather.condTEXT"
	IF(curWeather.condTEMP_SPLIT[1]){
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondTEMP_Split[1]+addOFFSET),',0,',ITOA(curWeather.condTEMP_SPLIT[1])"
	}
	ELSE{
		SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondTEMP_Split[1]+addOFFSET),',0,'"
	}
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondTEMP_Split[2]+addOFFSET),',0,',ITOA(curWeather.condTEMP_SPLIT[2])"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondTEMP+addOFFSET),',0,',ITOA(curWeather.condTEMP)"
	SEND_COMMAND tp[pPanel], "'^TXT-',ITOA(addcondDATE+addOFFSET),',0,',curWeather.condDATE"
}
/******************************************************************************
	Conversion Routines
******************************************************************************/
DEFINE_FUNCTION CHAR[2] fnGetWindDir(INTEGER pDEGREE){
	SELECT{
		ACTIVE(pDEGREE < 22 || pDEGREE > 337):{ RETURN 'N' }
		ACTIVE(pDEGREE < 67):{ RETURN 'NE'}
		ACTIVE(pDEGREE < 112):{RETURN 'E'}
		ACTIVE(pDEGREE < 157):{RETURN 'SE'}
		ACTIVE(pDEGREE < 202):{RETURN 'S'}
		ACTIVE(pDEGREE < 247):{RETURN 'SW'}
		ACTIVE(pDEGREE < 292):{RETURN 'W'}
		ACTIVE(pDEGREE < 337):{RETURN 'NW'}
	}
}
/******************************************************************************
	Comms Routines
******************************************************************************/
DEFINE_FUNCTION fnPollWeather(){
	fnDebug('Try Conn', 'Yahoo Weather')
	IP_CLIENT_OPEN(ipDevice.PORT,'weather.yahooapis.com',80,1)
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPollWeather()
}
DEFINE_EVENT TIMELINE_EVENT[TLID_BOOT]{
	fnPollWeather()
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

DEFINE_FUNCTION fnSendQuery(){ //Goes to an external site and gets the RSS Data		
	IF(!myCOMMS.WOEID){myCOMMS.WOEID = 44418}		// Default to London	
	IF(myCOMMS.UNITS == ''){myCOMMS.UNITS = 'c'}	// Default to London
	SEND_STRING ipDevice,"'GET /forecastrss?w=',ITOA(myCOMMS.WOEID),'&u=c',' HTTP/1.1',13,10"
	SEND_STRING ipDevice,"'Host: weather.yahooapis.com',13,10"
	SEND_STRING ipDevice,"'User-Agent: Mozilla/5.0',13,10"
	SEND_STRING ipDevice,"'CONNECTION: Keep-Alive',13,10"
	SEND_STRING ipDevice,"'Cache-Control: no-cache',13,10"
	SEND_STRING ipDevice,"13,10"
}

DEFINE_FUNCTION fnParseFeedback(CHAR pData[20000]){
	STACK_VAR CHAR cTEMP[255]
	STACK_VAR INTEGER bFLAG
	(** Get Title **)
	REMOVE_STRING(pData,'<title>',1)
	newWeather.Title = fnStripCharsRight(REMOVE_STRING(pData,'</title>',1),LENGTH_ARRAY('</title>'))
	(** Get Location Data **)
	REMOVE_STRING(pData,'<yweather:location',1)
	REMOVE_STRING(pData,'city="',1)
	newWeather.CITY = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	REMOVE_STRING(pData,'region="',1)
	newWeather.REGION = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	REMOVE_STRING(pData,'country="',1)
	newWeather.COUNTRY = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	(** Get Wind Data **)
	REMOVE_STRING(pData,'<yweather:wind',1)
	REMOVE_STRING(pData,'chill="',1)
	newWeather.windCHILL = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	REMOVE_STRING(pData,'direction="',1)
	newWeather.windDEGREE = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	REMOVE_STRING(pData,'speed="',1)
	newWeather.windSPEED = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	(** Get Atmosphere Data **)
	REMOVE_STRING(pData,'<yweather:atmosphere',1)
	REMOVE_STRING(pData,'humidity="',1)
	newWeather.atmosHUMIDITY = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	REMOVE_STRING(pData,'visibility="',1)
	newWeather.atmosVISIBILITY = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	REMOVE_STRING(pData,'pressure="',1)
	newWeather.atmosPRESSURE = ATOF(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	REMOVE_STRING(pData,'rising="',1)
	newWeather.atmosCHANGE = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	(** Get Astronomy Data **)
	REMOVE_STRING(pData,'<yweather:astronomy',1)
	REMOVE_STRING(pData,'sunrise="',1)
	newWeather.SUNRISE = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	REMOVE_STRING(pData,'sunset="',1)
	newWeather.SUNSET = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	(** Get Conditions Data **)
	REMOVE_STRING(pData,'<yweather:condition',1)
	REMOVE_STRING(pData,'text="',1)
	newWeather.condTEXT = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	REMOVE_STRING(pData,'code="',1)
	newWeather.condCODE = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	IF(newWeather.condCODE == 3200){newWeather.condCODE = 48}
	REMOVE_STRING(pData,'temp="',1)
	newWeather.condTEMP = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
	cTEMP = ITOA(newWeather.condTEMP)
	bFLAG = (LEFT_STRING(cTEMP,1) == '-')
	IF(bFLAG){ GET_BUFFER_CHAR(cTEMP) }
	IF(LENGTH_ARRAY(cTEMP) > 1){
		newWeather.condTEMP_SPLIT[1] = ATOI(GET_BUFFER_STRING(cTEMP,1))
		IF(bFLAG) {newWeather.condTEMP_SPLIT[1] = newWeather.condTEMP_SPLIT[1] * -1}
		newWeather.condTEMP_SPLIT[2] = ATOI(cTEMP)
	}
	ELSE{
		newWeather.condTEMP_SPLIT[1] = 0
		newWeather.condTEMP_SPLIT[2] = ATOI(cTEMP)
		IF(bFLAG) {newWeather.condTEMP_SPLIT[2] = newWeather.condTEMP_SPLIT[2] * -1}
	}
	REMOVE_STRING(pData,'date="',1)
	newWeather.condDATE = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
	(** get Forcast Data **)
	IF(1){
		STACK_VAR INTEGER x;
		x = 1;
		WHILE(FIND_STRING(pData,'<yweather:forecast',1)){
			REMOVE_STRING(pData,'day="',1)
			newWeather.forDAY[x] = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
			REMOVE_STRING(pData,'date="',1)
			newWeather.forDATE[x] = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
			REMOVE_STRING(pData,'low="',1)
			newWeather.forLOW[x] = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
			REMOVE_STRING(pData,'high="',1)
			newWeather.forHIGH[x] = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
			REMOVE_STRING(pData,'text="',1)
			newWeather.forTEXT[x] = fnStripCharsRight(REMOVE_STRING(pData,'"',1),1)
			REMOVE_STRING(pData,'code="',1)
			newWeather.forCODE[x] = ATOI(fnStripCharsRight(REMOVE_STRING(pData,'"',1),1))
			IF(newWeather.forCODE[x] = 3200){newWeather.forCODE[x] = 48}
			x++
		}
	}
	fnFeedbackNew()
}
/******************************************************************************
	Startup
******************************************************************************/
DEFINE_START{
	CREATE_BUFFER ipDevice,myCOMMS.cRxBuffer
}

/******************************************************************************
	Panel Events
******************************************************************************/
DEFINE_EVENT
DATA_EVENT[tp]{
	ONLINE:{
		fnRefreshPanel(GET_LAST(tp))
	}
}

/******************************************************************************
	Data Events
******************************************************************************/
DATA_EVENT[vdvControl]{
	ONLINE:{
		TIMELINE_CREATE(TLID_BOOT,TLT_BOOT,LENGTH_ARRAY(TLT_BOOT),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	}
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'LOCATION':{ myCOMMS.WOEID = ATOI(DATA.TEXT) }
					CASE 'DEBUG':{ myCOMMS.DEBUG = ATOI(DATA.TEXT) }
					CASE 'OFFSET':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'ADDRESS':addOFFSET = ATOI(DATA.TEXT)
							CASE 'LEVEL':	lvlOFFSET = ATOI(DATA.TEXT)
						}
					}
				}
			}
		}
	}
}
DATA_EVENT[ipDevice]{
	ONERROR:{
		fnDebug('Conn Fail', 'Yahoo Weather')
		myCOMMS.bConnected 	= FALSE
		myCOMMS.bTrying		= FALSE
	}
	ONLINE:{
		fnDebug('Conn Made', 'Yahoo Weather')
		myCOMMS.bConnected 	= TRUE
		myCOMMS.bTrying		= FALSE
		myCOMMS.cRxBuffer = ''
		fnSendQuery()
	}
	OFFLINE:{
		fnDebug('Conn End', 'Yahoo Weather')
		myCOMMS.bConnected 	= FALSE
		myCOMMS.bTrying		= FALSE
		IF(FIND_STRING(myCOMMS.cRxBuffer,'</channel>',1)){
			fnDebug('Feedback', 'Yahoo Weather')
			fnParseFeedback(myCOMMS.cRxBuffer)
		}
	}
}

DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	IF(myCOMMS.DEBUG = 1)	{
		SEND_STRING 0:1:0, "ITOA(vdvControl.Number),':',Msg, ':', MsgData"
	}
}
