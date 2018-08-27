MODULE_NAME='mSkyDusky'(DEV vdvControl[],DEV dvRS232)
INCLUDE 'CustomFunctions'

DEFINE_VARIABLE
INTEGER DEBUG
INTEGER nOutput = 0;

DEFINE_EVENT CHANNEL_EVENT[vdvControl,0]{
	ON:{
		STACK_VAR CHAR _cmd 
		_cmd = $FF
		SWITCH(CHANNEL.CHANNEL){
			CASE 1:	_cmd = $3E //Play		 		[1]
			CASE 2:	_cmd = $3F // Stop 			[2]
			CASE 3:	_cmd = $24 // Pause	 		[3]
			CASE 4:	_cmd = $28 // Fastforward	[4]
			CASE 5:	_cmd = $3D // Rewind			[5]
			CASE 8:	_cmd = $40 // Record			[8]
			CASE 9:	_cmd = $0C // Power			[9]
				
			CASE 10:	_cmd = $00 // Digit 0	[10]
			CASE 11:	_cmd = $01 // Digit 1	[11]
			CASE 12:	_cmd = $02 // Digit 2	[12]
			CASE 13:	_cmd = $03 // Digit 3	[13]
			CASE 14:	_cmd = $04 // Digit 4	[14]
			CASE 15:	_cmd = $05 // Digit 5	[15]
			CASE 16:	_cmd = $06 // Digit 6	[16]
			CASE 17:	_cmd = $07 // Digit 7	[17]
			CASE 18:	_cmd = $08 // Digit 8	[18]
			CASE 19:	_cmd = $09 // Digit 9	[19]
				
			CASE 49:	_cmd = $5C // Select	[49]
			CASE 22:	_cmd = $20 // Chan Up	[22]
			CASE 23:	_cmd = $21 // Chan Down [23]
		  
			CASE 45:	_cmd = $58 // Up			[45]
			CASE 48:	_cmd = $5B // Right		[48]
			CASE 46:	_cmd = $59 // Down		[46]
			CASE 47:	_cmd = $5A // Left		[47]
			CASE 81:	_cmd = $83 // Backup	[81]
			CASE 101:_cmd = $CB // Info	[101]
			CASE 105:_cmd = $CC // TV Guide [105]
			CASE 113:_cmd = $81 // Help	[113]
			
			CASE 201:_cmd = $80 // SKY Button	[201]
			CASE 202:_cmd = $6D // RED				[202]
			CASE 203:_cmd = $6E // GREEN			[203]
			CASE 204:_cmd = $6F // YELLOW			[204]
			CASE 205:_cmd = $70 // BLUE			[205]
			
			CASE 210:_cmd = $84 // TV				[210]
			CASE 211:_cmd = $7D // Box Office	[211]
			CASE 212:_cmd = $7E // Services		[212]
			CASE 213:_cmd = $F5 // Interactive	[213]
		}
		IF(_cmd <> $FF)fnSendCommand(GET_LAST(vdvControl),_cmd)
	}
}

DATA_EVENT[vdvControl]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'POWER':{
				IF(DATA.TEXT = 'ON'){  fnSendCommand(GET_LAST(vdvControl),$80);}
				IF(DATA.TEXT = 'OFF'){
					// If feedback is occuring and power is ON OR feedback is not occuring, push standby toggle
					IF( ([vdvControl[GET_LAST(vdvControl)],255] && [vdvControl[GET_LAST(vdvControl)],251]) || ![vdvControl[GET_LAST(vdvControl)],251] ){
						fnSendCommand(GET_LAST(vdvControl),$0C);
					}
				}
			}
			CASE 'CHANJUMP':{
				fnSendCommand(GET_LAST(vdvControl),ATOI("DATA.TEXT[1]"))
				fnSendCommand(GET_LAST(vdvControl),ATOI("DATA.TEXT[2]"))
				fnSendCommand(GET_LAST(vdvControl),ATOI("DATA.TEXT[3]"))
				IF(LENGTH_ARRAY(DATA.TEXT) = 4)fnSendCommand(GET_LAST(vdvControl),ATOI("DATA.TEXT[4]"))
			}
		}
	}
}

DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET BAUD 57600 N 8 1 485 DISABLE'
	}
}

DEFINE_FUNCTION fnSendCommand(INTEGER _output,CHAR _cmd){
	 SEND_STRING dvRS232, "$43,_output - 1,$0C,_cmd"
}