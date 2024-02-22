#!/bin/bash
# License: MIT. See license file in root directory
# Copyright(c) JetsonHacks (2017-2019)
trap cleanup ERR
INSTALL_DIR=/usr/local
# Version
OPENCV_VERSION=4.5.4
# Jetson AGX Orin
CUDA_ARCH_BIN=8.7
PTX="sm_87"
CUDNN='8.9'
# Download the opencv_extras repository
# If you are installing the opencv testdata, i.e.
# OPENCV_TEST_DATA_PATH=../opencv_extra/testdata
# Make sure that you set this to 1
# Value should be 1 or 0
TEST_OPENCV=0
# Value in order to packaging OpenCV
PACKAGE_OPENCV=0
# Source code directory will be /tmp/build_opencv
OPENCV_SOURCE_DIR=$HOME
WHEREAMI=$PWD
# NUM_JOBS is the number of jobs to run simultaneously when using make
# Alognside better board detection. 
# If it has 6 or more cpus, it probably has a ton of ram too
CPUS=$(nproc)
if [[ $CPUS -gt 5 ]]; then
    # something with a ton of ram
    NUM_JOBS=$CPUS
else
    NUM_JOBS=1  # you can set this to 4 if you have a swap file
    # otherwise a Nano will choke towards the end of the build
fi

cleanup () {
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    while true ; do
        echo "Do you wish to remove temporary build files in /tmp/build_opencv ? "
        if ! [[ "$1" = "--test-warning" ]] ; then
            echo "(Doing so may make running tests on the build later impossible)"
        fi
        read -rp "Y/N " yn
        case ${yn} in
            [Yy]* ) sudo rm -rf /tmp/build_opencv ; break;;
            [Nn]* ) exit ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
}

setup () {
    if [[ -d "/tmp/build_opencv" ]] ; then
        echo "It appears an existing build exists in /tmp/build_opencv"
        cleanup
    fi
    mkdir -p /tmp/build_opencv
    OPENCV_SOURCE_DIR=/tmp/build_opencv
}

remove () {
    while true ; do
	echo "Do you want to remove OpenCV completely from your system? "
	read -rp "Y/N " yn
        case ${yn} in
	    [Yy]* ) sudo find / -name ' *opencv* ' -exec rm -i '{}' \; ;
     		    CHECK_PKG="$(pkg-config --modversion opencv)" ;
		    if [[ "$CHECK_PKG" != ^[3-5]* ]]
      		    then
			echo "Purge Completed."
		    fi
     		    break;;
            [Nn]* ) exit ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
}

usage () {
    echo "usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]"
    echo "-s | --sourcedir   Directory in which to place the opencv sources (default $HOME)"
    echo "-i | --installdir  Directory in which to install opencv libraries (default /usr/local)"
    echo "-r | --remove      Ask to remove previous installations from OpenCV of your system alongside all files related."
    echo "-t | --test        Download examples and test the OpenCV after building."
    echo "-p | --package     Package OpenCV as .deb file to install in other JETSON equipments."
    echo "-h | --help        This message"
}

install_dependencies () {
	# open-cv has a lot of dependencies, but most can be found in the default
	# package repository or should already be installed (eg. CUDA).
	echo "Installing build dependencies."
	sudo apt-add-repository universe
	sudo apt update -y
	sudo apt dist-upgrade -y --autoremove
	
	# Download dependencies for the desired configuration
	cd $HOME
	sudo apt install -y \
		software-properties-common \
	    build-essential \
	    cmake \
	    libavcodec-dev \
	    libavformat-dev \
	    libavutil-dev \
	    libeigen3-dev \
	    libglew-dev \
	    libgtk2.0-dev \
	    libgtk-3-dev \
	    libjpeg-dev \
	    libpng-dev \
	    libpostproc-dev \
	    libswscale-dev \
	    libtbb-dev \
	    libtiff5-dev \
	    libv4l-dev \
	    libxvidcore-dev \
	    libx264-dev \
	    zlib1g-dev \
		pkg-config
	
	# Python 2.7
	# sudo apt-get install -y python-dev  python-numpy  python-py  python-pytest
	# Python 3.x
	sudo apt install -y python3-dev python3-numpy python3-py python3-pytest
	# GStreamer support
	sudo apt install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev 
	# QT5 support
	sudo apt install -y qt5-default
 
 	# In order to support OpenGL, we need a little magic to help
	# https://devtalk.nvidia.com/default/topic/1007290/jetson-tx2/building-opencv-with-opengl-support-/post/5141945/#5141945
	cd /usr/local/cuda/include
	sudo patch -N cuda_gl_interop.h $WHEREAMI'/patches/OpenGLHeader.patch' 
}

download_sources() {
    cd $OPENCV_SOURCE_DIR
    echo "Getting version '$OPENCV_VERSION' of OpenCV"
    git clone --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv.git
    git clone --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv_contrib.git
    # checking the correct TAG
    echo "Downloaded: $(cd ./opencv/ | git log | grep --colour=auto -o 4.5.4)"

    if [ "$TEST_OPENCV" -eq 1 ] ; then
	echo "Installing opencv_extras for the test data"
  	cd $OPENCV_SOURCE_DIR
   	git clone --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv_extra.git
    fi
}

configure () {
	# Fix for Eigen
	cd $OPENCV_SOURCE_DIR/opencv
	sed -i 's/include <Eigen\/Core>/include <eigen3\/Eigen\/Core>/g' modules/core/include/opencv2/core/private.hpp
	
	echo $PWD
	CMAKEFLAGS="
 		-D CMAKE_BUILD_TYPE=RELEASE
		-D CMAKE_INSTALL_PREFIX=${INSTALL_DIR}
		-D OPENCV_EXTRA_MODULES_PATH=${OPENCV_SOURCE_DIR}/opencv_contrib/modules
		-D OPENCV_GENERATE_PKGCONFIG=YES
		-D OPENCV_ENABLE_NONFREE=ON
		
		-D ENABLE_NEON=ON
		-D WITH_EIGEN=ON
		-D EIGEN_INCLUDE_PATH=/usr/include/eigen3
		 
		-D WITH_OPENCL=OFF
		-D WITH_OPENGL=ON
		
	    -D WITH_CUDA=ON
	    -D CUDA_ARCH_BIN=${CUDA_ARCH_BIN}
	    -D CUDA_ARCH_PTX=${PTX}
	    -D WITH_CUDNN=ON
	 	-D CUDNN_VERSION=${CUDNN}
	  	-D WITH_CUBLAS=ON
      	-D OPENCV_DNN_CUDA=ON
      	-D ENABLE_FAST_MATH=ON
      	-D CUDA_FAST_MATH=ON
		-D WITH_TBB=ON
  		-D BUILD_TBB=ON
		-D WITH_OPENMP=ON
  		-D WITH_PROTOBUF=ON
	  	-D BUILD_PROTOBUF=ON
	      
	   	-D WITH_V4L=ON
	 	-D WITH_LIBV4L=ON
   		-D WITH_FFMPEG=ON
	 	-D WITH_GSTREAMER=ON
		-D WITH_GSTREAMER_0_10=OFF
	 
	    -D WITH_QT=ON
	    -D BUILD_opencv_python3=ON
	    -D BUILD_opencv_python2=OFF
	    -D BUILD_JAVA=OFF
	      	
	    -D CPU_BASELINE=VFPV3"
	
	if [ "$PACKAGE_OPENCV" -eq 1 ] ; then
		CMAKEFLAGS="
	    ${CMAKEFLAGS}
	    -D CPACK_BINARY_DEB=ON"
	fi
	
	if [ "$TEST_OPENCV" -eq 1 ] ; then
	    CMAKEFLAGS="
		    ${CMAKEFLAGS}
		    -D INSTALL_TESTS=ON
		    -D OPENCV_TEST_DATA_PATH=${OPENCV_SOURCE_DIR}/opencv_extra/testdata
		    -D BUILD_TESTS=ON
		    -D BUILD_PERF_TESTS=ON
		    -D BUILD_EXAMPLES=ON
		    -D INSTALL_C_EXAMPLES=ON
		    -D INSTALL_PYTHON_EXAMPLES=ON"; else
	    CMAKEFLAGS="
		    ${CMAKEFLAGS}
		    -D BUILD_TESTS=OFF
		    -D BUILD_PERF_TESTS=OFF
		    -D BUILD_EXAMPLES=OFF
		    -D INSTALL_C_EXAMPLES=OFF
		    -D INSTALL_PYTHON_EXAMPLES=OFF"
	fi
	
	# Create the build directory and start cmake
	mkdir -p $OPENCV_SOURCE_DIR/opencv/build
	cd $OPENCV_SOURCE_DIR/opencv/build
	time cmake ${CMAKEFLAGS} .. 2>&1 | tee -a configure.log

	if [ $? -eq 0 ] ; then
	  echo "CMake configuration make successful"
	else
	  echo "CMake issues " >&2
	  echo "Please check the configuration being used"
	  exit 1
	fi
}

build () {
	cd $OPENCV_SOURCE_DIR/opencv/build
	# Consider the MAXN performance mode if using a barrel jack on the Nano
	time make -j$NUM_JOBS 2>&1 | tee -a build.log
	if [ $? -eq 0 ] ; then
	  echo "OpenCV make successful"
	else
	  # Try to make again; Sometimes there are issues with the build
	  # because of lack of resources or concurrency issues
	  echo "Make did not build " >&2
	  echo "Retrying ... "
	  # Single thread this time
	  make
	  if [ $? -eq 0 ] ; then
	    echo "OpenCV make successful"
	  else
	    # Try to make again
	    echo "Make did not successfully build" >&2
	    echo "Please fix issues and retry build"
	    exit 1
	  fi
	fi
	
	if [[ "${TEST_OPENCV}" ]] ; then
		make test 2>&1 | tee -a test.log
	fi
}

install () {
	echo "Installing ... "
 	cd $OPENCV_SOURCE_DIR/opencv/build
	if [[ -w ${PREFIX} ]] ; then
	    make install 2>&1 | tee -a install.log
	else
	    sudo make install 2>&1 | tee -a install.log
	fi
	
	sudo ldconfig -v
	
	if [ $? -eq 0 ] ; then
	   echo "OpenCV installed in: $INSTALL_DIR"
	else
	   echo "There was an issue with the final installation"
	   exit 1
	fi
}

wrap () {
	# If PACKAGE_OPENCV is on, pack 'er up and get ready to go!
	# We should still be in the build directory ...
	cd $OPENCV_SOURCE_DIR/opencv/build
	echo "Starting Packaging"
	sudo ldconfig -v
	time sudo make package -j$NUM_JOBS
	if [ $? -eq 0 ] ; then
		echo "OpenCV make package successful"
	else
		# Try to make again; Sometimes there are issues with the build
		# because of lack of resources or concurrency issues
		echo "Make package did not build " >&2
		echo "Retrying ... "
		# Single thread this time
		sudo make package
		if [ $? -eq 0 ] ; then
			echo "OpenCV make package successful"
		else
			echo "Make package did not successfully build" >&2
			echo "Please fix issues and retry build"
			exit 1
		fi
	fi
}

visual_check () {
	# check installation
	IMPORT_CHECK="$(python -c "import cv2 ; print(cv2.__version__)")"
	if [[ "$IMPORT_CHECK" != *$OPENCV_VERSION* ]]; then
		echo "There was an error loading OpenCV in the Python sanity test."
		echo "The loaded version does not match the version built here."
		echo "Please check the installation."
		echo "The first check should be the PYTHONPATH environment variable."
	fi
}
	
main () {
	# Iterate through command line inputs
	while [ "$1" != "" ]; do
	case $1 in
			-s | --sourcedir )      shift
									OPENCV_SOURCE_DIR=$1
									;;
			-i | --installdir )     shift
									INSTALL_DIR=$1
									;;
			-r | --remove )         remove
									;;
			-t | --test )           TEST_OPENCV=1
									;;
			-p | --package )        PACKAGE_OPENCV=1
									;;
			-h | --help )           usage
									exit
									;;
			* )                     usage
									exit 1
		esac
		shift
	done
	setup
	
	# Print out the current configuration
	echo "Build configuration: "
	echo " - NVIDIA Jetson AGX Orin"
	echo " - OpenCV binaries will be installed in: $INSTALL_DIR"
	echo " - OpenCV source code is currently located at: $OPENCV_SOURCE_DIR"
	if [ "$PACKAGE_OPENCV" -eq 0 ] ; then
	   echo " - NOT Packaging OpenCV"
	else
	   echo " - Packaging OpenCV"
	fi
	
	if [ "$TEST_OPENCV" -eq 1 ] ; then
	 echo " - Also Download Tests from opencv_extras"
	fi
	
	install_dependencies
	download_sources
	configure
	build
	install
	if [ "$PACKAGE_OPENCV" -eq 1 ] ; then
		wrap
	fi
	visual_check
}

main $@
