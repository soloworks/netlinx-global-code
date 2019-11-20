/******************************************************************************
	RMS Monitoring of VC Systems for Solo Control Modules
******************************************************************************/
MODULE_NAME='RmsVCMonitor'(DEV vdvRMS,
									DEV vdvCalls[],
                           DEV vdvDevice)
INCLUDE 'CustomFunctions'
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
// This compiler directive is provided as a clue so that other include
// files can provide SNAPI specific behavior if needed.
#DEFINE SNAPI_MONITOR_MODULE;

//#DEFINE HAS_POWER
(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

// RMS Asset Properties (Recommended)
CHAR MONITOR_ASSET_NAME[]             = 'Video Conference Unit';

// RMS Asset Properties (Optional)
CHAR MONITOR_ASSET_DESCRIPTION[50]      = '';
CHAR MONITOR_ASSET_MANUFACTURERNAME[50] = '';
CHAR MONITOR_ASSET_MODELNAME[50]        = '';
CHAR MONITOR_ASSET_MANUFACTURERURL[50]  = '';
CHAR MONITOR_ASSET_MODELURL[50]         = '';
CHAR MONITOR_ASSET_SERIALNUMBER[50]     = '';
CHAR MONITOR_ASSET_FIRMWAREVERSION[50]  = '';

CHAR MONITOR_ASSET_UPTIME[50]  = '';
SLONG MONITOR_PROP_TEMP
CHAR MONITOR_ASSET_IP_ADDRESS[50] = ''
INTEGER MONITOR_ASSET_VOLUME

// This module's version information (for logging)
CHAR MONITOR_NAME[]       = 'Solo Control VC Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'SC_RMS_VC_Monitor';
CHAR MONITOR_VERSION[]    = '4.3.25';

CHAR MONITOR_VIDCALL_NAME[5][50]
CHAR MONITOR_VIDCALL_NUMBER[5][50]
CHAR MONITOR_VIDCALL_SPEED[5][50]
CHAR MONITOR_VIDCALL_STATUS[5][50]

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

(***********************************************************)
(*               INCLUDE DEFINITIONS GO BELOW              *)
(***********************************************************)

// include RMS MONITOR COMMON AXI
#INCLUDE 'RmsMonitorCommon';

// include SNAPI
#INCLUDE 'SNAPI';

#INCLUDE 'RmsNlSnapiComponents';


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  RegisterAsset                                    *)
(* Args:  RmsAsset asset data object to be registered .    *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset.                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAsset(RmsAsset asset)
{
  // Client key must be unique for this master (recommended to leave it as DPS)
  asset.clientKey         = RmsDevToString(vdvDevice);

  // These are recommended
  asset.name              = MONITOR_ASSET_NAME;
  asset.assetType         = RMS_ASSET_TYPE_VIDEO_CONFERENCER;

  // These are optional
  asset.description       = MONITOR_ASSET_DESCRIPTION;
  asset.manufacturerName  = MONITOR_ASSET_MANUFACTURERNAME;
  asset.modelName         = MONITOR_ASSET_MODELNAME;
  asset.manufacturerUrl   = MONITOR_ASSET_MANUFACTURERURL;
  asset.modelUrl          = MONITOR_ASSET_MODELURL;
  asset.serialNumber      = MONITOR_ASSET_SERIALNUMBER;
  asset.firmwareVersion   = MONITOR_ASSET_FIRMWAREVERSION;

  // perform registration of this asset
  RmsAssetRegister(vdvDevice, asset);
}


(***********************************************************)
(* Name:  RegisterAssetParameters                          *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's parameters to be monitored *)
(*        by RMS.                                          *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetParameters()
{
	STACK_VAR INTEGER x
   //Register all snapi HAS_xyz components
   RegisterAssetParametersSnapiComponents(assetClientKey);

	// Mic State
	RmsAssetParameterEnqueueEnumeration(
		assetClientKey,
		'asset.micstatus',
		'Microphone',
		'Near End Microphone Status',
		RMS_ASSET_PARAM_TYPE_NONE,
		'Muted',
		'Muted|Live',
		FALSE,
		'',
		FALSE
	)
	// Volume State
	RmsAssetParameterEnqueueLevel(
		assetClientKey,
		'asset.volume',
		'Volume',
		'Near End Volume Status',
		RMS_ASSET_PARAM_TYPE_NONE,
		MONITOR_ASSET_VOLUME,
		0,
		50,
		'',
		FALSE,
		0,
		FALSE,
		RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL
	)
	// Standby State
	RmsAssetParameterEnqueueEnumeration(
		assetClientKey,
		'asset.standby',
		'Power State',
		'Current System Status',
		RMS_ASSET_PARAM_TYPE_NONE,
		'Sleeping',
		'Awake|Sleeping',
		FALSE,
		'',
		FALSE
	)
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		// Active Video Call
		RmsAssetParameterEnqueueBoolean(
			assetClientKey,
			"'asset.call',ITOA(x),'.active'",
			"'Call - Video',ITOA(x),': Active'",
			"'True if Video Call is active'",
			RMS_ASSET_PARAM_TYPE_NONE,
			[vdvCalls[x],238],
			FALSE,
			FALSE,
			FALSE
		)
		// End Point Name
		RmsAssetParameterEnqueueString(
			assetClientKey,
			"'asset.call',ITOA(x),'.name'",
			"'Call - Video',ITOA(x),': Name'",
			"'Endpoint Name'",
			RMS_ASSET_PARAM_TYPE_NONE,
			MONITOR_VIDCALL_NAME[x],
			'',
			FALSE,
			'',
			TRUE
		)
		// End Point Number
		RmsAssetParameterEnqueueString(
			assetClientKey,
			"'asset.call',ITOA(x),'.number'",
			"'Call - Video',ITOA(x),': Number'",
			"'Endpoint Number'",
			RMS_ASSET_PARAM_TYPE_NONE,
			MONITOR_VIDCALL_NUMBER[x],
			'',
			FALSE,
			'',
			TRUE
		)
		// End Point Speed
		RmsAssetParameterEnqueueString(
			assetClientKey,
			"'asset.call',ITOA(x),'.speed'",
			"'Call - Video',ITOA(x),': Speed'",
			"'Current Call Speed'",
			RMS_ASSET_PARAM_TYPE_NONE,
			MONITOR_VIDCALL_SPEED[x],
			'',
			FALSE,
			'',
			TRUE
		)
		// End Point Number
		RmsAssetParameterEnqueueString(
			assetClientKey,
			"'asset.call',ITOA(x),'.status'",
			"'Call - Video',ITOA(x),': Status'",
			"'Current Call Status'",
			RMS_ASSET_PARAM_TYPE_NONE,
			MONITOR_VIDCALL_STATUS[x],
			'',
			FALSE,
			'',
			TRUE
		)
	}
	// IP Address
	RmsAssetParameterEnqueueString(
		assetClientKey,
		'asset.network.ip',
		'IP Address',
		'Current IP Address',
		RMS_ASSET_PARAM_TYPE_NONE,
		MONITOR_ASSET_IP_ADDRESS,
		'',
		FALSE,
		'',
		TRUE
	)

  RmsAssetParameterThresholdEnqueue(
	assetClientKey,
	'asset.network.ip',
	'IP Error',
	RMS_STATUS_TYPE_ROOM_COMMUNICATION_ERROR,
	RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL,
	'0.0.0.0'
  )

	// Uptime
	RmsAssetParameterEnqueueString(
		assetClientKey,
		'asset.uptime',
		'Uptime',
		'System Uptime',
		RMS_ASSET_PARAM_TYPE_NONE,
		MONITOR_ASSET_UPTIME,
		'',
		FALSE,
		'',
		FALSE
	)
  // Temperature
	RmsAssetParameterEnqueueNumberWithBargraph(
		assetClientKey,
		"'asset.temp'",
		"'Temperature'",
		'Temperature',
		RMS_ASSET_PARAM_TYPE_TEMPERATURE,
		0,
		-40,
		125,
		"176,'C'",
		FALSE,
		0,
		FALSE,
		RMS_ASSET_PARAM_BARGRAPH_TEMPERATURE
	)


  // submit all parameter registrations
  RmsAssetParameterSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  SynchronizeAssetParameters                       *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset parameter values   *)
(*        with RMS.                                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetParameters()
{
  // This callback method is invoked when either the RMS server connection
  // has been offline or this monitored device has been offline from some
  // amount of time.   Since the monitored parameter state values could
  // be out of sync with the RMS server, we must perform asset parameter
  // value updates for all monitored parameters so they will be in sync.
  // Update only asset monitoring parameters that may have changed in value.
	STACK_VAR INTEGER x;
  //Synchronize all snapi HAS_xyz components
    SynchronizeAssetParametersSnapiComponents(assetClientKey)
	// Standby State
	IF([vdvDevice,255]){
		RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.standby','Awake');
	}
	ELSE{
		RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.standby','Sleeping');
	}
	// Microphone State
	IF([vdvDevice,199]){
		RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.micstate','Muted');
	}
	ELSE{
		RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.micstate','Live');
	}
	// Uptime
	RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.uptime',MONITOR_ASSET_UPTIME);
	// IP Address
	RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.network.ip',MONITOR_ASSET_IP_ADDRESS);
	// Temperature State
	RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'asset.temp',MONITOR_PROP_TEMP);
	// Volume State
	RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'asset.volume',MONITOR_ASSET_VOLUME);
	// Video Call Status
	FOR(x = 1; x <= LENGTH_ARRAY(vdvCalls); x++){
		// Video Call State
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'asset.call',ITOA(x),'.active'",[vdvCalls[x],238]);
		RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.call',ITOA(x),'.name'",  MONITOR_VIDCALL_NAME[x])
		RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.call',ITOA(x),'.number'",MONITOR_VIDCALL_NUMBER[x])
		RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.call',ITOA(x),'.speed'", MONITOR_VIDCALL_SPEED[x])
		RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.call',ITOA(x),'.status'",MONITOR_VIDCALL_STATUS[x])
	}
	RmsAssetParameterUpdatesSubmit (assetClientKey)
}


(***********************************************************)
(* Name:  ResetAssetParameterValue                         *)
(* Args:  parameterKey   - unique parameter key identifier *)
(*        parameterValue - new parameter value after reset *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that an asset          *)
(*        parameter value has been reset by the RMS server *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION ResetAssetParameterValue(CHAR parameterKey[],CHAR parameterValue[])
{
  // if your monitoring module performs any parameter
  // value tracking, then you may want to update the
  // tracking value based on the new reset value
  // received from the RMS server.
}


(***********************************************************)
(* Name:  RegisterAssetMetadata                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's metadata properties with   *)
(*        RMS.                                             *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetMetadata()
{

  //Register all snapi HAS_xyz components
  RegisterAssetMetadataSnapiComponents(assetClientKey);

  RmsAssetMetadataSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  SynchronizeAssetMetadata                         *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        update/synchronize this asset metadata properties *)
(*        with RMS if needed.                              *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetMetadata()
{
  //Register all snapi HAS_xyz components
  IF(SynchronizeAssetMetadataSnapiComponents(assetClientKey))
    RmsAssetMetadataSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  RegisterAssetControlMethods                      *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it is time to     *)
(*        register this asset's control methods with RMS.  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetControlMethods()
{
  //Register all snapi HAS_xyz components
  RegisterAssetControlMethodsSnapiComponents(assetClientKey);
	// Volume Control
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.volume', 'Volume', 'Set Volume');
  RmsAssetControlMethodArgumentLevel  (assetClientKey,  'asset.customaction.volume', 0,
																		 'Volume', 'Set Volume',
																		 50,0,50,1);
	// Hangup Control
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.system', 'System Actions', 'General System Actions');
  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.system', 0,
																		 'Action', 'Choose Action',
																		 '',
																		 'Hangup All|Reboot|Reload Directory');
	// Power Control
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.standby', 'System Status', 'Wake or Sleep unit');
  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.standby', 0,
																		 'State', 'Select the state to apply',
																		 '',
																		 'Sleep|Wake');
	// Mic Control
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.micstate', 'Microphone Status', 'Change Microphone Status');
  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.micstate', 0,
																		 'State', 'Set State',
																		 '',
																		 'Muted|Live');
  // when done enqueuing all asset control methods and
  // arguments for this asset, we just need to submit
  // them to finalize and register them with the RMS server
  RmsAssetControlMethodsSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  ExecuteAssetControlMethod                        *)
(* Args:  methodKey - unique method key that was executed  *)
(*        arguments - array of argument values invoked     *)
(*                    with the execution of this method.   *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that it should         *)
(*        fullfill the execution of one of this asset's    *)
(*        control methods.                                 *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION ExecuteAssetControlMethod(CHAR methodKey[], CHAR arguments[])
STACK_VAR
  CHAR cValue1[RMS_MAX_PARAM_LEN]
  INTEGER nValue1
{
  DEBUG("'<<< EXECUTE CONTROL METHOD : [',methodKey,'] args=',arguments,' >>>'");

  cValue1 = RmsParseCmdParam(arguments)
  nValue1 = ATOI(cValue1)

	SWITCH(methodKey){
		CASE 'asset.customaction.system' :{
			SWITCH(cValue1){
				CASE 'Hangup All'  :{ 		 SEND_COMMAND vdvDevice,'HANGUP-ALL' }
				CASE 'Reboot'  :{				 SEND_COMMAND vdvDevice,'ACTION-REBOOT' }
				CASE 'Reload Directory'  :{ SEND_COMMAND vdvDevice,'DIRECTORY-INIT' }
			}
		}
		CASE 'asset.customaction.volume' :{
			SEND_COMMAND vdvDevice,"'VOLUME-',cValue1"
		}
		CASE 'asset.customaction.standby' :{
			SWITCH(cValue1){
				CASE 'Wake'  :{ SEND_COMMAND vdvDevice,'ACTION-WAKE' }
				CASE 'Sleep' :{ SEND_COMMAND vdvDevice,'ACTION-SLEEP' }
			}
		}
		CASE 'asset.customaction.micstate' :{
			SWITCH(cValue1){
				CASE 'Muted'  :{ SEND_COMMAND vdvDevice,'MICMUTE-ON' }
				CASE 'Live' :{   SEND_COMMAND vdvDevice,'MICMUTE-OFF' }
			}
		}
		DEFAULT :{
		}
	}
}

(***********************************************************)
(* Name:  SystemPowerChanged                               *)
(* Args:  powerOn - boolean value representing ON/OFF      *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM POWER  *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemPowerChanged(CHAR powerOn)
{
  // optionally implement logic based on
  // system power state.
}


(***********************************************************)
(* Name:  SystemModeChanged                                *)
(* Args:  modeName - string value representing mode change *)
(*                                                         *)
(* Desc:  This is a callback method that is invoked by     *)
(*        RMS to notify this module that the SYSTEM MODE   *)
(*        state has changed states.                        *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SystemModeChanged(CHAR modeName[])
{
  // optionally implement logic based on
  // newly selected system mode name.
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START


(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
// Standby Feedback
DEFINE_EVENT CHANNEL_EVENT[vdvDevice,255]{
	ON:{ IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,'asset.standby','Awake'); } }
	OFF:{IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,'asset.standby','Sleeping'); } }
}
// Mic State Feedback
DEFINE_EVENT CHANNEL_EVENT[vdvDevice,199]{
	ON:{ IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,'asset.micstatus','Muted'); } }
	OFF:{IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,'asset.micstatus','Live'); } }
}
// Volume Feedback
DEFINE_EVENT LEVEL_EVENT[vdvDevice,1]{
	MONITOR_ASSET_VOLUME = LEVEL.VALUE
	IF(IsRmsReady()){ RmsAssetParameterSetValueLevel(assetClientKey,'asset.volume',MONITOR_ASSET_VOLUME) }
}
// Video Call Feedback
DEFINE_EVENT CHANNEL_EVENT[vdvCalls,238]{
	ON:{ IF(IsRmsReady()){ RmsAssetParameterSetValueBoolean(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.active'",TRUE); } }
	OFF:{IF(IsRmsReady()){ RmsAssetParameterSetValueBoolean(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.active'",FALSE); } }
}
DEFINE_EVENT DATA_EVENT[vdvCalls]{
	STRING:{
		IF(IsRmsReady()){
			SWITCH(REMOVE_STRING(DATA.TEXT,'-',1)){
				CASE 'NAME-':{
					MONITOR_VIDCALL_NAME[GET_LAST(vdvCalls)] 	= DATA.TEXT
					RmsAssetParameterSetValue(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.name'",  MONITOR_VIDCALL_NAME[GET_LAST(vdvCalls)])
				}
				CASE 'NUMBER-':{
					MONITOR_VIDCALL_NUMBER[GET_LAST(vdvCalls)] = DATA.TEXT
					RmsAssetParameterSetValue(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.number'",MONITOR_VIDCALL_NUMBER[GET_LAST(vdvCalls)])
				}
				CASE 'SPEED-':{
					MONITOR_VIDCALL_SPEED[GET_LAST(vdvCalls)] 	= DATA.TEXT
					RmsAssetParameterSetValue(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.speed'", MONITOR_VIDCALL_SPEED[GET_LAST(vdvCalls)])
				}
				CASE 'STATUS-':{
					MONITOR_VIDCALL_STATUS[GET_LAST(vdvCalls)] = DATA.TEXT
					RmsAssetParameterSetValue(assetClientKey,"'asset.call',ITOA(GET_LAST(vdvCalls)),'.status'",MONITOR_VIDCALL_STATUS[GET_LAST(vdvCalls)])
				}
			}
		}
	}
}
//
// (VIRTUAL DEVICE EVENT HANDLERS)
//
DATA_EVENT[vdvDevice]
{
  ONLINE:
  {
    SEND_COMMAND vdvDevice, "'PROPERTY-RMS-Type,Asset'"
  }
  STRING:{
		SWITCH(REMOVE_STRING(DATA.TEXT,'-',1)){
			CASE 'PROPERTY-':{
				SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
					CASE 'META,':{
						SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
							CASE 'DESC,': { 	 MONITOR_ASSET_DESCRIPTION 		= DATA.TEXT }
							CASE 'MAKE,': { 	 MONITOR_ASSET_MANUFACTURERNAME 	= DATA.TEXT }
							CASE 'MODEL,':{ 	 MONITOR_ASSET_MODELNAME 			= DATA.TEXT }
							CASE 'SN,':{ 		 MONITOR_ASSET_SERIALNUMBER 		= DATA.TEXT }
							CASE 'SOFTWARE,':{ MONITOR_ASSET_FIRMWAREVERSION 	= DATA.TEXT }
						}
					}
					CASE 'STATE,':{
						SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
							CASE 'NET_IP,':{
								MONITOR_ASSET_IP_ADDRESS = DATA.TEXT
								IF(IsRmsReady()){
									RmsAssetParameterSetValue( assetClientKey, 'asset.ip', MONITOR_ASSET_IP_ADDRESS)
								}
							}
							CASE 'TEMP,':{
								MONITOR_PROP_TEMP = ATOI(DATA.TEXT)
								IF(IsRmsReady()){
									RmsAssetParameterSetValueLevel( assetClientKey, 'asset.temp', MONITOR_PROP_TEMP)
								}
							}
							CASE 'UPTIME,':{
								MONITOR_ASSET_UPTIME = fnSecondsToDurationText(ATOI(DATA.TEXT),TRUE)
								IF(IsRmsReady()){
									RmsAssetParameterSetValue( assetClientKey, 'asset.uptime', MONITOR_ASSET_UPTIME)
								}
							}
						}
					}
				}
			}
		}
	}
}


(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
