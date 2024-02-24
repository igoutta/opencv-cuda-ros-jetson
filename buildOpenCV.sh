#!/bin/bash
# License: MIT. See license file in root directory
# Copyright(c) JetsonHacks (2017-2019)
# Updated by Gustavo Alvardo (2024).
trap cleanup ERR
# Version
OPENCV_VERSION=4.9.0
# Jetson AGX Orin
CUDA_ARCH_BIN=8.7
PTX="sm_87"
CUDNN='8.9'
# Install directory
INSTALL_DIR=/usr/local
# Source code directory
OPENCV_SOURCE_DIR=/tmp/build_opencv
# Current location where the script is running
WHEREAMI=$PWD
# Download the opencv_extras repository for testing
# Value should be 1 or 0
TEST_OPENCV=0
# Packaging OpenCV
# Value should be 1 or 0
PACKAGE_OPENCV=0
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
		echo "Do you wish to remove temporary build files in $OPENCV_SOURCE_DIR ? "
		if ! [[ "$1" = "--test-warning" ]]; then
			echo "(Doing so may make running tests on the build later impossible)"
		fi
		read -rp "Y/N " yn
		case ${yn} in
			[Yy]* ) sudo rm -rf "$OPENCV_SOURCE_DIR" ; break;;
			[Nn]* ) exit ;;
			* ) echo "Please answer yes or no." ;;
		esac
	done
}

setup () {
	if [[ -d ${OPENCV_SOURCE_DIR} ]]; then
		echo "It appears an existing build exists in $OPENCV_SOURCE_DIR"
		cleanup
	fi
	mkdir -p "$OPENCV_SOURCE_DIR"
}

remove () {
	while true ; do
	echo "Do you want to remove OpenCV completely from your system? "
	read -rp "Y/N " yn
		case ${yn} in
			[Yy]* ) sudo find / -name ' *opencv* ' -exec rm -i '{}' \; ;
					CHECK_PKG="$(pkg-config --modversion opencv)";
					if [[ "$CHECK_PKG" != ^[3-5]* ]]; then
						echo "Purge Completed."
					fi
					break;;
			[Nn]* ) exit ;;
			* ) echo "Please answer yes or no." ;;
		esac
	done
}

install_dependencies () {
	# open-cv has a lot of dependencies, but most can be found in the default
	# package repository or should already be installed (eg. CUDA).
	echo "Installing build dependencies."
	sudo apt-add-repository universe
	sudo apt update -y
	sudo apt dist-upgrade -y --autoremove
	
	# Download dependencies for the desired configuration
	cd "$HOME" || return
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
			libtiff5-dev \
			libpostproc-dev \
			libswscale-dev \
			libswresample-dev \
			libtbb-dev \
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
	sudo apt install -y qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
 
 	# In order to support OpenGL, we need a little magic to help
	# https://devtalk.nvidia.com/default/topic/1007290/jetson-tx2/building-opencv-with-opengl-support-/post/5141945/#5141945
	cd /usr/local/cuda/include || exit
	sudo patch -N cuda_gl_interop.h "$WHEREAMI"/patches/OpenGLHeader.patch
}

download_sources() {
    cd "$OPENCV_SOURCE_DIR" || setup
    echo "Getting OpenCV version: $OPENCV_VERSION"
    git clone -c advice.detachedHead=false --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv.git
    git clone -c advice.detachedHead=false --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv_contrib.git
    if [ "$TEST_OPENCV" -eq 1 ] ; then
		echo "Getting opencv_extras for the test data"
   		git clone -c advice.detachedHead=false --depth 1 -b "$OPENCV_VERSION" https://github.com/opencv/opencv_extra.git
    fi
	# checking the correct TAG
	CHECK_SOURCE="$(cd ./opencv/ || return; git log | grep -o "$OPENCV_VERSION")"
	if [ "$CHECK_SOURCE" != "" ]; then
		echo "Checking the downloaded version: Correct."
	else
		echo "Checking the downloaded version: Wrong."
		exit 1
	fi
}

configure () {
	cd "$OPENCV_SOURCE_DIR"/opencv || exit
	echo "$WHEREAMI"
	CMAKEFLAGS="
		-D CMAKE_BUILD_TYPE=RELEASE
		-D CMAKE_INSTALL_PREFIX=${INSTALL_DIR}
		-D OPENCV_EXTRA_MODULES_PATH=${OPENCV_SOURCE_DIR}/opencv_contrib/modules
		-D OPENCV_GENERATE_PKGCONFIG=YES
		-D OPENCV_ENABLE_NONFREE=ON
			
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

		-D WITH_V4L=ON
		-D WITH_LIBV4L=ON
		-D WITH_FFMPEG=ON
		-D WITH_GSTREAMER=ON
		-D WITH_GSTREAMER_0_10=OFF
		
		-D WITH_QT=ON
		-D BUILD_opencv_python3=ON
		-D BUILD_opencv_python2=OFF
		-D BUILD_JAVA=OFF"
	
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
	mkdir -p "$OPENCV_SOURCE_DIR"/opencv/build
	cd "$OPENCV_SOURCE_DIR"/opencv/build || exit
	CONFIG="$(time cmake "${CMAKEFLAGS}" .. 2>&1 | tee -a configure.log)"

	if $CONFIG; then
		echo "CMake configuration make successful"
	else
		echo "CMake issues " >&2
		echo "Please check the configuration being used"
		exit 1
	fi
}

build_install () {
	cd "$OPENCV_SOURCE_DIR"/opencv/build || exit
	# Consider the MAXN performance mode if using a barrel jack on the Nano
	time make -j"$NUM_JOBS" 2>&1 | tee -a build.log
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
	
	if [ "$TEST_OPENCV" -eq 1 ] ; then
		time make test 2>&1 | tee -a test.log
	fi

	echo "Installing ... "
	sudo ldconfig -v
	if [[ -w ${INSTALL_DIR} ]] ; then
	    time make install 2>&1 | tee -a install.log
	else
	    time sudo make install 2>&1 | tee -a install.log
	fi
	
	if [ $? -eq 0 ] ; then
	   echo "OpenCV installed in: $INSTALL_DIR"
	else
	   echo "There was an issue with the final installation."
	   exit 1
	fi
}

wrap () {
	# We assure to be in the build directory ...
	cd "$OPENCV_SOURCE_DIR"/opencv/build || exit
	# If PACKAGE_OPENCV is on, pack 'er up and get ready to go!
	echo "Starting Packaging"
	sudo ldconfig -v
	time sudo make package -j"$NUM_JOBS" 2>&1 | tee -a package.log
	if [ $? -eq 0 ] ; then
		echo "OpenCV make package successful"
	else
		# Try to make again; Sometimes there are issues with the build
		# because of lack of resources or concurrency issues
		echo "Make package did not build " >&2
		echo "Retrying ... "
		# Single thread this time
		time sudo make package 2>&1 | tee -a package.log
		if [ $? -eq 0 ] ; then
			echo "OpenCV make package successful"
		else
			echo "Make package did not successfully build" >&2
			echo "Please fix issues and retry build"
			exit 1
		fi
	fi
	mv ./_CPACK_Packages/Linux/STGZ/ "$HOME"/Package_OpenCV_CUDA/
}

visual_check () {
	# check installation with Python 3
	IMPORT_CHECK="$(python -c "import cv2; print(cv2.__version__)")"
	if [ "$IMPORT_CHECK" != "$OPENCV_VERSION" ]; then
		echo "There was an error loading OpenCV in the Python sanity test."
		echo "The loaded version does not match the version built here."
		echo "Please check the installation."
		echo "The first check should be the PYTHONPATH environment variable."
	fi
}

usage () {
	echo "usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]"
	echo "-v | --version	Change the version of OpenCV to install. (default: 4.9.0)"
	echo "-s | --sourcedir	Directory in which to place the opencv sources (default: /tmp/build_opencv)"
	echo "-i | --installdir	Directory in which to install opencv libraries (default: /usr/local)"
	echo "-t | --test		Download examples and test the OpenCV after building."
	echo "-p | --package	Package OpenCV as .deb file to install in other JETSON equipments."
	echo "-r | --remove		In case you want to completely remove installed OpenCV of your system."
	echo "-h | --help		This message"
}

main () {
	# Iterate through command line inputs
	while [ "$1" != "" ]; do
		case $1 in
			-v | --version )	shift 
								OPENCV_VERSION=$1
								;;
			-s | --sourcedir )	shift
								OPENCV_SOURCE_DIR=$1
								;;
			-i | --installdir )	shift
								INSTALL_DIR=$1
								;;
			-t | --test )		TEST_OPENCV=1
								;;
			-p | --package )	PACKAGE_OPENCV=1
								;;
			-r | --remove )		remove
								;;
			-h | --help )		usage
								exit
								;;
			* )					usage
								exit 1
		esac
		shift
	done

	setup

	# Print out the current configuration
	echo "Build configuration: "
	echo " - NVIDIA Jetson AGX Orin"
	echo " - OpenCV version: $OPENCV_VERSION" 
	echo " - Binaries will be installed in: $INSTALL_DIR"
	echo " - Source code will be located at: $OPENCV_SOURCE_DIR"
	if [ "$PACKAGE_OPENCV" -eq 0 ] ; then
		echo " - NOT Packaging OpenCV"
	else
		echo " - Packaging OpenCV"
	fi

	if [ "$TEST_OPENCV" -eq 0 ] ; then
		echo " - NOT Testing OpenCV Build"
	else
		echo " - Testing OpenCV with testdata from opencv_extras"
	fi

	install_dependencies
	download_sources
	configure
	build_install
	if [ "$PACKAGE_OPENCV" -eq 1 ] ; then
		wrap
	fi
	visual_check
}

main "$@"
