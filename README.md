# Build OpenCV with CUDA for Jetson

Script to build OpenCV 4.9.0 with CUDA and CUDNN support on the NVIDIA Jetson AGX Orin

***Note:** The script does not check to see which version of L4T is running before building, understand the script may only work with the stated versions.*

## Usage

> usage: ./buildOpenCV.sh [[-s sourcedir ] | [-h]]  
>>>-v | --version&ensp;&ensp;&ensp;&ensp;&thinsp;&thinsp;Change the version of OpenCV to install. (default: 4.9.0)  
>>>-s | --sourcedir&ensp;&thinsp;&ensp;&thinsp;Directory to place the opencv sources (default: /tmp/build_opencv)  
>>>-i | --installdir&ensp;&ensp;&ensp;&ensp;Directory to install opencv libraries (default: /usr/local)  
>>>-t | --test&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&thinsp;Download examples and test the OpenCV after building.  
>>>-p | --package&ensp;&ensp;&ensp;&thinsp;Package OpenCV as .deb file to install in other JETSONs.  
>>>-r | --remove&ensp;&ensp;&ensp;&ensp;&thinsp;Ask to remove previous installations from OpenCV alongside all files related.  
>>>-h | --help&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;Print help

## Directories

OpenCV will be installed in the `/usr/local` directory as default, all files will be copied to the following locations:

- `/usr/bin` - executable files
- `/usr/lib/aarch64-linux-gnu` - libraries (.so)
- `/usr/lib/aarch64-linux-gnu/cmake/opencv4` - cmake package
- `/usr/include/opencv4` - headers
- `/usr/share/opencv4` - other files (e.g. trained cascades in XML format)

## Build Parameters

OpenCV is a very rich environment, with many different options available. Check the script to make sure that the options you need are included/excluded. By default, the buildOpenCV.sh script selects these major options:

- CUDA **ON**
- CUDNN **ON**
- GStreamer
- V4L - (Video for Linux)
- QT - (*No gtk support built in*)
- Python 3 bindings

## Packaging

By default, the build will create a OpenCV package. The package file will be found in:
> opencv/build/_CPACK_Packages/Linux/STGZ/OpenCV-4.9.0-<*commit*>-aarch64.sh

The advantage of packaging is that you can use the resulting package file to install this OpenCV build on other machines without having to rebuild. Whether the OpenCV package is built or not is controlled by the CMake directive **CPACK_BINARY_DEB** in the script.

## Notes

Building for:

- Jetson AGX Orin
- JetPack 5.1.2 (CUDA 8.7, CUDNN 8.9)
- OpenCV 4.9.0
- Packaging Option
