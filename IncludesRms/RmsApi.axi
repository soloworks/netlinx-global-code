
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
PROGRAM_NAME='RmsApi'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file is provided to implement many of     *)
(*  the RMS API channels, levels, and command strings as   *)
(*  constants and also to provide many helper functions    *)
(*  that can simplify NetLinx integration with the RMS     *)
(*  client.                                                *)
(*                                                         *)
(***********************************************************)

// this is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_API__
#DEFINE __RMS_API__

// include RmsMathUtil
#INCLUDE 'RmsMathUtil';

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//
// RMS API CHANNELS - CONTROL via PUSH
//
RMS_CHANNEL_SYSTEM_POWER_TOGGLE    = 9;
RMS_CHANNEL_SYSTEM_POWER_ON        = 27;
RMS_CHANNEL_SYSTEM_POWER_OFF       = 28;

//
// RMS API CHANNELS - FEEDBACK ONLY
//
RMS_CHANNEL_LICENSED_ASSETS        = 240;
//RMS_CHANNEL_LICENSED_SCHEDULING  = 241;
//RMS_CHANNEL_RESERVED             = 242;
//RMS_CHANNEL_RESERVED             = 243;
//RMS_CHANNEL_RESERVED             = 244;
//RMS_CHANNEL_RESERVED             = 245;
//RMS_CHANNEL_RESERVED             = 246;
RMS_CHANNEL_VERSION_REQUEST        = 247;
RMS_CHANNEL_ASSETS_REGISTER        = 249;
RMS_CHANNEL_CLIENT_ONLINE          = 250;
RMS_CHANNEL_CLIENT_REGISTERED      = 251;
//RMS_CHANNEL_RESERVED             = 252;
//RMS_CHANNEL_RESERVED             = 253;
//RMS_CHANNEL_RESERVED             = 254;
RMS_CHANNEL_SYSTEM_POWER           = 255;


//
// RMS API Levels
//
RMS_LEVEL_HOTLIST_ITEM_COUNT       = 1;

//
// RMS API Event Commands
//
RMS_EVENT_EXCEPTION                    = 'EXCEPTION';
RMS_EVENT_CLIENT_ONLINE                = 'CLIENT.ONLINE';
RMS_EVENT_CLIENT_OFFLINE               = 'CLIENT.OFFLINE';
RMS_EVENT_CLIENT_REGISTERED            = 'CLIENT.REGISTERED';
RMS_EVENT_CLIENT_STATE_TRANSITION      = 'CLIENT.CONNECTION.STATE.TRANSITION';
RMS_EVENT_VERSION_REQUEST              = '?VERSIONS';
RMS_EVENT_SYSTEM_POWER_ON              = 'SYSTEM.POWER.ON';
RMS_EVENT_SYSTEM_POWER_OFF             = 'SYSTEM.POWER.OFF';
RMS_EVENT_SYSTEM_POWER_REQUEST_ON      = 'SYSTEM.POWER.REQUEST.ON';
RMS_EVENT_SYSTEM_POWER_REQUEST_OFF     = 'SYSTEM.POWER.REQUEST.OFF';
RMS_EVENT_SYSTEM_MODE_CHANGE           = 'SYSTEM.MODE';
RMS_EVENT_SYSTEM_MODE_CHANGE_REQUEST   = 'SYSTEM.MODE.REQUEST';
RMS_EVENT_LOCATION_INFORMATION         = 'LOCATION';
RMS_EVENT_CONFIGURATION_CHANGE         = 'CONFIG.CHANGE';
RMS_EVENT_ASSETS_REGISTER              = 'ASSETS.REGISTER';
RMS_EVENT_ASSET_REGISTERED             = 'ASSET.REGISTERED';
RMS_EVENT_ASSET_RELOCATED              = 'ASSET.LOCATION.CHANGE';
RMS_EVENT_ASSET_PARAM_UPDATE           = 'ASSET.PARAM.UPDATE';
RMS_EVENT_ASSET_PARAM_VALUE            = 'ASSET.PARAM.VALUE';
RMS_EVENT_ASSET_PARAM_RESET            = 'ASSET.PARAM.RESET';
RMS_EVENT_ASSET_METHOD_EXECUTE         = 'ASSET.METHOD.EXECUTE';
RMS_EVENT_HOTLIST_RECORD_COUNT         = 'HOTLIST.COUNT';
RMS_EVENT_DISPLAY_MESSAGE              = 'MESSAGE.DISPLAY';
RMS_EVENT_DEVICE_AUTO_REGISTER         = 'CONFIG.DEVICE.AUTO.REGISTER';
RMS_EVENT_DEVICE_AUTO_REGISTER_REQUEST = '?CONFIG.DEVICE.AUTO.REGISTER';
RMS_EVENT_DEVICE_AUTO_REGISTER_FILTER         = 'CONFIG.DEVICE.AUTO.REGISTER.FILTER';
RMS_EVENT_DEVICE_AUTO_REGISTER_FILTER_REQUEST = '?CONFIG.DEVICE.AUTO.REGISTER.FILTER';


//
// RMS API Custom Event Addresses
//
RMS_CUSTOM_EVENT_ADDRESS_CLIENT           = 1;
RMS_CUSTOM_EVENT_ADDRESS_LOCATION         = 2;
RMS_CUSTOM_EVENT_ADDRESS_ASSET            = 3;
RMS_CUSTOM_EVENT_ADDRESS_DISPLAY_MESSAGE  = 4;
RMS_CUSTOM_EVENT_ADDRESS_SERVICE_PROVIDER = 5;
RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING    = 6;

//
// RMS API Custom Event IDs
//
RMS_CUSTOM_EVENT_CLIENT_INFORMATION          = 1;
RMS_CUSTOM_EVENT_CLIENT_LOCATION_INFORMATION = 2;
RMS_CUSTOM_EVENT_CLIENT_LOCATION_ASSOCIATED  = 3;
RMS_CUSTOM_EVENT_CLIENT_LOCATIONS_ASSOCIATED = 4;


// location custom events
RMS_CUSTOM_EVENT_LOCATION_INFORMATION     = 1;

// asset custom events
RMS_CUSTOM_EVENT_ASSET_INFORMATION        = 1;
RMS_CUSTOM_EVENT_ASSET_REGISTERED         = 2;
RMS_CUSTOM_EVENT_ASSET_RELOCATED          = 3;
RMS_CUSTOM_EVENT_ASSET_PARAMETER_UPDATE   = 101;
RMS_CUSTOM_EVENT_ASSET_PARAMETER_RESET    = 102;
RMS_CUSTOM_EVENT_ASSET_METADATA_UPDATE    = 200;
RMS_CUSTOM_EVENT_ASSET_METHOD_UPDATE      = 301;
RMS_CUSTOM_EVENT_ASSET_METHOD_REGISTERED  = 302;
RMS_CUSTOM_EVENT_ASSET_METHOD_EXECUTE     = 301;

// display message custom events
RMS_CUSTOM_EVENT_DISPLAY_MESSAGE          = 1;

// scheduling/booking custom events
RMS_CUSTOM_EVENT_BOOKING_INFORMATION      = 1;
RMS_CUSTOM_EVENT_BOOKING_STARTED          = 2;
RMS_CUSTOM_EVENT_BOOKING_ENDED            = 3;
RMS_CUSTOM_EVENT_BOOKING_EXTENDED         = 4;
RMS_CUSTOM_EVENT_BOOKING_CANCELED         = 5;
RMS_CUSTOM_EVENT_BOOKING_CREATED          = 6;


//
// RMS API Instruction Commands
//
RMS_COMMAND_VERSION_REQUEST        = '?VERSIONS';
RMS_COMMAND_HELP_REQUEST           = 'SERVICE.HELP.REQUEST';
RMS_COMMAND_MAINTENANCE_REQUEST    = 'SERVICE.MAINTENANCE.REQUEST';
RMS_COMMAND_SYSTEM_POWER_ON        = 'SYSTEM.POWER.ON';
RMS_COMMAND_SYSTEM_POWER_OFF       = 'SYSTEM.POWER.OFF';
RMS_COMMAND_SYSTEM_MODE            = 'SYSTEM.MODE';
RMS_COMMAND_REINITIALIZE           = 'CLIENT.REINIT';
RMS_COMMAND_LOCATION_ASSOCIATED    = '?CLIENT.LOCATION.ASSOCIATED';
RMS_COMMAND_LOCATIONS_ASSOCIATED   = '?CLIENT.LOCATIONS.ASSOCIATED';

// Maximum command header length for parsing/packing functions
#IF_NOT_DEFINED RMS_MAX_HDR_LEN
RMS_MAX_HDR_LEN       = 100
#END_IF

// Maximum parameter length for parsing/packing functions
#IF_NOT_DEFINED RMS_MAX_PARAM_LEN
RMS_MAX_PARAM_LEN     = 250
#END_IF

// Maximum command length for parsing/packing functions
#IF_NOT_DEFINED RMS_MAX_CMD_LEN
RMS_MAX_CMD_LEN       = 1000
#END_IF

//
// RMS Logging Levels
//
RMS_LOG_LEVEL_ERROR   = 1
RMS_LOG_LEVEL_WARNING = 2
RMS_LOG_LEVEL_INFO    = 3
RMS_LOG_LEVEL_DEBUG   = 4

//
// RMS Status Types
//
// (This is the default listing of status types built into RMS
//  Users can extend this list by adding custom status types in
//  the RMS application web user interface)
RMS_STATUS_TYPE_NOT_ASSIGNED             = 'NOT_ASSIGNED';
RMS_STATUS_TYPE_HELP_REQUEST             = 'HELP_REQUEST';
RMS_STATUS_TYPE_ROOM_COMMUNICATION_ERROR = 'ROOM_COMMUNICATION_ERROR';
RMS_STATUS_TYPE_CONTROL_SYSTEM_ERROR     = 'CONTROL_SYSTEM_ERROR';
RMS_STATUS_TYPE_MAINTENANCE              = 'MAINTENANCE';
RMS_STATUS_TYPE_EQUIPMENT_USAGE          = 'EQUIPMENT_USAGE';
RMS_STATUS_TYPE_NETWORK                  = 'NETWORK';
RMS_STATUS_TYPE_SECURITY                 = 'SECURITY';

//
// RMS Metadata Property Data Types
//
RMS_METADATA_TYPE_STRING    = 'STRING';
RMS_METADATA_TYPE_MEMO      = 'MEMO';
RMS_METADATA_TYPE_BOOLEAN   = 'BOOLEAN';
RMS_METADATA_TYPE_NUMBER    = 'NUMBER';
RMS_METADATA_TYPE_DECIMAL   = 'DECIMAL';
RMS_METADATA_TYPE_DATE      = 'DATE';
RMS_METADATA_TYPE_TIME      = 'TIME';
RMS_METADATA_TYPE_HYPERLINK = 'HYPERLINK';
RMS_METADATA_TYPE_DATETIME  = 'DATETIME';

//
// RMS Control Method Argument Data Types
//
RMS_METHOD_ARGUMENT_TYPE_NUMBER       = 'NUMBER';
RMS_METHOD_ARGUMENT_TYPE_STRING       = 'STRING';
RMS_METHOD_ARGUMENT_TYPE_ENUMERATION  = 'ENUMERATION';
RMS_METHOD_ARGUMENT_TYPE_LEVEL        = 'LEVEL';
RMS_METHOD_ARGUMENT_TYPE_BOOLEAN      = 'BOOLEAN';
RMS_METHOD_ARGUMENT_TYPE_DECIMAL      = 'DECIMAL';

//
// RMS Common Asset Keys
//
RMS_KEY_ASSET_ONLINE = 'asset.online';
RMS_KEY_ASSET_POWER  = 'asset.power';
RMS_KEY_ASSET_DATA_INITIALIZED = 'asset.data.initialized';

//
// RMS Asset Parameter Data Types
//
RMS_ASSET_PARAM_DATA_TYPE_NUMBER      = 'NUMBER';
RMS_ASSET_PARAM_DATA_TYPE_STRING      = 'STRING';
RMS_ASSET_PARAM_DATA_TYPE_ENUMERATION = 'ENUMERATION';
RMS_ASSET_PARAM_DATA_TYPE_LEVEL       = 'LEVEL';
RMS_ASSET_PARAM_DATA_TYPE_BOOLEAN     = 'BOOLEAN';
RMS_ASSET_PARAM_DATA_TYPE_DECIMAL     = 'DECIMAL';

//
// RMS Asset Parameter Update Operation
//
RMS_ASSET_PARAM_UPDATE_OPERATION_SET       = 'SET_VALUE';
RMS_ASSET_PARAM_UPDATE_OPERATION_INCREMENT = 'INCREMENT_VALUE';
RMS_ASSET_PARAM_UPDATE_OPERATION_DECREMENT = 'DECREMENT_VALUE';
RMS_ASSET_PARAM_UPDATE_OPERATION_DIVIDE    = 'DIVIDE_VALUE';
RMS_ASSET_PARAM_UPDATE_OPERATION_RESET     = 'RESET_VALUE';

//
// RMS Asset Parameter (Reporting) Types
//
RMS_ASSET_PARAM_TYPE_NONE                   = 'NONE';
RMS_ASSET_PARAM_TYPE_ASSET_ONLINE           = 'ASSET_ONLINE';
RMS_ASSET_PARAM_TYPE_ASSET_POWER            = 'ASSET_POWER';
RMS_ASSET_PARAM_TYPE_POWER_CONSUMPTION      = 'POWER_CONSUMPTION';
RMS_ASSET_PARAM_TYPE_ENVIONMENTAL_EMISSIONS = 'EMISSIONS';
RMS_ASSET_PARAM_TYPE_LAMP_USAGE             = 'LAMP_USAGE';
RMS_ASSET_PARAM_TYPE_BATTERY_LEVEL          = 'BATTERY_LEVEL';
RMS_ASSET_PARAM_TYPE_BATTERY_CHARGING_STATE = 'BATTERY_CHARGING_STATE';
RMS_ASSET_PARAM_TYPE_SOURCE_USAGE           = 'SOURCE_USAGE';
RMS_ASSET_PARAM_TYPE_SOURCE_STATE           = 'SOURCE_STATE'
RMS_ASSET_PARAM_TYPE_SYSTEM_ONLINE          = 'SYSTEM_ONLINE';
RMS_ASSET_PARAM_TYPE_SYSTEM_POWER           = 'SYSTEM_POWER';
RMS_ASSET_PARAM_TYPE_TRANSPORT_STATE        = 'TRANSPORT_STATE';
RMS_ASSET_PARAM_TYPE_TRANSPORT_USAGE        = 'TRANSPORT_USAGE';
RMS_ASSET_PARAM_TYPE_DISPLAY_USAGE          = 'DISPLAY_USAGE';
RMS_ASSET_PARAM_TYPE_TEMPERATURE            = 'TEMPERATURE';
RMS_ASSET_PARAM_TYPE_SECURITY_STATE         = 'SECURITY_STATE';
RMS_ASSET_PARAM_TYPE_LIGHT_LEVEL            = 'LIGHT_LEVEL';
RMS_ASSET_PARAM_TYPE_SIGNAL_STRENGTH        = 'SIGNAL_STRENGTH';
RMS_ASSET_PARAM_TYPE_HVAC_STATE             = 'HVAC_STATE';
RMS_ASSET_PARAM_TYPE_DIALER_STATE           = 'DIALER_STATE';
RMS_ASSET_PARAM_TYPE_DOCKING_STATE          = 'DOCKING_STATE';

//
// RMS Asset Parameter Threshold Comparison Operators
//
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_NONE             = 'NONE';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_LESS_THAN        = 'LESS_THAN';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_LESS_THAN_EQUAL  = 'LESS_THAN_EQUAL_TO';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN     = 'GREATER_THAN';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL = 'GREATER_THAN_EQUAL_TO';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL            = 'EQUAL_TO';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_NOT_EQUAL        = 'NOT_EQUAL_TO';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_CONTAINS         = 'CONTAINS';
RMS_ASSET_PARAM_THRESHOLD_COMPARISON_DOES_NOT_CONTAIN = 'DOES_NOT_CONTAIN';

//
// RMS Asset Parameter History Tracking
//
RMS_TRACK_CHANGES_YES = TRUE;
RMS_TRACK_CHANGES_NO  = FALSE;

//
// RMS Asset Parameter Reset
//
RMS_ALLOW_RESET_YES  = TRUE;
RMS_ALLOW_RESET_NO   = FALSE;

//
// RMS Display Message Types
//
RMS_DISPLAY_MESSAGE_TYPE_INFO     = 'INFORMATION';
RMS_DISPLAY_MESSAGE_TYPE_WARNING  = 'WARNING';
RMS_DISPLAY_MESSAGE_TYPE_SECURITY = 'SECURITY';
RMS_DISPLAY_MESSAGE_TYPE_CRITICAL = 'CRITICAL';
RMS_DISPLAY_MESSAGE_TYPE_QUESTION = 'QUESTION';

//
// RMS Asset Bargraph Keys
//
// (This is the default listing of asset bargraphs built into RMS
//  Users can extend this list by adding custom asset bargraphs in
//  the RMS application web user interface)
RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE   = 'general';
RMS_ASSET_PARAM_BARGRAPH_BATTERY_LEVEL     = 'battery.level';
RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL      = 'volume.level';
RMS_ASSET_PARAM_BARGRAPH_SIGNAL_STRENGTH   = 'signal.strength';
RMS_ASSET_PARAM_BARGRAPH_LIGHT_LEVEL       = 'light.level';
RMS_ASSET_PARAM_BARGRAPH_LAMP_CONSUMPTION  = 'lamp.consumption';
RMS_ASSET_PARAM_BARGRAPH_TEMPERATURE       = 'temperature';

//
// RMS Hotlist Record Types
//
RMS_HOTLIST_TYPE_CLIENT_GATEWAY        = 0;
RMS_HOTLIST_TYPE_PARAMETER_TRIP        = 1;
RMS_HOTLIST_TYPE_SERVICE_PROVIDER      = 2;
RMS_HOTLIST_TYPE_ASSET_MAINTENANCE     = 3;
RMS_HOTLIST_TYPE_LOCATION_MAINTENANCE  = 4;
RMS_HOTLIST_TYPE_USER                  = 5;
RMS_HOTLIST_TYPE_NOTIFICATION_PROVIDER = 6;
RMS_HOTLIST_TYPE_LOG_PROVIDER          = 7;
RMS_HOTLIST_TYPE_SCHEDULING            = 8;
RMS_HOTLIST_TYPE_MESSAGE               = 9;

//
// RMS Asset Types
//
// (This is the default listing of asset types built into RMS
//  Users can extend this list by adding custom asset types in
//  the RMS application web user interface)
CHAR RMS_ASSET_TYPE_DEVICE_CONTROLLER[]         = 'DeviceController'
CHAR RMS_ASSET_TYPE_TOUCH_PANEL[]               = 'TouchPanel'
CHAR RMS_ASSET_TYPE_CONTROL_SYSTEM[]            = 'ControlSystem'
CHAR RMS_ASSET_TYPE_SOURCE_USAGE[]              = 'SourceUsage'
CHAR RMS_ASSET_TYPE_UNKNOWN[]                   = 'Unknown'
CHAR RMS_ASSET_TYPE_AUDIO_CONFERENCER[]         = 'AudioConferencer'
CHAR RMS_ASSET_TYPE_AUDIO_MIXER[]               = 'AudioMixer'
CHAR RMS_ASSET_TYPE_AUDIO_PROCESSOR[]           = 'AudioProcessor'
CHAR RMS_ASSET_TYPE_AUDIO_TAPE[]                = 'AudioTape'
CHAR RMS_ASSET_TYPE_AUDIO_TUNER_DEVICE[]        = 'AudioTunerDevice'
CHAR RMS_ASSET_TYPE_CAMERA[]                    = 'Camera'
CHAR RMS_ASSET_TYPE_DIGITAL_MEDIA_DECODER[]     = 'DigitalMediaDecoder'
CHAR RMS_ASSET_TYPE_DIGITAL_MEDIA_ENCODER[]     = 'DigitalMediaEncoder'
CHAR RMS_ASSET_TYPE_DIGITAL_MEDIA_SERVER[]      = 'DigitalMediaServer'
CHAR RMS_ASSET_TYPE_DIGITAL_SATELLITE_SYSTEM[]  = 'DigitalSatelliteSystem'
CHAR RMS_ASSET_TYPE_DIGITAL_VIDEO_RECORDER[]    = 'DigitalVideoRecorder'
CHAR RMS_ASSET_TYPE_DISC_DEVICE[]               = 'DiscDevice'
CHAR RMS_ASSET_TYPE_DOCUMENT_CAMERA[]           = 'DocumentCamera'
CHAR RMS_ASSET_TYPE_HVAC[]                      = 'HVAC'
CHAR RMS_ASSET_TYPE_KEYPAD[]                    = 'Keypad'
CHAR RMS_ASSET_TYPE_LIGHT[]                     = 'Light'
CHAR RMS_ASSET_TYPE_MONITOR[]                   = 'Monitor'
CHAR RMS_ASSET_TYPE_MOTOR[]                     = 'Motor'
CHAR RMS_ASSET_TYPE_MULTI_WINDOW[]              = 'MultiWindow'
CHAR RMS_ASSET_TYPE_POOL_SPA[]                  = 'PoolSpa'
CHAR RMS_ASSET_TYPE_PRE_AMP_SURROUND_SOUND_PROCESSOR[] = 'PreAmpSurroundSoundProcessor'
CHAR RMS_ASSET_TYPE_RECEIVER[]                  = 'Receiver'
CHAR RMS_ASSET_TYPE_SECURITY_SYSTEM[]           = 'SecuritySystem'
CHAR RMS_ASSET_TYPE_SENSOR_DEVICE[]             = 'SensorDevice'
CHAR RMS_ASSET_TYPE_SETTOP_BOX[]                = 'SettopBox'
CHAR RMS_ASSET_TYPE_SLIDE_PROJECTOR[]           = 'SlideProjector'
CHAR RMS_ASSET_TYPE_SWITCHER[]                  = 'Switcher'
CHAR RMS_ASSET_TYPE_TEXT_KEYPAD[]               = 'TextKeypad'
CHAR RMS_ASSET_TYPE_TV[]                        = 'TV'
CHAR RMS_ASSET_TYPE_UTILITY[]                   = 'Utility'
CHAR RMS_ASSET_TYPE_VCR[]                       = 'VCR'
CHAR RMS_ASSET_TYPE_VIDEO_CONFERENCER[]         = 'VideoConferencer'
CHAR RMS_ASSET_TYPE_VIDEO_PROCESSOR[]           = 'VideoProcessor'
CHAR RMS_ASSET_TYPE_VIDEO_PROJECTOR[]           = 'VideoProjector'
CHAR RMS_ASSET_TYPE_VIDEO_WALL[]                = 'VideoWall'
CHAR RMS_ASSET_TYPE_VOLUME_CONTROLLER[]         = 'VolumeController'
CHAR RMS_ASSET_TYPE_WEATHER[]                   = 'Weather'
CHAR RMS_ASSET_TYPE_AMPLIFIER[]                 = 'Amplifier'
CHAR RMS_ASSET_TYPE_IO_DEVICE[]                 = 'IODevice'
CHAR RMS_ASSET_TYPE_RELAY_DEVICE[]              = 'RelayDevice'
CHAR RMS_ASSET_TYPE_UPS[]                       = 'UPS'
CHAR RMS_ASSET_TYPE_LIGHTSYSTEM[]               = 'LightSystem'
CHAR RMS_ASSET_TYPE_DISPLAY[]                   = 'Display'
CHAR RMS_ASSET_TYPE_POWER_DEVICE[]              = 'PowerDevice'
CHAR RMS_ASSET_TYPE_DISTANCE_TRANSPORT[]        = 'DistanceTransport'
CHAR RMS_ASSET_TYPE_DIGITAL_SIGNAGE_PLAYER[]    = 'DigitalSignagePlayer'

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

VOLATILE CHAR RMS_SYSTEM_POWER_ENABLED  = TRUE;
VOLATILE CHAR RMS_SYSTEM_POWER_DISABLED = FALSE;
VOLATILE CHAR RMS_SYSTEM_MODES_NONE[1]  = '';

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

//
// RMS Asset Data Structure
//
STRUCTURE RmsAsset
{
  CHAR assetType[50];
  CHAR clientKey[30];
  CHAR globalKey[150];
  CHAR name[50];
  CHAR description[250];
  CHAR manufacturerName[50];
  CHAR manufacturerUrl[250];
  CHAR modelName[50];
  CHAR modelUrl[250];
  CHAR serialNumber[100];
  CHAR firmwareVersion[30];
}

//
// RMS Asset Metadata Property Data Structure
//
STRUCTURE RmsAssetMetadataProperty
{
  CHAR key[50];
  CHAR name[50];
  CHAR value[50];
  CHAR dataType[30];
  CHAR readOnly;
  CHAR hyperlinkName[50];
  CHAR hyperlinkUrl[100];
}

//
// RMS Asset Control Method Data Structure
//
STRUCTURE RmsAssetControlMethodArgument
{
  INTEGER ordinal;
  CHAR name[50];
  CHAR description[250];
  CHAR dataType[30];
  CHAR defaultValue[30];
  SLONG minimumValue;
  SLONG maximumValue;
  INTEGER stepValue;
  CHAR enumerationValues[15][30];
}

//
// RMS Asset Parameter Data Structure
//
STRUCTURE RmsAssetParameter
{
  CHAR key[50];
  CHAR name[50];
  CHAR description[250];
  CHAR dataType[30];
  CHAR reportingType[30];
  CHAR initialValue[50];
  CHAR units[50];
  CHAR allowReset;
  CHAR resetValue[50];
  SLONG minimumValue;
  SLONG maximumValue;
  CHAR enumeration[500];
  CHAR trackChanges;
  CHAR bargraphKey[30];
  CHAR stockParam;
}

//
// RMS Asset Parameter Threshold Data Structure
//
STRUCTURE RmsAssetParameterThreshold
{
  CHAR name[50];
  CHAR enabled;
  CHAR statusType[30];
  CHAR comparisonOperator[30];
  CHAR value[50];
  CHAR notifyOnTrip;
  CHAR notifyOnRestore;
  INTEGER delayInterval;
}


//
// RMS Client Gateway Data Structure
//
STRUCTURE RmsClientGateway
{
  CHAR uid[100];
  CHAR name[100];
  CHAR hostname[100];
  CHAR ipAddress[50];
  CHAR ipPort[20];
  CHAR gateway[100];
  CHAR subnetMask[100];
  CHAR macAddress[100];
  CHAR sdkVersion[20];
  INTEGER communicationProtocol
  INTEGER communicationProtocolVersion
}

//
// RMS Location Data Structure
//
STRUCTURE RmsLocation
{
  INTEGER id;
  CHAR name[100];
  CHAR timezone[100];
  INTEGER occupancy;
  CHAR prestigeName[100];
  CHAR owner[100];
  CHAR phoneNumber[50];
  CHAR assetLicensed;
}


//
// RMS Display Message Data Structure
//
STRUCTURE RmsDisplayMessage
{
  CHAR type[100];
  CHAR title[250];
  CHAR message[2000];
  LONG timeout;
  CHAR isModal;
  CHAR isResponse;
  LONG locationId;
}


//
// RMS Asset Control Method Data Structure
//
STRUCTURE RmsAssetControlMethod
{
  CHAR assetClientKey[50];
  CHAR methodKey[50];
  CHAR argumentValues[20][250];  // MAX 20 ARGUMENTS
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  RmsGetEnumValue                                  *)
(* Args:  INTEGER nLookupIndex - Enum index                *)
(*        CHAR cEnumList[] - A CHAR array consisting of    *)
(* | delimited entries.                                    *)
(*                                                         *)
(* Desc:  Get the enum entry at position specified by      *)
(* nLookupIndex.                                           *)
(*                                                         *)
(* Rtrn:  The enum entry at the position specified or ""   *)
(* if it does not exist.                                   *)
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_PARAM_LEN] RmsGetEnumValue(INTEGER nLookupIndex, CHAR cEnumList[RMS_MAX_PARAM_LEN])
STACK_VAR
  INTEGER nIndex
  CHAR    cList[RMS_MAX_PARAM_LEN]
  CHAR    cTemp[RMS_MAX_PARAM_LEN]
{
  cList = "cEnumList,'|'";

  WHILE(LENGTH_STRING(cList))
  {
  nIndex++;
  cTemp = REMOVE_STRING(cList,'|',1);
  SET_LENGTH_STRING(cTemp,LENGTH_STRING(cTemp)-1);
  IF(nIndex = nLookupIndex)
    RETURN(cTemp);
  }

  RETURN("");
}

(***********************************************************)
(* Name:  RmsDevToString                                   *)
(* Args:  DEV dvDPS                                        *)
(*                                                         *)
(* Desc:  This function is used to convert a device        *)
(*        variable of type DEV to a string representation  *)
(*        using the <D>:<P>:<S> formatting syntax.         *)
(*                                                         *)
(* Rtrn:  DPS string; example "5001:1:0"                   *)
(***********************************************************)
DEFINE_FUNCTION CHAR[20] RmsDevToString(DEV dvDPS)
{
  RETURN "ITOA(dvDPS.Number),':',ITOA(dvDPS.Port),':',ITOA(dvDPS.System)"
}


(***********************************************************)
(* Name:  RmsDeviceIdInList                                *)
(* Args:  INTEGER devID - device ID (number) to search for *)
(*        INTEGER devList[] - device ID array to search in *)
(*                                                         *)
(* Desc:  This function is used to determine if a device   *)
(*        ID (number) is included in a list of devices IDs *)
(*                                                         *)
(* Rtrn:  index of the device in array; 0 if not found     *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsDeviceIdInList(INTEGER devId, INTEGER devList[])
{
  STACK_VAR INTEGER index;

  // iterate over the device ID listing and search
  // for a matching device ID, return if found.
  FOR(index = 1; index <= LENGTH_ARRAY(devList); index++)
  {
    IF(devList[index] == devId)
    {
      RETURN index;
    }
  }
  RETURN 0;
}


(***********************************************************)
(* Name:  RmsDeviceInList                                  *)
(* Args:  DEV devTarget - target device to search for      *)
(*        DEV devList[] - array of devices to search in    *)
(*                                                         *)
(* Desc:  This function is used to determine if a device   *)
(*        instance is included in an array of devices.     *)
(*                                                         *)
(* Rtrn:  index of the device in array; 0 if not found     *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsDeviceInList(DEV devTarget, DEV devList[])
{
  STACK_VAR INTEGER index;

  // NOTE: this function does not take the device SYSTEM number
  //       into account when evaluating a possible match.
  //       Data/Channel/Button event returned device instances
  //       may return the DPS structure with the real system
  //       number and the hard coded device definition only
  //       specified system '0'.

  // iterate over the device listing (array) and search
  // for a matching device instance, return index if found.
  FOR(index = 1; index <= LENGTH_ARRAY(devList); index++)
  {
    IF(devList[index].NUMBER == devTarget.NUMBER &&
       devList[index].PORT == devTarget.PORT)
    {
      RETURN index;
    }
  }
  RETURN 0;
}


(***********************************************************)
(* Name:  RmsDeviceStringInList                            *)
(* Args:  CHAR devTarget[] - target device to search for   *)
(*        DEV devList[] - array of devices to search in    *)
(*                                                         *)
(* Desc:  This function is used to determine if a device   *)
(*        D:P:S string is found in and array of devices.   *)
(*                                                         *)
(* Rtrn:  index of the device in array; 0 if not found     *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsDeviceStringInList(CHAR devTarget[], DEV devList[])
{
  STACK_VAR INTEGER index;

  // iterate over the device listing (array) and search
  // for a matching device instance, return index if found.
  FOR(index = 1; index <= LENGTH_ARRAY(devList); index++)
  {
    IF(RmsDevToString(devList[index]) == devTarget)
    {
      RETURN index;
    }
  }
  RETURN 0;
}


(***********************************************************)
(* Name:  RmsParseDPSFromString                            *)
(* Args:  CHAR cCmd[] (in) - target string to search in    *)
(*        DEV dvDPS (out)  - device to return              *)
(*                                                         *)
(* Desc:  This function is used to parse a string and      *)
(*        extract a D:P:S device instance.                 *)
(*                                                         *)
(* Rtrn:  -nothing-                                        *)
(***********************************************************)
DEFINE_FUNCTION RmsParseDPSFromString(CHAR cCmd[], DEV dvDPS)
STACK_VAR
INTEGER nPos
{
  dvDPS.Number = ATOI(cCmd)
  dvDPS.Port = 1
  dvDPS.System = 0
  nPos = FIND_STRING(cCmd,':',1)
  IF (nPos)
  {
    nPos++
    dvDPS.Port = ATOI(MID_STRING(cCmd,nPos,LENGTH_STRING(cCmd)-nPos+1))
    nPos = FIND_STRING(cCmd,':',nPos)
    IF (nPos)
    {
      nPos++
      dvDPS.System = ATOI(MID_STRING(cCmd,nPos,LENGTH_STRING(cCmd)-nPos+1))
    }
  }
}

(***********************************************************)
// Name   : ==== RmsPackCmdHeader ====
// Purpose:
// Params : (1) IN - sndcmd/str header
// Returns: Packed header with command separator added if missing
// Notes  : Adds the command header to the string and adds the command if missing
//          This function assumes the standard Duet command separator '-'
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_HDR_LEN] RmsPackCmdHeader(CHAR cHdr[])
{
  STACK_VAR CHAR cSep[1]
  cSep = '-'

  IF (RIGHT_STRING(cHdr,LENGTH_STRING(cSep)) != cSep)
      RETURN "cHdr,cSep";

  RETURN cHdr;
}


(***********************************************************)
// Name   : ==== RmsPackCmdParam ====
// Purpose: To package parameter for module send_command or send_string
// Params : (1) IN - sndcmd/str to which parameter will be added
//          (2) IN - sndcmd/str parameter
// Returns: Packed parameter wrapped in double-quotes if needed, added to the command
// Notes  : Wraps the parameter in double-quotes if it contains the separator
//          This function assumes the standard Duet parameter separator ','
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_CMD_LEN] RmsPackCmdParam(CHAR cCmd[], CHAR cParam[])
{
  STACK_VAR CHAR cTemp[RMS_MAX_CMD_LEN]
  STACK_VAR CHAR cTempParam[RMS_MAX_CMD_LEN]
  STACK_VAR CHAR cCmdSep[1]
  STACK_VAR CHAR cParamSep[1]
  STACK_VAR INTEGER nLoop
  cCmdSep = '-'
  cParamSep = ','

  // Not the first param?  Add the param separator
  cTemp = cCmd
  IF (FIND_STRING(cCmd,cCmdSep,1) != (LENGTH_STRING(cCmd)-LENGTH_STRING(cCmdSep)+1))
    cTemp = "cTemp,cParamSep"

  // Escape any quotes
  FOR (nLoop = 1; nLoop <= LENGTH_ARRAY(cParam); nLoop++)
  {
    IF (cParam[nLoop] == '"')
      cTempParam = "cTempParam,'"'"
    cTempParam = "cTempParam,cParam[nLoop]"
  }

  // Add the param, wrapped in double-quotes if needed
  IF (FIND_STRING(cTempParam,cParamSep,1) > 0)
      cTemp = "cTemp,'"',cTempParam,'"'"
  ELSE
      cTemp = "cTemp,cTempParam"

  RETURN cTemp;
}


(***********************************************************)
// Name   : ==== RmsPackCmdParamArray ====
// Purpose: To package parameters for module send_command or send_string
// Params : (1) IN - sndcmd/str to which parameter will be added
//          (2) IN - sndcmd/str parameter array
// Returns: packed parameters wrapped in double-quotes if needed
// Notes  : Wraps the parameter in double-quotes if it contains the separator
//          and separates them using the separator sequence
//          This function assumes the standard Duet parameter separator ','
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_CMD_LEN] RmsPackCmdParamArray(CHAR cCmd[], CHAR cParams[][])
{
  STACK_VAR CHAR    cTemp[RMS_MAX_CMD_LEN]
  STACK_VAR INTEGER nLoop
  STACK_VAR INTEGER nMax
  STACK_VAR CHAR cCmdSep[1]
  STACK_VAR CHAR cParamSep[1]
  cCmdSep = '-'
  cParamSep = ','

  nMax = LENGTH_ARRAY(cParams)
  IF (nMax == 0)
    nMax = MAX_LENGTH_ARRAY(cParams)

  cTemp = cCmd
  FOR (nLoop = 1; nLoop <= nMax; nLoop++)
    cTemp = RmsPackCmdParam(cTemp,cParams[nLoop])

  RETURN cTemp;
}


(***********************************************************)
// Name   : ==== RmsParseCmdHeader ====
// Purpose: To parse out parameters from module send_command or send_string
// Params : (1) IN/OUT  - sndcmd/str data
// Returns: parsed property/method name, still includes the leading '?' if present
// Notes  : Parses the strings sent to or from modules extracting the command header.
//          Command separating character assumed to be '-', Duet standard
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_HDR_LEN] RmsParseCmdHeader(CHAR cCmd[])
{
  STACK_VAR CHAR cTemp[RMS_MAX_HDR_LEN]
  STACK_VAR CHAR cSep[1]
  cSep = '-'

  // Assume the argument to be the command
  cTemp = cCmd

  // If we find the seperator, remove it from the command
  IF (FIND_STRING(cCmd,cSep,1) > 0)
  {
    cTemp = REMOVE_STRING(cCmd,cSep,1)
    IF (LENGTH_STRING(cTemp))
      cTemp = LEFT_STRING(cTemp,LENGTH_STRING(cTemp)-LENGTH_STRING(cSep))
  }

  // Did not find seperator, argument is the command (like ?SOMETHING)
  ELSE
    cCmd = ""

  RETURN cTemp;
}


(***********************************************************)
// Name   : ==== RMSDuetParseCmdParam ====
// Purpose: To parse out parameters from module send_command or send_string
// Params : (1) IN/OUT  - sndcmd/str data
// Returns: Parse parameter from the front of the string not including the separator
// Notes  : Parses the strings sent to or from modules extracting the parameters.
//          A single param is picked of the cmd string and removed, through the separator.
//          The separator is NOT returned from the function.
//          If the first character of the param is a double quote, the function will
//          remove up to (and including) the next double-quote and the separator without spaces.
//          The double quotes will then be stripped from the parameter before it is returned.
//          If the double-quote/separator sequence is not found, the function will remove up to (and including)
//          the separator character and the leading double quote will NOT be removed.
//          If the separator is not found, the entire remained of the command is removed.
//          Command separating character assumed to be ',', Duet standard
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_PARAM_LEN] RmsParseCmdParam(CHAR cCmd[])
{
  RETURN RmsParseCmdParamEx(cCmd, ',');
}


(***********************************************************)
// Name   : ==== RmsParseCmdParamEx ====
// Purpose: To parse out parameters from module send_command or send_string
// Params : (1) IN/OUT  - sndcmd/str data
//          (2) SEPARATOR  - delimiting character
// Returns: Parse parameter from the front of the string not including the separator
// Notes  : Parses the strings sent to or from modules extracting the parameters.
//          A single param is picked of the cmd string and removed, through the separator.
//          The separator is NOT returned from the function.
//          If the first character of the param is a double quote, the function will
//          remove up to (and including) the next double-quote and the separator without spaces.
//          The double quotes will then be stripped from the parameter before it is returned.
//          If the double-quote/separator sequence is not found, the function will remove up to (and including)
//          the separator character and the leading double quote will NOT be removed.
//          If the separator is not found, the entire remained of the command is removed.
(***********************************************************)
DEFINE_FUNCTION CHAR[RMS_MAX_PARAM_LEN] RmsParseCmdParamEx(CHAR cCmd[], CHAR separator)
{
  STACK_VAR CHAR cTemp[RMS_MAX_PARAM_LEN]
  STACK_VAR CHAR cSep[1]
  STACK_VAR CHAR chC
  STACK_VAR INTEGER nLoop
  STACK_VAR INTEGER nState
  STACK_VAR CHAR bInquotes
  STACK_VAR CHAR bDone
  cSep[1] = separator;

  // Reset state
  nState = 1; //ST_START
  bInquotes = FALSE;
  bDone = FALSE;

  // Loop the command and escape it
  FOR (nLoop = 1; nLoop <= LENGTH_ARRAY(cCmd); nLoop++)
  {
    // Grab characters and process it based on state machine
    chC = cCmd[nLoop];
    Switch (nState)
    {
      // Start or string: end of string bails us out
      CASE 1: //ST_START
      {
        // Starts with a quote?
        // If so, skip it, set flag and move to collect.
        IF (chC == '"')
        {
          nState = 2; //ST_COLLECT
          bInquotes = TRUE;
        }

        // Starts with a separator?  Empty param
        ELSE IF (chC == cSep)
        {
          // I am done
          bDone = TRUE;
        }

        // Not a quote or a comma?  Add it to the string and move to collection
        Else
        {
          cTemp = "cTemp, chC"
          nState = 2; //ST_COLLECT
        }
        BREAK;
      }

      // Collect string.
      CASE 2: //ST_COLLECT
      {
        // If in quotes, just grab the characters
        IF (bInquotes)
        {
          // Ah...found a quote, jump to end quote state
          IF (chC == '"' )
          {
            nState = 3; //ST_END_QUOTE
            BREAK;
          }
        }

        // Not in quotes, look for separator
        ELSE IF (chC == cSep)
        {
          // I am done
          bDone = TRUE;
          BREAK;
        }

        // Not in quotes, look for quotes (this would be wrong)
        // But instead of barfing, I will just add the quote (below)
        ELSE IF (chC == '"' )
        {
          // I will check to see if it should be escaped
          IF (nLoop < LENGTH_ARRAY(cCmd))
          {
            // If this is 2 uqotes back to back, just include the one
            IF (cCmd[nLoop+1] = '"')
              nLoop++;
          }
        }

        // Add character to collection
        cTemp = "cTemp,chC"
        BREAK;
      }

      // End Quote
      CASE 3: //ST_END_QUOTE
      {
        // Hit a seperator
        IF (chC == cSep)
        {
          // I am done
          bDone = TRUE;
        }

        // OK, found a quote right after another quote.  So this is escaped.
        ELSE IF (chC == '"')
        {
          cTemp = "cTemp,chC"
          nState = 2; //ST_COLLECT
        }
        BREAK;
      }
    }

    // OK, if end of string or done, process and exit
    IF (bDone == TRUE || nLoop >= LENGTH_ARRAY(cCmd))
    {
      // remove cTemp from cCmd
      cCmd = MID_STRING(cCmd, nLoop + 1, LENGTH_STRING(cCmd) - nLoop)

      // cTemp is done
      RETURN cTemp;
    }
  }

  // Well...we should never hit this
  RETURN "";
}


(***********************************************************)
(* Name:  RmsBooleanValue                                  *)
(* Args:  CHAR value[] - string to convert to char (bit)  *)
(*                                                         *)
(* Desc:  This function is used to parse a string and      *)
(*        return a char (bit) for boolean state.           *)
(*                                                         *)
(* Rtrn:  0 if string results in FALSE                     *)
(*        1 if string results in TRUE                      *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBooleanValue(CHAR value[])
{
  IF(LOWER_STRING(value) == 'true' || value=='1' || LOWER_STRING(value) == 'on' )
  {
    RETURN TRUE;
  }
  ELSE
  {
    RETURN FALSE;
  }
}


(***********************************************************)
(* Name:  RmsBooleanString                                 *)
(* Args:  CHAR value - convert bit to boolean string       *)
(*                                                         *)
(* Desc:  This function is used to convert a char (bit)    *)
(*        to a RMS boolean string of 'true' or 'false'.    *)
(*                                                         *)
(* Rtrn:  'false' if char value is 0                       *)
(*        'true'  if char value is >0                      *)
(***********************************************************)
DEFINE_FUNCTION CHAR[5] RmsBooleanString(CHAR value)
{
  IF(value)
  {
    RETURN 'true';
  }
  ELSE
  {
    RETURN 'false';
  }
}


(***********************************************************)
(* Name:  RmsAssetOnlineParameterEnqueue                   *)
(* Args:  CHAR assetClientKey[]                            *)
(*        INTEGER nOnline                                  *)
(*                                                         *)
(* Desc:  This function is used to queue an asset online   *)
(*        parameter for a speficied asset key.             *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetOnlineParameterEnqueue(CHAR assetClientKey[], INTEGER nOnline)
{
  STACK_VAR RmsAssetParameter parameter;
  STACK_VAR RmsAssetParameterThreshold threshold;

  // device device online parameter
  parameter.key = RMS_KEY_ASSET_ONLINE;
  parameter.name = 'Online Status';
  parameter.description = 'Current asset online or offline state';
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_ENUMERATION;
  parameter.enumeration = 'Offline|Online';
  parameter.allowReset = RMS_ALLOW_RESET_NO;
  parameter.stockParam = TRUE;
  parameter.reportingType = RMS_ASSET_PARAM_TYPE_ASSET_ONLINE;
  parameter.trackChanges = RMS_TRACK_CHANGES_YES;
  parameter.resetValue = 'Offline';
  IF(nOnline)
  {
    parameter.initialValue = 'Online';
  }
  ELSE
  {
    parameter.initialValue = 'Offline';
  }

  // enqueue parameter
  RmsAssetParameterEnqueue(assetClientKey, parameter);

  // populate default threshold settings
  threshold.name = 'Offline';
  threshold.comparisonOperator = RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL;
  threshold.value = 'Offline';
  threshold.statusType = RMS_STATUS_TYPE_ROOM_COMMUNICATION_ERROR;
  threshold.enabled = TRUE;
  threshold.notifyOnRestore = TRUE;
  threshold.notifyOnTrip = TRUE;

  // add a default threshold for the device online/offline parameter
  RmsAssetParameterThresholdEnqueueEx(assetClientKey,
                                      parameter.key,
                                      threshold)
}


(***********************************************************)
(* Name:  RmsAssetOnlineParameterUpdate                    *)
(* Args:  CHAR assetClientKey[]                            *)
(*        INTEGER nOnline                                  *)
(*                                                         *)
(* Desc:  This function is used to update an asset online  *)
(*        parameter for a speficied asset key.             *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetOnlineParameterUpdate(CHAR assetClientKey[], INTEGER nOnline)
{
  // update RMS parameter value for the device online parameter
  IF(nOnline)
  {
    RmsAssetParameterSetValue(assetClientKey,RMS_KEY_ASSET_ONLINE,'Online');
  }
  ELSE
  {
    RmsAssetParameterSetValue(assetClientKey,RMS_KEY_ASSET_ONLINE,'Offline');
  }
}


(***********************************************************)
(* Name:  RmsAssetDataInitializedParameterEnqueue          *)
(* Args:  CHAR assetClientKey[]                            *)
(*        CHAR dataInitialized                             *)
(*                                                         *)
(* Desc:  This function is used to queue an asset data     *)
(*        initialized parameter for a speficied asset key. *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetDataInitializedParameterEnqueue(CHAR assetClientKey[], CHAR dataInitialized)
{
  STACK_VAR RmsAssetParameter parameter;
  STACK_VAR RmsAssetParameterThreshold threshold;

  // device data initialized parameter
  parameter.key = RMS_KEY_ASSET_DATA_INITIALIZED;
  parameter.name = 'Device Data Initialized';
  parameter.description = 'Duet module data has been initialized';
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_BOOLEAN;
  parameter.allowReset = RMS_ALLOW_RESET_NO;
  parameter.stockParam = TRUE;
  parameter.reportingType = RMS_ASSET_PARAM_TYPE_NONE;
  parameter.trackChanges = RMS_TRACK_CHANGES_NO;

  IF(dataInitialized)
  {
    parameter.initialValue = 'true';
  }
  ELSE
  {
    parameter.initialValue = 'false';
  }

  // enqueue parameter
  RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetDataInitializedParameterUpdate           *)
(* Args:  CHAR assetClientKey[]                            *)
(*        CHAR dataInitialized                             *)
(*                                                         *)
(* Desc:  This function is used to update an asset data    *)
(*        initialized parameter for a speficied asset key. *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetDataInitializedParameterUpdate(CHAR assetClientKey[], CHAR dataInitialized)
{
  // update RMS parameter value for the device data initialized parameter
  RmsAssetParameterSetValueBoolean(assetClientKey,RMS_KEY_ASSET_DATA_INITIALIZED,dataInitialized);
}


(***********************************************************)
(* Name:  RmsAssetPowerParameterEnqueue                    *)
(* Args:  CHAR assetClientKey[]                            *)
(*        CHAR powerOn                                     *)
(*                                                         *)
(* Desc:  This function is used to queue an asset power    *)
(*        parameter for a speficied asset key.             *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetPowerParameterEnqueue(CHAR assetClientKey[], CHAR powerOn)
{
  STACK_VAR RmsAssetParameter parameter;

  // device asset power parameter
  parameter.key = RMS_KEY_ASSET_POWER;
  parameter.name = 'Power Status';
  parameter.description = 'Current asset power state';
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_ENUMERATION;
  parameter.enumeration = 'Off|On';
  parameter.allowReset = RMS_ALLOW_RESET_NO;
  parameter.stockParam = TRUE;
  parameter.reportingType = RMS_ASSET_PARAM_TYPE_ASSET_POWER;
  parameter.trackChanges = RMS_TRACK_CHANGES_YES;
  parameter.resetValue = 'Off';

  IF(powerOn)
  {
    parameter.initialValue = 'On';
  }
  ELSE
  {
    parameter.initialValue = 'Off';
  }

  // enqueue parameter
  RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetPowerParameterUpdate                     *)
(* Args:  CHAR assetClientKey[]                            *)
(*        CHAR PowerOn                                     *)
(*                                                         *)
(* Desc:  This function is used to update an asset power   *)
(*        parameter for a speficied asset key.             *)
(*                                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsAssetPowerParameterUpdate(CHAR assetClientKey[], CHAR powerOn)
{
  // update RMS parameter value for the asset power parameter
  IF(powerOn)
  {
    RmsAssetParameterSetValue(assetClientKey,RMS_KEY_ASSET_POWER,'On');
  }
  ELSE
  {
    RmsAssetParameterSetValue(assetClientKey,RMS_KEY_ASSET_POWER,'Off');
  }
}



////////////////////////////////////////////////////////////////////////////
//
//  RMS ASSET MANAGEMENT
//
////////////////////////////////////////////////////////////////////////////


(***********************************************************)
(* Name:  RmsAssetRegister                                 *)
(* Args:  DEV device - asset physical device instance      *)
(*        RmsAsset asset - asset configuration to register *)
(*                                                         *)
(* Desc:  This function is used to register a new asset    *)
(*        with the RMS system.                             *)
(*                                                         *)
(* Rtrn:  1 if asset registration call was successful      *)
(*        0 if asset registration call was unsuccessful    *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetRegister(DEV device, RmsAsset asset)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetRegister> :: RMS is not ready to accept asset management registrations.';
    RETURN FALSE;
  }

  // the asset client key is the DPS string
  // for NetLinx-based devices
  IF(asset.clientKey == '')
  {
    asset.clientKey = RmsDevToString(device);
  }

  // create asset registration send command
  rmsCommand = RmsPackCmdHeader('ASSET.REGISTER.DEV');
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsDevToString(device));
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.assetType);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.globalKey);

  // add device to registration queue
  SEND_COMMAND vdvRMS, rmsCommand;

  // now that the asset has been created in the
  // asset registration queue, finalize and submit
  // the asset
  RETURN RmsAssetRegistrationSubmit(asset);
}


(***********************************************************)
(* Name:  RmsAssetRegisterAmxDevice                        *)
(* Args:  DEV device - asset physical device instance      *)
(*        RmsAsset asset - asset configuration to register *)
(*                                                         *)
(* Desc:  This function is used to register an AMX         *)
(*        hardware based device with the RMS system.       *)
(*        (AxLink or NetLinx device)                       *)
(*                                                         *)
(* Rtrn:  1 if asset registration call was successful      *)
(*        0 if asset registration call was unsuccessful    *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetRegisterAmxDevice(DEV device, RmsAsset asset)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetRegisterAmxDevice> :: RMS is not ready to accept asset management registrations.';
    RETURN FALSE;
  }

  // the asset client key is the DPS string
  // for NetLinx-based devices
  IF(asset.clientKey == '')
  {
    asset.clientKey = RmsDevToString(device);
  }

  // create asset registration send command
  rmsCommand = RmsPackCmdHeader('ASSET.REGISTER.AMX.DEV');
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsDevToString(device));
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.assetType);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.globalKey);

  // add device to registration queue
  SEND_COMMAND vdvRMS, rmsCommand;

  // now that the asset has been created in the
  // asset registration queue, finalize and submit
  // the asset
  RETURN RmsAssetRegistrationSubmit(asset);
}


(***********************************************************)
(* Name:  RmsAssetRegisterDuetDevice                       *)
(* Args:  DEV device - asset physical device instance      *)
(*        DEV duetDevice - Duet virtual device instance    *)
(*        RmsAsset asset - asset configuration to register *)
(*                                                         *)
(* Desc:  This function is used to register an asset that  *)
(*        is using a Duet device module for control.       *)
(*        RMS will interrogate the Duet module to provide  *)
(*        the default asset registration, asset parameters,*)
(*        asset metadata properties, and asset control     *)
(*        methods.                                         *)
(*                                                         *)
(* Rtrn:  1 if asset registration call was successful      *)
(*        0 if asset registration call was unsuccessful    *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetRegisterDuetDevice(DEV realDevice, DEV duetDevice, RmsAsset asset)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetRegisterDuetDevice> :: RMS is not ready to accept asset management registrations.';
    RETURN FALSE;
  }

  // the asset client key is the DPS string
  // for NetLinx-based devices
  IF(asset.clientKey == '')
  {
    asset.clientKey = RmsDevToString(realDevice);
  }

  // create asset registration send command
  rmsCommand = RmsPackCmdHeader('ASSET.REGISTER.DUET.DEV');
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsDevToString(realDevice));
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsDevToString(duetDevice));
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.assetType);
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.globalKey);

  // add device to registration queue
  SEND_COMMAND vdvRMS, rmsCommand;

  // now that the asset has been created in the
  // asset registration queue, finalize and submit
  // the asset
  RETURN RmsAssetRegistrationSubmit(asset);
}


(***********************************************************)
(* Name:  RmsAssetRegistrationSubmit                       *)
(* Args:  RmsAsset asset - asset configuration to register *)
(*                                                         *)
(* Desc:  This function is used to perform the registration*)
(*        on a fully populated RmsAsset data object.       *)
(*                                                         *)
(*        (This function is typically not accessed         *)
(*         directly, but rather called by a another        *)
(*         asset registration wrapper function.)           *)
(*                                                         *)
(* Rtrn:  1 if asset registration call was successful      *)
(*        0 if asset registration call was unsuccessful    *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetRegistrationSubmit(RmsAsset asset)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetRegistrationSubmit> :: RMS is not ready to accept asset management registrations.';
    RETURN FALSE;
  }

  // add asset description
  IF(asset.description != '')
  {
    rmsCommand = RmsPackCmdHeader('ASSET.DESCRIPTION');
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.description);
    SEND_COMMAND vdvRMS, rmsCommand;
  }

  // add asset serial number
  IF(asset.serialNumber != '')
  {
    rmsCommand = RmsPackCmdHeader('ASSET.SERIAL');
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.serialNumber);
    SEND_COMMAND vdvRMS, rmsCommand;
  }

  // add asset firmware version
  IF(asset.firmwareVersion != '')
  {
    rmsCommand = RmsPackCmdHeader('ASSET.FIRMWARE');
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.firmwareVersion);
    SEND_COMMAND vdvRMS, rmsCommand;
  }

  // add asset manufacturer information
  IF(asset.manufacturerName != '')
  {
    rmsCommand = RmsPackCmdHeader('ASSET.MANUFACTURER');
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.manufacturerName);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.manufacturerUrl);
    SEND_COMMAND vdvRMS, rmsCommand;
  }

  // add asset manufacturer information
  IF(asset.modelName != '')
  {
    rmsCommand = RmsPackCmdHeader('ASSET.MODEL');
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.modelName);
    rmsCommand = RmsPackCmdParam(rmsCommand,asset.modelUrl);
    SEND_COMMAND vdvRMS, rmsCommand;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.SUBMIT');
  rmsCommand = RmsPackCmdParam(rmsCommand,asset.clientKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetExclude                                  *)
(* Args:  CHAR assetClientKey[] - asset key to exclude     *)
(*                                                         *)
(* Desc:  This function is used to define an exclusion     *)
(*        an any asset attempting to register using the    *)
(*        provided asset client key string identifier.     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetExclude(CHAR assetClientKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetExclude> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the asset exclusion now
  rmsCommand = RmsPackCmdHeader('ASSET.EXCLUDE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // force exclusion
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


////////////////////////////////////////////////////////////////////////////
//
//  RMS ASSET METADATA MANAGEMENT
//
////////////////////////////////////////////////////////////////////////////


(***********************************************************)
(* Name:  RmsAssetMetadataSubmit                           *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*                                                         *)
(* Desc:  This function is used to submit any pending      *)
(*        asset metadata properties that are currently     *)
(*        in queue waiting to be registered with RMS.      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataSubmit(CHAR assetClientKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataSubmit> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataSubmit> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA.SUBMIT');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataDelete                           *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*                                                         *)
(* Desc:  This function is used to delete an existing      *)
(*        asset metadata property from the RMS server.     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataDelete(CHAR assetClientKey[], CHAR metadataKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataDelete> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataDelete> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA.DELETE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataExclude                          *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*                                                         *)
(* Desc:  This function is used to exclude a specific      *)
(*        asset metadata property from being registered    *)
(*        to the specified asset client key.               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataExclude(CHAR assetClientKey[], CHAR metadataKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataExclude> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataExclude> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset exclusion now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA.EXCLUDE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // force exclusion
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueueString                    *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataName[] - metadata property name     *)
(*        CHAR metadataValue[] - metadata property value   *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers a metadata property of   *)
(*        type: STRING                                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueueString(CHAR assetClientKey[],
                                                   CHAR metadataKey[],
                                                   CHAR metadataName[],
                                                   CHAR metadataValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueString> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueString> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueString> :: missing metadata name';
    RETURN FALSE;
  }

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataName);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,RMS_METADATA_TYPE_STRING);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // read-only
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueueBoolean                   *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataName[] - metadata property name     *)
(*        CHAR metadataValue - metadata property value     *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers a metadata property of   *)
(*        type: BOOLEAN                                    *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueueBoolean(CHAR assetClientKey[],
                                                    CHAR metadataKey[],
                                                    CHAR metadataName[],
                                                    CHAR metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueBoolean> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueBoolean> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueBoolean> :: missing metadata name';
    RETURN FALSE;
  }

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataName);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(metadataValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,RMS_METADATA_TYPE_BOOLEAN);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // read-only
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueueNumber                    *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataName[] - metadata property name     *)
(*        SLONG metadataValue - metadata property value    *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers a metadata property of   *)
(*        type: NUMBER                                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueueNumber(CHAR assetClientKey[],
                                                   CHAR metadataKey[],
                                                   CHAR metadataName[],
                                                   SLONG metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueNumber> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueNumber> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueNumber> :: missing metadata name';
    RETURN FALSE;
  }

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataName);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(metadataValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,RMS_METADATA_TYPE_NUMBER);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // read-only
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueueDecimal                   *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataName[] - metadata property name     *)
(*        DOUBLE metadataValue - metadata property value   *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers a metadata property of   *)
(*        type: DECIMAL                                    *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueueDecimal(CHAR assetClientKey[],
                                                    CHAR metadataKey[],
                                                    CHAR metadataName[],
                                                    DOUBLE metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueDecimal> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueDecimal> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueDecimal> :: missing metadata name';
    RETURN FALSE;
  }

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataName);
  rmsCommand = RmsPackCmdParam(rmsCommand,FTOA(metadataValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,RMS_METADATA_TYPE_DECIMAL);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // read-only
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueueHyperlink                 *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataName[] - metadata property name     *)
(*        CHAR hyperlinkName[] - metadata hyperlink name   *)
(*        CHAR hyperlinUrl[] - metadata hyperlink address  *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers a metadata property of   *)
(*        type: HYPERLINK                                  *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueueHyperlink(CHAR assetClientKey[],
                                                      CHAR metadataKey[],
                                                      CHAR metadataName[],
                                                      CHAR metadataHyperlinkName[],
                                                      CHAR metadataHyperlinkUrl[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueHyperlink> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueHyperlink> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueueHyperlink> :: missing metadata name';
    RETURN FALSE;
  }

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataName);
  rmsCommand = RmsPackCmdParam(rmsCommand,''); // no value data, this is a hyperlink
  rmsCommand = RmsPackCmdParam(rmsCommand,RMS_METADATA_TYPE_HYPERLINK);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // read-only
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataHyperlinkName);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataHyperlinkUrl);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataEnqueue                          *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        RmsAssetMetadataProperty metadataProperty        *)
(*                                                         *)
(* Desc:  This function is used to place an asset metadata *)
(*        property registration in queue.                  *)
(*                                                         *)
(*        This function registers an asset metadata        *)
(*        property defined by the RmsAssetMetadataProperty *)
(*        data structure argument.                         *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataEnqueue(CHAR assetClientKey[],
                                             RmsAssetMetadataProperty metadataProperty)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataProperty.key == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueue> :: missing metadata key';
    RETURN FALSE;
  }

  // ensure a metadata name has been provided
  IF(metadataProperty.name == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataEnqueue> :: missing metadata name';
    RETURN FALSE;
  }

  // ensure a metadta property data type is assigned
  IF(metadataProperty.dataType == '')
    metadataProperty.dataType = RMS_METADATA_TYPE_STRING;

  // submit the asset metadata registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.key);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.value);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.dataType);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(metadataProperty.readOnly));
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.hyperlinkName);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataProperty.hyperlinkUrl);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataUpdateString                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataValue[] - metadata property value   *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: STRING                                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateString(CHAR assetClientKey[],
                                                  CHAR metadataKey[],
                                                  CHAR metadataValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateString> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateString> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateString> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  RETURN RmsAssetMetadataUpdateValue(assetClientKey,metadataKey,metadataValue);
}


(***********************************************************)
(* Name:  RmsAssetMetadataUpdateBoolean                    *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataValue - metadata property value     *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: BOOLEAN                                    *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateBoolean(CHAR assetClientKey[],
                                                   CHAR metadataKey[],
                                                   CHAR metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateBoolean> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateBoolean> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateBoolean> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  RETURN RmsAssetMetadataUpdateValue(assetClientKey,metadataKey,RmsBooleanString(metadataValue));
}


(***********************************************************)
(* Name:  RmsAssetMetadataUpdateNumber                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        SLONG metadataValue - metadata property value    *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: NUMBER                                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateNumber(CHAR assetClientKey[],
                                                  CHAR metadataKey[],
                                                  SLONG metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateNumber> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateNumber> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateNumber> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  RETURN RmsAssetMetadataUpdateValue(assetClientKey,metadataKey,ITOA(metadataValue));
}


(***********************************************************)
(* Name:  RmsAssetMetadataUpdateDecimal                    *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        DOUBLE metadataValue - metadata property value   *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: DECIMAL                                    *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateDecimal(CHAR assetClientKey[],
                                                   CHAR metadataKey[],
                                                   DOUBLE metadataValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateDecimal> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateDecimal> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateDecimal> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  RETURN RmsAssetMetadataUpdateValue(assetClientKey,metadataKey,FTOA(metadataValue));
}


(***********************************************************)
(* Name:  RmsAssetMetadataUpdateHyperlink                  *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR hyperlinkName[] - metadata hyperlink name   *)
(*        CHAR hyperlinUrl[] - metadata hyperlink address  *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: HYPERLINK                                  *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateHyperlink(CHAR assetClientKey[],
                                                     CHAR metadataKey[],
                                                     CHAR metadataHyperlinkName[],
                                                     CHAR metadataHyperlinkUrl[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateHyperlink> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateHyperlink> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateHyperlink> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA.UPDATE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,''); // empty placeholder for value field for other data types
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataHyperlinkName);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataHyperlinkUrl);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}



(***********************************************************)
(* Name:  RmsAssetMetadataUpdateValue                      *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR metadataKey[] - metadata property key       *)
(*        CHAR metadataValue[] - metadata property value   *)
(*                                                         *)
(* Desc:  This function is used to update and existing     *)
(*        asset metadata property value.                   *)
(*                                                         *)
(*        This function updates a metadata property of     *)
(*        type: HYPERLINK                                  *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetMetadataUpdateValue(CHAR assetClientKey[],
                                                 CHAR metadataKey[],
                                                 CHAR metadataValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    //SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateValue> :: RMS is not ready to accept asset metadata changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateValue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a metadata key has been provided
  IF(metadataKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetMetadataUpdateValue> :: missing metadata key';
    RETURN FALSE;
  }

  // submit the asset metadata update now
  rmsCommand = RmsPackCmdHeader('ASSET.METADATA.UPDATE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,metadataValue);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


////////////////////////////////////////////////////////////////////////////
//
//  RMS ASSET CONTROL METHODS MANAGEMENT
//
////////////////////////////////////////////////////////////////////////////


(***********************************************************)
(* Name:  RmsAssetControlMethodsSubmit                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*                                                         *)
(* Desc:  This function is used to submit any pending      *)
(*        asset control methods that are currently         *)
(*        in queue waiting to be registered with RMS.      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodsSubmit(CHAR assetClientKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodsSubmit> :: RMS is not ready to accept asset control method changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodsSubmit> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the pended queued asset registrations now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.SUBMIT');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodDelete                      *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR methodKey[] - control method key            *)
(*                                                         *)
(* Desc:  This function is used to delete an existing      *)
(*        asset control method from the RMS server.        *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodDelete(CHAR assetClientKey[],
                                                 CHAR methodKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodDelete> :: RMS is not ready to accept asset control method changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodDelete> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodDelete> :: missing control method key';
    RETURN FALSE;
  }

  // delete existing registered asset control method
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.DELETE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodExclude                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR methodKey[] - control method key            *)
(*                                                         *)
(* Desc:  This function is used to exclude a specific      *)
(*        asset control method from being registered       *)
(*        to the specified asset client key.               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodExclude(CHAR assetClientKey[], CHAR methodKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodExclude> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodExclude> :: missing method key';
    RETURN FALSE;
  }

  // submit the asset method exclusion now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.EXCLUDE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // force exclusion
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodEnqueue                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR methodKey[] - control method key            *)
(*        CHAR methodName[] - control method name          *)
(*        CHAR methodDescription[] - control method desc.  *)
(*                                                         *)
(* Desc:  This function is used to place an asset control  *)
(*        method registration in queue in the RMS client.  *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodEnqueue(CHAR assetClientKey[],
                                                  CHAR methodKey[],
                                                  CHAR methodName[],
                                                  CHAR methodDescription[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodEnqueue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodEnqueue> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodEnqueue> :: missing control method name';
    RETURN FALSE;
  }

  // enqueue asset control method for registration
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodName);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodDescription);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentString              *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: STRING                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentString(CHAR assetClientKey[],
                                                         CHAR methodKey[],
                                                         INTEGER argumentOrdinal,
                                                         CHAR argumentName[],
                                                         CHAR argumentDescription[],
                                                         CHAR argumentDefaultValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentString> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentString> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentString> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.STRING');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDefaultValue);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentBoolean             *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: BOOLEAN                              *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentBoolean(CHAR assetClientKey[],
                                                          CHAR methodKey[],
                                                          INTEGER argumentOrdinal,
                                                          CHAR argumentName[],
                                                          CHAR argumentDescription[],
                                                          CHAR argumentDefaultValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentBoolean> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentBoolean> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentBoolean> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.BOOLEAN');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(argumentDefaultValue));
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentNumber              *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: NUMBER                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentNumber( CHAR assetClientKey[],
                                                     CHAR methodKey[],
                                                     INTEGER argumentOrdinal,
                                                     CHAR argumentName[],
                                                     CHAR argumentDescription[],
                                                     SLONG argumentDefaultValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumber> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumber> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumber> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.NUMBER');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentDefaultValue));
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentNumberEx            *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        This EXTENDED function provides the additional   *)
(*        arguments to provide min, max, and step values   *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: NUMBER                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentNumberEx( CHAR assetClientKey[],
                                                     CHAR methodKey[],
                                                     INTEGER argumentOrdinal,
                                                     CHAR argumentName[],
                                                     CHAR argumentDescription[],
                                                     SLONG argumentDefaultValue,
                                                     SLONG argumentMinimumValue,
                                                     SLONG argumentMaximumValue,
                                                     INTEGER argumentStepValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumberEx> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumberEx> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentNumberEx> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.NUMBER');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentDefaultValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentMinimumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentMaximumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentStepValue));
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentDecimal             *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: DECIMAL                              *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentDecimal(CHAR assetClientKey[],
                                                          CHAR methodKey[],
                                                          INTEGER argumentOrdinal,
                                                          CHAR argumentName[],
                                                          CHAR argumentDescription[],
                                                          DOUBLE argumentDefaultValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentDecimal> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentDecimal> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentDecimal> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.DECIMAL');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,FTOA(argumentDefaultValue));
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentLevel               *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: LEVEL                                *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentLevel(CHAR assetClientKey[],
                                                        CHAR methodKey[],
                                                        INTEGER argumentOrdinal,
                                                        CHAR argumentName[],
                                                        CHAR argumentDescription[],
                                                        SLONG argumentDefaultValue,
                                                        SLONG argumentMinimumValue,
                                                        SLONG argumentMaximumValue,
                                                        INTEGER argumentStepValue)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];


  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentLevel> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentLevel> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentLevel> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.LEVEL');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentDefaultValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentMinimumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentMaximumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentStepValue));
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentEnum                *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: ENUMERATION                          *)
(*                                                         *)
(*        Enueration is provided as a pipe '|' separated   *)
(*        list of strings.                                 *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentEnum(CHAR assetClientKey[],
                                                       CHAR methodKey[],
                                                       INTEGER argumentOrdinal,
                                                       CHAR argumentName[],
                                                       CHAR argumentDescription[],
                                                       CHAR argumentDefaultValue[],
                                                       CHAR argumentEnumerationValues[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
            INTEGER index;

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnum> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnum> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnum> :: missing control method argument name';
    RETURN FALSE;
  }

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT.ENUM');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argumentOrdinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentName);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDescription);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentDefaultValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,argumentEnumerationValues);

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentEnumEx              *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.        *)
(*                                                         *)
(*        The asset control method argument being added    *)
(*        is of type: ENUMERATION                          *)
(*                                                         *)
(*        This EXTENDED function support enumeration values*)
(*        provided as a multi-dimensional array.           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentEnumEx(CHAR assetClientKey[],
                                                       CHAR methodKey[],
                                                       INTEGER argumentOrdinal,
                                                       CHAR argumentName[],
                                                       CHAR argumentDescription[],
                                                       CHAR argumentDefaultValue[],
                                                       CHAR argumentEnumerationValues[][])
{
  STACK_VAR CHAR rmsEnumValues[RMS_MAX_CMD_LEN];
            INTEGER index;

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnumEx> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnumEx> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argumentName == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnumEx> :: missing control method argument name';
    RETURN FALSE;
  }

  // convert array of enumeration values into pipe separated string
  FOR(index = 1; index <= LENGTH_ARRAY(argumentEnumerationValues); index++)
  {
    rmsEnumValues = "rmsEnumValues,argumentEnumerationValues[index],'|'";
  }

  IF(LENGTH_STRING(rmsEnumValues))
    SET_LENGTH_STRING(rmsEnumValues,LENGTH_STRING(rmsEnumValues)-1)

// Add pipe parsing and call up
  RmsAssetControlMethodArgumentEnum(assetClientKey,
                                         methodKey,
                                         argumentOrdinal,
                                         argumentName,
                                         argumentDescription,
                                         argumentDefaultValue,
                                         rmsEnumValues)

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetControlMethodArgumentEnqueue             *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR methodKey[] - control method key            *)
(*        RmsAssetControlMethodArgument argument           *)
(*                                                         *)
(* Desc:  This function is used to add an asset control    *)
(*        method argument to an asset control method       *)
(*        registration that is currently in queue and has  *)
(*        not yet been submitted to the RMS server.  This  *)
(*        method accepts a RmsAssetControlMethodArgument   *)
(*        data type argument.                              *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetControlMethodArgumentEnqueue(CHAR assetClientKey[],
                                                          CHAR methodKey[],
                                                          RmsAssetControlMethodArgument argument)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
            INTEGER index;

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnqueue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a control method key has been provided
  IF(methodKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnqueue> :: missing control method key';
    RETURN FALSE;
  }

  // ensure a control method argument has been provided
  IF(argument.name == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetControlMethodArgumentEnqueue> :: missing control method argument name';
    RETURN FALSE;
  }

  // ensure a control method argument data type is assigned
  IF(argument.dataType == '')
    argument.dataType = RMS_METHOD_ARGUMENT_TYPE_STRING;

  // submit the asset registration now
  rmsCommand = RmsPackCmdHeader('ASSET.METHOD.ARGUMENT');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,methodKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argument.ordinal));
  rmsCommand = RmsPackCmdParam(rmsCommand,argument.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,argument.description);
  rmsCommand = RmsPackCmdParam(rmsCommand,argument.dataType);
  rmsCommand = RmsPackCmdParam(rmsCommand,argument.defaultValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argument.minimumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argument.maximumValue));
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(argument.stepValue));

  FOR(index = 1; index <= LENGTH_ARRAY(argument.enumerationValues); index++)
  {
    if(index ==1){
	rmsCommand = RmsPackCmdParam(rmsCommand,argument.enumerationValues[index]);
    } else {
	rmsCommand = "rmsCommand,'|',argument.enumerationValues[index]";
    }
    
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


////////////////////////////////////////////////////////////////////////////
//
//  RMS ASSET PARAMETER MANAGEMENT
//
////////////////////////////////////////////////////////////////////////////

(***********************************************************)
(* Name:  RmsAssetParameterSubmit                          *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*                                                         *)
(* Desc:  This function is used to submit any pending      *)
(*        asset monitored parameter that are currently     *)
(*        in queue waiting to be registered with RMS.      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSubmit(CHAR assetClientKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterSubmit> :: RMS is not ready to accept asset parameters changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterSubmit> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the asset parameter registration now
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.SUBMIT');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetMetadataDelete                           *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*                                                         *)
(* Desc:  This function is used to delete an existing      *)
(*        asset monitored parameter from the RMS server.   *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterDelete(CHAR assetClientKey[],
                                             CHAR parameterKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterDelete> :: RMS is not ready to accept asset parameters changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterDelete> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameterKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterDelete> :: missing parameter key';
    RETURN FALSE;
  }

  // submit the asset parameter delete command
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.DELETE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetParameterExclude                         *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*                                                         *)
(* Desc:  This function is used to exclude a specific      *)
(*        asset monitored parameter from being registered  *)
(*        to the specified asset client key.               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterExclude(CHAR assetClientKey[],
                                              CHAR parameterKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterExclude> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameterKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterExclude> :: missing parameter key';
    RETURN FALSE;
  }

  // submit the asset exclusion now
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.EXCLUDE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // force exclusion
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueEnumeration              *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: ENUMERATION                 *)
(*                                                         *)
(*        The enumeration values should be provided as     *)
(*        a pipe "|" delimited list of string values.      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueEnumeration(CHAR assetClientKey[],
                                                         CHAR parameterKey[],
                                                         CHAR parameterName[],
                                                         CHAR parameterDescription[],
                                                         CHAR reportingType[],
                                                         CHAR initialValue[],
                                                         CHAR enumeration[],
                                                         CHAR allowReset,
                                                         CHAR resetValue[],
                                                         CHAR trackChanges)
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_ENUMERATION;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = initialValue;
  parameter.allowReset = allowReset;
  parameter.resetValue = resetValue;
  parameter.trackChanges = trackChanges;
  parameter.enumeration = enumeration;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueDecimal                  *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: DECIMAL                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueDecimal(CHAR assetClientKey[],
                                                     CHAR parameterKey[],
                                                     CHAR parameterName[],
                                                     CHAR parameterDescription[],
                                                     CHAR reportingType[],
                                                     DOUBLE initialValue,
                                                     SLONG minimumValue,
                                                     SLONG maximumValue,
                                                     CHAR units[],
                                                     CHAR allowReset,
                                                     DOUBLE resetValue,
                                                     CHAR trackChanges)
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_DECIMAL;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = FTOA(initialValue);
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = FTOA(resetValue);
  parameter.trackChanges = trackChanges;
  parameter.minimumValue = minimumValue;
  parameter.maximumValue = maximumValue;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}

(***********************************************************)
(* Name:  RmsAssetParameterEnqueueDecimalWithBargraph      *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: DECIMAL                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueDecimalWithBargraph(CHAR assetClientKey[],
                                                     CHAR parameterKey[],
                                                     CHAR parameterName[],
                                                     CHAR parameterDescription[],
                                                     CHAR reportingType[],
                                                     DOUBLE initialValue,
                                                     SLONG minimumValue,
                                                     SLONG maximumValue,
                                                     CHAR units[],
                                                     CHAR allowReset,
                                                     DOUBLE resetValue,
                                                     CHAR trackChanges,
                                                     CHAR bargraphKey[])
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_DECIMAL;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = FTOA(initialValue);
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = FTOA(resetValue);
  parameter.trackChanges = trackChanges;
  parameter.minimumValue = minimumValue;
  parameter.maximumValue = maximumValue;
  parameter.bargraphKey = bargraphKey;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueLevel                    *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: LEVEL                       *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueLevel (CHAR assetClientKey[],
                                                    CHAR parameterKey[],
                                                    CHAR parameterName[],
                                                    CHAR parameterDescription[],
                                                    CHAR reportingType[],
                                                    SLONG initialValue,
                                                    SLONG minimumValue,
                                                    SLONG maximumValue,
                                                    CHAR units[],
                                                    CHAR allowReset,
                                                    SLONG resetValue,
                                                    CHAR trackChanges,
                                                    CHAR bargraphKey[])
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_LEVEL;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = ITOA(initialValue);
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = ITOA(resetValue);
  parameter.trackChanges = trackChanges;
  parameter.minimumValue = minimumValue;
  parameter.maximumValue = maximumValue;
  parameter.bargraphKey = bargraphKey;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueNumber                   *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: NUMBER                      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueNumber(CHAR assetClientKey[],
                                                    CHAR parameterKey[],
                                                    CHAR parameterName[],
                                                    CHAR parameterDescription[],
                                                    CHAR reportingType[],
                                                    SLONG initialValue,
                                                    SLONG minimumValue,
                                                    SLONG maximumValue,
                                                    CHAR units[],
                                                    CHAR allowReset,
                                                    SLONG resetValue,
                                                    CHAR trackChanges)
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_NUMBER;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = ITOA(initialValue);
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = ITOA(resetValue);
  parameter.trackChanges = trackChanges;
  parameter.minimumValue = minimumValue;
  parameter.maximumValue = maximumValue;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueNumberWithBargraph       *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: NUMBER                      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueNumberWithBargraph(CHAR assetClientKey[],
                                                    CHAR parameterKey[],
                                                    CHAR parameterName[],
                                                    CHAR parameterDescription[],
                                                    CHAR reportingType[],
                                                    SLONG initialValue,
                                                    SLONG minimumValue,
                                                    SLONG maximumValue,
                                                    CHAR units[],
                                                    CHAR allowReset,
                                                    SLONG resetValue,
                                                    CHAR trackChanges,
                                                    CHAR bargraphKey[])
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for number param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_NUMBER;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = ITOA(initialValue);
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = ITOA(resetValue);
  parameter.trackChanges = trackChanges;
  parameter.minimumValue = minimumValue;
  parameter.maximumValue = maximumValue;
  parameter.bargraphKey = bargraphKey;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueString                   *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: STRING                      *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueString(CHAR assetClientKey[],
                                                    CHAR parameterKey[],
                                                    CHAR parameterName[],
                                                    CHAR parameterDescription[],
                                                    CHAR reportingType[],
                                                    CHAR initialValue[],
                                                    CHAR units[],
                                                    CHAR allowReset,
                                                    CHAR resetValue[],
                                                    CHAR trackChanges)
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for string param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_STRING;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = initialValue;
  parameter.units = units;
  parameter.allowReset = allowReset;
  parameter.resetValue = resetValue;
  parameter.trackChanges = trackChanges;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueBoolean                  *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.                                      *)
(*                                                         *)
(*        The asset parameter being registered is of asset *)
(*        parameter data type: BOOLEAN                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueBoolean(CHAR assetClientKey[],
                                                     CHAR parameterKey[],
                                                     CHAR parameterName[],
                                                     CHAR parameterDescription[],
                                                     CHAR reportingType[],
                                                     CHAR initialValue,
                                                     CHAR allowReset,
                                                     CHAR resetValue,
                                                     CHAR trackChanges)
{
  STACK_VAR RmsAssetParameter parameter

  // set all parameter properties for boolean param
  parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_BOOLEAN;
  parameter.key = parameterKey;
  parameter.name = parameterName;
  parameter.description = parameterDescription;
  parameter.reportingType = reportingType;
  parameter.initialValue = RmsBooleanString(initialValue);
  parameter.allowReset = allowReset;
  parameter.resetValue = RmsBooleanString(resetValue);
  parameter.trackChanges = trackChanges;

  RETURN RmsAssetParameterEnqueue(assetClientKey, parameter);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueBoolean                  *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to place an asset parameter*)
(*        registration in queue for a specified asset      *)
(*        client key.  This method accepts the data        *)
(*        structure RmsAssetParameter as an argument       *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueue(CHAR assetClientKey[],
                                              RmsAssetParameter parameter)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterEnqueue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameter.key == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterEnqueue> :: missing parameter key';
    RETURN FALSE;
  }

  // ensure a parameter data type is assigned
  IF(parameter.dataType == '')
    parameter.dataType = RMS_ASSET_PARAM_DATA_TYPE_STRING;

  // ensure a parameter reporting type is assigned
  IF(parameter.reportingType == '')
    parameter.reportingType = RMS_ASSET_PARAM_TYPE_NONE;

  // enqueue asset control method for registration
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.key);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.description);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.dataType);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.reportingType);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.initialValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.units);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(parameter.allowReset));
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.resetValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(parameter.minimumValue));
  IF(parameter.maximumValue > parameter.minimumValue)
  {
    // only register a max value if it is greater than the minimum value
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(parameter.maximumValue));
  }
  ELSE
  {
    // undefined max value
    rmsCommand = RmsPackCmdParam(rmsCommand,'');
  }
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.enumeration);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(parameter.trackChanges));
  rmsCommand = RmsPackCmdParam(rmsCommand,parameter.bargraphKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(parameter.stockParam));

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetParameterThresholdEnqueue                *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset parameter  *)
(*        threshold on the asset parameter currently       *)
(*        pending in the asset parameter registration queue*)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterThresholdEnqueue(CHAR assetClientKey[],
                                                       CHAR parameterKey[],
                                                       CHAR thresholdName[],
                                                       CHAR thresholdStatusType[],
                                                       CHAR thresholdComparisonOperator[],
                                                       CHAR thresholdValue[])
{
  STACK_VAR RmsAssetParameterThreshold threshold;

  // setup threshold data structure
  threshold.name = thresholdName;
  threshold.statusType = thresholdStatusType;
  threshold.comparisonOperator = thresholdComparisonOperator;
  threshold.value = thresholdValue;
  threshold.delayInterval = 0;
  threshold.notifyOnTrip = TRUE;
  threshold.notifyOnRestore = FALSE;
  threshold.enabled = TRUE;

  RETURN RmsAssetParameterThresholdEnqueueEx(assetClientKey, parameterKey, threshold);
}


(***********************************************************)
(* Name:  RmsAssetParameterThresholdEnqueueEx              *)
(* Args:  -see method signature below-                     *)
(*                                                         *)
(* Desc:  This function is used to add an asset parameter  *)
(*        threshold on the asset parameter currently       *)
(*        pending in the asset parameter registration queue*)
(*                                                         *)
(*        This EXTENDED function accepts the data structure*)
(*        RmsAssetParameterThreshold as an argument.       *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterThresholdEnqueueEx(CHAR assetClientKey[],
                                                         CHAR parameterKey[],
                                                         RmsAssetParameterThreshold threshold)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterThresholdEnqueueEx> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameterKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterThresholdEnqueueEx> :: missing parameter key';
    RETURN FALSE;
  }

  // ensure a threshold name has been provided
  IF(threshold.name == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterThresholdEnqueueEx> :: missing threshold name';
    RETURN FALSE;
  }

  // ensure a threshold comparison operator has been provided
  IF(threshold.comparisonOperator == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterThresholdEnqueueEx> :: missing threshold comparison operator';
    RETURN FALSE;
  }

  // ensure a threshold value has been provided
  IF(threshold.value == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterThresholdEnqueueEx> :: missing threshold value';
    RETURN FALSE;
  }

  // if a status type was not provided, then apply the NOT_ASSIGNED status type
  IF(threshold.statusType == '')
  {
    threshold.statusType = RMS_STATUS_TYPE_NOT_ASSIGNED;
  }

  // submit the asset parameter update now
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.THRESHOLD');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,threshold.name);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(threshold.enabled));
  rmsCommand = RmsPackCmdParam(rmsCommand,threshold.statusType);
  rmsCommand = RmsPackCmdParam(rmsCommand,threshold.comparisonOperator);
  rmsCommand = RmsPackCmdParam(rmsCommand,threshold.value);
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(threshold.notifyOnTrip));
  rmsCommand = RmsPackCmdParam(rmsCommand,RmsBooleanString(threshold.notifyOnRestore));
  IF(threshold.delayInterval > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,'true'); // delayed = TRUE
  }
  ELSE
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,'false');  // delayed = FALSE
  }
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(threshold.delayInterval));

  SEND_COMMAND vdvRMS, rmsCommand;
}


(***********************************************************)
(* Name:  RmsAssetParameterSetValueBoolean                 *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue - monitored parameter value  *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: BOOLEAN                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSetValueBoolean(CHAR assetClientKey[],
                                                      CHAR parameterKey[],
                                                      CHAR parameterValue)
{
  // submit the asset parameter update now
  RETURN RmsAssetParameterSetValue(assetClientKey,
                                   parameterKey,
                                   RmsBooleanString(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterSetValueNumber                  *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        SLONG parameterValue - monitored parameter value *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: NUMBER                                *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSetValueNumber(CHAR assetClientKey[],
                                                     CHAR parameterKey[],
                                                     SLONG parameterValue)
{
  RETURN RmsAssetParameterSetValue(assetClientKey,
                                   parameterKey,
                                   ITOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterSetValueDecimal                 *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        DOUBLE parameterValue - monitored parameter value*)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: DECIMAL                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSetValueDecimal(CHAR assetClientKey[],
                                                      CHAR parameterKey[],
                                                      DOUBLE parameterValue)
{
  RETURN RmsAssetParameterSetValue(assetClientKey,
                                   parameterKey,
                                   FTOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterSetValueLevel                   *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        SLONG parameterValue - monitored parameter value *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: LEVEL                                 *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSetValueLevel (CHAR assetClientKey[],
                                                     CHAR parameterKey[],
                                                     SLONG parameterValue)
{
  RETURN RmsAssetParameterSetValue(assetClientKey,
                                   parameterKey,
                                   ITOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterSetValue                        *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue[] - monitored parameter value*)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: STRING                                *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterSetValue(CHAR assetClientKey[],
                                               CHAR parameterKey[],
                                               CHAR parameterValue[])
{
  // submit the asset parameter update now
  RETURN RmsAssetParameterUpdateValue(assetClientKey,
                                      parameterKey,
                                      RMS_ASSET_PARAM_UPDATE_OPERATION_SET,
                                      parameterValue);
}


(***********************************************************)
(* Name:  RmsAssetParameterUpdateValue                     *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterOperation[] - update operation     *)
(*        CHAR parameterValue[] - update parameter value   *)
(*                                                         *)
(* Desc:  This function is used to udpate an asset         *)
(*        parameter value to the RMS server immediately.   *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterUpdateValue(CHAR assetClientKey[],
                                                  CHAR parameterKey[],
                                                  CHAR parameterOperation[],
                                                  CHAR parameterValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, "'>>>> RMS API ERROR <RmsAssetParameterUpdateValue> :: missing asset client key for parameter: ',parameterKey";
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameterKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterUpdateValue> :: missing parameter key';
    RETURN FALSE;
  }

  // if an operation was not provided, then apply the SET operation
  IF(parameterOperation == '')
  {
    parameterOperation = RMS_ASSET_PARAM_UPDATE_OPERATION_SET;
  }

  // submit the asset parameter update now
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.UPDATE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterOperation);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,'true');  // SUBMIT-NOW = TRUE
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueSetValueBoolean          *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue - monitored parameter value  *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: BOOLEAN                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueSetValueBoolean(CHAR assetClientKey[],
                                                             CHAR parameterKey[],
                                                             CHAR parameterValue)
{
  // enqueue the asset parameter update
  RETURN RmsAssetParameterEnqueueSetValue(assetClientKey,
                                             parameterKey,
                                             RmsBooleanString(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueSetValueNumber           *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        SLONG parameterValue - monitored parameter value *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: NUMBER                                *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueSetValueNumber(CHAR assetClientKey[],
                                                            CHAR parameterKey[],
                                                            SLONG parameterValue)
{
  // enqueue the asset parameter update
  RETURN RmsAssetParameterEnqueueSetValue(assetClientKey,
                                          parameterKey,
                                          ITOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueSetValueDecimal          *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        DOUBLE parameterValue - monitored parameter value*)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: DECIMAL                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueSetValueDecimal(CHAR assetClientKey[],
                                                             CHAR parameterKey[],
                                                             DOUBLE parameterValue)
{
  // enqueue the asset parameter update
  RETURN RmsAssetParameterEnqueueSetValue(assetClientKey,
                                          parameterKey,
                                          FTOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueSetValueLevel            *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        SLONG parameterValue - monitored parameter value *)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: LEVEL                                 *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueSetValueLevel(CHAR assetClientKey[],
                                                           CHAR parameterKey[],
                                                           SLONG parameterValue)
{
  // enqueue the asset parameter update
  RETURN RmsAssetParameterEnqueueSetValue(assetClientKey,
                                          parameterKey,
                                          ITOA(parameterValue));
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueSetValueLevel            *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterValue[] - monitored parameter value*)
(*                                                         *)
(* Desc:  This function is used to set a new asset         *)
(*        parameter value to the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(*        This function will set an asset parameter of     *)
(*        data type: STRING                                *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueSetValue(CHAR assetClientKey[],
                                                      CHAR parameterKey[],
                                                      CHAR parameterValue[])
{
  // enqueue the asset parameter update
  RETURN RmsAssetParameterEnqueueUpdateValue(assetClientKey,
                                             parameterKey,
                                             RMS_ASSET_PARAM_UPDATE_OPERATION_SET,
                                             parameterValue);
}


(***********************************************************)
(* Name:  RmsAssetParameterEnqueueUpdateValue              *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*        CHAR parameterKey[] - monitored parameter key    *)
(*        CHAR parameterOperation[] - update operation     *)
(*        CHAR parameterValue[] - update parameter value   *)
(*                                                         *)
(* Desc:  This function is used to udpate an asset         *)
(*        parameter value on the RMS server.  The update   *)
(*        is not sent immediately, but rather placed in    *)
(*        an update queue waiting for a submission call.   *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterEnqueueUpdateValue(CHAR assetClientKey[],
                                                         CHAR parameterKey[],
                                                         CHAR parameterOperation[],
                                                         CHAR parameterValue[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterEnqueueUpdateValue> :: missing asset client key';
    RETURN FALSE;
  }

  // ensure a parameter key has been provided
  IF(parameterKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterEnqueueUpdateValue> :: missing parameter key';
    RETURN FALSE;
  }

  // if an operation was not provided, then apply the SET operation
  IF(parameterOperation == '')
  {
    parameterOperation = RMS_ASSET_PARAM_UPDATE_OPERATION_SET;
  }

  // enqueue the asset parameter update
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.UPDATE');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterKey);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterOperation);
  rmsCommand = RmsPackCmdParam(rmsCommand,parameterValue);
  rmsCommand = RmsPackCmdParam(rmsCommand,'false');  // SUBMIT-NOW = FALSE
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsAssetParameterUpdatesSubmit                   *)
(* Args:  CHAR assetClientKey[] - asset client key         *)
(*                                                         *)
(* Desc:  This function is used to submit all pending      *)
(*        asset parameter value updated to the RMS server. *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsAssetParameterUpdatesSubmit(CHAR assetClientKey[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure RMS is ONLINE, REGISTERED, and ready for ASSET registration
  IF(![vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterUpdatesSubmit> :: RMS is not ready to accept asset parameters changes.';
    RETURN FALSE;
  }

  // ensure an asset client key has been provided
  IF(assetClientKey == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsAssetParameterUpdatesSubmit> :: missing asset client key';
    RETURN FALSE;
  }

  // submit the pending asset parameter updates now
  rmsCommand = RmsPackCmdHeader('ASSET.PARAM.UPDATE.SUBMIT');
  rmsCommand = RmsPackCmdParam(rmsCommand,assetClientKey);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}



(***********************************************************)
(* Name:  RmsSendHelpRequest                               *)
(* Args:  CHAR requestMessage[] - message body             *)
(*                                                         *)
(* Desc:  This function is used to submit a help request   *)
(*        message to the RMS server.                       *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsSendHelpRequest(CHAR requestMessage[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure a request message has been provided
  IF(requestMessage == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsSendHelpRequest> :: missing request message';
    RETURN FALSE;
  }

  // send the request message to RMS
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_HELP_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,requestMessage);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsSendMaintenanceRequest                        *)
(* Args:  CHAR requestMessage[] - message body             *)
(*                                                         *)
(* Desc:  This function is used to submit a maintenance    *)
(*        request message to the RMS server.               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsSendMaintenanceRequest(CHAR requestMessage[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // ensure a request message has been provided
  IF(requestMessage == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsSendMaintenanceRequest> :: missing request message';
    RETURN FALSE;
  }

  // send the request message to RMS
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_MAINTENANCE_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,requestMessage);
  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsGetVersionInfo                                *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function is used to query the RMS client    *)
(*        to display version information via the master's  *)
(*        telnet console.                                  *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsGetVersionInfo()
{
  // send the version request to RMS
  SEND_COMMAND vdvRMS, RMS_COMMAND_VERSION_REQUEST;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsReinitialize                                  *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This reinitialize request will reset the RMS     *)
(*        connection to the server and force all the asset *)
(*        parameter, control methods and metadata to be    *)
(*        resent/registered with RMS server.               *)
(***********************************************************)
DEFINE_FUNCTION RmsReinitialize()
{
  // send the reinitialization request to RMS
  SEND_COMMAND vdvRMS, RMS_COMMAND_REINITIALIZE;
}


(***********************************************************)
(* Name:  RmsSystemPowerOn                                 *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function will set the RMS system power to   *)
(*        the ON state.  System Power event notifications  *)
(*        will be sent out if this request causes a state  *)
(*        change .                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsSystemPowerOn()
{
  // set the system power to the ON state
  SEND_COMMAND vdvRMS,RMS_COMMAND_SYSTEM_POWER_ON;
}


(***********************************************************)
(* Name:  RmsSystemPowerOff                                *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function will set the RMS system power to   *)
(*        the OFF state.  System Power event notifications *)
(*        will be sent out if this request causes a state  *)
(*        change .                                         *)
(***********************************************************)
DEFINE_FUNCTION RmsSystemPowerOff()
{
  // set the system power to the OFF state
  SEND_COMMAND vdvRMS,RMS_COMMAND_SYSTEM_POWER_OFF;
}


(***********************************************************)
(* Name:  RmsSystemSetMode                                 *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function will apply a new System Mode by    *)
(*        name.  System Mode event notifications will be   *)
(*        sent out if this request causes a state change   *)
(***********************************************************)
DEFINE_FUNCTION RmsSystemSetMode(CHAR modeName[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // set the system mode in RMS
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SYSTEM_MODE);
  rmsCommand = RmsPackCmdParam(rmsCommand,modeName);
  SEND_COMMAND vdvRMS, rmsCommand;
}


(***********************************************************)
(* Name:  RmsProxyCustomCommand                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This function will forward a user custom command *)
(*        thru the RMS virtual device interface.  RMS will *)
(*        not take any action on this command, it will     *)
(*        simply relay it bakc out to all DATA_EVENT       *)
(*        listeners subscribed to the vdvRMS virtual device*)
(***********************************************************)
DEFINE_FUNCTION RmsProxyCustomCommand(CHAR customHeader[], CHAR customData[])
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // proxy custom user command thru RMS
  rmsCommand = RmsPackCmdHeader("'@',customHeader");
  rmsCommand = RmsPackCmdParam(rmsCommand,customData);
  SEND_COMMAND vdvRMS, rmsCommand;
}

(***********************************************************)
(* Name:  RmsEnumToArray                                   *)
(*                                                         *)
(* Args:  CHAR charEnum[] - charEnum is an enumeration.    *)
(*                                                         *)
(*        CHAR charArray - A two-dimensional array which   *)
(*        will be used to store the parsed enumeration.    *)
(*                                                         *)
(* Desc:  Parse an enumeration into a two-dimensional      *)
(*        string array                                     *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsEnumToArray(CHAR charEnum[], CHAR charArray[][])
{
	STACK_VAR CHAR charTemp[RMS_MAX_PARAM_LEN];
	STACK_VAR INTEGER ndx;

	ndx = 0;

	WHILE(LENGTH_STRING(charEnum))
	{
		charTemp = REMOVE_STRING(charEnum, '|', 1);
		if(charTemp != '')
		{
			SET_LENGTH_STRING(charTemp, LENGTH_STRING(charTemp) - 1);
			ndx++;
			charArray[ndx] = charTemp;
		}
		// Anything remaining after the delimiter?
		ELSE
		{
			if(charEnum != '')
			{
				ndx++;
				charArray[ndx] = charEnum;
				REMOVE_STRING(charEnum, charEnum, 1);
			}
		}
	}
	return TRUE;
}

(***********************************************************)
(* Name:  RmsGetClientLocationAssociated                   *)
(* Args:  LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Get the client associated location for the       *)
(*        given location ID                                *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsGetClientLocationAssociated(LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_LOCATION_ASSOCIATED);

  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsGetClientLocationsAssociated                  *)
(*                                                         *)
(* Desc:  Get all locations associated with the client     *)
(*                                                         *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsGetClientLocationsAssociated()
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
  
  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_LOCATIONS_ASSOCIATED);

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}


(***********************************************************)
(* Name:  RmsGetDeviceAutoRegister                  	   *)
(*                                                         *)
(* Desc:  Gets device auto register configuration          *)
(*                                                         *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsGetDeviceAutoRegister()
{
    STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
    
    // create send command
    rmsCommand = RmsPackCmdHeader(RMS_EVENT_DEVICE_AUTO_REGISTER_REQUEST);
    SEND_COMMAND vdvRMS, rmsCommand;
    
    RETURN TRUE;
}

(***************************************************************)
(* Name:  RmsGetDeviceAutoRegister                  	       *)
(*                                                             *)
(* Desc:  Sets device auto register configuration (true|false) *)
(*                                                             *)
(*                                                             *)
(* Rtrn:  1 if call was successful                             *)
(*        0 if call was unsuccessful                           *)
(***************************************************************)

DEFINE_FUNCTION CHAR RmsSetDeviceAutoRegister(CHAR value){
    STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
    
    // create send command
    rmsCommand = RmsPackCmdHeader(RMS_EVENT_DEVICE_AUTO_REGISTER);
    
    if(value){
	rmsCommand = RmsPackCmdParam(rmsCommand, 'true');
	
    } else {
	rmsCommand = RmsPackCmdParam(rmsCommand, 'false');	
    }
    SEND_COMMAND vdvRMS,rmsCommand;
    
    RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsGetDeviceAutoRegisterFilter                   *)
(*                                                         *)
(* Desc:  Gets device auto register filter configuration   *)
(*                                                         *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsGetDeviceAutoRegisterFilter()
{
    STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
    
    // create send command
    rmsCommand = RmsPackCmdHeader(RMS_EVENT_DEVICE_AUTO_REGISTER_FILTER_REQUEST);
    SEND_COMMAND vdvRMS, rmsCommand;
    
    RETURN TRUE;
}


(***************************************************************)
(* Name:  RmsGetDeviceAutoRegister                  	       *)
(*                                                             *)
(* Desc:  Sets device auto register configuration (true|false) *)
(*                                                             *)
(*                                                             *)
(* Rtrn:  1 if call was successful                             *)
(*        0 if call was unsuccessful                           *)
(***************************************************************)

DEFINE_FUNCTION CHAR RmsSetDeviceAutoRegisterFilter(DEV devices[]){
    STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];
    STACK_VAR INTEGER index;
    STACK_VAR CHAR inputString[1000];
    
    // create send command
    rmsCommand = RmsPackCmdHeader(RMS_EVENT_DEVICE_AUTO_REGISTER_FILTER);
    IF(1 == LENGTH_ARRAY(devices)){
	inputString = ITOA(devices[1].number);
    } ELSE IF(1 < LENGTH_ARRAY(devices)){
	inputString = ITOA(devices[1].number);
	FOR(index = 2; index <= LENGTH_ARRAY(devices); index ++){
	    inputString = "inputString,',',ITOA(devices[index].number)"; 
	}
    } ELSE {
	inputString = '';
    }    
    
    rmsCommand = RmsPackCmdParam(rmsCommand, inputString);
    
    SEND_COMMAND vdvRMS,rmsCommand;
    
    RETURN TRUE;
}

#END_IF // __RMS_API__


