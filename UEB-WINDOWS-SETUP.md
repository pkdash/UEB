# UEB VSCode Setup for Windows Development

## Overview

This guide provides Windows-specific instructions for setting up the UEB (Utah Energy Balance Snowmelt Model) development environment in VSCode. Windows developers have three main approaches:

1. **WSL2 (Windows Subsystem for Linux)** - Recommended ⭐
2. **Visual Studio with MSVC** - Native Windows
3. **MinGW-w64** - Unix-like toolchain on Windows

---

## Table of Contents
1. [Recommended Approach: WSL2](#recommended-approach-wsl2)
2. [Visual Studio (MSVC) Setup](#visual-studio-msvc-setup)
3. [MinGW-w64 Setup](#mingw-w64-setup)
4. [Installing Dependencies on Windows](#installing-dependencies-on-windows)
5. [VSCode Configuration for Windows](#vscode-configuration-for-windows)
6. [Building on Windows](#building-on-windows)
7. [Debugging on Windows](#debugging-on-windows)
8. [Troubleshooting Windows Issues](#troubleshooting-windows-issues)

---

## Recommended Approach: WSL2

### Why WSL2?

✅ **Advantages:**
- Most compatible with the existing build system (Makefile, shell scripts)
- Easiest dependency installation using apt/yum
- Better MPI support
- No path conversion issues
- Same commands as Linux/macOS developers

✅ **Recommendation:** Use WSL2 with Ubuntu for the smoothest experience.

### WSL2 Setup

#### 1. Install WSL2

Open PowerShell as Administrator and run:

```powershell
# Enable WSL2
wsl --install

# Or if WSL is already installed, ensure it's WSL2
wsl --set-default-version 2

# Install Ubuntu (recommended)
wsl --install -d Ubuntu-22.04

# Restart your computer
```

#### 2. Set Up Ubuntu in WSL2

Open "Ubuntu" from Start menu:

```bash
# Update package lists
sudo apt update && sudo apt upgrade -y

# Install build essentials
sudo apt install -y build-essential gdb

# Install MPI
sudo apt install -y mpich libmpich-dev

# Install dependencies
sudo apt install -y \
  libcurl4-openssl-dev \
  zlib1g-dev \
  libhdf5-mpich-dev \
  libnetcdf-dev \
  libnetcdf-mpi-dev

# Install Git (if not present)
sudo apt install -y git

# Verify installations
g++ --version
mpicxx --version
nc-config --version
```

#### 3. Access Your Project Files

Your Windows drives are mounted at `/mnt/`:

```bash
# Navigate to your Windows project directory
cd /mnt/c/Users/YourUsername/Workspace/UEB

# Or clone the project in WSL home directory
cd ~
git clone <your-repo-url>
cd UEB
```

#### 4. Install VSCode with WSL Extension

1. **Install VSCode** on Windows: https://code.visualstudio.com/
2. **Install WSL Extension**: 
   - Open VSCode
   - Press `Ctrl+Shift+X`
   - Search for "WSL"
   - Install "WSL" by Microsoft

3. **Open Project in WSL**:
   ```bash
   # From WSL terminal in project directory
   code .
   ```
   
   Or from VSCode: `Ctrl+Shift+P` → "WSL: Open Folder in WSL"

#### 5. Build and Run in WSL

```bash
# Build
make

# Run with single process
./uebpar

# Run with MPI (4 processes)
mpirun -np 4 ./uebpar
```

### WSL2 VSCode Configuration

The Linux configurations in `.vscode/c_cpp_properties.json` work directly in WSL:

```json
{
    "configurations": [
        {
            "name": "WSL",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/include",
                "/usr/include/mpich"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/mpicxx",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "linux-gcc-x64"
        }
    ],
    "version": 4
}
```

### WSL2 Tips

- **Performance**: Keep project files in WSL filesystem (`~/`) for better performance
- **GUI Apps**: WSL2 supports GUI apps (WSLg) on Windows 11
- **VS Code**: Always use "WSL" extension to work with WSL projects
- **File Access**: Access WSL files from Windows at `\\wsl$\Ubuntu-22.04\home\username\`

---

## Visual Studio (MSVC) Setup

For native Windows development using Microsoft Visual C++ compiler.

### Prerequisites

#### 1. Install Visual Studio 2019 or 2022

Download from: https://visualstudio.microsoft.com/downloads/

Install with these components:
- ✅ Desktop development with C++
- ✅ C++ MPI support
- ✅ Windows 10/11 SDK
- ✅ C++ CMake tools (optional)
- ✅ Git for Windows

#### 2. Install vcpkg (Package Manager)

```powershell
# Open PowerShell
cd C:\
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat

# Add to PATH (run as Administrator)
[Environment]::SetEnvironmentVariable("Path", "$env:Path;C:\vcpkg", "Machine")
```

#### 3. Install Dependencies with vcpkg

```powershell
# Install libraries
vcpkg install netcdf-c:x64-windows
vcpkg install hdf5:x64-windows
vcpkg install curl:x64-windows
vcpkg install zlib:x64-windows

# Install MPI
vcpkg install msmpi:x64-windows

# Integrate with Visual Studio
vcpkg integrate install
```

#### 4. Install Microsoft MPI

Download and install both:
- **MS-MPI Runtime**: https://www.microsoft.com/en-us/download/details.aspx?id=100593
- **MS-MPI SDK**: https://www.microsoft.com/en-us/download/details.aspx?id=100593

### Creating Visual Studio Project

Create `CMakeLists.txt` in project root:

```cmake
cmake_minimum_required(VERSION 3.15)
project(UEB CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find MPI
find_package(MPI REQUIRED)

# Find NetCDF (if using vcpkg, this should work automatically)
find_package(netCDF CONFIG REQUIRED)
find_package(HDF5 REQUIRED)
find_package(CURL REQUIRED)
find_package(ZLIB REQUIRED)

# Source files for MPI version
set(UEB_SOURCES
    main.cpp
    canopy.cpp
    matrixnvector.cpp
    ncfunctions_mswin.cpp
    snowdgtv.cpp
    snowdv.cpp
    snowxv.cpp
    uebdecls.cpp
    uebinputs.cpp
)

# Create executable
add_executable(uebpar ${UEB_SOURCES})

# Include directories
target_include_directories(uebpar PRIVATE ${MPI_CXX_INCLUDE_DIRS})

# Link libraries
target_link_libraries(uebpar 
    PRIVATE 
    MPI::MPI_CXX
    netCDF::netcdf
    ${HDF5_LIBRARIES}
    CURL::libcurl
    ZLIB::ZLIB
)

# Compiler definitions
target_compile_definitions(uebpar PRIVATE 
    _CRT_SECURE_NO_WARNINGS
    NOMINMAX
)

# For GPU version (optional)
option(BUILD_GPU_VERSION "Build GPU version with CUDA" OFF)

if(BUILD_GPU_VERSION)
    enable_language(CUDA)
    
    set(UEB_GPU_SOURCES
        gpumain.cpp
        gpucanopy.cpp
        gpumatrixnvector.cpp
        gpuncfunctions.cpp
        gpusnowdgtv.cpp
        gpusnowdv.cpp
        gpusnowxv.cpp
        gpuuebdecls.cpp
        gpuuebinputs.cpp
    )
    
    add_executable(uebgpu ${UEB_GPU_SOURCES})
    
    target_include_directories(uebgpu PRIVATE ${MPI_CXX_INCLUDE_DIRS})
    
    target_link_libraries(uebgpu 
        PRIVATE 
        MPI::MPI_CXX
        netCDF::netcdf
        ${HDF5_LIBRARIES}
        CURL::libcurl
        ZLIB::ZLIB
    )
    
    set_target_properties(uebgpu PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        CUDA_ARCHITECTURES "52;61;75"
    )
endif()
```

### Building with Visual Studio

```powershell
# Create build directory
mkdir build
cd build

# Configure with vcpkg toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build . --config Release

# Or open in Visual Studio
cmake .. -G "Visual Studio 17 2022" -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
start UEB.sln
```

### Visual Studio VSCode Configuration

Add to `.vscode/c_cpp_properties.json`:

```json
{
    "name": "Win32 MSVC",
    "includePath": [
        "${workspaceFolder}/**",
        "C:/Program Files (x86)/Microsoft SDKs/MPI/Include",
        "C:/vcpkg/installed/x64-windows/include"
    ],
    "defines": [
        "_DEBUG",
        "UNICODE",
        "_UNICODE",
        "_CRT_SECURE_NO_WARNINGS"
    ],
    "windowsSdkVersion": "10.0.19041.0",
    "compilerPath": "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705/bin/Hostx64/x64/cl.exe",
    "cStandard": "c11",
    "cppStandard": "c++14",
    "intelliSenseMode": "windows-msvc-x64"
}
```

---

## MinGW-w64 Setup

MinGW provides GCC compiler on Windows with better Unix compatibility than MSVC.

### 1. Install MSYS2 (Recommended way to get MinGW)

Download from: https://www.msys2.org/

```bash
# After installation, open MSYS2 MinGW 64-bit terminal

# Update package database
pacman -Syu

# Close and reopen terminal, then:
pacman -Su

# Install development tools
pacman -S --needed base-devel mingw-w64-x86_64-toolchain

# Install dependencies
pacman -S mingw-w64-x86_64-netcdf
pacman -S mingw-w64-x86_64-hdf5
pacman -S mingw-w64-x86_64-curl
pacman -S mingw-w64-x86_64-zlib

# Install MPI (MPICH or MS-MPI wrapper)
pacman -S mingw-w64-x86_64-msmpi
```

### 2. Add MinGW to Windows PATH

Add to System Environment Variables:
```
C:\msys64\mingw64\bin
```

### 3. Configure Makefile for MinGW

Edit `makefile` for MinGW:

```makefile
CXX = g++
MPICXX = mpicc.exe
CXXFLAGS = -std=c++11 -g -Wall
LINKFLAGS = -std=c++11 -g
LIBDIRS = -LC:/msys64/mingw64/lib
LDFLAGS = -lnetcdf -lhdf5 -lhdf5_hl -lcurl -lz
INCDIRS = -IC:/msys64/mingw64/include

TARGET = uebpar.exe
CXX_SRCS = main.cpp canopy.cpp matrixnvector.cpp ncfunctions_mswin.cpp \
           snowdgtv.cpp snowdv.cpp snowxv.cpp uebdecls.cpp uebinputs.cpp
OBJS = $(CXX_SRCS:.cpp=.o)

$(TARGET): $(OBJS)
	$(MPICXX) $(LINKFLAGS) -o $@ $^ $(LIBDIRS) $(LDFLAGS)

%.o: %.cpp
	$(MPICXX) $(CXXFLAGS) $(INCDIRS) -c $<

clean:
	del /Q *.o $(TARGET)
```

### 4. Build with MinGW

```bash
# Open MSYS2 MinGW 64-bit terminal
cd /c/path/to/UEB

# Build
make

# Run
./uebpar.exe

# Or with MPI
mpiexec -n 4 ./uebpar.exe
```

### MinGW VSCode Configuration

Add to `.vscode/c_cpp_properties.json`:

```json
{
    "name": "MinGW-w64",
    "includePath": [
        "${workspaceFolder}/**",
        "C:/msys64/mingw64/include"
    ],
    "defines": [
        "_DEBUG"
    ],
    "compilerPath": "C:/msys64/mingw64/bin/g++.exe",
    "cStandard": "c11",
    "cppStandard": "c++11",
    "intelliSenseMode": "windows-gcc-x64"
}
```

---

## Installing Dependencies on Windows

### Using vcpkg (Recommended for MSVC)

```powershell
# Install vcpkg
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat

# Install packages
.\vcpkg install netcdf-c:x64-windows
.\vcpkg install hdf5[parallel]:x64-windows
.\vcpkg install curl:x64-windows
.\vcpkg install zlib:x64-windows
.\vcpkg install msmpi:x64-windows

# Integrate
.\vcpkg integrate install
```

### Using MSYS2/MinGW

```bash
# Open MSYS2 terminal
pacman -S mingw-w64-x86_64-netcdf
pacman -S mingw-w64-x86_64-hdf5
pacman -S mingw-w64-x86_64-curl
pacman -S mingw-w64-x86_64-msmpi
```

### Manual Installation (Advanced)

Follow instructions in `compile parallel netcdf_mpich.txt` but adapt for Windows:

1. **Download sources** for HDF5, NetCDF, etc.
2. **Use CMake** to configure each library
3. **Build with Visual Studio** or MinGW
4. **Install to common location** (e.g., `C:\Libraries\`)

Example for HDF5:
```powershell
# Download HDF5 source
cd C:\temp
# Extract HDF5 source

mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=C:/Libraries/hdf5 -DHDF5_ENABLE_PARALLEL=ON
cmake --build . --config Release
cmake --install .
```

---

## VSCode Configuration for Windows

### Complete Windows configurations

Update `.vscode/c_cpp_properties.json`:

```json
{
    "configurations": [
        {
            "name": "WSL",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/include",
                "/usr/include/mpich"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/mpicxx",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "linux-gcc-x64"
        },
        {
            "name": "Win32 MSVC",
            "includePath": [
                "${workspaceFolder}/**",
                "C:/Program Files (x86)/Microsoft SDKs/MPI/Include",
                "C:/vcpkg/installed/x64-windows/include",
                "${vcpkgRoot}/x64-windows/include"
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE",
                "_CRT_SECURE_NO_WARNINGS",
                "NOMINMAX"
            ],
            "windowsSdkVersion": "10.0.22000.0",
            "compilerPath": "C:/Program Files/Microsoft Visual Studio/2022/Community/VC/Tools/MSVC/14.30.30705/bin/Hostx64/x64/cl.exe",
            "cStandard": "c11",
            "cppStandard": "c++14",
            "intelliSenseMode": "windows-msvc-x64",
            "configurationProvider": "ms-vscode.cmake-tools"
        },
        {
            "name": "MinGW-w64",
            "includePath": [
                "${workspaceFolder}/**",
                "C:/msys64/mingw64/include",
                "C:/msys64/mingw64/include/c++/12.2.0"
            ],
            "defines": [
                "_DEBUG"
            ],
            "compilerPath": "C:/msys64/mingw64/bin/g++.exe",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "windows-gcc-x64"
        }
    ],
    "version": 4
}
```

### Windows Build Tasks

Add to `.vscode/tasks.json`:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build UEB (WSL)",
            "type": "shell",
            "command": "wsl",
            "args": [
                "make",
                "-C",
                "/mnt/c/path/to/UEB"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": ["$gcc"]
        },
        {
            "label": "Build UEB (MinGW)",
            "type": "shell",
            "command": "C:\\msys64\\usr\\bin\\bash.exe",
            "args": [
                "-l",
                "-c",
                "cd '${workspaceFolder}' && make"
            ],
            "group": "build",
            "problemMatcher": ["$gcc"]
        },
        {
            "label": "Build UEB (CMake)",
            "type": "shell",
            "command": "cmake",
            "args": [
                "--build",
                "${workspaceFolder}/build",
                "--config",
                "Release"
            ],
            "group": "build",
            "problemMatcher": ["$msCompile", "$gcc"]
        },
        {
            "label": "Configure CMake",
            "type": "shell",
            "command": "cmake",
            "args": [
                "-S",
                "${workspaceFolder}",
                "-B",
                "${workspaceFolder}/build",
                "-DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake"
            ],
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Clean (WSL)",
            "type": "shell",
            "command": "wsl",
            "args": [
                "make",
                "clean"
            ],
            "group": "build"
        },
        {
            "label": "Clean (MinGW)",
            "type": "shell",
            "command": "C:\\msys64\\usr\\bin\\bash.exe",
            "args": [
                "-l",
                "-c",
                "cd '${workspaceFolder}' && make clean"
            ],
            "group": "build"
        }
    ]
}
```

### Windows Debug Configuration

Add to `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug UEB (WSL - gdb)",
            "type": "cppdbg",
            "request": "launch",
            "program": "/mnt/c/path/to/UEB/uebpar",
            "args": [],
            "stopAtEntry": false,
            "cwd": "/mnt/c/path/to/UEB",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "pipeTransport": {
                "pipeCwd": "",
                "pipeProgram": "wsl",
                "pipeArgs": [],
                "debuggerPath": "/usr/bin/gdb"
            },
            "sourceFileMap": {
                "/mnt/c": "C:\\"
            },
            "preLaunchTask": "Build UEB (WSL)"
        },
        {
            "name": "Debug UEB (MSVC)",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${workspaceFolder}/build/Release/uebpar.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "console": "integratedTerminal",
            "preLaunchTask": "Build UEB (CMake)"
        },
        {
            "name": "Debug UEB (MinGW - gdb)",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/uebpar.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "C:/msys64/mingw64/bin/gdb.exe",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "Build UEB (MinGW)"
        }
    ]
}
```

---

## Building on Windows

### Using WSL2 (Recommended)
```bash
# Open WSL terminal
cd ~/UEB  # or /mnt/c/path/to/UEB
make
./uebpar
```

### Using Visual Studio + CMake
```powershell
# PowerShell or CMD
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build . --config Release
.\Release\uebpar.exe
```

### Using MinGW/MSYS2
```bash
# MSYS2 MinGW 64-bit terminal
cd /c/path/to/UEB
make
./uebpar.exe
```

---

## Debugging on Windows

### WSL2 Debugging

VSCode with WSL extension provides seamless debugging:

1. Open project in WSL: `code .` from WSL terminal
2. Set breakpoints in VSCode
3. Press `F5` → Select "Debug UEB (WSL - gdb)"

### Visual Studio Debugging

#### Option 1: VSCode with MSVC debugger
1. Build with CMake (Debug configuration)
2. Press `F5` → Select "Debug UEB (MSVC)"
3. Uses `cppvsdbg` debugger (native Windows)

#### Option 2: Full Visual Studio IDE
1. Open `UEB.sln` in Visual Studio
2. Set breakpoints
3. Press `F5` or Debug → Start Debugging

### MinGW Debugging

Uses GDB from MSYS2:
1. Press `F5` → Select "Debug UEB (MinGW - gdb)"
2. GDB path: `C:/msys64/mingw64/bin/gdb.exe`

### MPI Debugging on Windows

Debugging MPI applications on Windows is challenging:

#### Method 1: Debug Single Process
```powershell
# Run without mpiexec for single-process debugging
.\uebpar.exe
```

#### Method 2: Attach to MPI Process
```powershell
# Start MPI program
mpiexec -n 4 uebpar.exe

# Get process IDs
Get-Process uebpar

# Attach debugger to one process
# In VSCode: Debug → Attach to Process
```

#### Method 3: Use Intel MPI (if available)
Intel MPI has better Windows debugging support:
```powershell
mpiexec -n 4 -gdb uebpar.exe
```

---

## Troubleshooting Windows Issues

### Issue: "mpiexec not found"

**Solution**:
```powershell
# For MS-MPI, ensure it's in PATH
$env:Path += ";C:\Program Files\Microsoft MPI\Bin"

# Permanently add to PATH:
[Environment]::SetEnvironmentVariable(
    "Path",
    "$env:Path;C:\Program Files\Microsoft MPI\Bin",
    "Machine"
)
```

### Issue: "netcdf.lib not found"

**Solution for vcpkg**:
```powershell
# Ensure vcpkg integration is active
cd C:\vcpkg
.\vcpkg integrate install

# Verify installation
.\vcpkg list | findstr netcdf

# For CMake, use toolchain file
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
```

**Solution for manual install**:
- Add library path to project settings
- Or set environment variable:
  ```powershell
  $env:LIB += ";C:\Libraries\netcdf\lib"
  $env:INCLUDE += ";C:\Libraries\netcdf\include"
  ```

### Issue: "DLL not found" when running

**Solution**:
```powershell
# Add DLL directories to PATH
$env:Path += ";C:\vcpkg\installed\x64-windows\bin"
$env:Path += ";C:\Program Files\Microsoft MPI\Bin"
$env:Path += ";C:\msys64\mingw64\bin"

# Or copy DLLs to executable directory
Copy-Item "C:\vcpkg\installed\x64-windows\bin\*.dll" ".\build\Release\"
```

### Issue: Line ending issues (CRLF vs LF)

**Solution**:
```bash
# Configure Git to handle line endings
git config --global core.autocrlf true

# Convert existing files (in WSL or Git Bash)
find . -name "*.cpp" -o -name "*.h" -o -name "Makefile" | xargs dos2unix
```

### Issue: Permission denied in WSL

**Solution**:
```bash
# Make scripts executable
chmod +x makeUEB.sh runUEB.sh

# Fix file ownership if needed
sudo chown -R $USER:$USER /path/to/UEB
```

### Issue: Slow file access in WSL

**Symptom**: Build is very slow when project is on Windows filesystem (`/mnt/c/`)

**Solution**:
```bash
# Move project to WSL filesystem
cp -r /mnt/c/path/to/UEB ~/UEB
cd ~/UEB

# Or use symbolic link
ln -s /mnt/c/path/to/UEB ~/UEB-link
```

### Issue: "Cannot open include file: 'mpi.h'"

**For MSVC**:
```powershell
# Install MS-MPI SDK
# Download from: https://www.microsoft.com/en-us/download/details.aspx?id=100593

# Add include path to project
# In CMakeLists.txt:
# include_directories("C:/Program Files (x86)/Microsoft SDKs/MPI/Include")
```

**For MinGW**:
```bash
# Install MSMPI package
pacman -S mingw-w64-x86_64-msmpi
```

### Issue: CMake can't find packages

**Solution**:
```powershell
# Use vcpkg toolchain
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake

# Or set CMAKE_PREFIX_PATH
cmake .. -DCMAKE_PREFIX_PATH="C:/Libraries/netcdf;C:/Libraries/hdf5"

# Or use find hints in CMakeLists.txt:
# set(netCDF_ROOT "C:/Libraries/netcdf")
# find_package(netCDF REQUIRED)
```

### Issue: Wrong configuration in VSCode

**Solution**:
1. Click configuration name in status bar (bottom-right)
2. Select appropriate configuration:
   - **WSL** for WSL2 development
   - **Win32 MSVC** for Visual Studio
   - **MinGW-w64** for MinGW development

### Issue: `#include` paths not resolved

**Solution**:
```json
// In .vscode/c_cpp_properties.json, add:
"compileCommands": "${workspaceFolder}/build/compile_commands.json",

// Generate compile_commands.json with:
cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
```

---

## Recommended VSCode Extensions for Windows

### Essential
- **C/C++** (ms-vscode.cpptools)
- **C/C++ Extension Pack** (ms-vscode.cpptools-extension-pack)
- **WSL** (ms-vscode-remote.remote-wsl) - For WSL2 development
- **CMake Tools** (ms-vscode.cmake-tools) - For CMake projects

### Development Tools
- **Makefile Tools** (ms-vscode.makefile-tools)
- **Remote Development** (ms-vscode-remote.vscode-remote-extensionpack)
- **Git Graph** (mhutchie.git-graph)

### Debugging
- **C/C++ Themes** (ms-vscode.cpptools-themes)
- **Hex Editor** (ms-vscode.hexeditor)

### Optional
- **CUDA C++** (kriegalex.vscode-cudacpp) - For GPU version
- **Better C++ Syntax** (jeff-hykin.better-cpp-syntax)
- **Error Lens** (usernamehw.errorlens)

---

## Windows Development Workflow Summary

### WSL2 (Recommended) ⭐
```bash
# 1. Open WSL terminal
wsl

# 2. Navigate to project
cd ~/UEB

# 3. Open in VSCode
code .

# 4. Build (in VSCode terminal or WSL)
make

# 5. Run
./uebpar
mpirun -np 4 ./uebpar

# 6. Debug: Press F5 in VSCode
```

### Visual Studio (Native Windows)
```powershell
# 1. Open PowerShell in project directory

# 2. Configure with CMake
mkdir build
cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake

# 3. Build
cmake --build . --config Release

# 4. Run
.\Release\uebpar.exe

# 5. Debug: Open in Visual Studio or use VSCode F5
```

### MinGW/MSYS2 (Unix-like on Windows)
```bash
# 1. Open MSYS2 MinGW 64-bit terminal

# 2. Navigate to project
cd /c/path/to/UEB

# 3. Build
make

# 4. Run
./uebpar.exe
mpiexec -n 4 ./uebpar.exe

# 5. Debug: Use VSCode with MinGW configuration
```

---

## Performance Considerations on Windows

### WSL2 Performance Tips
- ✅ Store files in WSL filesystem (`~/`) for best performance
- ✅ Use `/mnt/c/` for sharing files with Windows, but expect slower I/O
- ✅ WSL2 has near-native Linux performance
- ✅ Allocate more memory to WSL2 if needed (`.wslconfig` file)

### Native Windows Performance
- MSVC typically produces fastest native Windows code
- MinGW has better compatibility but may be slower than MSVC
- File I/O in Windows can be slower than Linux for many small files

### Recommended Approach by Use Case

| Use Case | Recommended | Why |
|----------|-------------|-----|
| **Active Development** | WSL2 | Best compatibility, easiest setup |
| **Production Windows Binary** | MSVC | Optimal Windows performance |
| **Cross-Platform Build** | MinGW or WSL2 | Better Unix compatibility |
| **GPU Development** | Native Windows (CUDA) | Direct GPU access |
| **CI/CD** | WSL2 or Docker | Consistency across platforms |

---

## Additional Resources

### Windows-Specific
- **WSL Documentation**: https://docs.microsoft.com/en-us/windows/wsl/
- **vcpkg**: https://vcpkg.io/
- **MS-MPI**: https://docs.microsoft.com/en-us/message-passing-interface/microsoft-mpi
- **Visual Studio C++**: https://docs.microsoft.com/en-us/cpp/

### Cross-Platform Development
- **CMake**: https://cmake.org/documentation/
- **MSYS2**: https://www.msys2.org/
- **MinGW-w64**: https://www.mingw-w64.org/

### VSCode
- **WSL Tutorial**: https://code.visualstudio.com/docs/remote/wsl-tutorial
- **CMake in VSCode**: https://code.visualstudio.com/docs/cpp/cmake-linux
- **C++ on Windows**: https://code.visualstudio.com/docs/cpp/config-msvc

---

## Quick Reference Card

### Environment Setup
```powershell
# WSL2
wsl --install -d Ubuntu-22.04

# vcpkg
git clone https://github.com/Microsoft/vcpkg C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg install netcdf-c hdf5 curl zlib msmpi --triplet x64-windows

# MSYS2 packages
pacman -S mingw-w64-x86_64-{netcdf,hdf5,curl,msmpi}
```

### Build Commands
```bash
# WSL2/MinGW
make
make clean

# CMake
cmake -B build -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build build --config Release
```

### Run Commands
```bash
# WSL2/MinGW
./uebpar
mpiexec -n 4 ./uebpar

# Windows
.\uebpar.exe
mpiexec -n 4 uebpar.exe
```

---

## Contact & Support

For Windows-specific issues:
- Check this documentation first
- Review `ueb-vscode-setup.md` for general setup
- Check Windows-specific error messages in troubleshooting section

For UEB model questions:
- **David G. Tarboton** - dtarb@usu.edu
- Project: https://github.com/dtarb/UEBFortran

---

*Last Updated: [Current Date]*  
*For general VSCode setup, see: `ueb-vscode-setup.md`*  
*For quick start guide, see: `QUICK-START.md`*
