echo "Downloading XRT"
mkdir -p /local/repository/scripts
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_xrt.sh" > /local/repository/scripts/install_xrt.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_xrm.sh" > /local/repository/scripts/install_xrm.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_v70_xclbins.sh" > /local/repository/scripts/install_v70_xclbins.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/scripts/install_v70_shell.sh" > /local/repository/scripts/install_v70_shell.sh
wget -cO - "https://raw.githubusercontent.com/Xilinx/Vitis-AI/master/board_setup/v70/install.sh" > /local/repository/install.sh
