#!/bin/bash
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
#
# LICENSE UPL 1.0
#
# Copyright (c) 1982-2020 Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      01_setup_u01.sh
#
#    DESCRIPTION
#      Setup for u01
#
#    NOTES
#      DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#
#    AUTHOR
#      ruggero.citton@oracle.com
#
#    MODIFIED   (MM/DD/YY)
#    rcitton     03/30/20 - VBox libvirt & kvm support
#    rcitton     10/01/19 - Creation
#
#    REVISION
#    20200330 - $Revision: 2.0.2.1 $
#
#│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
echo "-----------------------------------------------------------------"
echo -e "${INFO}`date +%F' '%T`: Setting-up /u02 disk"
echo "-----------------------------------------------------------------"
# Single GPT partition for the whole disk
BOX_DISK_NUM=$1
PROVIDER=$2

if [ "${PROVIDER}" == "libvirt" ]; then
  DEVICE="vd"
elif [ "${PROVIDER}" == "virtualbox" ];  then
  DEVICE="sd"
else
  echo "Not supported provider: ${PROVIDER}"
  exit 1
fi

LETTER=`tr 0123456789 abcdefghij <<< $BOX_DISK_NUM`
parted -s -a optimal /dev/${DEVICE}${LETTER} mklabel gpt -- mkpart primary 2048s 100%

# LVM setup
pvcreate /dev/${DEVICE}${LETTER}1
vgcreate VolGroupU02 /dev/${DEVICE}${LETTER}1
lvcreate -l 100%FREE -n LogVolU02 VolGroupU02

# Make XFS
mkfs.xfs -f /dev/VolGroupU02/LogVolU02

# Set fstab
UUID=`blkid -s UUID -o value /dev/VolGroupU02/LogVolU02`
mkdir -p /u02
cat >> /etc/fstab <<EOF
UUID=${UUID}  /u02    xfs    defaults 1 2
EOF

# Mount
mount /u02
#----------------------------------------------------------
# EndOfFile
#----------------------------------------------------------
