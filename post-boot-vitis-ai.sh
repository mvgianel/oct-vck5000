#!/bin/bash

set -e
exec > /local/logs/post_boot.log 2>&1

# === System update ===
sudo apt update

# === Install Remote Desktop ===
echo "[INFO] Installing GNOME and TigerVNC..."
sudo apt install -y ubuntu-gnome-desktop tigervnc-standalone-server
sudo systemctl set-default multi-user.target

# === Install Docker ===
echo "[INFO] Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
sudo apt update
sudo apt install -y docker-ce

# === Docker setup ===
DOCKERIMAGE=$1
echo "$DOCKERIMAGE" > /local/repository/dockerimage.txt

GENIUSER=$(geni-get user_urn | awk -F+ '{print $4}')
if [ $? -ne 0 ]; then
  echo "ERROR: could not run geni-get user_urn!"
  exit 1
fi
if [ "$USER" != "$GENIUSER" ]; then
  sudo -u $GENIUSER $0
  exit $?
fi

echo "[INFO] Setting up Docker Vitis-AI repo..."
HOMEDIR="/users/$USER"
REPO_URL="https://github.com/OCT-FPGA/Vitis-AI"
docker_dir="/docker"
sudo chmod 755 $docker_dir
sudo chown $USER:octfpga-PG0 $docker_dir
bash -c "cd '$docker_dir' && git clone -b 3.0 '$REPO_URL' && cd Vitis-AI/board_setup/vck5000 && source install.sh"

sudo usermod -aG docker $USER
newgrp docker

echo '{
  "data-root": "'"$docker_dir"'"
}' | sudo tee /etc/docker/daemon.json > /dev/null
sudo systemctl restart docker

# === Download Docker image ===
DOCKERIMAGE=$(cat /local/repository/dockerimage.txt)
sudo -u $USER docker pull xilinx/vitis-ai-$DOCKERIMAGE-cpu:latest

# === Install Python 3.8 ===
echo "[INFO] Installing Python 3.8..."
sudo apt install -y python3.8 python3.8-dev python3.8-venv
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# === Install GCC 7.3.1 ===
echo "[INFO] Installing GCC 7.3.1..."
sudo apt install -y gcc-7 g++-7
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100

# === Install OpenCV 3.0.0 ===
echo "[INFO] Installing OpenCV 3.0.0..."
sudo apt install -y cmake unzip pkg-config \
  libjpeg-dev libpng-dev libtiff-dev \
  libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
  libxvidcore-dev libx264-dev libgtk2.0-dev \
  libatlas-base-dev gfortran python3.8-dev

python3.8 -m pip install --upgrade pip numpy

cd /tmp
OPENCV_VERSION="3.0.0"
wget -q https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip
unzip -q $OPENCV_VERSION.zip
cd opencv-$OPENCV_VERSION
mkdir build && cd build

PYTHON_EXEC=$(which python3.8)
PYTHON_INCLUDE=$(python3.8 -c "from sysconfig import get_paths as gp; print(gp()['include'])")
PYTHON_SITEPKG=$(python3.8 -c "from distutils.sysconfig import get_python_lib")
PYTHON_LIBRARY=$(find /usr/lib -name "libpython3.8.so" | head -n 1)

cmake -DBUILD_SHARED_LIBS=OFF \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DBUILD_opencv_python2=OFF \
      -DBUILD_opencv_python3=ON \
      -DPYTHON3_EXECUTABLE=$PYTHON_EXEC \
      -DPYTHON3_INCLUDE_DIR=$PYTHON_INCLUDE \
      -DPYTHON3_LIBRARY=$PYTHON_LIBRARY \
      -DPYTHON3_PACKAGES_PATH=$PYTHON_SITEPKG \
      -DWITH_IPP=OFF -DWITH_TBB=OFF ..

make -j$(nproc)
sudo make install
sudo ldconfig

CV2_SO=$(find . -name "cv2*.so" | head -n 1)
if [ -f "$CV2_SO" ]; then
  sudo cp "$CV2_SO" "$PYTHON_SITEPKG/"
  echo "[INFO] cv2 module installed successfully to $PYTHON_SITEPKG"
else
  echo "[ERROR] cv2.so not found after build"
  exit 1
fi

echo "[INFO] All installations completed!"
