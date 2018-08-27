//*********************************************************************
//
//             AMX Resource Management Suite  (4.6.7)
//
//*********************************************************************
/*
 *  Legal Notice :
 *
 *     Copyright, AMX LLC, 2012
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
PROGRAM_NAME='RmsMathUtil'


(***********************************************************)
(*                                                         *)
(*  PURPOSE:                                               *)
(*                                                         *)
(*  This include file provides math related helper         *)
(*  functions. These functions make certain tasks easier   *)
(*  such as the rounding of values and the scaling of      *)
(*  levels.                                                *)
(*                                                         *)
(***********************************************************)


(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)


(***********************************************************)
(* Name:  RmsRoundToSignedLong                             *)
(* Args:  DOUBLE value - value to round.                   *)
(*                                                         *)
(* Desc:  Round the input parameter to the nearest whole   *)
(*        number.  Any value with decimal .5 or greater    *)
(*        will be rounded to the next largest whole        *)
(*        number.  Any value with decimal .5 or less will  *)
(*        rounded to the next smallest whole number.       *)
(*                                                         *)
(* Rtrn:  SLONG : rounded whole number                     *)
(***********************************************************)
DEFINE_FUNCTION SLONG RmsRoundToSignedLong(DOUBLE value)
{
  STACK_VAR DOUBLE remainder 
  STACK_VAR SLONG whole_number 
    
  // casting to INT, decimal will be truncated
  whole_number = TYPE_CAST(value); 
  // find remainder (Note: can't use MOD with Double) 
  remainder = value - whole_number;     

  // if remainder is between -.5 and .5, then...
  IF((remainder > -.5) && (remainder < .5))      
  {
    // round to nearest truncated whole number
    RETURN whole_number;        
  }
  ELSE IF(remainder >= .5)        
  {
    // round up for positive numbers
    RETURN (whole_number + 1);
  }
  ELSE
  {
    // round down for negative numbers
    RETURN (whole_number - 1);
  }
}


(***********************************************************)
(* Name:  RmsRoundToLong                                   *)
(* Args:  DOUBLE value - value to round.                   *)
(*                                                         *)
(* Desc:  Round the input parameter to the nearest whole   *)
(*        number.  Any value with decimal .5 or greater    *)
(*        will be rounded to the next largest whole number.*)
(*                                                         *)
(* Rtrn:  LONG : rounded whole number                      *)
(***********************************************************)
DEFINE_FUNCTION LONG RmsRoundToLong(DOUBLE value)
{
    return TYPE_CAST(RmsRoundToSignedLong(value));
}


(***********************************************************)
(* Name:  RmsRoundToInt                                    *)
(* Args:  DOUBLE value - value to round.                   *)
(*                                                         *)
(* Desc:  Round the input parameter to the nearest whole   *)
(*        number.  Any value with decimal .5 or greater    *)
(*        will be rounded to the next largest whole number.*)
(*                                                         *)
(* Rtrn:  INTEGER : rounded whole number                   *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsRoundToInt(DOUBLE value)
{
  RETURN TYPE_CAST(RmsRoundToSignedLong(value));
}


(***********************************************************)
(* Name:  RmsRoundToSignedInt                              *)
(* Args:  DOUBLE value - value to round.                   *)
(*                                                         *)
(* Desc:  Round the input parameter to the nearest whole   *)
(*        number.  Any value with decimal .5 or greater    *)
(*        will be rounded to the next largest whole        *)
(*        number.  Any value with decimal .5 or less will  *)
(*        rounded to the next smallest whole number.       *)
(*                                                         *)
(* Rtrn:  SINTEGER : rounded whole number                  *)
(***********************************************************)
DEFINE_FUNCTION SINTEGER RmsRoundToSignedInt(DOUBLE value)
{
  RETURN TYPE_CAST(RmsRoundToSignedLong(value));
}


(***********************************************************)
(* Name:  RmsScaleLevelToPercent                           *)
(* Args:  DOUBLE current level value  (value to scale)     *)
(*        SLONG  maximum level value                       *)
(*        SLONG  minimum level value                       *)
(*                                                         *)
(* Desc:  Scales the level value provided to a percentage  *)
(*        number.                                          *)
(*                                                         *)
(* Rtrn:  INTEGER : percentage (whole number)              *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsScaleLevelToPercent(DOUBLE currentLevel, SLONG maxLevel, SLONG minLevel)
{
  STACK_VAR SLONG range;
  STACK_VAR SLONG max;
  STACK_VAR SLONG min;
  
  // sanity check the min and max levels
  max = MAX_VALUE(maxLevel, minLevel);
  min = MIN_VALUE(maxLevel, minLevel);

  // determine range
  range = max - min;

  // prevent divide by zero condition 
  IF(range == 0)
  {
    RETURN 0;
  }

  // is/of = %/100 :: % = (is/of) * 100
  // shift current level value based on min scale range
  RETURN RmsRoundToInt((((currentLevel - min) * 100.0)/range)); 
}


(***********************************************************)
(* Name:  RmsScaleStdLevelToPercent                        *)
(* Args:  DOUBLE current level value  (value to scale)     *)
(*                                                         *)
(* Desc:  Scales a standard level value provided to a      *)
(*        percentage number.  A standard level is defined  *)
(*        as having a fixed 0 to 255 range.                *)
(*                                                         *)
(* Rtrn:  INTEGER : percentage (whole number)              *)
(***********************************************************)
DEFINE_FUNCTION INTEGER RmsScaleStdLevelToPercent(DOUBLE currentLevel)
{
  // a standard level ranges from 0 to 255
  RETURN RmsScaleLevelToPercent(currentLevel, 0 , 255); 
}


(***********************************************************)
(* Name:  RmsScalePercentToLevel                           *)
(* Args:  INTEGER current percent value                    *)
(*        SLONG  maximum level value                       *)
(*        SLONG  minimum level value                       *)
(*                                                         *)
(* Desc:  Determines the scaled level value based on the   *)
(*        provided percentage number and level range.      *)
(*                                                         *)
(* Rtrn:  SLONG : scaled level value (whole number)        *)
(***********************************************************)
DEFINE_FUNCTION SLONG RmsScalePercentToLevel(INTEGER percentValue, SLONG maxLevel, SLONG minLevel)
{
  STACK_VAR LONG  range;
  STACK_VAR SLONG  max;
  STACK_VAR SLONG  min; 
  STACK_VAR SLONG  shift;
  STACK_VAR DOUBLE levelValue;
  
  // sanity check the min and max levels
  max = MAX_VALUE(maxLevel, minLevel);
  min = MIN_VALUE(maxLevel, minLevel);

  // determine range & shift
  range = ABS_VALUE(max - min);
  
  // is/of = %/100 :: is = (%/100) * of
  levelValue = (percentValue * range) / 100.0;
  
  // shift level value based on min scale range
  RETURN RmsRoundToSignedLong((levelValue) + min);
}


(***********************************************************)
(* Name:  RmsScalePercentToStdLevel                        *)
(* Args:  INTEGER current percent value                    *)
(*                                                         *)
(* Desc:  Determines the scaled level value based on the   *)
(*        provided percentage number and standard level    *)
(*        range.  A standard level is defined as having a  *)
(*        fixed 0 to 255 range.                            *)
(*                                                         *)
(* Rtrn:  SLONG : scaled level value (whole number)        *)
(***********************************************************)
DEFINE_FUNCTION SLONG RmsScalePercentToStdLevel(INTEGER percentValue)
{
  // a standard level ranges from 0 to 255
  RETURN RmsScalePercentToLevel(percentValue, 0 , 255); 
}
