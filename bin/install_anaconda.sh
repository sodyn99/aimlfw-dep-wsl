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

echo "Starting Anaconda installation..."
wget -q $ANACONDA_URL -O $INSTALLER
check_status "Downloading Anaconda"

chmod +x $INSTALLER

echo "Installing Anaconda to $INSTALL_DIR (this may take a few minutes)..."
./$INSTALLER -b -p $INSTALL_DIR
check_status "Anaconda installation"

echo "Configuring conda environment..."
source "$INSTALL_DIR/bin/activate"
conda init
check_status "Conda initialization"

rm $INSTALLER

echo "Installing additional packages and configuring PATH..."
conda install -y argcomplete
echo 'export PATH=~/anaconda3/bin:~/anaconda3/condabin:$PATH' >> ~/.bashrc
echo "$(register-python-argcomplete conda)" >> ~/.bashrc
source ~/.bashrc
conda config --set auto_activate_base false
check_status "Anaconda configuration"
