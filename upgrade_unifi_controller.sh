#!/bin/sh

# upgrade_unifi_controller.sh
# Easy UniFi Controller Upgrade Script for Unix/Linux Systems
# by Steve Jenkins (stevejenkins.com)
# Version 2.3
# Last Updated January 8, 2017

# REQUIREMENTS
# 1) Assumes you already have any version of UniFi Controller installed 
#    and running on your system.
# 2) Assumes a user named "ubnt" owns the /opt/UniFi directory.
# 3) Requires a service start/stop script to properly shut down and 
#    restart the UniFi controller before and after upgrade. I've written
#    compatible startup scrips for SysV and systemd systems at 
#    http://wp.me/p1iGgP-2wl
# 4) Requires wget command to fetch the software from UBNT's download site.

# USAGE
# Modify the "UNIFI_DOWNLOAD_URL" variable below using the full URL of
# the UniFi Controller zip file on UBNT's download site. Optionally modify
# any of the additional variables below (defaults should work fine),
# then run the script!

# CONFIGURATION OPTIONS
UNIFI_DOWNLOAD_URL=http://dl.ubnt.com/unifi/$1/UniFi.unix.zip
UNIFI_BIN_INSTALL=/opt/unfi_version
UNIFI_ARCHIVE_FILENAME=$UNIFI_BIN_INSTALL/UniFi.$1-unix.zip
UNIFI_OWNER=unifi
UNIFI_SERVICE=unifi.service
UNIFI_PARENT_DIR=/usr/lib
UNIFI_DIR=/usr/lib/UniFi
UNIFI_BACKUP_DIR=/opt/UniFi_bak
UNIFI_BACKUP_FILE=unifi_ctrl_$(date +%d-%m-$Y_%Hh%M)
TEMP_DIR=/tmp

#### SHOULDN'T HAVE TO MODIFY PAST THIS POINT ####

if [ ! -d "$UNIFI_BIN_INSTAL" ];then
	mkdir $UNIFI_BIN_INSTAL
fi

# Jump into the backup directory
if [ ! -d "$UNIFI_BACKUP_DIR" ]; then
       	mkdir $UNIFI_BACKUP_DIR
fi
# Create progress dots function
show_dots() {
	while ps $1 >/dev/null ; do
	printf "."
	sleep 1
	done
	printf "\n"
}

# Let's DO this!
printf "Upgrading UniFi Controller...\n"

if [ ! -f "${UNIFI_ARCHIVE_FILENAME}" ]; then

    # Retrieve the updated zip archive from UBNT (overwriting any previous version)
    printf "\nDownloading %s from UBNT..." "$UNIFI_DOWNLOAD_URL"
    cd $TEMP_DIR || exit
    wget -qq $UNIFI_DOWNLOAD_URL -O $UNIFI_ARCHIVE_FILENAME &
    show_dots $!
fi

# Check to make sure we have a downloaded file to work with

if [ -f "$UNIFI_ARCHIVE_FILENAME" ]; then

	# Archive file exists, extract and install it

	# Stop the local UniFi Controller service
	printf "\n"
	service $UNIFI_SERVICE stop
	
	# Remove previous backup directory (if it exists)
	#if [ -d "$UNIFI_BACKUP_DIR" ]; then
#		printf "\nRemoving previous backup directory...\n"
#		rm -rf $UNIFI_BACKUP_DIR
#	fi
	
	# Move existing UniFi directory to backup location
	printf "\nBackup existing UniFi Controller directory to backup location...\n"
	if [ -f "$UNIFI_DIR" ];then
        if [ -f "$UNIFI_BACKUP_DIR" ];then
            tar -czvf $UNIFI_BACKUP_DIR/$UNIFI_BACKUP_FILE;tar.gz $UNIFI_DIR
            mv $UNIFI_DIR $UNIFI_BACKUP_DIR
        fi
	fi

	if [ -d "$UNIFI_PARENT_DIR" ];then
	    # Extract new version
	    printf "\nExtracting downloaded software..."
	    unzip -qq $UNIFI_ARCHIVE_FILENAME -d $UNIFI_PARENT_DIR &
	    show_dots $!
	fi


#
#	# Create an archive of the existing data directory
	if [ -d "$UNIFI_DIR" ]; then
#        printf "\nBacking up existing UniFi Controller data..."
#        tar zcf $TEMP_DIR/unifi_data_bak.tar.gz data/ &
        if [ -d "$UNIFI_BACKUP_DIR/UniFi/data" ]; then
            printf "\nExtracting UniFi Controller backup data to new directory..."
            cp -rf $UNIFI_BACKUP_DIR/UniFi/data/* $UNIFI_DIR/data/
            show_dots $!
        fi
	fi

	
	# Enforce proper ownership of UniFi directory
	chown -R $UNIFI_OWNER:$UNIFI_OWNER $UNIFI_DIR
	
	# Restart the local UniFi Controller service
	printf "\n"
	service $UNIFI_SERVICE start
	
	# All done!
	printf "\nUpgrade of UniFi Controller complete!\n"

	exit 0

else

	# Archive file doesn't exist, warn and exit
	printf "\nUniFi Controller software not found! Please check download link.\n"

	exit 1
fi
