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

install_extra() {
# === Install Python 3.8 ===
echo "[INFO] Installing Python 3.8..."
sudo apt update
sudo apt install -y python3.8 python3.8-venv python3.8-dev \
  libjpeg-dev \
  libpng-dev \
  libtiff-dev \
  libjasper-dev
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1

# === Install GCC 7.3.1 ===
echo "[INFO] Installing GCC 7.3.1..."
#sudo apt install -y gcc-7 g++-7
#sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 100
#sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 100
wget http://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.gz \
&& tar -xzf gcc-7.3.0.tar.gz \
&& cd gcc-7.3.0 && ./contrib/download_prerequisites \
&& mkdir build && cd build \
&& ../configure \
    --disable-multilib \
    --disable-libsanitizer \
    --enable-languages=c,c++ \
    --prefix=/opt/gcc-7.3.1 \
&& make -j$(nproc) && make install \
&& ln -s /opt/gcc-7.3.1/bin/gcc /usr/local/bin/gcc-7.3 \
&& ln -s /opt/gcc-7.3.1/bin/g++ /usr/local/bin/g++-7.3 \
&& cd / && rm -rf /tmp/gcc-7.3.0*


# === Install OpenCV 3.0.0 (Static Build) ===
echo "[INFO] Installing OpenCV 3.0.0 (static build)..."

# Required dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y \
    build-essential cmake git pkg-config \
    libgtk2.0-dev libavcodec-dev libavformat-dev libswscale-dev \
    libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev \
    python3-dev python3-numpy \
    wget unzip

# Download and extract
wget https://github.com/opencv/opencv/archive/3.0.0.zip -O opencv-3.0.0.zip
unzip opencv-3.0.0.zip
cd opencv-3.0.0

# Configure static build
mkdir build && cd build
cmake \
  -D CMAKE_BUILD_TYPE=RELEASE \
  -D CMAKE_INSTALL_PREFIX=/usr/local \
  -D BUILD_SHARED_LIBS=OFF \
  -D WITH_FFMPEG=OFF \
  -D WITH_V4L=OFF \
  -D WITH_LIBV4L=OFF \
  -D WITH_1394=OFF \
  -D WITH_GTK=OFF \
  -D WITH_VIDEOIO=OFF \
  -D WITH_JPEG=ON \
  -D WITH_PNG=ON \
  -D WITH_TIFF=ON \
  -D WITH_JASPER=ON \
  -D BUILD_EXAMPLES=OFF \
  -D BUILD_TESTS=OFF \
  -D BUILD_PERF_TESTS=OFF \
  ..

make -j$(nproc)
sudo make install
sudo ldconfig

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
VITISVERSION="2022.1"
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

sudo apt update
echo "Installing remote desktop software"
sudo apt install -y ubuntu-gnome-desktop
echo "Installed gnome desktop"
sudo systemctl set-default multi-user.target
sudo apt install -y tigervnc-standalone-server

install_extra
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
