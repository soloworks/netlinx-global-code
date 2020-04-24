MODULE_NAME='mZeeVeeZvMXEPlus'(DEV vdvControl, DEV ipHTTP)
/******************************************************************************
	Control of ZeeVee ZvMXE+ IPTV Decoder via HTTP
	ToDo:
	- Extract Channel List
	- Send Channel
	- Store last channel, recall with CHAN-PREVIOUS
******************************************************************************/
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
INCLUDE 'HTTP'
DEFINE_FUNCTION eventHTTPResponse(uHTTPResponse r){}
/******************************************************************************
	EoF
******************************************************************************/
