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
MODULE_NAME='RmsSystemPowerMonitor'(DEV vdvRMS,
                                    DEV dvControlSystem)

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This NetLinx module contains the source code for       *)
(*  registering and monitoring the 'System Power'          *)
(*  parameter on the control system asset in RMS.          *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

CHAR MONITOR_NAME[]       = 'RMS System Power Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'RmsSystemPowerMon';
CHAR MONITOR_VERSION[]    = '4.6.7';


// Including the RmsEventListener.AXI will listen for RMS
// events from the RMS virtual device interface (vdvRMS)
// and invoke callback methods to notify this program when
// these event occur.
//
// The following set of INCLUDE_RMS_EVENT_xxx compiler
// directives subscribe for the desired callback event
// and the callback methods for these events must exist
// in this program file.

// subscribe to the asset registered event notification callback
// this callback event will invoke the 'RmsEventAssetRegistered' method
#DEFINE INCLUDE_RMS_EVENT_ASSET_REGISTERED_CALLBACK

// subscribe to the system power event notification callback
// this callback event will invoke the 'RmsEventSystemPowerChanged' method
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_CALLBACK;

// subscribe to the system power change request event notification callback
// this callback event will invoke the 'RmsEventSystemPowerChangeRequest' method
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_REQUEST_CALLBACK

// subscribe to the version request event notification callback
// this callback event will invoke the 'RmsEventVersionRequest' method
#DEFINE INCLUDE_RMS_EVENT_VERSION_REQUEST_CALLBACK

// include RmsEventListener (which also includes RMS API)
#INCLUDE 'RmsEventListener';

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
CHAR assetClientKey[50];


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)


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
(* Name:  RmsEventAssetRegistered                          *)
(* Args:  registeredAssetClientKey - unique identifier key *)
(*                          for each asset.                *)
(*        assetId - unique identifier number for each asset*)
(*        newAssetRegistration - true/false                *)
(*        registeredAssetDps - DPS for each asset          *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program of when an asset registration has been   *)
(*        completed.  After asset registration is complete *)
(*        asset parameters, control methods, and metadata  *)
(*        propteries are ready to be registered/updated.   *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventAssetRegistered(CHAR registeredAssetClientKey[], LONG assetId, CHAR newAssetRegistration, CHAR registeredAssetDps[])
{
  STACK_VAR CHAR sValue[3];

  // This function will listen for each asset key that is registered to RMS
  // and then attempt a lookup on the key in the source usage tracking
  // collection of source assets and if a match is found, then it will
  // register the additional source usage asset parameter with RMS and
  // then maintain parameter value updates as the source usage changes.
  IF(registeredAssetClientKey == RmsDevToString(dvControlSystem) || registeredAssetDps == RmsDevToString(dvControlSystem))
  {
    assetClientKey = registeredAssetClientKey;
    // determine current system power value
    IF([vdvRMS,RMS_CHANNEL_SYSTEM_POWER])
      sValue = 'On';
    ELSE
      sValue = 'Off';

    IF(newAssetRegistration)
    {
      DEBUG("'registering system power parameter for asset [',assetClientKey,']'");

      // system power
      RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                    'system.power',
                                    'System Power',
                                    'System power state',
                                    RMS_ASSET_PARAM_TYPE_SYSTEM_POWER,
                                    sValue,
                                    'Off|On',
                                    RMS_ALLOW_RESET_NO,
                                    'Off',
                                    RMS_TRACK_CHANGES_YES);

      // submit parameter registration
      RmsAssetParameterSubmit(assetClientKey);


      // register control methods for system power
      DEBUG("'registering system power control methods for asset [',assetClientKey,']'");
      RmsAssetControlMethodEnqueue(assetClientKey, 'system.power.on', 'System Power On', 'Set the system power to the ON state.');
      RmsAssetControlMethodEnqueue(assetClientKey, 'system.power.off', 'System Power Off', 'Set the system power to the OFF state.');

      // submit the control methods
      RmsAssetControlMethodsSubmit(assetClientKey);
    }
    ELSE
    {
      DEBUG("'synchronizing system power parameter for asset [',assetClientKey,']'");

      // update the "System Power" parameter in RMS
      RmsAssetParameterSetValue(assetClientKey,'system.power',sValue);
    }
  }
}


(***********************************************************)
(* Name:  RmsEventSystemPowerChangeRequest                 *)
(* Args:  powerOn - boolean bit TRUE|FALSE for system      *)
(*                  power state                            *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when a system power state change has     *)
(*        been requested.                                  *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventSystemPowerChangeRequest(CHAR powerOn)
{
  //
  // (RMS SYSTEM POWER CHANGE REQUEST NOTIFICATION)
  //

  IF(powerOn)
  {
    // system power ON request received
  }
  ELSE
  {
    // system power OFF request received
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
  // upon receiving the system power change notification from
  // this module should perform an update on the system
  // power asset parameter value in RMS
  //

  // update the "System Power" parameter in RMS
  // when the power state changes
  IF(powerOn)
  {
    // system power in ON
    RmsAssetParameterSetValue(assetClientKey,'system.power','On');
  }
  ELSE
  {
    // system power in OFF
    RmsAssetParameterSetValue(assetClientKey,'system.power','Off');
  }
}



(***********************************************************)
(* Name:  Debug                                            *)
(* Args:  data - message string to display.                *)
(*                                                         *)
(* Desc:  This is a convienance method to print debugging  *)
(*        and diagnostics information message to the       *)
(*        master's telnet console.  The message string     *)
(*        will be prepended with the RMS monitoring module *)
(*        name and source usage virtual device ID string   *)
(*        to help identify from which module instance the  *)
(*        message originated.                              *)
(***********************************************************)
DEFINE_FUNCTION Debug(CHAR data[])
{
  SEND_STRING 0, "'[',MONITOR_DEBUG_NAME,'-',RmsDevToString(dvControlSystem),'] ',data";
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
  SEND_STRING 0, "name,' : ',MONITOR_VERSION,' (',RmsDevToString(dvControlSystem),')'";
}


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM
