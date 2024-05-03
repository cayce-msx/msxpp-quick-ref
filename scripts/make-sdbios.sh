#!/bin/bash

set -e

if [[ $# == 0 ]]; then
  echo "Create SD-BIOS (OCM-BIOS.DAT) for use with OCM-PLD."
  echo "Based on make-sdb.cmd for OCM-SDBIOS v3.7 by KdL (2024.01.13)."
  echo "Named 'make-sdbios.sh' because, well, make-sdb.sh could make Linux folks uneasy about their internal drive ;)"
  echo "Menu selections are less feature rich. Cancels exits."
  echo
  echo "Usage: $0 [args] <path to extracted OCM-SDBIOS Pack> [opt1..6] [<custom mainrom file> <custom subrom file>]"
  echo "  where each 'opt' is either a choice number or a dot (.) for the default choice"
  echo "  (make-sdb.cmd uses '*' for defaults, but that's not very convenient in *nix shell)"
  echo
  echo "args:"
  echo " -n\toutput as OCM-BIOSiiiiii.DAT which each 'i' a choice value"
  echo " -s <digit>\toutput as ALT-BIOS.DAi"
  echo " -y\toverwrite existing file without asking"
  exit 1
fi

# Texts
FIRM1="MSX2+ OCM-PLD v3.0 to v3.3.3"
FIRM2="MSX2+ OCM-PLD v3.4 or later"
FIRM3="MSXtR OCM-PLD v3.4 or later"
FIRM4="512kB dummy blank file to run the EPBIOS"
ESPVER="2022.08.13"

# Parameters
while [[ $1 =~ ^\- ]] do
  if [[ $1 == "-n" ]]; then
    number_output=true
  elif [[ $1 == "-y" ]]; then
    overwrite=true
  elif [[ $1 == "-s" ]]; then
    alt_output=$2
    shift
  elif [[ $1 == "-q" ]]; then
    quiet=true
  else
    echo "option $1 not recognized"
    exit 17
  fi
  shift
done
SDBIOS="$1/make"

# Sanity check
if [[ ! -d "${SDBIOS}" ]]; then
  echo "SDBIOS path ${SDBIOS} not found"
  exit 11
fi

# Variables
ROMDIR="${SDBIOS}/roms"
FREE16="${ROMDIR}/free16kb.rom"
NULL64="${ROMDIR}/null64kb.rom"
TMPDIR=$(mktemp -d)
CBIOS_PATH="$(dirname $0)/../roms"
DEFOPT1=2
DEFOPT2=1
DEFOPT3=2
DEFOPT4=2
DEFOPT5=1
DEFOPT6=3
SDBIOSFN=OCM-BIOS.DAT
OUTPUT="${SDBIOSFN}"

# Option parameters
## 1: firmware
shift && case $1 in
  '.' ) OPT1=$DEFOPT1;;
  1   ) OPT1=$1;;
  2   ) OPT1=$1;;
  3   ) OPT1=$1;;
  4   ) OPT1=$1;;
  5   ) OPT1=$1;;
  6   ) OPT1=$1;;
  7   ) OPT1=$1;;
  8   ) OPT1=$1;;
  *) ;;
esac
## 2: Disk-ROM
shift && case $1 in
  '.' ) OPT2=$DEFOPT2;;
  1   ) OPT2=$1;;
  2   ) OPT2=$1;;
  3   ) OPT2=$1; [[ $OPT1 == 1 ]] && OPT2=;;
  *) ;;
esac
## 3: Main-ROM / keyboard mapping
shift && case $1 in
  '.' ) OPT3=$DEFOPT3;;
  1   ) OPT3=$1;;
  2   ) OPT3=$1;;
  3   ) OPT3=$1; [[ $OPT1 == 3 ]] && OPT3=;;
  *) ;;
esac
## 4: Kanji-ROM / logo
shift && case $1 in
  '.' ) OPT4=$DEFOPT4;;
  0   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  1   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  2   ) OPT4=$1;;
  3   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  4   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  5   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  6   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  7   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  8   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  9   ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'A' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'B' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'C' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'D' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'E' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'F' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'G' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'H' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  'I' ) OPT4=$1; [[ $OPT1 == 3 ]] && OPT4=;;
  *) ;;
esac
## 5: Option-ROM / Wi-Fi
shift && case $1 in
  '.' ) OPT5=$DEFOPT5;;
  0   ) OPT5=$1; [[ $OPT1 == 1 ]] && OPT5=;;
  1   ) OPT5=$1;;
  2   ) OPT5=$1; [[ $OPT1 == 1 ]] && OPT5=;;
  3   ) OPT5=$1; [[ $OPT1 == 1 ]] && OPT5=;;
  *) ;;
esac
## 6: Extra-ROM / Kun-BASIC
shift && case $1 in
  '.' ) OPT6=$DEFOPT6;;
  1   ) OPT6=$1;;
  2   ) OPT6=$1;;
  3   ) OPT6=$1;;
  *) ;;
esac

# 1: Firmware
if [[ -z "$OPT1" ]]; then
  OPT1=$(dialog \
    --title "Firmware Menu" \
    --default-item '2' \
    --menu "Please select firmware" \
    15 70 8 \
    1 "${FIRM1}" \
    2 "${FIRM2}  (default)" \
    3 "${FIRM3}  (experimental)" \
    4 "${FIRM4}" \
    5 "MSX1 OCM-PLD v3.9.x" \
    6 "MSX2 OCM-PLD v3.9.x" \
    7 "Custom MainROM & SubROM" \
    8 "C-BIOS v0.29a MSX2+ (requires OCM-PLD v3.9.1 or newer)" \
    2>&1 >/dev/tty)
fi
if [[ $OPT1 == 4 ]]; then
  # fast track for blank file
  OPT2=0
  OPT3=0
  OPT4=0
  OPT5=0
  OPT6=0
fi

# 2: Disk-ROM
opts=(
  1 "MegaSDHC FAT16X Single drive  (default)" \
  2 "MegaSDHC FAT16X Double drive  (drive A: and B:)" \
)
if [[ $OPT1 != 1 ]]; then
  opts+=(3)
  # https://github.com/Konamiman/Nextor/releases/tag/v2.1.2
  # Dec 1, 2023
  # Nextor-2.1.2.OCM.ROM
  # sha1 15f7d295d574124dec7073b7d54bff76aeb243d5
  # Comparable to MegaFlashROM SCC+ SD; DiskROM related code removed
  opts+=("Nextor Kernel v2.1.2")
fi
if [[ $OPT1 == 5 ]]; then
  # MSX1 only supports Nextor; not MegaSDHC
  OPT2=3
fi
if [[ -z "$OPT2" ]]; then
  OPT2=$(dialog \
    --title "Disk-ROM Menu" \
    --default-item '1' \
    --menu "Please select Disk-ROM" \
    15 60 4 \
    "${opts[@]}" \
    2>&1 >/dev/tty)
fi

if [[ $OPT1 == 1 ]]; then
  # older firmware: no Nextor, and no NULL rom
  case $OPT2 in
    1) DISK=("${ROMDIR}/megasd1s.rom");;
    2) DISK=("${ROMDIR}/megasd2s.rom");;
    *);;
  esac
else
  case $OPT2 in
    1) DISK=("${ROMDIR}/megasd1s.rom" "${NULL64}");;
    2) DISK=("${ROMDIR}/megasd2s.rom" "${NULL64}");;
    3) DISK=("${ROMDIR}/nextsd1s.rom");;
    *);;
  esac
fi

# 3: Main-ROM
case $OPT1 in
  1|2|4)
    opts=(
      1 "MSX2+ FS-A1WSX Fn-mod Yen" \
      2 "MSX2+ FS-A1WSX Fn-mod Backslash  (default)" \
      3 "MSX2+ FS-A1WSX Fn-mod Western layout" \
    );;
  3)
    opts=(
      1 "MSXtR FS-A1GT Fn-mod Yen" \
      2 "MSXtR FS-A1GT Fn-mod Backslash  (default)"\
    );;
  5)
    opts=(
      1 "MSX1 Yen" \
      2 "MSX1 Backslash  (default)" \
      3 "MSX1 Western layout" \
    );;
  6)
    opts=(
      1 "MSX2 Yen" \
      2 "MSX2 Backslash  (default)" \
      3 "MSX2 Western layout" \
    );;
  7|8);; # no choice
  *)
    echo "unhandled situation"
    exit 15;;
esac
if [[ -z "$OPT3" && $OPT1 != 7 && $OPT1 != 8 ]]; then
  OPT3=$(dialog \
    --title "Main-ROM Menu" \
    --default-item '2' \
    --menu "Please select character map" \
    15 60 4 \
    "${opts[@]}" \
    2>&1 >/dev/tty)
fi

case $OPT1 in
  1|2|4)
    case $OPT3 in
      1) MAIN="${ROMDIR}/a1wsxyen.rom";;
      2) MAIN="${ROMDIR}/a1wsxbsl.rom";;
      3) MAIN="${ROMDIR}/a1wsxwst.rom";;
      *);;
    esac;;
  3)
    case $OPT3 in
      1) MAIN="${ROMDIR}/msxtryen.rom";;
      2) MAIN="${ROMDIR}/msxtrbsl.rom";;
      *);;
    esac;;
  5)
    case $OPT3 in
      1) MAIN="${ROMDIR}/msx1-yen.rom";;
      2) MAIN="${ROMDIR}/msx1-bsl.rom";;
      3) MAIN="${ROMDIR}/msx1-wst.rom";;
      *);;
    esac;;
  6)
    case $OPT3 in
      1) MAIN="${ROMDIR}/msx2-yen.rom";;
      2) MAIN="${ROMDIR}/msx2-bsl.rom";;
      3) MAIN="${ROMDIR}/msx2-wst.rom";;
      *);;
    esac;;
  7)
    shift
    MAIN="$1"
    if [[ -z "${MAIN}" ]]; then
      echo -n "full path to Main-ROM : "
      read MAIN
    fi
    if [[ ! -f $MAIN ]] then
      echo "File '$MAIN' does not exist"
      exit 13
    fi;;
  # could add choice for regular/JP/BR/EU C-BIOS MainROM - now always regular
  # we don't use cbios_basic.rom nor cbios_logo*.rom
  8) MAIN="${CBIOS_PATH}/cbios_main_msx2+.rom";;
  *)
    echo "unhandled situation"
    exit 16;;
esac

# Sub-ROM
case $OPT1 in
  1) SUB="${ROMDIR}/2pextr01.rom";;
  3) SUB="${ROMDIR}/trextrtc.rom";;
  # could leave this empty - sdbios-n34/msx1/n34msx1.bsl contains x2extrtc
  #5) SUB="${ROMDIR}/free16kb.rom";;
  5) SUB="${ROMDIR}/x2extrtc.rom";;
  6) SUB="${ROMDIR}/x2extrtc.rom";;
  7)
    shift
    SUB="$1"
    if [[ -z "${SUB}" ]]; then
      echo -n "full path to Sub-ROM : "
      read SUB
    fi
    if [[ ! -f $SUB ]] then
      echo "File '$SUB' does not exist"
      exit 14
    fi;;
  8) SUB="${CBIOS_PATH}/cbios_sub.rom";;
  *) SUB="${ROMDIR}/2pextrtc.rom";;
esac

# MSX-Music
case $OPT1 in
  3) MUSIC="${ROMDIR}/msxtrmus.rom";;
  # C-BIOS expects MSX-MUSIC at slot 3-1 and nothing in 0-2 - leave this block empty
  8) MUSIC="${ROMDIR}/free16kb.rom";;
  *) MUSIC="${ROMDIR}/msx2pmus.rom";;
esac

# 4: Kanji-ROM
case $OPT1 in
  3) # Turbo-R: no Kanji-ROM / logo choice
     KANJI="${ROMDIR}/kn2plfix.rom";;
  # C-BIOS expects logo at unexpanded slot 0, in page 2. OCM-PLD does not support that. C-BIOS will boot without logo.
  8) KANJI="${CBIOS_PATH}/cbios_music_plus_free16kb.rom";; # C-BIOS expects MSX-MUSIC rom at slot 3-1 page 1 - which is where OCM-PLD puts the first half of Kanji ROM
  *)
    opts=(
      0 "No logo" \
      1 "MSX2+ logo fix" \
      2 "MSX++ official logo  (default)" \
      3 "SONY unofficial logo" \
      4 "PHILIPS unofficial logo" \
      5 "Zemmix Neo Korean logo" \
      6 "Zemmix Neo Brazilian logo" \
      7 "SX-1 logo by 8bits4ever" \
      8 "SM-X logo by Victor Trucco" \
      9 "1chipMSX-Kai logo by HRA!" \
      A "SX-2 logo by 8bits4ever" \
      B "OCM generic unbound logo" \
      C "u2-SX logo by Denjhang" \
      D "extra: 2000" \
      E "extra: 8bits4ever" \
      F "extra: MiSXer" \
      G "extra: MSX3+" \
      H "extra: MSX3" \
      I "extra: SX-1 v1" \
    )
    if [[ -z "$OPT4" ]]; then
      OPT4=$(dialog \
        --title "Kanji-ROM Menu" \
        --default-item '2' \
        --menu "Please select logo" \
        20 60 18 \
        "${opts[@]}" \
        2>&1 >/dev/tty)
    fi
    case $OPT4 in
      0) KANJI="${ROMDIR}/knnologo.rom";;
      1) KANJI="${ROMDIR}/kn2plfix.rom";;
      2) KANJI="${ROMDIR}/knmsxppl.rom";;
      3) KANJI="${ROMDIR}/knsonyun.rom";;
      4) KANJI="${ROMDIR}/knphilun.rom";;
      5) KANJI="${ROMDIR}/knzneokr.rom";;
      6) KANJI="${ROMDIR}/knzneobr.rom";;
      7) KANJI="${ROMDIR}/knsx-1v2.rom";;
      8) KANJI="${ROMDIR}/knsm-xbr.rom";;
      9) KANJI="${ROMDIR}/knocmkai.rom";;
      A) KANJI="${ROMDIR}/knsx-2v2.rom";;
      B) KANJI="${ROMDIR}/knocmgun.rom";;
      C) KANJI="${ROMDIR}/knu2sx11.rom";;
      D) KANJI="${ROMDIR}/extra/kn2000un.rom";;
      E) KANJI="${ROMDIR}/extra/kn8bi4ev.rom";;
      F) KANJI="${ROMDIR}/extra/knmisxer.rom";;
      G) KANJI="${ROMDIR}/extra/knmsx3pl.rom";;
      H) KANJI="${ROMDIR}/extra/knmsx3un.rom";;
      I) KANJI="${ROMDIR}/extra/knsx-1v1.rom";;
      *);;
    esac;;
esac

# 5: Option-ROM
case $OPT1 in
  # older firmware
  1) OPT5=$DEFOPT5;;
  # MSX1/2/2+
  2|5|6|7|8) opts=(
       1 "No Option-ROM  (default)"
       2 "ESP8266 Wi-Fi BIOS ${ESPVER}"
     )
     if [[ -z "$OPT5" ]]; then
       OPT5=$(dialog \
         --title "Option-ROM Menu" \
         --default-item '1' \
         --menu "Please (de)select Wi-Fi" \
         15 60 2 \
         "${opts[@]}" \
         2>&1 >/dev/tty)
     fi
     case $OPT5 in
       1) OPTION="${ROMDIR}/free16kb.rom";;
       2) OPTION="${ROMDIR}/esp8266e.rom";;
       *);;
     esac;;
  # Turbo-R
  3) opts=(
       0 "No logo" \
       1 "MSXtR logo  (default)" \
       2 "ESP8266 Wi-Fi BIOS ${ESPVER} + No logo" \
       3 "ESP8266 Wi-Fi BIOS ${ESPVER} + MSXtR logo" \
     )
     if [[ -z "$OPT5" ]]; then
       OPT5=$(dialog \
         --title "Option-ROM Menu" \
         --default-item '1' \
         --menu "Please select Wi-Fi/logo combo" \
         15 60 4 \
         "${opts[@]}" \
         2>&1 >/dev/tty)
     fi
     case $OPT5 in
       0) OPTION="${ROMDIR}/emptyopt.rom";;
       1) OPTION="${ROMDIR}/msxtropt.rom";;
       2) OPTION="${ROMDIR}/esp8266e.rom";;
       3) OPTION="${ROMDIR}/esp8266m.rom";;
       *);;
     esac;;
  *)
    echo "unhandled situation"
    exit 14;;
esac

# JIS1-ROM
JIS1="${ROMDIR}/a1xxjis1.rom"

# JIS2-ROM
JIS2="${ROMDIR}/a1xxjis2.rom"

# 6: Extra-ROM
opts=(
  1 "No Extra-ROM" \
  2 "BASIC'n plus v2.0" \
  3 "BASIC'n turbo v2.1  (default)" \
)
if [[ -z "$OPT6" ]]; then
  OPT6=$(dialog \
    --title "Extra-ROM Menu" \
    --default-item '3' \
    --menu "Please select Extra-ROM" \
    15 60 3 \
    "${opts[@]}" \
    2>&1 >/dev/tty)
fi
case $OPT6 in
  1) EXTRA="${ROMDIR}/free16kb.rom";;
  2) EXTRA="${ROMDIR}/xbasic20.rom";;
  3) EXTRA="${ROMDIR}/xbasic21.rom";;
  *);;
esac

# print choices
if [[ -z $quiet ]]; then
  echo
  echo "selected options - 1: $OPT1, 2: $OPT2, 3: $OPT3, 4: $OPT4, 5: $OPT5, 6: $OPT6"
fi

# self-check
if [[ $OPT1 != 4 ]]; then
  if [[ -z $DISK ]]; then
    echo "Disk-ROM empty"
    exit 2
  fi
  if [[ -z $MAIN ]]; then
    echo "Main-ROM empty"
    exit 3
  fi
  if [[ -z $SUB ]]; then
    echo "Sub-ROM empty"
    exit 4
  fi
  if [[ -z $MUSIC ]]; then
    echo "Music-ROM empty"
    exit 5
  fi
  if [[ -z $KANJI ]]; then
    echo "Kanji-ROM empty"
    exit 6
  fi
  if [[ $OPT1 != 1 && -z $OPTION ]]; then
    echo "Option-ROM empty"
    exit 7
  fi
  if [[ -z $JIS1 ]]; then
    echo "JIS1-ROM empty"
    exit 8
  fi
  if [[ -z $JIS2 ]]; then
    echo "JIS2-ROM empty"
    exit 9
  fi
  if [[ -z $EXTRA ]]; then
    echo "Extra-ROM empty"
    exit 10
  fi
fi

if [[ $number_output == true ]]; then
  OUTPUT="OCM-BIOS-${OPT1}${OPT2}${OPT3}${OPT4}${OPT5}${OPT6}.DAT"
elif [[ ! -z $alt_output ]]; then
  OUTPUT="ALT-BIOS.DA${alt_output}"
fi

if [[ -f "${OUTPUT}" && $overwrite != true ]]; then
  echo "${OUTPUT} already exists"
  exit 12
fi

if [[ -z $quiet ]]; then
  echo "Creating output file $OUTPUT"
fi

# Chaining of ROMs
case $OPT1 in
  1) # older firmware - different order, no option ROM and no JIS2 (384KiB SDBIOS)
    cat "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" > "${TMPDIR}/BLANK128.TMP"
    cat "${DISK[@]}" "${MAIN}" "${SUB}" "${MUSIC}" "${JIS1}" "${FREE16}" "${KANJI}" "${FREE16}" "${FREE16}" "${EXTRA}" "${FREE16}" "${FREE16}" "${TMPDIR}/BLANK128.TMP" > "${OUTPUT}"
    ;;
  4) # blank
    cat "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" "${FREE16}" > "${TMPDIR}/BLANK128.TMP"
    cat "${TMPDIR}/BLANK128.TMP" "${TMPDIR}/BLANK128.TMP" "${TMPDIR}/BLANK128.TMP" "${TMPDIR}/BLANK128.TMP" > "${OUTPUT}"
    ;;
  *) # MSX1/2/2+/TR
    #echo "${DISK[@]}" "${MAIN}" "${EXTRA}" "${MUSIC}" "${SUB}" "${KANJI}" "${OPTION}" "${JIS1}" "${JIS2}"
    cat "${DISK[@]}" "${MAIN}" "${EXTRA}" "${MUSIC}" "${SUB}" "${KANJI}" "${OPTION}" "${JIS1}" "${JIS2}" > "${OUTPUT}";;
esac

if [[ -z $quiet ]]; then
  echo "Done"
  echo

  # Help Message
  echo "---| MSX-BIOS Configuration (OCM-PLD v3.4 or later) |------------------------"
  echo "3-2 (4000h)  128kB  MEGASDHC.ROM + NULL64KB.ROM / NEXTOR  .ROM   blocks 01-08"
  echo "0-0 (0000h)   32kB  MSX2P   .ROM / MSXTR   .ROM                  blocks 09-10"
  echo "3-3 (4000h)   16kB  XBASIC2 .ROM / XBASIC21.ROM                  block  11"
  echo "0-2 (4000h)   16kB  MSX2PMUS.ROM / MSXTRMUS.ROM                  block  12"
  echo "3-1 (0000h)   16kB  MSX2PEXT.ROM / MSXTREXT.ROM                  block  13"
  echo "3-1 (4000h)   32kB  MSXKANJI.ROM                                 blocks 14-15"
  echo "0-3 (4000h)   16kB  FREE16KB.ROM / MSXTROPT.ROM / ESP8266 .ROM   block  16"
  echo "I/O          128kB  JIS1    .ROM                                 blocks 17-24"
  echo "I/O          128kB  JIS2    .ROM                        (512kB)  blocks 25-32"
  echo "-----------------------------------------------------------------------------"
fi
