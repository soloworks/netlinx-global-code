MODULE_NAME='mEmulatorGain'(DEV vdvGain)
INCLUDE 'CustomFunctions'
DEFINE_TYPE STRUCTURE uAudio{
	INTEGER  MUTE
	SINTEGER GAIN
	SINTEGER	STEP
	SINTEGER RANGE[2]
}

DEFINE_VARIABLE
VOLATILE uAudio myAudio

DEFINE_EVENT DATA_EVENT[vdvGain]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'RANGE':{
						myAudio.RANGE[1] = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1))
						myAudio.RANGE[2] = ATOI(DATA.TEXT)
						SEND_STRING vdvGain,"'RANGE-',ITOA(myAudio.RANGE[1]),',',ITOA(myAudio.RANGE[2])"
					}
					CASE 'STEP':{
						myAudio.STEP = ATOI(DATA.TEXT)
					}
				}
			}
			CASE 'VOLUME':{
				IF(myAudio.STEP == 0){myAudio.STEP = 1}
				SWITCH(DATA.TEXT){
					CASE 'INC':	myAudio.GAIN = myAudio.GAIN + myAudio.STEP
					CASE 'DEC':	myAudio.GAIN = myAudio.GAIN - myAudio.STEP
					DEFAULT:		myAudio.GAIN = ATOI(DATA.TEXT)
				}

				IF(myAudio.GAIN < myAudio.RANGE[1]){ myAudio.GAIN = myAudio.RANGE[1] }
				IF(myAudio.GAIN > myAudio.RANGE[2]){ myAudio.GAIN = myAudio.RANGE[2] }
			}
			CASE 'MUTE':
			CASE 'MICMUTE':{
				SWITCH(DATA.TEXT){
					CASE 'ON': 		myAudio.MUTE = TRUE
					CASE 'OFF':		myAudio.MUTE = FALSE
					CASE 'TOGGLE':	myAudio.MUTE = !myAudio.MUTE
				}
			}
		}
	}
}

DEFINE_PROGRAM{
	SEND_LEVEL vdvGain,1,myAudio.GAIN
	[vdvGain,198] = (myAudio.MUTE)
	[vdvGain,199] = (myAudio.MUTE)
}