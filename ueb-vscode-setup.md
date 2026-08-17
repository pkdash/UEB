# UEB VSCode Development Environment Setup Guide

## Project Overview

**UEB (Utah Energy Balance Snowmelt Model)** is a C++ implementation of an energy balance snowmelt model. The codebase includes:
- **CPU/MPI Parallel Version**: Standard parallel implementation using MPI
- **GPU/CUDA Version**: GPU-accelerated version using NVIDIA CUDA
- **Dependencies**: NetCDF, HDF5, MPI, and related scientific computing libraries

> **Don't want to install a native toolchain at all?** Skip straight to
> [Dev Container Setup (Docker)](#dev-container-setup-docker---recommended) — it works identically
> on macOS, Windows, and Linux and needs no native dependency installation.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Dev Container Setup (Docker) - Recommended](#dev-container-setup-docker---recommended)
3. [Installing Dependencies](#installing-dependencies)
4. [Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required)
5. [VSCode Setup](#vscode-setup)
6. [Building the Project](#building-the-project)
7. [Debugging](#debugging)
8. [Troubleshooting](#troubleshooting)
9. [Running with Test Data](#running-with-test-data)

---

## Prerequisites

### Required Software

#### 1. C++ Compiler
- **GCC/G++** (version 4.8 or later) with C++11 support
  ```bash
  # Check installation
  g++ --version
  
  # Install on macOS
  xcode-select --install
  # Or install via Homebrew
  brew install gcc
  
  # Install on Linux (Ubuntu/Debian)
  sudo apt-get update
  sudo apt-get install build-essential
  
  # Install on Linux (CentOS/RHEL)
  sudo yum groupinstall "Development Tools"
  ```

#### 2. MPI Implementation
- **MPICH** or **OpenMPI** (for parallel version)
  ```bash
  # Check installation
  mpicxx --version
  
  # Install on macOS
  brew install mpich
  # or
  brew install open-mpi
  
  # Install on Linux (Ubuntu/Debian)
  sudo apt-get install mpich
  # or
  sudo apt-get install libopenmpi-dev openmpi-bin
  
  # Install on Linux (CentOS/RHEL)
  sudo yum install mpich mpich-devel
  # or
  sudo yum install openmpi openmpi-devel
  ```

#### 3. NVIDIA CUDA Toolkit (Optional - GPU Version Only)
- **CUDA Toolkit** (version 8.0 or later)
- Requires NVIDIA GPU with compute capability 3.0+
  ```bash
  # Check installation
  nvcc --version
  
  # Download from: https://developer.nvidia.com/cuda-downloads
  # Follow platform-specific installation instructions
  ```

---

## Dev Container Setup (Docker) - Recommended

If you'd rather not install a native toolchain at all — especially useful on Windows, or for
getting a team onto an identical, reproducible environment — use the bundled Dev Container
instead of the native steps in the rest of this guide. It works the same way on macOS, Windows,
and Linux, since Docker Desktop runs the same Ubuntu Linux container regardless of host OS; this
sidesteps the platform-specific quirks entirely (Homebrew's non-parallel NetCDF, vcpkg/MSYS2
package differences, etc.).

### What it gives you

- Ubuntu 22.04, `mpich`, `gdb`, and a parallel-enabled HDF5/NetCDF-C already built (via the same
  `build-parallel-netcdf.sh` documented in
  [Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required)) into
  `/opt/netcdf-parallel` — no manual build step
- The same VS Code C/C++ extensions as the native setup (`.vscode/extensions.json`)
- The bundled `TWDEF.zip` test dataset auto-extracted to `data/` on first container creation
- Debugging via the existing `.vscode/launch.json` configs, unchanged — `gdb` is already at
  `/usr/bin/gdb` inside the container, and `--cap-add=SYS_PTRACE`/`seccomp=unconfined` are set so
  breakpoints/stepping work reliably

### What it doesn't cover

- The GPU/CUDA build (`uebgpu`) — Docker Desktop has no GPU passthrough on macOS, and it's out of
  scope for Windows without a separate WSL2 + CUDA passthrough setup

### Dev Container Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- VS Code extension: **Dev Containers** (`ms-vscode-remote.remote-containers`)

### Dev Container Steps

1. Open this project folder in VS Code
2. Command Palette (`Cmd/Ctrl+Shift+P`) → **"Dev Containers: Reopen in Container"** (or click the
   notification VS Code shows automatically when it detects `.devcontainer/`)
3. First time only: VS Code builds the image — apt packages plus the parallel NetCDF/HDF5 build
   take a few minutes; subsequent reopens reuse the cached image and are near-instant
4. Once the container is up, build and debug exactly as described in
   [Building the Project](#building-the-project) and [Debugging](#debugging) below
   (`Cmd/Ctrl+Shift+B` to build, `F5` → "Debug UEB MPI (Single Process)" to debug) — no native
   dependency installation needed

Everything from here on (VSCode extensions/config, building, debugging, troubleshooting, running
with test data) applies the same way whether you're inside the Dev Container or a native install —
the only difference is where the toolchain came from.

---

## Installing Dependencies

### Core Dependencies Installation Order

The UEB project requires the following libraries in this specific order:

1. **curl**
2. **zlib**
3. **HDF5** (with parallel support)
4. **NetCDF-C** (with parallel support)
5. **Parallel-NetCDF** (pnetcdf) - optional for advanced parallel I/O

### Automated Installation (Recommended)

#### Using Homebrew (macOS)
```bash
# Install basic dependencies
brew install curl zlib

# Install HDF5 with MPI support
brew install hdf5-mpi

# Install NetCDF-C
brew install netcdf

# Install parallel-netcdf (optional)
brew install parallel-netcdf
```

> **macOS/Homebrew caveat:** Homebrew's `netcdf` formula is linked against the plain (non-parallel)
> `hdf5` formula, not `hdf5-mpi` — `nc-config --has-parallel4` will report `no` and `netcdf_par.h`
> will not exist anywhere under `/opt/homebrew`. UEB's `ncfunctions.cpp` requires `netcdf_par.h`
> (`nc_open_par`, `nc_create_par`, `nc_var_par_access`) to compile at all, so **the Homebrew install
> above is not sufficient on macOS** — it only gets you `curl`/`zlib` and a `hdf5-mpi` package that
> conflicts with the plain `hdf5` also depended on by other formulae (e.g. `gdal`). See
> [Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required) below for the
> approach that works without touching your existing Homebrew packages.

#### Using Package Manager (Linux - Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install -y \
  libcurl4-openssl-dev \
  zlib1g-dev \
  libhdf5-mpi-dev \
  libnetcdf-dev \
  libnetcdf-mpi-dev \
  libnetcdf-c++4-dev
```

#### Using Package Manager (Linux - CentOS/RHEL)
```bash
sudo yum install -y \
  libcurl-devel \
  zlib-devel \
  hdf5-devel \
  netcdf-devel \
  netcdf-cxx-devel
```

### Manual Installation (If Package Managers Unavailable)

If you need to compile from source, follow the instructions in `compile parallel netcdf_mpich.txt`:

#### 1. Install curl
```bash
cd /tmp
wget https://curl.se/download/curl-latest.tar.gz
tar -xzf curl-latest.tar.gz
cd curl-*
./configure --prefix=/usr/local
make
sudo make install
```

#### 2. Install zlib
```bash
cd /tmp
wget http://zlib.net/zlib-1.2.13.tar.gz
tar -xzf zlib-1.2.13.tar.gz
cd zlib-*
./configure --prefix=/usr/local
make
sudo make install
```

#### 3. Install HDF5 with parallel support
```bash
cd /tmp
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.3/src/hdf5-1.14.3.tar.gz
tar -xzf hdf5-1.14.3.tar.gz
cd hdf5-*
LIBS=-ldl CC=mpicc ./configure \
  --enable-parallel \
  --prefix=/usr/local \
  --with-zlib=/usr/local
make
sudo make install
```

#### 4. Install NetCDF-C
```bash
cd /tmp
wget https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-c-4.9.2.tar.gz
tar -xzf netcdf-c-4.9.2.tar.gz
cd netcdf-c-*
LIBS=-ldl CC=mpicc \
  LDFLAGS=-L/usr/local/lib \
  CPPFLAGS=-I/usr/local/include \
  ./configure \
    --disable-shared \
    --enable-parallel-tests \
    --prefix=/usr/local
make
sudo make install
```

#### 5. Install Parallel-NetCDF (Optional)
```bash
cd /tmp
wget https://parallel-netcdf.github.io/Release/pnetcdf-1.12.3.tar.gz
tar -xzf pnetcdf-1.12.3.tar.gz
cd pnetcdf-*
./configure --prefix=/usr/local
make
sudo make install
```

### Verify Installation

```bash
# Check library locations
which nc-config
nc-config --all

# Check HDF5
which h5cc
h5cc -showconfig

# Check pkg-config can find libraries
pkg-config --cflags --libs netcdf hdf5
```

---

## Building Parallel NetCDF/HDF5 (Required)

UEB's `ncfunctions.cpp` uses the parallel NetCDF4 API (`#include <netcdf_par.h>`, `nc_open_par`,
`nc_create_par`, `nc_var_par_access`) for MPI-collective NetCDF I/O. This requires NetCDF-C built
against an HDF5 that was itself configured `--enable-parallel`. Standard package-manager installs
(Homebrew, apt, yum) do not provide this — see the caveat above.

The repo includes `build-parallel-netcdf.sh` (documented in detail in `BUILD-PARALLEL-NETCDF.md`),
which builds HDF5 (parallel-enabled) and NetCDF-C from source into an isolated prefix — by default
`$HOME/local/netcdf-parallel` — without touching or conflicting with any Homebrew/apt/yum packages
also used by other projects (e.g. `gdal`, which depends on the plain `hdf5`/`netcdf` formulae).

### 1. Run the build script

```bash
# Requires mpicc (from your MPI install) and curl/wget on PATH
./build-parallel-netcdf.sh
# Or build into a custom location:
# ./build-parallel-netcdf.sh /path/to/install/prefix
```

This builds zlib, then HDF5 (`--enable-parallel`), then NetCDF-C (`--disable-dap`, so it has no
curl dependency of its own — the final UEB binary links against the curl already provided by your
package manager). It downloads several hundred MB of sources and compiles them, so expect roughly
**15-50 minutes** depending on your machine. It's safe to re-run — each step is skipped if its
library is already installed in the target prefix.

### 2. Verify

```bash
~/local/netcdf-parallel/bin/nc-config --has-parallel4   # should print: yes
ls ~/local/netcdf-parallel/include/netcdf_par.h          # should exist
```

### 3. Point UEB's makefile at it

`makefile` already defines an `NCPREFIX` variable used to build `INCDIRS`/`LIBDIRS`/`LDFLAGS`, with
an `-Wl,-rpath,$(NCPREFIX)/lib` linker flag so the built `uebpar` finds its shared libraries at
runtime without needing `DYLD_LIBRARY_PATH`/`LD_LIBRARY_PATH` set:

```makefile
NCPREFIX = $(HOME)/local/netcdf-parallel
LIBDIRS = -L$(NCPREFIX)/lib -L/opt/homebrew/lib -L/usr/local/lib
LDFLAGS = -lnetcdf -lhdf5_hl -lhdf5 -lcurl -lm -lz -ldl -Wl,-rpath,$(NCPREFIX)/lib
INCDIRS = -I$(NCPREFIX)/include -I/opt/homebrew/include -I/usr/local/include
```

If you built into the default `$HOME/local/netcdf-parallel` prefix, no makefile changes are needed.
If you used a custom prefix (step 1 above), update `NCPREFIX` to match.

---

## VSCode Setup

### 1. Install VSCode
Download from: https://code.visualstudio.com/

### 2. Required VSCode Extensions

Install these extensions from the VSCode marketplace:

#### Essential Extensions
1. **C/C++** (by Microsoft) - `ms-vscode.cpptools`
   - IntelliSense, debugging, and code browsing
   
2. **C/C++ Extension Pack** (by Microsoft) - `ms-vscode.cpptools-extension-pack`
   - Includes C/C++ Themes and additional tools

3. **Makefile Tools** (by Microsoft) - `ms-vscode.makefile-tools`
   - Makefile support and IntelliSense

4. **Better C++ Syntax** (by Jeff Hykin) - `jeff-hykin.better-cpp-syntax`
   - Enhanced syntax highlighting

#### Recommended Extensions
5. **GitLens** (by GitKraken) - `eamodio.gitlens`
   - Git integration and history

6. **Error Lens** (by Alexander) - `usernamehw.errorlens`
   - Inline error highlighting

7. **Code Spell Checker** (by Street Side Software) - `streetsidesoftware.code-spell-checker`
   - Spelling checker for code and comments

8. **Clangd** (Optional alternative to C/C++ extension)
   - `llvm-vs-code-extensions.vscode-clangd`
   - More powerful IntelliSense (requires clangd installation)

#### GPU/CUDA Development Extensions (If using GPU version)
9. **CUDA C++** (by kriegalex) - `kriegalex.vscode-cudacpp`
   - CUDA syntax highlighting

10. **Nsight Visual Studio Code Edition** (by NVIDIA)
    - CUDA debugging support

### 3. VSCode Configuration Files

Create a `.vscode` directory in the project root and add these configuration files:

#### a. `c_cpp_properties.json` - IntelliSense Configuration

```json
{
    "configurations": [
        {
            "name": "Linux/Mac MPI",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/local/include",
                "/usr/include",
                "/usr/include/openmpi",
                "/usr/lib/x86_64-linux-gnu/openmpi/include"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/mpicxx",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "linux-gcc-x64",
            "compilerArgs": [
                "-Wall",
                "-g"
            ]
        },
        {
            "name": "Mac Homebrew",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/local/include",
                "/opt/homebrew/include",
                "/opt/homebrew/opt/netcdf/include",
                "/opt/homebrew/opt/hdf5-mpi/include",
                "/opt/homebrew/opt/open-mpi/include"
            ],
            "defines": [],
            "compilerPath": "/opt/homebrew/bin/mpicxx",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "macos-gcc-x64",
            "compilerArgs": [
                "-Wall",
                "-g"
            ]
        },
        {
            "name": "CUDA GPU",
            "includePath": [
                "${workspaceFolder}/**",
                "/usr/local/include",
                "/usr/local/cuda/include",
                "/usr/local/cuda/samples/common/inc"
            ],
            "defines": [
                "__CUDACC__"
            ],
            "compilerPath": "/usr/local/cuda/bin/nvcc",
            "cStandard": "c11",
            "cppStandard": "c++11",
            "intelliSenseMode": "linux-gcc-x64"
        }
    ],
    "version": 4
}
```

#### b. `tasks.json` - Build Tasks

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build UEB MPI (makefile)",
            "type": "shell",
            "command": "make",
            "args": [
                "-j4"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": [
                "$gcc"
            ],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "Clean UEB",
            "type": "shell",
            "command": "make",
            "args": [
                "clean"
            ],
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Build UEB GPU (CUDA)",
            "type": "shell",
            "command": "make",
            "args": [
                "-f",
                "uebGpuMake",
                "-j4"
            ],
            "group": "build",
            "problemMatcher": [
                "$gcc"
            ],
            "presentation": {
                "reveal": "always",
                "panel": "shared"
            }
        },
        {
            "label": "Clean UEB GPU",
            "type": "shell",
            "command": "make",
            "args": [
                "-f",
                "uebGpuMake",
                "clean"
            ],
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Rebuild UEB MPI",
            "dependsOn": [
                "Clean UEB",
                "Build UEB MPI (makefile)"
            ],
            "dependsOrder": "sequence",
            "group": "build"
        }
    ]
}
```

#### c. `launch.json` - Debug Configuration

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug UEB MPI (Single Process)",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/uebpar",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "LD_LIBRARY_PATH",
                    "value": "/usr/local/lib:${env:LD_LIBRARY_PATH}"
                }
            ],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "Build UEB MPI (makefile)",
            "miDebuggerPath": "/usr/bin/gdb"
        },
        {
            "name": "Debug UEB MPI (mpirun 4 processes)",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/uebpar",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "LD_LIBRARY_PATH",
                    "value": "/usr/local/lib:${env:LD_LIBRARY_PATH}"
                }
            ],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "Build UEB MPI (makefile)",
            "miDebuggerPath": "/usr/bin/gdb",
            "miDebuggerArgs": "attach",
            "processId": "${command:pickProcess}"
        },
        {
            "name": "Debug UEB GPU",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/uebgpu",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [
                {
                    "name": "LD_LIBRARY_PATH",
                    "value": "/usr/local/cuda/lib64:/usr/local/lib:${env:LD_LIBRARY_PATH}"
                }
            ],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "Build UEB GPU (CUDA)",
            "miDebuggerPath": "/usr/bin/gdb"
        }
    ]
}
```

#### d. `settings.json` - Workspace Settings

```json
{
    "files.associations": {
        "*.h": "cpp",
        "iostream": "cpp",
        "vector": "cpp",
        "array": "cpp",
        "string": "cpp",
        "algorithm": "cpp",
        "cmath": "cpp",
        "netcdf.h": "c"
    },
    "C_Cpp.default.cppStandard": "c++11",
    "C_Cpp.default.cStandard": "c11",
    "C_Cpp.default.compilerPath": "/usr/bin/mpicxx",
    "C_Cpp.default.includePath": [
        "${workspaceFolder}/**",
        "/usr/local/include",
        "/usr/include"
    ],
    "C_Cpp.errorSquiggles": "enabled",
    "editor.formatOnSave": false,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "editor.tabSize": 4,
    "editor.detectIndentation": false,
    "[cpp]": {
        "editor.defaultFormatter": "ms-vscode.cpptools",
        "editor.tabSize": 4
    },
    "makefile.configurations": [
        {
            "name": "Default",
            "makefilePath": "${workspaceFolder}/makefile"
        }
    ]
}
```

### 4. Create the `.vscode` Directory

Run these commands in the project root:

```bash
# Create .vscode directory
mkdir -p .vscode

# Create configuration files
touch .vscode/c_cpp_properties.json
touch .vscode/tasks.json
touch .vscode/launch.json
touch .vscode/settings.json
```

Then copy the JSON configurations above into each respective file.

---

## Building the Project

### Method 1: Using VSCode Tasks (Recommended)

1. Press `Cmd+Shift+B` (Mac) or `Ctrl+Shift+B` (Linux/Windows)
2. Select the build task:
   - **Build UEB MPI (makefile)** - Builds the MPI version
   - **Build UEB GPU (CUDA)** - Builds the GPU version
   - **Clean UEB** - Cleans build artifacts
   - **Rebuild UEB MPI** - Clean + Build

### Method 2: Using Terminal in VSCode

Open integrated terminal (`Ctrl+` ` or View > Terminal`):

```bash
# Build MPI version
make

# Build with parallel compilation (faster)
make -j4

# Clean build
make clean

# Build GPU version
make -f uebGpuMake

# Clean GPU build
make -f uebGpuMake clean
```

### Method 3: Using Build Script

```bash
# Make script executable
chmod +x makeUEB.sh

# Edit the script to update paths (if needed)
# Set correct paths for your installation:
# - LD_LIBRARY_PATH
# - CPPFLAGS
# - LDFLAGS

# Run the script
./makeUEB.sh
```

### Build Outputs

- **MPI Version**: `uebpar` executable
- **GPU Version**: `uebgpu` executable

### Update Makefile Paths (if needed)

`make` will fail with `fatal error: 'netcdf_par.h' file not found` as soon as it reaches
`ncfunctions.cpp` unless you've completed
[Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required) first.

`makefile` already points at the parallel NetCDF/HDF5 build via an `NCPREFIX` variable:

```makefile
NCPREFIX = $(HOME)/local/netcdf-parallel
LIBDIRS = -L$(NCPREFIX)/lib -L/opt/homebrew/lib -L/usr/local/lib
LDFLAGS = -lnetcdf -lhdf5_hl -lhdf5 -lcurl -lm -lz -ldl -Wl,-rpath,$(NCPREFIX)/lib
INCDIRS = -I$(NCPREFIX)/include -I/opt/homebrew/include -I/usr/local/include
```

Only edit `NCPREFIX` if you built the parallel stack into a non-default location.

---

## Debugging

### Debugging MPI Programs

#### Option 1: Debug Single Process
1. Press `F5` or click Run > Start Debugging
2. Select "Debug UEB MPI (Single Process)"
3. This runs the program without mpirun for easier debugging

#### Option 2: Debug MPI Multi-Process
Debugging multi-process MPI applications is more complex:

**Using terminal with xterm:**
```bash
# Start 4 processes, each in separate xterm window with gdb attached
mpirun -np 4 xterm -e gdb ./uebpar
```

**Using tmux:**
```bash
# Start tmux session
tmux new-session -d -s mpi_debug

# Split into panes and run gdb in each
tmux split-window -h
tmux select-pane -t 0
tmux send-keys "gdb ./uebpar" C-m

tmux select-pane -t 1
tmux send-keys "gdb ./uebpar" C-m

# Attach to session
tmux attach -t mpi_debug
```

**Attach to running process:**
1. Run program with mpirun: `mpirun -np 4 ./uebpar`
2. Find process IDs: `ps aux | grep uebpar`
3. In VSCode, use "Debug UEB MPI (mpirun 4 processes)" and select process

### Debugging CUDA Programs

#### Using cuda-gdb
```bash
# Build with debug flags (already in uebGpuMake)
make -f uebGpuMake

# Run with cuda-gdb
cuda-gdb ./uebgpu

# Common cuda-gdb commands:
# (cuda-gdb) break main
# (cuda-gdb) run
# (cuda-gdb) cuda thread
# (cuda-gdb) cuda block
# (cuda-gdb) cuda kernel
```

#### Using VSCode with CUDA
1. Install NVIDIA Nsight VSCode extension
2. Press `F5` and select "Debug UEB GPU"
3. Set breakpoints in both CPU and GPU code

### Setting Breakpoints

- Click in the left margin next to line numbers
- Or press `F9` on a line
- Conditional breakpoints: Right-click breakpoint > Edit Breakpoint

### Debug Console Commands

While debugging, use the Debug Console:
```
# Print variable
p myVariable

# Print array elements
p myArray[0]@10

# Print struct members
p myStruct.member

# Call functions
call myFunction()
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Library Not Found Errors

**Error**: `error while loading shared libraries: libnetcdf.so.XX: cannot open shared object file`

**Solution**:
```bash
# Find where library is installed
find /usr -name "libnetcdf.so*" 2>/dev/null

# Add to library path (temporary)
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Add to library path (permanent - Linux)
echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Add to library path (permanent - macOS)
echo 'export DYLD_LIBRARY_PATH=/usr/local/lib:$DYLD_LIBRARY_PATH' >> ~/.zshrc
source ~/.zshrc

# Update system library cache (Linux)
sudo ldconfig
```

#### 2. Header Files Not Found

**Error**: `fatal error: netcdf.h: No such file or directory`

**Solution**:
```bash
# Find header location
find /usr -name "netcdf.h" 2>/dev/null

# Update INCDIRS in makefile
INCDIRS = -I/usr/local/include -I/path/to/netcdf/include

# Or set environment variable
export CPPFLAGS="-I/usr/local/include"
```

#### 2a. `netcdf_par.h` Not Found (or `nc-config --has-parallel4` says `no`)

**Error**: `fatal error: 'netcdf_par.h' file not found` when compiling `ncfunctions.cpp`

**Cause**: Your NetCDF-C install is not built against a parallel-enabled HDF5. This is the default
state for Homebrew/apt/yum-installed NetCDF — see
[Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required).

**Solution**: Run `./build-parallel-netcdf.sh` (details in `BUILD-PARALLEL-NETCDF.md`), then confirm:
```bash
~/local/netcdf-parallel/bin/nc-config --has-parallel4   # should print: yes
```
`makefile`'s `NCPREFIX` variable already points at the default install location; update it only if
you built to a custom prefix.

#### 3. MPI Compiler Not Found

**Error**: `mpicxx: command not found`

**Solution**:
```bash
# Find MPI installation
which mpicc mpicxx mpirun

# If not found, install MPI (see Prerequisites section)

# If installed but not in PATH, add to PATH
export PATH=/usr/local/bin:$PATH

# Or create symbolic link
sudo ln -s /path/to/mpicxx /usr/local/bin/mpicxx
```

#### 4. CUDA Compiler Not Found

**Error**: `nvcc: command not found`

**Solution**:
```bash
# Add CUDA to PATH
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Add to shell profile (permanent)
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
```

#### 5. IntelliSense Not Working

**Solution**:
1. Open Command Palette (`Cmd+Shift+P` or `Ctrl+Shift+P`)
2. Type "C/C++: Edit Configurations (UI)"
3. Verify include paths
4. Or run "C/C++: Reset IntelliSense Database"
5. Reload window: "Developer: Reload Window"

#### 6. Wrong Configuration Selected

**Solution**:
- Click on configuration name in status bar (bottom right)
- Select appropriate configuration:
  - "Linux/Mac MPI" for standard build
  - "Mac Homebrew" for Homebrew installations
  - "CUDA GPU" for GPU development

#### 7. Build Errors with Homebrew (macOS)

If libraries were installed with Homebrew:

```bash
# Find library paths
brew --prefix netcdf
brew --prefix hdf5-mpi
brew --prefix open-mpi

# Update makefile with Homebrew paths
LIBDIRS = -L$(brew --prefix)/lib
INCDIRS = -I$(brew --prefix)/include
```

#### 8. Parallel NetCDF Linking Issues

**Error**: `undefined reference to 'ncmpi_*'`

**Solution**: Add `-lpnetcdf` before `-lnetcdf` in makefile:
```makefile
LDFLAGS = -lpnetcdf -lnetcdf -lhdf5_hl -lhdf5 -lcurl -lm -lz -ldl
```

### Getting Help

If you encounter issues:

1. **Check Build Output**: Look for specific error messages
2. **Verify Dependencies**: Ensure all libraries are installed
3. **Check Library Paths**: Use `ldd` (Linux) or `otool -L` (macOS) on executables
   ```bash
   ldd ./uebpar
   # or on macOS:
   otool -L ./uebpar
   ```
4. **Enable Verbose Build**: 
   ```bash
   make VERBOSE=1
   ```
5. **Check Documentation**: See `README.md` and `compile parallel netcdf_mpich.txt`

---

## Running the Project

### MPI Version

```bash
# Run with 1 process (for testing)
./uebpar

# Run with 4 processes
mpirun -np 4 ./uebpar

# Run with specific hosts
mpirun -np 4 -host node1,node2,node3,node4 ./uebpar
```

### GPU Version

```bash
# Run GPU version
./uebgpu

# Check GPU availability first
nvidia-smi
```

### Using the Run Script

```bash
chmod +x runUEB.sh
./runUEB.sh
```

---

## Running with Test Data

The repo includes a bundled sample dataset, `TWDEF.zip` (a test watershed with ~6 months of forcing
data), that doubles as an end-to-end smoke test for a new build. It is not extracted automatically —
set it up once per clone:

### 1. Extract the test data

```bash
mkdir -p data
unzip -q TWDEF.zip -d data
```

This creates `data/TWDEF/` containing `control.dat`, `param.dat`, `siteinitial.dat`,
`inputcontrol.dat`, `outputcontrol.dat`, the watershed/forcing NetCDF files, and reference output
files (`SWE.nc`, `SWIT.nc`, `SWISM.nc`, `aggout.nc`, `Point11.txt`, `Point35.txt`) from a prior run
that your build's output can be compared against.

`data/` is listed in `.gitignore` — it's local scratch, safe to delete and re-extract at any time,
and running UEB against it will overwrite the bundled reference outputs in place. If you want to
diff against them afterward, back them up first:

```bash
mkdir -p data/TWDEF/_reference_outputs
cp data/TWDEF/{SWE,SWIT,SWISM,aggout}.nc data/TWDEF/Point11.txt data/TWDEF/Point35.txt \
   data/TWDEF/_reference_outputs/
```

### 2. Run UEB against it

`control.dat` and the files it references use paths relative to the directory it's run from, so
run from inside `data/TWDEF/`, pointing at the `uebpar` you built at the repo root:

```bash
cd data/TWDEF
mpirun -np 1 ../../uebpar control.dat
cd ../..
```

A successful run prints per-time-step progress (`number of time steps: 5808`, `percent completed:
...`) and ends with `Done! return value: 0`, having (re)written `SWE.nc`, `SWIT.nc`, `SWISM.nc`,
`aggout.nc`, `Point11.txt`, and `Point35.txt` in `data/TWDEF/`.

### 3. (Optional) Compare against the reference outputs

If you backed up the reference outputs in step 1, a quick sanity check with Python's `netCDF4`
package:

```bash
python3 - <<'EOF'
from netCDF4 import Dataset
import numpy as np
new = Dataset("data/TWDEF/SWE.nc")
ref = Dataset("data/TWDEF/_reference_outputs/SWE.nc")
diff = np.abs(new.variables["SWE"][:].astype("float64") - ref.variables["SWE"][:].astype("float64"))
print("max abs diff:", diff.max(), " mean abs diff:", diff.mean())
EOF
```

Small differences (well under 1% of the SWE range) are expected and normal — they come from
rebuilding this ~decade-old code against a modern compiler/NetCDF/HDF5/MPI toolchain (floating-point
rounding, math-library implementation differences), not from a logic error. Large differences, NaNs,
or all-fill-value output indicate an actual problem with the build or run configuration.

---

## Project Structure

```
UEB/
├── main.cpp                    # Main entry point (MPI version)
├── gpumain.cpp                 # Main entry point (GPU version)
├── uebpgdecls.h               # Header with function declarations (MPI)
├── gpuuebpgdecls.h            # Header with function declarations (GPU)
├── makefile                    # Build configuration (MPI)
├── uebGpuMake                 # Build configuration (GPU)
├── makeUEB.sh                 # Build script
├── runUEB.sh                  # Run script
│
├── canopy.cpp                 # Canopy model implementation
├── matrixnvector.cpp          # Matrix and vector operations
├── ncfunctions.cpp            # NetCDF I/O functions (Unix/Linux)
├── ncfunctions_mswin.cpp      # NetCDF I/O functions (Windows)
├── snowdgtv.cpp               # Snow model: differential equations
├── snowdv.cpp                 # Snow model: derivatives
├── snowxv.cpp                 # Snow model: auxiliary functions
├── uebdecls.cpp               # UEB declarations
├── uebinputs.cpp              # Input file parsing
│
├── gpu*.cpp                   # GPU versions of above files
│
├── README.md                  # Project README
├── LICENSE.txt                # MIT License
├── compile parallel netcdf_mpich.txt  # Dependency install guide
├── UEB Parallel input output settings.docx  # Documentation
│
├── build-parallel-netcdf.sh   # Builds parallel-enabled HDF5/NetCDF-C from source (see below)
├── BUILD-PARALLEL-NETCDF.md   # Detailed guide for build-parallel-netcdf.sh
├── TWDEF.zip                  # Test watershed dataset (extract to data/, see "Running with Test Data")
├── data/                      # Extracted test data (gitignored, created locally - not in git)
└── .gitignore
```

---

## Additional Resources

### Official Documentation
- **UEB Fortran Version**: https://github.com/dtarb/UEBFortran
- **NetCDF Documentation**: https://www.unidata.ucar.edu/software/netcdf/docs/
- **HDF5 Documentation**: https://portal.hdfgroup.org/documentation/index.html
- **MPI Tutorial**: https://mpitutorial.com/
- **CUDA Programming Guide**: https://docs.nvidia.com/cuda/cuda-c-programming-guide/

### VSCode Resources
- **C++ in VSCode**: https://code.visualstudio.com/docs/languages/cpp
- **Debugging in VSCode**: https://code.visualstudio.com/docs/editor/debugging
- **Tasks in VSCode**: https://code.visualstudio.com/docs/editor/tasks

### Contact
For UEB-specific questions, contact:
- **David G. Tarboton**
- Utah State University
- Email: dtarb@usu.edu
- Website: http://hydrology.usu.edu/dtarb/

---

## Quick Start Checklist

- [ ] Install GCC/G++ compiler
- [ ] Install MPI (mpich or openmpi)
- [ ] Install curl and zlib (Homebrew/apt/yum is fine)
- [ ] Build parallel HDF5 + NetCDF-C from source: `./build-parallel-netcdf.sh` (see
      [Building Parallel NetCDF/HDF5 (Required)](#building-parallel-netcdfhdf5-required) — Homebrew/apt/yum
      NetCDF packages are not parallel-enabled and will not work)
- [ ] Verify: `~/local/netcdf-parallel/bin/nc-config --has-parallel4` prints `yes`
- [ ] (Optional) Install CUDA toolkit for GPU version
- [ ] Install VSCode
- [ ] Install required VSCode extensions
- [ ] Create `.vscode` directory with configuration files
- [ ] Update makefile's `NCPREFIX` if you built to a non-default location
- [ ] Build project: `make` or use VSCode build task
- [ ] Extract test data: `mkdir -p data && unzip -q TWDEF.zip -d data` (see
      [Running with Test Data](#running-with-test-data))
- [ ] Run a smoke test: `cd data/TWDEF && mpirun -np 1 ../../uebpar control.dat`
- [ ] Set breakpoints and start debugging

---

## Tips for Productive Development

1. **Use Build Tasks**: Press `Cmd+Shift+B` for quick builds
2. **Keyboard Shortcuts**:
   - `F5` - Start Debugging
   - `F9` - Toggle Breakpoint
   - `F10` - Step Over
   - `F11` - Step Into
   - `Shift+F11` - Step Out
3. **Code Navigation**:
   - `Cmd+Click` (Mac) or `Ctrl+Click` - Go to Definition
   - `Cmd+P` - Quick file open
   - `Cmd+Shift+O` - Go to symbol in file
   - `Cmd+T` - Go to symbol in workspace
4. **Search**:
   - `Cmd+F` - Find in file
   - `Cmd+Shift+F` - Find in workspace
5. **Format Code**: Install clang-format and use `Shift+Alt+F`

---

## License

This project is licensed under the MIT License. See `LICENSE.txt` for details.
