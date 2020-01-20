MODULE_NAME='mDataPathIolite'(DEV vdvServer, DEV vdvWall[], DEV ipServer)
/******************************************************************************
	DataPath iolite 600/10x Control Module
******************************************************************************/
INCLUDE 'CustomFunctions'
INCLUDE 'Debug'
/******************************************************************************
	Module Structures
******************************************************************************/
DEFINE_CONSTANT
INTEGER MAX_WINDOWS = 8
INTEGER MAX_WALLS   = 8
INTEGER MAX_LAYOUTS = 8
INTEGER MAX_ARGS    = 8

// Key Pair Structure
DEFINE_TYPE STRUCTURE uArg{
	CHAR Key[30]
	CHAR Val[30]
	INTEGER QuoteValue
}
// CLI Command Structure
DEFINE_TYPE STRUCTURE uCli{
	CHAR    WallID[50]
	uArg    Arg[MAX_ARGS]
}
// Window Structure
DEFINE_TYPE STRUCTURE uWindow{
	INTEGER Width
	INTEGER Height
	CHAR    Stream[255]
	INTEGER Input
	CHAR    Image[255]
}
// Wall Structure
DEFINE_TYPE STRUCTURE uWall{
	CHAR       ID[50]
	CHAR       Name[50]
	INTEGER    Port
	INTEGER    CliPort
	INTEGER    AutoStart
	INTEGER    IsPartition
	INTEGER    IsBlueprint
	CHAR       CurrentState[20]
	CHAR       OperationState[20]
	INTEGER    x
	INTEGER    y
	INTEGER 	  h
	INTEGER    w
	CHAR       Layouts[MAX_LAYOUTS][30]
	uWindow    Window[MAX_WINDOWS]
}
// Connection Structure
DEFINE_TYPE STRUCTURE uConn{
	(** IP Comms Control **)
	INTEGER STATE
	INTEGER IP_PORT
	CHAR	  IP_HOST[255]
	INTEGER isIP
	(** General Comms Control **)
	uCli    CurrentCLI
	CHAR 	  Rx[2000]
	//INTEGER RTS		// Ready To Send
	uDebug  DEBUG
	CHAR 	  PASSWORD[20]
}
// System Structure
DEFINE_TYPE STRUCTURE uVidWall{
	uConn   Conn
	uWall   Wall[MAX_WALLS]
	CHAR	  Model[25]
	CHAR    WallNameRefs[MAX_WALLS][50]
}

/******************************************************************************
	Module Constants
******************************************************************************/
DEFINE_CONSTANT
// Connection States
INTEGER CONN_STATE_OFFLINE		  = 0
INTEGER CONN_STATE_CONNECTING	  = 1
INTEGER CONN_STATE_NEGOTIATING  = 2
INTEGER CONN_STATE_CONNECTED	  = 3
// Timelines
LONG TLID_RETRY		= 1
LONG TLID_COMMS		= 2
LONG TLID_CHAN			= 3
LONG TLID_POLL			= 4
/******************************************************************************
	Module Variable
******************************************************************************/
DEFINE_VARIABLE
(** General **)
uVidWall   myVidWall
(** Timeline Times **)
LONG TLT_RETRY[]		= {  5000 }
LONG TLT_COMMS[]		= { 60000 }
LONG TLT_POLL[]		= { 15000 }
/******************************************************************************
	Helper Functions - Connection
******************************************************************************/
// Open connection to the server
DEFINE_FUNCTION fnOpenTCPConnection(){
	IF(myVidWall.CONN.IP_HOST == ''){
		fnDebug(myVidWall.Conn.Debug,DEBUG_ERR,'iolite IP Not Set')
	}
	ELSE{
		fnDebug(myVidWall.Conn.Debug,DEBUG_STD,"'Connecting to iolite ',myVidWall.CONN.IP_HOST,':',ITOA(myVidWall.CONN.IP_PORT)")
		IF(myVidWall.CONN.STATE == CONN_STATE_OFFLINE){
			myVidWall.CONN.STATE = CONN_STATE_CONNECTING
			IP_CLIENT_OPEN(ipServer.PORT, myVidWall.CONN.IP_HOST, myVidWall.CONN.IP_PORT, IP_TCP)
		}
	}
}

// Close TCP connection to server
DEFINE_FUNCTION fnCloseTCPConnection(){
	IP_CLIENT_CLOSE(ipServer.PORT)
}

// Queue a call to open connection to server
DEFINE_FUNCTION fnTryConnection(){
	IF(TIMELINE_ACTIVE(TLID_RETRY)){TIMELINE_KILL(TLID_RETRY)}
	TIMELINE_CREATE(TLID_RETRY,TLT_RETRY,LENGTH_ARRAY(TLT_RETRY),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
}

// Timeline action for above fnTryConnection()
DEFINE_EVENT TIMELINE_EVENT[TLID_RETRY]{
	fnOpenTCPConnection()
}

// Create or Reset polling timeline
DEFINE_FUNCTION fnInitPoll(){
	IF(TIMELINE_ACTIVE(TLID_POLL)){ TIMELINE_KILL(TLID_POLL) }
	TIMELINE_CREATE(TLID_POLL,TLT_POLL,LENGTH_ARRAY(TLT_POLL),TIMELINE_ABSOLUTE,TIMELINE_REPEAT)
}

// Timeline action for Polling
DEFINE_EVENT TIMELINE_EVENT[TLID_POLL]{
	fnPoll()
}

// Polling function to query server
DEFINE_FUNCTION fnPoll(){
	STACK_VAR uCli	c
	c.Arg[1].Key = 'wallstate'
	fnSendCLI(c)
}

/******************************************************************************
	Helper Functions - Transmit Data
******************************************************************************/
//
// Add command string to queue
//DEFINE_FUNCTION fnAddToQueue(){
//	STACK_VAR INTEGER i
//	FOR(i = 1; i <= MAX_QUEUE; i++){
//		IF(myVidWall.Conn.Tx[i].Arg[1].Key == ""){
//			myVidWall.Conn.Tx[i] = c
//			BREAK
//		}
//	}
//	fnSendFromQueue()
//}

DEFINE_FUNCTION fnSendCLI(uCli c){
	// If there is a pending CLI command and system is ready
		// Local Variables
		STACK_VAR CHAR toSend[255]
		STACK_VAR uCli blankCli
		STACK_VAR INTEGER i

		// Create new send string
		toSend = 'wcmd '
		toSend = "toSend,' '"

		// If Wall is set then direct this to that port
		IF(c.WallID != ''){
			toSend = "toSend,'-machine=localhost:',ITOA(myVidWall.Wall[fnGetWallByID(c.WallID)].CliPort)"
			toSend = "toSend,' '"
		}

		// Add arguments as set
		FOR(i = 1; i <= MAX_ARGS; i++){
			IF(c.Arg[i].Key != ""){
				// Add the argument key
				toSend = "toSend,'-',c.Arg[i].Key"
				// Quote out the value if specified
				IF(c.Arg[i].QuoteValue){
					c.Arg[i].Val = "'"',c.Arg[i].Val,'"'"
				}
				// Add the argument value if present
				IF(c.Arg[i].Val != ""){
					toSend = "toSend,'=',c.Arg[i].Val"
				}
				// If there are more to come, add space seperator
				IF(i <= MAX_ARGS){
					IF(c.Arg[i+1].Key){
						toSend = "toSend,' '"
					}
				}
			}
		}

		toSend = "toSend,$0D,$0A"
		fnDebug(myVidWall.Conn.Debug,DEBUG_STD,"'->DP::',toSend")
		SEND_STRING ipServer, toSend
		//myVidWall.Conn.RTS = FALSE

	fnInitPoll()
}
DEFINE_FUNCTION fnProcessFeedback(CHAR pDATA[]){
	// Local Variables
	LOCAL_VAR uCli c

	IF(LEFT_STRING(pDATA,6) == ' =wcmd'){
		STACK_VAR INTEGER i
		// Is Echo of Command, body to follow, so Store
		GET_BUFFER_STRING(pDATA,6)
		// Loop through all arguments
		WHILE(FIND_STRING(pDATA,'-',1)){
			i++
			// Remove up to Arg
			REMOVE_STRING(pDATA,'-',1)
			// Check for Value
			IF(FIND_STRING(pDATA,'=',1)){
				c.Arg[i].Key = fnStripCharsRight(REMOVE_STRING(pDATA,'=',1),1)
				IF(pDATA[1] == '"'){
					c.Arg[i].QuoteValue = TRUE
					c.Arg[i].Val = fnRemoveQuotes(REMOVE_STRING(pDATA,'"',2))
				}
				ELSE{
					c.Arg[i].Val = fnRemoveWhiteSpace(REMOVE_STRING(pDATA,' ',1))
				}
			}
			ELSE IF(FIND_STRING(pDATA,' ',1)){
				c.Arg[i].Key = fnRemoveWhiteSpace(REMOVE_STRING(pDATA,' ',1))
			}
			ELSE{
				c.Arg[i].Key = fnRemoveWhiteSpace(pDATA)
			}
		}
		RETURN
	}
	ELSE IF(pDATA == ''){
		// Is Empty Line
		RETURN
	}
	ELSE{
		// Debug Out
		fnDebug(myVidWall.Conn.Debug,DEBUG_STD,"'DP->::',pDATA")
		// Switch on main Arg
		SWITCH(c.Arg[1].Key){
			CASE 'wallstate':{
				// Local Variables
				LOCAL_VAR CHAR WallID[50]
				STACK_VAR CHAR Key[30]
				STACK_VAR CHAR Val[100]

				// Get Data
				Key = fnRemoveWhiteSpace(fnStripCharsRight(REMOVE_STRING(pDATA,':',1),1))
				Val = fnRemoveWhiteSpace(pDATA)

				// Debug Out
				//fnDebug(myVidWall.Conn.Debug,DEBUG_DEV,"'WallStateKP::',Key,'::',Val")

				SWITCH(Key){
					CASE 'Wall Id': 	WallID = Val
					CASE 'Wall Name': myVidWall.Wall[fnGetWallByID(WallID)].Name = Val
					CASE 'WallPort':  myVidWall.Wall[fnGetWallByID(WallID)].Port = ATOI(Val)
					CASE 'Cli Port':{
						//STACK_VAR uCli newC
						myVidWall.Wall[fnGetWallByID(WallID)].CliPort = ATOI(Val)
						// Queue layout resquests for this wall
						//newC.WallID = WallID
//						newC.Arg[1].Key = 'layouts'
//						fnSendCLI(newC)
					}
					CASE 'AutoStart':       myVidWall.Wall[fnGetWallByID(WallID)].AutoStart = (UPPER_STRING(Val) == 'TRUE')
					CASE 'Is Partition':    myVidWall.Wall[fnGetWallByID(WallID)].IsPartition = (UPPER_STRING(Val) == 'TRUE')
					CASE 'Is Blueprint':    myVidWall.Wall[fnGetWallByID(WallID)].IsBlueprint = (UPPER_STRING(Val) == 'TRUE')
					CASE 'Current State':   myVidWall.Wall[fnGetWallByID(WallID)].CurrentState = Val
					CASE 'Operation State': myVidWall.Wall[fnGetWallByID(WallID)].OperationState = Val
					CASE 'DesktopRelativeBounds':{
						STACK_VAR CHAR tmp[100]
						// Get x
						tmp = Val
						REMOVE_STRING(tmp,'"x":',1)
						myVidWall.Wall[fnGetWallByID(WallID)].x = ATOI(tmp)
						// Get y
						tmp = Val
						REMOVE_STRING(tmp,'"y":',1)
						myVidWall.Wall[fnGetWallByID(WallID)].y = ATOI(tmp)
						// Get h
						tmp = Val
						REMOVE_STRING(tmp,'"height":',1)
						myVidWall.Wall[fnGetWallByID(WallID)].h = ATOI(tmp)
						// Get w
						tmp = Val
						REMOVE_STRING(tmp,'"width":',1)
						myVidWall.Wall[fnGetWallByID(WallID)].w = ATOI(tmp)
					}
				}
			}
		}
	}
}

DEFINE_FUNCTION INTEGER fnGetWallByID(CHAR id[50]){
	STACK_VAR INTEGER i
	FOR(i = 1; i <= MAX_WALLS; i++){
		// If ID is blank then set this as current
		IF(myVidWall.Wall[i].ID  == ''){
			myVidWall.Wall[i].ID = id
		}
		// IF ID matches return index
		IF(myVidWall.Wall[i].ID == id){
			RETURN i
		}
	}
}

DEFINE_FUNCTION INTEGER fnGetWallByName(CHAR name[50]){
	STACK_VAR INTEGER i
	FOR(i = 1; i <= MAX_WALLS; i++){
		// IF ID matches return index
		IF(myVidWall.Wall[i].Name == name){
			RETURN i
		}
	}
}
/******************************************************************************
	Comms Rx/Tx Control
******************************************************************************/
(** Startup Code **)
DEFINE_START{
	CREATE_BUFFER ipServer, myVidWall.CONN.Rx
	myVidWall.CONN.isIP = !(ipServer.NUMBER)
}

(** Physical Device Events **)
DEFINE_EVENT DATA_EVENT[ipServer]{
	ONLINE:{
		myVidWall.CONN.STATE 	= CONN_STATE_CONNECTED
		//myVidWall.Conn.RTS 		= TRUE
		IF(!myVidWall.CONN.isIP){
			SEND_COMMAND ipServer, 'SET MODE DATA'
			SEND_COMMAND ipServer, 'SET BAUD 115200 N 8 1 485 DISABLE'
		}
		fnPoll()
	}
	OFFLINE:{
		STACK_VAR INTEGER i
		myVidWall.CONN.Rx = ''
		myVidWall.CONN.STATE 	= CONN_STATE_OFFLINE
		//myVidWall.Conn.RTS 		= FALSE
		fnTryConnection()
	}
	ONERROR:{
		STACK_VAR CHAR _MSG[255]
		myVidWall.CONN.Rx = ''
		myVidWall.CONN.STATE 	= CONN_STATE_OFFLINE
		//myVidWall.Conn.RTS 		= FALSE
		SWITCH(DATA.NUMBER){
			CASE 2:{ _MSG = 'General Failure'}					// General Failure - Out Of Memory
			CASE 4:{ _MSG = 'Unknown Host'}						// Unknown Host
			CASE 6:{ _MSG = 'Conn Refused'}						// CoNNECtion Refused
			CASE 7:{ _MSG = 'Conn Timed Out'}					// CoNNECtion Timed Out
			CASE 8:{ _MSG = 'Unknown'}								// Unknown CoNNECtion Error
			CASE 9:{ _MSG = 'Already Closed'}					// Already Closed
			CASE 10:{_MSG = 'Binding Error'} 					// Binding Error
			CASE 11:{_MSG = 'Listening Error'} 					// Listening Error
			CASE 14:{_MSG = 'Local Port Already Used'}		// Local Port Already Used
			CASE 15:{_MSG = 'UDP Socket Already Listening'} // UDP socket already listening
			CASE 16:{_MSG = 'Too many open Sockets'}			// Too many open sockets
			CASE 17:{_MSG = 'Local port not Open'}				// Local Port Not Open
		}
		fnDebug(myVidWall.Conn.Debug,DEBUG_ERR,"'DataPath IP Error:[',myVidWall.CONN.IP_HOST,'][',ITOA(DATA.NUMBER),'][',_MSG,']'")
		SWITCH(DATA.NUMBER){
			CASE 14:{}
			DEFAULT:{ fnTryConnection() }
		}
	}
	STRING:{
		fnDebug(myVidWall.Conn.Debug,DEBUG_DEV,"'RAW->::',DATA.TEXT");
		WHILE(FIND_STRING(myVidWall.CONN.Rx,"$0D,$0A",1)){
			fnProcessFeedback(fnStripCharsRight(REMOVE_STRING(myVidWall.CONN.Rx,"$0D,$0A",1),2))
			IF(TIMELINE_ACTIVE(TLID_COMMS)){TIMELINE_KILL(TLID_COMMS)}
			TIMELINE_CREATE(TLID_COMMS,TLT_COMMS,LENGTH_ARRAY(TLT_COMMS),TIMELINE_ABSOLUTE,TIMELINE_ONCE)
		}
	}
}
(** Delay for IP based control to allow system to boot **)
DEFINE_EVENT DATA_EVENT[vdvServer]{
	COMMAND:{
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'DEBUG':{
						SWITCH(DATA.TEXT){
							CASE 'DEV':  myVidWall.CONN.DEBUG.LOG_LEVEL = DEBUG_DEV
							CASE 'TRUE': myVidWall.CONN.DEBUG.LOG_LEVEL = DEBUG_STD
							CASE 'LOG':  myVidWall.CONN.DEBUG.LOG_LEVEL = DEBUG_LOG
							DEFAULT:     myVidWall.CONN.DEBUG.LOG_LEVEL = DEBUG_ERR
						}
					}
					CASE 'PASSWORD':{myVidWall.CONN.PASSWORD = DATA.TEXT}
					CASE 'IP':{
						IF(myVidWall.CONN.isIP){
							myVidWall.CONN.IP_HOST = fnGetSplitStringValue(DATA.TEXT,':',1)
							myVidWall.CONN.IP_PORT = 23
							IF(ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))){
								myVidWall.CONN.IP_PORT = ATOI(fnGetSplitStringValue(DATA.TEXT,':',2))
							}
							fnOpenTCPConnection()
						}
					}
				}
			}
			CASE 'RAW':{
				//fn(DATA.TEXT,'')
			}
		}
	}
}

(** Delay for IP based control to allow system to boot **)
DEFINE_EVENT DATA_EVENT[vdvWall]{
	COMMAND:{
		STACK_VAR INTEGER w
		w = fnGetWallByName(myVidWall.WallNameRefs[GET_LAST(vdvWall)])
		SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'-',1),1)){
			CASE 'PROPERTY':{
				SWITCH(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,',',1),1)){
					CASE 'NAME':myVidWall.WallNameRefs[GET_LAST(vdvWall)] = DATA.TEXT
				}
			}
			CASE 'LAYOUT':{
				STACK_VAR uCli c
				c.WallID = myVidWall.Wall[w].ID
				c.Arg[1].Key = 'layout'
				c.Arg[1].Val = DATA.TEXT
				c.Arg[1].QuoteValue = TRUE
				fnSendCLI(c)
			}
			//-id=1 -provider=Capture -input="Input 2"
			CASE 'MATRIX':{
				// Setup New CLI Command
				STACK_VAR uCli c
				STACK_VAR INTEGER Inp
				c.WallID = myVidWall.Wall[w].ID
				inp = ATOI(fnStripCharsRight(REMOVE_STRING(DATA.TEXT,'*',1),1))
				// Set Window ID
				c.Arg[1].Key = 'id'
				c.Arg[1].Val = DATA.TEXT
				// Set Window Type
				c.Arg[2].Key = 'provider'
				c.Arg[2].Val = 'Capture'
				// Set Input
				c.Arg[3].Key = 'input'
				c.Arg[3].Val = "'Input ',ITOA(inp)"
				c.Arg[3].QuoteValue = TRUE
				// Send Command
				fnSendCLI(c)
			}
		}
	}
}
/******************************************************************************
	Device Feedback
******************************************************************************/
DEFINE_PROGRAM{
	STACK_VAR INTEGER x;
	// Server Feedback
	[vdvServer,251] = (TIMELINE_ACTIVE(TLID_COMMS))
	[vdvServer,252] = (TIMELINE_ACTIVE(TLID_COMMS))
	// Wall State Feedback
	FOR(x = 1; x <= MAX_WALLS; x++){
		IF(x <= LENGTH_ARRAY(vdvWall)){
			STACK_VAR INTEGER w;
			[vdvWall[x],251] = TIMELINE_ACTIVE(TLID_COMMS)
			[vdvWall[x],252] = TIMELINE_ACTIVE(TLID_COMMS)
			w = fnGetWallByName(myVidWall.WallNameRefs[x])
			IF(w){
				[vdvWall[x],255] = myVidWall.Wall[w].CurrentState == 'Running'
			}
		}
	}
}
/******************************************************************************
	EoF
******************************************************************************/
