# netlinx-global-code : Custom modules and include files for Netlinx (AMX by Harman)

[![MIT license](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.en.html)
[![LinkedIn](https://img.shields.io/badge/contact-LinkedIn-blue)](https://www.linkedin.com/company/soloworkslondon/)

| branch | status |
|-------|----|
| master  | [![Build Status](https://dev.azure.com/soloworkslondon/WindowsComplierPipelineTest/_apis/build/status/soloworks.netlinx-global-code?branchName=master)](https://dev.azure.com/soloworkslondon/WindowsComplierPipelineTest/_build/latest?definitionId=1&branchName=master) |
| develop | [![Build Status](https://dev.azure.com/soloworkslondon/WindowsComplierPipelineTest/_apis/build/status/soloworks.netlinx-global-code?branchName=develop)](https://dev.azure.com/soloworkslondon/WindowsComplierPipelineTest/_build/latest?definitionId=1&branchName=develop) |

## Overview
This repo contains all centralised code and modules used by Solo Works London in our Netlinx development.

We are making them availible to other developers in order to faciitate better collaboration and conversation

Please get in touch with any updates, fixes, suggestions. If you are feeling collaborative, get involved.

All code and modules are used at own risk, we offer no garantee or support beyond friendly advice.

## Code Quality & Standards

There are some standard code practices we have developed over time which will be documented here in the near future. Some adhere to a rough version of SNAPI, some are internal convention we have found useful.

Some highlights for now:

* Modules will only be passed devices, and all communications will be via those
* Last device in module declaration is always the real world port
* One virtual device should exist for each logical object, e.g. each gain structure, each display panel, each call
* Control is always via Commands
* Feedback is via Strings, Channels, Levels
* Structures > lots of variables

Channels Often Used:

* 251: High when communication is live with end device, drops when communication lost
* 252: Follows 251 (Both required for RMS)
* 199: Mute (Gain)
* 198: Mute (Mic)
* 236: Call Incoming
* 237: Call Outgoing
* 238: Call Live

Levels Often Used:

* 1: Gain (Native Range)
* 2: Gain (0-100)
* 3: Gain (0-255)

## Getting Started

Prior to using the modules automatically, you can compile them all using the .apw file which references them all. Just compile the entire workspace (and go make some tea whilst you wait)

We find it good practice to have a Modules project in each workspace which references the used files for easy access to the source code for development.

Our use case for these file is to download the repo to a sibling directory to your projects:

    -- AMXProjectsFolder
        |-- netlinx-global-code
        |    |-- Includes
        |    |-- IncludesRms
        |    |-- ModulesNetlinx
        |    |-- ModulesNetlinxRms
        |    |-- ModulesDuet
        |    |-- ModulesDuetRms
        |
        |-- YourFirstProject
        |-- YourOtherProject

Set your Netlinx Studio module and include folders manually to include the subfolders above to allow automatic discovery of compiled files:

```
Settings->Preferences->Netlinx Compiler->Directories
```

Or use the Netlinx Studio configuration tool at:
bitbucket.org/solo_works/netlinxstudioconfigtool

### Folders

* Includes            - Include Files
* ModulesDuet         - AMX Supplied Duet Modules
* ModulesNetlinx      - Bespoke Netlinx Modules
* rmsModulesCustom    - Bespoke RMS Netlinx Modules
* IncludesRms         - Standard AMX Supplied RMS - Includes
* ModulesDuetRms      - Standard AMX Supplied RMS Modules
* ModulesNetlinxRms   - Standard and Custom RMS Modules

### Sample Code

Most modules will use a variation on the following code to run

```netlinx
DEFINE_DEVICE
ipSol  = 0:03:0
vdvSol = 33001:1:0

DEFINE_MODULE 'mSolsticeAPI' mySolMod01(vdvSol,ipSol)

DEFINE_START{
	SEND_COMMAND vdvSol,'PROPERTY-IP,192.168.1.29'
}

DEFINE_EVENT DATA_EVENT[vdvSol]{
	STRING:{
		SWITCH(REMOVE_STRING(DATA.TEXT,'-',1)){
			CASE 'PROPERTY-':{
				SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
					CASE 'META':{
						SWITCH(REMOVE_STRING(DATA.TEXT,',',1)){
							CASE 'SESSIONKEY':{
								SEND_STRING 0, "'Session Key is [',DATA.TEXT,']'"
							}
						}
					}
				}
			}
		}
	}
}
```

## Author

Created by Solo Works London, maintained by Sam Shelton and others

Find us at https://soloworks.co.uk/