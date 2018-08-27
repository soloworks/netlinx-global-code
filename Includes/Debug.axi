PROGRAM_NAME='Debug'

/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_CONSTANT
INTEGER DEBUG_ERR = 0
INTEGER DEBUG_STD = 1
INTEGER DEBUG_DEV = 2
INTEGER DEBUG_LOG = 3

DEFINE_TYPE STRUCTURE uDebug{
	INTEGER LOG_LEVEL
	CHAR    UID[30]
}
/******************************************************************************
	Debugging Utlity Functions
******************************************************************************/
DEFINE_FUNCTION fnDebug(uDebug d, INTEGER l, CHAR pMsg[]){
	STACK_VAR INTEGER x
	STACK_VAR CHAR pMsgCopy[10000]
	pMsgCopy = pMsg
	IF(d.log_level >= l){
		WHILE(LENGTH_ARRAY(pMsgCopy) || !x){
			SEND_STRING 0, "d.uid,'[',FORMAT('%02d',x),']->',GET_BUFFER_STRING(pMsgCopy,100)"
			x++
		}
	}
}
DEFINE_FUNCTION fnDebugHTTP(uDebug d, INTEGER l, CHAR pData[10000]){
	STACK_VAR CHAR myData[10000]
	myData = pData
	fnDebug(d,DEBUG_DEV,"'fnDebugHTTP Called'")
	IF(d.log_level >= l){

		WHILE(FIND_STRING(myData,"$0D,$0A,$0D,$0A",1)){
			fnDebug(d,l,"'HEADER->',REMOVE_STRING(myData,"$0D,$0A",1)")
		}
		// Body
		fnDebug(d,l,"'BODY->',myData")

	}
	fnDebug(d,DEBUG_DEV,"'fnDebugHTTP Ended'")
}
/******************************************************************************
	EoF
******************************************************************************/