PROGRAM_NAME='AMXDevices'

/******************************************************************************
	Get AMX Device Type
******************************************************************************/
DEFINE_FUNCTION CHAR[100] fnGetAMXDevType(INTEGER devID){

	SWITCH(devID){

		// DVX Switcher IDs
		CASE  354:                            //  0x0162 DVX3150HD_SP
		CASE  387:									  //  0x0183 DVX3150HD_T
		CASE  388:									  //  0x0184 DVX3155HD_SP
		CASE  389:									  //  0x0185 DVX3155HD_T
		CASE  390:									  //  0x0186 DVX2150HD_SP
		CASE  391:									  //  0x0187 DVX2150HD_T
		CASE  392:									  //  0x0188 DVX2155HD_SP
		CASE  393:									  //  0x0189 DVX2155HD_T
		CASE  419:									  //  0x01A3 DVX3156HD_SP
		CASE  420:									  //  0x01A4 DVX3156HD_T
		CASE  427:									  //  0x01AB DVX2110HD_SP
		CASE  428:									  //  0x01AC DVX2110HD_T
		CASE  458:									  //  0x01CA DVX2210HD_SP
		CASE  459:									  //  0x01CB DVX2210HD_T
		CASE  438:									  //  0x01B6 DVX3250HD_SP
		CASE  449:									  //  0x01C1 DVX3250HD_T
		CASE  450:									  //  0x01C2 DVX3255HD_SP
		CASE  451:									  //  0x01C3 DVX3255HD_T
		CASE  452:									  //  0x01C4 DVX2250HD_SP
		CASE  453:									  //  0x01C5 DVX2250HD_T
		CASE  454:									  //  0x01C6 DVX2255HD_SP
		CASE  455:									  //  0x01C7 DVX2255HD_T
		CASE  456:									  //  0x01C8 DVX3256HD_SP
		CASE  457:									  //  0x01C9 DVX3256HD_T

		CASE  352:									  //  0x0160 DGX
		CASE  448:{									  //  0x01C0 DGX 100
			RETURN 'VideoMatrix'
		}

		CASE  381:{									  //  0x017D DxLink-HDMI-Rx
			RETURN 'VideoRx'
		}

		CASE  383:{									  //  0x017F DXLINK-HDMI-MFTX
			RETURN 'VideoTx'
		}

		// DVX Controller IDs
		CASE  439:									  // 0x01B7 DVX Controller
		CASE  441:                            // 0x01B9 DGX Controller
		CASE  397:                            // 0x018D NX Controller
		CASE  286:{                           // 0x011E NI Controller
			RETURN 'DeviceController'
		}

		CASE  356:                            // 0x0164 EXB-COM2
		CASE  357:                            // 0x0165 EXB-MPL1
		CASE  359:                            // 0x0167 EXB-REL8
		CASE  360:{                           // 0x0168 EXB-I/O8
			RETURN 'DeviceExpansion'
		}

		// Touchpanel IDs
		CASE 341:{									  // 0x155 NXV-300
			RETURN 'TouchPanelVirtual'
		}

		CASE 288:									  // 0x0120 MVP-7500
		CASE 314:									  // 0x013A MVP-7500
		CASE 315:								     // 0x013B MVP-8400
		CASE 289:									  // 0x0121 MVP-8400
		CASE 323:									  // 0x0143 MVP-8400i
		CASE 328:									  // 0x0148 MVP-8400i
		CASE 329:									  // 0x0149 MVP-5200i
		CASE 332:									  // 0x014C MVP-5000
		CASE 333:									  // 0x014D MVP-5100
		CASE 343:{									  // 0x0157 MVP-9000
			RETURN 'TouchPanelWireless'
		}

		CASE 402:                             // 0x0192 MST-1001
		CASE 403:                             // 0x0193 MSD-1001-L and MSD-1001-L2
		CASE 400:                             // 0x0190 MST-701
		CASE 401:                             // 0x0191 MSD-701-L and MSD-701-L2
		CASE 398:                             // 0x018E MST-431
		CASE 399:                             // 0x018F MSD-431-L
		CASE 468:                             // 0x01D4 HPX-MSP-7
		CASE 469:                             // 0x01D5 HPX-MSP-10

		CASE 361:                             // 0x169  MXT-2000XL-PAN
		CASE 368:                             // 0x170: MXD-2000XL-PAN
		CASE 369:                             // 0x171: MXT-1900L-PAN
		CASE 370:                             // 0x172: MXD-1900L-PAN
		CASE 371:                             // 0x173: MXT-1000
		CASE 372:                             // 0x174: MXD-1000
		CASE 373:                             // 0x175: MXT-700
		CASE 374:                             // 0x176: MXD-700
		CASE 375:                             // 0x177: MXD-430

		CASE 406:                             // 0x0196: MXT-2001-PAN
		CASE 407:                             // 0x0197: MXD-2001-PAN-P
		CASE 408:                             // 0x0198: MXD-2001-PAN-L
		CASE 409:                             // 0x0199: MXT-1901-PAN
		CASE 410:                             // 0x019A: MXD-1901-PAN-P
		CASE 411:                             // 0x019B: MXD-1901-PAN-L
		CASE 412:                             // 0x019C: MXT-1001
		CASE 413:                             // 0x019D: MXD-1001-P
		CASE 414:                             // 0x019E: MXD-1001-L
		CASE 415:                             // 0x019F: MXT-701
		CASE 416:                             // 0x01A0: MXD-701-P
		CASE 417:{                            // 0x01A1: MXD-701-L
			RETURN 'TouchPanelWired'
		}


	}
}
/******************************************************************************
	EoF
******************************************************************************/