echo MSXDOS2.SYS and NEXTOR.SYS are going to be exchanged, wait for reboot...
echo
if not exist \MSXDOS2.SYS echo *** MSXDOS2.SYS not found
if not exist \NEXTOR.SYS echo *** NEXTOR.SYS not found
if not exist \MSXDOS2.SYS exit
if not exist \NEXTOR.SYS exit
del \MSXDOS2.TMP/H/S>nul
ren \MSXDOS2.SYS/H/S MSXDOS2.TMP
ren \NEXTOR.SYS/H/S MSXDOS2.SYS
ren \MSXDOS2.TMP/H/S NEXTOR.SYS
reset
