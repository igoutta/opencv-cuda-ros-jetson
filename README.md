# Build OpenCV with CUDA for Jetson

Script to build OpenCV with CUDA and CUDNN support on NVIDIA Jetson boards running JetPack 5. It builds OpenCV 4.9.0 by default, and any other release tag (e.g. 4.10.0, 4.11.0, 4.12.0) can be chosen with `-v`.

***Note:** The script does not check to see which version of L4T is running before building, understand the script may only work with the stated versions.*

## Usage

> usage: `./buildOpenCV.sh [-b board] [-v version] [-s sourcedir] [-i installdir] [-t] [-p] [-r] [-h]`  
>>>-b | --board&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&thinsp;Board to build for: `xavier` or `orin` (default: orin)  
>>>-v | --version&ensp;&ensp;&ensp;&ensp;&thinsp;&thinsp;Change the version of OpenCV to install. (default: 4.9.0)  
>>>-s | --sourcedir&ensp;&thinsp;&ensp;&thinsp;Directory to place the opencv sources (default: /tmp/build_opencv)  
>>>-i | --installdir&ensp;&ensp;&ensp;&ensp;Directory to install opencv libraries (default: /usr/local)  
>>>-t | --test&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&thinsp;Download examples and test the OpenCV after building.  
>>>-p | --package&ensp;&ensp;&ensp;&thinsp;Package OpenCV as .deb file to install in other JETSONs.  
>>>-r | --remove&ensp;&ensp;&ensp;&ensp;&thinsp;Ask to remove previous installations from OpenCV alongside all files related.  
>>>-h | --help&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;Print help

## Directories

OpenCV will be installed in the `/usr/local` directory as default (change it with `-i`), under these subdirectories of the install prefix:

- `bin` - executable files
- `lib` - libraries (.so)
- `lib/cmake/opencv4` - cmake package
- `include/opencv4` - headers
- `share/opencv4` - other files (e.g. trained cascades in XML format)

## Build Parameters

OpenCV is a very rich environment, with many different options available. Check the script to make sure that the options you need are included/excluded. By default, the buildOpenCV.sh script selects these major options:

- CUDA **ON**
- CUDNN **ON**
- GStreamer
- V4L - (Video for Linux)
- QT - (*No gtk support built in*)
- Python 3 bindings

## Packaging

With `-p`, the build will also create an OpenCV package. The package file will be found in:
> ~/Package_OpenCV_CUDA/ (`OpenCV-4.9.0-<*commit*>-*.deb` and the `.sh` installer)

The advantage of packaging is that you can use the resulting package file to install this OpenCV build on other machines without having to rebuild. Whether the OpenCV package is built or not is controlled by the CMake directive **CPACK_BINARY_DEB** in the script.

## Project layout

- `buildOpenCV.sh` - the build, install and packaging script
- `patches/` - patches applied by the script (CUDA OpenGL header fix)
- `Examples/` - camera and CUDA sample programs to check the build, see [Examples/README.md](Examples/README.md)
- `.github/` - issue templates

## Notes

Building for:

- Jetson AGX Orin / Orin NX / Orin Nano (`-b orin`, compute capability 8.7) or AGX Xavier / Xavier NX (`-b xavier`, compute capability 7.2)
- JetPack 5.1.x (Ubuntu 20.04, CUDA 11.4, CUDNN 8.6)
- OpenCV 4.9.0 by default, newer releases with `-v`
- Packaging Option
