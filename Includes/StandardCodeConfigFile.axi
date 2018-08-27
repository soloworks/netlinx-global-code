PROGRAM_NAME='StandardCodeConfigFile'
/******************************************************************************
	Include file for Configuration File Handling
******************************************************************************/
DEFINE_CONSTANT
CHAR LOAD_CONFIG_MISSING[] = 'CONFIG ERROR: File Not Found'
CHAR LOAD_CONFIG_MULTI[]   = 'CONFIG ERROR: Multiple File Matches Found'
CHAR LOAD_CONFIG_ERROR[]   = 'CONFIG ERROR: Unknown File Processing Error'

DEFINE_FUNCTION CHAR[200] fnLoadConfigFile(CHAR pFileExt[]){
	STACK_VAR CHAR FileName[255]
	STACK_VAR SLONG TotalFilesInDir
	STACK_VAR SLONG ConfigFilesFound
 	STACK_VAR SLONG Entry
	STACK_VAR INTEGER x
	TotalFilesInDir = 1
	Entry = 1

	// Skim file list to see what files are there
	WHILE(TotalFilesInDir > 0){
		TotalFilesInDir = FILE_DIR('.',FileName,Entry)
		Entry++
		IF(LOWER_STRING(RIGHT_STRING(FileName,LENGTH_ARRAY(pFileExt))) == LOWER_STRING(pFileExt)){
			ConfigFilesFound++
		}
	}

	// Throw error if no config found
	IF(ConfigFilesFound == 0){
		SEND_STRING 0, 'LoadConfigFile: Not Found'
		RETURN LOAD_CONFIG_MISSING
	}

	// Throw error if multiple configs found
	IF(ConfigFilesFound > 1){
		SEND_STRING 0, 'LoadConfigFile: Multiple Found'
		RETURN LOAD_CONFIG_MULTI
	}

	// Process single config
	TotalFilesInDir = 1
	Entry = 1
	WHILE(TotalFilesInDir > 0){
		TotalFilesInDir = FILE_DIR('.',FileName,Entry)
		Entry++
		IF(LOWER_STRING(RIGHT_STRING(FileName,LENGTH_ARRAY(pFileExt))) == LOWER_STRING(pFileExt)){
			SEND_STRING 0, "'LoadConfigFile: ',FileName"
			SWITCH(fnProcessConfigFile(FileName)){
				CASE TRUE:  RETURN FileName
				CASE FALSE: RETURN LOAD_CONFIG_ERROR
			}
		}
	}
}

//config is processed by the setting type and assigned to the appropriate room config strucutre
DEFINE_FUNCTION INTEGER fnProcessConfigFile(CHAR pFileName[200]){
	STACK_VAR SLONG slFileHandle
	STACK_VAR CHAR  thisLine[1000]
	STACK_VAR INTEGER _LINE
	// Load Config
	slFileHandle = FILE_OPEN(pFileName,FILE_READ_ONLY)

	IF(slFileHandle > 0){
		STACK_VAR SLONG readRESULT
		SEND_STRING 0, "'LoadConfigFile: Start Of File'"
		_LINE = 1
		readRESULT = FILE_READ_LINE(slFileHandle,thisLine,MAX_LENGTH_ARRAY(thisLine))
		WHILE(readRESULT >= 0){
			SEND_STRING 0, "'LoadConfigFile: Line ',FORMAT('%03d',_LINE),':',thisLine"
			thisLine = fnRemoveWhiteSpace(thisLine)

			IF(thisLine[1] == '#'){
				// Comment Line, Do Nothing
			}
			ELSE IF(FIND_STRING(thisLine,'=',1)){
				// Local Variables
				STACK_VAR CHAR pSetting[255]
				STACK_VAR CHAR pValue[255]
				// Get Setting
				pSetting = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(thisLine,'=',1),1))
				// Get Value
				// If a comment is present, strip it (Check for space ahead)
				IF(FIND_STRING(thisLine,"$20,'//'",1)){
					thisLine = fnStripCharsRight(REMOVE_STRING(thisline,"$20,'//'",1),2)
				}
				// If a comment is present, strip it (Check for tab ahead)
				IF(FIND_STRING(thisLine,"$09,'//'",1)){
					thisLine = fnStripCharsRight(REMOVE_STRING(thisline,"$09,'//'",1),2)
				}
				// Get rid of white space
				pValue = fnRemoveWhiteSpace(thisLine)
				// Callback Setting Processing
				fnProcessConfigSetting(pSetting,pValue)
			}
			_LINE++
			readRESULT = FILE_READ_LINE(slFileHandle,thisLine,MAX_LENGTH_ARRAY(thisLine))
		}
		FILE_CLOSE(slFileHandle)
		SEND_STRING 0, "'LoadConfigFile: End Of File'"
		RETURN TRUE
	}
	ELSE{
		SEND_STRING 0, "'LoadConfigFile: FILE_OPEN ERROR ',ITOA(slFileHandle)"
		RETURN FALSE
	}
}

DEFINE_FUNCTION fnUpdateConfigFileSetting(CHAR pFileName[], CHAR pSetting[], CHAR pValue[]){

	SEND_STRING 0, "'UpdateConfigFile: ',pFileName"

	// Bail if config file isn't loaded
	SWITCH(pFileName){
		CASE LOAD_CONFIG_MISSING:
		CASE LOAD_CONFIG_ERROR:
		CASE LOAD_CONFIG_MULTI:{
			RETURN
		}
	}


}

DEFINE_FUNCTION INTEGER fnIsConfigFileValid(pFileName){
// Bail if config file isn't loaded
	SWITCH(pFileName){
		CASE LOAD_CONFIG_MISSING:
		CASE LOAD_CONFIG_ERROR:
		CASE LOAD_CONFIG_MULTI:{
			RETURN FALSE
		}
	}
	RETURN TRUE
}
/******************************************************************************
	EoF
******************************************************************************/