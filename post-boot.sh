echo "Install docker"
apt update 
apt install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" 
apt-cache policy docker-ce 
apt install -y docker-ce 

HOMEDIR=$(./get-home.sh)
# Now you can use the HOMEDIR variable
echo "HOMEDIR: $HOMEDIR"

#bash -c "cd '$HOMEDIR' || exit; git clone '$REPO_URL'; cd Vitis-AI/board_setup/v70; source install.sh"

#usermod -aG docker ${USER}
#newgrp docker

# Specify the desired data directory
#new_data_path="/docker"

# Create the daemon.json file with the specified content
#echo '{
#  "data-root": "'"$new_data_path"'"
#}' | sudo tee /etc/docker/daemon.json > /dev/null

# Restart Docker
#sudo systemctl restart docker
#echo "Docker data directory updated to $new_data_path"
