#!/bin/bash


function update {
    echo "Updating $1"
    sudo aptitude install -y ${@:2} > /dev/null
}

function install {
    echo "Installing $1"
    sudo aptitude install -y ${@:2} > /dev/null
}

function remove {
    echo "Removing $1"
    sudo apt-get purge --auto-remove -y ${@:2} > /dev/null
}


function main {
    echo "Updating system"
    sudo aptitude update > /dev/null

    remove "brasero" brasero brasero-cdrkit brasero-common libbrasero-media3-1
    remove "gthumb" gthumb gthumb-data
    remove "banshee" banshee
    remove "totem" totem gir1.2-totem-1.0 gir1.2-totem-plparser-1.0 libtotem-plparser18 libtotem0 totem-mozilla totem-common totem-plugins-extra totem-plugins
    remove "pidgin" pidgin pidgin-data libpurple0
    remove "mintutils" mintupload mintwelcome mintbackup
    remove "simple-scan" simple-scan


    install "mercurial" mercurial mercurial-common
    install "vim" vim
    install "vlc" vlc vlc-nox vlc-plugin-notify vlc-plugin-pulse

    update "firefox" firefox
    update "thunderbird" thunderbird
}

