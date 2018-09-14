MODULE_NAME='mCYPAmp'(DEV vdvControl, DEV ipDevice)
INCLUDE 'CustomFunctions'
/******************************************************************************
	By Solo Works (www.soloworks.co.uk)
	
	IP or RS232 control
******************************************************************************/
/******************************************************************************
	Module Structure
******************************************************************************/
DEFINE_TYPE STRUCTURE uZone{
	// Status
	INTEGER  POWER
	INTEGER  CUR_INPUT
	INTEGER  NEW_INPUT
	INTEGER  MUTE
	INTEGER  STEP
	// Status
	SINTEGER CUR_VOL
	SLONG    CUR_VOL_255
	SINTEGER	NEW_VOL
	INTEGER	VOL_PEND
	SINTEGER RANGE[2]
}
