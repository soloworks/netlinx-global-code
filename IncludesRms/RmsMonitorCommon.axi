//*********************************************************************
//
//             AMX Resource Management Suite  (4.6.7)
//
//*********************************************************************
/*
 *  Legal Notice :
 *
 *     Copyright, AMX LLC, 2011
 *
 *     Private, proprietary information, the sole property of AMX LLC.  The
 *     contents, ideas, and concepts expressed herein are not to be disclosed
 *     except within the confines of a confidential relationship and only
 *     then on a need to know basis.
 *
 *     Any entity in possession of this AMX Software shall not, and shall not
 *     permit any other person to, disclose, display, loan, publish, transfer
 *     (whether by sale, assignment, exchange, gift, operation of law or
 *     otherwise), license, sublicense, copy, or otherwise disseminate this
 *     AMX Software.
 *
 *     This AMX Software is owned by AMX and is protected by United States
 *     copyright laws, patent laws, international treaty provisions, and/or
 *     state of Texas trade secret laws.
 *
 *     Portions of this AMX Software may, from time to time, include
 *     pre-release code and such code may not be at the level of performance,
 *     compatibility and functionality of the final code. The pre-release code
 *     may not operate correctly and may be substantially modified prior to
 *     final release or certain features may not be generally released. AMX is
 *     not obligated to make or support any pre-release code. All pre-release
 *     code is provided "as is" with no warranties.
 *
 *     This AMX Software is provided with restricted rights. Use, duplication,
 *     or disclosure by the Government is subject to restrictions as set forth
 *     in subparagraph (1)(ii) of The Rights in Technical Data and Computer
 *     Software clause at DFARS 252.227-7013 or subparagraphs (1) and (2) of
 *     the Commercial Computer Software Restricted Rights at 48 CFR 52.227-19,
 *     as applicable.
*/
PROGRAM_NAME='RmsMonitorCommon'


// this is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_MONITOR_COMMON__
#DEFINE __RMS_MONITOR_COMMON__


(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file is used by each of the RMS Duet      *)
(*  device monitoring modules.  It acts much like a base   *)
(*  class implementation where much of the details and     *)
(*  logic for interacting with the RMS client via the RMS  *)
(*  virtual device is placed here for reuse and to         *)
(*  simplify the implmentation in each monitoring module   *)
(*  instance.                                              *)
(*                                                         *)
(*  This include listens for RMS specific asset management *)
(*  event notifications from the RMS virtual device and    *)
(*  performs callback method calls to each monitoring      *)
(*  module as needed.                                      *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

// This include file supports the following list of compiler
// directives.  You can place any of these compiler directives
// if your implementation code that is consuming this include
// file to 'Subscribe' for callback event notification that
// are not provided by default or to 'Unsubscribe' to default
// enabled callback notifications.
/*
-- exclude default event callbacks --
#DEFINE EXCLUDE_RMS_ASSET_REGISTER_CALLBACK
#DEFINE EXCLUDE_RMS_metadata_REGISTER_CALLBACK
#DEFINE EXCLUDE_RMS_metadata_SYNC_CALLBACK
#DEFINE EXCLUDE_RMS_PARAMETER_REGISTER_CALLBACK
#DEFINE EXCLUDE_RMS_PARAMETER_SYNC_CALLBACK
#DEFINE EXCLUDE_RMS_PARAMETER_RESET_CALLBACK
#DEFINE EXCLUDE_RMS_CONTROL_METHOD_REGISTER_CALLBACK
#DEFINE EXCLUDE_RMS_CONTROL_METHOD_EXECUTE_CALLBACK
#DEFINE EXCLUDE_RMS_SYSTEM_POWER_CHANGE_CALLBACK
#DEFINE EXCLUDE_RMS_SYSTEM_MODE_CHANGE_CALLBACK

-- include non-default event callbacks --
#DEFINE INCLUDE_RMS_EVENT_ASSETS_REGISTER_RELAY_CALLBACK
#DEFINE INCLUDE_RMS_EVENT_ASSET_REGISTERED_RELAY_CALLBACK
#DEFINE INCLUDE_RMS_EVENT_ASSET_PARAM_RESET_RELAY_CALLBACK
#DEFINE INCLUDE_RMS_EVENT_ASSET_METHOD_EXECUTE_RELAY_CALLBACK
*/



// Including the RmsEventListener.AXI will listen for RMS
// events from the RMS virtual device interface (vdvRMS)
// and invoke callback methods to notify this program when
// these event occur.
//
// The following set of INCLUDE_RMS_EVENT_xxx compiler
// directives subscribe for the desired callback event
// and the callback methods for these events must exist
// in this program file.

// subscribe to asset management event notification callback methods
#DEFINE INCLUDE_RMS_EVENT_ASSETS_REGISTER_CALLBACK
#DEFINE INCLUDE_RMS_EVENT_ASSET_REGISTERED_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_ASSET_PARAM_RESET_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_ASSET_METHOD_EXECUTE_CALLBACK;

// subscribe to system event notification callback methods
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_CALLBACK;

// subscribe to the version request event notification callback method
#DEFINE INCLUDE_RMS_EVENT_VERSION_REQUEST_CALLBACK;

// include RmsEventListener (which also includes RMS API)
#INCLUDE 'RmsEventListener';

// The dependency file 'SNAPI.AXI' is included because it
// contains all the standard defined NetLinx API constants
// and functions used to communicate with the AMX
// standardized Duet-based device modules.
//
// S.N.A.P.I. = Standard NetLinx Application
//              Programming Interface
#INCLUDE 'SNAPI'


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

CHAR     assetClientKey[50];
CHAR     assetRegistered;

// Indicates whether or not all parameters, metadata, and
// control methods have been registered.
CHAR     parametersRegistered;


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  RmsEventRegisterAssets                           *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when RMS is ready for asset              *)
(*        registration to begin.                           *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
// #DEFINE INCLUDE_RMS_EVENT_ASSETS_REGISTER_CALLBACK
DEFINE_FUNCTION RmsEventRegisterAssets()
{
  STACK_VAR RmsAsset asset;

  // Certain monitoring modules may be interested in receiving
  // this raw asset registration callback notification,
  // not just callbacks tailored for the monitored asset.
  // A special compiler directive defined will allow this
  // notification to be relayed to the monitoring module
  #IF_DEFINED INCLUDE_RMS_EVENT_ASSETS_REGISTER_RELAY_CALLBACK

  // relay the notification via callback method invocation
  RmsEventRelayRegisterAssets();

  #END_IF

  //
  // (RMS REGISTER ASSETS NOTIFICATION)
  //
  // upon receiving the assets register notification from
  // the RMS client each monitor module should respond by
  // registering its asset(s).
  //

  // reset asset registered state flag
  OFF[assetRegistered];

  // reset asset parameters registered state flag
  OFF[parametersRegistered];

  // register asset now
  //
  // (the registration will only be performed
  //  if RMS is online and accepting asset
  //  registrations and the asset has not already
  //  been registered.)
  RegisterAssetWrapper();
}

(***********************************************************)
(* Name:  RmsEventAssetRegistered                          *)
(* Args:  registeredAssetClientKey - unique identifier key *)
(*        for each asset.                                  *)
(*        assetId - unique identifier number for each asset*)
(*        newAssetRegistration - true/false                *)
(*        registeredAssetDps - DPS for each asset          *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when an asset registration has been      *)
(*        completed.  After asset registration is complete *)
(*        asset parameters, control methods, and metadata  *)
(*        propteries are ready to be registered/updated.   *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventAssetRegistered(CHAR registeredAssetClientKey[], LONG assetId, CHAR newAssetRegistration, CHAR registeredAssetDps[])
{
  // Certain monitoring modules such as the PDU power
  // monitoring module may be interested in receiving
  // this callback notification that includes information
  // on all registered assets, not just the monitored asset.
  // A special compiler directive defined will allow this
  // notification to be relayed to the monitoring module
  #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_REGISTERED_RELAY_CALLBACK

  // relay the notification via callback method invocation
  RmsEventRelayAssetRegistered(registeredAssetClientKey, assetId, newAssetRegistration, registeredAssetDps);

  #END_IF

  //
  // (RMS ASSET REGISTERED NOTIFICATION)
  //
  // upon receiving the assets register notification from
  // the RMS client each monitor module should respond by
  // registering its asset(s).
  //

  // if the registered asset event notification
  // matches this asset's client key, then
  // we can begin registering this asset's
  // metadata properties, control functions,
  // and monitoring paramters.
  IF(registeredAssetClientKey == assetClientKey || registeredAssetDps == assetClientKey)
  {
    // Some registrations utilize the device DPS for the client key, while others use something
    // entirely different. In the case of auto-registered devices, the key is different from the DPS
    // and is not known until the asset registration event is received. This statement ensures that
    // the actual asset client key is alway known
    assetClientKey = registeredAssetClientKey;
  
    // set registered state flag for this asset
    ON[assetRegistered];

    // if this is a new asset registration then
    // perform the callbacks to register the
    // asset parameters, metadata, and control methods
    IF(newAssetRegistration)
    {
      // register asset metadata properties
      RegisterAssetMetadataWrapper();

      // register asset monitoring parameters
      RegisterAssetParametersWrapper();

      // register asset control methods
      RegisterAssetControlMethodsWrapper();
    }

    // if this is NOT a new asset registration then
    // perform the callbacks to synchronize the
    // asset metadata
    ELSE
    {
      // synchronize this asset's metadata
      SynchronizeAssetMetadataWrapper()
    }

    // synchronize this asset's parameters
    SynchronizeAssetParametersWrapper()

    // metadata, parameters and control methods now registered
    ON[parametersRegistered];
  }
}


(***********************************************************)
(* Name:  RmsEventAssetParameterReset                      *)
(* Args:  resetAssetClientKey - unique identifier key for  *)
(*                              each asset.                *)
(*        parameterKey   - unique identifier key for       *)
(*                         the asset parameter.            *)
(*        parameterName  - friendly string name for        *)
(*                         the asset parameter.            *)
(*        parameterValue - the reset parameter value       *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when an asset parameter has been reset   *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventAssetParameterReset(CHAR resetAssetClientKey[], CHAR parameterKey[], CHAR parameterName[], CHAR parameterValue[])
{
  // Certain monitoring modules may be interested in receiving
  // this callback notification that includes the parameter reset
  // notification for all assets, not just the monitored asset.
  // A special compiler directive defined will allow this
  // notification to be relayed to the monitoring module
  #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_PARAM_RESET_RELAY_CALLBACK

    // relay the notification via callback method invocation
    RmsEventRelayAssetParameterReset(resetAssetClientKey, parameterKey, parameterName, parameterValue);

  #END_IF

  //
  // (RMS ASSET PARAMETER RESET NOTIFICATION)
  //
  // upon receiving the asset parameter reset notification
  // from the RMS client, a callback method should be invoked
  // on each monitor module to notify them of the reset.
  //

  // if the registered asset event notification
  // matches this asset's client key, then
  // we can invoke the callback function for
  // this monitored asset module.
  IF(resetAssetClientKey == assetClientKey)
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_PARAMETER_RESET_CALLBACK

      // inkove callback method to notify the monitored
      // device module that an asset parameter value
      // hase been reset by the RMS server.
      ResetAssetParameterValue(parameterKey,parameterValue);

    #END_IF
  }
}


(***********************************************************)
(* Name:  RmsEventAssetControlMethodExecute                *)
(* Args:  methodAssetClientKey - unique identifier key for *)
(*                         each asset.                     *)
(*        methodKey      - unique identifier key for       *)
(*                         the asset control method.       *)
(*        methodArguments - comma separated string of      *)
(*                          executed method arguments.     *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program  when an asset method has been executed  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventAssetControlMethodExecute(CHAR methodAssetClientKey[], CHAR methodKey[], CHAR methodArguments[])
{
  // Certain monitoring modules may be interested in receiving
  // this callback notification that includes the control method
  // execution notification for all assets, not just the monitored asset.
  // A special compiler directive defined will allow this
  // notification to be relayed to the monitoring module
  #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_METHOD_EXECUTE_RELAY_CALLBACK

    // relay the notification via callback method invocation
    RmsEventRelayAssetControlMethodExecute(methodAssetClientKey, methodKey, methodArguments);

  #END_IF

  //
  // (RMS ASSET CONTROL METHOD EXECUTION NOTIFICATION)
  //
  // upon receiving the assets control method execution
  // notification from the RMS client each monitor module
  // should fire the control method if the asset client
  // key is a match to this asset and the method key
  // is supported by this asset.
  //

  // if the registered asset event notification
  // matches this asset's client key, then
  // we can accept this control method execution
  // instruction.
  IF(methodAssetClientKey == assetClientKey)
  {

    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_CONTROL_METHOD_EXECUTE_CALLBACK

      // invoke control method execute callback function
      ExecuteAssetControlMethod(methodKey,methodArguments);

    #END_IF
  }
}


(***********************************************************)
(* Name:  RmsEventSystemPowerChanged                       *)
(* Args:  powerOn - boolean bit TRUE|FALSE for system      *)
(*                  power state                            *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when the system power state has changed  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventSystemPowerChanged(CHAR powerOn)
{
  //
  // (RMS SYSTEM POWER CHANGE NOTIFICATION)
  //
  // upon receiving the system power change notification
  // from the RMS client each monitor module should be
  // notified via a callback function.
  //

  // skip this callback invocation if this
  // precompiler variable is detected
  #IF_NOT_DEFINED EXCLUDE_RMS_SYSTEM_POWER_CHANGE_CALLBACK

    // invoke system power change callback function
    SystemPowerChanged(powerOn);

  #END_IF
}


(***********************************************************)
(* Name:  RmsEventSystemModeChanged                        *)
(* Args:  modeName - mode name for the newly applied       *)
(*                   system operating mode                 *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when the system operating mode has       *)
(*        changed.                                         *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventSystemModeChanged(CHAR modeName[])
{
  //
  // (RMS SYSTEM MODE CHANGE NOTIFICATION)
  //
  // upon receiving the system mode change notification
  // from the RMS client each monitor module should be
  // notified via a callback function.
  //

  // skip this callback invocation if this
  // precompiler variable is detected
  #IF_NOT_DEFINED EXCLUDE_RMS_SYSTEM_MODE_CHANGE_CALLBACK

    // invoke system mode change callback function
    SystemModeChanged(modeName);

  #END_IF
}


(***********************************************************)
(* Name:  RmsEventVersionRequest                           *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when a version printout is required.     *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventVersionRequest()
{
  //
  // (RMS VERSION REQUEST NOTIFICATION)
  //
  // upon receiving a version request from the RMS client
  // each monitor module should respond by printing its
  // name and version information to the master's telnet
  // console.
  //
  PrintVersion();
}


(***********************************************************)
(* Name:  Debug                                            *)
(* Args:  data - message string to display.                *)
(*                                                         *)
(* Desc:  This is a convienance method to print debugging  *)
(*        and diagnostics information message to the       *)
(*        master's telnet console.  The message string     *)
(*        will be prepended with the RMS monitoring module *)
(*        name and device ID string to help identifyfrom   *)
(*        which specific RMS device monitoring module      *)
(*        instance the message originated.                 *)
(***********************************************************)
DEFINE_FUNCTION Debug(CHAR data[])
{
  SEND_STRING 0, "'[',MONITOR_DEBUG_NAME,'-',RmsDevToString(vdvDevice),'] ',data";
}


(***********************************************************)
(* Name:  PrintVersion                                     *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a convienance method to print the RMS    *)
(*        monitoring module's version information in a     *)
(*        formatted string message to the NetLinx masters  *)
(*        telnet console.                                  *)
(***********************************************************)
DEFINE_FUNCTION PrintVersion()
{
  STACK_VAR
    CHAR name[30];
    CHAR emptyString[30];

  emptyString = '                          ';

  // append monitor name
  IF(LENGTH_STRING(MONITOR_NAME) > 30)
  {
    name = LEFT_STRING(MONITOR_NAME,30);
  }
  ELSE
  {
    name = "MONITOR_NAME,LEFT_STRING(emptyString,30-LENGTH_STRING(MONITOR_NAME))";
  }

  // print monitor module name and version to console
  SEND_STRING 0, "name,' : ',MONITOR_VERSION,' (',RmsDevToString(vdvDevice),')'";
}


(***********************************************************)
(* Name:  RegisterAssetWrapper                             *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the 'RegisterAsset'      *)
(*        method inside the RMS asset monitoring module.   *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetWrapper()
{
  STACK_VAR RmsAsset asset;

  // first, make sure that the RMS client
  // is ready to accept asset registrations
  // or asset parameter updates
  IF([vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
#IF_DEFINED SNAPI_MONITOR_MODULE
    // if a SNAPI module is invoking this function, then we need to
    // make sure that the SNAPI device is DATA_INITIALIZED and ready
    // to register it's data with RMS
    IF(DEVICE_ID(vdvDevice) && [vdvDevice,DATA_INITIALIZED])
    {
#END_IF
        // if this asset is ONLINE
        IF(DEVICE_ID(vdvDevice))
        {
          // set specific overriding asset name
          IF(MONITOR_ASSET_NAME != '')
          {
            asset.name = MONITOR_ASSET_NAME
          }

          // skip this callback invocation if this
          // precompiler variable is detected
          #IF_NOT_DEFINED RMS_EXCLUDE_ASSET_REGISTER_CALLBACK

            // perform registration of this asset
            RegisterAsset(asset);

          #END_IF

          // cache asset client key for later use
          assetClientKey = asset.clientKey;
        }

#IF_DEFINED SNAPI_MONITOR_MODULE
    }
#END_IF
  }
}


(***********************************************************)
(* Name:  RegisterAssetMetadataWrapper                     *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the                      *)
(*        'RegisterAssetMetadata' method inside the RMS    *)
(*        asset monitoring module.                         *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetMetadataWrapper()
{
  // if this asset on ONLINE and is already
  // registered and the RMS system is in
  // asset registration mode, then
  // register asset metadata properties
  // with RMS now
  IF((DEVICE_ID(vdvDevice) && assetRegistered) &&
    [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_metadata_REGISTER_CALLBACK

      // perform registration of this asset's metadata
      RegisterAssetMetadata();

    #END_IF
  }
}


(***********************************************************)
(* Name:  SynchronizeAssetMetadataWrapper                  *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the                      *)
(*        'SynchronizeAssetMetadata' method inside the RMS *)
(*        asset monitoring module.                         *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetMetadataWrapper()
{
  // if this asset on ONLINE and is already
  // registered and the RMS system is in
  // asset registration mode, then syncronize
  // any asset metadata properties with RMS now
  IF((DEVICE_ID(vdvDevice) && assetRegistered) &&
    [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_metadata_SYNC_CALLBACK

      // perform synchronization of this asset's metadata
      SynchronizeAssetMetadata();

    #END_IF
  }
}


(***********************************************************)
(* Name:  RegisterAssetParametersWrapper                   *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the                      *)
(*        'RegisterAssetParameters' method inside the RMS  *)
(*        asset monitoring module.                         *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetParametersWrapper()
{
  // if this asset on ONLINE and is already
  // registered and the RMS system is in
  // asset registration mode, then
  // register asset monitoring parameters
  // with RMS now
  IF((DEVICE_ID(vdvDevice) && assetRegistered) &&
    [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_PARAMETER_REGISTER_CALLBACK

      // perform registration of this asset's metadata
      RegisterAssetParameters();

    #END_IF
  }
}


(***********************************************************)
(* Name:  SynchronizeAssetParametersWrapper                *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the                      *)
(*        'SynchronizeAssetParameters' method inside the   *)
(*        RMS asset monitoring module.                     *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION SynchronizeAssetParametersWrapper()
{
  // if this asset on ONLINE and is already
  // registered and the RMS system is in
  // asset registration mode, then synchronize
  // the asset monitoring parameters with RMS now
  IF((DEVICE_ID(vdvDevice) && assetRegistered) &&
    [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_PARAMETER_SYNC_CALLBACK

      // perform registration of this asset's metadata
      SynchronizeAssetParameters();

    #END_IF
  }
}


(***********************************************************)
(* Name:  RegisterAssetControlMethodsWrapper               *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used locally in this include file *)
(*        to invoke a callback to the                      *)
(*        'RegisterAssetControlMethods' method inside the  *)
(*        RMS asset monitoring module.                     *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RegisterAssetControlMethodsWrapper()
{
  STACK_VAR RmsAssetParameter deviceOnlineParameter;

  // if this asset on ONLINE and is already
  // registered and the RMS system is in
  // asset registration mode, then
  // register asset contol methods
  // with RMS now
  IF((DEVICE_ID(vdvDevice) && assetRegistered) &&
    [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    // skip this callback invocation if this
    // precompiler variable is detected
    #IF_NOT_DEFINED EXCLUDE_RMS_CONTROL_METHOD_REGISTER_CALLBACK

      // perform registration of this asset's metadata
      RegisterAssetControlMethods();

    #END_IF
  }
}


(***********************************************************)
(* Name:  IsRmsReadyForParameterUpdates                    *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This method is used to ensure that the RMS       *)
(*        client is fully online and that all parameters,  *)
(*        metadata, and control-methods have been fully    *)
(*        registered.                                      *)
(***********************************************************)
DEFINE_FUNCTION CHAR IsRmsReadyForParameterUpdates()
{
  RETURN ([vdvRMS,RMS_CHANNEL_ASSETS_REGISTER] && parametersRegistered);
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START


(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

//
// (MONITORED DEVICE DATA EVENT HANDLERS)
//
// handle events generated by the monitored device
//
DATA_EVENT[vdvDevice]
{
  ONLINE:
  {
    // wait a few seconds before sending asset registration
    // to RMS, lets just make sure the device connection is
    // stable and not coming online and immediately falling
    // offline
    WAIT 100 'RegisterAssetWait'
    {
      // register asset now
      //
      // (the registration will only be performed
      //  if RMS is online and accepting asset
      //  registrations and the asset has not already
      //  been registerd.)
      RegisterAssetWrapper();
    }
  }
  OFFLINE:
  {
    // cancel any pending asset registration waits
    CANCEL_WAIT 'RegisterAssetWait';
  }
}

//
// (DUET VIRTUAL DEVICE DATA INITIALIZED EVENT HANDLER)
//
// If this channel event goes into the ON state, then
// this means that the device is communicating with the
// Duet module and it data has been synchronized, thus
// we need to register this asset with RMS if RMS is
// accepting asset registrations.
//
#IF_DEFINED SNAPI_MONITOR_MODULE
CHANNEL_EVENT[vdvDevice,DATA_INITIALIZED]
{
  ON:
  {
    // register asset now
    //
    // (the registration will only be performed
    //  if RMS is online and accepting asset
    //  registrations and the asset has not already
    //  been registerd.)
    RegisterAssetWrapper();
  }
}
#END_IF

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)


#END_IF // __RMS_MONITOR_COMMON__
