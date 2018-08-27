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
PROGRAM_NAME='RmsEventListener'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file is used to listen to the RMS client  *)
(*  virtual device events and invoke callback methods when *)
(*  a RMS event occurs.                                    *)
(*                                                         *)
(*  Each event callback method can be exposed to the       *)
(*  consuming program by including the respective #DEFINE  *)
(*  compiler directive.  Please see the list of available  *)
(*  event directives below.  If a #DEFINE event directive  *)
(*  in enabled, then the implementation callback method    *)
(*  must exists in the consuming code base, else the       *)
(* program node will fail to compile.                      *)
(***********************************************************)

// this is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_EVENT_LISTENER__
#DEFINE __RMS_EVENT_LISTENER__


(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

// include RMS API
#INCLUDE 'RmsApi';

/*
-------------------------------------------------------------------------------
Please note all the RMS event callback function signatures below associated
with their respective compiler directives.  If you wish to implement any of
these event in your code, then make sure to include this file, provide the
'vdvRMS' visual device interface to the RMS client, declare the desired
compiler directives for each event you wish to subscribe to, and copy the
event callback method to your implementation code.
-------------------------------------------------------------------------------


// #DEFINE INCLUDE_RMS_EVENT_EXCEPTION_CALLBACK
DEFINE_FUNCTION RmsEventException(CHAR exceptionMessage[], CHAR commandHeader[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_CLIENT_ONLINE_CALLBACK
DEFINE_FUNCTION RmsEventClientOnline()
{
}

// #DEFINE INCLUDE_RMS_EVENT_CLIENT_OFFLINE_CALLBACK
DEFINE_FUNCTION RmsEventClientOffline()
{
}

// #DEFINE INCLUDE_RMS_EVENT_CLIENT_REGISTERED_CALLBACK
DEFINE_FUNCTION RmsEventClientRegistered()
{
}

// #DEFINE INCLUDE_RMS_EVENT_CLIENT_STATE_CHANGE_CALLBACK
DEFINE_FUNCTION RmsEventClientStateChanged(CHAR oldState[], CHAR newState[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_VERSION_REQUEST_CALLBACK
DEFINE_FUNCTION RmsEventVersionRequest()
{
}

// #DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_CALLBACK
DEFINE_FUNCTION RmsEventSystemPowerChanged(CHAR powerOn)
{
}

// #DEFINE INCLUDE_RMS_EVENT_SYSTEM_POWER_REQUEST_CALLBACK
DEFINE_FUNCTION RmsEventSystemPowerChangeRequest(CHAR powerOn)
{
}

// #DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_CALLBACK
DEFINE_FUNCTION RmsEventSystemModeChanged(CHAR newMode[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_SYSTEM_MODE_REQUEST_CALLBACK
DEFINE_FUNCTION RmsEventSystemModeChangeRequest(CHAR newMode[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_LOCATION_INFORMATION_CALLBACK
DEFINE_FUNCTION RmsEventLocationInformation(CHAR isClientDefaultLocation, LONG locationId, CHAR locationName[], CHAR additionalParameters[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_CONFIGURATION_CHANGE_CALLBACK
DEFINE_FUNCTION RmsEventConfigurationPropertyChange(CHAR propertyName[], CHAR propertyValue[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSETS_REGISTER_CALLBACK
DEFINE_FUNCTION RmsEventRegisterAssets()
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_REGISTERED_CALLBACK
DEFINE_FUNCTION RmsEventAssetRegistered(CHAR assetClientKey[], LONG assetId, CHAR newAssetRegistration, CHAR registeredAssetDps[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_RELOCATED_CALLBACK
DEFINE_FUNCTION RmsEventAssetRelocated(CHAR assetClientKey[], LONG assetId, LONG newLocationId)
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_PARAM_UPDATE_CALLBACK
DEFINE_FUNCTION RmsEventAssetParameterUpdate(CHAR assetClientKey[], CHAR parameterKey[], CHAR changeOperator[], CHAR changeValue[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_PARAM_VALUE_CHANGE_CALLBACK
DEFINE_FUNCTION RmsEventAssetParameterValueChange(CHAR assetClientKey[], CHAR parameterKey[], CHAR parameterName[], CHAR parameterValue[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_PARAM_RESET_CALLBACK
DEFINE_FUNCTION RmsEventAssetParameterReset(CHAR assetClientKey[], CHAR parameterKey[], CHAR parameterName[], CHAR parameterValue[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_ASSET_METHOD_EXECUTE_CALLBACK
DEFINE_FUNCTION RmsEventAssetControlMethodExecute(CHAR assetClientKey[], CHAR methodKey[], CHAR methodArguments[])
{
}

// #DEFINE INCLUDE_RMS_EVENT_HOTLIST_RECORD_COUNT_CALLBACK
DEFINE_FUNCTION RmsEventHotlistRecordCount(CHAR isClientDefaultLocation, LONG locationId, INTEGER recordCount)
{
}

// #DEFINE INCLUDE_RMS_EVENT_DISPLAY_MESSAGE_CALLBACK
DEFINE_FUNCTION RmsEventDisplayMessage(CHAR type[], CHAR title[], CHAR body[], INTEGER timeoutSeconds, CHAR modal, CHAR responseMessage, LONG locationId, CHAR isDefaultLocation)
{
}

// # DEFINE INCLUDE_RMS_EVENT_CUSTOM_COMMAND_CALLBACK
DEFINE_FUNCTION RmsEventCustomCommand(CHAR header[], CHAR data[])
{
}

(***********************************************************)
(* Name:  RmsEventClientLocationsAssociatedResponse        *)
(* Args:                                                   *)
(* RmsLocation location - A structure with location        *)
(*       information                                       *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query to get the client associated     *)
(* location for the  given location ID.                    *)
(*                                                         *)
(***********************************************************)
// # DEFINE INCLUDE_RMS_EVENT_CLIENT_LOC_ASSOC_RESP_CALLBACK
DEFINE_FUNCTION RmsEventClientLocationAssociatedResponse(RmsLocation location)
{
}

(***********************************************************)
(* Name:  RmsEventClientLocationsAssociatedResponse        *)
(* Args:                                                   *)
(* RmsLocation location - A structure with location        *)
(*       information                                       *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query to get all locations associated  *)
(* with the client.                                        *)
(*                                                         *)
(***********************************************************)
// # DEFINE INCLUDE_RMS_EVENT_CLIENT_LOCS_ASSOC_RESP_CALLBACK
DEFINE_FUNCTION RmsEventClientLocationsAssociatedResponse(RmsLocation location)
{
}

*/

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT


//
// (RMS EVENT NOTIFICATION HANDLERS)
//
// All RMS events are advertised to the NetLinx program
// via SEND_COMMANDS.
//
DATA_EVENT[vdvRMS]
{
  COMMAND:
  {
    STACK_VAR CHAR rmsHeader[RMS_MAX_HDR_LEN];

    //
    // parse RMS command header
    //
    rmsHeader = RmsParseCmdHeader(DATA.TEXT);
    rmsHeader = UPPER_STRING(rmsHeader);

    SELECT
    {
      // (RMS EXCEPTION/ERROR EVENT NOTIFICATION)
      //
      // upon receiving the exception/error notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_EXCEPTION_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_EXCEPTION):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 1 : <exception-message>  (STRING)
        // PARAM 2 : <command-header>     (STRING)
        RmsEventException(rmsParam1,rmsParam2);
      }
      #END_IF

      // (RMS CLIENT ONLINE EVENT NOTIFICATION)
      //
      // upon receiving the client online notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_ONLINE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_CLIENT_ONLINE):
      {
        // invoke the callback method
        RmsEventClientOnline();
      }
      #END_IF

      // (RMS CLIENT OFFLINE EVENT NOTIFICATION)
      //
      // upon receiving the client offline notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_OFFLINE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_CLIENT_OFFLINE):
      {
        // invoke the callback method
        RmsEventClientOffline();
      }
      #END_IF

      // (RMS CLIENT REGISTERED EVENT NOTIFICATION)
      //
      // upon receiving the client registration notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_REGISTERED_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_CLIENT_REGISTERED):
      {
        // invoke the callback method
        RmsEventClientRegistered();
      }
      #END_IF

      // (RMS CLIENT STATE CHANGE EVENT NOTIFICATION)
      //
      // upon receiving the client state transition change notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_STATE_CHANGE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_CLIENT_STATE_TRANSITION):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 1 : <old-state>     (STRING)
        // PARAM 2 : <new-state>     (STRING)
        RmsEventClientStateChanged(rmsParam1,rmsParam2);
      }
      #END_IF

      // (RMS VERSION REQUEST EVENT NOTIFICATION)
      //
      // upon receiving the version request notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_VERSION_REQUEST_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_VERSION_REQUEST):
      {
        // invoke the callback method
        RmsEventVersionRequest();
      }
      #END_IF

      //
      // (RMS SYSTEM POWER ON/OFF EVENT NOTIFICATION)
      //
      // upon receiving the system power ON/OFF notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_SYSTEM_POWER_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_POWER_ON):
      {
        // invoke the callback method
        //
        // PARAM 1 : <power-on-state>  (BOOLEAN)
        RmsEventSystemPowerChanged(TRUE);
      }
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_POWER_OFF):
      {
        // invoke the callback method
        //
        // PARAM 1 : <power-on-state>  (BOOLEAN)
        RmsEventSystemPowerChanged(FALSE);
      }
      #END_IF

      //
      // (RMS SYSTEM POWER ON/OFF REQUEST EVENT NOTIFICATION)
      //
      // upon receiving the system power ON/OFF request notification
      // from the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_SYSTEM_POWER_REQUEST_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_POWER_REQUEST_ON):
      {
        // invoke the callback method
        //
        // PARAM 1 : <requested-power-on-state>  (BOOLEAN)
        RmsEventSystemPowerChangeRequest(TRUE);
      }
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_POWER_REQUEST_OFF):
      {
        // invoke the callback method
        //
        // PARAM 1 : <requested-power-on-state>  (BOOLEAN)
        RmsEventSystemPowerChangeRequest(FALSE);
      }
      #END_IF


      //
      // (RMS SYSTEM MODE CHANGE EVENT NOTIFICATION)
      //
      // upon receiving the system mode change notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_SYSTEM_MODE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_MODE_CHANGE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 1 : <new-mode>  (STRING)
        RmsEventSystemModeChanged(rmsParam1);
      }
      #END_IF

      //
      // (RMS SYSTEM MODE CHANGE REQUEST EVENT NOTIFICATION)
      //
      // upon receiving the system mode change request notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_SYSTEM_MODE_REQUEST_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_SYSTEM_MODE_CHANGE_REQUEST):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 1 : <new-mode>  (STRING)
        RmsEventSystemModeChangeRequest(rmsParam1);
      }
      #END_IF

      //
      // (RMS LOCATION INFORMATION EVENT NOTIFICATION)
      //
      // upon receiving the location information notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_LOCATION_INFORMATION_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_LOCATION_INFORMATION):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 2 : <is-client-default-loc>  (BOOLEAN)
        // PARAM 2 : <location-id>            (LONG)
        // PARAM 3 : <location-name>          (STRING)
        // PARAM 4 : <additional-parameters>  (STRING)
        //
        // The additional parameters argument contains the
        // following element still packed in a comma delimited
        // string.  It is up to the consumer to unpack this
        // information if needed.
        //
        //           <location-owner>          (STRING)
        //           <location-phone-number>   (STRING)
        //           <location-occupancy>      (INTEGER)
        //           <location-prestige-name>  (STRING)
        //           <location-timezone>       (STRING)
        //           <location-asset-licensed> (BOOLEAN)
        //
        RmsEventLocationInformation(RmsBooleanValue(rmsParam1),ATOI(rmsParam2),rmsParam3,DATA.TEXT);
      }
      #END_IF

      //
      // (RMS CONFIGURATION CHANGE EVENT NOTIFICATION)
      //
      // upon receiving the configuration property change notification from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CONFIGURATION_CHANGE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_CONFIGURATION_CHANGE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);

        // invoke the callback method
        //
        // PARAM 1 : <property-name>   (STRING)
        // PARAM 2 : <property-value>  (STRING)
        RmsEventConfigurationPropertyChange(rmsParam1,rmsParam2);
      }
      #END_IF

      //
      // (RMS REGISTER ASSETS EVENT NOTIFICATION)
      //
      // upon receiving the assets register notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSETS_REGISTER_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSETS_REGISTER):
      {
          // invoke the callback method
          RmsEventRegisterAssets();
      }
      #END_IF

      //
      // (RMS ASSET REGISTERED EVENT NOTIFICATION)
      //
      // upon receiving the asset registered notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_REGISTERED_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_REGISTERED):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam4[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);
        rmsParam4 = RmsParseCmdParam(DATA.TEXT);
	
	// invoke callback method
        //
        // PARAM 1 : <asset-client-key>  (STRING)
        // PARAM 2 : <asset-id>          (LONG)
        // PARAM 3 : <new-registration>  (BOOLEAN)
	// PARAM 3 : <asset-dps>  	 (STRING)
        RmsEventAssetRegistered(rmsParam1,ATOI(rmsParam2),RmsBooleanValue(rmsParam3),rmsParam4);
      }
      #END_IF

      //
      // (RMS ASSET RELOCATED EVENT NOTIFICATION)
      //
      // upon receiving the asset relocated notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_RELOCATED_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_RELOCATED):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <asset-client-key>  (STRING)
        // PARAM 2 : <asset-id>          (LONG)
        // PARAM 3 : <new-location-id>   (LONG)
        RmsEventAssetRelocated(rmsParam1,ATOI(rmsParam2),ATOI(rmsParam3));
      }
      #END_IF

      //
      // (RMS ASSET PARAMETER UPDATE EVENT NOTIFICATION)
      //
      // upon receiving the asset parameter update notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_PARAM_UPDATE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_PARAM_UPDATE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam4[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);
        rmsParam4 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <asset-client-key>  (STRING)
        // PARAM 2 : <parameter-key>     (STRING)
        // PARAM 3 : <change-operator>   (STRING)
        // PARAM 4 : <change-value>      (STRING)
        RmsEventAssetParameterUpdate(rmsParam1,rmsParam2,rmsParam3,rmsParam4);
      }
      #END_IF

      //
      // (RMS ASSET PARAMETER VALUE CHANGE EVENT NOTIFICATION)
      //
      // upon receiving the asset parameter value change notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_PARAM_VALUE_CHANGE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_PARAM_VALUE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam4[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);
        rmsParam4 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <asset-client-key>  (STRING)
        // PARAM 2 : <parameter-key>     (STRING)
        // PARAM 3 : <parameter-name>    (STRING)
        // PARAM 4 : <parameter-value>   (STRING)
        RmsEventAssetParameterValueChange(rmsParam1,rmsParam2,rmsParam3,rmsParam4);
      }
      #END_IF

      //
      // (RMS ASSET PARAMETER VALUE RESET EVENT NOTIFICATION)
      //
      // upon receiving the asset parameter value reset notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_PARAM_RESET_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_PARAM_RESET):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam4[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);
        rmsParam4 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <asset-client-key>  (STRING)
        // PARAM 2 : <parameter-key>     (STRING)
        // PARAM 3 : <parameter-name>    (STRING)
        // PARAM 4 : <parameter-value>   (STRING)
        RmsEventAssetParameterReset(rmsParam1,rmsParam2,rmsParam3,rmsParam4);
      }
      #END_IF

      //
      // (RMS ASSET CONTROL METHOD EXECUTION EVENT NOTIFICATION)
      //
      // upon receiving the asset control method execution notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_ASSET_METHOD_EXECUTE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_ASSET_METHOD_EXECUTE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <asset-client-key>        (STRING)
        // PARAM 2 : <method-key>              (STRING)
        // PARAM 3 : <method-argument-values>  (STRING)
        RmsEventAssetControlMethodExecute(rmsParam1,rmsParam2,DATA.TEXT);
      }
      #END_IF

      //
      // (RMS HOTLIST COUNT EVENT NOTIFICATION)
      //
      // upon receiving the hotlist record count notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_HOTLIST_RECORD_COUNT_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_HOTLIST_RECORD_COUNT):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <is-client-default-loc>  (BOOLEAN)
        // PARAM 2 : <location-id>            (LONG)
        // PARAM 3 : <record-count>           (INTEGER)
        RmsEventHotlistRecordCount(RmsBooleanValue(rmsParam1),ATOI(rmsParam2),ATOI(rmsParam3));
      }
      #END_IF

      //
      // (RMS DISPALY MESSAGE EVENT NOTIFICATION)
      //
      // upon receiving the display message notification from
      // the RMS client relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_DISPLAY_MESSAGE_CALLBACK
      ACTIVE (rmsHeader == RMS_EVENT_DISPLAY_MESSAGE):
      {
        STACK_VAR CHAR rmsParam1[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam2[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam3[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam4[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam5[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam6[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam7[RMS_MAX_PARAM_LEN];
        STACK_VAR CHAR rmsParam8[RMS_MAX_PARAM_LEN];

        rmsParam1 = RmsParseCmdParam(DATA.TEXT);
        rmsParam2 = RmsParseCmdParam(DATA.TEXT);
        rmsParam3 = RmsParseCmdParam(DATA.TEXT);
        rmsParam4 = RmsParseCmdParam(DATA.TEXT);
        rmsParam5 = RmsParseCmdParam(DATA.TEXT);
        rmsParam6 = RmsParseCmdParam(DATA.TEXT);
        rmsParam7 = RmsParseCmdParam(DATA.TEXT);
        rmsParam8 = RmsParseCmdParam(DATA.TEXT);

        // invoke callback method
        //
        // PARAM 1 : <message-type>               (STRING)
        // PARAM 2 : <message-title>              (STRING)
        // PARAM 3 : <message-body>               (STRING)
        // PARAM 4 : <message-timeout-seconds>    (INTEGER)
        // PARAM 5 : <message-modal>              (BOOLEAN)
        // PARAM 6 : <response-message>           (BOOLEAN)
        // PARAM 7 : <location-id>                (LONG)
        // PARAM 8 : <id-default-location>        (BOOLEAN)
        RmsEventDisplayMessage(rmsParam1,
                               rmsParam2,
                               rmsParam3,
                               ATOI(rmsParam4),
                               RmsBooleanValue(rmsParam5),
                               RmsBooleanValue(rmsParam6),
                               ATOI(rmsParam7),
                               RmsBooleanValue(rmsParam8));
      }
      #END_IF

      // (RMS CUSTOM COMMAND EVENT NOTIFICATION)
      //
      // upon receiving a user custom relay command from
      // the RMS client, relay this event to any event subscribers
      //
      #IF_DEFINED INCLUDE_RMS_EVENT_CUSTOM_COMMAND_CALLBACK
      ACTIVE (LEFT_STRING(rmsHeader,1) == '@'):
      {
        // invoke the callback method
        RmsEventCustomCommand(rmsHeader, DATA.TEXT);
      }
      #END_IF


      ACTIVE(1):
      {
       // do nothing
       // this is a placeholder in case no events subscriptions were declared
      }
    }
  }
}

// ***************************************************************************
//
// [CUSTOM EVENT] CLIENT GATEWAY QUERY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_CLIENT_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_CLIENT,
             RMS_CUSTOM_EVENT_CLIENT_INFORMATION]
{
  STACK_VAR RmsClientGateway clientGateway;

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to client gateway structure
    STRING_TO_VARIABLE(clientGateway, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventClientGatewayInformationResponse(clientGateway)
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] CLIENT GATEWAY LOCATION QUERY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_CLIENT_LOCATION_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_CLIENT,
             RMS_CUSTOM_EVENT_CLIENT_LOCATION_INFORMATION]
{
  STACK_VAR RmsLocation location;

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(location, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventClientLocationInformationResponse(location)
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] LOCATION INFORMATION UPDATE EVENT
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_LOCATION_INFORMATION_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_LOCATION,
             RMS_CUSTOM_EVENT_LOCATION_INFORMATION]
{
  STACK_VAR RmsLocation location;
  STACK_VAR LONG locationId;
  STACK_VAR CHAR isClientDefaultLocation;

  // the 'value1' member of the custom data event
  //  stores event the default client location state
  isClientDefaultLocation = TYPE_CAST(custom.value1);

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(location, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventLocationInformation2(location, isClientDefaultLocation)
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] ASSET RELOCATED EVENT
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_ASSET_RELOCATED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_ASSET,
             RMS_CUSTOM_EVENT_ASSET_RELOCATED]
{
  STACK_VAR RmsLocation location;
  STACK_VAR CHAR isClientDefaultLocation;
  STACK_VAR CHAR assetClientKey[50];
  STACK_VAR LONG assetId;

  // the 'value1' member of the custom data event
  //  stores event the default client location state
  isClientDefaultLocation = TYPE_CAST(custom.value1);

  // the 'value2' member of the custom data event
  //  stores event the asset id
  assetId = TYPE_CAST(custom.value2);

  // the 'text' member of the custom data event
  //  stores event the asset client key
  assetClientKey = custom.text;

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(location, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventAssetRelocated2(assetClientKey, assetId, location, isClientDefaultLocation)
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] DISPLAY MESSAGE RECEIVED EVENT
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_DISPLAY_MESSAGE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_DISPLAY_MESSAGE,
             RMS_CUSTOM_EVENT_DISPLAY_MESSAGE]
{
  STACK_VAR RmsDisplayMessage displayMessage;
  STACK_VAR CHAR isClientDefaultLocation;

  // the 'value1' member of the custom data event
  //  stores event the default client location state
  isClientDefaultLocation = TYPE_CAST(custom.value1);

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(displayMessage, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventDisplayMessage2(displayMessage, isClientDefaultLocation)
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] EXECUTE ASSET CONTROL METHOD EVENT
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_CUSTOM_EVENT_ASSET_METHOD_EXECUTE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_ASSET,
             RMS_CUSTOM_EVENT_ASSET_METHOD_EXECUTE]
{
  STACK_VAR RmsAssetControlMethod controlMethod;
  STACK_VAR LONG argumentCount;

  // the 'value1' property of the custom data
  //  event stores the number of method argument
  argumentCount = TYPE_CAST(custom.value1);

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // set the array size based on the argument count
    // this will prepare the array to accept the encoded data
    SET_LENGTH_ARRAY(controlMethod.argumentValues, argumentCount);

    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(controlMethod, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventAssetControlMethodExecute2(controlMethod);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] RMS_CUSTOM_EVENT_CLIENT_LOCATION_ASSOCIATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_LOCATION_ASSOCIATED_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_CLIENT,
             RMS_CUSTOM_EVENT_CLIENT_LOCATION_ASSOCIATED]
{
  STACK_VAR RmsLocation location;

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(location, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventClientLocationAssociatedResponse(location)
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] RMS_CUSTOM_EVENT_CLIENT_LOCATIONS_ASSOCIATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_RMS_EVENT_CLIENT_LOCATIONS_ASSOCIATED_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_CLIENT,
             RMS_CUSTOM_EVENT_CLIENT_LOCATIONS_ASSOCIATED]
{
  STACK_VAR RmsLocation location;

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to location structure
    STRING_TO_VARIABLE(location, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventClientLocationsAssociatedResponse(location)
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

#END_IF // __RMS_EVENT_LISTENER__
