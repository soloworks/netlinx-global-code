MODULE_NAME='RmsSoundStructureMonitor'(DEV vdvRMS,
                                           DEV vdvDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	RMS Monitoring of VC Systems for Solo Control Modules
******************************************************************************/

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
// This compiler directive is provided as a clue so that other include
// files can provide SNAPI specific behavior if needed.
#DEFINE SNAPI_MONITOR_MODULE;

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
// RMS Asset Properties (Recommended)
CHAR MONITOR_ASSET_NAME[50]             = 'Sound Processor';

CHAR MONITOR_META_SYS_NAME[50]             = '';
CHAR MONITOR_META_SYS_SW_VER[8][20]        = '';
CHAR MONITOR_META_DEV_TYPE[8][20]          = '';
CHAR MONITOR_META_DEV_HW_REV[8][20]        = '';
CHAR MONITOR_META_DEV_FIRMWARE_REV[8][20]  = '';
CHAR MONITOR_META_DEV_BOOTLOADER_VER[8][20]= '';

SLONG MONITOR_PROP_DEV_TEMP1[8]
SLONG MONITOR_PROP_DEV_TEMP2[8]
SLONG MONITOR_PROP_DEV_TEMP3[8]
CHAR MONITOR_PROP_DEV_UPTIME[8][20]        = '';
CHAR MONITOR_PROP_DEV_STATUS[8][20]      	 = '';
CHAR MONITOR_PROP_DEV_IP[8][40] 		 = '';

// RMS Asset Properties (Optional)
CHAR MONITOR_ASSET_DESCRIPTION[50]      = '';
CHAR MONITOR_ASSET_MANUFACTURERNAME[50] = 'Polycom';
CHAR MONITOR_ASSET_MODELNAME[50]        = 'SoundStructure';
CHAR MONITOR_ASSET_MANUFACTURERURL[50]  = '';
CHAR MONITOR_ASSET_MODELURL[50]         = '';
CHAR MONITOR_ASSET_SERIALNUMBER[50]     = '';
CHAR MONITOR_ASSET_FIRMWAREVERSION[50]  = '';


// This module's version information (for logging)
CHAR MONITOR_NAME[]       = 'Solo Control SoundStructure Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'SC_RMS_SoundStructure_Monitor';
CHAR MONITOR_VERSION[]    = '4.3.25';

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
  asset.assetType         = RMS_ASSET_TYPE_AUDIO_PROCESSOR;

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
  
	FOR(x = 1; X <= 8; x++){
		IF(LENGTH_ARRAY(MONITOR_META_DEV_TYPE[x])){
			STACK_VAR INTEGER y
			// Temp 1
			RmsAssetParameterEnqueueNumberWithBargraph(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_temp1'",
				"'Dev ',ITOA(x),': Temp Sensor 1'",
				'Temperature at Rear Right',
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
		   RmsAssetParameterThresholdEnqueue(	
			assetClientKey,
			"'asset.custom.dev',ITOA(x),'.dev_temp1'",
			"'Dev ',ITOA(x),': Temp Warning'",
			RMS_STATUS_TYPE_MAINTENANCE,
			RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN,
			'59'
		   )
			// Temp 2
			RmsAssetParameterEnqueueNumberWithBargraph(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_temp2'",
				"'Dev ',ITOA(x),': Temp Sensor 2'",
				'Temperature at Mid',
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
		   RmsAssetParameterThresholdEnqueue(	
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_temp2'",
				"'Dev ',ITOA(x),': Temp Warning'",
				RMS_STATUS_TYPE_MAINTENANCE,
				RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN,
				'79'
		   )
			// Temp 3
			RmsAssetParameterEnqueueNumberWithBargraph(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_temp3'",
				"'Dev ',ITOA(x),': Temp Sensor 3'",
				'Temperature at Front',
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
		   RmsAssetParameterThresholdEnqueue(	
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_temp3'",
				"'Dev ',ITOA(x),': Temp Warning'",
				RMS_STATUS_TYPE_MAINTENANCE,
				RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN,
				'58'
		   )
			// Status Warning
			RmsAssetParameterEnqueueString(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_status'",
				"'Dev ',ITOA(x),': Status'",
				'Current Status Message',
				RMS_ASSET_PARAM_TYPE_NONE,
				MONITOR_PROP_DEV_STATUS[x],
				'',
				FALSE,
				'',
				TRUE
			)
		   RmsAssetParameterThresholdEnqueue(	
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_status'",
				"'Dev ',ITOA(x),': Status Error'",
				RMS_STATUS_TYPE_ROOM_COMMUNICATION_ERROR,
				RMS_ASSET_PARAM_THRESHOLD_COMPARISON_NOT_EQUAL,
				'ok'
		   )
			// Uptime Detail
			RmsAssetParameterEnqueueString(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.dev_uptime'",
				"'Dev ',ITOA(x),': Uptime'",
				'Device Uptime',
				RMS_ASSET_PARAM_TYPE_NONE,
				MONITOR_PROP_DEV_UPTIME[x],
				'',
				FALSE,
				'',
				FALSE
			)
			// Uptime Detail
			RmsAssetParameterEnqueueString(
				assetClientKey,
				"'asset.custom.dev',ITOA(x),'.ip'",
				"'Dev ',ITOA(x),': IP Address'",
				'IPAddress',
				RMS_ASSET_PARAM_TYPE_NONE,
				MONITOR_PROP_DEV_IP[x],
				'',
				FALSE,
				'',
				FALSE
			)
		}
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
	STACK_VAR INTEGER x
  //Synchronize all snapi HAS_xyz components
   SynchronizeAssetParametersSnapiComponents(assetClientKey)
	FOR(x = 1; x <= 8; x++){
		IF(LENGTH_ARRAY(MONITOR_META_DEV_TYPE[x])){
			RmsAssetParameterEnqueueSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp1'", MONITOR_PROP_DEV_TEMP1[x])
			RmsAssetParameterEnqueueSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp2'", MONITOR_PROP_DEV_TEMP2[x])
			RmsAssetParameterEnqueueSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp3'", MONITOR_PROP_DEV_TEMP3[x])
			RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_status'", MONITOR_PROP_DEV_STATUS[x])
			RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_uptime'", MONITOR_PROP_DEV_UPTIME[x])
			RmsAssetParameterEnqueueSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.ip'", MONITOR_PROP_DEV_IP[x])
		}
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
	STACK_VAR INTEGER x
	RmsAssetMetadataEnqueueString(assetClientKey,'meta.custom.sys_name','System Name',MONITOR_META_SYS_NAME)
	FOR(x = 1; x <= 8; x++){
		IF(LENGTH_ARRAY(MONITOR_META_DEV_TYPE[x])){
			RmsAssetMetadataEnqueueString(assetClientKey,"'meta.custom.sys_sw_ver',ITOA(x)","'Dev ',ITOA(x),': Software Version'",MONITOR_META_SYS_SW_VER[x])
			RmsAssetMetadataEnqueueString(assetClientKey,"'meta.custom.dev_type',ITOA(x)","'Dev ',ITOA(x),': Device Type'",		 MONITOR_META_DEV_TYPE[x])
			RmsAssetMetadataEnqueueString(assetClientKey,"'meta.custom.dev_hw_rev',ITOA(x)","'Dev ',ITOA(x),': Hardware Rev'",	 MONITOR_META_DEV_HW_REV[x])
			RmsAssetMetadataEnqueueString(assetClientKey,"'meta.custom.dev_firmware_rev',ITOA(x)","'Dev ',ITOA(x),': Firmware Rev'",	 MONITOR_META_DEV_FIRMWARE_REV[x])
			RmsAssetMetadataEnqueueString(assetClientKey,"'meta.custom.dev_bootloader_ver',ITOA(x)","'Dev ',ITOA(x),': Bootloader Ver'",	 MONITOR_META_DEV_BOOTLOADER_VER[x])
		}
	}
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
		CASE 'asset.customaction.power' :{
			SWITCH(cValue1){
				CASE 'On'  :{ SEND_COMMAND vdvDevice, 'POWER-ON' }
				CASE 'Off' :{ SEND_COMMAND vdvDevice, 'POWER-OFF' }
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

DATA_EVENT[vdvDevice]{
  ONLINE:
  {
    SEND_COMMAND vdvDevice, "'PROPERTY-RMS-Type,Asset'"
  }
  COMMAND:{
	
  }
  STRING:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'SYS_NAME': { 	 	MONITOR_META_SYS_NAME			= DATA.TEXT }
					CASE 'SW_VER': { 	 		MONITOR_META_SYS_SW_VER[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT }
					CASE 'DEV_TYPE': { 	 	MONITOR_META_DEV_TYPE[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT }
					CASE 'DEV_HW_REV': { 	MONITOR_META_DEV_HW_REV[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT }
					CASE 'DEV_FIRMWARE_REV': { 	 MONITOR_META_DEV_FIRMWARE_REV[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT }
					CASE 'DEV_BOOTLOADER_VER': { 	 MONITOR_META_DEV_BOOTLOADER_VER[ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))] = DATA.TEXT }
					CASE 'DEV_TEMP1': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_TEMP1[x] = ATOI(DATA.TEXT)
						IF(IsRmsReady()){ RmsAssetParameterSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp1'",MONITOR_PROP_DEV_TEMP1[x]); }
					}
					CASE 'DEV_TEMP2': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_TEMP2[x] = ATOI(DATA.TEXT)
						IF(IsRmsReady()){ RmsAssetParameterSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp2'",MONITOR_PROP_DEV_TEMP2[x]); }
					}
					CASE 'DEV_TEMP3': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_TEMP3[x] = ATOI(DATA.TEXT)
						IF(IsRmsReady()){ RmsAssetParameterSetValueNumber(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_temp3'",MONITOR_PROP_DEV_TEMP3[x]); }
					}
					CASE 'DEV_UPTIME': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_UPTIME[x] = DATA.TEXT 
						IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_uptime'",DATA.TEXT); }
					}
					CASE 'DEV_STATUS': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_STATUS[x] = DATA.TEXT 
						IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.dev_status'",DATA.TEXT); }
					}
					CASE 'DEV_IP': { 	
						STACK_VAR INTEGER x
						x = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						MONITOR_PROP_DEV_IP[x] = DATA.TEXT 
						IF(IsRmsReady()){ RmsAssetParameterSetValue(assetClientKey,"'asset.custom.dev',ITOA(x),'.ip'",DATA.TEXT); }
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
