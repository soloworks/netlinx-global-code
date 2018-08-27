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
PROGRAM_NAME='RmsSchedulingEventListener'

(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file is used to listen to the RMS client  *)
(*  virtual device events and invoke callback methods when *)
(*  a RMS scheduling event occurs.                         *)
(*                                                         *)
(*  Each event callback method can be exposed to the       *)
(*  consuming program by including the respective #DEFINE  *)
(*  compiler directive.  Please see the list of available  *)
(*  event directives below.  If a #DEFINE event directive  *)
(*  in enabled, then the implementation callback method    *)
(*  must exists in the consuming code base, else the       *)
(* program node will fail to compile.                      *)
(***********************************************************)

// This is a compiler guard to ensure that only one copy
// of this include file is incorporated in the final compilation
#IF_NOT_DEFINED __RMS_SCHEDULING_EVENT_LISTENER__
#DEFINE __RMS_SCHEDULING_EVENT_LISTENER__


(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 08/07/2012                      *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)

/*
-------------------------------------------------------------------------------
Please note all the RMS event callback function signatures below associated
with their respective compiler directives.  If you wish to implement any of
these event in your code, then make sure to include this file, provide the
'vdvRMS' visual device interface to the RMS client, declare the desired
compiler directives for each event you wish to subscribe to, and copy the
event callback method to your implementation code.
-------------------------------------------------------------------------------

(***********************************************************)
(* Name:  RmsEventSchedulingBookingsRecordResponse         *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* INTEGER recordIndex - The index position of this record *)
(*                                                         *)
(* INTEGER recordCount - Total record count                *)
(*                                                         *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query for booking events.              *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_BOOKINGS_RECORD_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingBookingsRecordResponse(CHAR isDefaultLocation, 
																													INTEGER recordIndex, 
																													INTEGER recordCount, 
																													CHAR bookingId[], 
																													RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingBookingResponse                *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query for information about a specific *)
(* booking event ID                                        *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_BOOKING_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingBookingResponse(CHAR isDefaultLocation, 
																									CHAR bookingId[], 
																									RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingActiveResponse                 *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* INTEGER recordIndex - The index position of this record *)
(*                                                         *)
(* INTEGER recordCount - Total record count                *)
(*                                                         *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query for the current active booking   *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_ACTIVE_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingActiveResponse(CHAR isDefaultLocation, 
																									INTEGER recordIndex, 
																									INTEGER recordCount, 
																									CHAR bookingId[], 
																									RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingNextActiveResponse             *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* INTEGER recordIndex - The index position of this record *)
(*                                                         *)
(* INTEGER recordCount - Total record count                *)
(*                                                         *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query for the next active booking      *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_NEXT_ACTIVE_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingNextActiveResponse(CHAR isDefaultLocation, 
																											INTEGER recordIndex, 
																											INTEGER recordCount, 
																											CHAR bookingId[], 
																											RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name: RmsEventSchedulingSummariesDailyResponse          *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if th location   *)
(* in the response is the default location                 *)
(*                                                         *)
(* RmsEventBookingDailyCount dailyCount - A                *)
(* structure with information about a specific date        *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query summaries daily count            *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_BOOKING_SUMMARIES_DAILY_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingSummariesDailyResponse(CHAR isDefaultLocation,
																													RmsEventBookingDailyCount dailyCount)
{
}

(***********************************************************)
(* Name: RmsEventSchedulingSummaryDailyResponse            *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if th location   *)
(* in the response is the default location                 *)
(*                                                         *)
(* RmsEventBookingDailyCount dailyCount - A                *)
(* structure with information about a specific date        *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a query summary daily                    *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_BOOKING_SUMMARY_DAILY_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingSummaryDailyResponse(CHAR isDefaultLocation,
																												RmsEventBookingDailyCount dailyCount)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingCreateResponse                 *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if th location   *)
(* in the response is the default location                 *)
(*                                                         *)
(* CHAR responseText[] - Booking ID if successful else     *)
(* some error information.                                 *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a booking creation request               *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_CREATE_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingCreateResponse(CHAR isDefaultLocation, 
																									CHAR responseText[], 
																									RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingExtendResponse                 *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* CHAR responseText[] - Booking ID if successful else     *)
(* some error information.                                 *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a extending a booking event              *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_EXTEND_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingExtendResponse(CHAR isDefaultLocation, 
																									CHAR responseText[], 
																									RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingEndResponse                    *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* CHAR responseText[] - Booking ID if successful else     *)
(* some error information.                                 *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* in response to a ending a booking event                 *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_END_RESPONSE_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingEndResponse(CHAR isDefaultLocation, 
																								CHAR responseText[], 
																								RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingActiveUpdated                  *)
(* Args:                                                   *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates there was an update to an active     *)
(* booking event                                           *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_ACTIVE_UPDATED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingActiveUpdated(CHAR bookingId[], 
																									RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingNextActiveUpdated              *)
(* Args:                                                   *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates there was an update to a next active *)
(* booking event                                           *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_NEXT_ACTIVE_UPDATED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingNextActiveUpdated(CHAR bookingId[], 
																											RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingEventEnded                     *)
(* Args:                                                   *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates a booking event has ended            *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_EVENT_ENDED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingEventEnded(CHAR bookingId[], 
																							RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingEventStarted                   *)
(* Args:                                                   *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates a booking event has started          *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_EVENT_STARTED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingEventStarted(CHAR bookingId[], 
																								RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingEventUpdated                   *)
(* Args:                                                   *)
(* CHAR bookingId[] - The booking ID string                *)
(*                                                         *)
(* RmsEventBookingResponse eventBookingResponse - A        *)
(* structure with additional booking information           *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates a booking event has updated          *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_EVENT_UPDATED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingEventUpdated(CHAR bookingId[], 
																								RmsEventBookingResponse eventBookingResponse)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingMonthlySummaryUpdated          *)
(* Args:                                                   *)
(* INTEGER dailyCountsTotal - The total number of daily    *)
(* count entries in the monthly summary                    *)
(*                                                         *)
(* RmsEventBookingMonthlySummary monthlySummary - A        *)
(* structure general summary information                   *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS indicates the monthly summary has updated      *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_MONTHLY_SUMMARY_UPDATED_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingMonthlySummaryUpdated(INTEGER dailyCountsTotal,
																													RmsEventBookingMonthlySummary monthlySummary)
{
}

(***********************************************************)
(* Name:  RmsEventSchedulingDailyCount                     *)
(* Args:                                                   *)
(* CHAR isDefaultLocation - boolean, TRUE if the location  *)
(* in the response is the default location                 *)
(*                                                         *)
(* RmsEventBookingDailyCount dailyCount - A                *)
(* structure with information about a specific date        *)
(*                                                         *)
(* Desc:  Implementations of this method will be called    *)
(* when RMS provides daily count information such as in    *)
(* when there is a monthly summary update                  *)
(*                                                         *)
(***********************************************************)
// #DEFINE INCLUDE_SCHEDULING_DAILY_COUNT_CALLBACK
DEFINE_FUNCTION RmsEventSchedulingDailyCount(CHAR isDefaultLocation,
																							RmsEventBookingDailyCount dailyCount)
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

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKINGS RECORD QUERY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_BOOKINGS_RECORD_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_RECORD_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR INTEGER recordCount;
  STACK_VAR INTEGER recordIndex;
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
  
  // value2 - booking index
  recordIndex = TYPE_CAST(custom.value2);
  
    // value3 - booking record count
  recordCount = TYPE_CAST(custom.value3);
  
  // The text member of the custom event contains
  // the booking ID
  bookingId = custom.text;
    
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventSchedulingBookingsRecordResponse(isDefaultLocation, recordIndex, recordCount, bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING QUERY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_BOOKING_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_INFORMATION_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
    
  // The text member of the custom event contains
  // the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventSchedulingBookingResponse(isDefaultLocation, bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING ACTIVE RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_ACTIVE_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_ACTIVE_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR INTEGER recordCount;
  STACK_VAR INTEGER recordIndex;
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
    
  // value2 - current record index
  recordIndex = TYPE_CAST(custom.value2);
  
  // value3 - the total number of records
  recordCount = TYPE_CAST(custom.value3);
  
  // The text member of the custom event contains
  // the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventSchedulingActiveResponse(isDefaultLocation, recordIndex, recordCount, bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING NEXT ACTIVE RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_NEXT_ACTIVE_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_NEXT_ACTIVE_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR INTEGER recordCount;
  STACK_VAR INTEGER recordIndex;
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
    
  // value2 - current record index
  recordIndex = TYPE_CAST(custom.value2);
  
  // value3 - the total number of records
  recordCount = TYPE_CAST(custom.value3);
    
  // The text member of the custom event contains
  // the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }

  // invoke the callback method
  RmsEventSchedulingNextActiveResponse(isDefaultLocation, recordIndex, recordCount, bookingId, eventBookingResponse);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING NEXT ACTIVE RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_CREATE_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_CREATED_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR responseText[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
     
  // The text member of the custom event contains
  // the booking ID if successful, else an error
  // message indicating the failure
  responseText = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingCreateResponse(isDefaultLocation, responseText, eventBookingResponse);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING EXTEND RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_EXTEND_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_EXTENDED_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR responseText[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
    
  // The text member of the custom event contains
  // the booking ID if successful, else an error
  // message indicating the failure
  responseText = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingExtendResponse(isDefaultLocation, responseText, eventBookingResponse);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING END RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_END_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_ENDED_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR CHAR responseText[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
    
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
    
  // The text member of the custom event contains
  // the booking ID if successful, else an error
  // message indicating the failure
  responseText = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingEndResponse(isDefaultLocation, responseText, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] RMS EVENT SCHEDULING BOOKING SUMMARIES DAILY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_BOOKING_SUMMARIES_DAILY_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_SUMMARIES_DAILY_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR RmsEventBookingDailyCount dailyCount;
  
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
           
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(dailyCount, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingSummariesDailyResponse(isDefaultLocation, dailyCount);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] RMS EVENT SCHEDULING BOOKING SUMMARY DAILY RESPONSE
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_BOOKING_SUMMARY_DAILY_RESPONSE_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_SUMMARY_DAILY_RESPONSE]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR RmsEventBookingDailyCount dailyCount;
  
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);
           
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(dailyCount, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingSummaryDailyResponse(isDefaultLocation, dailyCount);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING ACTIVE EVENT UPDATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_ACTIVE_UPDATED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_ACTIVE_UPDATED]
{
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
       
  // The text member of the custom event contains the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingActiveUpdated(bookingId, eventBookingResponse);
}
#END_IF


// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING NEXT ACTIVE EVENT UPDATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_NEXT_ACTIVE_UPDATED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_NEXT_ACTIVE_UPDATED]
{
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
       
  // The text member of the custom event contains the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingNextActiveUpdated(bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING EVENT ENDED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_EVENT_ENDED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_ENDED]
{
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
       
  // The text member of the custom event contains the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingEventEnded(bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING EVENT STARTED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_EVENT_STARTED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_STARTED]
{
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
       
  // The text member of the custom event contains the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingEventStarted(bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING EVENT UPDATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_EVENT_UPDATED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_UPDATED]
{
  STACK_VAR CHAR bookingId[RMS_MAX_PARAM_LEN];
  STACK_VAR RmsEventBookingResponse eventBookingResponse;
       
  // The text member of the custom event contains the booking ID
  bookingId = custom.text;
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(eventBookingResponse, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingEventUpdated(bookingId, eventBookingResponse);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING MONTHLY SUMMARY UPDATED
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_MONTHLY_SUMMARY_UPDATED_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_MONTHLY_SUMMARY_UPDATED]
{
  STACK_VAR RmsEventBookingMonthlySummary monthlySummary;
  STACK_VAR INTEGER dailyCountsTotal;
         
  // A count of the daily count entries
  dailyCountsTotal = TYPE_CAST(custom.value1);
  
  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(monthlySummary, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingMonthlySummaryUpdated(dailyCountsTotal, monthlySummary);
}
#END_IF

// ***************************************************************************
//
// [CUSTOM EVENT] SCHEDULING BOOKING DAILY COUNT
//
// ***************************************************************************
#IF_DEFINED INCLUDE_SCHEDULING_DAILY_COUNT_CALLBACK
CUSTOM_EVENT[vdvRMS,
             RMS_CUSTOM_EVENT_ADDRESS_EVENT_BOOKING,
             RMS_EVENT_SCHEDULING_BOOKING_DAILY_COUNT]
{
  STACK_VAR CHAR isDefaultLocation;
  STACK_VAR RmsEventBookingDailyCount dailyCount;
  
  // value1 - is default location
  isDefaultLocation = TYPE_CAST(custom.value1);

  // the 'flag' property determines if the 'encode' contains data
  IF(custom.flag == TRUE)
  {
    // decode custom enceded data to event booking structure
    STRING_TO_VARIABLE(dailyCount, custom.encode, 1);
  }
 
  // invoke the callback method
  RmsEventSchedulingDailyCount(isDefaultLocation, dailyCount);
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

#END_IF // __RMS_SCHEDULING_EVENT_LISTENER__
