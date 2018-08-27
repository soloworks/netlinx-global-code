MODULE_NAME='RmsPCMonitor'(DEV vdvRMS, DEV vdvDevice)
#INCLUDE 'CustomFunctions'
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
DEFINE_CONSTANT
INTEGER MAX_SERVICES = 10
INTEGER assetDelayIntervalOverride = 3
DEFINE_VARIABLE
// RMS Asset Properties (Recommended)
CHAR MONITOR_ASSET_NAME[50] = 'PC Monitor'

// This module's version information (for logging)
CHAR MONITOR_NAME[50] 		 = 'Solo Control PC Monitor';
CHAR MONITOR_VERSION[20]    = '4.3.25';
CHAR MONITOR_DEBUG_NAME[50] =  'SC_RMS_PC_Monitor'

DEFINE_TYPE STRUCTURE uPCMonitorAsset{
	// RMS Asset Properties (Optional)
	CHAR ASSET_DESCRIPTION[50]
	CHAR ASSET_MANUFACTURERNAME[50]
	CHAR ASSET_MODELNAME[50]
	CHAR ASSET_MAC_ADDRESS[50]
	CHAR ASSET_IP_ADDRESS[50]
	CHAR ASSET_LOCATION[50]

	CHAR SERVICE_NAME[MAX_SERVICES][50]
	CHAR SERVICE_KEY[MAX_SERVICES][50]
}


DEFINE_VARIABLE
VOLATILE uPCMonitorAsset myPCMonitorAsset

DEFINE_FUNCTION INTEGER fnGetServiceIndex(CHAR pKEY[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= MAX_SERVICES; x++){
		IF(myPCMonitorAsset.SERVICE_KEY[x] == pKEY){
			RETURN x
		}
	}
}
DEFINE_FUNCTION INTEGER fnAddService(CHAR pNAME[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= MAX_SERVICES; x++){
		IF(!LENGTH_ARRAY(myPCMonitorAsset.SERVICE_KEY[x])){
			myPCMonitorAsset.SERVICE_NAME[x] = pNAME
			myPCMonitorAsset.SERVICE_KEY[x]  = fnRemoveWhiteSpace(pNAME)
			RETURN x
		}
	}
}
DEFINE_FUNCTION fnRemoveService(CHAR pKEY[]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= MAX_SERVICES; x++){
		IF(myPCMonitorAsset.SERVICE_KEY[x] == pKEY){
			BREAK
		}
	}
	FOR(x = x; x < MAX_SERVICES; x++){
		myPCMonitorAsset.SERVICE_NAME[x] = myPCMonitorAsset.SERVICE_NAME[x+1]
		myPCMonitorAsset.SERVICE_KEY[x]  = myPCMonitorAsset.SERVICE_KEY[x+1]
	}
	myPCMonitorAsset.SERVICE_NAME[MAX_SERVICES] = ''
	myPCMonitorAsset.SERVICE_KEY[MAX_SERVICES]  = ''
}
/******************************************************************************
	System Includes
******************************************************************************/
#INCLUDE 'RmsMonitorCommon';
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
  asset.assetType         = 'SignageNuc';

  // These are optional
  asset.description       = myPCMonitorAsset.ASSET_DESCRIPTION;
  asset.manufacturerName  = myPCMonitorAsset.ASSET_MANUFACTURERNAME;
  asset.modelName         = myPCMonitorAsset.ASSET_MODELNAME;

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
	FOR(x = 1; x <= MAX_SERVICES; x++){
		IF(LENGTH_ARRAY(myPCMonitorAsset.SERVICE_KEY[x])){
		  fnRegisterServiceParam(x)
		}
	}
   // submit all parameter registrations
   RmsAssetParameterSubmit(assetClientKey);
}

DEFINE_FUNCTION fnRegisterServiceParam(INTEGER pService){
	STACK_VAR RmsAssetParameter parameter
	STACK_VAR RmsAssetParameterThreshold threshold

	// device device online parameter
	parameter.key = "'service.',myPCMonitorAsset.SERVICE_KEY[pService]"
	parameter.name = "'Process Status for ',myPCMonitorAsset.SERVICE_NAME[pService]"
	parameter.description = 'Current service status';
	parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_ENUMERATION;
	parameter.enumeration = 'Running|Stopped';
	parameter.allowReset = RMS_ALLOW_RESET_NO;
	parameter.stockParam = TRUE;
	parameter.reportingType = RMS_ASSET_PARAM_TYPE_NONE;
	parameter.trackChanges = RMS_TRACK_CHANGES_YES;
	parameter.resetValue = 'Stopped';
	SWITCH([vdvDevice,pService]){
		CASE TRUE:	parameter.initialValue = 'Online'
		CASE FALSE:	parameter.initialValue = 'Offline'
	}

  // enqueue parameter
  RmsAssetParameterEnqueue(assetClientKey, parameter);

  // populate default threshold settings for low battery condition
  threshold.name = 'ServiceActive';
  threshold.comparisonOperator = RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL;
  threshold.value = 'Stopped'; // less than 5%
  threshold.statusType = RMS_STATUS_TYPE_MAINTENANCE;
  threshold.enabled = TRUE;
  threshold.notifyOnRestore = TRUE;
  threshold.notifyOnTrip = TRUE;
  threshold.delayInterval = 3; // number of minute before threshold takes effect

  // add a default threshold for service not running
  RmsAssetParameterThresholdEnqueueEx(assetClientKey,
												  "'service.',myPCMonitorAsset.SERVICE_KEY[pService]",
													  threshold)
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
	STACK_VAR INTEGER x
  // This callback method is invoked when either the RMS server connection
  // has been offline or this monitored device has been offline from some
  // amount of time.   Since the monitored parameter state values could
  // be out of sync with the RMS server, we must perform asset parameter
  // value updates for all monitored parameters so they will be in sync.
  // Update only asset monitoring parameters that may have changed in value.

  //Synchronize all snapi HAS_xyz components
   SynchronizeAssetParametersSnapiComponents(assetClientKey)
	FOR(x = 1; x <= MAX_SERVICES; x++){
		IF(LENGTH_ARRAY(myPCMonitorAsset.SERVICE_KEY[x])){
			SWITCH([vdvDevice,x]){
				CASE TRUE: RmsAssetParameterSetValue(assetClientKey,"'service.',myPCMonitorAsset.SERVICE_KEY[x]",'Running')
				CASE FALSE:RmsAssetParameterSetValue(assetClientKey,"'service.',myPCMonitorAsset.SERVICE_KEY[x]",'Stopped')
			}
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

	//Custom go here

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
		CASE 'asset.customaction.input' :{
			//SEND_COMMAND vdvDevice, "'INPUT-',DATA.TEXT"
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
					CASE 'META':{
						SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
							CASE 'NAME':{		 MONITOR_ASSET_NAME 					= DATA.TEXT }
							CASE 'DESC': { 	 myPCMonitorAsset.ASSET_DESCRIPTION 		= DATA.TEXT }
							CASE 'MAKE': { 	 myPCMonitorAsset.ASSET_MANUFACTURERNAME 	= DATA.TEXT }
							CASE 'MODEL':{ 	 myPCMonitorAsset.ASSET_MODELNAME 			= DATA.TEXT }
							CASE 'LOCATION':{  myPCMonitorAsset.ASSET_LOCATION 			= DATA.TEXT }
						}
					}
				}
			}
			CASE 'SERVICE':{
				SWITCH(DATA.TEXT){
					CASE 'UPDATE':{
						IF(IsRmsReady()){ RmsAssetParameterSubmit(assetClientKey); }
					}
					DEFAULT:{
						STACK_VAR CHAR pSERVICE_NAME[50]
						STACK_VAR CHAR pSERVICE_KEY[50]
						pSERVICE_NAME = fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)
						pSERVICE_KEY = fnRemoveWhiteSpace(pSERVICE_NAME)
						SWITCH(DATA.TEXT){
							CASE 'REMOVE':{
								fnRemoveService(pSERVICE_NAME)
								IF(IsRmsReady()){ RmsAssetParameterDelete(assetClientKey,"'service.',pSERVICE_KEY") }
							}
							CASE 'ADD':{
								STACK_VAR INTEGER pServiceID
								pServiceID = fnGetServiceIndex(pSERVICE_KEY)
								IF(!pServiceID){
									fnAddService(pSERVICE_KEY)
									// Mute State
									IF(IsRmsReady()){
										fnRegisterServiceParam(fnGetServiceIndex(pSERVICE_KEY))
										RmsAssetParameterSubmit(assetClientKey);
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

DEFINE_EVENT CHANNEL_EVENT[vdvDevice,0]{
	ON:{
		IF(CHANNEL.CHANNEL <= MAX_SERVICES && IsRmsReady()){
			RmsAssetParameterSetValue(assetClientKey,"'service.',myPCMonitorAsset.SERVICE_KEY[CHANNEL.CHANNEL]",'Running')
		}
	}
	OFF:{
		IF(CHANNEL.CHANNEL <= MAX_SERVICES && IsRmsReady()){
			RmsAssetParameterSetValue(assetClientKey,"'service.',myPCMonitorAsset.SERVICE_KEY[CHANNEL.CHANNEL]",'Stopped')
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
