# buildOpenCV
Script to build OpenCV 4.9.0 with CUDA and CUDNN support on the NVIDIA Jetson AGX Orin

<em><b>Note: </b>The script does not check to see which version of L4T is running before building, understand the script may only work with the stated versions.</em>

### Usage
<blockquote>usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]<br>
&nbsp;&nbsp;&nbsp;&nbsp; -v | --version     Change the version of OpenCV to install. (default: 4.9.0)<br>
&nbsp;&nbsp;&nbsp;&nbsp; -s | --sourcedir   Directory in which to place the opencv sources (default: /tmp/build_opencv)<br>
&nbsp;&nbsp;&nbsp;&nbsp; -i | --installdir  Directory in which to install opencv libraries (default: /usr/local)<br>
&nbsp;&nbsp;&nbsp;&nbsp; -t | --test        Download examples and test the OpenCV after building.<br>
&nbsp;&nbsp;&nbsp;&nbsp; -p | --package     Package OpenCV as .deb file to install in other JETSON equipments.<br>
&nbsp;&nbsp;&nbsp;&nbsp; -r | --remove      Ask to remove previous installations from OpenCV alongside all files related.<br>
&nbsp;&nbsp;&nbsp;&nbsp; -h | --help        Print help</blockquote>

## Directories
OpenCV will be installed in the `/usr/local` directory as default, all files will be copied to the following locations:<br/>

- `/usr/bin` - executable files<br/>
- `/usr/lib/aarch64-linux-gnu` - libraries (.so)<br/>
- `/usr/lib/aarch64-linux-gnu/cmake/opencv4` - cmake package<br/>
- `/usr/include/opencv4` - headers<br/>
- `/usr/share/opencv4` - other files (e.g. trained cascades in XML format)<br/>

## Build Parameters
OpenCV is a very rich environment, with many different options available. Check the script to make sure that the options you need are included/excluded. By default, the buildOpenCV.sh script selects these major options:

* CUDA ON
* CUDNN ON
* GStreamer
* V4L - (Video for Linux)
* QT - (<em>No gtk support built in</em>)
* Python 3 bindings

## Packaging
By default, the build will create a OpenCV package. The package file will be found in:
<blockquote>opencv/build/_CPACK_Packages/Linux/STGZ/OpenCV-4.9.0-<<em>commit</em>>-aarch64.sh</blockquote>

The advantage of packaging is that you can use the resulting package file to install this OpenCV build on other machines without having to rebuild. Whether the OpenCV package is built or not is controlled by the CMake directive <b>CPACK_BINARY_DEB</b> in the script.

## Notes 
Building for:
* Jetson AGX Orin
* JetPack 5.1.2 (CUDA 8.7, CUDNN 8.9)
* OpenCV 4.9.0
* Packaging Option
