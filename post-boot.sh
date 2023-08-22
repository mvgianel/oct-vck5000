echo "Downloading XRT"
mkdir -p /local/repository/scripts
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_xrt.sh" > /local/repository/scripts/install_xrt.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_xrm.sh" > /local/repository/scripts/install_xrm.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_v70_xclbins.sh" > /local/repository/scripts/install_v70_xclbins.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_v70_shell.sh" > /local/repository/scripts/install_v70_shell.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/install.sh" > /local/repository/install.sh
apt update
cd /local/repository
bash ./install.sh

# Install V70 card platform
wget -cO - "https://www.xilinx.com/bin/public/openDownload?filename=xilinx-v70-gen5x8-qdma-base_2-20221028_all.deb.tar.gz" > /tmp/shell.tgz
tar xzvf /tmp/shell.tgz -C /tmp/
apt-get install -y /tmp/xilinx*

# Install the DPU xclbin
wget -cO - "https://www.xilinx.com/bin/public/openDownload?filename=DPUCV2DX8G_xclbins_3_0_0.tar.gz" > /tmp/xclbins.tar.gz
tar -xzf /tmp/xclbins.tar.gz --directory /
rm /tmp/xclbins.tar.gz
