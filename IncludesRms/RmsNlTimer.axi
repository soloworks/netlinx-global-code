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
PROGRAM_NAME='RmsNlTimer'


// this is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_TIMER__
#DEFINE __RMS_TIMER__

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

(* Version For Code *)
CHAR __RMS_TIMER_NAME__[]       = 'RMSNlTimer.axi';
CHAR __RMS_TIMER_VERSION__[]    = '4.6.7';

LONG    MonitoringTimeArray[1]  = { 60000 }; // must be set to 1 minute (60000 ms)


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

LONG lTimerMinutes[TL_MAX_COUNT];
CHAR bTimerOverride[TL_MAX_COUNT];


(***********************************************************)
(*           SUBROUTINE DEFINITIONS GO BELOW               *)
(***********************************************************)

(**********************************************************)
(* Function: RMSTimerStart                                *)
(* Purpose:  Start Timer                                  *)
(**********************************************************)
DEFINE_FUNCTION RMSTimerStart(LONG TL)
STACK_VAR
  LONG nIdx
{
  nIdx = TL - TL_OFFSET

  IF((nIdx = 0) || (nIdx > TL_MAX_COUNT))
    RETURN;

  IF(bTimerOverride[nIdx])
    RETURN;

  IF(!TIMELINE_ACTIVE(TL))
    TIMELINE_CREATE(TL, MonitoringTimeArray, 1, TIMELINE_RELATIVE,TIMELINE_REPEAT);
}


(**********************************************************)
(* Function: RMSTimerStop                                 *)
(* Purpose:  Stop  Timer                                  *)
(**********************************************************)
DEFINE_FUNCTION RMSTimerStop (LONG TL)
{
  IF(TIMELINE_ACTIVE(TL))
    TIMELINE_KILL(TL);
}


(**********************************************************)
(* Function: RMSTimerOverride                             *)
(* Purpose:  Override Timer                               *)
(**********************************************************)
DEFINE_FUNCTION RMSTimerOverride(LONG TL)
STACK_VAR
  LONG nIdx
{
  nIdx = TL - TL_OFFSET

  IF((nIdx = 0) || (nIdx > TL_MAX_COUNT))
    RETURN;

  bTimerOverride[nIdx] = 1

  RMSTimerStop(TL)
}


(***********************************************************)
(*                THE EVENTS GOES BELOW                    *)
(***********************************************************)
DEFINE_EVENT

(*******************************************)
(* User defined timelines.                 *)
(*******************************************)
#IF_DEFINED TL_MONITOR_1
  TIMELINE_EVENT[TL_MONITOR_1]
  #IF_DEFINED TL_MONITOR_2  TIMELINE_EVENT[TL_MONITOR_2]  #END_IF
  #IF_DEFINED TL_MONITOR_3  TIMELINE_EVENT[TL_MONITOR_3]  #END_IF
  #IF_DEFINED TL_MONITOR_4  TIMELINE_EVENT[TL_MONITOR_4]  #END_IF
  #IF_DEFINED TL_MONITOR_5  TIMELINE_EVENT[TL_MONITOR_5]  #END_IF
  {
    STACK_VAR LONG nIdx

    nIdx = TIMELINE.ID - TL_OFFSET

    IF(bTimerOverride[nIdx])
    {
      RMSTimerStop(TIMELINE.ID)
    }
    ELSE
    {
      lTimerMinutes[nIdx]++;

    // Note: you must define this in the module.
      RMSTimerCallback(TIMELINE.ID, lTimerMinutes[nIdx]);
    }
  }
#END_IF


(*******************************************)
(* SNAPI timeline for power.               *)
(*******************************************)
#IF_DEFINED TL_MONITOR_POWER_ON
  TIMELINE_EVENT[TL_MONITOR_POWER_ON]
  {
    STACK_VAR LONG nIdx

    nIdx = TIMELINE.ID - TL_OFFSET

    IF(bTimerOverride[nIdx])
    {
      RMSTimerStop(TIMELINE.ID)
    }
    ELSE
    {
      lTimerMinutes[nIdx]++;

    // Note: you must define this in the module.
      RMSTimerCallback(TIMELINE.ID, lTimerMinutes[nIdx]);
    }
  }
#END_IF


(*******************************************)
(* SNAPI timeline for lamp.                *)
(*******************************************)
#IF_DEFINED TL_MONITOR_LAMP_RUNTIME
  TIMELINE_EVENT[TL_MONITOR_LAMP_RUNTIME]
  {
    STACK_VAR LONG nIdx

    nIdx = TIMELINE.ID - TL_OFFSET

    IF(bTimerOverride[nIdx])
    {
      RMSTimerStop(TIMELINE.ID)
    }
    ELSE
    {
      lTimerMinutes[nIdx]++;

    // Note: you must define this in the module.
      RMSTimerCallback(TIMELINE.ID, lTimerMinutes[nIdx]);
    }
  }
#END_IF


(*******************************************)
(* SNAPI timeline for transports.          *)
(*******************************************)
#IF_DEFINED TL_MONITOR_TRANSPORT_RUNTIME
  TIMELINE_EVENT[TL_MONITOR_TRANSPORT_RUNTIME]
  {
    STACK_VAR LONG nIdx

    nIdx = TIMELINE.ID - TL_OFFSET

    IF(bTimerOverride[nIdx])
    {
      RMSTimerStop(TIMELINE.ID)
    }
    ELSE
    {
      lTimerMinutes[nIdx]++;

    // Note: you must define this in the module.
      RMSTimerCallback(TIMELINE.ID, lTimerMinutes[nIdx]);
    }
  }
#END_IF


(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
#END_IF
