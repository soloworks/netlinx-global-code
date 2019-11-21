MODULE_NAME='RmsGenericDeviceMonitor'(DEV vdvRMS,
                                           DEV vdvDevice)

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
CHAR MONITOR_ASSET_NAME[50]             = 'Unknown';


// RMS Asset Properties (Optional)
CHAR MONITOR_ASSET_DESCRIPTION[50]      = '';
CHAR MONITOR_ASSET_MANUFACTURERNAME[50] = '';
CHAR MONITOR_ASSET_MODELNAME[50]        = '';
CHAR MONITOR_ASSET_MANUFACTURERURL[50]  = '';
CHAR MONITOR_ASSET_MODELURL[50]         = '';
CHAR MONITOR_ASSET_SERIALNUMBER[50]     = '';
CHAR MONITOR_ASSET_FIRMWAREVERSION[50]  = '';
CHAR MONITOR_ASSET_FIRMWAREVERSION_S[50]= '';
CHAR MONITOR_ASSET_MAC_ADDRESS[50] 		 = '';
CHAR MONITOR_ASSET_PART_NUMBER[50] 		 = '';
CHAR MONITOR_ASSET_IP_ADDRESS[50] 		 = '';

SLONG MONITOR_PROP_TEMP

CHAR MONITOR_ASSET_INPUT[50]  = '';

// This module's version information (for logging)
CHAR MONITOR_NAME[]       = 'Solo Control Generic Device Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'SC_RMS_Generic_Monitor';
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
  asset.assetType         = RMS_ASSET_TYPE_UNKNOWN;

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
  //Register all snapi HAS_xyz components
  RegisterAssetParametersSnapiComponents(assetClientKey);
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
	// IP Address
	RmsAssetParameterEnqueueSetValue(assetClientKey,'asset.network.ip',MONITOR_ASSET_IP_ADDRESS);
	// Submit
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
		SWITCH(REMOVE_STRING(DATA.TEXT,'-',1)){
			CASE 'PROPERTY-':{
				SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
					CASE 'META,':{
						SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
							CASE 'NAME,':{		    MONITOR_ASSET_NAME              = DATA.TEXT }
							CASE 'DESC,': { 	    MONITOR_ASSET_DESCRIPTION 	   = DATA.TEXT }
							CASE 'MAKE,': { 	 	 MONITOR_ASSET_MANUFACTURERNAME 	= DATA.TEXT }
							CASE 'MODEL,':{ 	    MONITOR_ASSET_MODELNAME 			= DATA.TEXT }
							CASE 'SWVERSION,':{ 	 MONITOR_ASSET_FIRMWAREVERSION 	= DATA.TEXT }
							CASE 'SERIALNO,':{ 	 MONITOR_ASSET_SERIALNUMBER 		= DATA.TEXT }
							CASE 'PARTNO,':{ 	 MONITOR_ASSET_PART_NUMBER 		= DATA.TEXT }
						}
					}
					CASE 'IP,':{
						MONITOR_ASSET_IP_ADDRESS = DATA.TEXT
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

