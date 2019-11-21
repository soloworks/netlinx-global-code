MODULE_NAME='mRMSDisplayDeviceMonitor'(DEV vdvRMS, DEV vdvDevice)
DEFINE_VARIABLE
CHAR MONITOR_NAME[]         = 'Solo Works RMS DisplayDevice Monitor';
CHAR MONITOR_VERSION[]      = '4.3.25';
CHAR MONITOR_DEBUG_NAME[]   = 'mRMSDisplayDeviceMonitor';
CHAR MONITOR_ASSET_NAME[20]
#DEFINE SNAPI_MONITOR_MODULE;
#INCLUDE 'CustomFunctions'
#INCLUDE 'RmsMonitorCommon';
#INCLUDE 'SNAPI';
#INCLUDE 'RmsNlSnapiComponents';
/******************************************************************************
	RMS Monitoring Module for Display Devices (Screens & Projectors)
******************************************************************************/
/******************************************************************************
	Structures & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uAsset{
	// Meta Data
	CHAR TYPE[50]
	CHAR DESC[50]
	CHAR MAKE[50]
	CHAR MODEL[50]
	CHAR SN[20]
	CHAR FW[20]
	// State Data
	CHAR INPUT[20]
	CHAR INPUT_OPTIONS[500]
	SLONG LAMPHOURS
	SLONG LAMPLIFE
	INTEGER VOL
	INTEGER VOL_RANGE[2]
}

DEFINE_VARIABLE
VOLATILE uAsset myAsset
/******************************************************************************
	RMS Built In Functions follow
******************************************************************************/

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
  IF(MONITOR_ASSET_NAME = ''){MONITOR_ASSET_NAME = 'NoName'}
  asset.name              = MONITOR_ASSET_NAME;
  asset.assetType         = myAsset.TYPE;

  // These are optional
  asset.description       = myAsset.DESC;
  asset.manufacturerName  = myAsset.MAKE;
  asset.modelName         = myAsset.MODEL;
  asset.serialNumber      = myAsset.SN;
  asset.firmwareVersion   = myAsset.FW;

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
  //Register all snapi HAS_xyz components
  RegisterAssetParametersSnapiComponents(assetClientKey);

	// Current Input
	RmsAssetParameterEnqueueEnumeration(
		assetClientKey,
		'asset.custom.input',
		'Input',
		'Current Input',
		RMS_ASSET_PARAM_TYPE_NONE,
		myAsset.INPUT,
		myAsset.INPUT_OPTIONS,
		FALSE,
		'',
		FALSE
	)

	// Standby State
	RmsAssetParameterEnqueueBoolean(
		assetClientKey,
		'asset.custom.power',
		'Powered On',
		'Current Power Status',
		RMS_ASSET_PARAM_TYPE_NONE,
		[vdvDevice,255],
		FALSE,
		FALSE,
		FALSE
	)
	// Register lamp hours if a lamplife has been set
	IF(myAsset.LAMPLIFE){
		// register the asset parameter for display usage
		RmsAssetParameterEnqueueDecimalWithBargraph(assetClientKey,
			'display.usage',
			'Display Usage', 'Current consumption usage of the lamp or display device',
			RMS_ASSET_PARAM_TYPE_DISPLAY_USAGE,
			myAsset.LAMPHOURS,
			0,
			myAsset.LAMPLIFE,
			'Hours',
			RMS_ALLOW_RESET_YES,
			0,
			RMS_TRACK_CHANGES_YES,
			'display.usage');

		// add a default threshold for the display usage parameter
		RmsAssetParameterThresholdEnqueue(assetClientKey,
			'display.usage',
			'Display/Lamp Life',
			RMS_STATUS_TYPE_MAINTENANCE,
			RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL,
			ITOA(myAsset.LAMPLIFE));
	}
	// Register Volume if a range has been set
	IF(myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){
		// Mute State
		RmsAssetParameterEnqueueBoolean(
			assetClientKey,
			'asset.custom.mute',
			'Audio Muted',
			'Current Mute Status',
			RMS_ASSET_PARAM_TYPE_NONE,
			[vdvDevice,199],
			FALSE,
			FALSE,
			FALSE
		)
		// Volume
		RmsAssetParameterEnqueueLevel(
			assetClientKey,
			'asset.custom.volume',
			'Volume',
			'Volume Level',
			RMS_ASSET_PARAM_TYPE_NONE,
			myAsset.VOL,
			myAsset.VOL_RANGE[1],
			myAsset.VOL_RANGE[2],
			'',
			FALSE,
			0,
			FALSE,
			RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL
		)
	}
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

  //Synchronize all snapi HAS_xyz components
   SynchronizeAssetParametersSnapiComponents(assetClientKey)
	// Power State
	RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'asset.custom.power',[vdvDevice,255])
	// Input State
	RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.custom.input'",  myAsset.INPUT)

	IF(myAsset.LAMPLIFE){
		RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'display.usage'",  myAsset.LAMPHOURS)
	}

	IF(myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){
		// Mute State
		RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'asset.custom.mute',[vdvDevice,199]);
		// Volume State
		RmsAssetParameterEnqueueSetValueLevel(assetClientKey,'asset.custom.volume',myAsset.VOL);
	}

	RmsAssetParameterUpdatesSubmit (assetClientKey)
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
  //RegisterAssetControlMethodsSnapiComponents(assetClientKey);

	// Power Control
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.power', 'Power State', 'Set Power State');
  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.power', 0,
																		 'State', 'Select the Power state',
																		 '',
																		 'On|Off');
	// Input Select (From Device Module Meta Feedback)
  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.input', 'Screen Input Status', 'Set Input');
  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.input', 0,
																		 'State', 'Select Input',
																		 '',
																		 myAsset.INPUT_OPTIONS);
	IF(myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){
		// Volume Control
	  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.volume', 'Volume', 'Set Volume');
	  RmsAssetControlMethodArgumentLevel  (assetClientKey,  'asset.customaction.volume', 0,
																			 'Volume', 'Set Volume',
																			 30,myAsset.VOL_RANGE[1],myAsset.VOL_RANGE[2],5);

		// Mute Control
	  RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.customaction.mute', 'Mute Status', 'Set Mute');
	  RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.customaction.mute', 0,
																			 'State', 'Set',
																			 '',
																			 'Mute|UnMute');
	}
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
DEFINE_FUNCTION ExecuteAssetControlMethod(CHAR methodKey[], CHAR arguments[]){
	STACK_VAR CHAR cValue1[RMS_MAX_PARAM_LEN]
	cValue1 = RmsParseCmdParam(arguments)

	SWITCH(methodKey){
		CASE 'asset.customaction.power' :{
			SWITCH(cValue1){
				CASE 'On'  :{ SEND_COMMAND vdvDevice, 'POWER-ON' }
				CASE 'Off' :{ SEND_COMMAND vdvDevice, 'POWER-OFF' }
			}
		}
		CASE 'asset.customaction.input' :{
			SEND_COMMAND vdvDevice, "'INPUT-',DATA.TEXT"
		}
		CASE 'asset.customaction.volume' :{
			SEND_COMMAND vdvDevice,"'VOLUME-',cValue1"
		}
		CASE 'asset.customaction.mute' :{
			SWITCH(cValue1){
				CASE 'Mute'  :{  SEND_COMMAND vdvDevice, 'MUTE-ON' }
				CASE 'UnMute' :{ SEND_COMMAND vdvDevice, 'MUTE-OFF' }
			}
		}
		DEFAULT :{
		}
	}
}
/******************************************************************************
	Unused Callback Functions
******************************************************************************/
DEFINE_FUNCTION ResetAssetParameterValue(CHAR parameterKey[],CHAR parameterValue[]){}
DEFINE_FUNCTION SystemPowerChanged(CHAR powerOn){}
DEFINE_FUNCTION SystemModeChanged(CHAR modeName[]){}
/******************************************************************************
	Virtual Device Events - Channels
******************************************************************************/
// Power Feedback
DEFINE_EVENT CHANNEL_EVENT[vdvDevice,255]{
	ON:{ IF(IsRmsReady()){ RmsAssetParameterSetValueBoolean(assetClientKey,'asset.custom.power',TRUE); } }
	OFF:{IF(IsRmsReady()){ RmsAssetParameterSetValueBoolean(assetClientKey,'asset.custom.power',FALSE); } }
}
// Mute State Feedback
DEFINE_EVENT CHANNEL_EVENT[vdvDevice,199]{
	ON:{ IF(IsRmsReady() && myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){ RmsAssetParameterSetValueBoolean(assetClientKey,'asset.custom.mute',TRUE); } }
	OFF:{IF(IsRmsReady() && myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){ RmsAssetParameterSetValueBoolean(assetClientKey,'asset.custom.mute',FALSE); } }
}
/******************************************************************************
	Virtual Device Events - Levels
******************************************************************************/
// Volume Feedback
DEFINE_EVENT LEVEL_EVENT[vdvDevice,1]{
	IF(myAsset.VOL_RANGE[1] != myAsset.VOL_RANGE[2]){
		myAsset.VOL = LEVEL.VALUE
		IF(IsRmsReady()){ RmsAssetParameterSetValueLevel(assetClientKey,'asset.custom.volume',myAsset.VOL) }
	}
}
/******************************************************************************
	Virtual Device Events - Data
******************************************************************************/
DATA_EVENT[vdvDevice]{
  STRING:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'META':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'TYPE': { 	 myAsset.TYPE			= DATA.TEXT }
							CASE 'DESC': { 	 myAsset.DESC			= DATA.TEXT }
							CASE 'MAKE': { 	 myAsset.MAKE 			= DATA.TEXT }
							CASE 'MODEL':{ 	 myAsset.MODEL 		= DATA.TEXT }
							CASE 'SERIALNO':{  myAsset.SN 			= DATA.TEXT }
							CASE 'FIRMWARE':{  myAsset.FW 			= DATA.TEXT }
							CASE 'LAMPLIFE':{  myAsset.LAMPLIFE 	= ATOI(DATA.TEXT) }
							CASE 'NAME': { 	 MONITOR_ASSET_NAME 	= DATA.TEXT }
							CASE 'INPUTS': { 	 myAsset.INPUT_OPTIONS 	= DATA.TEXT }
						}
					}
				}
			}
			CASE 'LAMPHOURS':{
				myAsset.LAMPHOURS = ATOI(DATA.TEXT)
				IF(IsRmsReady()){ RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'display.usage'",  myAsset.LAMPHOURS) }
			}
			CASE 'INPUT':{
				myAsset.INPUT = DATA.TEXT
				IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,'asset.custom.input',myAsset.INPUT); }
			}
			CASE 'RANGE':{
				myAsset.VOL_RANGE[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
				myAsset.VOL_RANGE[2] = ATOI(DATA.TEXT)
			}
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/
