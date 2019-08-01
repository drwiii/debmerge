#!/bin/bash

# debmerge - Merging script for Debian GNU/Linux DVD ISOs
# Copyright (C) 2019 Douglas Winslow
# Licensed under the GPLv2

#####################################################################
# ---= INTRODUCTION =---
#
# USER INTERVENTION REQUIRED,
# see the PREPARATION area of this file.
#
# This script merges multiple Debian DVDs into an ISO file which can
# be written to a larger medium, such as a compact USB drive.  The
# process currently requires a superuser password, however, if you
# have something which can extract ISO files, you can replace the
# relevant loop mount commands in this script before starting.
#
# We will be using the /dev/loop0 loop device.  Your kernel should
# be configured to support loop mounting capability.  This allows it
# to mount a file such as an .iso as if it were inserted in a CD or
# DVD drive.
#
# I made this for personal use, so please let me know if you have
# any questions.  You need to have at least the first Debian DVD
# for this to work as intended, and even then, you should get the
# others.  There are 16 DVDs in the Debian 10.0.0 release; if you
# can get this to merge all of them, consider that you are a pretty
# cool person.

#####################################################################
# ---= PREPARATION =---
#
# You can download Debian ISO files from the following URL:
# <https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/>
#
# 5206549aab4b54026aa6dcd026f8ffcb  debian-10.0.0-amd64-DVD-1.iso
# 7dde7b1787bd1d628958d915e92c2e0d  debian-10.0.0-amd64-DVD-2.iso
# edf3256c7504a0694be25d4d9367009d  debian-10.0.0-amd64-DVD-3.iso
#
# 1) Place these .iso files in the current directory
# 2) Review this script to see what it does
# 3) Make any necessary edits (merging more or less DVDs, etc.)
# 4) Note that it is normal to see some errors in this version
# 5) The resulting ISO file should boot in VirtualBox or on most PCs
# 6) ???
# 7) PROFIT!

#####################################################################
# ---= DEBIAN DRIVER SUPPORT =---
#
# If you make a directory called firmware/, you can extract the
# popular firmware.zip file for extended driver support.  If you
# do this, be sure to uncomment the relevant lines below which
# permit this to be added to your resulting ISO file.  Be sure to
# read the licensing concerns of doing this.

#####################################################################
# ---= DISK SPACE =---
#
# IMPORTANT: These files take up 13 gigabytes of disk space to begin
# with, so keep in mind that we will be using a lot of space:
#
# * Saving the ISO files to this directory (you do this)
# * Extracting them to a temporary directory (this does this)
# * Creating another ISO file as our result (maybe this works)

#####################################################################
# ---= INSTALLER DISC LABEL =---
#
# There are files in the resulting .disk/ directory that should be
# changed to note the fact that the resulting ISO file is not an
# official DVD, as well as the command to make the file.  This
# version of the script does not yet perform this action.

echo "
Debian multi-disc media merging script [drw 31-Jul-2019]
Douglas Winslow <https://github.com/drwiii>

** If you haven't read this script yet, exit and do so please! **

Now, let's choose whether to proceed.
 If no, you would like to exit? Press Control+C to cancel.
 Or yes, to continue? Press your [Return] or [Enter] key.
"

echo -n "? "
read i

echo
echo "* Preparing loop device"
sudo umount /dev/loop0
sudo losetup -d /dev/loop0

echo "* Creating/resetting staging directory"
sudo rm -r CD1/
mkdir CD1/

echo "* Creating/resetting mountpoint directory"
sudo umount mnt/
sudo rm -r mnt/
mkdir mnt/

echo "* Removing any previous output attempt"
rm debian-10.0.0-amd64.iso

echo "* Extracting ISOLINUX boot sector"
dd if=debian-10.0.0-amd64-DVD-1.iso of=isolinux.bin bs=1 count=432

merge_disc()
{
	echo "* Merging ISO file: \"$1\""
	sudo losetup /dev/loop0 $1
	sudo mount /dev/loop0 ./mnt/ -o ro
	cp -npR mnt/.disk CD1/
	cp -npR mnt/* CD1/
	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0
#	rm $1
	sudo chmod -R u+w CD1/
}

merge_disc debian-10.0.0-amd64-DVD-1.iso
merge_disc debian-10.0.0-amd64-DVD-2.iso
merge_disc debian-10.0.0-amd64-DVD-3.iso

#echo "* Merging extended firmware directory"
#sudo rm -r CD1/firmware/
#cp -npR firmware/ CD1/

echo "* Producing MD5 catalog for integrity verification"
rm md5sum.txt CD1/md5sum.txt
cd CD1/
for i in `find . \( \! -wholename './isolinux/*' \) | sort`;
 do
   if [ \! -d $i ]; then md5sum $i >> ../md5sum.txt; fi;
 done
cd ..
mv md5sum.txt CD1/

echo "* Creating target ISO file"
xorriso -as mkisofs -r -checksum_algorithm_iso md5,sha1,sha256,sha512 -V \
'Debian 10.0.0 amd64 1' -o debian-10.0.0-amd64.iso -J -joliet-long \
-cache-inodes -isohybrid-mbr isolinux.bin -b isolinux/isolinux.bin \
-c isolinux/boot.cat -boot-load-size 4 -boot-info-table -no-emul-boot \
-eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
-isohybrid-gpt-basdat -isohybrid-apm-hfsplus -quiet CD1

echo "* Cleaning up temporary files"
sudo rm -r CD1/ mnt/
rm isolinux.bin

echo "* Finished"
echo

ls -l debian-10.0.0-amd64.iso

exit
