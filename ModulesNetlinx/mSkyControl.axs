MODULE_NAME='mSkyControl'(DEV vdvSkyBox[],DEV tp[],DEV dvDusky,DEV dvSkyFB[])
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 07/24/2013  AT: 16:37:03        *)
(***********************************************************)
INCLUDE 'CustomFunctions'
/******************************************************************************
	Sky Control module - Mutliple Boxes, Multiple Interfaces
******************************************************************************/

/******************************************************************************
	Types, Constants, Variables
******************************************************************************/
DEFINE_TYPE STRUCTURE uSkyBox{
	CHAR CHANNUM[10]		// Current Channel Number
	CHAR CHANNAME[255]	// Current Channel Name
	CHAR PROGNAME[255]	// Current Program Name
	CHAR PROGDESC[255]	// Current Program Desc
	CHAR STARTED[255]		// Program Start Time
	INTEGER POWER			//
	CHAR Rx[1500]			// Buffer from Device
	INTEGER FailCount		// Safeguard against repeated garbage
	INTEGER newData		// Is there new data to send up?
}
DEFINE_TYPE STRUCTURE uPanel{
	INTEGER BOX		// Currently Controlled SkyBox
}

DEFINE_CONSTANT
LONG TLID_POLL    = 1
LONG TLID_REFRESH = 2
LONG TLID_COMMS0 = 10
LONG TLID_COMMS1 = 11
LONG TLID_COMMS2 = 12
LONG TLID_COMMS3 = 13
LONG TLID_COMMS4 = 14
LONG TLID_COMMS5 = 15

DEFINE_VARIABLE
uSkyBox mySkyBoxs[5]
uPanel  mySkyTPs[25]
INTEGER DEBUG

LONG 	  TLT_POLL[]  = { 30000 }	// Polling Interval for Dusky
LONG 	  TLT_COMMS[] = { 300000 }	// Flag boxes as No Comms after 5 mins
LONG 	  TLT_FAIL[] = {500}
LONG 	  TLT_REFRESH[] = {100}

/******************************************************************************
	System Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(CHAR Msg[], CHAR MsgData[]){
	 IF(DEBUG = 1)SEND_STRING 0:0:0, "ITOA(GET_LAST(vdvSkyBox)),':',Msg, ':', MsgData"
}
/******************************************************************************
	User Interface Helper Functions
******************************************************************************/
DEFINE_FUNCTION fnSendCommand(INTEGER pBOX, INTEGER pCMD){
	STACK_VAR CHAR ToSend
	ToSend = $FF
	SWITCH(pCMD){
		CASE 1:	ToSend = $3E //Play		 		[1]
		CASE 2:	ToSend = $3F // Stop 			[2]
		CASE 3:	ToSend = $24 // Pause	 		[3]
		CASE 4:	ToSend = $28 // Fastforward	[4]
		CASE 5:	ToSend = $3D // Rewind			[5]
		CASE 8:	ToSend = $40 // Record			[8]
		CASE 9:	ToSend = $0C // Power			[9]

		CASE 10:	ToSend = $00 // Digit 0	[10]
		CASE 11:	ToSend = $01 // Digit 1	[11]
		CASE 12:	ToSend = $02 // Digit 2	[12]
		CASE 13:	ToSend = $03 // Digit 3	[13]
		CASE 14:	ToSend = $04 // Digit 4	[14]
		CASE 15:	ToSend = $05 // Digit 5	[15]
		CASE 16:	ToSend = $06 // Digit 6	[16]
		CASE 17:	ToSend = $07 // Digit 7	[17]
		CASE 18:	ToSend = $08 // Digit 8	[18]
		CASE 19:	ToSend = $09 // Digit 9	[19]

		CASE 49:	ToSend = $5C // Select	[49]
		CASE 22:	ToSend = $20 // Chan Up	[22]
		CASE 23:	ToSend = $21 // Chan Down [23]

		CASE 45:	ToSend = $58 // Up			[45]
		CASE 48:	ToSend = $5B // Right		[48]
		CASE 46:	ToSend = $59 // Down		[46]
		CASE 47:	ToSend = $5A // Left		[47]
		CASE 81:	ToSend = $83 // Backup	[81]
		CASE 101:ToSend = $CB // Info	[101]
		CASE 105:ToSend = $CC // TV Guide [105]
		CASE 113:ToSend = $81 // Help	[113]

		CASE 201:ToSend = $80 // SKY Button	[201]
		CASE 202:ToSend = $6D // RED				[202]
		CASE 203:ToSend = $6E // GREEN			[203]
		CASE 204:ToSend = $6F // YELLOW			[204]
		CASE 205:ToSend = $70 // BLUE			[205]
		CASE 206:ToSend = $3C // TEXT			[206]

		CASE 210:ToSend = $84 // TV				[210]
		CASE 211:ToSend = $7D // Box Office	[211]
		CASE 212:ToSend = $7E // Services		[212]
		CASE 213:ToSend = $F5 // Interactive	[213]
	}
	IF(ToSend <> $FF){
		fnDebug("'->Dusky_',ITOA(pBOX)","$43,pBOX - 1,$0C,ToSend")
		SEND_STRING dvDusky, "$43,pBOX - 1,$0C,ToSend"
	}
}
DEFINE_FUNCTION fnSendChannel(INTEGER pBOX, INTEGER pCHAN, INTEGER pRADIO){
	STACK_VAR CHAR _CHAN[3]
	_CHAN = fnPadLeadingChars( ITOA(pCHAN),'0',3)
	IF(pRADIO){ SEND_STRING dvDusky, "$43,pBOX - 1,$0C,$00" }
	SEND_STRING dvDusky, "$43,pBOX - 1,$0C,ATOI("GET_BUFFER_CHAR(_CHAN)"),$00"
	SEND_STRING dvDusky, "$43,pBOX - 1,$0C,ATOI("GET_BUFFER_CHAR(_CHAN)"),$00"
	SEND_STRING dvDusky, "$43,pBOX - 1,$0C,ATOI("GET_BUFFER_CHAR(_CHAN)"),$00"
}
/******************************************************************************
	User Interface Events
******************************************************************************/
DEFINE_CONSTANT
INTEGER btnSelectBox[] = {500,501,502,503,504,505}

DEFINE_EVENT BUTTON_EVENT[tp,btnSelectBox]{
	PUSH:{
		mySkyTPs[GET_LAST(tp)].BOX = GET_LAST(btnSelectBox) - 1
		fnRefreshPanel(GET_LAST(tp))
	}
}

DEFINE_EVENT BUTTON_EVENT[tp,0]{
	PUSH:{
		STACK_VAR INTEGER _BOX
		_BOX = mySkyTPs[GET_LAST(tp)].BOX
		SELECT{
			ACTIVE(BUTTON.INPUT.CHANNEL < 500):{ fnSendCommand(_BOX,BUTTON.INPUT.CHANNEL)   }
			ACTIVE(BUTTON.INPUT.CHANNEL < 1000):{ 			}
			ACTIVE(BUTTON.INPUT.CHANNEL < 2001):{ fnSendChannel(_BOX,BUTTON.INPUT.CHANNEL - 1000,FALSE) }
			ACTIVE(BUTTON.INPUT.CHANNEL < 3001):{ fnSendChannel(_BOX,BUTTON.INPUT.CHANNEL - 2000,TRUE) }
		}
	}

	/*HOLD[3,REPEAT]:{
		STACK_VAR INTEGER _BOX
		_BOX = mySkyTPs[GET_LAST(tp)].BOX
		IF(_BOX != 0){
			IF(BUTTON.INPUT.CHANNEL < 1001 && BUTTON.HOLDTIME > 5){ fnSendCommand(_BOX,BUTTON.INPUT.CHANNEL)   }
		}
	}*/
}

DEFINE_PROGRAM{
	STACK_VAR INTEGER p
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		IF(mySkyTPs[p].BOX){
			STACK_VAR INTEGER b
			FOR(b = 1; b <= 999; b++){
				[tp[p],b+1000] = (ATOI(mySkyBoxs[mySkyTPs[p].BOX].CHANNUM) == b)
			}
		}
	}
}

DEFINE_EVENT DATA_EVENT[tp]{
	ONLINE:fnRefreshPanel(GET_LAST(tp))
}
/******************************************************************************
	Box Control Events
******************************************************************************/
DEFINE_EVENT DATA_EVENT[vdvSkyBox]{
	COMMAND:{
		STACK_VAR INTEGER _BOX
		_BOX = GET_LAST(vdvSkyBox)
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'POWER':{
				IF(DATA.TEXT = 'ON'){  IF(!mySkyBoxs[_BOX].POWER){ fnSendCommand(_BOX,201) } }
				IF(DATA.TEXT = 'OFF'){ IF(mySkyBoxs[_BOX].POWER){  fnSendCommand(_BOX,9) } }
			}
			CASE 'CHANNEL':{
				IF(!mySkyBoxs[_BOX].POWER){ fnSendCommand(_BOX,201) }
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'RADIO':fnSendChannel(_BOX,ATOI(DATA.TEXT),TRUE)
					CASE 'TV':	 fnSendChannel(_BOX,ATOI(DATA.TEXT),FALSE)
				}
			}
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':DEBUG = (DATA.TEXT == 'TRUE')
				}
			}
		}
	}
}
DEFINE_EVENT CHANNEL_EVENT[vdvSkyBox,0]{
	ON:{
		STACK_VAR CHAR ToSend
		ToSend = $FF
		SWITCH(CHANNEL.CHANNEL){
			CASE 22:	ToSend = $20 // Chan Up	[22]
			CASE 23:	ToSend = $21 // Chan Down [23]

			CASE 45:	ToSend = $58 // Up			[45]
			CASE 48:	ToSend = $5B // Right		[48]
			CASE 46:	ToSend = $59 // Down		[46]
			CASE 47:	ToSend = $5A // Left		[47]
			CASE 49:	ToSend = $5C // Select	[49]
		}
		IF(ToSend <> $FF){ SEND_STRING dvDusky, "$43,GET_LAST(vdvSkyBox) - 1,$0C,ToSend" }
	}
}
/******************************************************************************
	Dusky Control
******************************************************************************/
DEFINE_EVENT DATA_EVENT[dvDusky]{
	ONLINE:{
		SEND_COMMAND dvDusky, 'SET BAUD 57600 N 8 1 485 DISABLE'
		SEND_STRING dvDusky, 'p'
		TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
	}
	STRING:{
		IF(DATA.TEXT == "'OK',$0D,$0A"){
			IF(TIMELINE_ACTIVE(TLID_COMMS0)){TIMELINE_KILL(TLID_COMMS0)}
			TIMELINE_CREATE(TLID_COMMS0,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	SEND_STRING dvDusky, 'p'
}
DEFINE_PROGRAM{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(vdvSkyBox); x++){
		[vdvSkyBox[x],251] = (TIMELINE_ACTIVE(TLID_COMMS0))		// Dusky - All
		[vdvSkyBox[x],252] = (TIMELINE_ACTIVE(TLID_COMMS0+x))	// FB Recieved
	}
}
/******************************************************************************
	Feedback Handling
******************************************************************************/
DEFINE_FUNCTION fnProcessWholePacket(INTEGER pBOX, CHAR pDATA[]){			// Chew up the packet
	fnDebug('fnProcessWholePacket','Start')
	GET_BUFFER_CHAR(pDATA)					// Chew off $0A
	pDATA = fnStripCharsRight(pDATA,2)	// Bite off Checksum
	GET_BUFFER_STRING(pDATA,3)				// Chew off Packet Length
	WHILE(LENGTH_ARRAY(pDATA)){
		STACK_VAR CHAR _COMMAND[4]
		STACK_VAR INTEGER _LEN
		_COMMAND = GET_BUFFER_STRING(pDATA,4)
		_LEN = ATOI(GET_BUFFER_STRING(pDATA,3))
		fnProcessFeedback(pBOX,_COMMAND,GET_BUFFER_STRING(pDATA,_LEN-7))
	}
	fnDebug('fnProcessWholePacket','End')
}
DEFINE_FUNCTION fnProcessFeedback(INTEGER pBOX,CHAR pCMD[],CHAR pVAL[]){
	fnDebug('fnProcessFeedback','Start')
	fnDebug("'Sky',ITOA(pBOX),'->'","pCMD,':',pVAL")
	SWITCH(pCMD){
		CASE 'CEER':{fnChanError(pBox)}
		CASE 'CE00':
		CASE 'SSCN':{
			mySkyBoxs[pBOX].CHANNUM  = fnTidyChan(pVAL);
			fnChanSend(pBox)
			mySkyBoxs[pBox].POWER = TRUE
		}
		CASE 'SSCA':{mySkyBoxs[pBOX].CHANNAME = fnTidyStr(pVAL);	mySkyBoxs[pBox].newData = TRUE;}
		CASE 'SST0':{mySkyBoxs[pBOX].STARTED  = pVAL;				mySkyBoxs[pBox].newData = TRUE;}
		CASE 'SSN0':{mySkyBoxs[pBOX].PROGNAME = fnTidyStr(pVAL);	mySkyBoxs[pBox].newData = TRUE;}
		CASE 'SSE0':{mySkyBoxs[pBOX].PROGDESC = fnTidyStr(pVAL);	mySkyBoxs[pBox].newData = TRUE;}
		CASE 'SYST':{
			mySkyBoxs[pBox].POWER 	 = !ATOI(pVAL);
			IF(!mySkyBoxs[pBox].POWER){
				mySkyBoxs[pBOX].CHANNUM  = ''
				mySkyBoxs[pBOX].CHANNAME = ''
				mySkyBoxs[pBOX].STARTED  = ''
				mySkyBoxs[pBOX].PROGNAME = ''
				mySkyBoxs[pBOX].PROGDESC = ''
				mySkyBoxs[pBox].newData  = TRUE;
			}
		}
		CASE 'SSDT':{} // System Time
		CASE 'SYIC':{} // Protected Channel
		CASE 'SYFS':{} // Audio Unavil
		CASE 'SYD1':{} // System Message
		CASE 'PUSP':{} // Signal Error
		CASE 'PUCP':{} // Subscribe Error
		CASE 'SYIA':{} // 'Red' Button Active
		CASE 'SSEI':{} // Sky Plus Operations
	}
	IF(TIMELINE_ACTIVE(TLID_REFRESH)){TIMELINE_KILL(TLID_REFRESH)}
	TIMELINE_CREATE(TLID_REFRESH,TLT_REFRESH,LENGTH_ARRAY(TLT_REFRESH),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
	fnDebug('fnProcessFeedback','End')
}
DEFINE_EVENT TIMELINE_EVENT[TLID_REFRESH]{
	STACK_VAR INTEGER x;
	FOR(x = 1; x <= LENGTH_ARRAY(tp); x++){
		IF(mySkyTPs[x].BOX){
			IF(mySkyBoxs[mySkyTPs[x].BOX].newData){
				fnRefreshPanel(x)
			}
		}
	}
	FOR(x = 1; x <= LENGTH_ARRAY(vdvSkyBox); x++){
		mySkyBoxs[x].newData = FALSE
	}
}

DEFINE_FUNCTION fnChanSend(INTEGER pBOX){
	STACK_VAR INTEGER p;
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		IF(mySkyTPs[p].BOX == pBOX){
			SEND_COMMAND tp[p],"'^TXT-1,0,',mySkyBoxs[pBOX].CHANNUM"
		}
	}
}
DEFINE_FUNCTION fnChanError(INTEGER pBOX){
	STACK_VAR INTEGER p;
	FOR(p = 1; p <= LENGTH_ARRAY(tp); p++){
		IF(mySkyTPs[p].BOX == pBOX){
			SEND_COMMAND tp[p],"'^TXT-1,0,ERR'"
		}
	}
}
DEFINE_FUNCTION fnRefreshPanel(p){
	IF(mySkyTPs[p].BOX){
		SEND_COMMAND tp[p],"'^TXT-1,0,',mySkyBoxs[mySkyTPs[p].BOX].CHANNUM"
		SEND_COMMAND tp[p],"'^TXT-2,0,',mySkyBoxs[mySkyTPs[p].BOX].CHANNAME"
		SEND_COMMAND tp[p],"'^TXT-3,0,',mySkyBoxs[mySkyTPs[p].BOX].PROGDESC"
		SEND_COMMAND tp[p],"'^TXT-4,0,',mySkyBoxs[mySkyTPs[p].BOX].PROGNAME"
		SEND_COMMAND tp[p],"'^TXT-5,0,Started: ',mySkyBoxs[mySkyTPs[p].BOX].STARTED"
	}
	ELSE{
		SEND_COMMAND tp[p],"'^TXT-1,0,'"
		SEND_COMMAND tp[p],"'^TXT-2,0,'"
		SEND_COMMAND tp[p],"'^TXT-3,0,'"
		SEND_COMMAND tp[p],"'^TXT-4,0,'"
		SEND_COMMAND tp[p],"'^TXT-5,0,'"
	}
}

DEFINE_FUNCTION CHAR[300] fnTidyStr(CHAR _str[]){
	 STACK_VAR INTEGER i;
	 STACK_VAR CHAR _rtn[300];
	 FOR(i=1;i<LENGTH_ARRAY(_str)+1;i++){
		  IF(_str[i] >= $20 && _str[i] <= $7E){
				_rtn = "_rtn,_str[i]"
		  }
	 }
	 RETURN _rtn;
}
DEFINE_FUNCTION CHAR [4] fnTidyChan(CHAR _str[]){
	 IF(_str[1] = '0' || _str[1] = $7F){
		  _str[1] = 'R';
		  RETURN _str;
	 }
	 ELSE RETURN _str
}
DEFINE_FUNCTION CHAR[2] fnGetChecksum(CHAR pData[1000]){
	STACK_VAR INTEGER chk
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(pDATA); x++){
		chk = chk + pData[x]
	}
	RETURN(LOWER_STRING(RIGHT_STRING(ITOHEX(chk),2)))
}
DEFINE_START{
	STACK_VAR INTEGER x
	FOR(x = 1; x <= LENGTH_ARRAY(dvSkyFB); x++){
		CREATE_BUFFER dvSkyFB[x], mySkyBoxs[x].Rx
	}
}
DEFINE_EVENT DATA_EVENT[dvSkyFB]{
	ONLINE:{
		SEND_COMMAND DATA.DEVICE, 'SET BAUD 57600 N 8 1 485 DISABLE'
	}
	STRING:{
		STACK_VAR INTEGER _BOX
		_BOX = GET_LAST(dvSkyFB)
		fnDebug('FB',DATA.TEXT)
		//fnDebug('Rx',mySkyBoxs[_BOX].Rx)
		WHILE(LENGTH_ARRAY(mySkyBoxs[_BOX].Rx)){
			fnDebug('WHILE','String FB')
			IF(mySkyBoxs[_BOX].Rx[1] != $0A){ GET_BUFFER_CHAR(mySkyBoxs[_BOX].Rx) }
			ELSE IF(LENGTH_ARRAY(mySkyBoxs[_BOX].Rx > 4)){
				STACK_VAR INTEGER _LEN
				_LEN = ATOI(MID_STRING(mySkyBoxs[_BOX].Rx,2,3))
				fnDebug('_LEN',ITOA(_LEN))
				IF(LENGTH_ARRAY(mySkyBoxs[_BOX].Rx) >= _LEN+1){
					STACK_VAR CHAR Lump[1000]
					STACK_VAR CHAR Chk[2]
					Lump = GET_BUFFER_STRING(mySkyBoxs[_BOX].Rx,_LEN+1)
					Chk = RIGHT_STRING(Lump,2)
					//fnDebug('Actual',Chk);
					//fnDebug('Calced',fnGetChecksum(LEFT_STRING(Lump,_LEN-1)));
					IF(Chk == fnGetChecksum(LEFT_STRING(Lump,_LEN-1))){
						fnDebug('Calling','fnProcessWholePacket')
						fnProcessWholePacket(_BOX,Lump)
						fnDebug('Checking','TIMELINE_ACTIVE')
						IF(TIMELINE_ACTIVE(TLID_COMMS0+_BOX)){TIMELINE_KILL(TLID_COMMS0+_BOX)}
						fnDebug('Calling','TIMELINE_CREATE')
						TIMELINE_CREATE(TLID_COMMS0+_BOX,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
					}
					ELSE{
						fnDebug('Clearing','mySkyBoxs[_BOX].Rx')
						mySkyBoxs[_BOX].Rx = ''
					}
				}
				ELSE{fnDebug('FB Break','Not Long Enough'); BREAK }
			}
			ELSE{fnDebug('FB Break','No Len Yet'); BREAK }
		}
	}
}