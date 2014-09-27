#!/bin/bash

echo "Updating system"
sudo aptitude update > /dev/null

echo "Removing brasero"
sudo apt-get purge --auto-remove brasero brasero-cdrkit brasero-common libbrasero-media3-1

echo "Updating firefox"
sudo aptitude install firefox