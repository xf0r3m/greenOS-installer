#!/bin/bash

wget $ARCHIVE_LINK -O /mnt/$ARCHIVE;
tar -xzvf /mnt/$ARCHIVE -C /mnt
