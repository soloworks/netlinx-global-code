//*********************************************************************
//
//             AMX Resource Management Suite  (4.3.25)
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
PROGRAM_NAME='RmsNlSnapiComponents'


// this is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_SNAPI_COMPONENTS__
#DEFINE __RMS_SNAPI_COMPONENTS__

#IF_NOT_DEFINED __RMS_API__
#INCLUDE 'RmsApi';
#END_IF

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//-- Use keys to cache state --
#IF_NOT_DEFINED MAX_KEYS
  MAX_KEYS = 20
#END_IF


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

//-- Use keys to cache state --
STRUCTURE _uKeys
{
  CHAR  cName[30]
  CHAR  cValue[30]
}


(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

//-- Use keys to cache state --
INTEGER nKeyCount
_uKeys uKeys[MAX_KEYS]


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)

(************************************************************************************************************)
(*                                   Key value pairs (for state synchronization)                            *)
(************************************************************************************************************)

(*****************************************************)
(* Call Name: keyLookup()                            *)
(* Function:  Find (or add) a key.                   *)
(*****************************************************)
DEFINE_FUNCTION INTEGER keyLookup(CHAR cKey[30])
STACK_VAR
  INTEGER nLoop
{
// Look it up
  FOR(nLoop=1; nLoop<=MAX_KEYS; nLoop++)
  {
    IF(uKeys[nLoop].cName = cKey)
      RETURN(nLoop)
  }

// Add it
  IF(nKeyCount < MAX_KEYS)
  {
    nKeyCount++
    RETURN(nKeyCount)
  }

// Not found, no more room
  RETURN(0)
}

(*****************************************************)
(* Call Name: keyFind()                              *)
(* Function:  Find a key.                            *)
(*****************************************************)
DEFINE_FUNCTION INTEGER keyFind(CHAR cKey[30])
STACK_VAR
  INTEGER nLoop
{
// Look it up
  FOR(nLoop=1; nLoop<=MAX_KEYS; nLoop++)
  {
    IF(uKeys[nLoop].cName = cKey)
      RETURN(nLoop)
  }

// Not found
  RETURN(0)
}


(*****************************************************)
(* Call Name: keySetValue()                          *)
(* Function:  Set value of a key.                    *)
(*****************************************************)
DEFINE_FUNCTION KeySetValue(CHAR cKey[30], CHAR cValue[30])
STACK_VAR
  INTEGER nIdx
{
  nIdx = keyLookup (cKey)
  IF(nIdx = 0)
    RETURN;

   uKeys[nIdx].cValue = cValue
}


(*****************************************************)
(* Call Name: keyGetValue()                          *)
(* Function:  Set value of a key.                    *)
(*****************************************************)
DEFINE_FUNCTION CHAR[30] KeyGetValue(CHAR cKey[30])
STACK_VAR
  INTEGER nIdx
{
  nIdx = keyFind (cKey)
  IF(nIdx = 0)
    RETURN('')

   RETURN(uKeys[nIdx].cValue)
}


(************************************************************************************************************)
(*                                   Individual SNAPI component synchronization                             *)
(************************************************************************************************************)
(*****************************************************)
(* Call Name: SynchronizeAssetParametersSnapiComponents *)
(* Function:  Synchronizes this asset's snapi        *)
(*            components with RMS                    *)
(*****************************************************)
DEFINE_FUNCTION CHAR SynchronizeAssetParametersSnapiComponents(CHAR assetClientKey[])
STACK_VAR
  CHAR bReturn
{
  // update device online parameter value & device data initialized parameter value
  RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice))
  RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice))

#IF_DEFINED HAS_POWER
  #IF_DEFINED HAS_LAMP
    IF([vdvDevice,POWER_FB]) RmsAssetParameterSetValue(assetClientKey,'projector.lamp.power','On' );
    ELSE                           RmsAssetParameterSetValue(assetClientKey,'projector.lamp.power','Off');
  #ELSE
    IF([vdvDevice,POWER_FB]) RmsAssetParameterSetValue(assetClientKey,'asset.power','On' );
    ELSE                           RmsAssetParameterSetValue(assetClientKey,'asset.power','Off');
  #END_IF

  bReturn++
#END_IF

#IF_DEFINED HAS_FIXED_POWER
  RmsAssetParameterSetValue(assetClientKey,'asset.power','On' );
  bReturn++
#END_IF

#IF_DEFINED HAS_VOLUME
  IF([vdvDevice,VOL_MUTE_FB] )  RmsAssetParameterEnqueueSetValue(assetClientKey, 'volume.mute'           , 'true' );
  ELSE                                RmsAssetParameterEnqueueSetValue(assetClientKey, 'volume.mute'           , 'false');

  RmsAssetParameterEnqueueSetValue(assetClientKey, 'volume.level', KeyGetValue('volume.level'));

  bReturn++
#END_IF

#IF_DEFINED HAS_GAIN
  IF([vdvDevice,GAIN_MUTE_FB])  RmsAssetParameterEnqueueSetValue(assetClientKey, 'gain.mute'             , 'true' );
  ELSE                                RmsAssetParameterEnqueueSetValue(assetClientKey, 'gain.mute'             , 'false');

  RmsAssetParameterEnqueueSetValue(assetClientKey, 'gain.level', KeyGetValue('gain.level'));

  bReturn++
#END_IF

#IF_DEFINED HAS_PREAMP
  IF([vdvDevice,LOUDNESS_FB] )  RmsAssetParameterEnqueueSetValue(assetClientKey, 'preamp.loudness'       , 'true' );
  ELSE                                RmsAssetParameterEnqueueSetValue(assetClientKey, 'preamp.loudness'       , 'false');

  RmsAssetParameterEnqueueSetValue(assetClientKey, 'preamp.balance', KeyGetValue('preamp.balance'));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'preamp.treble' , KeyGetValue('preamp.treble' ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'preamp.bass'   , KeyGetValue('preamp.bass'   ));

  bReturn++
#END_IF

#IF_DEFINED HAS_DIALER
  IF([vdvDevice,DIAL_OFF_HOOK_FB] )      RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.hook'           , 'true' );
  ELSE                                         RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.hook'           , 'false');

  IF([vdvDevice,DIAL_AUTO_ANSWER_FB] )   RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.auto.answer'    , 'true' );
  ELSE                                         RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.auto.answer'    , 'false');

  RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.status', KeyGetValue('dialer.status'));

  RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.incoming.call', KeyGetValue('dialer.incoming.call'));

  IF([vdvDevice,DIAL_AUDIBLE_RING_FB])   RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.ring.audible'   , 'true' );
  ELSE                                         RmsAssetParameterEnqueueSetValue(assetClientKey, 'dialer.ring.audible'   , 'false');

  bReturn++
#END_IF

#IF_DEFINED HAS_PHONEBOOK     // See command events
#END_IF

#IF_DEFINED HAS_CONFERENCER
  IF([vdvDevice,ACONF_PRIVACY_FB] )  RmsAssetParameterEnqueueSetValue(assetClientKey, 'conferencer.privacy'   , 'true' );
  ELSE                                     RmsAssetParameterEnqueueSetValue(assetClientKey, 'conferencer.privacy'   , 'false');

  IF([vdvDevice,ACONF_PRIVACY_FB] )  RmsAssetParameterEnqueueSetValue(assetClientKey, 'conferencer.privacy'   , 'true' );
  ELSE                                     RmsAssetParameterEnqueueSetValue(assetClientKey, 'conferencer.privacy'   , 'false');

  bReturn++
#END_IF

#IF_DEFINED HAS_CAMERA_PRESET // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.preset' , KeyGetValue('camera.preset'));

  bReturn++
#END_IF

#IF_DEFINED HAS_CAMERA_PAN_TILT
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.pan.position' , KeyGetValue('camera.pan.position' ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.tilt.position', KeyGetValue('camera.tilt.position'));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.pan.speed'    , KeyGetValue('camera.pan.speed'    ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.tilt.speed'   , KeyGetValue('camera.tilt.speed'   ));

  bReturn++
#END_IF

#IF_DEFINED HAS_CAMERA_LENS
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.zoom.level' , KeyGetValue('camera.zoom.level' ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.focus.level', KeyGetValue('camera.focus.level'));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.iris.level' , KeyGetValue('camera.iris.level' ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.zoom.speed' , KeyGetValue('camera.zoom.speed' ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.focus.speed', KeyGetValue('camera.focus.speed'));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.iris.speed' , KeyGetValue('camera.iris.speed' ));

  IF([vdvDevice,AUTO_FOCUS_FB] )      RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.focus.auto'     , 'true' );
  ELSE                                      RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.focus.auto'     , 'false');

  IF([vdvDevice,AUTO_IRIS_FB]  )      RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.iris.auto'      , 'true' );
  ELSE                                      RmsAssetParameterEnqueueSetValue(assetClientKey, 'camera.iris.auto'      , 'false');

  bReturn++
#END_IF

#IF_DEFINED HAS_SOURCE_SELECT           // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'source.input' , KeyGetValue('source.input'));

  bReturn++
#END_IF

#IF_DEFINED HAS_LAMP                    // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'lamp.consumption' , KeyGetValue('lamp.consumption'));

  bReturn++
#END_IF

#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO    // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'display.aspect.ratio' , KeyGetValue('display.aspect.ratio'));

  bReturn++
#END_IF

#IF_DEFINED HAS_TUNER                   // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'tuner.band'           , KeyGetValue('tuner.band'          ));
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'tuner.station'        , KeyGetValue('tuner.station'       ));

  bReturn++
#END_IF

#IF_DEFINED HAS_DISC_TRANSPORT
  SELECT
  {
    ACTIVE([vdvDevice,PLAY_FB    ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Play'    )
    ACTIVE([vdvDevice,STOP_FB    ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Stop'    )
    ACTIVE([vdvDevice,PAUSE_FB   ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Pause'   )
    ACTIVE([vdvDevice,SFWD_FB    ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Next'    )
    ACTIVE([vdvDevice,SREV_FB    ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Previous')
    ACTIVE([vdvDevice,RECORD_FB  ]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Record'  )
    ACTIVE([vdvDevice,SLOW_FWD_FB]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Slow Fwd')
    ACTIVE([vdvDevice,SLOW_REV_FB]) : RmsAssetParameterEnqueueSetValue(assetClientKey, 'transport.state', 'Slow Rev')
  }

  bReturn++
#END_IF

#IF_DEFINED HAS_SWITCHER              // See command events
#END_IF

#IF_DEFINED HAS_LIGHT           // See command events
  RmsAssetParameterEnqueueSetValue(assetClientKey, 'light.scene' , KeyGetValue('light.scene'));

  bReturn++
#END_IF

  RETURN(bReturn)
}


(*****************************************************)
(* Call Name: SynchronizeAssetMetadataSnapiComponents *)
(* Function:  Synchronizes this asset's snapi        *)
(*            components with RMS                    *)
(*****************************************************)
DEFINE_FUNCTION CHAR SynchronizeAssetMetadataSnapiComponents(CHAR assetClientKey[])
{
  RETURN(0)
}


(************************************************************************************************************)
(*                                   Individual SNAPI component registration                                *)
(************************************************************************************************************)
(*****************************************************)
(* Call Name: RegisterAssetParametersSnapiComponents *)
(* Function:  registers this asset's snapi           *)
(*            components with RMS                    *)
(*****************************************************)
DEFINE_FUNCTION RegisterAssetParametersSnapiComponents(CHAR assetClientKey[])
{
  // register default device online and data initialized parameters
  RmsAssetOnlineParameterEnqueue (assetClientKey, GetOnlineSnapiValue(vdvDevice));
  RmsAssetDataInitializedParameterEnqueue (assetClientKey, GetDataInitializedSnapiValue(vdvDevice));

#IF_DEFINED HAS_CAMERA_PRESET         RegisterAssetsCameraPreset       (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_CAMERA_PAN_TILT       RegisterAssetsCameraPanTilt      (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_CAMERA_LENS           RegisterAssetsCameraLens         (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_CONFERENCER           RegisterAssetsConferencer        (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DIALER                RegisterAssetsDialer             (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DISC_TRANSPORT        RegisterAssetsDiscTransport      (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DISC_INFO             RegisterAssetsDiscInfo           (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DISPLAY_USAGE         RegisterAssetsDisplayUsage       (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO  RegisterAssetsDisplayAspectRatio (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_DOCUMENT_CAMERA       RegisterAssetsDocumentCamera     (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_GAIN                  RegisterAssetsGain               (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_HVAC                  RegisterAssetsHvac               (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_LAMP                  RegisterAssetsLamp               (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_PHONEBOOK             RegisterAssetsPhonebook          (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_POWER                 RegisterAssetsPower              (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_FIXED_POWER           RegisterAssetsFixedPower         (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_PREAMP                RegisterAssetsPreamp             (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_SECURITY_SYSTEM       RegisterAssetsSecuritySystem     (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_SOURCE_SELECT         RegisterAssetsSourceSelect       (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_SWITCHER              RegisterAssetsSwitcher           (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_TUNER                 RegisterAssetsTuner              (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_VOLUME                RegisterAssetsVolume             (assetClientKey, 'PARAMETERS')     #END_IF
#IF_DEFINED HAS_LIGHT                 RegisterAssetsLight              (assetClientKey, 'PARAMETERS')     #END_IF
}


(****************************************************)
(* Call Name: RegisterAssetMetadataSnapiComponents  *)
(* Function:  registers this asset's snapi          *)
(*            components with RMS                   *)
(****************************************************)
DEFINE_FUNCTION RegisterAssetMetadataSnapiComponents(CHAR assetClientKey[])
{
#IF_DEFINED HAS_CAMERA_PRESET         RegisterAssetsCameraPreset       (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_CAMERA_PAN_TILT       RegisterAssetsCameraPanTilt      (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_CAMERA_LENS           RegisterAssetsCameraLens         (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_CONFERENCER           RegisterAssetsConferencer        (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DIALER                RegisterAssetsDialer             (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DISC_TRANSPORT        RegisterAssetsDiscTransport      (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DISC_INFO             RegisterAssetsDiscInfo           (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DISPLAY_USAGE         RegisterAssetsDisplayUsage       (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO  RegisterAssetsDisplayAspectRatio (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_DOCUMENT_CAMERA       RegisterAssetsDocumentCamera     (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_GAIN                  RegisterAssetsGain               (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_HVAC                  RegisterAssetsHvac               (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_LAMP                  RegisterAssetsLamp               (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_PHONEBOOK             RegisterAssetsPhonebook          (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_POWER                 RegisterAssetsPower              (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_FIXED_POWER           RegisterAssetsFixedPower         (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_PREAMP                RegisterAssetsPreamp             (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_SECURITY_SYSTEM       RegisterAssetsSecuritySystem     (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_SOURCE_SELECT         RegisterAssetsSourceSelect       (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_SWITCHER              RegisterAssetsSwitcher           (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_TUNER                 RegisterAssetsTuner              (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_VOLUME                RegisterAssetsVolume             (assetClientKey, 'METADATA')     #END_IF
#IF_DEFINED HAS_LIGHT                 RegisterAssetsLight              (assetClientKey, 'METADATA')     #END_IF
}



(**********************************************************)
(* Call Name: RegisterAssetControlMethodsSnapiComponents  *)
(* Function:  registers this asset's snapi                *)
(*            components with RMS                         *)
(**********************************************************)
DEFINE_FUNCTION RegisterAssetControlMethodsSnapiComponents(CHAR assetClientKey[])
{
#IF_DEFINED HAS_CAMERA_PRESET         RegisterAssetsCameraPreset       (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_CAMERA_PAN_TILT       RegisterAssetsCameraPanTilt      (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_CAMERA_LENS           RegisterAssetsCameraLens         (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_CONFERENCER           RegisterAssetsConferencer        (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DIALER                RegisterAssetsDialer             (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DISC_TRANSPORT        RegisterAssetsDiscTransport      (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DISC_INFO             RegisterAssetsDiscInfo           (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DISPLAY_USAGE         RegisterAssetsDisplayUsage       (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO  RegisterAssetsDisplayAspectRatio (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_DOCUMENT_CAMERA       RegisterAssetsDocumentCamera     (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_GAIN                  RegisterAssetsGain               (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_HVAC                  RegisterAssetsHvac               (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_LAMP                  RegisterAssetsLamp               (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_PHONEBOOK             RegisterAssetsPhonebook          (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_POWER                 RegisterAssetsPower              (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_FIXED_POWER           RegisterAssetsFixedPower         (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_PREAMP                RegisterAssetsPreamp             (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_SECURITY_SYSTEM       RegisterAssetsSecuritySystem     (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_SOURCE_SELECT         RegisterAssetsSourceSelect       (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_SWITCHER              RegisterAssetsSwitcher           (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_TUNER                 RegisterAssetsTuner              (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_VOLUME                RegisterAssetsVolume             (assetClientKey, 'CONTROL_METHODS')     #END_IF
#IF_DEFINED HAS_LIGHT                 RegisterAssetsLight              (assetClientKey, 'CONTROL_METHODS')     #END_IF
}


(************************************************************************************************************)
(*                                   Individual SNAPI components                                            *)
(************************************************************************************************************)
#IF_DEFINED HAS_CAMERA_PRESET
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsCameraPreset (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueNumber(assetClientKey,
                                      'camera.preset',
                                      'Last Selected Camera Preset', 'The last selected camera preset',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      0,
                                      1,
                                      METADATA_PROPERTY_CAMERA_PRESET_COUNT,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      0,
                                      RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'camera.preset.count', 'Camera Preset Count', METADATA_PROPERTY_CAMERA_PRESET_COUNT);
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue           (assetClientKey, 'camera.preset', 'Select Camera Preset', 'Select the camera preset');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey, 'camera.preset', 0,
                                                                'Preset', 'Select the camera preset to apply',
                                                                1,
                                                                1, METADATA_PROPERTY_CAMERA_PRESET_COUNT,
                                                                1);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_CAMERA_PAN_TILT
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsCameraPanTilt (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      #IF_DEFINED METADATA_PROPERTY_PAN_LVL_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.pan.position',
                                      'Pan Position', 'Current pan position of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_PAN_LVL_INIT,
                                      METADATA_PROPERTY_PAN_LVL_MIN,
                                      METADATA_PROPERTY_PAN_LVL_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_PAN_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_TILT_LVL_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.tilt.position',
                                      'Tilt Position', 'Current tilt position of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_TILT_LVL_INIT,
                                      METADATA_PROPERTY_TILT_LVL_MIN,
                                      METADATA_PROPERTY_TILT_LVL_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_TILT_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_PAN_SPD_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.pan.speed',
                                      'Pan Speed', 'the speed at which pan ramping operations occur',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_PAN_SPD_INIT,
                                      METADATA_PROPERTY_PAN_SPD_MIN,
                                      METADATA_PROPERTY_PAN_SPD_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_PAN_SPD_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_TILT_SPD_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.tilt.speed',
                                      'Tilt Speed', 'the speed at which tilt ramping operations occur',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_TILT_SPD_INIT,
                                      METADATA_PROPERTY_TILT_SPD_MIN,
                                      METADATA_PROPERTY_TILT_SPD_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_TILT_SPD_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      }
    }
  }
#END_IF

#IF_DEFINED HAS_CAMERA_LENS
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsCameraLens (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'camera.focus.auto',
                                      'Auto Focus', 'The auto focus state of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'camera.iris.auto',
                                      'Auto Iris',  'The auto iris state of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

      #IF_DEFINED METADATA_PROPERTY_ZOOM_LVL_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.zoom.level',
                                      'Zoom Level', 'Current zoom position of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_ZOOM_LVL_INIT,
                                      METADATA_PROPERTY_ZOOM_LVL_MIN,
                                      METADATA_PROPERTY_ZOOM_LVL_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_ZOOM_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_FOCUS_LVL_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.focus.level',
                                      'Focus Level', 'Current focus position of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_FOCUS_LVL_INIT,
                                      METADATA_PROPERTY_FOCUS_LVL_MIN,
                                      METADATA_PROPERTY_FOCUS_LVL_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_FOCUS_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_IRIS_LVL_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.iris.level',
                                      'Iris Level', 'Current iris level of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_IRIS_LVL_INIT,
                                      METADATA_PROPERTY_IRIS_LVL_MIN,
                                      METADATA_PROPERTY_IRIS_LVL_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_IRIS_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_ZOOM_SPD_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.zoom.speed',
                                      'Zoom Speed', 'Current zoom speed of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_ZOOM_SPD_INIT,
                                      METADATA_PROPERTY_ZOOM_SPD_MIN,
                                      METADATA_PROPERTY_ZOOM_SPD_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_ZOOM_SPD_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_FOCUS_SPD_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.focus.speed',
                                      'Focus Speed', 'Current focus speed of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_FOCUS_SPD_INIT,
                                      METADATA_PROPERTY_FOCUS_SPD_MIN,
                                      METADATA_PROPERTY_FOCUS_SPD_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_FOCUS_SPD_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_IRIS_SPD_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'camera.iris.speed',
                                      'Iris Speed', 'Current iris speed of the camera',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_IRIS_SPD_INIT,
                                      METADATA_PROPERTY_IRIS_SPD_MIN,
                                      METADATA_PROPERTY_IRIS_SPD_MAX,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_IRIS_SPD_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      }
    }
  }
#END_IF


#IF_DEFINED HAS_CONFERENCER
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsConferencer (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'conferencer.privacy',
                                      'Privacy',  'The video conferencers privacy mode',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'conferencer.privacy', 'Set Privacy', 'Set the video conferencing privacy mode by enabling or disabling the microphone mute state');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'conferencer.privacy', 0,
                                                               'Privacy State', 'Select the privacy state to apply',
                                                               0);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DIALER
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDialer (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'dialer.hook',
                                      'Off Hook', 'The off hook state of the dialer',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'dialer.auto.answer',
                                      'Auto Answer', 'The auto-answer feature state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'dialer.status',
                                        'Dialer Status', 'Current dialer status setting',
                                        RMS_ASSET_PARAM_TYPE_DIALER_STATE,
                                        'Disconnected',
                                        'Dialing|Busy|Ringing|Disconnected|Negotiating|Fault|Connected',
                                        RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueString(assetClientKey,
                                        'dialer.incoming.call',
                                        'Last Incoming Call', 'Last incoming caller information received.',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', '', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_YES);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'dialer.ring.audible',
                                      'Audible Ring', 'The audible ring feature state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue(assetClientKey, 'dialer.hook', 'Set Off Hook', 'Set the on/off state of the dialer');
        RmsAssetControlMethodArgumentBoolean(assetClientKey,'dialer.hook', 0,
        													'Set Off Hook', 'Set the on/off state of the dialer',
        													0);

        RmsAssetControlMethodEnqueue(assetClientKey, 'dialer.auto.answer', 'Set Auto Answer', 'Set the auto answer feature state of the dialer');
        RmsAssetControlMethodArgumentBoolean(assetClientKey, 'dialer.auto.answer', 0,
        													'Auto Answer On/Off', 'Select the auto answer state to apply',
        													0);

        RmsAssetControlMethodEnqueue(assetClientKey, 'dialer.dial.number', 'Dial Telephone Number', 'Dial a phone number');
        RmsAssetControlMethodArgumentString(assetClientKey, 'dialer.dial.number', 0,
        													'Phone Number', 'Enter the phone number',
        													'');

        RmsAssetControlMethodEnqueue(assetClientKey, 'dialer.redial', 'Redial', 'Redial the last number dialed');

        RmsAssetControlMethodEnqueue(assetClientKey, 'dialer.ring.audible', 'Set Audible Ring', 'Set the audible ring feature state');
        RmsAssetControlMethodArgumentBoolean(assetClientKey, 'dialer.ring.audible', 0,
        													'Audible Ring On/Off', 'Select the audible ring state to apply',
        													0);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DISC_TRANSPORT
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDiscTransport (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'transport.state',
                                        'Transport State', 'Current disc transport',
                                        RMS_ASSET_PARAM_TYPE_TRANSPORT_STATE,
                                        'Stop', 'Stop|Play|Pause|Next|Previous|Scan Fwd|Scan Rev|Record|Slow Fwd|Slow Rev', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueDecimal(assetClientKey,
                                       'transport.runtime',
                                       'Run Time', 'Current disc transport runtime',
                                       RMS_ASSET_PARAM_TYPE_TRANSPORT_USAGE,
                                       0,
                                       0,
                                       0,
                                       'Hours',
                                       RMS_ALLOW_RESET_YES,
                                       0,
                                       RMS_TRACK_CHANGES_YES);

      #IF_DEFINED METADATA_PROPERTY_DISC_CAPACITY
        RmsAssetParameterEnqueueNumber(assetClientKey,
                                      'disc.selected',
                                      'Disc Number', 'Current disc number',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      0,
                                      1,
                                      METADATA_PROPERTY_DISC_CAPACITY,
                                      '',
                                      RMS_ALLOW_RESET_NO,
                                      0,
                                      RMS_TRACK_CHANGES_NO);
      #END_IF
      }
      CASE 'METADATA' :
      {
      #IF_DEFINED METADATA_PROPERTY_DISC_CAPACITY
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'disc.capacity', 'Disc Capacity', METADATA_PROPERTY_DISC_CAPACITY);
      #END_IF
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.play'    , 'Play'                  , 'Play the current media content');
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.stop'    , 'Stop'                  , 'Stop the current media content');
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.pause'   , 'Pause'                 , 'Pause the current media content');
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.next'    , 'Next Track/Chapter'    , 'Advance to the next track/chapter on the disc');
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.previous', 'Previous Track/Chapter', 'Go back to the previous track/chapter on the disc');
        #IF_DEFINED HAS_DISC_RECORD
        RmsAssetControlMethodEnqueue          (assetClientKey, 'transport.record'    , 'Record'                  , 'Record the content to the disc');
        #END_IF

        #IF_DEFINED METADATA_PROPERTY_DISC_CAPACITY
        RmsAssetControlMethodEnqueue          (assetClientKey, 'disc.select', 'Select Disc', 'Select the disc to load');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'disc.select', 0,
                                                               'Disc', 'Select the disc number to load',
                                                               1,
                                                               1, METADATA_PROPERTY_DISC_CAPACITY,
                                                               1);
        #END_IF

        #IF_DEFINED HAS_DISC_INFO
        RmsAssetControlMethodEnqueue          (assetClientKey, 'disc.track.select', 'Select Track/Chapter', 'Select the track/chapter on the disc to load');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'disc.track.select', 0,
                                                               'Track', 'Select the track number',
                                                               1,
                                                               1, 99,
                                                               1);
        #END_IF
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DISC_INFO
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDiscInfo (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueString(assetClientKey,
                                        'disc.type',
                                        'Disc Type', 'Current disc media type',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', '', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueString(assetClientKey,
                                        'disc.duration',
                                        'Disc Duration', 'The time and frame count of the current media',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', '', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueNumber(assetClientKey,
                                        'disc.track.count',
                                        'Number of Tracks', 'The total tracks',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        0,
                                        0,
                                        99,
                                        '',
                                        RMS_ALLOW_RESET_NO,
                                        0,
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueString(assetClientKey,
                                        'disc.track.duration',
                                        'Track/Chapter Duration', 'The length of the track',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', '', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueNumber(assetClientKey,
                                        'disc.track.selected',
                                        'Track/Chapter Number', 'The track number',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        0,
                                        0,
                                        99,
                                        '',
                                        RMS_ALLOW_RESET_NO,
                                        0,
                                        RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DISPLAY_USAGE
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDisplayUsage (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        // register the asset parameter for display usage
        RmsAssetParameterEnqueueDecimalWithBargraph(assetClientKey,
                                       'display.usage',
                                       'Display Usage', 'Current consumption usage of the lamp or display device',
                                       RMS_ASSET_PARAM_TYPE_DISPLAY_USAGE,
                                       0,
                                       0,
                                       100000,
                                       'Hours',
                                       RMS_ALLOW_RESET_YES,
                                       0,
                                       RMS_TRACK_CHANGES_YES,
                                       'display.usage');

        // add a default threshold for the display usage parameter
        RmsAssetParameterThresholdEnqueue(assetClientKey,
                                    'display.usage',
                                    'Display/Lamp Life',
                                    RMS_STATUS_TYPE_MAINTENANCE,
                                    RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL,
                                    '100000');
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDisplayAspectRatio (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      #IF_DEFINED METADATA_PROPERTY_ASPECT_RATIO
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'display.aspect.ratio',
                                        'Aspect Ratio', 'Current display aspect ratio',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', METADATA_PROPERTY_ASPECT_RATIO, RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);
      #END_IF

     }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue        (assetClientKey,   'display.aspect.ratio',  'Set Aspect Ratio',  'Set the aspect ratio');
          RmsAssetControlMethodArgumentEnum (assetClientKey,   'display.aspect.ratio',  0,
                                                               'Aspect Ratio', 'Select the aspect ratio to apply',
                                                               '',
                                                               METADATA_PROPERTY_ASPECT_RATIO);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DOCUMENT_CAMERA
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsDocumentCamera (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        // UPPER LIGHT

        // register the asset parameter for upper light power state
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'document.camera.light.upper.power',
                                      'Upper Light',  'The on/off state of the doc camera upper light',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        // register the asset parameter for upper lamp usage
        RmsAssetParameterEnqueueDecimalWithBargraph(assetClientKey,
                                       'lamp.consumption.upper',
                                       'Upper Light Hours',
                                       'Current consumption usage of the upper light.',
                                       RMS_ASSET_PARAM_TYPE_LAMP_USAGE,
                                       0,
                                       0,
                                       5000,
                                       'Hours',
                                       RMS_ALLOW_RESET_YES,
                                       0,
                                       RMS_TRACK_CHANGES_YES,
                                       'lamp.consumption');

        // add a default threshold for the upper lamp usage parameter
        RmsAssetParameterThresholdEnqueue(assetClientKey,
                                    'lamp.consumption.upper',
                                    'Lamp Life',
                                    RMS_STATUS_TYPE_MAINTENANCE,
                                    RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL,
                                    '5000');

        // LOWER LIGHT

        // register the asset parameter for upper light power state
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'document.camera.light.lower.power',
                                      'Lower Light',  'The on/off state of the doc camera lower light',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        // register the asset parameter for upper lamp usage
        RmsAssetParameterEnqueueDecimalWithBargraph(assetClientKey,
                                       'lamp.consumption.lower',
                                       'Lower Light Hours',
                                       'Current consumption usage of the lower light.',
                                       RMS_ASSET_PARAM_TYPE_LAMP_USAGE,
                                       0,
                                       0,
                                       5000,
                                       'Hours',
                                       RMS_ALLOW_RESET_YES,
                                       0,
                                       RMS_TRACK_CHANGES_YES,
                                       'lamp.consumption');

        // add a default threshold for the upper lamp usage parameter
        RmsAssetParameterThresholdEnqueue(assetClientKey,
                                    'lamp.consumption.lower',
                                    'Lamp Life',
                                    RMS_STATUS_TYPE_MAINTENANCE,
                                    RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL,
                                    '5000');
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'document.camera.light.upper.power', 'Upper Light', 'The on/off state of the doc camera upper light');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'document.camera.light.upper.power', 0,
                                                               'Upper Light State', 'Select the upper light state to apply',
                                                               0);

        RmsAssetControlMethodEnqueue          (assetClientKey, 'document.camera.light.lower.power', 'Lower Light', 'The on/off state of the doc camera lower light');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'document.camera.light.lower.power', 0,
                                                               'Lower Light State', 'Select the lower light state to apply',
                                                               0);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_GAIN
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsGain (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'gain.mute',
                                      'Gain Mute', 'The current gain mute state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'gain.level',
                                      'Gain Level', 'Current gain level',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_GAIN_LVL_INIT,
                                      METADATA_PROPERTY_GAIN_LVL_MIN,
                                      METADATA_PROPERTY_GAIN_LVL_MAX,
                                      METADATA_PROPERTY_GAIN_LVL_UNITS,
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_GAIN_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'gain.mute', 'Set Gain Mute', 'Turn the gain mute ON or OFF');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'gain.mute', 0,
                                                               'Gain Mute State', 'Select the gain mute state to apply',
                                                               0);

        RmsAssetControlMethodEnqueue          (assetClientKey, 'gain.level', 'Set Gain Level', 'Set the volume level');
          RmsAssetControlMethodArgumentLevel  (assetClientKey, 'gain.level', 0,
                                                               'Set Gain Level', 'Set the gain level within the range',
                                                               METADATA_PROPERTY_GAIN_LVL_INIT,
                                                               METADATA_PROPERTY_GAIN_LVL_MIN,
                                                               METADATA_PROPERTY_GAIN_LVL_MAX,
                                                               METADATA_PROPERTY_GAIN_LVL_STEP);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_HVAC
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsHvac (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                      'hvac.state',
                                      'HVAC State', 'Current hvac state',
                                      RMS_ASSET_PARAM_TYPE_HVAC_STATE,
                                      '', METADATA_PROPERTY_STAT_MODES, RMS_ALLOW_RESET_NO, '',
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                      'hvac.fan.status',
                                      'Fan Status', 'Current fan status',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      'Off', 'Off|On', RMS_ALLOW_RESET_NO, '',
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'hvac.thermostat.hold',
                                      'Thermostat Hold', 'The thermostat hold state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'hvac.thermostat.lock',
                                      'Thermostat Lock', 'The thermostat lock state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueNumber(assetClientKey,
                                       'hvac.cool.setpoint',
                                       'Cool Setpoint', 'Set the cool setpoint',
                                       RMS_ASSET_PARAM_TYPE_NONE,
                                       METADATA_PROPERTY_COOL_SETPOINT_LOW,
                                       METADATA_PROPERTY_COOL_SETPOINT_LOW,
                                       METADATA_PROPERTY_COOL_SETPOINT_HIGH,
                                       "176",
                                       RMS_ALLOW_RESET_NO,
                                       METADATA_PROPERTY_COOL_SETPOINT_LOW,
                                       RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueNumber(assetClientKey,
                                       'hvac.heat.setpoint',
                                       'Heat Setpoint', 'Set the heat setpoint',
                                       RMS_ASSET_PARAM_TYPE_NONE,
                                       METADATA_PROPERTY_HEAT_SETPOINT_LOW,
                                       METADATA_PROPERTY_HEAT_SETPOINT_LOW,
                                       METADATA_PROPERTY_HEAT_SETPOINT_HIGH,
                                       "176",
                                       RMS_ALLOW_RESET_NO,
                                       METADATA_PROPERTY_HEAT_SETPOINT_LOW,
                                       RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueDecimal(assetClientKey,
                                       'temperature.outdoor',
                                       'Outdoor Temperature', 'Current outdoor temperature',
                                       RMS_ASSET_PARAM_TYPE_TEMPERATURE,
                                       0,
                                       0,
                                       0,
                                       "176",
                                       RMS_ALLOW_RESET_NO,
                                       0,
                                       RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueDecimal(assetClientKey,
                                       'temperature.indoor',
                                       'Indoor Temperature', 'Current indoor temperature',
                                       RMS_ASSET_PARAM_TYPE_TEMPERATURE,
                                       0,
                                       0,
                                       0,
                                       "176",
                                       RMS_ALLOW_RESET_NO,
                                       0,
                                       RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'hvac.cool.setpoint.low' , 'Cool Setpoint Range:Low', METADATA_PROPERTY_COOL_SETPOINT_LOW );
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'hvac.cool.setpoint.hi'  , 'Cool Setpoint Range:Hi' , METADATA_PROPERTY_COOL_SETPOINT_HIGH);
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'hvac.heat.setpoint.low' , 'Heat Setpoint Range:Low', METADATA_PROPERTY_HEAT_SETPOINT_LOW );
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'hvac.heat.setpoint.hi'  , 'Heat Setpoint Range:Hi' , METADATA_PROPERTY_HEAT_SETPOINT_HIGH);
        RmsAssetMetadataEnqueueString(assetClientKey, 'hvac.temperature.scale' , 'Temperature Scale'      , METADATA_PROPERTY_TEMPERATURE_SCALE );
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'hvac.fan.state', 'Set Fan State', 'Set the fan state');
          RmsAssetControlMethodArgumentEnum   (assetClientKey, 'hvac.fan.state', 0,
                                                               'Fan State', 'Select the fan state to apply',
                                                               '',
                                                               'Off|On');

        RmsAssetControlMethodEnqueue          (assetClientKey, 'hvac.state', 'Set HVAC State', 'Set the HVAC state');
          RmsAssetControlMethodArgumentEnum   (assetClientKey, 'hvac.state', 0,
                                                               'HVAC State', 'Select the HVAC state to apply',
                                                               '',
                                                               METADATA_PROPERTY_STAT_MODES);

        RmsAssetControlMethodEnqueue           (assetClientKey,'hvac.cool.setpoint', 'Set Cool Setpoint','Set the cool setpoint');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'hvac.cool.setpoint', 0,
                                                               'Cool Setpoint', 'Set the cool setpoint',
                                                               METADATA_PROPERTY_COOL_SETPOINT_LOW,
                                                               METADATA_PROPERTY_COOL_SETPOINT_LOW,
                                                               METADATA_PROPERTY_COOL_SETPOINT_HIGH,
                                                               1);

        RmsAssetControlMethodEnqueue           (assetClientKey,'hvac.heat.setpoint', 'Set Heat Setpoint','Set the heat setpoint');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'hvac.heat.setpoint', 0,
                                                               'Heat Setpoint', 'Set the heat setpoint',
                                                               METADATA_PROPERTY_HEAT_SETPOINT_LOW,
                                                               METADATA_PROPERTY_HEAT_SETPOINT_LOW,
                                                               METADATA_PROPERTY_HEAT_SETPOINT_HIGH,
                                                               1);

        RmsAssetControlMethodEnqueue          (assetClientKey, 'hvac.thermostat.hold', 'Sets Thermostat Hold', 'Sets the thermostat hold state ON or OFF');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'hvac.thermostat.hold', 0,
                                                               'Thermostat Hold State',  'Select the thermostat hold state to apply',
                                                               0);

        RmsAssetControlMethodEnqueue          (assetClientKey, 'hvac.thermostat.lock', 'Sets Thermostat Lock', 'Sets the thermostat lock state ON or OFF');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'hvac.thermostat.lock', 0,
                                                               'Thermostat Lock State',  'Select the thermostat lock state to apply',
                                                               0);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_LAMP
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsLamp (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        // register the asset parameter for lamp usage
        RmsAssetParameterEnqueueDecimalWithBargraph(assetClientKey,
                                       'lamp.consumption',
                                       'Lamp Consumption',
                                       'Current usage of the lamp life',
                                       RMS_ASSET_PARAM_TYPE_LAMP_USAGE,
                                       0,
                                       0,
                                       2000,
                                       'Hours',
                                       RMS_ALLOW_RESET_YES,
                                       0,
                                       RMS_TRACK_CHANGES_YES,
                                       'lamp.consumption');

        // add a default threshold for the lamp usage parameter
        RmsAssetParameterThresholdEnqueue(assetClientKey,
                                    'lamp.consumption',
                                    'Lamp Life',
                                    RMS_STATUS_TYPE_MAINTENANCE,
                                    RMS_ASSET_PARAM_THRESHOLD_COMPARISON_GREATER_THAN_EQUAL,
                                    ITOA(METADATA_PROPERTY_LAMP_THRESHOLD));
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'projector.lamp.warmup.time'  , 'Lamp Warm Up Time (seconds)'  , METADATA_PROPERTY_LAMP_WARMUP_TIME  );
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'projector.lamp.cooldown.time', 'Lamp Cool Down Time (seconds)', METADATA_PROPERTY_LAMP_COOLDOWN_TIME);
      }
      CASE 'CONTROL_METHODS' :
      {
      // See RegisterAssetsPower() for lamp control method.
      }
    }
  }
#END_IF

#IF_DEFINED HAS_PHONEBOOK
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsPhonebook (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'phonebook.capacity', 'Phonebook Capacity', METADATA_PROPERTY_PHONEBOOK_CAPACITY);
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue           (assetClientKey, 'dialer.dial.preset', 'Dial Speed Dial Preset', 'Dial a number given an index');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey, 'dialer.dial.preset', 0,
                                                                'Speed Dial Index', 'Select the speed dial index to apply',
                                                                1,
                                                                1, METADATA_PROPERTY_PHONEBOOK_CAPACITY,
                                                                1);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_POWER
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsPower (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
#IF_DEFINED HAS_LAMP
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'projector.lamp.power',
                                        'Lamp Power', 'Current lamp power state',
                                        RMS_ASSET_PARAM_TYPE_ASSET_POWER,
                                        'Off', 'Off|On', RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_YES);
#ELSE
        RmsAssetPowerParameterEnqueue(assetClientKey,FALSE)
#END_IF
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
#IF_DEFINED HAS_LAMP
          RmsAssetControlMethodEnqueue        (assetClientKey,  'projector.lamp.power', 'Set Lamp Power', 'Turn the video project lamp ON or OFF');
          RmsAssetControlMethodArgumentEnum   (assetClientKey,  'projector.lamp.power', 0,
                                                                'Power State', 'Select the power state to apply',
                                                                '',
                                                                'Off|On');
#ELSE
          RmsAssetControlMethodEnqueue        (assetClientKey,  'asset.power', 'Set Power', 'Turn the asset/device ON or OFF');
          RmsAssetControlMethodArgumentEnum   (assetClientKey,  'asset.power', 0,
                                                                'Power State', 'Select the power state to apply',
                                                                '',
                                                                'Off|On');
#END_IF
      }
    }
  }
#END_IF

#IF_DEFINED HAS_FIXED_POWER
  (*****************************************************)
  (* Call Name: RegisterAssetsFixedPower               *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsFixedPower (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetPowerParameterEnqueue(assetClientKey,TRUE)
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      }
    }
  }
#END_IF

#IF_DEFINED HAS_PREAMP
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsPreamp (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      #IF_DEFINED METADATA_PROPERTY_PREAMP_BALANCE_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'preamp.balance',
                                      'Balance Level', 'Current balance level',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_PREAMP_BALANCE_INIT,
                                      METADATA_PROPERTY_PREAMP_BALANCE_MIN,
                                      METADATA_PROPERTY_PREAMP_BALANCE_MAX,
                                      METADATA_PROPERTY_PREAMP_BALANCE_UNITS,
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_PREAMP_BALANCE_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_PREAMP_BASS_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'preamp.bass',
                                      'Bass Level', 'Current bass level',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_PREAMP_BASS_INIT,
                                      METADATA_PROPERTY_PREAMP_BASS_MIN,
                                      METADATA_PROPERTY_PREAMP_BASS_MAX,
                                      METADATA_PROPERTY_PREAMP_BASS_UNITS,
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_PREAMP_BASS_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_PREAMP_TREBLE_INIT
        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'preamp.treble',
                                      'Treble Level', 'Current treble level',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_PREAMP_TREBLE_INIT,
                                      METADATA_PROPERTY_PREAMP_TREBLE_MIN,
                                      METADATA_PROPERTY_PREAMP_TREBLE_MAX,
                                      METADATA_PROPERTY_PREAMP_TREBLE_UNITS,
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_PREAMP_TREBLE_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_GENERAL_PURPOSE);
      #END_IF

      RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'preamp.loudness',
                                      'Loudness State', 'The current loudness state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
      #IF_DEFINED METADATA_PROPERTY_PREAMP_BALANCE_INIT
        RmsAssetControlMethodEnqueue          (assetClientKey, 'preamp.balance', 'Set Balance Level','Set the current balance level');
          RmsAssetControlMethodArgumentLevel  (assetClientKey, 'preamp.balance', 0,
                                                               'Balance Level', 'Set the balance level within the range',
                                                               METADATA_PROPERTY_PREAMP_BALANCE_INIT,
                                                               METADATA_PROPERTY_PREAMP_BALANCE_MIN,
                                                               METADATA_PROPERTY_PREAMP_BALANCE_MAX,
                                                               METADATA_PROPERTY_PREAMP_BALANCE_STEP);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_PREAMP_BASS_INIT
        RmsAssetControlMethodEnqueue          (assetClientKey, 'preamp.bass', 'Set Bass Level','Set the current bass level');
          RmsAssetControlMethodArgumentLevel  (assetClientKey, 'preamp.bass', 0,
                                                               'Bass Level',  'Set the bass level in the range',
                                                               METADATA_PROPERTY_PREAMP_BASS_INIT,
                                                               METADATA_PROPERTY_PREAMP_BASS_MIN,
                                                               METADATA_PROPERTY_PREAMP_BASS_MAX,
                                                               METADATA_PROPERTY_PREAMP_BASS_STEP);
      #END_IF

      #IF_DEFINED METADATA_PROPERTY_PREAMP_TREBLE_INIT
        RmsAssetControlMethodEnqueue          (assetClientKey, 'preamp.treble', 'Set Treble Level','Set the current treble level');
          RmsAssetControlMethodArgumentLevel  (assetClientKey, 'preamp.treble', 0,
                                                               'Treble Level', 'Set the treble level within the range',
                                                               METADATA_PROPERTY_PREAMP_TREBLE_INIT,
                                                               METADATA_PROPERTY_PREAMP_TREBLE_MIN,
                                                               METADATA_PROPERTY_PREAMP_TREBLE_MAX,
                                                               METADATA_PROPERTY_PREAMP_TREBLE_STEP);
      #END_IF

      RmsAssetControlMethodEnqueue          (assetClientKey, 'preamp.loudness', 'Set Loudness State', 'Turn the loudness state on or off');
        RmsAssetControlMethodArgumentBoolean(assetClientKey, 'preamp.loudness', 0,
                                                             'Loudness State',  'Select the loudness state to apply',
                                                             0);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_SECURITY_SYSTEM
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsSecuritySystem (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'secuirty.system.status',
                                        'Security Status', 'Current security status',
                                        RMS_ASSET_PARAM_TYPE_SECURITY_STATE,
                                        '', METADATA_PROPERTY_SECURITY_STATES, RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                        'security.oktoarm',
                                        'OK to Arm',  'Whether it is OK to arm the security system',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                        RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue        (assetClientKey, 'security.system.state', 'Set Security State', 'Set the current security system state');
          RmsAssetControlMethodArgumentEnum (assetClientKey, 'security.system.state', 0,
                                                             'Security System State', 'Select the security system state',
                                                             '',
                                                             METADATA_PROPERTY_SECURITY_STATES);
        RmsAssetControlMethodArgumentString (assetClientKey, 'security.system.state', 1,
                                                             'Security System Password', 'Enter the security system password',
                                                             '');
      }
    }
  }
#END_IF

#IF_DEFINED HAS_SOURCE_SELECT
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsSourceSelect (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'source.input',
                                        'Input Source', 'Current selected input source',
                                        RMS_ASSET_PARAM_TYPE_SOURCE_STATE,
                                        '', METADATA_PROPERTY_SOURCE_INPUT, RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_YES);
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'source.input.count', 'Input Source Count', METADATA_PROPERTY_SOURCE_INPUT_COUNT);
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue        (assetClientKey, 'source.input', 'Select Input Source', 'Select the input source');
          RmsAssetControlMethodArgumentEnum (assetClientKey, 'source.input', 0,
                                                             'Input Source', 'Select the input source to apply',
                                                             '',
                                                             METADATA_PROPERTY_SOURCE_INPUT);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_SWITCHER
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsSwitcher (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.input.count' , 'Switcher Input Count' , METADATA_PROPERTY_SWITCHER_INPUT_COUNT );
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.output.count', 'Switcher Output Count', METADATA_PROPERTY_SWITCHER_OUTPUT_COUNT);

        #IF_DEFINED METADATA_PROPERTY_SWITCHER_PRESET_COUNT
          RmsAssetMetadataEnqueueNumber(assetClientKey, 'switcher.preset.count', 'Switcher Preset Count', METADATA_PROPERTY_SWITCHER_PRESET_COUNT);
        #END_IF
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue        (assetClientKey, 'switcher.switch', 'Switch', 'Connect the input source to the output source');
          RmsAssetControlMethodArgumentEnum (assetClientKey, 'switcher.switch', 0,
                                                             'Switch Level', 'Select the switch level to apply',
                                                             '',
                                                             METADATA_PROPERTY_SWITCHER_LEVELS);
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'switcher.switch', 1,
                                                               'Input', 'Set the switchers input source',
                                                               1,
                                                               1, METADATA_PROPERTY_SWITCHER_INPUT_COUNT,
                                                               1);
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'switcher.switch', 2,
                                                               'Output', 'Set the switchers output destination',
                                                               1,
                                                               1, METADATA_PROPERTY_SWITCHER_OUTPUT_COUNT,
                                                               1);

        #IF_DEFINED METADATA_PROPERTY_SWITCHER_PRESET_COUNT
          RmsAssetControlMethodEnqueue          (assetClientKey, 'switcher.preset', 'Select Switcher Preset','Select the switchers preset');
            RmsAssetControlMethodArgumentNumberEx(assetClientKey,'switcher.preset', 0,
                                                                 'Switcher Preset', 'Select the switchers preset to apply',
                                                                 1,
                                                                 1, METADATA_PROPERTY_SWITCHER_PRESET_COUNT,
                                                                 1);
        #END_IF
      }
    }
  }
#END_IF

#IF_DEFINED HAS_TUNER
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsTuner (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        IF(LENGTH_STRING(METADATA_PROPERTY_TUNER_BAND))
        {
          RmsAssetParameterEnqueueEnumeration(assetClientKey,
                                        'tuner.band',
                                        'Tuner Band', 'Current selected tuner band',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', METADATA_PROPERTY_TUNER_BAND, RMS_ALLOW_RESET_NO, '',
                                        RMS_TRACK_CHANGES_NO);
        }

        RmsAssetParameterEnqueueString(assetClientKey,
                                        'tuner.station',
                                        'Station', 'Current stations name',
                                        RMS_ASSET_PARAM_TYPE_NONE,
                                        '', '', RMS_ALLOW_RESET_NO, 'Reset',
                                        RMS_TRACK_CHANGES_NO);
      }
      CASE 'METADATA' :
      {
        RmsAssetMetadataEnqueueNumber(assetClientKey, 'tuner.station.count', 'Station Preset Count', METADATA_PROPERTY_STATION_PRESET_COUNT);

        IF(METADATA_PROPERTY_TUNER_BAND_COUNT > 0)
        {
          RmsAssetMetadataEnqueueNumber(assetClientKey, 'tuner.band.count', 'Tuner Band Count', METADATA_PROPERTY_TUNER_BAND_COUNT);
        }
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'tuner.station', 'Set Station', 'Set the station');
          RmsAssetControlMethodArgumentString (assetClientKey, 'tuner.station', 0,
                                                               'Set Station', 'Enter the station string such as 103.7',
                                                               '');

        RmsAssetControlMethodEnqueue          (assetClientKey, 'tuner.station.preset', 'Select Station Preset','Set the station preset');
          RmsAssetControlMethodArgumentNumberEx(assetClientKey,'tuner.station.preset', 0,
                                                               'Preset', 'Select the station preset to apply',
                                                               1,
                                                               1, METADATA_PROPERTY_STATION_PRESET_COUNT,
                                                               1);

        IF(LENGTH_STRING(METADATA_PROPERTY_TUNER_BAND))
        {
          RmsAssetControlMethodEnqueue        (assetClientKey, 'tuner.band', 'Select Tuner Band', 'Set the band');
            RmsAssetControlMethodArgumentEnum (assetClientKey, 'tuner.band', 0,
                                                               'Tuner Band', 'Select the band to apply',
                                                               '',
                                                               METADATA_PROPERTY_TUNER_BAND);
        }
      }
    }
  }
#END_IF

#IF_DEFINED HAS_VOLUME
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsVolume (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
        RmsAssetParameterEnqueueBoolean(assetClientKey,
                                      'volume.mute',
                                      'Volume Mute', 'The current volume mute state',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      FALSE, RMS_ALLOW_RESET_NO, FALSE,
                                      RMS_TRACK_CHANGES_NO);

        RmsAssetParameterEnqueueLevel(assetClientKey,
                                      'volume.level',
                                      'Volume Level', 'Current volume level',
                                      RMS_ASSET_PARAM_TYPE_NONE,
                                      METADATA_PROPERTY_VOL_LVL_INIT,
                                      METADATA_PROPERTY_VOL_LVL_MIN,
                                      METADATA_PROPERTY_VOL_LVL_MAX,
                                      METADATA_PROPERTY_VOL_LVL_UNITS,
                                      RMS_ALLOW_RESET_NO,
                                      METADATA_PROPERTY_VOL_LVL_RESET,
                                      RMS_TRACK_CHANGES_NO,
                                      RMS_ASSET_PARAM_BARGRAPH_VOLUME_LEVEL);
      }
      CASE 'METADATA' :
      {
      }
      CASE 'CONTROL_METHODS' :
      {
        RmsAssetControlMethodEnqueue          (assetClientKey, 'volume.mute', 'Set Volume Mute', 'Turn the volume mute on or off');
          RmsAssetControlMethodArgumentBoolean(assetClientKey, 'volume.mute', 0,
                                                               'Volume Mute State', 'Select the volume mute state to apply',
                                                               0);

        RmsAssetControlMethodEnqueue          (assetClientKey, 'volume.level', 'Set Volume Level','Set the volume level');
          RmsAssetControlMethodArgumentLevel  (assetClientKey, 'volume.level', 0,
                                                               'Set Volume Level', 'Set the volume level',
                                                               METADATA_PROPERTY_VOL_LVL_INIT,
                                                               METADATA_PROPERTY_VOL_LVL_MIN,
                                                               METADATA_PROPERTY_VOL_LVL_MAX,
                                                               METADATA_PROPERTY_VOL_LVL_STEP);
      }
    }
  }
#END_IF

#IF_DEFINED HAS_LIGHT
  (*****************************************************)
  (* Call Name: RegisterAssets                         *)
  (* Function:  registers this asset's snapi           *)
  (*            components with RMS for parameters,    *)
  (*            metadata, and control methods.         *)
  (*****************************************************)
  DEFINE_FUNCTION RegisterAssetsLight (CHAR assetClientKey[], CHAR cRegister[15])
  {
    SWITCH(cRegister)
    {
      CASE 'PARAMETERS' :
      {
      }
      CASE 'METADATA' :
      {
        #IF_DEFINED METADATA_PROPERTY_LIGHT_SCENE_COUNT
          RmsAssetMetadataEnqueueNumber(assetClientKey, 'light.scene.count', 'Light Scene Count', METADATA_PROPERTY_LIGHT_SCENE_COUNT);
        #END_IF
      }
      CASE 'CONTROL_METHODS' :
      {
        #IF_DEFINED METADATA_PROPERTY_LIGHT_SCENE_COUNT
          RmsAssetControlMethodEnqueue          (assetClientKey, 'light.scene', 'Select Light Scene','Select the lighting scene');
            RmsAssetControlMethodArgumentNumberEx(assetClientKey,'light.scene', 0,
                                                                 'light.scene', 'Select the lighting scene to apply',
                                                                 0,
                                                                 0, METADATA_PROPERTY_LIGHT_SCENE_COUNT,
                                                                 1);
        #END_IF
      }
    }
  }
#END_IF



(************************************************************************************************************)
(*                                   Helper functions                                                       *)
(************************************************************************************************************)

(**********************************************************)
(* Call Name: RmsNlSnapiGetEnumIndex                      *)
(* Function:  Return index pointer of value in enum.      *)
(**********************************************************)
DEFINE_FUNCTION INTEGER RmsNlSnapiGetEnumIndex(CHAR cValue[RMS_MAX_PARAM_LEN], CHAR cEnumList[RMS_MAX_PARAM_LEN])
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
    IF(cTemp = cValue)
      RETURN(nIndex);
  }

  RETURN(0);
}

DEFINE_FUNCTION CHAR[DUET_MAX_PARAM_LEN] RmsNlSnapiAppendEnum (CHAR cList[DUET_MAX_PARAM_LEN], CHAR cValue[DUET_MAX_PARAM_LEN])
{
  stringTrim(cValue)

  IF(!LENGTH_STRING(cList))
    cList = "cValue"
  ELSE
    cList = "cList,'|',cValue"

  RETURN(cList)
}

DEFINE_FUNCTION INTEGER stringLTrim(CHAR strTXT[RMS_MAX_PARAM_LEN])
STACK_VAR
  INTEGER nTrimmed
{
  WHILE(LENGTH_STRING(strTXT)) {
    IF(strTXT[1] = $20) {
      GET_BUFFER_CHAR(strTXT)
      nTrimmed++
    }
    ELSE {
      BREAK
    }
  }

  RETURN(nTrimmed)
}

DEFINE_FUNCTION INTEGER stringRTrim(CHAR strTXT[RMS_MAX_PARAM_LEN])
STACK_VAR
  INTEGER nTrimmed
{
  WHILE(LENGTH_STRING(strTXT)) {
    IF(strTXT[LENGTH_STRING(strTXT)] = $20) {
      SET_LENGTH_STRING(strTXT,LENGTH_STRING(strTXT)-1)
      nTrimmed++
    }
    ELSE {
      BREAK
    }
  }

  RETURN(nTrimmed)
}

DEFINE_FUNCTION CHAR[RMS_MAX_PARAM_LEN] stringTrim(CHAR strTXT[RMS_MAX_PARAM_LEN])
{
  stringLTrim(strTXT)
  stringRTrim(strTXT)

  RETURN(strTXT)
}

DEFINE_FUNCTION CHAR IsRmsReady()
{
  RETURN ([vdvRMS,RMS_CHANNEL_ASSETS_REGISTER] && assetRegistered);
}

(**********************************************************)
(* Call Name: GetOnlineSnapiValue                         *)
(* Function:  Return device's online state.               *)
(**********************************************************)
DEFINE_FUNCTION INTEGER GetOnlineSnapiValue(DEV device)
{
  // the physical device must be online and the SNAPI
  // channel for DATA_INITIALIZED must be turned on
  RETURN(DEVICE_ID(device) && [vdvDevice,DEVICE_COMMUNICATING])
}


(**********************************************************)
(* Call Name: GetDataInitializedSnapiValue                *)
(* Function:  Return device's data initialized state.     *)
(**********************************************************)
DEFINE_FUNCTION CHAR GetDataInitializedSnapiValue(DEV device)
{
  // the physical device must be online and the SNAPI
  // channel for DATA_INITIALIZED must be turned on
  RETURN(DEVICE_ID(device) && [vdvDevice,DATA_INITIALIZED])
}


(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT

//
// Update the "asset.online" parameter in RMS if the SNAPI
// virtual device channel DEVICE_COMMUNICATING (251) changes.
//
// For the "asset.online" parameter to show ONLINE the physical
// device must be ONLINE and channel DEVICE_COMMUNICATING (251)
// must be ON.
//
CHANNEL_EVENT[vdvDevice,DEVICE_COMMUNICATING]
{
  ON:
  {
    IF(IsRmsReady())
      RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice))
  }
  OFF:
  {
    IF(IsRmsReady())
      RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice))
  }
}

//
// Update the "asset.data.initialized" parameter in RMS if the SNAPI
// virtual device channel DATA_INITIALIZED (252) changes.
//
// For the "asset.data.initialized" parameter to show TRUE the physical
// device must be ONLINE and channel DATA_INITIALIZED (252)
// must be ON.
//
CHANNEL_EVENT[vdvDevice,DATA_INITIALIZED]
{
  ON:
  {
    IF(IsRmsReady())
      RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice))
  }
  OFF:
  {
    IF(IsRmsReady())
      RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice))
  }
}

//
// Update the "asset.online" parameter in RMS if the physical
// device online status changes.
//
// For the "asset.online" parameter to show ONLINE the physical
// device must be ONLINE and channel DEVICE_COMMUNICATING (251)
// must be ON.
//
DATA_EVENT[vdvDevice]
{
  ONLINE :
  {
    IF(IsRmsReady())
    {
      RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice));
      RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice));
    }
  }
  OFFLINE :
  {
    IF(IsRmsReady())
    {
      RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice));
      RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice));
    }
  }
  ONERROR :
  {
    // With these errors, the socket is still open (online).
    // With all other errors, the socket closes without an offline event.
    IF((DATA.NUMBER <> 13) && (DATA.NUMBER <> 14))
    {
      IF(IsRmsReady())
      {
        RmsAssetOnlineParameterUpdate(assetClientKey, GetOnlineSnapiValue(vdvDevice));
        RmsAssetDataInitializedParameterUpdate(assetClientKey, GetDataInitializedSnapiValue(vdvDevice));
      }
    }
  }
}


(************************************************************************************************************)
(*                                   Individual SNAPI component commands                                    *)
(************************************************************************************************************)
//
// (VIRTUAL DEVICE EVENT HANDLERS)
//
DATA_EVENT[vdvDevice]
{
  ONLINE :
  {
#IF_DEFINED HAS_POWER     // See channel events
#END_IF

#IF_DEFINED HAS_VOLUME    // See channel/level events
#END_IF

#IF_DEFINED HAS_GAIN      // See channel/level events
#END_IF

#IF_DEFINED HAS_PREAMP    // See channel/level events
#END_IF

#IF_DEFINED HAS_DIALER
    SEND_COMMAND DATA.DEVICE,'?DIALERSTATUS'
#END_IF

#IF_DEFINED HAS_PHONEBOOK
    SEND_COMMAND DATA.DEVICE,'?PHONEBOOKCAPACITY'
#END_IF

#IF_DEFINED HAS_CONFERENCER     // See channel events
#END_IF

#IF_DEFINED HAS_CAMERA_PRESET
    SEND_COMMAND DATA.DEVICE,'?CAMERAPRESETCOUNT'
    SEND_COMMAND DATA.DEVICE,'?CAMERAPRESET'
#END_IF

#IF_DEFINED HAS_CAMERA_PAN_TILT     // See channel/level events
#END_IF

#IF_DEFINED HAS_CAMERA_LENS         // See channel/level events
#END_IF

#IF_DEFINED HAS_SOURCE_SELECT
    SEND_COMMAND DATA.DEVICE,'?INPUT'
    SEND_COMMAND DATA.DEVICE,'?INPUTCOUNT'
    SEND_COMMAND DATA.DEVICE,'?INPUTPROPERTIES'
    SEND_COMMAND DATA.DEVICE,'?INPUTSELECT'
#END_IF

#IF_DEFINED HAS_LAMP
#END_IF

#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO
    SEND_COMMAND DATA.DEVICE,'?ASPECT'
    SEND_COMMAND DATA.DEVICE,'?ASPECTRATIOCOUNT'
    SEND_COMMAND DATA.DEVICE,'?ASPECTRATIOPROPERTIES'
    SEND_COMMAND DATA.DEVICE,'?ASPECTRATIOSELECT'

    SEND_COMMAND DATA.DEVICE,'?VIDEOTYPE'
#END_IF

#IF_DEFINED HAS_TUNER
    SEND_COMMAND DATA.DEVICE,'?BAND'
    SEND_COMMAND DATA.DEVICE,'?TUNERBANDPROPERTYCOUNT'
    SEND_COMMAND DATA.DEVICE,'?TUNERBANDPROPERTIES'
    SEND_COMMAND DATA.DEVICE,'?TUNERBANDSELECT'

    SEND_COMMAND DATA.DEVICE,'?TUNERPRESET'
    SEND_COMMAND DATA.DEVICE,'?STATIONPRESETCOUNT'
    SEND_COMMAND DATA.DEVICE,'?STATIONPRESETSELECT'

    SEND_COMMAND DATA.DEVICE,'?XCH'
#END_IF

#IF_DEFINED HAS_DISC_TRANSPORT    // See channel events
#END_IF

#IF_DEFINED HAS_SWITCHER
#END_IF

#IF_DEFINED HAS_LIGHT
    SEND_COMMAND DATA.DEVICE,'?SCENEPRESET'
#END_IF
  }
  COMMAND :
  {
    STACK_VAR CHAR cHeader[DUET_MAX_HDR_LEN]
    STACK_VAR CHAR cValue1[DUET_MAX_PARAM_LEN]
    STACK_VAR INTEGER nValue1

    cHeader = DuetParseCmdHeader(DATA.TEXT)
    cValue1 = DuetParseCmdParam (DATA.TEXT)
    nValue1 = ATOI(cValue1)

    SWITCH(cHeader)
    {
#IF_DEFINED HAS_POWER     // See channel events
#END_IF

#IF_DEFINED HAS_VOLUME    // See channel/level events
#END_IF

#IF_DEFINED HAS_GAIN      // See channel/level events
#END_IF

#IF_DEFINED HAS_PREAMP    // See channel/level events
#END_IF

#IF_DEFINED HAS_DIALER
      CASE 'DIALERSTATUS' :
      {
        SWITCH(cValue1)
        {
          CASE 'DIALING'      : KeySetValue('dialer.status', 'Dialing'     );
          CASE 'BUSY'         : KeySetValue('dialer.status', 'Busy'        );
          CASE 'RINGING'      : KeySetValue('dialer.status', 'Ringing'     );
          CASE 'DISCONNECTED' : KeySetValue('dialer.status', 'Disconnected');
          CASE 'NEGOTIATING'  : KeySetValue('dialer.status', 'Negotiating' );
          CASE 'FAULT'        : KeySetValue('dialer.status', 'Fault'       );
          CASE 'CONNECTED'    : KeySetValue('dialer.status', 'Connected'   );
        }

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'dialer.status', KeyGetValue('dialer.status'));
      }
      CASE 'INCOMINGCALL' :
      {
        KeySetValue('dialer.incoming.call', cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'dialer.incoming.call', KeyGetValue('dialer.incoming.call'));
      }
#END_IF

#IF_DEFINED HAS_PHONEBOOK
      CASE 'PHONEBOOKCAPACITY' :
      {
        METADATA_PROPERTY_PHONEBOOK_CAPACITY = nValue1

        IF(IsRmsReady())
        {
          RegisterAssetsPhonebook (assetClientKey, 'METADATA')
          RmsAssetMetadataSubmit(assetClientKey)

          RegisterAssetsPhonebook (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
#END_IF

#IF_DEFINED HAS_CONFERENCER     // See channel events
#END_IF

#IF_DEFINED HAS_CAMERA_PRESET
      CASE 'CAMERAPRESETCOUNT' :
      {
        METADATA_PROPERTY_CAMERA_PRESET_COUNT = nValue1

        IF(IsRmsReady())
        {
          RegisterAssetsCameraPreset (assetClientKey, 'PARAMETERS')
          RmsAssetParameterSubmit(assetClientKey)

          RegisterAssetsCameraPreset (assetClientKey, 'METADATA')
          RmsAssetMetadataSubmit(assetClientKey)

          RegisterAssetsCameraPreset (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
      CASE 'CAMERAPRESET' :
      {
        KeySetValue('camera.preset',ITOA(nValue1));

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'camera.preset', ITOA(nValue1) );
      }
#END_IF

#IF_DEFINED HAS_CAMERA_PAN_TILT     // See channel/level events
#END_IF

#IF_DEFINED HAS_CAMERA_LENS         // See channel/level events
#END_IF

#IF_DEFINED HAS_SOURCE_SELECT
      CASE 'INPUT' :
      {
        KeySetValue('source.input',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'source.input' , cValue1);
      }
      CASE 'INPUTCOUNT' :
      {
        METADATA_PROPERTY_SOURCE_INPUT_COUNT = nValue1

        IF(IsRmsReady())
        {
          RegisterAssetsSourceSelect (assetClientKey, 'METADATA')
          RmsAssetMetadataSubmit(assetClientKey)
        }
      }
      CASE 'INPUTPROPERTIES' :
      { // 'INPUTPROPERTIES-"1,InpGrp,SigType,DevLbl,DispName"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

        cValue2 = DuetParseCmdParam(cValue1)
        nValue1 = ATOI(cValue2)

        IF(nValue1 = 1)
          METADATA_PROPERTY_SOURCE_INPUT = ""

//      cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Input group
        cValue2 = DuetParseCmdParam(cValue1)  // Signal type
        cValue2 = DuetParseCmdParam(cValue1)  // Device label
        cValue2 = DuetParseCmdParam(cValue1)  // Display name

        METADATA_PROPERTY_SOURCE_INPUT = RmsNlSnapiAppendEnum (METADATA_PROPERTY_SOURCE_INPUT,cValue2)

        IF(IsRmsReady())
        {
          RegisterAssetsSourceSelect (assetClientKey, 'PARAMETERS')
          RmsAssetParameterSubmit(assetClientKey)

          RegisterAssetsSourceSelect (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
      CASE 'INPUTSELECT' :
      {
        KeySetValue('source.input',RmsGetEnumValue (nValue1, METADATA_PROPERTY_SOURCE_INPUT));

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'source.input' , RmsGetEnumValue (nValue1, METADATA_PROPERTY_SOURCE_INPUT));
      }
      CASE 'INPUTPROPERTY' :
      { // 'INPUTPROPERTY-"1,InpGrp,SigType,DevLbl,DispName"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

        cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Input group
        cValue2 = DuetParseCmdParam(cValue1)  // Signal type
        cValue2 = DuetParseCmdParam(cValue1)  // Device label
        cValue2 = DuetParseCmdParam(cValue1)  // Display name

        KeySetValue('source.input',cValue2);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'source.input' , "cValue2");
      }
#END_IF

#IF_DEFINED HAS_LAMP
      CASE 'LAMPTIME' :
      {
        KeySetValue('lamp.consumption',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'lamp.consumption' , cValue1);

      #IF_DEFINED TL_MONITOR_LAMP_RUNTIME
        RMSTimerOverride(TL_MONITOR_LAMP_RUNTIME)
      #END_IF
      }
#END_IF

#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO
      CASE 'ASPECT' :
      {
        KeySetValue('display.aspect.ratio',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'display.aspect.ratio' , cValue1);
      }
      CASE 'ASPECTRATIOCOUNT' :
      {
      }
      CASE 'ASPECTRATIOPROPERTIES' :
      { // 'ASPECTRATIOPROPERTIES-"1,DispName,Value"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

        cValue2 = DuetParseCmdParam(cValue1)
        nValue1 = ATOI(cValue2)

        IF(nValue1 = 1)
          METADATA_PROPERTY_ASPECT_RATIO = ""

//      cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Display Name
//      cValue2 = DuetParseCmdParam(cValue1)  // Value

        METADATA_PROPERTY_ASPECT_RATIO = RmsNlSnapiAppendEnum (METADATA_PROPERTY_ASPECT_RATIO,cValue2)

        IF(IsRmsReady())
        {
          RegisterAssetsDisplayAspectRatio (assetClientKey, 'PARAMETERS')
          RmsAssetParameterSubmit(assetClientKey)

          RegisterAssetsDisplayAspectRatio (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
      CASE 'ASPECTRATIOSELECT' :
      {
        KeySetValue('display.aspect.ratio',RmsGetEnumValue (nValue1, METADATA_PROPERTY_ASPECT_RATIO));

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'display.aspect.ratio' , RmsGetEnumValue (nValue1, METADATA_PROPERTY_ASPECT_RATIO));
      }
      CASE 'ASPECTRATIOPROPERTY' :
      { // 'ASPECTRATIOPROPERTY-1,DispName,Value"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

//      cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Display name
//      cValue2 = DuetParseCmdParam(cValue1)  // Value

        KeySetValue('display.aspect.ratio',cValue2);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'display.aspect.ratio' , "cValue2");
      }
      CASE 'VIDEOTYPE' :
      {
        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'display.video.type'   , cValue1);
      }
#END_IF

#IF_DEFINED HAS_TUNER
      CASE 'BAND' :
      {
        KeySetValue('tuner.band',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'tuner.band'   , cValue1);
      }
      CASE 'TUNERBANDPROPERTYCOUNT' :
      {
        METADATA_PROPERTY_TUNER_BAND_COUNT = nValue1

        IF(IsRmsReady())
        {
          RegisterAssetsTuner (assetClientKey, 'METADATA')
          RmsAssetMetadataSubmit(assetClientKey)
        }
      }
      CASE 'TUNERBANDPROPERTIES' :
      { // 'TUNERBANDPROPERTIES-"1,DispName,Value"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

        cValue2 = DuetParseCmdParam(cValue1)
        nValue1 = ATOI(cValue2)

        IF(nValue1 = 1)
          METADATA_PROPERTY_TUNER_BAND = ""

//      cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Display name
//      cValue2 = DuetParseCmdParam(cValue1)  // Value

        METADATA_PROPERTY_TUNER_BAND = RmsNlSnapiAppendEnum (METADATA_PROPERTY_TUNER_BAND,cValue2)

        IF(IsRmsReady())
        {
          RegisterAssetsTuner (assetClientKey, 'PARAMETERS')
          RmsAssetParameterSubmit(assetClientKey)

          RegisterAssetsTuner (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
      CASE 'TUNERBANDSELECT' :
      {
        KeySetValue('tuner.band',RmsGetEnumValue (nValue1, METADATA_PROPERTY_TUNER_BAND));

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'tuner.band' , RmsGetEnumValue (nValue1, METADATA_PROPERTY_TUNER_BAND));
      }
      CASE 'TUNERBANDPROPERTY' :
      { // 'TUNERBANDPROPERTY-1,DispName,Value"'
        STACK_VAR CHAR cValue2[DUET_MAX_PARAM_LEN]

//      cValue2 = DuetParseCmdParam(cValue1)  // Index
        cValue2 = DuetParseCmdParam(cValue1)  // Display name
//      cValue2 = DuetParseCmdParam(cValue1)  // Value

        KeySetValue('tuner.band',cValue2);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'tuner.band' , "cValue2");
      }
      CASE 'STATIONPRESETCOUNT' :
      {
        METADATA_PROPERTY_STATION_PRESET_COUNT = nValue1

        IF(IsRmsReady())
        {
          RegisterAssetsTuner (assetClientKey, 'PARAMETERS')
          RmsAssetParameterSubmit(assetClientKey)

          RegisterAssetsTuner (assetClientKey, 'METADATA')
          RmsAssetMetadataSubmit(assetClientKey)

          RegisterAssetsTuner (assetClientKey, 'CONTROL_METHODS')
          RmsAssetControlMethodsSubmit(assetClientKey)
        }
      }
      CASE 'XCH' :
      {
        KeySetValue('tuner.station',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'tuner.station', cValue1);
      }
#END_IF

#IF_DEFINED HAS_DISC_TRANSPORT    // See channel events
#END_IF

#IF_DEFINED HAS_SWITCHER
#END_IF

#IF_DEFINED HAS_LIGHT
      CASE 'SCENEPRESET' :
      {
        KeySetValue('light.scene',cValue1);

        IF(IsRmsReady())
          RmsAssetParameterSetValue(assetClientKey, 'light.scene', cValue1);
      }
#END_IF

      DEFAULT :
      {
      }
    }
  }
}


(************************************************************************************************************)
(*                                   Individual SNAPI component channels & levels                           *)
(************************************************************************************************************)
#IF_DEFINED HAS_POWER
  CHANNEL_EVENT[vdvDevice,POWER_FB]
  {
    ON :
    {
#IF_DEFINED HAS_LAMP
      IF(IsRmsReady())
        RmsAssetParameterSetValue(assetClientKey,'projector.lamp.power','On');
#ELSE
      IF(IsRmsReady())
        RmsAssetParameterSetValue(assetClientKey,'asset.power','On');
#END_IF

    #IF_DEFINED TL_MONITOR_POWER_ON
      RMSTimerStart (TL_MONITOR_POWER_ON);
    #END_IF
    #IF_DEFINED TL_MONITOR_LAMP_RUNTIME
      RMSTimerStart (TL_MONITOR_LAMP_RUNTIME);
    #END_IF
    }
    OFF :
    {
#IF_DEFINED HAS_LAMP
      IF(IsRmsReady())
        RmsAssetParameterSetValue(assetClientKey,'projector.lamp.power','Off');
#ELSE
      IF(IsRmsReady())
        RmsAssetParameterSetValue(assetClientKey,'asset.power','Off');
#END_IF

    #IF_DEFINED TL_MONITOR_POWER_ON
      RMSTimerStop  (TL_MONITOR_POWER_ON);
    #END_IF
    #IF_DEFINED TL_MONITOR_LAMP_RUNTIME
      RMSTimerStop (TL_MONITOR_LAMP_RUNTIME);
    #END_IF
    }
  }
#END_IF

#IF_DEFINED HAS_VOLUME
  CHANNEL_EVENT[vdvDevice,VOL_MUTE_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE VOL_MUTE_FB         :  RmsAssetParameterSetValue(assetClientKey, 'volume.mute'           , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE VOL_MUTE_FB         :  RmsAssetParameterSetValue(assetClientKey, 'volume.mute'           , 'false' );
        }
      }
    }
  }

  LEVEL_EVENT[vdvDevice,VOL_LVL]
  {
    KeySetValue ('volume.level', ITOA(LEVEL.VALUE))

    IF(IsRmsReady())
      RmsAssetParameterSetValue(assetClientKey, 'volume.level', ITOA(LEVEL.VALUE) );
  }
#END_IF

#IF_DEFINED HAS_GAIN
  CHANNEL_EVENT[vdvDevice,GAIN_MUTE_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE GAIN_MUTE_FB        :   RmsAssetParameterSetValue(assetClientKey, 'gain.mute'             , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE GAIN_MUTE_FB        :  RmsAssetParameterSetValue(assetClientKey, 'gain.mute'             , 'false' );
        }
      }
    }
  }

  LEVEL_EVENT[vdvDevice,GAIN_LVL]
  {
    KeySetValue ('gain.level', ITOA(LEVEL.VALUE))

    IF(IsRmsReady())
      RmsAssetParameterSetValue(assetClientKey, 'gain.level'  , ITOA(LEVEL.VALUE) );
  }
#END_IF

#IF_DEFINED HAS_PREAMP
  LEVEL_EVENT[vdvDevice,BALANCE_LVL]
  LEVEL_EVENT[vdvDevice,BASS_LVL   ]
  LEVEL_EVENT[vdvDevice,TREBLE_LVL ]
  {
    IF(IsRmsReady())
    {
      SWITCH(LEVEL.INPUT.LEVEL)
      {
        CASE BALANCE_LVL    : RmsAssetParameterSetValue(assetClientKey, 'preamp.balance'      , ITOA(LEVEL.VALUE) );
        CASE BASS_LVL       : RmsAssetParameterSetValue(assetClientKey, 'preamp.treble'       , ITOA(LEVEL.VALUE) );
        CASE TREBLE_LVL     : RmsAssetParameterSetValue(assetClientKey, 'preamp.bass'         , ITOA(LEVEL.VALUE) );
      }
    }

    SWITCH(LEVEL.INPUT.LEVEL)
    {
      CASE BALANCE_LVL    : KeySetValue ('preamp.balance', ITOA(LEVEL.VALUE))
      CASE BASS_LVL       : KeySetValue ('preamp.treble' , ITOA(LEVEL.VALUE))
      CASE TREBLE_LVL     : KeySetValue ('preamp.bass'   , ITOA(LEVEL.VALUE))
    }
  }

  CHANNEL_EVENT[vdvDevice,LOUDNESS_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE LOUDNESS_FB         :    RmsAssetParameterSetValue(assetClientKey, 'preamp.loudness'       , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE LOUDNESS_FB         :  RmsAssetParameterSetValue(assetClientKey, 'preamp.loudness'       , 'false' );
        }
      }
    }
  }
#END_IF

#IF_DEFINED HAS_DIALER
  CHANNEL_EVENT[vdvDevice,DIAL_OFF_HOOK_FB]
  CHANNEL_EVENT[vdvDevice,DIAL_AUTO_ANSWER_FB]
  CHANNEL_EVENT[vdvDevice,DIAL_AUDIBLE_RING_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE DIAL_OFF_HOOK_FB     : RmsAssetParameterSetValue(assetClientKey, 'dialer.hook'           , 'true' );
          CASE DIAL_AUTO_ANSWER_FB  : RmsAssetParameterSetValue(assetClientKey, 'dialer.auto.answer'    , 'true' );
          CASE DIAL_AUDIBLE_RING_FB : RmsAssetParameterSetValue(assetClientKey, 'dialer.ring.audible'   , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE DIAL_OFF_HOOK_FB     : RmsAssetParameterSetValue(assetClientKey, 'dialer.hook'           , 'false' );
          CASE DIAL_AUTO_ANSWER_FB  : RmsAssetParameterSetValue(assetClientKey, 'dialer.auto.answer'    , 'false' );
          CASE DIAL_AUDIBLE_RING_FB : RmsAssetParameterSetValue(assetClientKey, 'dialer.ring.audible'   , 'false' );
        }
      }
    }
  }
#END_IF

#IF_DEFINED HAS_PHONEBOOK     // See command events
#END_IF

#IF_DEFINED HAS_CONFERENCER
  CHANNEL_EVENT[vdvDevice,ACONF_PRIVACY_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE ACONF_PRIVACY_FB    : RmsAssetParameterSetValue(assetClientKey, 'conferencer.privacy'   , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE ACONF_PRIVACY_FB    : RmsAssetParameterSetValue(assetClientKey, 'conferencer.privacy'   , 'false' );
        }
      }
    }
  }
#END_IF

#IF_DEFINED HAS_CAMERA_PRESET // See command events
#END_IF

#IF_DEFINED HAS_CAMERA_PAN_TILT
  LEVEL_EVENT[vdvDevice,PAN_LVL   ]
  LEVEL_EVENT[vdvDevice,TILT_LVL  ]
  LEVEL_EVENT[vdvDevice,PAN_SPEED_LVL ]
  LEVEL_EVENT[vdvDevice,TILT_SPEED_LVL]
  {
    IF(IsRmsReady())
    {
      SWITCH(LEVEL.INPUT.LEVEL)
      {
        CASE PAN_LVL        : RmsAssetParameterSetValue(assetClientKey, 'camera.pan.position' , ITOA(LEVEL.VALUE) );
        CASE TILT_LVL       : RmsAssetParameterSetValue(assetClientKey, 'camera.tilt.position', ITOA(LEVEL.VALUE) );
        CASE PAN_SPEED_LVL  : RmsAssetParameterSetValue(assetClientKey, 'camera.pan.speed'    , ITOA(LEVEL.VALUE) );
        CASE TILT_SPEED_LVL : RmsAssetParameterSetValue(assetClientKey, 'camera.tilt.speed'   , ITOA(LEVEL.VALUE) );
      }
    }

    SWITCH(LEVEL.INPUT.LEVEL)
    {
      CASE PAN_LVL        : KeySetValue ('camera.pan.position' , ITOA(LEVEL.VALUE));
      CASE TILT_LVL       : KeySetValue ('camera.tilt.position', ITOA(LEVEL.VALUE));
      CASE PAN_SPEED_LVL  : KeySetValue ('camera.pan.speed'    , ITOA(LEVEL.VALUE));
      CASE TILT_SPEED_LVL : KeySetValue ('camera.tilt.speed'   , ITOA(LEVEL.VALUE));
    }
  }
#END_IF

#IF_DEFINED HAS_CAMERA_LENS
  LEVEL_EVENT[vdvDevice,ZOOM_LVL   ]
  LEVEL_EVENT[vdvDevice,FOCUS_LVL  ]
  LEVEL_EVENT[vdvDevice,IRIS_LVL   ]
  LEVEL_EVENT[vdvDevice,ZOOM_SPEED_LVL ]
  LEVEL_EVENT[vdvDevice,FOCUS_SPEED_LVL]
  LEVEL_EVENT[vdvDevice,IRIS_SPEED_LVL ]
  {
    IF(IsRmsReady())
    {
      SWITCH(LEVEL.INPUT.LEVEL)
      {
        CASE ZOOM_LVL        : RmsAssetParameterSetValue(assetClientKey, 'camera.zoom.level' , ITOA(LEVEL.VALUE) );
        CASE FOCUS_LVL       : RmsAssetParameterSetValue(assetClientKey, 'camera.focus.level', ITOA(LEVEL.VALUE) );
        CASE IRIS_LVL        : RmsAssetParameterSetValue(assetClientKey, 'camera.iris.level' , ITOA(LEVEL.VALUE) );
        CASE ZOOM_SPEED_LVL  : RmsAssetParameterSetValue(assetClientKey, 'camera.zoom.speed' , ITOA(LEVEL.VALUE) );
        CASE FOCUS_SPEED_LVL : RmsAssetParameterSetValue(assetClientKey, 'camera.focus.speed', ITOA(LEVEL.VALUE) );
        CASE IRIS_SPEED_LVL  : RmsAssetParameterSetValue(assetClientKey, 'camera.iris.speed' , ITOA(LEVEL.VALUE) );
      }
    }

    SWITCH(LEVEL.INPUT.LEVEL)
    {
      CASE ZOOM_LVL        : KeySetValue ('camera.zoom.level' , ITOA(LEVEL.VALUE));
      CASE FOCUS_LVL       : KeySetValue ('camera.focus.level', ITOA(LEVEL.VALUE));
      CASE IRIS_LVL        : KeySetValue ('camera.iris.level' , ITOA(LEVEL.VALUE));
      CASE ZOOM_SPEED_LVL  : KeySetValue ('camera.zoom.speed' , ITOA(LEVEL.VALUE));
      CASE FOCUS_SPEED_LVL : KeySetValue ('camera.focus.speed', ITOA(LEVEL.VALUE));
      CASE IRIS_SPEED_LVL  : KeySetValue ('camera.iris.speed' , ITOA(LEVEL.VALUE));
    }
  }

  CHANNEL_EVENT[vdvDevice,AUTO_FOCUS_FB]
  CHANNEL_EVENT[vdvDevice,AUTO_IRIS_FB ]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE AUTO_FOCUS_FB       : RmsAssetParameterSetValue(assetClientKey, 'camera.focus.auto'     , 'true' );
          CASE AUTO_IRIS_FB        : RmsAssetParameterSetValue(assetClientKey, 'camera.iris.auto'      , 'true' );
        }
      }
    }
    OFF :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE AUTO_FOCUS_FB       : RmsAssetParameterSetValue(assetClientKey, 'camera.focus.auto'     , 'false' );
          CASE AUTO_IRIS_FB        : RmsAssetParameterSetValue(assetClientKey, 'camera.iris.auto'      , 'false' );
        }
      }
    }
  }
#END_IF

#IF_DEFINED HAS_SOURCE_SELECT           // See command events
#END_IF

#IF_DEFINED HAS_LAMP                    // See command events
#END_IF

#IF_DEFINED HAS_DISPLAY_ASPECT_RATIO    // See command events
#END_IF

#IF_DEFINED HAS_TUNER                   // See command events
#END_IF

#IF_DEFINED HAS_DISC_TRANSPORT
  CHANNEL_EVENT[vdvDevice,PLAY_FB    ]
  CHANNEL_EVENT[vdvDevice,STOP_FB    ]
  CHANNEL_EVENT[vdvDevice,PAUSE_FB   ]
  CHANNEL_EVENT[vdvDevice,SFWD_FB    ]
  CHANNEL_EVENT[vdvDevice,SREV_FB    ]
  CHANNEL_EVENT[vdvDevice,RECORD_FB  ]
  CHANNEL_EVENT[vdvDevice,SLOW_FWD_FB]
  CHANNEL_EVENT[vdvDevice,SLOW_REV_FB]
  {
    ON :
    {
      IF(IsRmsReady())
      {
        SWITCH(CHANNEL.CHANNEL)
        {
          CASE PLAY_FB     : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Play'    )
          CASE STOP_FB     : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Stop'    )
          CASE PAUSE_FB    : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Pause'   )
          CASE SFWD_FB     : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Next'    )
          CASE SREV_FB     : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Previous')
          CASE RECORD_FB   : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Record'  )
          CASE SLOW_FWD_FB : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Slow Fwd')
          CASE SLOW_REV_FB : RmsAssetParameterSetValue(assetClientKey, 'transport.state', 'Slow Rev')
        }
      }

    #IF_DEFINED TL_MONITOR_TRANSPORT_RUNTIME
      IF(CHANNEL.CHANNEL = PLAY_FB)
        RMSTimerStart (TL_MONITOR_TRANSPORT_RUNTIME);
      ELSE
        RMSTimerStop  (TL_MONITOR_TRANSPORT_RUNTIME);
    #END_IF
    }
  }
#END_IF

#IF_DEFINED HAS_SWITCHER              // See command events
#END_IF

#IF_DEFINED HAS_LIGHT                 // See command events
#END_IF


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
#END_IF
