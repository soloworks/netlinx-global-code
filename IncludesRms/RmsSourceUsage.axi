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
PROGRAM_NAME='RmsSourceUsage'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file contains the NetLinx sample code to  *)
(*  implement asset source usage tracking in RMS.          *)
(*                                                         *)
(*  This code was placed in this include file to allow     *)
(*  separation from the main RMS implementation code and   *)
(*  allow for easy inclusion/exclusion.                    *)
(*                                                         *)
(*  All sources that should have usage tracking must be    *)
(*  registered with the RmsSourceUsageMonitor module.      *)
(*  Please see the sample code below.                      *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE

(***********************************************************)
(*                INCLUDE DEFINITIONS GO BELOW             *)
(***********************************************************)

// Include the RMS API constants & helper functions
#INCLUDE 'RmsApi';

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)


(***********************************************************)
(* Name:  RmsSourceUsageReset                              *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function is used to deactivate and reset    *)
(*        all source selected asset tracking.  Call this   *)
(*        method anytime a condition exists where are      *)
(*        selected sources should be de-selected and no    *)
(*        active sources apply.  This reset will also      *)
(*        reset any currently pending cached source usage. *)
(*        This function is typically only used on program  *)
(*        startup.                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageReset()
{
  // to reset the selected source and all cached source usage
  SEND_COMMAND vdvRMSSourceUsage, 'SOURCE.RESET';
}


(***********************************************************)
(* Name:  RmsSourceUsageAssignAsset                        *)
(* Args:  index - source index position for source device  *)
(*        sourceDevice - device to use as a source device. *)
(*                                                         *)
(* Desc:  This function is used to assign a RMS asset to   *)
(*        be monitored for non-mutually exclusive source   *)
(*        usage tracking.  This method should be called on *)
(*        startup to assign each source based asset to an  *)
(*        index for source usage monitoring.               *)
(*                                                         *)
(*        Non-mutually exclusive source usage tracking     *)
(*        allows any combination of sources to be active   *)
(*        concurrently at any given time.  When using      *)
(*        non-mutually exclusive source tracking, you      *)
(*        the implementation programmer are 100%           *)
(*        responsible for coordinating the 'Activated'     *)
(*        'Deactivated' states for each source index in    *)
(*        the source usage tracking monitor.               *)
(*                                                         *)
(*        Non-mutually exclusive source usage tracking is  *)
(*        provided to allow you to handle complex or more  *)
(*        sophisticated setups where perhaps more than one *)
(*        source can be active at the same time such as    *)
(*        cases with split or quad screen setups or in     *)
(*        cases where there are multiple display outputs   *)
(*        devices that can accept a variety of difference  *)
(*        selected sources.                                *)
(*                                                         *)
(*        NOTE:  If you combine both mutually exclusive    *)
(*               and non-mutually exclusive source usage   *)
(*               registrations, then be aware that you     *)
(*               cannot reuse index number.  Each source   *)
(*               usage asset but be assiged exclusively    *)
(*               to a single index number.                 *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageAssignAsset(INTEGER index, DEV sourceDevice)
{
  STACK_VAR CHAR commandString[RMS_MAX_CMD_LEN];

  commandString = RmsPackCmdHeader('SOURCE.ASSIGN');
  commandString = RmsPackCmdParam(commandString,ITOA(index));
  commandString = RmsPackCmdParam(commandString,RmsDevToString(sourceDevice));

  SEND_COMMAND vdvRMSSourceUsage, commandString;
}


(***********************************************************)
(* Name:  RmsSourceUsageAssignAssetMutExcl                 *)
(* Args:  index - source index position for source device  *)
(*        sourceDevice - device to use as a source device. *)
(*                                                         *)
(* Desc:  This function is used to assign a RMS asset to   *)
(*        be monitored as a mutually exclusive source.     *)
(*        This method should be called on startup to       *)
(*        assign each source based asset to an index for   *)
(*        source usage monitoring.                         *)
(*                                                         *)
(*        Mutually exclusive source usage tracking only    *)
(*        allows a single sources asset to be active at    *)
(*        any given time.  When using mutually exclusive   *)
(*        source tracking, you the implementation          *)
(*        programmer are only responsible for 'Activating' *)
(*        the newly selected source.  The RMS source usage *)
(*        tracking module will automatically 'Deactivate'  *)
(*        all other currently activated mutually exclusive *)
(*        sources.                                         *)
(*                                                         *)
(*        NOTE:  If you combine both mutually exclusive    *)
(*               and non-mutually exclusive source usage   *)
(*               registrations, then be aware that you     *)
(*               cannot reuse index number.  Each source   *)
(*               usage asset but be assiged exclusively    *)
(*               to a single index number.                 *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageAssignAssetMutExcl(INTEGER index, DEV sourceDevice)
{
  STACK_VAR CHAR commandString[RMS_MAX_CMD_LEN];

  commandString = RmsPackCmdHeader('SOURCE.ASSIGN');
  commandString = RmsPackCmdParam(commandString,ITOA(index));
  commandString = RmsPackCmdParam(commandString,RmsDevToString(sourceDevice));
  commandString = RmsPackCmdParam(commandString,ITOA(TRUE)); // set mutually exclusive flag

  SEND_COMMAND vdvRMSSourceUsage, commandString;
}


(***********************************************************)
(* Name:  RmsSourceUsageActivateSource                     *)
(* Args:  sourceIndex - index of source to be activated    *)
(*                                                         *)
(* Desc:  This function is used to 'Activate' a source     *)
(*        by it's index number.  This function will        *)
(*        activate either a mutually exclusive or non-     *)
(*        mutually exclusive tracked source asset.         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageActivateSource(INTEGER index)
{
  STACK_VAR CHAR commandString[RMS_MAX_CMD_LEN];
  commandString = RmsPackCmdHeader('SOURCE.ACTIVATE');
  commandString = RmsPackCmdParam(commandString,ITOA(index));
  SEND_COMMAND vdvRMSSourceUsage, commandString;
}


(***********************************************************)
(* Name:  RmsSourceUsageDeactivateSource                   *)
(* Args:  sourceIndex - index of source to be deactivated  *)
(*                                                         *)
(* Desc:  This function is used to 'Deactivate' a source   *)
(*        by it's index number.  This function will        *)
(*        deactivate either a mutually exclusive or non-   *)
(*        mutually exclusive tracked source asset.         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageDeactivateSource(INTEGER index)
{
  STACK_VAR CHAR commandString[RMS_MAX_CMD_LEN];
  commandString = RmsPackCmdHeader('SOURCE.DEACTIVATE');
  IF(index > 0)
  {
    commandString = RmsPackCmdParam(commandString,ITOA(index));
  }
  SEND_COMMAND vdvRMSSourceUsage, commandString;
}


(***********************************************************)
(* Name:  RmsSourceUsageDeactivateSource                   *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function is used to 'Deactivate' all        *)
(*        currently active source assets.  This function   *)
(*        deactivates all mutually exclusive and  non-     *)
(*        mutually exclusive tracked source asset.         *)
(***********************************************************)
DEFINE_FUNCTION RmsSourceUsageDeactivateAllSources()
{
  SEND_COMMAND vdvRMSSourceUsage, 'SOURCE.DEACTIVATE';
}


(***********************************************************)
(*                MODULE CODE GOES BELOW                   *)
(***********************************************************)

//
// Source Usage Monitoring Module
//
// - include only one of these source usage modules if you wish to support
//   source usage monitoring for assets.
//
DEFINE_MODULE 'RmsSourceUsageMonitor' mdlRmsSourceUsageMonitorMod(vdvRMS,vdvRMSSourceUsage);


(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

#WARN 'README: RMS source usage assignment requirements'
//
// THE NETLINX PROGRAMMER WILL NEED TO IMPLEMENT THE ASSIGNMENT
// OF SOURCES TO RMS ASSET DEVICES AT THE STARTUP OF THE NETLINX
// PROGRAM.  IT IS RECOMMENDED TO COPY THIS BLOCK OF CODE TO THE
// DEFINE_START SECTION OF YOUR PROGRAM AND MODIFY IT TO MEET THE
// SPECIFIC IMPLEMENTATION REQUIREMENTS OF YOUR PROJECT.
//
/*

  #WARN 'Assign all assets that should participate in source usage tracking here ...'

  // add all assets to tracked for source usage
  //
  // using the mutually exclusive assignment method means that
  // only a single mutually exclusive source can be active at
  // any given time.  If a source asset is activated, then all
  // other mutually exclusive configured source assets will
  // be automatically deactivated.

  RmsSourceUsageAssignAssetMutExcl(1, dvDSS);
  RmsSourceUsageAssignAssetMutExcl(2, dvDVR);
  RmsSourceUsageAssignAssetMutExcl(3, dvDiscDevice);
  RmsSourceUsageAssignAssetMutExcl(4, dvDocCamera);

  // if you have sources that are not mutually exclusive and may track
  // source usage concurrently, independant from mutually exclusive
  // sources, then use the following command to register those
  // source assets.  If you have a scenario where the are mutiple
  // sources that can be dispalyed on mutiple displays such as is the
  // case using a matrix switcher, then it is best to use this non-
  // mutually exclusive source usage tracking method and manually
  // maintain the source activated states in your business implementation
  // code.
  //
  // <EXAMPLE> RmsSourceUsageAssignAsset(1, dvDSS);
  // <EXAMPLE> RmsSourceUsageAssignAsset(2, dvDVR);

  // reset all sources on program startup
  RmsSourceUsageReset();
*/


  #WARN 'README: RMS source usage programming notes'
  // ----------------------------------------------------------------------
  //
  // you are responsible for manually ACTIVATING and DEACTIVATING
  // the sources in your NetLinx program.  The source usage
  // module provide an easy channel API and simply send command API
  // for managing the selected sources.  This include file also provides
  // convenience functions for this purpose.
  //
  // ----------------------------------------------------------------------
  //
  // ACTIVATING A SOURCE
  //
  // <EXAMPLE>  ON[vdvRMSSourceUsage, 1]
  //            (this will activate the source at index #1.)
  //
  // <EXAMPLE>  SEND_COMMAND vdvRMSSourceUsage, 'SOURCE.ACTIVATE-1'
  //            (this will activate the source at index #1.)
  //
  // <EXAMPLE>  RmsSourceUsageActivateSource(1)
  //            (this will activate the source at index #1.)
  //
  // ----------------------------------------------------------------------
  //
  // DEACTIVATING A SOURCE
  //
  // <EXAMPLE>  OFF[vdvRMSSourceUsage, 1]
  //            (this will deactivate the source at index #1.)
  //
  // <EXAMPLE>  SEND_COMMAND vdvRMSSourceUsage, 'SOURCE.DEACTIVATE-1'
  //            (this will deactivate the source at index #1.)
  //
  // <EXAMPLE>  RmsSourceUsageDeactivateSource(1)
  //            (this will deactivate the source at index #1.)
  //
  // ----------------------------------------------------------------------

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)

