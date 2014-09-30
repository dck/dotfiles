#!/bin/bash


function update {
    echo "Updating $@"
    sudo aptitude install $@
}

function install {
    echo "Installing $@"
    sudo aptitude install $@
}

function remove {
    echo "Removing $@"
    sudo apt-get purge --auto-remove $@
}


function main {
    echo "Updating system"
    sudo aptitude update > /dev/null

    remove brasero brasero-cdrkit brasero-common libbrasero-media3-1
    remove gthumb gthumb-data
    remove banshee
    remove totem gir1.2-totem-1.0 gir1.2-totem-plparser-1.0 libtotem-plparser18 libtotem0 totem-mozilla totem-common totem-plugins-extra totem-plugins
    remove pidgin pidgin-data libpurple0
    remove mintupload mintwelcome mintbackup
    remove simple-scan
    remove vino
    remove fonts-tlwg-mono mono-* libmono-*
    remove gir1.2-atspi-2.0 at-spi2-core python3-pyatspi qt-at-spi
    remove evolution-data-server evolution-data-server-common

    update firefox
    update thunderbird thunderbird-gnome-support thunderbird-locale-en

    install vlc vlc-nox vlc-plugin-notify vlc-plugin-pulse
    install conky
    install kupfer
    install keepassx
    install dropbox caja-dropbox
    install curl

    # btsync
    sh -c "$(curl -fsSL http://debian.yeasoft.net/add-btsync-repository.sh)"
    install btsync-gui

    # dev
    install vim
    install mercurial mercurial-common
    install virtualbox virtualbox-qt virtualbox-dkms
    install vagrant
    install python-pip python-virtualenv

}

main "${@}"
