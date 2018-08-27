PROGRAM_NAME='StandardCodeDiagnostics'
/******************************************************************************
	System Control - Diagnostics
******************************************************************************/
DEFINE_CONSTANT
INTEGER spvDiagnostics = 3000
INTEGER btnDiagnostics[] = {
	3001,3002,3003,3004,3005,3006,3007,3008,3009,3010,
	3011,3012,3013,3014,3015,3016,3017,3018,3019,3020,
	3021,3022,3023,3024,3025,3026,3027,3028,3029,3030,
	3031,3032,3033,3034,3035,3036,3037,3038,3039,3040,
	3041,3042,3043,3044,3045,3046,3047,3048,3049,3050
}

INTEGER btnComms					= 4000

DEFINE_TYPE STRUCTURE uDevDiag{
	CHAR	  	TEXT[50]
	DEV 	  	OBJECT
}

DEFINE_VARIABLE
VOLATILE uDevDiag myDiagDevices[50]

DEFINE_FUNCTION fnAddDiagDevice(DEV pDEV, CHAR pNAME[50], CHAR pDESC[50]){
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(btnDiagnostics); x++){
		IF(myDiagDevices[x].TEXT = ''){
			myDiagDevices[x].OBJECT = pDEV
			myDiagDevices[x].TEXT = pNAME
			IF(LENGTH_ARRAY(pDESC)){
				myDiagDevices[x].TEXT = "myDiagDevices[x].TEXT,$0A,pDESC"
			}
			RETURN
		}
	}
}
DEFINE_EVENT DATA_EVENT[tpMain]{
	ONLINE:{
		STACK_VAR INTEGER TOTAL_DIAGS
		STACK_VAR INTEGER x
		FOR(x = 1; x <= LENGTH_ARRAY(btnDiagnostics); x++){
			IF(LENGTH_ARRAY(myDiagDevices[x].TEXT)){
				SEND_COMMAND DATA.DEVICE,"'^TXT-',ITOA(btnDiagnostics[x]),',0,',myDiagDevices[x].TEXT"
				TOTAL_DIAGS = x
			}
			ELSE{
				BREAK
			}
		}
		IF(x > 1){
			SEND_COMMAND DATA.DEVICE,"'^SHO-',ITOA(btnDiagnostics[1]),'.',ITOA(btnDiagnostics[x-1]),',1'"
		}
		IF(x < LENGTH_ARRAY(btnDiagnostics)){
			SEND_COMMAND DATA.DEVICE,"'^SHO-',ITOA(btnDiagnostics[x]),'.',ITOA(btnDiagnostics[LENGTH_ARRAY(btnDiagnostics)]),',0'"
		}
		// Sort out the list - hide all to release all ordering
		FOR(x = 1; x <= LENGTH_ARRAY(btnDiagnostics); x++){
			SEND_COMMAND DATA.DEVICE, "'^SHD-',ITOA(spvDiagnostics),',diagDevice',FORMAT('%02d',x)"
		}
		// Show relevant subPages - in reverse order to drop them in place
		IF(TOTAL_DIAGS){
			FOR(x = TOTAL_DIAGS; x >= 1; x--){
				SEND_COMMAND DATA.DEVICE, "'^SSH-',ITOA(spvDiagnostics),',diagDevice',FORMAT('%02d',x)"
			}
		}
	}
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(btnDiagnostics); x++){
		SELECT{
			ACTIVE(myDiagDevices[x].OBJECT.NUMBER >= 0 && myDiagDevices[x].OBJECT.NUMBER <= 32000):{
				[tpMain,btnDiagnostics[x]] = DEVICE_ID(myDiagDevices[x].OBJECT)
			}
			ACTIVE(myDiagDevices[x].OBJECT.NUMBER >= 32000 && myDiagDevices[x].OBJECT.NUMBER <= 36964):{
				[tpMain,btnDiagnostics[x]] = [myDiagDevices[x].OBJECT,251]
			}
			ACTIVE(myDiagDevices[x].OBJECT.NUMBER >= 41001 && myDiagDevices[x].OBJECT.NUMBER <= 42000):{
				[tpMain,btnDiagnostics[x]] = [myDiagDevices[x].OBJECT,251]
			}
			ACTIVE(myDiagDevices[x].OBJECT.NUMBER >= 45000):{
				[tpMain,btnDiagnostics[x]] = DEVICE_ID(myDiagDevices[x].OBJECT)
			}
		}
	}
	[tpMain,btnCOMMS] = TRUE
}

/******************************************************************************
	EoF
******************************************************************************/