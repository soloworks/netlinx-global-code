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
MODULE_NAME='RmsSourceUsageMonitor'(DEV vdvRMS,
                                    DEV vdvRMSSourceUsage)

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This NetLinx module contains the source code for asset *)
(*  source usage tracking in RMS.                          *)
(*                                                         *)
(*  This module allows the tracking of multiple sources    *)
(*  as independant sources or sources associated in        *)
(*  a mutually exclusive group.  This module will          *)
(*  track the time the source has been active and forward  *)
(*  the usage information to the RMS server at regular     *)
(*  intervals.  The module will send source usage          *)
(*  information to RMS immediately when a source is        *)
(*  deactivated.                                           *)
(*                                                         *)
(*  All sources that should have usage tracking must be    *)
(*  registered with this RmsSourceUsageMonitor module.     *)
(*  Please see the sample code in RmsSourceUsage.AXI       *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(*  NON-MUTUALLY EXCLUSIVE SOURCE USAGE TRACKING           *)
(***********************************************************)
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
(*        devices that can accept a variety of different   *)
(*        selected sources.                                *)
(*                                                         *)
(*        NOTE:  If you combine both mutually exclusive    *)
(*               and non-mutually exclusive source usage   *)
(*               registrations, then be aware that you     *)
(*               cannot reuse index number.  Each source   *)
(*               usage asset must be assigned exclusively  *)
(*               to a single index number.                 *)
(*                                                         *)
(***********************************************************)

(***********************************************************)
(*  MUTUALLY EXCLUSIVE SOURCE USAGE TRACKING               *)
(***********************************************************)
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

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

CHAR MONITOR_NAME[]       = 'RMS Source Usage Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'RmsSourceUsageMon';
CHAR MONITOR_VERSION[]    = '4.6.7';

// source usage send command headers
CHAR RMS_SOURCE_USAGE_COMMAND_ASSIGN_SOURCE[] = 'SOURCE.ASSIGN';
CHAR RMS_SOURCE_USAGE_COMMAND_ACTIVATE_SOURCE[] = 'SOURCE.ACTIVATE';
CHAR RMS_SOURCE_USAGE_COMMAND_DEACTIVATE_SOURCE[] = 'SOURCE.DEACTIVATE';
CHAR RMS_SOURCE_USAGE_COMMAND_RESET_SOURCE[] = 'SOURCE.RESET';

// the asset parameter name, key, descruiption, and units for the source usage parameter
CHAR RMS_ASSET_PARAM_KEY_SOURCE_USAGE[]   = 'source.usage';
CHAR RMS_ASSET_PARAM_NAME_SOURCE_USAGE[]  = 'Source Usage';
CHAR RMS_ASSET_PARAM_DESC_SOURCE_USAGE[]  = 'Amount of time this source has been in use since last reset.';
CHAR RMS_ASSET_PARAM_UNITS_SOURCE_USAGE[] = 'hours';

// level API constants
INTEGER SOURCE_USAGE_MAX_INDEX_LEVEL = 1;

// maximum number of source assets this module can monitor
#WARN 'Set the maximum number of source assets'
INTEGER MAX_SOURCE_ASSETS = 20;

// this constant defines the number of minutes
// that this module will buffer up usage time
// before sending the data to the RMS server.
INTEGER SOURCE_USAGE_HOLDTIME_MINUTES = 5;

// RMS Source Usage Monitoring Timeline
INTEGER TL_MONITOR = 101;
LONG    SourceUsageMonitoringTimeArray[1] = {60000}; // must be set to 1 minute (60000 ms)


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

// subscribe to the version request event notification callback
// this callback event will invoke the 'RmsEventVersionRequest' method
#DEFINE INCLUDE_RMS_EVENT_VERSION_REQUEST_CALLBACK

// include RmsEventListener (which also includes RMS API)
#INCLUDE 'RmsEventListener';


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

// data type for asset source usage tracking
STRUCTURE RmsAssetSourceUsage
{
  CHAR sourceDevice[50];
  CHAR assetClientKey[50];
  CHAR mutuallyExclusive
  INTEGER usageMinutes;
  INTEGER attemptCounter;
  CHAR activated;
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

// variables for asset source usage tracking
VOLATILE RmsAssetSourceUsage sourceAssets[MAX_SOURCE_ASSETS];
VOLATILE INTEGER maxAssignedSourceAssetIndex;


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
(* Args:  assetClientKey - unique identifier key for each  *)
(*                         asset.                          *)
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
DEFINE_FUNCTION RmsEventAssetRegistered(CHAR assetClientKey[], LONG assetId, CHAR newAssetRegistration, CHAR registeredAssetDps[])
{
  INTEGER index;
  FLOAT usageHours;

  // This function will listen for each asset key that is registered to RMS
  // and then attempt a lookup on the key in the source usage tracking
  // collection of source assets and if a match is found, then it will
  // register the additional source usage asset parameter with RMS and
  // then maintain parameter value updates as the source usage changes.

  // lookup the source asset
  index = GetSourceAssetIndex(registeredAssetDps);
  IF (index == 0) 
  {
    index = GetSourceAssetIndex(assetClientKey);
  }

  // if a source asset was found, then add/update the source usage parameter
  IF(index > 0)
  {
    // if client key was not previously set, update it
    IF (sourceAssets[index].assetClientKey == '')
    {
	    sourceAssets[index].assetClientKey = assetClientKey;
    }

    // if the client key was not just updated, check to ensure it matches
    // if the client key does not match, this asset has the same DPS, but is actually different
    // if client key does not match return
    IF (sourceAssets[index].assetClientKey != assetClientKey)
    {
	    RETURN;
    }    

    IF(newAssetRegistration)
    {
      // this is a new asset registration, register the
      // source usage monitoring parameter now.
      IF (sourceAssets[index].usageMinutes > 0)
      {
        usageHours = sourceAssets[index].usageMinutes / 60;
      }
      ELSE
      {
        usageHours = 0;
      }

      // source usage parameter
      IF(RmsAssetParameterEnqueueDecimal(assetClientKey,
                                     RMS_ASSET_PARAM_KEY_SOURCE_USAGE,
                                     RMS_ASSET_PARAM_NAME_SOURCE_USAGE,
                                     RMS_ASSET_PARAM_DESC_SOURCE_USAGE,
                                     RMS_ASSET_PARAM_TYPE_SOURCE_USAGE,
                                     usageHours,
                                     0,0,
                                     RMS_ASSET_PARAM_UNITS_SOURCE_USAGE,
                                     RMS_ALLOW_RESET_YES,
                                     0,
                                     RMS_TRACK_CHANGES_YES) == TRUE)
      {
        // submit all parameter registrations
        IF(RmsAssetParameterSubmit(assetClientKey) == TRUE)
        {
          // reset the source asset minute counter
          sourceAssets[index].usageMinutes = 0;
        }
      }
    }
    ELSE
    {
      // this is an existing asset registration, register/
      // update only asset monitoring parameters that may have
      // changed in value.
      IF (sourceAssets[index].usageMinutes > 0)
      {
        usageHours = sourceAssets[index].usageMinutes / 60;
        
        // send an incremental update to the source usage parameter for this asset
        IF(RmsAssetParameterUpdateValue(assetClientKey,
                                        RMS_ASSET_PARAM_KEY_SOURCE_USAGE,
                                        RMS_ASSET_PARAM_UPDATE_OPERATION_INCREMENT,
                                        FTOA(usageHours)) == TRUE)
        {
            // if the update was successful, then reset the usage and attempt counters
            sourceAssets[index].usageMinutes = 0;
            sourceAssets[index].attemptCounter = 0;
        }
      }
    }
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
  SEND_STRING 0, "'[',MONITOR_DEBUG_NAME,'-',RmsDevToString(vdvRMSSourceUSage),'] ',data";
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
  SEND_STRING 0, "name,' : ',MONITOR_VERSION,' (',RmsDevToString(vdvRMSSourceUsage),')'";
}

(***********************************************************)
(* Name:  HasSourceAsset                                   *)
(* Args:  sourceDevice - source device DPS                 *)
(*                                                         *)
(* Desc:  This function is used to determine if the asset  *)
(*        key identifier exists in the tracked set of      *)
(*        source usage monitored assets.   This function   *)
(*        simply returns a TRUE or FALSE bit.              *)
(***********************************************************)
DEFINE_FUNCTION CHAR HasSourceAsset(CHAR sourceDevice[])
{
  IF(GetSourceAssetIndex(sourceDevice) > 0)
  {
    RETURN TRUE;
  }
  ELSE
  {
    RETURN FALSE;
  }
}


(***********************************************************)
(* Name:  GetSourceAssetIndex                              *)
(* Args:  sourceDevice - source device DPS                 *)
(*                                                         *)
(* Desc:  This function is used to perform a lookup of an  *)
(*        asset key identifier in the tracked collection   *)
(*        of source usage monitored assets.  This function *)
(*        will return the index of the asset in the set if *)
(*        a match is found.  If no match is found, then    *)
(*        this function will return a '0' value.           *)
(***********************************************************)
DEFINE_FUNCTION INTEGER GetSourceAssetIndex(CHAR sourceDevice[])
{
  STACK_VAR INTEGER index;

  // iterate over the source assets and return the index if a match is found
  FOR(index = 1; index <= maxAssignedSourceAssetIndex; index++)
  {
    IF(sourceDevice == sourceAssets[index].sourceDevice)
    {
      RETURN index;
    }
  }

  // not found
  RETURN 0;
}


(***********************************************************)
(* Name:  ResetAllActiveSources                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function is used to deactivcate and reset   *)
(*        all source selected asset tracking.  Call this   *)
(*        method anytime a condition exists where are      *)
(*        selected sources should be de-selected and no    *)
(*        active sources apply.                            *)
(***********************************************************)
DEFINE_FUNCTION INTEGER ResetAllActiveSources()
{
  STACK_VAR INTEGER index;

  // iterate over the source assets and reset any activated sources
  FOR(index = 1; index <= maxAssignedSourceAssetIndex; index++)
  {
    IF(sourceAssets[index].activated)
    {
      DEBUG("'deactivating and resetting source asset #',ITOA(index),' [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,']'");
      sourceAssets[index].activated = FALSE;
    }
    sourceAssets[index].usageMinutes = 0;
    sourceAssets[index].attemptCounter = 0;

    // update channel API, if needed
    IF([vdvRMSSourceUsage,index] != sourceAssets[index].activated)
    {
      [vdvRMSSourceUsage,index] = sourceAssets[index].activated;
    }
  }

  // not found
  RETURN 0;
}


(***********************************************************)
(* Name:  SendSourceAssetUsageToRms                        *)
(* Args:  sourceAsset - data structure containing the      *)
(*                      source asset usage information     *)
(*                                                         *)
(* Desc:  This function is used to transmit the            *)
(*        accumulated source usage for a specific source   *)
(*        asset to the RMS server via the RMS virtual      *)
(*        device interface.                                *)
(***********************************************************)
DEFINE_FUNCTION CHAR SendSourceAssetUsageToRms(RmsAssetSourceUsage sourceAsset)
{
  STACK_VAR FLOAT usageHours;
            FLOAT usageMinutes;

  IF(sourceAsset.sourceDevice != '' &&
     sourceAsset.activated &&
     sourceAsset.usageMinutes > 0)
  {
    // only send if RMS is ONLINE and in asset management mode
    IF([vdvRMS,RMS_CHANNEL_CLIENT_REGISTERED] &&
       [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
    {
      usageMinutes = TYPE_CAST(sourceAsset.usageMinutes)
      usageHours =  (usageMinutes / 60);

      DEBUG("'sending accumulated source usage for asset [sourceDevice: ',sourceAsset.sourceDevice,', assetClientKey: ',sourceAsset.assetClientKey,']  / increment by [',FTOA(usageHours),'] hours'");

      // send an incremental update to the source usage parameter for this asset
      IF(RmsAssetParameterUpdateValue(sourceAsset.assetClientKey,
                                    RMS_ASSET_PARAM_KEY_SOURCE_USAGE,
                                    RMS_ASSET_PARAM_UPDATE_OPERATION_INCREMENT,
                                    FTOA(usageHours)) == TRUE)
      {
        // if the update was successful, then reset the usage and attempt counters
        sourceAsset.usageMinutes = 0;
        sourceAsset.attemptCounter = 0;

        // success
        RETURN TRUE;
      }
    }
  }

  // unsuccessful
  RETURN FALSE;
}


(***********************************************************)
(* Name:  DeactivateMutuallyExclusiveSources               *)
(* Args:  skipSourceIndex - if this value is greater than  *)
(*                          '0' and within the range of    *)
(*                           available source indexes then *)
(*                           this source asset deactivation*)
(*                           will be skipped .             *)
(*                                                         *)
(* Desc:  This function is used to deactivate all the      *)
(*        currently active mutually exclusive source       *)
(*        assets.  Any source that is deactivated will     *)
(*        also immediately send it's source usage to RMS   *)
(***********************************************************)
DEFINE_FUNCTION DeactivateMutuallyExclusiveSources(INTEGER skipSourceIndex)
{
  STACK_VAR INTEGER index;

  // iterate over the source assets and reset any activated sources
  // that are configured as mutually exclusive sources
  FOR(index = 1; index <= maxAssignedSourceAssetIndex; index++)
  {
    IF(index != skipSourceIndex)
    {
      IF(sourceAssets[index].mutuallyExclusive &&
   sourceAssets[index].activated)
      {
        DEBUG("'deactivating mutually exclusive source asset #',ITOA(index),' [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,']'");

  // send any pending changes to RMS server
  SendSourceAssetUsageToRms(sourceAssets[index]);

  // deactivate the source asset
  sourceAssets[index].activated = FALSE;

  // update channel API, if needed
  IF([vdvRMSSourceUsage,index] != sourceAssets[index].activated)
  {
     [vdvRMSSourceUsage,index] = sourceAssets[index].activated;
  }
      }
    }
  }
}


(***********************************************************)
(* Name:  DeactivateAllSources                             *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function is used to 'Deactivate' all        *)
(*        currently active soruce assets.  This function   *)
(*        deactivates all mutually exclusive and  non-     *)
(*        mutually exclusive tracked source asset.         *)
(*        Any source that is deactivated will also         *)
(*        immediately send it's source usage to RMS.       *)
(***********************************************************)
DEFINE_FUNCTION DeactivateAllSources()
{
  STACK_VAR INTEGER index;

  DEBUG('deactivating all source assets');

  // iterate over the source assets and deactivate any activated sources
  FOR(index = 1; index <= maxAssignedSourceAssetIndex; index++)
  {
    IF(sourceAssets[index].activated)
    {
      DEBUG("'deactivating source asset #',ITOA(index),' [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,']'");

      // send any pending changes to RMS server
      SendSourceAssetUsageToRms(sourceAssets[index]);

      // deactivate the source asset
      sourceAssets[index].activated = FALSE;

      // update channel API, if needed
      IF([vdvRMSSourceUsage,index] != sourceAssets[index].activated)
      {
        [vdvRMSSourceUsage,index] = sourceAssets[index].activated;
      }
    }
  }
}


(***********************************************************)
(* Name:  SelectSource                                     *)
(* Args:  sourceIndex - index of source to be activated    *)
(*        selected - boolean (bit) instructing whether to  *)
(*                   activate (true) or deactivate (false) *)
(*                   the target source usage asset.        *)
(*                                                         *)
(* Desc:  This function is used to 'Activate' or           *)
(*        'Deactivate' a source usage asset by it's index  *)
(*        number.  This is also known as 'Selecting' a     *)
(*        source.   This function will activate or         *)
(*        deactivate either a mutually exclusive or non-   *)
(*        mutually exclusive tracked source asset.         *)
(*                                                         *)
(*        If activating a source asset index that is a     *)
(*        mutually exclusive source, then all other        *)
(*        sources configured as mutually exclusive will    *)
(*        be automatically deactivated.                    *)
(*                                                         *)
(*        Any source that is deactivated will also         *)
(*        immediately send it's source usage to RMS.       *)
(***********************************************************)

(***********************************************************)
DEFINE_FUNCTION SelectSource(INTEGER index, CHAR selected)
{
  // if a source asset was found, then add/update the source usage parameter
  IF(index > 0 && index <= maxAssignedSourceAssetIndex)
  {
    // if this source is already in the selected state,
    // then skip any further processing
    IF(sourceAssets[index].activated == selected)
    {
      RETURN;
    }

    // ensure an asset has been assigned to this source asset index
    IF(sourceAssets[index].sourceDevice != '')
    {
      DEBUG("'select source asset #',ITOA(index),' [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,'] / activated: [',RmsBooleanString(selected),']'");

      // send any pending changes to RMS server
      SendSourceAssetUsageToRms(sourceAssets[index]);

      // activate/deactivate selected source asset
      sourceAssets[index].activated = selected;

      // deactivate all asset sources that are configured as mutually exclusive
      IF(selected && sourceAssets[index].mutuallyExclusive)
      {
        DeactivateMutuallyExclusiveSources(index);
      }
    }
  }
}


(***********************************************************)
(* Name:  ActivateSource                                   *)
(* Args:  sourceIndex - index of source to be activated    *)
(*                                                         *)
(* Desc:  This function is used to 'Activate' a source     *)
(*        by it's index number.  This function will        *)
(*        activate either a mutually exclusive or non-     *)
(*        mutually exclusive tracked source asset.         *)
(***********************************************************)
DEFINE_FUNCTION ActivateSource(INTEGER index)
{
  ON[vdvRMSSourceUsage, index];
}


(***********************************************************)
(* Name:  DeactivateSource                                 *)
(* Args:  sourceIndex - index of source to be deactivated  *)
(*                                                         *)
(* Desc:  This function is used to 'Deactivate' a source   *)
(*        by it's index number.  This function will        *)
(*        deactivate either a mutually exclusive or non-   *)
(*        mutually exclusive tracked source asset.         *)
(***********************************************************)
DEFINE_FUNCTION DeactivateSource(INTEGER index)
{
  OFF[vdvRMSSourceUsage, index];
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
// (SOURCE USAGE COMMAND EVENT HANDLERS)
//
//  handle incoming command events
//
DATA_EVENT[vdvRMSSourceUsage]
{
  COMMAND:
  {
    STACK_VAR CHAR sourceCmdHeader[RMS_MAX_HDR_LEN];
              CHAR sourceCmdParam1[RMS_MAX_PARAM_LEN];
              CHAR sourceCmdParam2[RMS_MAX_PARAM_LEN];
              CHAR sourceCmdParam3[RMS_MAX_PARAM_LEN];
              INTEGER index;

    sourceCmdHeader = RmsParseCmdHeader(DATA.TEXT);
    sourceCmdHeader = UPPER_STRING(sourceCmdHeader);

    SELECT
    {
      //
      // (SOURCE USAGE  - ASSIGN ASSET)
      //
      // upon receiving this assignment command, the assets
      // should be added to the internal source tracking
      // array.
      //
      ACTIVE (sourceCmdHeader == RMS_SOURCE_USAGE_COMMAND_ASSIGN_SOURCE):
      {
        sourceCmdParam1 = RmsParseCmdParam(DATA.TEXT); // source index
        sourceCmdParam2 = RmsParseCmdParam(DATA.TEXT); // source device
        sourceCmdParam3 = RmsParseCmdParam(DATA.TEXT); // sourge is mutually exclusive

        // ensure that argument data was provided
        IF(LENGTH_STRING(sourceCmdParam1) > 0 && LENGTH_STRING(sourceCmdParam2) > 0)
        {
          // get index
          index = ATOI(sourceCmdParam1);

          // validate index bounds
          IF(index > 0 && index <= MAX_SOURCE_ASSETS)
          {
            // track the highest assigned index to optimize
            // array looping and bounds checking routines
            IF(index > maxAssignedSourceAssetIndex)
            {
              maxAssignedSourceAssetIndex = index;

              // update level API
              SEND_LEVEL vdvRMSSourceUsage, SOURCE_USAGE_MAX_INDEX_LEVEL, maxAssignedSourceAssetIndex

              // create & start the source usage monitoring timeline
              IF(!TIMELINE_ACTIVE(TL_MONITOR))
              {
                TIMELINE_CREATE(TL_MONITOR,SourceUsageMonitoringTimeArray,1,TIMELINE_RELATIVE,TIMELINE_REPEAT);
              }
            }

            // add the new source to the source tracking array
            sourceAssets[index].sourceDevice = sourceCmdParam2;
            sourceAssets[index].usageMinutes = 0;
            sourceAssets[index].mutuallyExclusive = (ATOI(sourceCmdParam3));
            sourceAssets[index].activated = FALSE;

            IF(sourceAssets[index].mutuallyExclusive)
      {
        DEBUG("'source asset [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,'] assigned to source index [',sourceCmdParam1,'], source is mutually exclusive.'");
      }
      ELSE
      {
        DEBUG("'source asset [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,'] assigned to source index [',sourceCmdParam1,'], source is not mutually exclusive.'");
      }
          }
        }
      }

      //
      // (SOURCE USAGE  - RESET SELECTED SOURCE)
      //
      // upon receiving this reset command, all source assets
      // source tracking should be reset.
      //
      ACTIVE (sourceCmdHeader == RMS_SOURCE_USAGE_COMMAND_RESET_SOURCE):
      {
        ResetAllActiveSources();
      }


      //
      // (SOURCE USAGE  - ACTIVATE SELECTED SOURCE)
      //
      // upon receiving this activate command, the specified source index
      // should be activated for source usage tracking and reporting.
      //
      ACTIVE (sourceCmdHeader == RMS_SOURCE_USAGE_COMMAND_ACTIVATE_SOURCE):
      {
        sourceCmdParam1 = RmsParseCmdParam(DATA.TEXT);  // source index

        // get index
        index = ATOI(sourceCmdParam1);

        // validate index bounds
        IF(index > 0 && index <= maxAssignedSourceAssetIndex)
        {
          ActivateSource(index);
        }
      }


      //
      // (SOURCE USAGE  - DEACTIVATE SELECTED SOURCE)
      //
      // upon receiving this deactivate command, the specified source index
      // should be deactivated from source usage tracking and reporting.
      //
      ACTIVE (sourceCmdHeader == RMS_SOURCE_USAGE_COMMAND_DEACTIVATE_SOURCE):
      {
        sourceCmdParam1 = RmsParseCmdParam(DATA.TEXT);  // source index

        // if an index was provided, then deactivate that source
        // else deactivate all sources
        IF(sourceCmdParam1 == '')
        {
          DeactivateAllSources();
        }
        ELSE
        {
          // get index
          index = ATOI(sourceCmdParam1);

          // validate index bounds
          IF(index > 0 && index <= maxAssignedSourceAssetIndex)
          {
            DeactivateSource(index);
          }
        }
      }
    }
  }
}


// channel API
CHANNEL_EVENT[vdvRMSSourceUsage,0]
{
  ON:
  {
    IF(CHANNEL.CHANNEL > 0 && CHANNEL.CHANNEL <= maxAssignedSourceAssetIndex)
    {
      // activate source
      SelectSource(CHANNEL.CHANNEL, TRUE);
    }
  }
  OFF:
  {
    IF(CHANNEL.CHANNEL > 0 && CHANNEL.CHANNEL <= maxAssignedSourceAssetIndex)
    {
      // deactivate source
      SelectSource(CHANNEL.CHANNEL, FALSE);
    }
  }
}


// when this minute time fires, we need to increment each
// activated source to accumulate source usage minutes
TIMELINE_EVENT[TL_MONITOR]
{
  STACK_VAR INTEGER index;

  // iterate over the source assets and send the accumulated source usage
  // information to RMS for any activated sources
  FOR(index = 1; index <= maxAssignedSourceAssetIndex; index++)
  {
    IF(sourceAssets[index].sourceDevice != '' &&
       sourceAssets[index].activated)
    {
      // increment the usage minute counter by 1 minute
      sourceAssets[index].usageMinutes++;

      // increment the attempt counter by 1 minute
      sourceAssets[index].attemptCounter++;

      DEBUG("'source asset #',ITOA(index),' [sourceDevice: ',sourceAssets[index].sourceDevice,', assetClientKey: ',sourceAssets[index].assetClientKey,'] is active, incrementing minute count to [',ITOA(sourceAssets[index].usageMinutes),']'");

      // if we have met or exceeded the holdback time, then send the update to RMS now
      IF(sourceAssets[index].attemptCounter >= SOURCE_USAGE_HOLDTIME_MINUTES)
      {
        // reset attempt counter
        sourceAssets[index].attemptCounter = 0;

        // send any pending changes to RMS server
        SendSourceAssetUsageToRms(sourceAssets[index]);
      }
    }
  }
}


(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM
