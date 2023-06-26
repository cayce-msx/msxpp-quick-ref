#!/bin/bash

set -e

if [[ $# == 0 ]]; then
  echo "Format micro-SD card for use with OneChipMSX."
  echo "Based on sdcreate.cmd by KdL."
  echo "Assumes the following packages: util-linux, findutils, dosfstools, coreutils, rsync."
  echo "You will need sudo rights."
  echo "Use this program at your own risk - no warranties."
  echo
  echo "Usage: $0 /dev/<device> <path to extracted OCM-SDBIOS Pack> [label (default: MSXFAT16)]"
  exit 1
fi

# To do this on an image file, using loopback:
#
#  dd if=/dev/zero bs=1M count=<size> of=<file>.img
#  ..do (s)fdisk manually
#  sudo partx -av <file>.img
#  .. mkfs.fat as below ..
#  sudo partx -dv /dev/loopXX

# Input parameters
DEST="$1"
SDBIOS="$2/make/sdcreate"
LABEL="${3:-msxfat16}"
LABEL="${LABEL:0:11}"
LABEL="${LABEL^^}"

# Check prerequisites
if [[ ! -f "${SDBIOS}/os/MSXDOS2.SYS" ]]; then
    echo "'MSXDOS2.SYS' is missing!"
    exit 2
fi
if [[ ! -f "${SDBIOS}/os/COMMAND2.COM" ]]; then
    echo "'COMMAND2.COM' is missing!"
    exit 3
fi

# Start of process
mount=$(lsblk -no MOUNTPOINTS "${DEST}" | xargs)
if [[ ! -z "${mount}" ]]; then
  echo "Destination $DEST is mounted as ${mount}. Unmount it first."
  exit 4
fi

echo "WARNING: ALL EXISTING DATA OF THE TARGET DEVICE WILL BE DESTROYED!"
echo "Continue? (1=Yes, 2=No)"
select yn in "Y" "N"; do
    case $yn in
        Y ) break;;
        N ) exit 5;;
    esac
done

# partition size in 512B-sectors
destsize=$(sudo blockdev --getsz "${DEST}")
destsize=$(($destsize - 1))
if [[ $destsize > 8386560 ]]; then
  echo "Your micro-SD card is larger than 4GiB. Only creating 1 primary partition of 4095MiB. Create the other partitions manually."
  destsize=8386560
fi

destsize_mib=$(($destsize / 2048))

# type e=W95 FAT16, type 6=FAT16, 1=FAT12
## a 'p' is added as partition prefix when the device name ends in a digit
if [[ "${DEST}" =~ ^.*[0-9]$ ]]; then
  partition="${DEST}p1"
else
  partition="${DEST}1"
fi
echo "Partitioning $DEST with 1 non-boot primary partition ${partition} (type W95 FAT16) with $destsize 512B-sectors (${destsize_mib}MiB)."
echo "Formatting the partition as FAT16."
scriptfile=$(mktemp)
cat <<EOF > "${scriptfile}"
unit: sectors
sector-size: 512

${partition} : start=       1, size=     $destsize, type=e
EOF

sudo sfdisk "${DEST}" < "${scriptfile}"
# additional options tried:
# -a \ # don't align
# -S 512 \ # LOGICAL-SECTOR-SIZE 0x00B(2) = 0x200 (no sfdisk default - but 512 is used by all)
# -s 64 \ # SECTORS-PER-CLUSTER 0x00d(1) = 0x40 / 0x04 (determined by device size)
# -R 2 \ #NUMBER-OF-RESERVED-SECTORS 0x00E(2) = 0x002 / 0x004 (varies)
# -f 2 \ #NUMBER-OF-FATS #FATS 0x010(1) = 0x02 (default)
# -r 512 \ #ROOT-DIR-ENTRIES 0x011(2) = 0x200 (default)
sudo mkfs.fat -F 16 -n "${LABEL}" "${partition}"

echo "Stopping here; Linux fat fs seems to skip cluster 2, which breaks SD-BIOS loading on OCM-PLD firmware v3.9."
echo "Please copy OCM-BIOS.DAT using Windows..."
exit

the_uid=$(whoami)
the_gid=$(id -gn ${the_uid})
mountpoint=$(mktemp -d)
sudo mount -o uid="${the_uid}",gid="${the_gid}" "${partition}" "${mountpoint}"

echo
echo "Copying files"
SDBIOSFN=OCM-BIOS.DAT
cp "${SDBIOS}/sdbios/${SDBIOSFN}" ${mountpoint} || echo "not copying ${SDBIOSFN} - not found"

rsync -a --exclude="__*subfolder_readme.txt" "${SDBIOS}/os/" ${mountpoint}
rsync -a --exclude="__*subfolder_readme.txt" "${SDBIOS}/help" "${SDBIOS}/utils" ${mountpoint}

echo
echo "The following files are on your fresh new MSX++ micro-SD card:"
ls -R ${mountpoint}

echo
echo "Disk usage stats:"
df ${mountpoint}

echo
echo "Unmounting volume"
sudo umount "${mountpoint}"

echo
echo "Done - success!"
