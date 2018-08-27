MODULE_NAME='mDGXMatrix'(DEV vdvControl, DEV tp[], DEV dvDGX)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Basic Control for AMX DGX with TP which emulates standard control via 
	front panel
	
	Buttons:
	 98 - Take
	 99 - Cancel
	100 + Inputs
	201 + Outputs
******************************************************************************/
DEFINE_CONSTANT
INTEGER btnTake 	= 98
INTEGER btnCancel = 99
INTEGER btnInput	= 100
INTEGER btnOutput = 401
/******************************************************************************
	Constants & Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uPanel{
	INTEGER curINPUT
	INTEGER newSTATE[256]
}	
DEFINE_TYPE STRUCTURE uMatrix{
	INTEGER STATE[256]
}
DEFINE_VARIABLE
uMatrix 	myMatrix
uPanel	myDGXPanel[5]
/******************************************************************************
	Device Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDGX]{
	COMMAND:{
		STACK_VAR CHAR pDATA[500]
		STACK_VAR INTEGER OUT
		STACK_VAR INTEGER IN
		STACK_VAR INTEGER x
		STACK_VAR INTEGER p
		IF(LEFT_STRING(DATA.TEXT, 2) == 'SI'){
			GET_BUFFER_STRING(DATA.TEXT,2)
			IN = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT, 'T', 1), 1))
			FOR(x = 1; x <= 256; x++){
				IF(myMatrix.STATE[x] == IN){myMatrix.STATE[x] = 0}
			}
			GET_BUFFER_STRING(DATA.TEXT,2)
			pDATA = fnStripCharsRight(DATA.TEXT, 1)
			WHILE(LENGTH_ARRAY(pDATA)){
				OUT = ATOI( REMOVE_STRING(pDATA, ' ', 1) )
				myMatrix.STATE[OUT] = IN
				IF(!FIND_STRING(pDATA,' ',1)){pDATA = ''}
			}
			FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
				IF(myDGXPanel[p].curINPUT == IN){
					FOR(x = 1; x <= 256; x++){
						myDGXPanel[p].newSTATE[x] = (myMatrix.STATE[x] == IN)
					}
				}
			}
		}
	}
}
DEFINE_EVENT DATA_EVENT[vdvControl]{
	COMMAND:{
		IF(LEFT_STRING(DATA.TEXT, 8) == 'VMATRIX-'){
			STACK_VAR CHAR INPUT [10]
			STACK_VAR CHAR OUTPUT [10]
			STACK_VAR CHAR GARBAGE [10]
			send_string 0, 'VMATRIX COMMAND RECIEVED'
			GET_BUFFER_STRING(DATA.TEXT,8)
			GARBAGE = REMOVE_STRING(DATA.TEXT, '*', 1)
			send_string 0, "'garbage: ',GARBAGE"
			INPUT = fnStripCharsRight(GARBAGE, 1)
			send_string 0, "'input: ',INPUT"
			OUTPUT = DATA.TEXT
			send_string 0, "'ouput: ',OUTPUT"
			fnMatrix(ATOI(INPUT),ATOI(OUTPUT))
			send_string 0, "'INPUT: ',input,'OUTPUT: ',output"
		}
	}
}
/******************************************************************************
	Utility Functions
******************************************************************************/
DEFINE_FUNCTION fnMatrix(INTEGER pIN, INTEGER pOUT){
	IF(pIN){
		SEND_COMMAND dvDGX, "'CI',ITOA(pIN),'O',ITOA(pOUT),'T'"
	}
	ELSE{
		SEND_COMMAND dvDGX, "'DO',ITOA(pOUT),'T'"
	}
}
/******************************************************************************
	Interface Control
******************************************************************************/
DEFINE_CONSTANT
LONG TLID_SEND = 1
DEFINE_VARIABLE
LONG TLT_SEND[] = {200}
CHAR DISCONNECT[1000]
				
DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		STACK_VAR INTEGER btn
		STACK_VAR INTEGER pnl
		btn = BUTTON.INPUT.CHANNEL
		pnl = GET_LAST(tp)
		SELECT{
			ACTIVE(btn == btnTake):{		// Take Changes
				STACK_VAR INTEGER x
				STACK_VAR CHAR CONNECT[1000]
				DISCONNECT = ''
				FOR(x = 1; x <= 256; x++){
					if(myDGXPanel[pnl].newSTATE[x] &&  (myMatrix.STATE[x] != myDGXPanel[pnl].curINPUT)){
						IF(LENGTH_ARRAY(CONNECT)){
							CONNECT = "CONNECT,' ',ITOA(x)"
						}
						ELSE{
							CONNECT = ITOA(x)
						}
					}
					ELSE IF(!myDGXPanel[pnl].newSTATE[x] && myMatrix.STATE[x] == myDGXPanel[pnl].curINPUT){
						DISCONNECT = "DISCONNECT,' ',ITOA(x)"
					}
				}
				IF(LENGTH_ARRAY(CONNECT)){
					SEND_COMMAND dvDGX, "'CI',ITOA(myDGXPanel[pnl].curINPUT),'O',CONNECT,'T'"
				}
				IF(LENGTH_ARRAY(DISCONNECT)){
					TIMELINE_CREATE(TLID_SEND,TLT_SEND,LENGTH_ARRAY(TLT_SEND),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
				}
				myDGXPanel[pnl].curINPUT = 0
				FOR(x = 1; x <= 256; x++){ 
					myDGXPanel[pnl].newSTATE[x] = 0 
				}
			}
			ACTIVE(btn == btnCancel):{	// Cancel Changes
				SEND_COMMAND dvDGX,"'SI',ITOA(myDGXPanel[pnl].curINPUT),'T'"
			}
			ACTIVE(btn >= btnOutput && btn <= btnOutput + 255):{	// Select Output
				myDGXPanel[pnl].newSTATE[btn - btnOutput + 1] = !myDGXPanel[pnl].newSTATE[btn - btnOutput + 1]
			}
			ACTIVE(btn >= btnInput && btn <= btnInput + 256):{					// Select Input
				STACK_VAR INTEGER x
				myDGXPanel[pnl].curINPUT = btn - btnInput
				FOR(x = 1; x <= 256; x++){ 
					myDGXPanel[pnl].newSTATE[x] = 0 
				}
				SEND_COMMAND dvDGX,"'SI',ITOA(myDGXPanel[pnl].curINPUT),'T'"
			}
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_SEND]{
	SEND_COMMAND dvDGX, "'DO',DISCONNECT,'T'"
}
/******************************************************************************
	Program
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		FOR(x = 0; x <= 256; x++){
			[tp[p], btnInput+x] = (myDGXPanel[p].curINPUT == x)
		}
		FOR(x = 1; x <= 256; x++){
			[tp[p],btnOutput+x-1] = (myDGXPanel[p].newSTATE[x])
		}
	}
}