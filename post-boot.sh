echo "Install docker"
apt update 
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" 
apt-cache policy docker-ce 
apt install -y docker-ce 
usermod -aG docker ${USER}

bash -c 'cd /local/repository && git clone https://github.com/OCT-FPGA/Vitis-AI && cd Vitis-AI/board_setup/v70 && source install.sh'

#mkdir /docker 
#/usr/local/etc/emulab/mkextrafs.pl /docker 

# Specify the desired data directory
new_data_path="/docker"

# Create the daemon.json file with the specified content
echo '{
  "data-root": "'"$new_data_path"'"
}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker
sudo systemctl restart docker
echo "Docker data directory updated to $new_data_path"
