#!/usr/bin/env bash

install_xrt() {
    echo "Install XRT"
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        echo "Ubuntu XRT install"
        echo "Installing XRT dependencies..."
        apt update
        echo "Installing XRT package..."
        apt install -y $XRT_BASE_PATH/$TOOLVERSION/$OSVERSION/$XRT_PACKAGE
    fi
    sudo bash -c "echo 'source /opt/xilinx/xrt/setup.sh' >> /etc/profile"
    sudo bash -c "echo 'source $VITIS_BASE_PATH/$VITISVERSION/settings64.sh' >> /etc/profile"
}

install_shellpkg() {

if [[ "$VCK5000" == 0 ]]; then
    echo "[WARNING] No FPGA Board Detected."
    exit 1;
fi
     
for PF in VCK5000; do
    if [[ "$(($PF))" != 0 ]]; then
        echo "You have $(($PF)) $PF card(s). "
        PLATFORM=`echo "alveo-$PF" | awk '{print tolower($0)}'`
        install_vck5000_shell
    fi
done
}

check_shellpkg() {
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        PACKAGE_INSTALL_INFO=`apt list --installed 2>/dev/null | grep "$PACKAGE_NAME" | grep "$PACKAGE_VERSION"`
    elif [[ "$OSVERSION" == "centos-8" ]]; then
        PACKAGE_INSTALL_INFO=`yum list installed 2>/dev/null | grep "$PACKAGE_NAME" | grep "$PACKAGE_VERSION"`
    fi
}

check_xrt() {
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        XRT_INSTALL_INFO=`apt list --installed 2>/dev/null | grep "xrt" | grep "$XRT_VERSION"`
    elif [[ "$OSVERSION" == "centos-8" ]]; then
        XRT_INSTALL_INFO=`yum list installed 2>/dev/null | grep "xrt" | grep "$XRT_VERSION"`
    fi
}

check_requested_shell() {
    SHELL_INSTALL_INFO=`/opt/xilinx/xrt/bin/xbmgmt examine | grep "$DSA"`
}

check_factory_shell() {
    SHELL_INSTALL_INFO=`/opt/xilinx/xrt/bin/xbmgmt examine | grep "$FACTORY_SHELL"`
}

install_vck5000_shell() {
    check_shellpkg
    if [[ $? != 0 ]]; then
        # echo "Download Shell package"
        # wget -cO - "https://www.xilinx.com/bin/public/openDownload?filename=$SHELL_PACKAGE" > /tmp/$SHELL_PACKAGE
        if [[ $SHELL_PACKAGE == *.tar.gz ]]; then
            echo "Untar the package. "
            tar xzvf $SHELL_BASE_PATH/$TOOLVERSION/$OSVERSION/$SHELL_PACKAGE -C /tmp/
            rm /tmp/$SHELL_PACKAGE
        fi
        echo "Install Shell"
        if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
            echo "Install Ubuntu shell package"
            apt-get install -y /tmp/xilinx*
        elif [[ "$OSVERSION" == "centos-8" ]]; then
            echo "Install CentOS shell package"
            yum install -y /tmp/xilinx*
        fi
        rm /tmp/xilinx*
    else
        echo "The package is already installed. "
    fi
}

flash_card() {
    echo "Flash Card(s). "
    /opt/xilinx/xrt/bin/xbmgmt program --base --device $PCI_ADDR
}

detect_cards() {
    lspci > /dev/null
    if [ $? != 0 ] ; then
        if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
            apt-get install -y pciutils
        elif [[ "$OSVERSION" == "centos-7" ]] || [[ "$OSVERSION" == "centos-8" ]]; then
            yum install -y pciutils
        fi
    fi
    if [[ "$OSVERSION" == "ubuntu-20.04" ]] || [[ "$OSVERSION" == "ubuntu-22.04" ]]; then
        PCI_ADDR=$(lspci -d 10ee: | awk '{print $1}' | head -n 1)
        if [ -n "$PCI_ADDR" ]; then
            VCK5000=$((VCK5000 + 1))
        else
            echo "Error: No card detected."
            exit 1
        fi
    fi
}

install_libs() {
    echo "Installing libs."
    sudo $VITIS_BASE_PATH/$VITISVERSION/scripts/installLibs.sh
}

XRT_BASE_PATH="/proj/octfpga-PG0/tools/deployment/xrt"
SHELL_BASE_PATH="/proj/octfpga-PG0/tools/deployment/vck5000"
XBFLASH_BASE_PATH="/proj/octfpga-PG0/tools/xbflash"
VITIS_BASE_PATH="/proj/octfpga-PG0/tools/Xilinx/Vitis"
CONFIG_FPGA_PATH="/proj/octfpga-PG0/tools/post-boot"

OSVERSION=`grep '^ID=' /etc/os-release | awk -F= '{print $2}'`
OSVERSION=`echo $OSVERSION | tr -d '"'`
VERSION_ID=`grep '^VERSION_ID=' /etc/os-release | awk -F= '{print $2}'`
VERSION_ID=`echo $VERSION_ID | tr -d '"'`
OSVERSION="$OSVERSION-$VERSION_ID"
TOOLVERSION=$1
VITISVERSION="2023.1"
SCRIPT_PATH=/local/repository
COMB="${TOOLVERSION}_${OSVERSION}"
XRT_PACKAGE=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $1}' | awk -F= '{print $2}'`
SHELL_PACKAGE=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $2}' | awk -F= '{print $2}'`
DSA=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $3}' | awk -F= '{print $2}'`
PACKAGE_NAME=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $5}' | awk -F= '{print $2}'`
PACKAGE_VERSION=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $6}' | awk -F= '{print $2}'`
XRT_VERSION=`grep ^$COMB: $SCRIPT_PATH/spec.txt | awk -F':' '{print $2}' | awk -F';' '{print $7}' | awk -F= '{print $2}'`
FACTORY_SHELL="xilinx_vck5000"
NODE_ID=$(hostname | cut -d'.' -f1)
#PCI_ADDR=$(lspci -d 10ee: | awk '{print $1}' | head -n 1)

detect_cards
check_xrt
if [ $? == 0 ]; then
    echo "XRT is already installed."
else
    echo "XRT is not installed. Attempting to install XRT..."
    install_xrt

    check_xrt
    if [ $? == 0 ]; then
        echo "XRT was successfully installed."
    else
        echo "Error: XRT installation failed."
        exit 1
    fi
fi

install_libs

# Install remote desktop
sudo apt update
echo "Installing remote desktop software"
sudo apt install -y ubuntu-gnome-desktop
echo "Installed gnome desktop"
sudo systemctl set-default multi-user.target
sudo apt install -y tigervnc-standalone-server

DOCKERIMAGE=$1
echo "$DOCKERIMAGE" > /local/repository/dockerimage.txt
echo "Install docker"
apt update 
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" 
apt-cache policy docker-ce 
apt install -y docker-ce 

SCRIPTNAME=$0
#
GENIUSER=`geni-get user_urn | awk -F+ '{print $4}'`
if [ $? -ne 0 ]; then
echo "ERROR: could not run geni-get user_urn!"
exit 1
fi
if [ $USER != $GENIUSER ]; then
sudo -u $GENIUSER $SCRIPTNAME
exit $?
fi
echo "Home directory:"
HOMEDIR="/users/$USER"
echo "$HOMEDIR"
REPO_URL="https://github.com/OCT-FPGA/Vitis-AI"

docker_dir="/docker"
sudo chmod 755 $docker_dir
sudo chown $USER:octfpga-PG0 $docker_dir
bash -c "cd '$docker_dir' && git clone -b 3.0 '$REPO_URL' && cd Vitis-AI/board_setup/vck5000; source install.sh"

sudo usermod -aG docker $USER
newgrp docker

# Specify the desired data directory
new_data_path="/docker"

# Create the daemon.json file with the specified content
echo '{
  "data-root": "'"$new_data_path"'"
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker
sudo systemctl restart docker
echo "Docker data directory updated to $new_data_path"

# Download Vitis AI docker image
DOCKERIMAGE=$(cat /local/repository/dockerimage.txt)
sudo -u $USER docker pull xilinx/vitis-ai-$DOCKERIMAGE-cpu:latest# Install remote desktop
sudo apt update
echo "Installing remote desktop software"
sudo apt install -y ubuntu-gnome-desktop
echo "Installed gnome desktop"
sudo systemctl set-default multi-user.target
sudo apt install -y tigervnc-standalone-server

DOCKERIMAGE=$1
echo "$DOCKERIMAGE" > /local/repository/dockerimage.txt
echo "Install docker"
apt update 
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" 
apt-cache policy docker-ce 
apt install -y docker-ce 

SCRIPTNAME=$0
#
GENIUSER=`geni-get user_urn | awk -F+ '{print $4}'`
if [ $? -ne 0 ]; then
echo "ERROR: could not run geni-get user_urn!"
exit 1
fi
if [ $USER != $GENIUSER ]; then
sudo -u $GENIUSER $SCRIPTNAME
exit $?
fi
echo "Home directory:"
HOMEDIR="/users/$USER"
echo "$HOMEDIR"
REPO_URL="https://github.com/OCT-FPGA/Vitis-AI"

docker_dir="/docker"
sudo chmod 755 $docker_dir
sudo chown $USER:octfpga-PG0 $docker_dir
bash -c "cd '$docker_dir' && git clone -b 3.0 '$REPO_URL' && cd Vitis-AI/board_setup/vck5000; source install.sh"

sudo usermod -aG docker $USER
newgrp docker

# Specify the desired data directory
new_data_path="/docker"

# Create the daemon.json file with the specified content
echo '{
  "data-root": "'"$new_data_path"'"
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker
sudo systemctl restart docker
echo "Docker data directory updated to $new_data_path"

# Download Vitis AI docker image
DOCKERIMAGE=$(cat /local/repository/dockerimage.txt)
sudo -u $USER docker pull xilinx/vitis-ai-$DOCKERIMAGE-cpu:latest

check_shellpkg
if [ $? == 0 ]; then
    echo "Shell is already installed."
    if check_requested_shell ; then
        echo "FPGA shell verified."
    else
        echo "Error: FPGA shell couldn't be verified."
        exit 1
    fi
else
    echo "Shell is not installed. Installing shell..."
    install_shellpkg
    check_shellpkg
    if [ $? == 0 ]; then
        echo "Shell was successfully installed. Flashing..."
        #flash_card
        #/usr/local/bin/post-boot-fpga
        #echo "Cold rebooting..."
        #sudo -u geniuser perl /local/repository/cold-reboot.pl
    else
        echo "Error: Shell installation failed."
        exit 1
    fi
fi
