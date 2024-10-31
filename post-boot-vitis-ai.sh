#!/bin/bash

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
sudo -u $USER docker pull xilinx/vitis-ai-$DOCKERIMAGE-cpu:latest
