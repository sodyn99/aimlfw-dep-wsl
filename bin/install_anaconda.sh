#!/bin/bash

check_status() {
    if [ $? -eq 0 ]; then
        echo -e "\e[32m✓ $1 successful\e[0m"
    else
        echo -e "\e[31m✗ $1 failed\e[0m"
        exit 1
    fi
}

ANACONDA_URL="https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh"
INSTALLER="Anaconda3-2024.06-1-Linux-x86_64.sh"
INSTALL_DIR="$HOME/anaconda3"

wget -q $ANACONDA_URL -O $INSTALLER
check_status "Downloading Anaconda"

chmod +x $INSTALLER

./$INSTALLER -b -p $INSTALL_DIR

source "$INSTALL_DIR/bin/activate"
conda init

rm $INSTALLER
check_status "Installing Anaconda"

conda install -y argcomplete
echo 'export PATH=~/anaconda3/bin:~/anaconda3/condabin:$PATH' >> ~/.bashrc
echo "eval \"$(register-python-argcomplete conda)\"" >> ~/.bashrc
source ~/.bashrc
conda config --set auto_activate_base false
conda init
source ~/.bashrc

check_status "Configuring Anaconda"
