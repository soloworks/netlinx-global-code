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
MODULE_NAME='RmsSystemModeMonitor'(DEV vdvRMS,
                                   DEV dvControlSystem,
                                  CHAR SystemModes[])

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This NetLinx module contains the source code for       *)
(*  registering and monitoring the 'System Mode'           *)
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

CHAR MONITOR_NAME[]       = 'RMS System Modes Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'RmsSystemModesMon';
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

// subscribe to the system mode event notification callback
// this callback event will invoke the 'RmsEventSystemModeChanged' method
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_CALLBACK;

// subscribe to the system mode request event notification callback
// this callback event will invoke the 'RmsEventSystemModeChangeRequest' method
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_REQUEST_CALLBACK;

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
CHAR sCurrentMode[30];

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

  IF(registeredAssetClientKey == RmsDevToString(dvControlSystem) || registeredAssetDps == RmsDevToString(dvControlSystem))
  {
    assetClientKey = registeredAssetClientKey;
    IF(newAssetRegistration)
    {
      DEBUG("'registering system mode parameter for asset [',assetClientKey,']'");

      // system mode
      RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                    'system.mode',
                                    'System Mode',
                                    'System operational mode',
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    sCurrentMode,
                                    SystemModes,
                                    RMS_ALLOW_RESET_NO,
                                    '',
                                    RMS_TRACK_CHANGES_NO);

      // submit parameter registration
      RmsAssetParameterSubmit(assetClientKey);

      // register control methods for system mode
      DEBUG("'registering system mode control method for asset [',assetClientKey,']'");
      RmsAssetControlMethodEnqueue(assetClientKey, 'system.mode', 'Set System Mode', 'Set the system operational mode.');
      RmsAssetControlMethodArgumentEnum (assetClientKey, 'system.mode', 0,'Operational Mode', 'Select the operational mode to apply','',SystemModes);

      // submit the control methods
      RmsAssetControlMethodsSubmit(assetClientKey);
    }
    ELSE
    {
      DEBUG("'synchronizing system mode parameter for asset [',assetClientKey,']'");

      // update the "System Mode" parameter in RMS
      RmsAssetParameterSetValue(assetClientKey,'system.mode',sCurrentMode);
    }
  }
}


(***********************************************************)
(* Name:  RmsEventSystemModeChangeRequest                  *)
(* Args:  modeName - mode name for the requested           *)
(*                   system operating mode                 *)
(*                                                         *)
(* Desc:  This callback method is invoked by the           *)
(*        'RmsEventListener' include file to notify this   *)
(*        program when the system operating mode has       *)
(*        requested to be changed.                         *)
(*                                                         *)
(*        This method should not be invoked/called         *)
(*        by any user implementation code.                 *)
(***********************************************************)
DEFINE_FUNCTION RmsEventSystemModeChangeRequest(CHAR modeName[])
{
  //
  // (RMS SYSTEM MODE CHANGE REQUEST NOTIFICATION)
  //
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
  // upon receiving the system mode change event
  // notification from the RMS client
  // update the "System Mode" parameter in RMS
  //
  sCurrentMode = modeName;
  RmsAssetParameterSetValue(assetClientKey,'system.mode',sCurrentMode);
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
