PROGRAM_NAME='CustomFunctions'
/******************************************************************************
Functions for Device Handling
******************************************************************************/
DEFINE_FUNCTION CHAR[20] DEVTOA(DEV pDevice){
	RETURN "ITOA(pDevice.NUMBER),':',ITOA(pDevice.PORT),':',ITOA(pDevice.SYSTEM)"
}
DEFINE_FUNCTION ATODEV(DEV pDevice,CHAR pDPS[]){
	pDevice.NUMBER = ATOI(fnGetSplitStringValue(pDPS,':',1))
	pDevice.PORT = ATOI(fnGetSplitStringValue(pDPS,':',2))
	pDevice.SYSTEM = ATOI(fnGetSplitStringValue(pDPS,':',3))
}
/******************************************************************************
Functions for String Handling
******************************************************************************/
DEFINE_FUNCTION CHAR[10000] fnGetSplitStringValue(CHAR pString[10000],CHAR pDelimiter, INTEGER pIndex){
	STACK_VAR INTEGER x
	STACK_VAR CHAR myString[10000]
	STACK_VAR CHAR rs[10000]
	myString = pString
	x = 1
	WHILE(FIND_STRING(myString,"pDelimiter",1)){
		rs = fnStripCharsRight(REMOVE_STRING(myString,"pDelimiter",1),1)
		IF(pIndex == x){RETURN fnRemoveWhiteSpace(rs)}
		x++
	}
	IF(pIndex == x){RETURN fnRemoveWhiteSpace(myString)}
}

DEFINE_FUNCTION CHAR[10000] fnGetCSV(CHAR pString[10000],INTEGER pIndex){
	RETURN fnGetSplitStringValue(pString,',',pIndex)
}

DEFINE_FUNCTION CHAR[10000] fnStripCharsRight(CHAR _str[10000],INTEGER _Count){
	IF(LENGTH_ARRAY(_str) >= _Count){
		RETURN LEFT_STRING(_str,LENGTH_ARRAY(_str) - _Count)
	}
}

DEFINE_FUNCTION INTEGER fnGET_INTEGER(CHAR _str[]){
	STACK_VAR INTEGER iCount
	STACK_VAR INTEGER	iIndex
	IF(LENGTH_ARRAY(_str)){
		FOR(iCount = 1; iCount <= LENGTH_ARRAY(_str); iCount++){
			IF(_str[iCount] >= $30 && _str[iCount] <= $39){
				iIndex = iCount
			}
			ELSE{
				BREAK
			}
		}
		IF(iIndex){
			RETURN ATOI(LEFT_STRING(_str,iIndex))
		}
	}
}
DEFINE_FUNCTION CHAR[10000] fnPadLeadingChars(CHAR _str[10000],CHAR _pad, INTEGER _Count)
{
	 STACK_VAR CHAR rs[10000]
	 rs = _str;
	 IF(_Count = 0) RETURN ''									// Emergency Exit
	 WHILE(LENGTH_ARRAY(rs) <  _Count){ rs = "_pad,rs" }
	 RETURN rs;
}
DEFINE_FUNCTION CHAR[10000] fnPadTrailingChars(CHAR _str[10000],CHAR _pad, INTEGER _Count)
{
	 STACK_VAR CHAR rs[10000]
	 rs = _str;
	 IF(_Count = 0) RETURN ''									// Emergency Exit
	 WHILE(LENGTH_ARRAY(rs) <  _Count){ rs = "rs,_pad" }
	 RETURN rs;
}

DEFINE_FUNCTION INTEGER fnFindCharFromRight(CHAR _str[10000], CHAR _char){
	STACK_VAR INTEGER _INDEX
	STACK_VAR INTEGER _COUNT
	_COUNT = 0
	FOR(_INDEX = LENGTH_ARRAY(_str);_INDEX >= 0;_INDEX--){
		_COUNT++
		IF(_str[_INDEX] = _char) RETURN _COUNT
	}
	RETURN 0
}

DEFINE_FUNCTION CHAR[10000] fnRemoveWhiteSpace(CHAR pSTRING[10000]){
	STACK_VAR CHAR rs[10000]
	rs = fnRemoveLeadingWhiteSpace(pSTRING)
	rs = fnRemoveTrailingWhiteSpace(rs)
	RETURN rs
}
DEFINE_FUNCTION CHAR[10000] fnRemoveLeadingWhiteSpace(CHAR pSTRING[10000]){
	STACK_VAR CHAR rs[10000]
	rs = pSTRING;
	WHILE(LENGTH_ARRAY(rs)){
		IF(rs[1] <=  $20 || rs[1] >= $7F ){
			GET_BUFFER_CHAR(rs)
		}
		ELSE{ BREAK; }
	}
	RETURN rs
}
DEFINE_FUNCTION CHAR[10000] fnRemoveTrailingWhiteSpace(CHAR pSTRING[10000]){

	STACK_VAR CHAR rs[10000]
	rs = pSTRING;
	WHILE(LENGTH_ARRAY(rs)){
		IF(rs[LENGTH_ARRAY(rs)] <=  $20 || rs[LENGTH_ARRAY(rs)] >= $7F ){
			rs = fnStripCharsRight(rs,1)
		}
		ELSE{ BREAK; }
	}
	RETURN rs
}
DEFINE_FUNCTION CHAR[10000] fnRemoveQuotes(CHAR _str[10000]){

	STACK_VAR CHAR rs[10000]
	rs = _str;

	IF(rs[1] == $22 || rs[1] == $27){ GET_BUFFER_CHAR(rs) }
	IF(LENGTH_ARRAY(_str)){
		IF(rs[LENGTH_ARRAY(rs)] == $22 || rs[LENGTH_ARRAY(rs)] == $27){
			SET_LENGTH_ARRAY(rs,LENGTH_ARRAY(rs)-1)
		}
	}
	RETURN rs
}
DEFINE_FUNCTION CHAR[200] fnJSONEncode(CHAR pString[]){
	STACK_VAR INTEGER x
	STACK_VAR CHAR pReturn[200]

	FOR(x = 1; x <= LENGTH_ARRAY(pString); x++){
		SWITCH(pString[x]){

			CASE $00:{}									// Null
			CASE $01:{}									// Start of Header
			CASE $02:{}									// Start of Test
			CASE $03:{}									// End of Text
			CASE $04:{}									// End of Transmission
			CASE $05:{}									// Enquiry
			CASE $06:{}									// Acknowledge
			CASE $07:{}									// Bell
			CASE $08:pReturn = "pReturn,'\b'"	// Backspace
			CASE $09:pReturn = "pReturn,'\t"'"	// Horizontal Tab
			CASE $0A:pReturn = "pReturn,'\n"'"	// Newline
			CASE $0B:{}									// Vertical Tab
			CASE $0C:pReturn = "pReturn,'\f"'"	// Formfeed
			CASE $0D:pReturn = "pReturn,'\r"'"	// Carriage Return
			CASE $0E:{}									// Shift Out
			CASE $0F:{}									// Shift In
			CASE $10:{}									//
			CASE $11:{}									//
			CASE $12:{}									//
			CASE $13:{}									//
			CASE $14:{}									//
			CASE $15:{}									// Negative Acknowledge
			CASE $16:{}									//
			CASE $17:{}									//
			CASE $18:{}									//
			CASE $19:{}									//
			CASE $1A:{}									//
			CASE $1B:{}									// Escape
			CASE $1C:{}									//
			CASE $1D:{}									//
			CASE $1E:{}									//
			CASE $1F:{}									//
			CASE $22:pReturn = "pReturn,'\"'"	// Quotation Mark
			CASE $2F:pReturn = "pReturn,'\/'"	// Reverse Solidus
			CASE $5C:pReturn = "pReturn,'\\'"	// Solidus

			DEFAULT: pReturn = "pReturn,pString[x]"
		}
	}

	RETURN pReturn
}

DEFINE_FUNCTION INTEGER fnComparePrefix(CHAR pString[], CHAR pSuffix[]){
	RETURN (LEFT_STRING(pString,LENGTH_ARRAY(pSuffix)) == pSuffix)
}
/******************************************************************************
Functions for Logic Handling
******************************************************************************/
DEFINE_FUNCTION CHAR[10] fnGetBooleanString(INTEGER pSTATE){
	SWITCH(pSTATE){
		CASE FALSE:	RETURN 'false'
		DEFAULT:	   RETURN 'true'
	}
}
DEFINE_FUNCTION CHAR[10] fnGetONOffString(INTEGER pSTATE){
	SWITCH(pSTATE){
		CASE FALSE:	RETURN 'OFF'
		DEFAULT:	   RETURN 'ON'
	}
}

/******************************************************************************
Functions for Time Handling
******************************************************************************/
DEFINE_FUNCTION CHAR[30] TIME_STAMP(){
	STACK_VAR CHAR TS[30]
	TS = "FORMAT('%04d',DATE_TO_YEAR(LDATE))"
	TS = "TS,FORMAT('%02d',DATE_TO_MONTH(DATE))"
	TS = "TS,FORMAT('%02d',DATE_TO_DAY(DATE))"
	TS = "TS,FORMAT('%02d',TIME_TO_HOUR(TIME))"
	TS = "TS,FORMAT('%02d',TIME_TO_MINUTE(TIME))"
	TS = "TS,FORMAT('%02d',TIME_TO_SECOND(TIME))"
	RETURN TS
}
DEFINE_FUNCTION SLONG fnDateDif(CHAR pDATE1[10], CHAR pDATE2[10]){
	STACK_VAR SLONG pDAYS1
	STACK_VAR SLONG pDAYS2

	// Calculate the number of days in the first date
	pDays1 = fnDaysInDate(pDATE1)
	pDAYS2 = fnDaysInDate(pDATE2)

	RETURN pDAYS1 - pDAYS2
}
DEFINE_FUNCTION SLONG fnDaysInDate(CHAR pDATE[10]){
	STACK_VAR SLONG pDAYS
	STACK_VAR SINTEGER m
	// Get Number of days up to end of last year (Doesn't needt o be accurate)
	pDAYS = DATE_TO_YEAR(pDATE)-1 * TYPE_CAST(365)
	// Get days in each month that has passed
	FOR(m = 1; m < DATE_TO_MONTH(pDATE); m++){
		pDAYS = pDAYS + fnDaysInMonth(DATE_TO_YEAR(pDATE),m)
	}
	pDAYS = pDAYS + DATE_TO_DAY(pDATE)

}
DEFINE_FUNCTION SINTEGER fnDaysInMonth(SINTEGER pYEAR,SINTEGER pMONTH){
	SWITCH(pMONTH){
		CASE 04:
		CASE 06:
		CASE 09:
		CASE 11:RETURN 30
		CASE 01:
		CASE 03:
		CASE 05:
		CASE 07:
		CASE 08:
		CASE 10:
		CASE 12:RETURN 31
		CASE 02:{
			IF(pYEAR MOD 4){
				RETURN 29
			}
			ELSE{
				RETURN 28
			}
		}
	}
}
DEFINE_FUNCTION CHAR[8] fnSubtractSeconds(CHAR _time[8], SLONG _count)
{
	 STACK_VAR SLONG _Hour
	 STACK_VAR SLONG _Min
	 STACK_VAR SLONG _Sec
	 STACK_VAR SLONG _TotalSeconds

	 _Hour = TIME_TO_HOUR(_time)
	 _Min =  TIME_TO_MINUTE(_time)
	 _Sec =  TIME_TO_SECOND(_time)

	 _TotalSeconds = _Sec
	 _TotalSeconds = _TotalSeconds + (_Min * 60)
	 _TotalSeconds = _TotalSeconds + (_Hour * 3600)

	 // If more seconds than on time, then put to 1 second to midnight
	 IF(_count > _TotalSeconds)
		  {
		  _count = (_count - _TotalSeconds);
		  _TotalSeconds = 86400;
		  }

	 _TotalSeconds = (_TotalSeconds - _count)

	 RETURN fnSecondsToTime(_TotalSeconds)

}

DEFINE_FUNCTION CHAR[8] fnTimeString(INTEGER _Hour, INTEGER _Min, INTEGER _Sec)
{
	 RETURN "fnPadLeadingChars(ITOA(_Hour),'0',2),':',fnPadLeadingChars(ITOA(_Min),'0',2),':',fnPadLeadingChars(ITOA(_Sec),'0',2)"
}

DEFINE_FUNCTION CHAR[8] fnSecondsToTime(SLONG _Seconds)
{
	 STACK_VAR INTEGER rtn_Hour
	 STACK_VAR INTEGER rtn_Min
	 STACK_VAR INTEGER rtn_Secs

	 STACK_VAR INTEGER _Minutes

	 rtn_Secs = TYPE_CAST(_Seconds % 60)
	 _Minutes = TYPE_CAST((_Seconds - rtn_Secs) / 60)
	 rtn_Min = _Minutes % 60
	 rtn_Hour = (_Minutes - rtn_Min) / 60

	 RETURN fnTimeString(rtn_Hour,rtn_Min,rtn_Secs)
}

DEFINE_FUNCTION SLONG fnTimeToSeconds(CHAR pTIME[8]){
	STACK_VAR SINTEGER HOURS
	STACK_VAR SINTEGER MINS
	STACK_VAR SINTEGER SECONDS
	STACK_VAR SLONG    TOTAL

	// Set Values
	HOURS   = TIME_TO_HOUR(pTIME)
	MINS    = TIME_TO_MINUTE(pTIME)
	SECONDS = TIME_TO_SECOND(pTIME)
	IF(SECONDS = -1){SECONDS = 0}

	// Calculate
	TOTAL = HOURS * 60 * 60
	TOTAL = TOTAL +(MINS * 60)
	TOTAL = TOTAL +(SECONDS)

	// Return
	RETURN( TOTAL )
}

DEFINE_FUNCTION INTEGER fnTimeCompareToMin(CHAR cTime1[8], CHAR cTime2[8]){
	IF((TIME_TO_MINUTE(cTime1) = TIME_TO_MINUTE(cTime2)) && (TIME_TO_HOUR(cTime1) = TIME_TO_HOUR(cTime2))){
		RETURN 1
	}
	ELSE{
		RETURN 0
	}
}

DEFINE_FUNCTION SLONG fnSecsToMins(SLONG pSeconds, INTEGER pRoundUp){
	STACK_VAR SLONG pMaths

	// Reasign to prevent errorss
	pMaths = pSeconds

	// Calculate
	pMaths = ((pMaths - (pMaths MOD 60)) / 60)

	// Add Rounding
	IF(pRoundUp){
		IF(pSeconds MOD 60){
			pMaths = pMaths+1
		}
	}
	// Return
	RETURN pMaths
}

DEFINE_FUNCTION CHAR[100] fnSecondsToDurationText(SLONG pDurationParam, INTEGER pHandleSeconds){
/******************************************************************************

	pHandleSeconds
	1 = Include Seconds in Response
	2 = Round spare seconds UP

******************************************************************************/
	STACK_VAR SLONG pDAYs
	STACK_VAR SLONG pHOURs
	STACK_VAR SLONG pMINs
	STACK_VAR SLONG pSECs
	STACK_VAR CHAR pReturnString[64]
	STACK_VAR SLONG pDuration
	STACK_VAR SLONG pHolder	// Used to bypass weird compiler type errors
	STACK_VAR SLONG timeMINs
	STACK_VAR SLONG timeSECs

	// Re-assign param
	pDuration = pDurationParam

	IF(pDuration){
		// Get Seconds
		pSecs = pDURATION % 60

		// Remove Any Spare Seconds
		pDURATION = pDURATION - pSECs
		// convert to Mins
		pMINs = (pDURATION / 60) % 60

		// Get Hours
		pDURATION = pDURATION - (pMINs * 60)
		pHOURs = (pDURATION / 3600) % 24
		pDURATION = pDURATION - (pHOURs * 3600)

		// Get Days
		pHolder = 86400
		pDAYs = pDURATION / pHolder

		IF(pDAYs == 1){
			pReturnString = "pReturnString,ITOA(pDAYs),'day '"
		}
		ELSE IF(pDAYs > 1){
			pReturnString = "pReturnString,ITOA(pDAYs),'days '"
		}

		IF(pHOURs == 1){
			pReturnString = "pReturnString,ITOA(pHOURs),'hr '"
		}
		ELSE IF(pHOURs > 1 || pDays){
			pReturnString = "pReturnString,ITOA(pHOURs),'hrs '"
		}
		// Round up Secs if requested
		IF(pHandleSeconds == 2){
			IF(pSECs){
				pMINs = pMINs + 1
			}
		}
		IF(pMINs == 1){
			pReturnString = "pReturnString,ITOA(pMINs),'min '"
		}
		ELSE IF(pMINs > 1 || pHOURs || pDAYs){
			pReturnString = "pReturnString,ITOA(pMINs),'mins '"
		}

		IF(pHandleSeconds == 1){
			IF(pSECS == 1){
				pReturnString = "pReturnString,ITOA(pSECS),'sec '"
			}
			ELSE IF(pSECS > 1 || pMINs || pHOURs || pDAYs){
				pReturnString = "pReturnString,ITOA(pSECS),'secs'"
			}
		}
	}
	RETURN pReturnString
}
DEFINE_FUNCTION CHAR[255] fnMonthString(SINTEGER pMonth){
	SWITCH(pMonth){
		CASE 01: RETURN 'January';
		CASE 02: RETURN 'February';
		CASE 03: RETURN 'March';
		CASE 04: RETURN 'April';
		CASE 05: RETURN 'May';
		CASE 06: RETURN 'June';
		CASE 07: RETURN 'July';
		CASE 08: RETURN 'August';
		CASE 09: RETURN 'September';
		CASE 10: RETURN 'October';
		CASE 11: RETURN 'November';
		CASE 12: RETURN 'December';
	}
}
/******************************************************************************
	Functions for Number Handling
******************************************************************************/
DEFINE_FUNCTION CHAR[10000] fnRemoveNonPrintableChars(CHAR pString[10000]){
	STACK_VAR CHAR pRETURN[10000]
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(pString); x++){
		IF(pString[x] >= $20 && pString[x] <= $FF){
			pRETURN = "pRETURN,pString[x]"
		}
	}
	RETURN pRETURN
}


DEFINE_FUNCTION CHAR[10000] fnBytesToString(CHAR pString[10000]){
	STACK_VAR CHAR pRETURN[10000]
	STACK_VAR INTEGER x
	IF(!LENGTH_ARRAY(pString)){RETURN ''}
	FOR(x = 1; x <= LENGTH_ARRAY(pString); x++){
		pReturn = "pReturn,'$',fnPadLeadingChars(ITOHEX(pString[x]),'0',2),','"
	}
	RETURN fnStripCharsRight(pRETURN,1)
}

DEFINE_FUNCTION CHAR[10000] fnHexToString(CHAR pString[10000]){
	STACK_VAR CHAR pRETURN[10000]
	STACK_VAR INTEGER x
	IF(!LENGTH_ARRAY(pString)){RETURN ''}
	FOR(x = 1; x <= LENGTH_ARRAY(pString); x++){
		pReturn = "pReturn,FORMAT('%02x',pString[x])"
	}
	RETURN pRETURN
}
DEFINE_FUNCTION CHAR[800] fnBytesToBinary(CHAR pDATA[]){
	STACK_VAR CHAR pReturn[800]
	STACK_VAR INTEGER INDEX
	FOR(INDEX = 1; INDEX <= LENGTH_ARRAY(pDATA); INDEX++){
		STACK_VAR CHAR pBYTE[8]

		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $80 != FALSE)"	// Bit 8
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $40 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $20 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $10 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $08 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $04 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $02 != FALSE)"
		pBYTE = "pBYTE,ITOA(pDATA[INDEX] BAND $01 != FALSE)"	// Bit 1

		pReturn = "pReturn,pBYTE"
	}
	RETURN pRETURN
}
DEFINE_FUNCTION LONG fnBinaryToLong(CHAR pDATA[100]){
	STACK_VAR LONG pReturn
	STACK_VAR LONG Index
	STACK_VAR LONG Multiplier
	//SEND_STRING 0,"'fnBinaryToLong::pDATA[',pDATA,']'"
	IF(LENGTH_ARRAY(pDATA)){
		Multiplier = 1
		FOR(Index = LENGTH_ARRAY(pDATA); Index >= 1; Index--){
			pReturn = pReturn + ((pDATA[Index] == '1') * Multiplier)
			//SEND_STRING 0,"'fnBinaryToLong::pDATA[',ITOA(INDEX),']Multiplier[',ITOA(Multiplier),']pReturn[',ITOA(pReturn),']'"
			Multiplier = Multiplier * 2
		}
	}
	//SEND_STRING 0,"'fnBinaryToLong::pRETURN[',ITOA(pRETURN),']'"
	RETURN pRETURN
}
DEFINE_FUNCTION CHAR[50] fnLongToByte(LONG pValue, INTEGER pLength){
	STACK_VAR CHAR pHEX[100]
	STACK_VAR CHAR pRETURN[50]
	pHEX = ITOHEX(pVALUE)
	IF(LENGTH_ARRAY(pHEX)%2){pHEX = "'0',pHEX"}
	WHILE(LENGTH_ARRAY(pHEX)){
		pRETURN = "pRETURN,HEXTOI(GET_BUFFER_STRING(pHEX,2))"
	}
	// If length has been set the make sure we return correct array
	IF(pLength){
		IF(LENGTH_ARRAY(pRETURN) < pLength){
			RETURN fnPadLeadingChars(pRETURN,$00,pLength)
		}
		IF(LENGTH_ARRAY(pRETURN) > pLength){
			RIGHT_STRING(pRETURN,pLength)
		}
	}
	// Return Value
	RETURN pRETURN
}
DEFINE_FUNCTION CHAR[50] fnBinaryToByte(CHAR pDATA[]){
	RETURN fnLongToByte(fnBinaryToLong(pDATA),0)
}
(***********************************************************)
(* FUNCTION:     Scale_Range                               *)
(* RETURN:       SLONG                                     *)
(* PARAMETERS:   slNum_In - input number to scale          *)
(*           :   slMin_In - current range minimum value    *)
(*           :   slMax_In - current range maximum value    *)
(*           :   slMin_Out - desired range minimum value   *)
(*           :   slMax_Out - desired range maximum value   *)
(* 'Borrowed' from DarrenS											  *)
(***********************************************************)
DEFINE_FUNCTION SLONG fnScaleRange(SLONG slNum_In, SLONG slMin_In, SLONG slMax_In, SLONG slMin_Out, SLONG slMax_Out)
{
    SLONG slRange_In
    SLONG slRange_Out
    SLONG slNum_Out
    slong slPassByReferenceBug

    //this function used to change the value of parameter 1: slNum_In.  added slPassByReferenceBug to
    //get over this
    slPassByReferenceBug = slNum_In

    IF (slPassByReferenceBug < slMin_In OR slPassByReferenceBug > slMax_In)
    {
        SEND_STRING 0, "'Scale_Range() Error: Invalid value(',ITOA(slPassByReferenceBug),'). Enter a value between ',ITOA(slMin_In),' and ',ITOA(slMax_In),'.'"
        Return -1
    }
    ELSE IF (slPassByReferenceBug == slMin_In)
	 {
		Return slMin_Out
	 }
    ELSE IF (slPassByReferenceBug == slMax_In)
	 {
		Return slMax_Out
	 }
	 ELSE
    {
        slRange_In = slMax_In - slMin_In      // Establish input range
        slRange_Out = slMax_Out - slMin_Out   // Establish output range
        slPassByReferenceBug = slPassByReferenceBug - slMin_In        // Remove input offset
        slNum_Out = slPassByReferenceBug * slRange_Out    // Multiply by max out range
        slNum_Out = slNum_Out / slRange_In    // Then divide by max in range
        slNum_Out = slNum_Out + slMin_Out     // Add in minimum output value
        Return slNum_Out
    }
}


DEFINE_FUNCTION char math_is_whole_number(double a) {
	stack_var slong wholeComponent
   wholeComponent = type_cast(a)
   return wholeComponent == a
}

DEFINE_FUNCTION slong math_floor(double a) {
   if (a < 0 && !math_is_whole_number(a)) {
	return type_cast(a - 1.0)
   }else{
	return type_cast(a)
   }
}

DEFINE_FUNCTION slong math_round(DOUBLE a) {
	return math_floor(a + 0.5)
}
/******************************************************************************
	EoF
******************************************************************************/