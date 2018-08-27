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
PROGRAM_NAME='RmsSystemEventHandler'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file contains the NetLinx sample code to  *)
(*  implement system power ON/OFF and system mode changes  *)
(*  advertised by the RMS client via button event and      *)
(*  command notifications.                                 *)
(*                                                         *)
(*  This code was placed in this include file to allow     *)
(*  separation from the main RMS implementation code and   *)
(*  allow for easy inclusion/exclusion.                    *)
(*                                                         *)
(*  System power and system mode features must be enabled  *)
(*  include the RmsControlSystemMonitor module.            *)
(*  Please see the sample code and comments below.         *)
(*                                                         *)
(***********************************************************)


// Including the RmsEventListener.AXI will listen for RMS
// events from the RMS virtual device interface (vdvRMS)
// and invoke callback methods to notify this program when
// these event occur.
//
// The following set of INCLUDE_RMS_EVENT_xxx compiler
// directives subscribe for the desired callback event
// and the callback methods for these events must exist
// in this program file.

// subscribe to system event notification callback methods
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_REQUEST_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_CALLBACK;
#DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_REQUEST_CALLBACK;

// include RmsEventListener (which also includes RMS API)
#INCLUDE 'RmsEventListener';


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

#WARN 'README: System Power & System Modes'
// ----------------------------------------------------------------------
//
// You are responsible for manually handling the implementation logic
// for SYSTEM POWER ON and OFF events as well as for system modes.
//
// To enable/disable the SYSTEM POWER and SYSTEM MODE functionality
// and registration with RMS, please see the following precompiler
// variable inside the 'RmsControlSystemMonitor' module.  This module
// must be compiled with support enabled/disabled.
//
// #DEFINE HAS_SYSTEM_POWER    <<  inside 'RmsControlSystemMonitor' module
// #DEFINE HAS_SYSTEM_MODE     <<  inside 'RmsControlSystemMonitor' module
//
//
// The enumerated set of SYSTEM MODES are a hard coded and compiled
// variable inside the 'RmsControlSystemMonitor' module.  Please define
// the desired set of system modes inside this module.
//
// ----------------------------------------------------------------------


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
  // the RMS client the user code should implement the necessary
  // code logic to power the 'SYSTEM' ON or OFF
  //
  SEND_STRING 0, '**************************************';
  IF(powerOn)
  {
    SEND_STRING 0, ' SYSTEM POWER [ON] ';
  }
  ELSE
  {
    SEND_STRING 0, ' SYSTEM POWER [OFF] ';
  }
  SEND_STRING 0, '**************************************';

  #WARN 'Implement your SYSTEM POWER [ON/OFF] logic here!'
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
(* Name:  ChangeMySystemMode                               *)
(* Args:  modeName - mode name for the newly applied       *)
(*                   system operating mode                 *)
(***********************************************************)
DEFINE_FUNCTION ChangeMySystemMode(CHAR modeName[])
{
    #WARN 'Implement your SYSTEM MODE CHANGE logic here!'

    // after performing the system mode change implementation logic,
    // we must let RMS know that the system mode state has been
    // changed.  We can do this using an RMS API function.
    SEND_STRING 0, '************************************************';
    SEND_STRING 0,"' ChangeMySystemMode(',modeName,') called        '";
    SEND_STRING 0, '************************************************';
    RmsSystemSetMode(modeName);
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
  //
  SEND_STRING 0, '**************************************';
  SEND_STRING 0,"' SYSTEM MODE CHANGE [',modeName,']'";
  SEND_STRING 0, '**************************************';
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
DEFINE_FUNCTION RmsEventSystemModeChangeRequest(CHAR newMode[])
{
  //
  // (RMS SYSTEM MODE CHANGE REQUEST NOTIFICATION)
  //
  // upon receiving the system mode change request
  // event notification from the RMS client
  //
  SEND_STRING 0, '************************************************';
  SEND_STRING 0,"' SYSTEM MODE CHANGE REQUESTED [',newMode,']'";
  SEND_STRING 0, '************************************************';

  // call your own local function to perform the system mode change
  ChangeMySystemMode(newMode);
}

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

