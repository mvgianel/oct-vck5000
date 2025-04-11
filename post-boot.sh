#!/bin/bash

set -e

# Update package lists
sudo apt update

# Install Python 3.8 and set it as default
sudo apt install -y python3.8 python3.8-venv python3.8-dev
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# Install GCC 7.3.1 and set it as default
sudo apt install -y gcc-7 g++-7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100

# Install dependencies for OpenCV
sudo apt install -y cmake unzip pkg-config \
    libjpeg-dev libpng-dev libtiff-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libgtk2.0-dev \
    libatlas-base-dev gfortran

# Download and install OpenCV 3.0.0
cd /tmp
OPENCV_VERSION="3.0.0"
wget -q https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip
unzip -q $OPENCV_VERSION.zip
cd opencv-$OPENCV_VERSION
mkdir build && cd build

cmake -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_opencv_python2=OFF \
      -DBUILD_opencv_python3=ON \
      -DPYTHON3_EXECUTABLE=$(which python3) \
      -DPYTHON3_INCLUDE_DIR=$(python3 -c "from sysconfig import get_paths as gp; print(gp()['include'])") \
      -DPYTHON3_LIBRARY=$(python3 -c "from sysconfig import get_config_var as gcv; print(gcv('LIBDIR'))") \
      -DWITH_IPP=OFF \
      -DWITH_TBB=OFF ..

make -j$(nproc)
sudo make install
sudo ldconfig

# Clean up
cd ~
rm -rf /tmp/opencv-$OPENCV_VERSION /tmp/$OPENCV_VERSION.zip

# Install XRT 2022.1
# Assuming you have the XRT .deb package available at /local/repository/xrt_2022.1.deb
sudo apt install -y /local/repository/xrt_2022.1.deb

# Install Vitis and Vivado 2022.1
# Assuming you have the installers available at /local/repository/Vitis_2022.1_installer.sh and /local/repository/Vivado_2022.1_installer.sh
chmod +x /local/repository/Vitis_2022.1_installer.sh
chmod +x /local/repository/Vivado_2022.1_installer.sh
sudo /local/repository/Vitis_2022.1_installer.sh
sudo /local/repository/Vivado_2022.1_installer.sh

# Source environment settings
echo 'source /opt/Xilinx/Vitis/2022.1/settings64.sh' >> ~/.bashrc
echo 'source /opt/Xilinx/Vivado/2022.1/settings64.sh' >> ~/.bashrc
echo 'source /opt/xilinx/xrt/setup.sh' >> ~/.bashrc
