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
PROGRAM_NAME='RmsSchedulingApi'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file is provided to implement convenience *)
(*  methods and constants to aid in developing NetLinux    *)
(*  code to communicate with RMS scheduling API's.         *)
(*                                                         *)
(***********************************************************)

// This is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_SCHEDULING_API__
#DEFINE __RMS_SCHEDULING_API__

// Include RmsApi if it is not already included
#INCLUDE 'RmsApi';

(***********************************************************)
(*                INCLUDE DEFINITIONS GO BELOW             *)
(***********************************************************)

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT

//
// Event Responses
//
RMS_EVENT_SCHEDULING_BOOKING                              = 'SCHEDULING.BOOKING';
RMS_EVENT_SCHEDULING_BOOKINGS_COUNT                       = 'SCHEDULING.BOOKINGS.COUNT';
RMS_EVENT_SCHEDULING_BOOKINGS_RECORD                      = 'SCHEDULING.BOOKINGS.RECORD';
RMS_EVENT_SCHEDULING_BOOKINGS_SUMMARIES_DAILY_COUNT       = 'SCHEDULING.BOOKINGS.SUMMARIES.DAILY.COUNT';
RMS_EVENT_SCHEDULING_BOOKINGS_SUMMARIES_DAILY_RECORD      = 'SCHEDULING.BOOKINGS.SUMMARIES.DAILY.RECORD';
RMS_EVENT_SCHEDULING_BOOKINGS_SUMMARY_DAILY               = 'SCHEDULING.BOOKINGS.SUMMARY.DAILY';
RMS_EVENT_SCHEDULING_BOOKING_ACTIVE                       = 'SCHEDULING.BOOKING.ACTIVE';
RMS_EVENT_SCHEDULING_BOOKING_NEXT_ACTIVE                  = 'SCHEDULING.BOOKING.NEXT.ACTIVE';

//
// Non-query commands
//
RMS_COMMAND_SCHEDULING_BOOKING_CREATE                     = 'SCHEDULING.BOOKING.CREATE';
RMS_COMMAND_SCHEDULING_BOOKING_END                        = 'SCHEDULING.BOOKING.END';
RMS_COMMAND_SCHEDULING_BOOKING_EXTEND                     = 'SCHEDULING.BOOKING.EXTEND';

//
// Query Commands
//
RMS_COMMAND_SCHEDULING_BOOKINGS_REQUEST                   = '?SCHEDULING.BOOKINGS';
RMS_COMMAND_SCHEDULING_BOOKINGS_SUMMARIES_DAILY_REQUEST   = '?SCHEDULING.BOOKINGS.SUMMARIES.DAILY';
RMS_COMMAND_SCHEDULING_BOOKINGS_SUMMARY_DAILY_REQUEST     = '?SCHEDULING.BOOKINGS.SUMMARY.DAILY';
RMS_COMMAND_SCHEDULING_BOOKING_ACTIVE_REQUEST             = '?SCHEDULING.BOOKING.ACTIVE';
RMS_COMMAND_SCHEDULING_BOOKING_NEXT_ACTIVE_REQUEST        = '?SCHEDULING.BOOKING.NEXT.ACTIVE';
RMS_COMMAND_SCHEDULING_BOOKING_REQUEST                    = '?SCHEDULING.BOOKING';

//
// RMS Scheduling API Custom Event Addresses
//
// Note: To prevent even address number collisions,
// all event addresses are all in RmsApi.axi


//
// RMS Scheduling API Custom Event IDs
//
// Note, Events in this group are the server initiated, i.e. not
// the response to a NetLinx command
RMS_EVENT_SCHEDULING_BOOKING_STARTED                      = 1;
RMS_EVENT_SCHEDULING_BOOKING_ENDED                        = 2;
RMS_EVENT_SCHEDULING_BOOKING_EXTENDED                     = 3;
RMS_EVENT_SCHEDULING_BOOKING_CANCELED                     = 4;
RMS_EVENT_SCHEDULING_BOOKING_CREATED                      = 5;
RMS_EVENT_SCHEDULING_BOOKING_UPDATED                      = 6;
RMS_EVENT_SCHEDULING_BOOKING_MONTHLY_SUMMARY_UPDATED      = 7;
RMS_EVENT_SCHEDULING_BOOKING_ACTIVE_UPDATED               = 8;
RMS_EVENT_SCHEDULING_BOOKING_NEXT_ACTIVE_UPDATED          = 9;
RMS_EVENT_SCHEDULING_BOOKING_DAILY_COUNT                  = 10;

// This group of custom events are the result of a response to
// a NetLinx command
RMS_EVENT_SCHEDULING_BOOKING_ACTIVE_RESPONSE              = 30;
RMS_EVENT_SCHEDULING_BOOKING_CANCELED_RESPONSE            = 31;
RMS_EVENT_SCHEDULING_BOOKING_CREATED_RESPONSE             = 32;
RMS_EVENT_SCHEDULING_BOOKING_ENDED_RESPONSE               = 33;
RMS_EVENT_SCHEDULING_BOOKING_EXTENDED_RESPONSE            = 34;
RMS_EVENT_SCHEDULING_BOOKING_INFORMATION_RESPONSE         = 35;
RMS_EVENT_SCHEDULING_BOOKING_NEXT_ACTIVE_RESPONSE         = 36;
RMS_EVENT_SCHEDULING_BOOKING_RECORD_RESPONSE              = 37;
RMS_EVENT_SCHEDULING_BOOKING_SUMMARIES_DAILY_RESPONSE     = 38;
RMS_EVENT_SCHEDULING_BOOKING_SUMMARY_DAILY_RESPONSE       = 39;

//
// These are the codes which indicate the activity
// which created an event response.
//
RMS_RESPONSE_TYPE_CREATE    = 0;
RMS_RESPONSE_TYPE_EXTEND    = 1;
RMS_RESPONSE_TYPE_END       = 2;

// Maximum parameter length for parsing/packing functions
#IF_NOT_DEFINED RMS_MAX_PARAM_LEN
RMS_MAX_PARAM_LEN           = 250
#END_IF

// Maximum CHAR array size LDATE/TIME strings
#IF_NOT_DEFINED RMS_MAX_DATE_TIME_LEN
RMS_MAX_DATE_TIME_LEN       = 10
#END_IF

(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*                                                         *)
(* RMS Event Booking Response Data Structure               *)
(*                                                         *)
(* This structure represents two types of data:            *)
(*                                                         *)
(* 1. A response to a NetLinx command                      *)
(* 2. Information initiated by the server                  *)
(*                                                         *)
(* Note, in different events some fields may not be        *)
(* meaningful. As an example, for adhoc event creation,    *)
(* attendees will not be populated.                        *)
(*                                                         *)
(***********************************************************)
STRUCTURE RmsEventBookingResponse
{

    CHAR bookingId[RMS_MAX_PARAM_LEN];
    LONG location;
    CHAR isPrivateEvent;
    CHAR startDate[RMS_MAX_DATE_TIME_LEN];
    CHAR startTime[RMS_MAX_DATE_TIME_LEN];
    CHAR endDate[RMS_MAX_DATE_TIME_LEN];
    CHAR endTime[RMS_MAX_DATE_TIME_LEN];
    CHAR subject[RMS_MAX_PARAM_LEN];
    CHAR details[RMS_MAX_PARAM_LEN];
    CHAR clientGatewayUid[RMS_MAX_PARAM_LEN];
    CHAR isAllDayEvent;
    CHAR organizer[RMS_MAX_PARAM_LEN];
    LONG elapsedMinutes;													// Only used for active booking events
    LONG minutesUntilStart;												// Only used for next active booking events
    LONG remainingMinutes;												// Only used for active booking events
    CHAR onBehalfOf[RMS_MAX_PARAM_LEN];
    CHAR attendees[RMS_MAX_PARAM_LEN];						// Not used in some contexts such as adhoc creation
    CHAR isSuccessful;
    CHAR failureDescription[RMS_MAX_PARAM_LEN];		// Not used if result is from a successful event
    LONG totalAttendeeCount;											// In some cases attendee names may be truncated
    																							// due to the length, totalAttendeeCount is helpful 
    																							// to indicate the total number of attendees
}

(***********************************************************)
(*                                                         *)
(* RMS Event Booking Monthly Summary Data Structure        *)
(*                                                         *)
(* This structure represents a RMS Booking Monthly Summary *)
(*                                                         *)
(* Note: Daily counts associated with a monthly summary    *)
(* are respresended as a RmsEventBookingDailyCount         *)
(* structure, only a total of the number of entries is     *)
(* provided by dailyCountsTotal                            *)
(*                                                         *)
(***********************************************************)
STRUCTURE RmsEventBookingMonthlySummary
{
    LONG location;
    CHAR startDate[RMS_MAX_DATE_TIME_LEN];
    CHAR startTime[RMS_MAX_DATE_TIME_LEN];
    CHAR endDate[RMS_MAX_DATE_TIME_LEN];
    CHAR endTime[RMS_MAX_DATE_TIME_LEN];
    INTEGER dailyCountsTotal;
}

(***********************************************************)
(*                                                         *)
(* RMS Event Booking Daily Count Data Structure            *)
(*                                                         *)
(* This structure represents a RMS Booking Daily Count     *)
(*                                                         *)
(* Note: recordCount and recordNumber are only meaningful  *)
(* in the context of a monthly summary. For a monthly      *)
(* summary, these items provide information about the      *)
(* total number of records in the monthly summary and the  *)
(* record number of this specific entry.                   *)
(*                                                         *)
(***********************************************************)
STRUCTURE RmsEventBookingDailyCount
{
    LONG location;
    INTEGER dayOfMonth;
    INTEGER bookingCount;
    INTEGER recordCount;
    INTEGER recordNumber;
 }

// include RMS Scheduling API
#INCLUDE 'RmsSchedulingEventListener';

(***********************************************************)
(* Name:  RmsBookingsRequest                               *)
(* Args:  LDATE startDate - NetLinux format date           *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Query the event booking records for a location   *)
(*        and specific date.                               *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingsRequest(CHAR startDate[], LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  if(startDate == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsBookingsRequest> :: missing booking request start date';
    RETURN FALSE;
  }

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKINGS_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,startDate);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingRequest                                *)
(* Args:  CHAR bookingId[] - Booking ID                    *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Query a single event booking record by booking   *)
(*        ID.                                              *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingRequest(CHAR bookingId[], LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  if(bookingId == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsBookingRequest> :: missing booking request booking ID';
    RETURN FALSE;
  }

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,bookingId);
  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(************************************************************)
(* Name:  RmsBookingsSummariesDailyRequest                  *)
(* Args:  SINTEGER month - Month of the year, 1 - 12        *)
(*        LONG locationId - location ID                     *)
(*                                                          *)
(* Desc:  Query monthly booking summary for specified month *)
(*        of the year and location                          *)
(*                                                          *)
(*        If location ID is less than 1, the default        *)
(*        location will be used.                            *)
(*                                                          *)
(* Rtrn:  1 if call was successful                          *)
(*        0 if call was unsuccessful                        *)
(************************************************************)
DEFINE_FUNCTION CHAR RmsBookingsSummariesDailyRequest(SINTEGER month, LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  if(month < 1 || month > 12)
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsBookingsSummariesDailyRequest> :: month of the year should be in the range of 1 - 12';
    RETURN FALSE;
  }

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKINGS_SUMMARIES_DAILY_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(month));
  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingsSummaryDailyRequest                   *)
(* Args:  LDATE summaryDate - NetLinux LDATE format date   *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Query a single daily event summary record by     *)
(*        date and location                                *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingsSummaryDailyRequest(CHAR summaryDate[], LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  if(summaryDate == '')
  {
    SEND_STRING 0, '>>>> RMS API ERROR <RmsBookingsSummaryDailyRequest> :: missing booking request summary date';
    RETURN FALSE;
  }

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKINGS_SUMMARY_DAILY_REQUEST);
  rmsCommand = RmsPackCmdParam(rmsCommand,summaryDate);
  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingActiveRequest                          *)
(* Args:  LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Query the current active booking for a given     *)
(*        location                                         *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingActiveRequest(LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_ACTIVE_REQUEST);
  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingNextActiveRequest                      *)
(* Args:  LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Query the next active booking for a given        *)
(*        location                                         *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingNextActiveRequest(LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_NEXT_ACTIVE_REQUEST);
  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingCreate                                 *)
(* Args:  LDATE startDate - NetLinux LDATE format date     *)
(*        TIME startTime - NetLinx TIME format time        *)
(*        INTEGER durationMinutes - Length of the event    *)
(*        CHAR subject[] - Subject of the event            *)
(*        CHAR messageBody[] - Event information           *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Create booking event                             *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingCreate(CHAR startDate[],
                                        CHAR startTime[],
                                        INTEGER durationMinutes,
                                        CHAR subject[],
                                        CHAR messageBody[],
                                        LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_CREATE);
  rmsCommand = RmsPackCmdParam(rmsCommand,startDate);
  rmsCommand = RmsPackCmdParam(rmsCommand,startTime);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(durationMinutes));
  rmsCommand = RmsPackCmdParam(rmsCommand,subject);
  rmsCommand = RmsPackCmdParam(rmsCommand,messageBody);

  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingExtend                                 *)
(* Args:  CHAR bookingId[] - Booking ID                    *)
(*        LONG extendDurationMinutes - Minutes to extend   *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Extend a booking event                           *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingExtend(CHAR bookingId[],
                                        LONG extendDurationMinutes,
                                        LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_EXTEND);
  rmsCommand = RmsPackCmdParam(rmsCommand,bookingId);
  rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(extendDurationMinutes));

  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

(***********************************************************)
(* Name:  RmsBookingEnd                                    *)
(* Args:  CHAR bookingId[] - Booking ID                    *)
(*        LONG locationId - location ID                    *)
(*                                                         *)
(* Desc:  Extend a booking event                           *)
(*                                                         *)
(*        If location ID is less than 1, the default       *)
(*        location will be used.                           *)
(*                                                         *)
(* Rtrn:  1 if call was successful                         *)
(*        0 if call was unsuccessful                       *)
(***********************************************************)
DEFINE_FUNCTION CHAR RmsBookingEnd(CHAR bookingId[],
                                        LONG locationId)
{
  STACK_VAR CHAR rmsCommand[RMS_MAX_CMD_LEN];

  // create send command
  rmsCommand = RmsPackCmdHeader(RMS_COMMAND_SCHEDULING_BOOKING_END);
  rmsCommand = RmsPackCmdParam(rmsCommand,bookingId);

  if(locationId > 0)
  {
    rmsCommand = RmsPackCmdParam(rmsCommand,ITOA(locationId));
  }

  SEND_COMMAND vdvRMS, rmsCommand;

  RETURN TRUE;
}

#END_IF // __RMS_SCHEDULING_API__
