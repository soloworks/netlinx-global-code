MODULE_NAME='Pioneer BDP-LX'(DEV vdvControl, DEV dvRS232)

INCLUDE 'CustomFunctions'
INCLUDE 'SNAPI'

DEFINE_CONSTANT
_MODEL_LX52 = 0
_MODEL_LX54 = 1

DEFINE_VARIABLE
INTEGER _MODEL = 0
CHAR _ResponseBuffer[500]

DEFINE_START{
	CREATE_BUFFER dvRS232, _ResponseBuffer
}

DEFINE_EVENT DATA_EVENT[dvRS232]{
	ONLINE:{
		SEND_COMMAND dvRS232, 'SET MODE DATA'
		SWITCH(_MODEL){
			CASE _MODEL_LX52:SEND_COMMAND dvRS232, 'SET BAUD 115200 N 8 1 485 DISABLE'
			CASE _MODEL_LX54:SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
		}
	}
	STRING:{

	}
}

DEFINE_FUNCTION fnSendCommand(CHAR cmd[]){
	 SEND_STRING dvRS232, "cmd, $0D"
}

DEFINE_EVENT CHANNEL_EVENT[vdvControl,0]{
	 ON:{
		  SWITCH(CHANNEL.CHANNEL){
				CASE MENU_UP:			fnSendCommand('/A184FFFF/RU')
				CASE MENU_RT:			fnSendCommand('/A186FFFF/RU')
				CASE MENU_LT:			fnSendCommand('/A187FFFF/RU')
				CASE MENU_DN:			fnSendCommand('/A185FFFF/RU')
				CASE MENU_SELECT:		fnSendCommand('/A181AFEF/RU')

		  }
	 }
}

DEFINE_EVENT DATA_EVENT[vdvControl]{
	 COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'MODEL':{
						SWITCH(DATA.TEXT){
							CASE 'LX52':_MODEL = _MODEL_LX52
							CASE 'LX54':_MODEL = _MODEL_LX54
						}
						SWITCH(_MODEL){
							CASE _MODEL_LX52:SEND_COMMAND dvRS232, 'SET BAUD 115200 N 8 1 485 DISABLE'
							CASE _MODEL_LX54:SEND_COMMAND dvRS232, 'SET BAUD 9600 N 8 1 485 DISABLE'
						}
					}
				}
			}
			CASE 'RAW':{
				fnSendCommand(DATA.TEXT)
			}
			CASE 'POWER':{
				SWITCH(DATA.TEXT){
					CASE 'ON':			fnSendCommand('/A181AFBA/RU')
					CASE 'OFF':			fnSendCommand('/A181AFBB/RU')
				}
			}
			CASE 'MENU':{
				SWITCH(DATA.TEXT){
					CASE 'UP':			fnSendCommand('/A184FFFF/RU')
					CASE 'RIGHT':		fnSendCommand('/A186FFFF/RU')
					CASE 'LEFT':		fnSendCommand('/A187FFFF/RU')
					CASE 'DOWN':		fnSendCommand('/A185FFFF/RU')
					CASE 'ENTER':		fnSendCommand('/A181AFEF/RU')
					CASE 'MENU':		fnSendCommand('/A181AFB9/RU')
					CASE 'TOP':			fnSendCommand('/A181AFB4/RU')
					CASE 'HOME':		fnSendCommand('/A181AFB0/RU')
					CASE 'SUBTITLE':	fnSendCommand('/A181AF36/RU')
					CASE 'RETURN':		fnSendCommand('/A181AFF4/RU')
					CASE 'RED':			fnSendCommand('/A181AF64/RU')
					CASE 'GREEN':		fnSendCommand('/A181AF65/RU')
					CASE 'YELLOW':		fnSendCommand('/A181AF67/RU')
					CASE 'BLUE':		fnSendCommand('/A181AF66/RU')
					CASE 'DISPLAY':	fnSendCommand('/A181AFE3/RU')
					CASE 'POPUP':		fnSendCommand('/A181AFB9/RU')
				}
			}
			CASE 'TRANSPORT':{
				SWITCH(DATA.TEXT){
					CASE 'PLAY':		fnSendCommand('/A181AF39/RU')
					CASE 'PAUSE':		fnSendCommand('/A181AF3A/RU')
					CASE 'STOP':		fnSendCommand('/A181AF38/RU')
					CASE 'SKIP+':		fnSendCommand('/A181AF3D/RU')
					CASE 'SKIP-':		fnSendCommand('/A181AF3E/RU')
					CASE 'SCAN+': 		fnSendCommand('/A181AFE9/RU')
					CASE 'SCAN-': 		fnSendCommand('/A181AFEA/RU')
				}
			}
		}
	}
}