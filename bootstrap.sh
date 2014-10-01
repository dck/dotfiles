#!/bin/bash

workdir=$(pwd)

ln -s $(workdir)/vim ~/.vim
ln -s ~/.vim/.vimrc ~/.vimrc

ln -s $(workdir)/sublime-text-3 ~/.config/sublime-text-3

ln -s $(workdir)/.bashrc ~/.bashrc
ln -s $(workdir)/.conkyrc ~/.conkyrc

