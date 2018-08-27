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
MODULE_NAME='RmsPowerDistributionUnitMonitor'(DEV vdvRMS,
                                              DEV dvMonitoredDevice,
                                              DEV dvPowerMonitoredAssets[])

(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

// ---------------------------------------------------------
// Power Monitoring Information
// ---------------------------------------------------------
//
// This module will send the following monitored changes
// immediately to the RMS server:
//
// - Power State Change
// - Power Sense Change
// - Overcurrent Alarm & Overcurrent Load (Amps) Value
//
// All other monitored information is buffered locally in
// a tracking cache variable and only transmitted to RMS
// every 30 seconds.  This is to prevent frequent PDU
// changes from flooding the RMS system with a huge volume
// of parameter change updates.  These buffered parameters
// include:
//
// - voltage
// - power consumption rate (Watts)
// - current (Amps)
// - power factor (W/VA)
// - energy consumed (kWh)
// - temperature
//
// Additionally, these buffered parameter values are also
// only updated in RMS if the change represents a significant
// delta value that exceeds a minimum defined threshold.  This
// prevents minor fluxuating changes from constantly sending
// updated parameter values to RMS for insignificant changes.
// All the minimum thresholds are defined as constants in the
// code below.  This can be changed to meet the tolerances
// required in a specific implementation, but be sure not to
// define a threshold value too low that will generate
// unnecessary and a constant stream up parameter updates to
// the RMS server.

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

CHAR MONITOR_NAME[]       = 'RMS Power Distribution Unit Monitor';
CHAR MONITOR_DEBUG_NAME[] = 'RmsPDUMon';
CHAR MONITOR_VERSION[]    = '4.6.7';
CHAR MONITOR_ASSET_TYPE[] = 'PowerDevice';
CHAR MONITOR_ASSET_NAME[] = 'NXA-PDU-1508-8';

// include this precompiler directive to
// print strings to the telnet console
// for PDU status / information
//#DEFINE DIAGNOSTICS_OUTPUT

// this constant device the maximum number
// of outlets (and AxLink devices) monitored.
CHAR MAX_OUTLETS = 8;

// this constant device the maximum number
// of AxLink bus available on the PDU.
CHAR MAX_AXLINK_BUS = 2;

// this constant device the number
// of temperature readings used in
// the temperature averaging calculations
CHAR MAX_TEMPERATURE_READINGS = 10;

// Define if this PDU is using a temperature sensor
#WARN 'Define is the PDU is using a temperature sensor'
#DEFINE HAS_TEMPERATURE_SENSOR
VOLATILE CHAR temperatureSensorName[] = 'Temperature';

// RMS setup friendly names for each outlet
#WARN 'Define the power outlet names here ...'
VOLATILE CHAR powerOutletNames[][11]  =  { 'Outlet 1',
                                           'Outlet 2',
                                           'Outlet 3',
                                           'Outlet 4',
                                           'Outlet 5',
                                           'Outlet 6',
                                           'Outlet 7',
                                           'Outlet 8',
                                           'All Outlets'};  // this last name is a special placeholder for ALL OUTLETS


// RMS setup friendly names for each AxLink bus
#WARN 'Define the AxLink bus names here ...'
VOLATILE CHAR axLinkBusNames[][17]  =  { 'AxLink Bus 1',
                                         'AxLink Bus 2',
                                         'All AxLink Busses'};  // this last name is a special placeholder for ALL AXLINK BUSSES



// Define a minimum delta change threshold for the power consumption rate (watts)
// values so that the parameter updates sent to the RMS server
// are only sent when the power wattage levels meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the power levels.
FLOAT PDU_POWER_MINIMUM_CHANGE_THRESHOLD = 2.0; // watts

// Define a minimum delta change threshold for the current (amps)
// values so that the parameter updates sent to the RMS server
// are only sent when the current amperage levels meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the current levels.
FLOAT PDU_CURRENT_MINIMUM_CHANGE_THRESHOLD = 0.1; // amps

// Define a minimum delta change threshold for the power factor (W/VA)
// values so that the parameter updates sent to the RMS server
// are only sent when the power factor levels meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the power factor levels.
FLOAT PDU_POWER_FACTOR_MINIMUM_CHANGE_THRESHOLD = 1.5; // W/VA

// Define a minimum delta change threshold for the energy consumption (kWh)
// values so that the parameter updates sent to the RMS server
// are only sent when the energy consumption meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the energy consumption levels.
FLOAT PDU_ENERGY_MINIMUM_CHANGE_THRESHOLD = 0.1; // kWh

// Define a minimum delta change threshold for the circuit voltage (V)
// values so that the parameter updates sent to the RMS server
// are only sent when the circiut voltage meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the circuit voltage levels.
FLOAT PDU_VOLTAGE_MINIMUM_CHANGE_THRESHOLD = 3.0;         // volts : hi voltage (~120V/240 AC)
FLOAT PDU_AXLINK_VOLTAGE_MINIMUM_CHANGE_THRESHOLD = 2.0;  // volts : low voltage (~12V DC)

// Define a minimum delta change threshold for the temerature
// values so that the parameter updates sent to the RMS server
// are only sent when the temperature meets or exceeds
// this threshold.  This will prevent excessive parameter
// updates from being sent to RMS for minor fluxuating
// changes in the energy consumption levels.
FLOAT PDU_TEMPERATURE_MINIMUM_CHANGE_THRESHOLD = 2.0;  // degrees F or C

// RMS PDU Monitoring Timeline
INTEGER TL_MONITOR = 1;
LONG    PDUMonitoringTimeArray[1] = {30000};  // repeat every 30 seconds

// Including the RmsMonitorCommon.AXI will listen for RMS
// asset monitoring notification events and invoke callback
// methods to notify this program when these event occur.

// subscribe to one of the non-default callback methods to listen
// for all event notification for assets registered.
// this callback event will invoke the 'RmsEventRelayAssetRegistered' method
#DEFINE INCLUDE_RMS_EVENT_ASSET_REGISTERED_RELAY_CALLBACK

// include RMS MONITOR COMMON AXI
#INCLUDE 'RmsMonitorCommon';


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

// the following data structures are used to
// store power and energy usage state information

STRUCTURE PduEntityValue
{
  FLOAT value;
  CHAR  dirty;
}

STRUCTURE PduOutletState
{
  PduEntityValue pduPower;
  PduEntityValue current;
  PduEntityValue powerFactor;
  PduEntityValue energy;
  PduEntityValue overcurrentLoad;
  CHAR  overcurrentAlarm;
  CHAR  assetClientKey[50];
  CHAR  assetRegistered;
}

STRUCTURE PduAxLinkBusState
{
  PduEntityValue pduPower;
  PduEntityValue current;
}

STRUCTURE PduChasisState
{
  CHAR allowParameterUpdates;
  PduEntityValue inputVoltage;
  PduEntityValue axLinkVoltage;
  PduEntityValue temperature;
  FLOAT temperatureHistory[MAX_TEMPERATURE_READINGS];
  PduEntityValue overcurrentLoad;
  CHAR  overcurrentAlarm;
  CHAR  serialNumber[20];
  PduAxLinkBusState axLinkBus[MAX_AXLINK_BUS];
  PduOutletState    outlet[MAX_OUTLETS];
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

// device variable array to store a device ID for
// each of the 8 power outlets on the PDU chasis
DEV dvPDU_Outlet[MAX_OUTLETS];

// tracking data object for PDU states
// this cache variable will contain the last energy/power
// parameter values that were sent to the RMS server.
PduChasisState pduCache;

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(***********************************************************)
(* Name:  RmsEventRelayAssetRegistered                     *)
(* Args:  assetClientKey - unique identifier key for each  *)
(*                         asset.                          *)
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
DEFINE_FUNCTION RmsEventRelayAssetRegistered(CHAR registeredAssetClientKey[], LONG assetId, CHAR newAssetRegistration, CHAR registeredAssetDps[])
{
  STACK_VAR INTEGER index;

  // perform a lookup of the device client key
  // string in the power monitored device array
  index = RmsDeviceStringInList(registeredAssetClientKey,dvPowerMonitoredAssets);
  if (index == 0) 
  {
    index = RmsDeviceStringInList(registeredAssetDps,dvPowerMonitoredAssets);
  }

  // if a match was found, then register/update
  // the power monitoring asset parameters
  IF(index > 0 && index <= MAX_OUTLETS)
  {
    // store the asset registration information in the PDU cache state
    pduCache.outlet[index].assetClientKey = registeredAssetClientKey;
    pduCache.outlet[index].assetRegistered = TRUE;

    IF(newAssetRegistration)
    {
      // register the power monitoring power consumption parameter
      RmsAssetParameterEnqueueDecimal(registeredAssetClientKey,
                                      'asset.power.consumption',
                                      'Power Consumption Rate',
                                      'Last reported power consumption rate for this asset.',
                                      RMS_ASSET_PARAM_TYPE_POWER_CONSUMPTION,
                                      pduCache.outlet[index].pduPower.value,
                                      0,0,
                                      'Watts',
                                      RMS_ALLOW_RESET_NO,
                                      0,
                                      RMS_TRACK_CHANGES_YES);

      // submit all parameter registrations
      RmsAssetParameterSubmit(registeredAssetClientKey);
    }
    ELSE
    {
      // updated the power monitoring power consumption parameter
      RmsAssetParameterSetValueDecimal(registeredAssetClientKey,'asset.power.consumption',pduCache.outlet[index].pduPower.value);
    }
  }
}


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
  // setup optional asset properties
  //asset.name        = 'My Custom Device';
  //asset.description = 'Asset Description Goes Here!';

  // override the serial number, providing the
  // PDU's real serial number and model name
  asset.serialNumber = pduCache.serialNumber;
  asset.modelName = 'NXA-PDU-1508-8';

  // perform registration of this asset
  RmsAssetRegisterAmxDevice(dvMonitoredDevice, asset);

  // allow parameter updates to RMS
  pduCache.allowParameterUpdates = TRUE;

  // create the power monitoring timeline to send
  // updated parameter values to the RMS server.
  IF(!TIMELINE_ACTIVE(TL_MONITOR))
  {
    TIMELINE_CREATE(TL_MONITOR,PDUMonitoringTimeArray,1,TIMELINE_RELATIVE,TIMELINE_REPEAT);
  }
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
  STACK_VAR INTEGER index;

  // register the default "Device Online" parameter
  RmsAssetOnlineParameterEnqueue (assetClientKey, DEVICE_ID(dvMonitoredDevice));

  #IF_DEFINED HAS_TEMPERATURE_SENSOR

  // unit temperature probe
  RmsAssetParameterEnqueueDecimal(assetClientKey,
                                  'pdu.temperature',
                                  temperatureSensorName,
                                  'External temperature sensor',
                                  RMS_ASSET_PARAM_TYPE_TEMPERATURE,
                                  pduCache.temperature.value,0,0,
                                  GetTemperatureUnits(),
                                  RMS_ALLOW_RESET_NO,
                                  0,
                                  RMS_TRACK_CHANGES_YES);

  #END_IF

  // unit input voltage
  RmsAssetParameterEnqueueDecimal(assetClientKey,
                                  'pdu.input.voltage',
                                  'Input Voltage',
                                  'Last reported input voltage into the PDU.',
                                  RMS_ASSET_PARAM_TYPE_NONE,
                                  pduCache.inputVoltage.value,0,0,
                                  'Volts',
                                  RMS_ALLOW_RESET_NO,
                                  0,
                                  RMS_TRACK_CHANGES_NO);

  // unit AxLink voltage
  RmsAssetParameterEnqueueDecimal(assetClientKey,
                                  'pdu.input.axlink.voltage',
                                  'AxLink Voltage',
                                  'Last reported voltage on the AxLink bus.',
                                  RMS_ASSET_PARAM_TYPE_NONE,
                                  pduCache.axLinkVoltage.value,0,0,
                                  'Volts',
                                  RMS_ALLOW_RESET_NO,
                                  0,
                                  RMS_TRACK_CHANGES_NO);

  // unit overcurrent alarm
  RmsAssetParameterEnqueueBoolean(assetClientKey,
                                  'pdu.overcurrent.alarm',
                                  'Chasis Overcurrent Alarm',
                                  'Last reported input voltage into the PDU.',
                                  RMS_ASSET_PARAM_TYPE_NONE,
                                  pduCache.overcurrentAlarm,
                                  RMS_ALLOW_RESET_YES,
                                  0,
                                  RMS_TRACK_CHANGES_YES);

  // create a threshold for when the OVERCURRENT alarm occurs
  RmsAssetParameterThresholdEnqueue(assetClientKey,
                                      'pdu.overcurrent.alarm',
                                      'Overcurrent',
                                      RMS_STATUS_TYPE_MAINTENANCE,
                                      RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL,
                                      'true');

  // unit overcurrent load (Amps)
  RmsAssetParameterEnqueueDecimal(assetClientKey,
                                  'pdu.overcurrent.load',
                                  'Chasis Overcurrent Load',
                                  'Load current detected on overcurrent alarm.',
                                  RMS_ASSET_PARAM_TYPE_NONE,
                                  pduCache.overcurrentLoad.value,0,0,
                                  'Amps',
                                  RMS_ALLOW_RESET_NO,
                                  0,
                                  RMS_TRACK_CHANGES_YES);


  // iterate over all the AxLink busses and register their parameters
  FOR(index = 1; index <= MAX_AXLINK_BUS; index++)
  {
    RmsAssetParameterEnqueueBoolean(assetClientKey,
                                    "'pdu.axlink.bus.power.state.',ITOA(index)",
                                    "axLinkBusNames[index],' - Power State'",
                                    "'On/Off power state for AxLink Bus #',ITOA(index)",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    [dvPDU_Outlet[index],3],
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_YES);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.axlink.bus.power.consumption.',ITOA(index)",
                                    "axLinkBusNames[index],' - Power Consumption Rate'",
                                    "'Last reported power consumption rate for AxLink Bus #: ',ITOA(index)",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.axLinkBus[index].pduPower.value,0,0,
                                    'Watts',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.axlink.bus.current.',ITOA(index)",
                                    "axLinkBusNames[index],' - Current (Load)'",
                                    "'Last reported electrical current load for AxLink Bus #: ',ITOA(index)",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.axLinkBus[index].current.value,0,0,
                                    'Amps',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);
  }

  // iterate over all the power outlets and register their parameters
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
    RmsAssetParameterEnqueueBoolean(assetClientKey,
                                    "'pdu.outlet.power.state.',ITOA(index)",
                                    "powerOutletNames[index],' - Power State'",
                                    "'On/Off power state for outlet: ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    [dvPDU_Outlet[index],1],
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_YES);

    RmsAssetParameterEnqueueBoolean(assetClientKey,
                                    "'pdu.outlet.power.sense.',ITOA(index)",
                                    "powerOutletNames[index],' - Power Sensor'",
                                    "'Power sensor status for outlet: ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    [dvPDU_Outlet[index],255],
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.outlet.power.consumption.',ITOA(index)",
                                    "powerOutletNames[index],' - Power Consumption Rate'",
                                    "'Last reported power consumption rate for outlet #',ITOA(index)",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].pduPower.value,0,0,
                                    'Watts',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.outlet.current.',ITOA(index)",
                                    "powerOutletNames[index],' - Current (Load)'",
                                    "'Last reported electrical current load for outlet: ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].current.value,0,0,
                                    'Amps',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.outlet.power.factor.',ITOA(index)",
                                    "powerOutletNames[index],' - Power Factor'",
                                    "'Power factor on: ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].powerFactor.value,0,0,
                                    'W/VA',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.outlet.energy.',ITOA(index)",
                                    "powerOutletNames[index],' - Energy Consumed'",
                                    "'Total energy consumed since the last reset on : ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].energy.value,0,0,
                                    'kWh',
                                    RMS_ALLOW_RESET_YES,
                                    0,
                                    RMS_TRACK_CHANGES_NO);

    RmsAssetParameterEnqueueBoolean(assetClientKey,
                                    "'pdu.outlet.overcurrent.alarm.',ITOA(index)",
                                    "powerOutletNames[index],' - Overcurrent Alarm'",
                                    "'An overcurrent alarm has been detected on: ',powerOutletNames[index]",
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].overcurrentAlarm,
                                    RMS_ALLOW_RESET_YES,
                                    0,
                                    RMS_TRACK_CHANGES_YES);

    // create a threshold for when the OVERCURRENT condition occurs
    RmsAssetParameterThresholdEnqueue(assetClientKey,
                                      "'pdu.outlet.overcurrent.alarm.',ITOA(index)",
                                      'Overcurrent',
                                      RMS_STATUS_TYPE_MAINTENANCE,
                                      RMS_ASSET_PARAM_THRESHOLD_COMPARISON_EQUAL,
                                      'true');

    // unit overcurrent load (Amps)
    RmsAssetParameterEnqueueDecimal(assetClientKey,
                                    "'pdu.outlet.overcurrent.load.',ITOA(index)",
                                    "powerOutletNames[index],' - Overcurrent Load'",
                                    'Load current detected on overcurrent alarm.',
                                    RMS_ASSET_PARAM_TYPE_NONE,
                                    pduCache.outlet[index].overcurrentLoad.value,0,0,
                                    'Amps',
                                    RMS_ALLOW_RESET_NO,
                                    0,
                                    RMS_TRACK_CHANGES_YES);
  }

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

  // allow parameter updates to RMS
  pduCache.allowParameterUpdates = TRUE;

  // create the power monitoring timeline to send
  // updated parameter values to the RMS server.
  IF(!TIMELINE_ACTIVE(TL_MONITOR))
  {
    TIMELINE_CREATE(TL_MONITOR,PDUMonitoringTimeArray,1,TIMELINE_RELATIVE,TIMELINE_REPEAT);
  }

  // update device online parameter value
  RmsAssetOnlineParameterUpdate(assetClientKey, DEVICE_ID(dvMonitoredDevice));

  // syncronize power/energy management parameter values to the RMS server
  SyncPDUParameterValues();
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
  STACK_VAR CHAR trash[5];
            INTEGER index;

  // if your monitoring module performs any parameter
  // value tracking, then you may want to update the
  // tracking value based on the new reset value
  // received from the RMS server.

  SELECT
  {
    // reset the chasis overcurrent alarm state and load value
    ACTIVE(parameterKey == 'pdu.overcurrent.alarm'):
    {
      DEBUG("'RESET PDU OUTLET OVERCURRENT ALARM on chasis: [',parameterValue,']'");

      IF(RmsBooleanValue(parameterValue) == TRUE)
      {
        UpdatePDUOvercurrentParameters(TRUE,pduCache.overcurrentLoad.value);
      }
      ELSE
      {
        UpdatePDUOvercurrentParameters(FALSE,0);
      }
    }

    // reset an individual outlet overcurrent alarm state and load value
    ACTIVE(LEFT_STRING(parameterKey,29) == 'pdu.outlet.overcurrent.alarm.'):
    {
      trash = GET_BUFFER_STRING(parameterKey,29);
      index = ATOI(parameterKey);

      // verify the index number is within bounds
      IF(index > 0 && index <= MAX_OUTLETS)
      {
        DEBUG("'RESET PDU OUTLET OVERCURRENT ALARM on OUTLET #',ITOA(index),' : [',parameterValue,']'");

        IF(RmsBooleanValue(parameterValue) == TRUE)
        {
          UpdatePDUOutletOvercurrentParameters(index,TRUE,pduCache.outlet[index].overcurrentLoad.value);
        }
        ELSE
        {
          UpdatePDUOutletOvercurrentParameters(index,FALSE,0);
        }
      }
    }

    // reset an individual outlet accumulated energy consumption
    ACTIVE(LEFT_STRING(parameterKey,18) == 'pdu.outlet.energy.'):
    {
      trash = GET_BUFFER_STRING(parameterKey,18);
      index = ATOI(parameterKey);

      // verify the index number is within bounds
      IF(index > 0 && index <= MAX_OUTLETS)
      {
        DEBUG("'RESET PDU OUTLET ENERGY CONSUMPTION on OUTLET #',ITOA(index)");

        // reset energy consumption by sending o '0' value to the PDU
        SEND_LEVEL dvPDU_Outlet[index], 4, 0;
      }
    }
  }
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
  STACK_VAR INTEGER index;
            CHAR    metadataRegistered;

  // register all asset metadata properties now.
  FOR(index = 1; index <=LENGTH_ARRAY(dvPowerMonitoredAssets); index++)
  {
    IF(dvPowerMonitoredAssets[index] != 0:0:0)  // ignore null device records
    {
      RmsAssetMetadataEnqueueString(assetClientKey, "'pdu.outlet.asset.clientKey.',ITOA(index)", "'Asset Assigned to Outlet #',ITOA(index)",RmsDevToString(dvPowerMonitoredAssets[index]));
      metadataRegistered = TRUE;
    }
  }

  // submit metadata registrations
  IF(metadataRegistered == TRUE)
  {
    RmsAssetMetadataSubmit(assetClientKey);
  }
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
  // This callback method is invoked when either the RMS server connection
  // has been offline or this monitored device has been offline from some
  // amount of time.   Traditionally, asset metadata is relatively static
  // information and thus does not require any synchronization of values.
  // However, this callback method does provide the opportunity to perform
  // any necessary metadata updates if your implementation does include
  // any dynamic metadata values.
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
  // set Power Outlet ON/OFF
  RmsAssetControlMethodEnqueue(assetClientKey,'pdu.outlet.power','Outlet Power', 'Turn power ON/OFF for specific outlet.');
  RmsAssetControlMethodArgumentEnumEx(assetClientKey,'pdu.outlet.power',0,'Outlet','Select the power outlet to control.',powerOutletNames[1],powerOutletNames);
  RmsAssetControlMethodArgumentEnum(assetClientKey,'pdu.outlet.power',1,'Power State','Select the power state to apply to the outlet.','On','Off|On');

  // set AxLink Bus Power ON/OFF
  RmsAssetControlMethodEnqueue(assetClientKey,'pdu.axlink.bus.power','AxLink Bus Power', 'Turn power ON/OFF for specific AxLink bus.');
  RmsAssetControlMethodArgumentEnumEx(assetClientKey,'pdu.axlink.bus.power',0,'AxLink Bus','Select the AxLink bus to control.',axLinkBusNames[1],axLinkBusNames);
  RmsAssetControlMethodArgumentEnum(assetClientKey,'pdu.axlink.bus.power',1,'Power State','Select the power state to apply to the AxLink bus.','On','Off|On');

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
{
  STACK_VAR CHAR paramName[RMS_MAX_PARAM_LEN];
            CHAR paramPowerState[RMS_MAX_PARAM_LEN];
            CHAR powerState;
            INTEGER index;
            INTEGER loop;

  SELECT
  {
    // set outlet ON
    ACTIVE(methodKey == 'pdu.outlet.power'):
    {
      // parse outlet name
      paramName = RmsParseCmdParam(arguments);

      // lookup power outlet zone index from name
      index = GetOutletIndexByName(paramName)

      // parse ON/OFF state
      paramPowerState = RmsParseCmdParam(arguments);
      powerState = (LOWER_STRING(paramPowerState) == 'on');

      // if a valid index was returned, then send the instruction
      // to the PDU device to turn ON the outlet
      IF(index > 0 && index <= MAX_OUTLETS)   // SINGLE OUTLET
      {
        [dvPDU_Outlet[index],1] = powerState;
      }
      ELSE IF(index == (MAX_OUTLETS+1))  // ALL OUTLETS
      {
        FOR(loop=1; loop <= MAX_OUTLETS; loop++)
        {
          [dvPDU_Outlet[loop],1] = powerState;
        }
      }
    }

    // set AxLink Bus Power ON/OFF
    ACTIVE(methodKey == 'pdu.axlink.bus.power'):
    {
      // parse AxLink bus ID
      paramName = RmsParseCmdParam(arguments);

      // lookup AxLink bus index from name
      index = GetAxLinkIndexByName(paramName)

      // parse ON/OFF state
      paramPowerState = RmsParseCmdParam(arguments);
      powerState = (LOWER_STRING(paramPowerState) == 'on');

      // if a valid index was returned, then send the instruction
      // to the PDU device to turn ON the AxLink bus
      IF(index > 0 && index <= MAX_AXLINK_BUS)   // SINGLE AXLINK BUS
      {
        [dvPDU_Outlet[index],3] = powerState;
      }
      ELSE IF(index == (MAX_AXLINK_BUS+1))  // ALL AXLINK BUSSES
      {
        FOR(loop=1; loop <= MAX_AXLINK_BUS; loop++)
        {
          [dvPDU_Outlet[loop],3] = powerState;
        }
      }
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

  // the following is an example that sets all
  // power outlets and AxLink busses ON or OFF based
  // on the system power state change notification.
  /*
  [dvPDU_Outlet[1],1] = (powerOn);  // Power Outlet #1
  [dvPDU_Outlet[2],1] = (powerOn);  // Power Outlet #2
  [dvPDU_Outlet[3],1] = (powerOn);  // Power Outlet #3
  [dvPDU_Outlet[4],1] = (powerOn);  // Power Outlet #4
  [dvPDU_Outlet[5],1] = (powerOn);  // Power Outlet #5
  [dvPDU_Outlet[6],1] = (powerOn);  // Power Outlet #6
  [dvPDU_Outlet[7],1] = (powerOn);  // Power Outlet #7
  [dvPDU_Outlet[8],1] = (powerOn);  // Power Outlet #8
  [dvPDU_Outlet[1],3] = (powerOn);  // AxLink Bus #1
  [dvPDU_Outlet[2],3] = (powerOn);  // AxLink Bus #2
  */
}


(*********************************************)
(* Call Name: SystemModeChanged              *)
(* Function:  the system has received a      *)
(*            mode change notification.      *)
(*********************************************)
DEFINE_FUNCTION SystemModeChanged(CHAR modeName[])
{
  // optionally implement logic based on
  // newly selected system mode name.
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
DEFINE_FUNCTION InitilizeModule()
{
  STACK_VAR INTEGER index;

  // loop over the PDU outlets and create a device variable for each
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
    dvPDU_Outlet[index] = (dvMonitoredDevice.NUMBER+(index-1)):dvMonitoredDevice.PORT:dvMonitoredDevice.SYSTEM;
  }

  // rebuild the event table now that the device IDs are defined
  REBUILD_EVENT();
}


(***********************************************************)
(* Name:  GetOutletIndexByName                             *)
(* Args:  outletName - friendly name of power outlet       *)
(*                                                         *)
(* Desc:  This is a utility method to lookup the index     *)
(*        value of an outlet friendly name in the          *)
(*        'powerOutletNames' array.                        *)
(***********************************************************)
DEFINE_FUNCTION INTEGER GetOutletIndexByName(CHAR outletName[])
{
  STACK_VAR INTEGER index;

  // iterate over power outlet names and return index if a match is found
  FOR(index = 1; index <= LENGTH_ARRAY(powerOutletNames); index++)
  {
     IF(LOWER_STRING(powerOutletNames[index]) == LOWER_STRING(outletName))
     {
       RETURN index;
     }
  }

  // outlet name not found
  RETURN 0;
}


(***********************************************************)
(* Name:  GetAxLinkIndexByName                             *)
(* Args:  axLinkBusName - friendly name of power outlet    *)
(*                                                         *)
(* Desc:  This is a utility method to lookup the index     *)
(*        value of an AxLink bus name in the               *)
(*        'axLinkBusNames' array.                          *)
(***********************************************************)
DEFINE_FUNCTION INTEGER GetAxLinkIndexByName(CHAR axLinkBusName[])
{
  STACK_VAR INTEGER index;

  // iterate over AxLink bus names and return index if a match is found
  FOR(index = 1; index <= LENGTH_ARRAY(axLinkBusNames); index++)
  {
     IF(LOWER_STRING(axLinkBusNames[index]) == LOWER_STRING(axLinkBusName))
     {
       RETURN index;
     }
  }

  // AxLink bus name not found
  RETURN 0;
}


(***********************************************************)
(* Name:  GetOutletIndexByDevice                           *)
(* Args:  outletDevice - specific outlet device instance   *)
(*                                                         *)
(* Desc:  This is a utility method to lookup the index     *)
(*        value of a specific device <DPS> in the          *)
(*        'dvPDU_Outlet' device array.                     *)
(***********************************************************)
DEFINE_FUNCTION INTEGER GetOutletIndexByDevice(DEV outletDevice)
{
  STACK_VAR INTEGER index;

  // iterate over power outlet names and return index if a match is found
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
     IF(dvPDU_Outlet[index].NUMBER == outletDevice.NUMBER &&
        dvPDU_Outlet[index].PORT == outletDevice.PORT)
     {
       RETURN index;
     }
  }

  // outlet device not found
  RETURN 0;
}


(***********************************************************)
(* Name:  GetTemperatureUnits                              *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a utility method to obtain the units     *)
(*        label for the temperature scale that the PDU     *)
(*        is configured to output.                         *)
(***********************************************************)
DEFINE_FUNCTION CHAR[15] GetTemperatureUnits()
{
  // temperature scale is provided on channel 2 of the PDU base device
  IF([dvMonitoredDevice,2])
  {
    RETURN "'Fahrenheit'";  // byte 167 is the degrees symbol in ASCII
  }
  ELSE
  {
    RETURN "'Celsius'";  // byte 167 is the degrees symbol in ASCII
  }
}


(***********************************************************)
(* Name:  Scale                                            *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a utility method to convert a provided   *)
(*        value into a scaled value by the scale factor.   *)
(*        Example:  value 501 scaled by 10 factor = 50.1   *)
(***********************************************************)
DEFINE_FUNCTION FLOAT Scale(FLOAT originalValue, FLOAT scaleFactor)
{
  RETURN originalValue/scaleFactor;
}


(***********************************************************)
(* Name:  ResetPDUParameterValues                          *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a utility method to reset all of the     *)
(*        power monitored parameters in RMS.  This is      *)
(*        typically invoked in an OFFLINE scenario.        *)
(***********************************************************)
DEFINE_FUNCTION ResetPDUParameterValues()
{
  STACK_VAR INTEGER index;

  #IF_DEFINED HAS_TEMPERATURE_SENSOR

  // reset parameter value for chasis temperature voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.temperature',0);

  #END_IF

  // reset parameter value chasis input voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.voltage',0);

  // reset parameter value for chasis AxLink voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.axlink.voltage',0);

  // reset parameter value for chasis overcurent load (Apms)
  RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'pdu.overcurrent.alarm',0);

  // reset parameter value for chasis overcurent load (Apms)
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.overcurrent.load',0);

  // reset all AxLink bus energy values
  FOR(index = 1; index <= MAX_AXLINK_BUS; index++)
  {
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.axlink.bus.power.state.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.power.consumption.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.current.',ITOA(index)",0);
  }

  // reset all power outlet energy values
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.power.state.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.power.sense.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.consumption.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.current.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.factor.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.energy.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.overcurrent.alarm.',ITOA(index)",0);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.overcurrent.load.',ITOA(index)",0);

    // reset the energy monitoring power consumption parameter
    // on the associated asset that is mapped to this outlet
    // this paramater value update, since it is performed on another asset, should not be enqueued, but rather sent immediately
    RmsAssetParameterSetValueDecimal(pduCache.outlet[index].assetClientKey,'asset.power.consumption',0);
  }

  // submit all the pending parameter updates now
  RmsAssetParameterUpdatesSubmit(assetClientKey);
}

(***********************************************************)
(* Name:  SyncPDUParameterValues                           *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a utility method to synchronize and send *)
(*        all the cached state parameter values for the    *)
(*        PDU device to the RMS server.                    *)
(***********************************************************)
DEFINE_FUNCTION SyncPDUParameterValues()
{
  STACK_VAR INTEGER index;

  #IF_DEFINED HAS_TEMPERATURE_SENSOR

  // send parameter update to RMS for chasis temperature voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.temperature',pduCache.temperature.value);
  pduCache.temperature.dirty = FALSE;

  #END_IF

  // send parameter update to RMS for chasis input voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.voltage',pduCache.inputVoltage.value);

  // send parameter update to RMS for chasis AxLink voltage
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.axlink.voltage',pduCache.axLinkVoltage.value);

  // send parameter update to RMS for chasis overcurent load (Apms)
  RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,'pdu.overcurrent.alarm',pduCache.overcurrentAlarm);

  // send parameter update to RMS for chasis overcurent load (Apms)
  RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.overcurrent.load',pduCache.overcurrentLoad.value);

  // reset all dirty tracking states
  pduCache.inputVoltage.dirty = FALSE;
  pduCache.axLinkVoltage.dirty = FALSE;
  pduCache.overcurrentLoad.dirty = FALSE;

  // synchronize all AxLink bus energy values
  FOR(index = 1; index <= MAX_AXLINK_BUS; index++)
  {
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.axlink.bus.power.state.',ITOA(index)",[dvPDU_Outlet[index],3]);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.power.consumption.',ITOA(index)",pduCache.axLinkBus[index].pduPower.value);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.current.',ITOA(index)",pduCache.axLinkBus[index].current.value);

    // reset all dirty tracking states
    pduCache.axLinkBus[index].pduPower.dirty = FALSE;
    pduCache.axLinkBus[index].current.dirty = FALSE;
  }

  // synchronize all power outlet energy values
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.power.state.',ITOA(index)",[dvPDU_Outlet[index],1]);
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.power.sense.',ITOA(index)",[dvPDU_Outlet[index],255]);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.consumption.',ITOA(index)",pduCache.outlet[index].pduPower.value);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.current.',ITOA(index)",pduCache.outlet[index].current.value);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.factor.',ITOA(index)",pduCache.outlet[index].powerFactor.value);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.energy.',ITOA(index)",pduCache.outlet[index].energy.value);
    RmsAssetParameterEnqueueSetValueBoolean(assetClientKey,"'pdu.outlet.overcurrent.alarm.',ITOA(index)",pduCache.outlet[index].overcurrentAlarm);
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.overcurrent.load.',ITOA(index)",pduCache.outlet[index].overcurrentLoad.value);

    // reset all dirty tracking states
    pduCache.outlet[index].pduPower.dirty = FALSE;
    pduCache.outlet[index].current.dirty = FALSE;
    pduCache.outlet[index].powerFactor.dirty = FALSE;
    pduCache.outlet[index].energy.dirty = FALSE;
    pduCache.outlet[index].overcurrentLoad.dirty = FALSE;

    // update the energy monitoring power consumption parameter
    // on the associated asset that is mapped to this outlet
    // (send this asset parameter update immediately)
    IF(pduCache.outlet[index].assetClientKey != '')
    {
      // this paramater value update, since it is performed on another asset, should not be enqueued, but rather sent immediately
      RmsAssetParameterSetValueDecimal(pduCache.outlet[index].assetClientKey,'asset.power.consumption',pduCache.outlet[index].pduPower.value);
    }
  }

  // submit all the pending parameter updates now
  RmsAssetParameterUpdatesSubmit(assetClientKey);
}


(***********************************************************)
(* Name:  SendPDUParameterValueChanges                     *)
(* Args:  -none-                                           *)
(*                                                         *)
(* Desc:  This is a utility method to send all changed     *)
(*        parameter values for thePDU device to RMS.       *)
(***********************************************************)
DEFINE_FUNCTION SendPDUParameterValueChanges()
{
  STACK_VAR INTEGER index;
            CHAR    updateEnqueued;

  // do not send parameter updates to RMS if the allow
  // flag is not enabled.  This flag prevent redendant event
  // updated from sending duplicate values to RMS during
  // a device ONLINE/OFFLINE scenario.
  IF(pduCache.allowParameterUpdates == FALSE)
  {
    RETURN;
  }

  #IF_DEFINED HAS_TEMPERATURE_SENSOR

  IF(pduCache.temperature.dirty)
  {
    // send parameter update to RMS for chasis temperature voltage
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.temperature',pduCache.temperature.value);
    pduCache.temperature.dirty = FALSE;
    updateEnqueued = TRUE;
  }

  #END_IF

  // send parameter update to RMS for chasis input voltage
  IF(pduCache.inputVoltage.dirty)
  {
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.voltage',pduCache.inputVoltage.value);
    pduCache.inputVoltage.dirty = FALSE;
    updateEnqueued = TRUE;
  }

  // send parameter update to RMS for chasis AxLink voltage
  IF(pduCache.axLinkVoltage.dirty)
  {
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.input.axlink.voltage',pduCache.axLinkVoltage.value);
    pduCache.axLinkVoltage.dirty = FALSE;
    updateEnqueued = TRUE;
  }

  // send parameter update to RMS for chasis overcurent load (Apms)
  IF(pduCache.overcurrentLoad.dirty)
  {
    RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,'pdu.overcurrent.load',pduCache.overcurrentLoad.value);
    pduCache.overcurrentLoad.dirty = FALSE;
    updateEnqueued = TRUE;
  }

  // reset all AxLink bus energy values
  FOR(index = 1; index <= MAX_AXLINK_BUS; index++)
  {
    IF(pduCache.axLinkBus[index].pduPower.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.power.consumption.',ITOA(index)",pduCache.axLinkBus[index].pduPower.value);
      pduCache.axLinkBus[index].pduPower.dirty = FALSE;
      updateEnqueued = TRUE;
    }

    IF(pduCache.axLinkBus[index].current.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.axlink.bus.current.',ITOA(index)",pduCache.axLinkBus[index].current.value);
      pduCache.axLinkBus[index].current.dirty = FALSE;
      updateEnqueued = TRUE;
    }
  }

  // reset all power outlet energy values
  FOR(index = 1; index <= MAX_OUTLETS; index++)
  {
    // update the energy monitoring power consumption parameter
    // on the associated asset that is mapped to this outlet
    IF(pduCache.outlet[index].assetRegistered && pduCache.outlet[index].pduPower.dirty)
    {
      // this paramater value update, since it is performed on another asset, should not be enqueued, but rather sent immediately
      RmsAssetParameterSetValueDecimal(pduCache.outlet[index].assetClientKey,'asset.power.consumption',pduCache.outlet[index].pduPower.value);
      updateEnqueued = TRUE;
    }

    IF(pduCache.outlet[index].pduPower.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.consumption.',ITOA(index)",pduCache.outlet[index].pduPower.value);
      pduCache.outlet[index].pduPower.dirty = FALSE;
      updateEnqueued = TRUE;
    }

    IF(pduCache.outlet[index].current.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.current.',ITOA(index)",pduCache.outlet[index].current.value);
      pduCache.outlet[index].current.dirty = FALSE;
      updateEnqueued = TRUE;
    }

    IF(pduCache.outlet[index].powerFactor.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.power.factor.',ITOA(index)",pduCache.outlet[index].powerFactor.value);
      pduCache.outlet[index].powerFactor.dirty = FALSE;
      updateEnqueued = TRUE;
    }

    IF(pduCache.outlet[index].energy.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.energy.',ITOA(index)",pduCache.outlet[index].energy.value);
      pduCache.outlet[index].energy.dirty = FALSE;
      updateEnqueued = TRUE;
    }

    IF(pduCache.outlet[index].overcurrentLoad.dirty)
    {
      RmsAssetParameterEnqueueSetValueDecimal(assetClientKey,"'pdu.outlet.overcurrent.load.',ITOA(index)",pduCache.outlet[index].overcurrentLoad.value);
      pduCache.outlet[index].overcurrentLoad.dirty = FALSE;
      updateEnqueued = TRUE;
    }
  }

  // submit all the pending parameter updates now
  IF(updateEnqueued == TRUE)
  {
    RmsAssetParameterUpdatesSubmit(assetClientKey);
  }
}


(***********************************************************)
(* Name:  UpdatePDUInputVoltageParameter                   *)
(* Args:  value - input voltage level                      *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUInputVoltageParameter(FLOAT value)
{
  // only process further if the value has changed
  IF(pduCache.inputVoltage.value == value)
    RETURN;

  // only apply the change if the new value is '0', or if the value is
  // already dirty, or if the applied change would represent a change
  // delta that meets or exceeds the minimum change threshold
  IF((value == 0) || (pduCache.inputVoltage.dirty) ||
     (ABS_VALUE(pduCache.inputVoltage.value - value) >= PDU_VOLTAGE_MINIMUM_CHANGE_THRESHOLD))
  {
      // cache new value
      pduCache.inputVoltage.value = value;
      pduCache.inputVoltage.dirty = TRUE;
   }
}


(***********************************************************)
(* Name:  UpdatePDUTemeratureParameter                     *)
(* Args:  value - tmeperature value                        *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUTemeratureParameter(FLOAT value)
{
  #IF_DEFINED HAS_TEMPERATURE_SENSOR

  // only process further if the value has changed
  IF(pduCache.temperature.value == value)
    RETURN;

  // only apply the change if the new value is '0', or if
  // the value is already dirty, or or if the applied change
  // would represent a change delta that meets or exceeds
  // the minimum change threshold
  IF((value == 0) || (pduCache.temperature.dirty) ||
     (ABS_VALUE(pduCache.temperature.value - value) >= PDU_TEMPERATURE_MINIMUM_CHANGE_THRESHOLD))
  {
    // cache new value
    pduCache.temperature.value = value;
    pduCache.temperature.dirty = TRUE;
  }

  #END_IF
}


(***********************************************************)
(* Name:  UpdatePDUAxLinkVoltageParameter                  *)
(* Args:  value - AxLink voltage level                     *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUAxLinkVoltageParameter(FLOAT value)
{
  // only process further if the value has changed
  IF(pduCache.axLinkVoltage.value == value)
    RETURN;

  // only apply the change if the new value is '0', or if the
  // value si already dirty, or if the applied change would
  // represent a change delta that meets or exceeds the
  // minimum change threshold
  IF((value == 0) || (pduCache.axLinkVoltage.dirty) ||
     (ABS_VALUE(pduCache.axLinkVoltage.value - value) >= PDU_AXLINK_VOLTAGE_MINIMUM_CHANGE_THRESHOLD))
  {
    // cache new value
    pduCache.axLinkVoltage.value = value;
    pduCache.axLinkVoltage.dirty = TRUE;
  }
}


(***********************************************************)
(* Name:  UpdatePDUOvercurrentParameters                   *)
(* Args:  alarm - Overcurent alarm tripped                 *)
(*        load - Overcurent load level                     *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOvercurrentParameters(CHAR alarm, FLOAT load)
{
  // only process further if the value has changed
  IF(pduCache.overcurrentLoad.value != load)
  {
    // only apply the change if the new value is '0', or if
    // the vlaue is already dirty, or if the applied change
    // would represent a change greater than the currently
    // set overcurrent peak value
    IF((load == 0) || (load > pduCache.overcurrentLoad.value))
    {
      // cache new value
      pduCache.overcurrentLoad.value = load;
      pduCache.overcurrentLoad.dirty = TRUE;
    }
  }

  // only apply the change if the current cached value is
  // different than the new value to apply
  IF(alarm != pduCache.overcurrentAlarm)
  {
    // cache new value
    pduCache.overcurrentAlarm = alarm;

    // send parameter update to RMS for chasis overcurrent alarm state
    RmsAssetParameterSetValueBoolean(assetClientKey,'pdu.overcurrent.alarm',pduCache.overcurrentAlarm);

    // send parameter update to RMS for chasis overcurrent load peak value
    RmsAssetParameterSetValueDecimal(assetClientKey,'pdu.overcurrent.load',pduCache.overcurrentLoad.value);
    pduCache.overcurrentLoad.dirty = FALSE;
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletOvercurrentParameters             *)
(* Args:  outletIndex - Overcurent outlet index            *)
(*        alarm - Overcurent alarm tripped                 *)
(*        load - Overcurent load level                     *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletOvercurrentParameters(INTEGER outletIndex, CHAR alarm, FLOAT load)
{
  IF(outletIndex > 0 && outletIndex <= MAX_OUTLETS)
  {
    // only process further if the value has changed
    IF(pduCache.outlet[outletIndex].overcurrentLoad.value != load)
    {
      // only apply the change if the current cached value is 0
      // or if the applied change would represent a change greater
      // then the currently set overcurrent peak value
      IF((load == 0) || (load > pduCache.outlet[outletIndex].overcurrentLoad.value))
      {
        // cache new value
        pduCache.outlet[outletIndex].overcurrentLoad.value = load;
        pduCache.outlet[outletIndex].overcurrentLoad.dirty = TRUE;
      }
    }

    // only apply the change if the current cached value is
    // different than the new value to apply
    IF(alarm != pduCache.outlet[outletIndex].overcurrentAlarm)
    {
      // cache new value
      pduCache.outlet[outletIndex].overcurrentAlarm = alarm;

      // send parameter update to RMS for outlet overcurrent alarm state
      RmsAssetParameterSetValueBoolean(assetClientKey,"'pdu.outlet.overcurrent.alarm.',ITOA(outletIndex)",pduCache.outlet[outletIndex].overcurrentAlarm);

      // send parameter update to RMS for outlet overcurrent load peak value
      RmsAssetParameterSetValueDecimal(assetClientKey,"'pdu.outlet.overcurrent.load.',ITOA(outletIndex)",pduCache.outlet[outletIndex].overcurrentLoad.value);
      pduCache.outlet[outletIndex].overcurrentLoad.dirty = FALSE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUAxLinkBusPowerStateParameter            *)
(* Args:  axLinkBusIndex - AxLink bux index that this      *)
(*                         change applies to               *)
(*                                                         *)
(* Desc:  This method is used send a power state parameter *)
(*        value change to the RMS server for a given       *)
(*        AxLink bus index.                                *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUAxLinkBusPowerStateParameter(INTEGER axLinkBusIndex)
{
  // only perform this update if the allow parameter updates flag is enabled
  IF(pduCache.allowParameterUpdates == FALSE)
  {
    RETURN;
  }

  // make sure the AxLink bus index is within bounds
  IF(axLinkBusIndex >= 1 && axLinkBusIndex <= MAX_AXLINK_BUS)
  {
    // send parameter update to RMS for AxLinkBus power state
    RmsAssetParameterSetValueBoolean(assetClientKey,
                                     "'pdu.axlink.bus.power.state.',ITOA(axLinkBusIndex)",
                                     [dvPDU_Outlet[axLinkBusIndex],3]);
  }
}


(***********************************************************)
(* Name:  UpdatePDUAxLinkBusPowerConsumptionParameter      *)
(* Args:  busIndex - bus index that this change applies to *)
(*        value - AxLink power consumption level (Watts)   *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUAxLinkBusPowerConsumptionParameter(INTEGER busIndex, FLOAT value)
{
  // make sure the bus index is within bounds
  IF(busIndex >= 1 && busIndex <= MAX_AXLINK_BUS)
  {
    // only process further if the value has changed
    IF(pduCache.axLinkBus[busIndex].pduPower.value == value)
      RETURN;

    // only apply the change if the new value is '0', or if
    // the value is already dirty, or if the applied change
    // would represent a change delta that meets or exceeds
    // the minimum change threshold
    IF((value == 0) || (pduCache.axLinkBus[busIndex].pduPower.dirty) ||
       (ABS_VALUE(pduCache.axLinkBus[busIndex].pduPower.value - value) >= PDU_POWER_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.axLinkBus[busIndex].pduPower.value = value;
      pduCache.axLinkBus[busIndex].pduPower.dirty = TRUE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUAxLinkBusPowerConsumptionParameter      *)
(* Args:  busIndex - bus index that this change applies to *)
(*        value - AxLink power current level (Apms)        *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUAxLinkBusCurrentParameter(INTEGER busIndex, FLOAT value)
{
  // make sure the bus index is within bounds
  IF(busIndex >= 1 && busIndex <= MAX_AXLINK_BUS)
  {
    // only process further if the value has changed
    IF(pduCache.axLinkBus[busIndex].current.value == value)
      RETURN;

    // only apply the change if the new value is '0', or if
    // the value is already dirty, or if the applied change
    // would represent a change delta that meets or exceeds
    // the minimum change threshold
    IF((value == 0) || (pduCache.axLinkBus[busIndex].current.dirty) ||
       (ABS_VALUE(pduCache.axLinkBus[busIndex].current.value - value) >= PDU_CURRENT_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.axLinkBus[busIndex].current.value = value;
      pduCache.axLinkBus[busIndex].current.dirty = TRUE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletPowerStateParameter               *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*                                                         *)
(* Desc:  This method is used send a power state parameter *)
(*        value change to the RMS server for a given power *)
(*        outlet index.                                    *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletPowerStateParameter(INTEGER outletIndex)
{
  // only perform this update if the allow parameter updates flag is enabled
  IF(pduCache.allowParameterUpdates == FALSE)
  {
    RETURN;
  }

  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // send parameter update to RMS for outlet power state
    RmsAssetParameterSetValueBoolean(assetClientKey,
                                     "'pdu.outlet.power.state.',ITOA(outletIndex)",
                                     [dvPDU_Outlet[outletIndex],1]);
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletPowerSensorParameter              *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*                                                         *)
(* Desc:  This method is used send a power sense parameter *)
(*        value change to the RMS server for a given power *)
(*        outlet index.                                    *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletPowerSensorParameter(INTEGER outletIndex)
{
  // only perform this update if the allow parameter updates flag is enabled
  IF(pduCache.allowParameterUpdates == FALSE)
  {
    RETURN;
  }

  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // send parameter update to RMS for power sensor state
    RmsAssetParameterSetValueBoolean(assetClientKey,
                                     "'pdu.outlet.power.sense.',ITOA(outletIndex)",
                                     [dvPDU_Outlet[outletIndex],255]);
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletPowerConsumptionParameter         *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*        value - outlet power consumption level (Watts)   *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletPowerConsumptionParameter(INTEGER outletIndex, FLOAT value)
{
  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // only process further if the value has changed
    IF(pduCache.outlet[outletIndex].pduPower.value == value)
      RETURN;

    // only apply the change if the new value is '0', or if
    // the value is already dirty, or if the applied change
    // would represent a change delta that meets or exceeds
    // the minimum change threshold
    IF((value == 0) || (pduCache.outlet[outletIndex].pduPower.dirty) ||
       (ABS_VALUE(pduCache.outlet[outletIndex].pduPower.value - value) >= PDU_POWER_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.outlet[outletIndex].pduPower.value = value;
      pduCache.outlet[outletIndex].pduPower.dirty = TRUE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletCurrentParameter                  *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*        value - outlet power current level (Apms)        *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletCurrentParameter(INTEGER outletIndex, FLOAT value)
{
  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // only process further if the value has changed
    IF(pduCache.outlet[outletIndex].current.value == value)
      RETURN;

    // only apply the change if the new value is '0', or if
    // the value is already dirty, or if the applied change
    // would represent a change delta that meets or exceeds
    // the minimum change threshold
    IF((value == 0) || (pduCache.outlet[outletIndex].current.dirty) ||
       (ABS_VALUE(pduCache.outlet[outletIndex].current.value - value) >= PDU_CURRENT_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.outlet[outletIndex].current.value = value;
      pduCache.outlet[outletIndex].current.dirty = TRUE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletPowerFactorParameter              *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*        value - outlet power factor value (W/VA)         *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletPowerFactorParameter(INTEGER outletIndex, FLOAT value)
{
  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // only process further if the value has changed
    IF(pduCache.outlet[outletIndex].powerFactor.value == value)
      RETURN;

    // only apply the change if the current cached value is 0
    // or if the applied change would represent a change delta
    // that meets or exceeds the minimum change threshold
    IF((value == 0) || (pduCache.outlet[outletIndex].powerFactor.dirty) ||
       (ABS_VALUE(pduCache.outlet[outletIndex].powerFactor.value - value) >= PDU_POWER_FACTOR_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.outlet[outletIndex].powerFactor.value = value;
      pduCache.outlet[outletIndex].powerFactor.dirty = TRUE;
    }
  }
}


(***********************************************************)
(* Name:  UpdatePDUOutletPowerFactorParameter              *)
(* Args:  outletIndex - power outlet index that this       *)
(*                      change applies to                  *)
(*        value - outlet energy consumed value (kWh)      *)
(*                                                         *)
(* Desc:  This method is used to test a recevied value and *)
(*        determine if the amount of change (delta)        *)
(*        represents a significant change according to a   *)
(*        minimum threshold constant and then synchronize  *)
(*        the new parameter value with the local tracking  *)
(*        cache state and send the updated parameter value *)
(*        to the RMS server.                               *)
(***********************************************************)
DEFINE_FUNCTION UpdatePDUOutletEnergyConsumedParameter(INTEGER outletIndex, FLOAT value)
{
  // make sure the outlet index is within bounds
  IF(outletIndex >= 1 && outletIndex <= MAX_OUTLETS)
  {
    // only process further if the value has changed
    IF(pduCache.outlet[outletIndex].energy.value == value)
      RETURN;

    // only apply the change if the new value is '0'. or if
    // the value is already dirty, or if the applied change
    // would represent a change delta that meets or exceeds
    // the minimum change threshold
    IF((value == 0) || (pduCache.outlet[outletIndex].energy.dirty) ||
       (ABS_VALUE(pduCache.outlet[outletIndex].energy.value - value) >= PDU_ENERGY_MINIMUM_CHANGE_THRESHOLD))
    {
      // cache new value
      pduCache.outlet[outletIndex].energy.value = value;
      pduCache.outlet[outletIndex].energy.dirty = TRUE;
    }
  }
}



(***********************************************************)
(* Name:  ProcessOvercurrentAlarmData                      *)
(* Args:  commandData - power outlet index that this       *)
(*                      change applies to                  *)
(*        value - outlet energy consumed value (kWh)      *)
(*                                                         *)
(* Desc:  This method is used to process a received string *)
(*        data event that identifies an overcurrent alarm  *)
(*        on either the PDU unit (chasis) or on an         *)
(*        individual outlet in the PDU.                    *)
(*        This method will parse the data event string and *)
(*        update the respective RMS parameter values.      *)
(***********************************************************)
DEFINE_FUNCTION ProcessOvercurrentAlarmData(commandData[])
{
  STACK_VAR INTEGER outletIndex;
            CHAR    nextByte[1];
            CHAR    trash[10];

  // SYNTAX  :  OVERCURRENT-<outlet #>=<current>
  // EXAMPLE :  OVERCURRENT-0=56.7

  // parse data for PDU overcurrent alarm notification
  IF(LEFT_STRING(commandData,12) == 'OVERCURRENT-')
  {
    trash = GET_BUFFER_STRING(commandData, 12);  // remove command header from data string
    nextByte = GET_BUFFER_STRING(commandData,1); // get single digit character for index
    outletIndex = ATOI(nextByte);                // convert the index character to value
    nextByte = GET_BUFFER_STRING(commandData,1); // remove the '=' character

    // if the outlet index is value '0', then this
    // represents that entire PDU unit has encountered
    // an overcurrent alarm condition.
    IF(outletIndex == 0)
    {
      // diagnsotics output
      #IF_DEFINED DIAGNOSTICS_OUTPUT
      DEBUG("'PDU CHASIS OVERCURRENT ALARM DETECTED: ',commandData");
      #END_IF

      // apply overcurrent alarm to chasis
      UpdatePDUOvercurrentParameters(TRUE,ATOF(commandData));
    }

    // if the outlet index is withing the outlet range, then this
    // represents that a single outlet on the PDU has encountered
    // an overcurrent alarm condition.
    ELSE IF(outletIndex > 0 && outletIndex <= MAX_OUTLETS)
    {
      // diagnsotics output
      #IF_DEFINED DIAGNOSTICS_OUTPUT
      DEBUG("'PDU OUTLET [#',ITOA(outletIndex),'] OVERCURRENT ALARM DETECTED: ',commandData");
      #END_IF

      // apply overcurrent alarm to single outlet
      UpdatePDUOutletOvercurrentParameters(outletIndex,TRUE,ATOF(commandData));
    }
  }
}

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

// when this module is started, call the
// initialize module function to perform
// the necessary outlet to device mapping
InitilizeModule();


(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

// Outlet Power / Relay Status
CHANNEL_EVENT[dvPDU_Outlet[1],1]
CHANNEL_EVENT[dvPDU_Outlet[2],1]
CHANNEL_EVENT[dvPDU_Outlet[3],1]
CHANNEL_EVENT[dvPDU_Outlet[4],1]
CHANNEL_EVENT[dvPDU_Outlet[5],1]
CHANNEL_EVENT[dvPDU_Outlet[6],1]
CHANNEL_EVENT[dvPDU_Outlet[7],1]
CHANNEL_EVENT[dvPDU_Outlet[8],1]
{
  ON:
  {
    STACK_VAR INTEGER index;

    // get the outlet index by the input channel device
    index = GetOutletIndexByDevice(CHANNEL.DEVICE);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER RELAY STATE = ON'");
    #END_IF

    // update RMS power outlet power state to ON
    UpdatePDUOutletPowerStateParameter(index);
  }
  OFF:
  {
    STACK_VAR INTEGER index;

    // get the outlet index by the input channel device
    index = GetOutletIndexByDevice(CHANNEL.DEVICE);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER RELAY STATE = OFF'");
    #END_IF

    // update RMS power outlet power state to OFF
    UpdatePDUOutletPowerStateParameter(index);
  }
}

// Power Status for AxLink Bus #1
CHANNEL_EVENT[dvPDU_Outlet[1],3]
{
  ON:
  {
    // update RMS AxLink Bus power state to ON
    UpdatePDUAxLinkBusPowerStateParameter(1);
  }
  OFF:
  {
    // update RMS AxLink Bus power state to OFF
    UpdatePDUAxLinkBusPowerStateParameter(1);
  }
}

// Power Status for AxLink Bus #2
CHANNEL_EVENT[dvPDU_Outlet[2],3]
{
  ON:
  {
    // update RMS AxLink Bus power state to ON
    UpdatePDUAxLinkBusPowerStateParameter(2);
  }
  OFF:
  {
    // update RMS AxLink Bus power state to OFF
    UpdatePDUAxLinkBusPowerStateParameter(2);
  }
}

// Power Sensing Status (Power On Detected)
CHANNEL_EVENT[dvPDU_Outlet[1],255]
CHANNEL_EVENT[dvPDU_Outlet[2],255]
CHANNEL_EVENT[dvPDU_Outlet[3],255]
CHANNEL_EVENT[dvPDU_Outlet[4],255]
CHANNEL_EVENT[dvPDU_Outlet[5],255]
CHANNEL_EVENT[dvPDU_Outlet[6],255]
CHANNEL_EVENT[dvPDU_Outlet[7],255]
CHANNEL_EVENT[dvPDU_Outlet[8],255]
{
  ON:
  {
    STACK_VAR INTEGER index;

    // get the outlet index by the input channel device
    index = GetOutletIndexByDevice(CHANNEL.DEVICE);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER SENSOR STATE = ON'");
    #END_IF

    // update RMS power outlet power state to ON
    UpdatePDUOutletPowerSensorParameter(index);
  }
  OFF:
  {
    STACK_VAR INTEGER index;

    // get the outlet index by the input channel device
    index = GetOutletIndexByDevice(CHANNEL.DEVICE);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER SENSOR STATE = OFF'");
    #END_IF

    // update RMS power outlet power state to OFF
    UpdatePDUOutletPowerSensorParameter(index);
  }
}


// Power Consumption Rate (Watts)
//  (Data Scale Factor=10; Resolution 0.1W)
LEVEL_EVENT[dvPDU_Outlet[1],1]
LEVEL_EVENT[dvPDU_Outlet[2],1]
LEVEL_EVENT[dvPDU_Outlet[3],1]
LEVEL_EVENT[dvPDU_Outlet[4],1]
LEVEL_EVENT[dvPDU_Outlet[5],1]
LEVEL_EVENT[dvPDU_Outlet[6],1]
LEVEL_EVENT[dvPDU_Outlet[7],1]
LEVEL_EVENT[dvPDU_Outlet[8],1]
{
    STACK_VAR FLOAT value;
    STACK_VAR INTEGER index;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // get the outlet index by the input level device
    index = GetOutletIndexByDevice(LEVEL.INPUT.DEVICE);

    // update and if needed send the parameter update to RMS
    UpdatePDUOutletPowerConsumptionParameter(index,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER : ',FTOA(value),' Watts'");
    #END_IF
}


// Eletrical Current Load (Amps)
//  (Data Scale Factor=1000; Resolution 0.001A)
LEVEL_EVENT[dvPDU_Outlet[1],2]
LEVEL_EVENT[dvPDU_Outlet[2],2]
LEVEL_EVENT[dvPDU_Outlet[3],2]
LEVEL_EVENT[dvPDU_Outlet[4],2]
LEVEL_EVENT[dvPDU_Outlet[5],2]
LEVEL_EVENT[dvPDU_Outlet[6],2]
LEVEL_EVENT[dvPDU_Outlet[7],2]
LEVEL_EVENT[dvPDU_Outlet[8],2]
{
    STACK_VAR FLOAT value;
    STACK_VAR INTEGER index;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // get the outlet index by the input level device
    index = GetOutletIndexByDevice(LEVEL.INPUT.DEVICE);

    // update and if needed send the parameter update to RMS
    UpdatePDUOutletCurrentParameter(index,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - CURRENT : ',FTOA(value),' Amps'");
    #END_IF
}

// Power Factor (Watts/Volts*Apms)
//  (Data Scale Factor=100)
LEVEL_EVENT[dvPDU_Outlet[1],3]
LEVEL_EVENT[dvPDU_Outlet[2],3]
LEVEL_EVENT[dvPDU_Outlet[3],3]
LEVEL_EVENT[dvPDU_Outlet[4],3]
LEVEL_EVENT[dvPDU_Outlet[5],3]
LEVEL_EVENT[dvPDU_Outlet[6],3]
LEVEL_EVENT[dvPDU_Outlet[7],3]
LEVEL_EVENT[dvPDU_Outlet[8],3]
{
    STACK_VAR FLOAT value;
    STACK_VAR INTEGER index;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,100);

    // get the outlet index by the input level device
    index = GetOutletIndexByDevice(LEVEL.INPUT.DEVICE);

    // update and if needed send the parameter update to RMS
    UpdatePDUOutletPowerFactorParameter(index,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'OUTLET #',ITOA(index),' - POWER FACTOR: ',FTOA(value),' W/VA'");
    #END_IF
}

// Energy Consumption (Watts-Hour)
//  (Data Scale Factor=100; Resolution 0.1kWh)
LEVEL_EVENT[dvPDU_Outlet[1],4]
LEVEL_EVENT[dvPDU_Outlet[2],4]
LEVEL_EVENT[dvPDU_Outlet[3],4]
LEVEL_EVENT[dvPDU_Outlet[4],4]
LEVEL_EVENT[dvPDU_Outlet[5],4]
LEVEL_EVENT[dvPDU_Outlet[6],4]
LEVEL_EVENT[dvPDU_Outlet[7],4]
LEVEL_EVENT[dvPDU_Outlet[8],4]
{
  STACK_VAR FLOAT value;
  STACK_VAR INTEGER index;

  // caclulate the scaled value using the scale factor
  value = Scale(LEVEL.VALUE,10);

  // get the outlet index by the input level device
  index = GetOutletIndexByDevice(LEVEL.INPUT.DEVICE);

  // update and if needed send the parameter update to RMS
  UpdatePDUOutletEnergyConsumedParameter(index,value);

  // diagnsotics output
  #IF_DEFINED DIAGNOSTICS_OUTPUT
  DEBUG("'OUTLET #',ITOA(index),' - ENERGY (Accumulated): ',FTOA(value),' kWh'");
  #END_IF
}

// Input Voltage (Volts)
//  (Data Scale Factor=10; Resolution 0.1V)
LEVEL_EVENT[dvPDU_Outlet[1],5]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUInputVoltageParameter(value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'CHASIS INPUT VOLTAGE : ',FTOA(value),' Volts'");
    #END_IF
}

// AxLink Voltage (Volts)
//  (Data Scale Factor=10; Resolution 0.1V)
LEVEL_EVENT[dvPDU_Outlet[2],5]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUAxLinkVoltageParameter(value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'CHASIS AXLINK VOLTAGE : ',FTOA(value),' Volts'");
    #END_IF
}

// AxLink Bus #1 Power (Watts)
//  (Data Scale Factor=10; Resolution 0.1W)
LEVEL_EVENT[dvPDU_Outlet[1],6]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUAxLinkBusPowerConsumptionParameter(1,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'AXLINK BUS #1 : power=',FTOA(value),' Watts'");
    #END_IF
}

// AxLink Bus #2 Power (Watts)
//  (Data Scale Factor=10; Resolution 0.1W)
LEVEL_EVENT[dvPDU_Outlet[2],6]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUAxLinkBusPowerConsumptionParameter(2,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'AXLINK BUS #2 : power=',FTOA(value),' Watts'");
    #END_IF
}

// AxLink Bus #1 Current (Amps)
LEVEL_EVENT[dvPDU_Outlet[1],7]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUAxLinkBusCurrentParameter(1,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'AXLINK BUS #1 : current=',FTOA(value),' Amps'");
    #END_IF
}

// AxLink Bus #2 Current (Amps)
//  (Data Scale Factor=1000; Resolution 0.001A)
LEVEL_EVENT[dvPDU_Outlet[2],7]
{
    STACK_VAR FLOAT value;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // update and if needed send the parameter update to RMS
    UpdatePDUAxLinkBusCurrentParameter(2,value);

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'AXLINK BUS #2 : current=',FTOA(value),' Amps'");
    #END_IF
}

// Temperature Level
//  (Data Scale Factor=10; Resolution 0.1C)
//
// Since the individual temperature readings can be fluxuate quite a bit,
// we will collect a history of readings and perform an averaging of the
// individual values to obtain a reasonable temperature value to report
// into the RMS system.  Averaging a set of readings helps to reduce the
// overall impact of single erratic readings.
LEVEL_EVENT[dvPDU_Outlet[1],8]
{
    STACK_VAR FLOAT value;
              INTEGER index;
              FLOAT temperatureSum;
              INTEGER temperatureReadings;
              FLOAT temperatureAverage;

    // caclulate the scaled value using the scale factor
    value = Scale(LEVEL.VALUE,10);

    // insert new value into temperature history
    // and move all existing readings one step up in the array
    FOR(index = MAX_TEMPERATURE_READINGS; index > 1; index--)
    {
      pduCache.temperatureHistory[index] = pduCache.temperatureHistory[index-1];
    }
    pduCache.temperatureHistory[1] = value;

    // calculcate the average temperature reading
    FOR(index = 1; index <= MAX_TEMPERATURE_READINGS; index++)
    {
      IF(pduCache.temperatureHistory[index] > 0)
      {
        temperatureSum = temperatureSum + pduCache.temperatureHistory[index];
        temperatureReadings++;
      }
    }
    IF(temperatureReadings == 0)
    {
      temperatureAverage = 0;
    }
    ELSE
    {
      temperatureAverage = temperatureSum / temperatureReadings;
    }

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'TEMERATURE (RAW SINGLE READING): ',FTOA(value),' ',GetTemperatureUnits()");
    DEBUG("'TEMERATURE (AVERAGE over ',ITOA(MAX_TEMPERATURE_READINGS),' READINGS): ',FTOA(temperatureAverage),' ',GetTemperatureUnits()");
    #END_IF

    // update and if needed send the parameter update to RMS
    UpdatePDUTemeratureParameter(temperatureAverage);
}

//
// (DEVICE DATA EVENT HANDLER)
//
// handle data events generated by the PDU device
//
DATA_EVENT[dvMonitoredDevice]
{
  ONLINE:
  {
    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'PDU is ONLINE'");
    #END_IF

    // query the device for it's serial number
    SEND_COMMAND dvMonitoredDevice, '?SERIAL';

    // the device online parameter is updated to
    // the ONLINE state in the callback method:
    //   SynchronizeAssetParameters()
    // no further action is needed here
    // in the ONLINE data event
  }
  OFFLINE:
  {
    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'PDU is OFFLINE'");
    #END_IF

    // if a power monitoring timeline was created and is running, then permanently
    // destroy the power monitoring timeline while the PDU device is offline.
    IF(TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_KILL(TL_MONITOR);
    }

    // update device online parameter value to OFFLINE
    RmsAssetOnlineParameterUpdate(assetClientKey, FALSE);

    // if the PDU device goes OFFLINE, then reset the power
    // parameter values to '0' and send them to RMS
    ResetPDUParameterValues();

    // set parameter updates flag to FALSE.
    // After settings this flag
    // to 'FALSE', is will block further parameter
    // value updates from being sent to RMS.  We
    // primarily use this flag so that the numerous
    // channel and level events associated with
    // a device online/offline event do not fire
    // individual parameter updates to RMS.  The
    // device ONLINE and OFFLINE conditions are
    // addressed using a full synchronization of the
    // parameter values.
    pduCache.allowParameterUpdates = FALSE;
  }
  COMMAND:
  {
    STACK_VAR CHAR header[5];

    // diagnsotics output
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG("'PDU COMMAND RECEIVED: ',DATA.TEXT");
    #END_IF

    // parse data for PDU serial number response data
    IF(LEFT_STRING(DATA.TEXT,7) == 'SERIAL ')
    {
        header = GET_BUFFER_STRING(DATA.TEXT, 7);
        pduCache.serialNumber = DATA.TEXT;

        // diagnsotics output
        #IF_DEFINED DIAGNOSTICS_OUTPUT
        DEBUG("'PDU SERIAL NUMBER DETECTED: ',pduCache.serialNumber");
        #END_IF
    }

    // parse data for PDU overcurrent alarm notification
    IF(LEFT_STRING(DATA.TEXT,12) == 'OVERCURRENT-')
    {
      ProcessOvercurrentAlarmData(DATA.TEXT);
    }
  }
}


// If RMS is no longer in the asset management
// state, then we should stop the monitoring timeline.
CHANNEL_EVENT[vdvRMS,RMS_CHANNEL_ASSETS_REGISTER]
{
  OFF:
  {
    IF(TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_KILL(TL_MONITOR);
    }
  }
}


// Send changed (dirty) power monitored parameter values
// to the RMS server.
TIMELINE_EVENT[TL_MONITOR]
{
  // both the PDU device must be ONLINE and RMS must be
  // in the asset management state to send updated parameter
  // values to the RMS server.
  IF(DEVICE_ID(dvMonitoredDevice) && [vdvRMS,RMS_CHANNEL_ASSETS_REGISTER])
  {
    #IF_DEFINED DIAGNOSTICS_OUTPUT
    DEBUG('>>>>> Power Monitoring timeline sending changes to RMS...');
    #END_IF

    // send all dirty tracked parameter changes to RMS
    SendPDUParameterValueChanges();
  }
  ELSE
  {
    // if either the PDU device is OFFLINE, or RMS is not
    // in the asset management state, then we should stop
    // this timeline.
    IF(TIMELINE_ACTIVE(TL_MONITOR))
    {
      TIMELINE_KILL(TL_MONITOR);
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
