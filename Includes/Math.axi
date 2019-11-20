PROGRAM_NAME='Math'
(*{{PS_SOURCE_INFO(PROGRAM STATS)                          *)
(***********************************************************)
(*  FILE CREATED ON: 04/23/2003 AT: 10:13:29               *)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/23/2003 AT: 10:13:29         *)
(***********************************************************)
(*  ORPHAN_FILE_PLATFORM: 1                                *)
(***********************************************************)
(*!!FILE REVISION: Rev 0                                   *)
(*  REVISION DATE: 04/23/2003                              *)
(*                                                         *)
(*  COMMENTS:                                              *)
(*                                                         *)
(***********************************************************)
(*}}PS_SOURCE_INFO                                         *)
(***********************************************************)



////////////////////////////////////////////////////////////
//       ========== CVS Version History ==========        //
////////////////////////////////////////////////////////////
(*
    $Log: Math.axi,v $

    Revision 1.1  2003/03/05 14:38:31  peter
    Newly Prepeared - Functions from Darren and added fn_ScaleRange()

*)
////////////////////////////////////////////////////////////



(***********************************************************)
(*                MATH FUNCTIONS GO BELOW                  *)
(***********************************************************)
#define _MATHS_INCLUDED

#IF_DEFINED __NETLINX__

DEFINE_CONSTANT

INTEGER D2R_NUMBERS[13] = {1,4,5,9,10,40,50,90,100,400,500,900,1000}
CHAR D2R_ROMANS[13][2]  = {'I','IV','V','IX','X','XL','L','XC','C','CD','D','CM','M'}

(***********************************************************)
(* FUNCTION:     DEC2ROMAN                                 *)
(* RETURN:       STRING OF ROMAN CHARACTERS                *)
(* PARAMETERS:   lDECIMAL - DECIMAL INPUT                  *)
(***********************************************************)
DEFINE_FUNCTION CHAR[100] DEC2ROMAN(LONG lDECIMAL)
STACK_VAR
    INTEGER nI
    CHAR strTEMP[100]
{
    FOR (nI = 13; nI >= 1; nI--)
        WHILE (lDECIMAL >= D2R_NUMBERS[nI])
        {
            lDECIMAL = lDECIMAL - D2R_NUMBERS[nI]
            strTEMP = "strTEMP, D2R_ROMANS[nI]"
        }
    RETURN strTEMP
}

(***********************************************************)
(* FUNCTION:     ROUNDER                                   *)
(* RETURN:       DOUBLE                                    *)
(* PARAMETERS:   dVALUE - DOUBLE INPUT VALUE               *)
(*               nDECIMALS - INTEGER AMOUNT OF DIGITS 0.X  *)
(***********************************************************)
DEFINE_FUNCTION DOUBLE ROUNDER(DOUBLE dVALUE, INTEGER nDECIMALS)
STACK_VAR
    INTEGER nJ
    DOUBLE nA
    CHAR strFORMAT[10]
{
    nA = 1
    SWITCH (nDECIMALS)
    {
        CASE 0: nA = 1
        CASE 1: nA = 10
        DEFAULT:
        {
            FOR (nJ = 1; nJ <= nDECIMALS; nJ++)
                nA = nA * 10
        }
    }
    RETURN ATOI(FORMAT('%-9.0f', (dVALUE * nA) + 0.5)) / nA
}

(***********************************************************)
(* FUNCTION:     BIN2INT                                   *)
(* RETURN:       LONG                                      *)
(* PARAMETERS:   strVALUE - STRING OF BIN CHARS            *)
(***********************************************************)
DEFINE_FUNCTION LONG BIN2INT(CHAR strVALUE[])
STACK_VAR
    INTEGER nI, nVALUESIZE
    LONG lRESULT
{
    nVALUESIZE = LENGTH_STRING(strVALUE)
    FOR (nI = nVALUESIZE; nI > 0; nI--)
        IF (strVALUE[nI] = '1')
            lRESULT = lRESULT + (1 LSHIFT (nVALUESIZE - nI))
    RETURN lRESULT
}

(***********************************************************)
(* FUNCTION:     INT2BIN                                   *)
(* RETURN:       STRING                                    *)
(* PARAMETERS:   lVALUE - LONG VALUE                       *)
(*               nDIGITS - INTEGER AMOUNT OF DIGITS        *)
(***********************************************************)
DEFINE_FUNCTION CHAR[1000] INT2BIN(LONG lVALUE, SINTEGER nDIGITS)
STACK_VAR
    SINTEGER snI
    LONG lI
    CHAR strRESULT[1000]
{
    FOR (snI = nDIGITS-1; snI >= 0; snI--)
    {
        lI = TYPE_CAST(snI)
        IF ((lVALUE BAND (1 LSHIFT lI)) <> 0)
            strRESULT = "strRESULT, '1'"
        ELSE
            strRESULT = "strRESULT, '0'"
    }
    RETURN strRESULT
}

(***********************************************************)
(* FUNCTION:     INT2OCT                                   *)
(* RETURN:       STRING                                    *)
(* PARAMETERS:   lVALUE - LONG VALUE                       *)
(*               nDIGITS - INTEGER AMOUNT OF DIGITS        *)
(***********************************************************)
DEFINE_FUNCTION CHAR[1000] INT2OCT(LONG lVALUE, INTEGER nDIGITS)
STACK_VAR
    INTEGER nI
    CHAR strOCT[1000]
    LONG lREST
{
    WHILE(lVALUE <> 0)
    {
        lREST = lVALUE % 8
        lVALUE = lVALUE / 8
        strOCT = "ITOA(lREST),strOCT"
    }
    FOR (nI = LENGTH_STRING(strOCT)+1; nI <= nDIGITS; nI++)
        strOCT = "'0', strOCT"
    RETURN strOCT
}

(***********************************************************)
(* FUNCTION:     OCT2INT                                   *)
(* RETURN:       LONG                                      *)
(* PARAMETERS:   strVALUE - STRING OF OCT CHARS            *)
(***********************************************************)
DEFINE_FUNCTION LONG OCT2INT(CHAR strVALUE[])
STACK_VAR
    INTEGER nI
    INTEGER nINT
{
    FOR (nI = 1; nI <= LENGTH_STRING(strVALUE); nI++)
        nINT = nINT * 8 + ATOI(MID_STRING(strVALUE, nI, 1))
    RETURN nINT
}

#END_IF

(***********************************************************)
(* FUNCTION:     Scale_Range                               *)
(* RETURN:       SLONG                                     *)
(* PARAMETERS:   slNum_In - input number to scale          *)
(*           :   slMin_In - current range minimum value    *)
(*           :   slMax_In - current range maximum value    *)
(*           :   slMin_Out - desired range minimum value   *)
(*           :   slMax_Out - desired range maximum value   *)
(***********************************************************)
DEFINE_FUNCTION SLONG fn_ScaleRange(SLONG slNum_In, SLONG slMin_In, SLONG slMax_In, SLONG slMin_Out, SLONG slMax_Out)
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
        SEND_STRING 0, "'Scale_Range() Error: Invalid value. Enter a value between ',ITOA(slMin_In),' and ',ITOA(slMax_In),'.'"
        Return -1
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

(***********************************************************)
(* FUNCTION:     fnPrintHex()                              *)
(* RETURN:       N/A				                               *)
(* PARAMETERS:   s[]: string of hex chars coming in        *)
(***********************************************************)
define_function fnPrintHex(char s[])
{
	integer nLoop;
	nLoop = 1
	WHILE(nLoop <= length_string(s))
	{
		send_string 0:0:0, "'fnPrintHex(): $',itohex(s[nLoop])";
		if(nLoop < length_string(s))
		{
			send_string 0:0:0, "'fnPrintHex(): ,'";
		}
		nLoop++;
	}
}

(***********************************************************)
(*                   END OF INCLUDE FILE                   *)
(***********************************************************)