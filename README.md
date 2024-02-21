# buildOpenCV
Script to build OpenCV 4.5.4 with CUDA and CUDNN support on the NVIDIA Jetson AGX Orin

<em><b>Note: </b>The script does not check to see which version of L4T is running before building, understand the script may only work with the stated versions.</em>

## Building
This is a long build, I strongly advise to keep a log file, as follows:

<blockquote>$ ./buildOpenCV.sh |& tee openCV_build.log
            $ sudo ldconfig -v</blockquote>

While the build will still be written to the console, the build log will be written to openCV_build.log for later review.

## Directories
OpenCV will be installed in the `/usr/local` directory as default, all files will be copied to the following locations:<br/>

- `/usr/bin` - executable files<br/>
- `/usr/lib/aarch64-linux-gnu` - libraries (.so)<br/>
- `/usr/lib/aarch64-linux-gnu/cmake/opencv4` - cmake package<br/>
- `/usr/include/opencv4` - headers<br/>
- `/usr/share/opencv4` - other files (e.g. trained cascades in XML format)<br/>

### Usage
<blockquote>usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]<br>
&nbsp;&nbsp;&nbsp;&nbsp; -s | --sourcedir   Directory in which to place the opencv sources (default $HOME ; this is usually ~/)<br>
&nbsp;&nbsp;&nbsp;&nbsp; -i | --installdir  Directory in which to install opencv libraries (default /usr/local)<br>
&nbsp;&nbsp;&nbsp;&nbsp; --no_package       Do not package OpenCV as .deb file (default is true)<br>
&nbsp;&nbsp;&nbsp;&nbsp; -h | --help        Print help</blockquote>

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
<blockquote>opencv/build/_CPACK_Packages/Linux/STGZ/OpenCV-4.5.4-<<em>commit</em>>-aarch64.sh</blockquote>

The advantage of packaging is that you can use the resulting package file to install this OpenCV build on other machines without having to rebuild. Whether the OpenCV package is built or not is controlled by the CMake directive <b>CPACK_BINARY_DEB</b> in the script.

## Notes 
Building for:
* Jetson AGX
* JetPack 5.1.2
* OpenCV 4.5.4 in order to be compatible with ROS2 Bridge.
* Packaging Option ( Builds package by default; --no_package does not build package)
