ECHO
IF {%1} == {} ECHO *** Missing parameter [slt1dump.rom]
IF {%1} == {} EXIT
IF {%2} == {} ECHO *** Missing parameter [slt2dump.rom]
IF {%2} == {} EXIT
IF NOT EXIST %1 ECHO *** File not found [%1]
IF NOT EXIST %1 EXIT
IF NOT EXIST %2 ECHO *** File not found [%2]
IF NOT EXIST %2 EXIT
CLS
ECHO KONAMI Cartridges Combination
ECHO =============================
ECHO
ECHO Slot-1 = %1 
ECHO Slot-2 = %2
ECHO
ECHO Loading, please wait...
ECHO

SETSMART -0a0f33
ROMLOAD %2>nul
SETSMART -10
ROMLOAD %1>nul
SETSMART -03fd
