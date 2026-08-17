# UEB Development Environment Documentation

Welcome to the UEB (Utah Energy Balance Snowmelt Model) development environment documentation. This directory contains all the information you need to set up and develop with UEB on any platform.

## 📚 Documentation Overview

### Quick Start Guides (Read These First!)

1. **[Dev Container (Docker)](ueb-vscode-setup.md#dev-container-setup-docker---recommended)** ⭐ **RECOMMENDED** - Works identically on macOS, Windows, and Linux
   - No native dependency installation at all - Docker Desktop + the Dev Containers VS Code extension
   - Parallel NetCDF/HDF5, MPI, and gdb are pre-built into the container image
   - The easiest option if you're setting up UEB for other people, especially on Windows
   - GPU/CUDA build is out of scope for this path (see native Windows/Linux setup instead)

2. **[QUICK-START.md](QUICK-START.md)** - macOS/Linux Quick Start
   - Native setup for macOS with Homebrew
   - For Linux with apt/yum
   - Requires building parallel NetCDF/HDF5 from source (not a 5-minute setup - see item 1 above
     for a faster path)

3. **[WINDOWS-QUICK-START.md](WINDOWS-QUICK-START.md)** - Windows Quick Start
   - Three native approaches: WSL2, Visual Studio, MinGW
   - Step-by-step for each method
   - See item 1 above if you'd rather skip native setup entirely

### Comprehensive Guides

4. **[ueb-vscode-setup.md](ueb-vscode-setup.md)** - Complete VSCode Setup
   - Dev Container (Docker) setup - see item 1 above
   - Native prerequisites and dependencies
   - VSCode extensions and configuration
   - Build and debug setup
   - Troubleshooting guide
   - For macOS and Linux

5. **[UEB-WINDOWS-SETUP.md](UEB-WINDOWS-SETUP.md)** - Complete Windows Setup
   - WSL2 detailed setup
   - Visual Studio (MSVC) setup
   - MinGW-w64 setup
   - Windows-specific troubleshooting
   - CMake and vcpkg usage

6. **[BUILD-PARALLEL-NETCDF.md](BUILD-PARALLEL-NETCDF.md)** ⭐ **IMPORTANT** - Building Parallel NetCDF
   - Why parallel NetCDF is required for UEB
   - Complete build instructions for macOS and Linux
   - Step-by-step: zlib, curl, HDF5, NetCDF-C
   - Automated build script: `build-parallel-netcdf.sh` (also used inside the Dev Container image)
   - Verification and troubleshooting
   - **Required if `nc-config --has-parallel` returns "no", unless you're using the Dev Container**

### Project Files

7. **[README.md](README.md)** - Project README
   - About the UEB model
   - License information
   - Author contact

---

## 🚀 Which Guide Should I Use?

### I want the same setup to work on any machine (recommended if you're helping others set this up)
→ **Use the [Dev Container (Docker)](ueb-vscode-setup.md#dev-container-setup-docker---recommended)**
- Works identically on macOS, Windows, and Linux - Docker Desktop runs the same Ubuntu container
  regardless of host OS, so there's one set of instructions instead of three
- No native dependency installation, no Homebrew/vcpkg/apt version drift to debug for someone else
- Only gap: the GPU/CUDA build isn't available this way (native setup still needed for that)

### I'm on macOS
→ **Start with [QUICK-START.md](QUICK-START.md)**
- Homebrew gets you the compiler, MPI, curl, and zlib — but **not** a working NetCDF: Homebrew's
  `netcdf`/`hdf5` are not parallel-enabled, and UEB requires the parallel NetCDF4 API to compile.
- You must also run **[BUILD-PARALLEL-NETCDF.md](BUILD-PARALLEL-NETCDF.md)**'s
  `./build-parallel-netcdf.sh` (~15-50 min, one-time) before `make` will succeed.
- Follow the quick checklist (now includes this step)

### I'm on Linux (Ubuntu/Debian/CentOS/RHEL)
→ **Start with [QUICK-START.md](QUICK-START.md)**
- Install dependencies with apt/yum
- Verify your distro's NetCDF/HDF5 packages are actually parallel-enabled
  (`nc-config --has-parallel4`) before assuming they work — if not, use
  **[BUILD-PARALLEL-NETCDF.md](BUILD-PARALLEL-NETCDF.md)** the same way as macOS
- Use existing Makefile
- Standard Unix workflow

### I'm on Windows
→ **Easiest: use the [Dev Container (Docker)](ueb-vscode-setup.md#dev-container-setup-docker---recommended)**
  instead of the native options below - one setup path instead of three, and no vcpkg/MSYS2
  dependency wrangling
→ **If you need a native build** (e.g. for the GPU/CUDA version): **start with
  [WINDOWS-QUICK-START.md](WINDOWS-QUICK-START.md)**
- Choose your approach: WSL2 (recommended), Visual Studio, or MinGW
- Follow platform-specific instructions
- See [UEB-WINDOWS-SETUP.md](UEB-WINDOWS-SETUP.md) for details

### I need detailed troubleshooting
→ **Read the comprehensive guides**
- [ueb-vscode-setup.md](ueb-vscode-setup.md) for macOS/Linux
- [UEB-WINDOWS-SETUP.md](UEB-WINDOWS-SETUP.md) for Windows

---

## 📋 What's Been Set Up

### VSCode Configuration (`.vscode/` directory)

All necessary VSCode configuration files have been created:

- **`c_cpp_properties.json`** - IntelliSense configurations
  - Linux/Mac MPI
  - Mac Homebrew
  - WSL (Windows)
  - Win32 MSVC (Windows)
  - MinGW-w64 (Windows)
  - CUDA GPU

- **`tasks.json`** - Build tasks
  - Build for macOS/Linux
  - Build for WSL
  - Build for MSVC
  - Build for MinGW
  - Build for GPU (CUDA)
  - Clean tasks

- **`launch.json`** - Debug configurations
  - Debug on macOS (lldb)
  - Debug on Linux (gdb)
  - Debug in WSL
  - Debug with MSVC
  - Debug with MinGW
  - Debug GPU version
  - Attach to MPI process

- **`settings.json`** - Workspace settings
  - C/C++ standards (C++11)
  - File associations
  - Editor preferences
  - Makefile configuration

- **`extensions.json`** - Recommended extensions
  - C/C++ tools
  - Makefile/CMake support
  - WSL support
  - Git integration
  - CUDA support

### Build System Files

- **`makefile`** - Unix/Linux/macOS Makefile (Homebrew paths + `NCPREFIX` for parallel NetCDF/HDF5)
- **`Makefile.win`** - Windows MSVC nmake Makefile
- **`CMakeLists.txt`** - Cross-platform CMake configuration
- **`uebGpuMake`** - GPU/CUDA Makefile (existing)

---

## 🎯 Project Structure

```
UEB/
├── Documentation/
│   ├── QUICK-START.md                      # macOS/Linux quick start
│   ├── WINDOWS-QUICK-START.md             # Windows quick start
│   ├── ueb-vscode-setup.md                # Comprehensive Unix guide
│   ├── UEB-WINDOWS-SETUP.md               # Comprehensive Windows guide
│   └── BUILD-PARALLEL-NETCDF.md           # Required parallel NetCDF/HDF5 build guide
│
├── build-parallel-netcdf.sh                # Builds parallel NetCDF/HDF5 from source (required
│                                            # natively; already baked into the Dev Container image)
├── TWDEF.zip                               # Test watershed dataset (extract to data/)
├── data/                                   # Extracted test data (gitignored, created locally)
│
├── .devcontainer/                          # Dev Container (Docker) - recommended setup path
│   ├── Dockerfile                         # Ubuntu 22.04 + mpich + gdb + parallel NetCDF/HDF5
│   └── devcontainer.json                  # VS Code Dev Containers config, extensions, settings
│
├── .vscode/                                # VSCode configuration (used natively and in-container)
│   ├── c_cpp_properties.json              # IntelliSense config
│   ├── tasks.json                         # Build tasks
│   ├── launch.json                        # Debug config
│   ├── settings.json                      # Workspace settings
│   └── extensions.json                    # Extension recommendations
│
├── Build Files/
│   ├── makefile                           # Unix/Linux/macOS build
│   ├── Makefile.win                       # Windows MSVC build
│   ├── CMakeLists.txt                     # Cross-platform CMake
│   └── uebGpuMake                         # GPU/CUDA build
│
├── Source Code/
│   ├── main.cpp                           # MPI main entry point
│   ├── gpumain.cpp                        # GPU main entry point
│   ├── uebpgdecls.h                       # MPI header
│   ├── gpuuebpgdecls.h                    # GPU header
│   ├── ncfunctions.cpp                    # NetCDF I/O (Unix)
│   ├── ncfunctions_mswin.cpp              # NetCDF I/O (Windows)
│   ├── canopy.cpp / gpucanopy.cpp         # Canopy model
│   ├── snow*.cpp / gpusnow*.cpp           # Snow physics
│   ├── uebinputs.cpp / gpuuebinputs.cpp   # Input parsing
│   └── ... (other source files)
│
└── Scripts/
    ├── makeUEB.sh                         # Build script
    └── runUEB.sh                          # Run script
```

---

## 💻 Platform-Specific Quick Reference

### macOS (Homebrew)

```bash
# Compiler, MPI, curl, zlib already installed via Homebrew.
# NetCDF/HDF5 still need to be built with parallel support - required, not optional:
./build-parallel-netcdf.sh                                # ~15-50 min, one-time
~/local/netcdf-parallel/bin/nc-config --has-parallel4      # confirm: yes

# Build
make

# Run against the bundled test dataset (a bare `./uebpar` just exits - it always needs a control file)
mkdir -p data && unzip -q TWDEF.zip -d data
cd data/TWDEF && mpirun -np 4 ../../uebpar control.dat && cd ../..

# Debug in VSCode
# 1. Open project in VSCode
# 2. Select "Mac Homebrew" configuration
# 3. Press F5
```

### Linux (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt install -y \
  build-essential mpich libmpich-dev \
  libcurl4-openssl-dev zlib1g-dev \
  libhdf5-mpich-dev libnetcdf-dev

# Verify the packaged NetCDF actually has parallel support before assuming it works -
# if this prints "no", use build-parallel-netcdf.sh (see BUILD-PARALLEL-NETCDF.md) instead
nc-config --has-parallel4

# Build
make

# Run against the bundled test dataset (a bare `./uebpar` just exits - it always needs a control file)
mkdir -p data && unzip -q TWDEF.zip -d data
cd data/TWDEF && mpirun -np 4 ../../uebpar control.dat && cd ../..
```

### Windows (WSL2) - Recommended

```powershell
# Install WSL2
wsl --install -d Ubuntu-22.04

# Inside WSL2
sudo apt install -y build-essential mpich libmpich-dev \
  libcurl4-openssl-dev zlib1g-dev \
  libhdf5-mpich-dev libnetcdf-dev

make
./uebpar
```

### Windows (Visual Studio)

```powershell
# Install vcpkg and dependencies
cd C:\vcpkg
.\vcpkg install netcdf-c hdf5 curl zlib msmpi --triplet x64-windows

# Build with CMake
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake
cmake --build . --config Release

# Run
.\Release\uebpar.exe
```

### Windows (MinGW)

```bash
# In MSYS2 MinGW 64-bit terminal
pacman -S mingw-w64-x86_64-{netcdf,hdf5,curl,msmpi}

make
./uebpar.exe
```

---

## 🛠️ Common Tasks

### Building

| Platform | Command | Location |
|----------|---------|----------|
| macOS/Linux | `make` | Terminal |
| WSL2 | `make` | WSL Terminal |
| MSVC | `cmake --build build --config Release` | PowerShell |
| MinGW | `make` | MSYS2 Terminal |
| VSCode (any) | Press `Ctrl+Shift+B` | VSCode |

### Running

| Platform | Single Process | 4 Processes |
|----------|---------------|-------------|
| macOS/Linux | `./uebpar` | `mpirun -np 4 ./uebpar` |
| WSL2 | `./uebpar` | `mpirun -np 4 ./uebpar` |
| Windows | `.\uebpar.exe` | `mpiexec -n 4 uebpar.exe` |

### Debugging

| Platform | Method | Key |
|----------|--------|-----|
| All | VSCode debugger | `F5` |
| macOS | lldb | Built-in |
| Linux | gdb | Built-in |
| WSL2 | gdb via pipeTransport | Via VSCode |
| MSVC | Visual Studio debugger | Via VSCode |
| MinGW | gdb | Via VSCode |

---

## 📦 Dependencies

### Core Dependencies (All Platforms)

- **C++ Compiler**: GCC 4.8+, Clang, or MSVC with C++11 support
- **MPI**: MPICH, OpenMPI, or MS-MPI
- **NetCDF-C**: 4.x with parallel support
- **HDF5**: 1.8+ with parallel support
- **curl**: Any recent version
- **zlib**: Any recent version

### Optional Dependencies

- **CUDA Toolkit**: 8.0+ for GPU version (requires NVIDIA GPU)
- **Parallel-NetCDF**: For advanced parallel I/O

### Development Tools

- **VSCode**: Latest version
- **CMake**: 3.15+ (for CMake build method)
- **Git**: For version control

---

## 🔍 Troubleshooting

### Quick Fixes

**Issue**: IntelliSense not working
```
1. Select correct configuration (bottom-right in VSCode)
2. Ctrl+Shift+P → "C/C++: Reset IntelliSense Database"
3. Reload window
```

**Issue**: `fatal error: 'netcdf_par.h' file not found` when building
```bash
# Your NetCDF isn't parallel-enabled (nc-config --has-parallel4 will say "no").
# This is the default state for Homebrew/apt/yum NetCDF packages - see BUILD-PARALLEL-NETCDF.md.
./build-parallel-netcdf.sh
~/local/netcdf-parallel/bin/nc-config --has-parallel4   # should now say: yes
```

**Issue**: Library not found when building
```bash
# macOS
export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH

# Linux
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Windows (PowerShell)
$env:Path += ";C:\vcpkg\installed\x64-windows\bin"
```

**Issue**: MPI not found
```bash
# macOS
brew install mpich

# Linux
sudo apt install mpich libmpich-dev

# Windows (in vcpkg)
.\vcpkg install msmpi:x64-windows
```

### More Help

- See **Troubleshooting** sections in comprehensive guides
- Check system-specific documentation
- Review error messages carefully

---

## 📖 Additional Resources

### Official Documentation
- **UEB Fortran**: https://github.com/dtarb/UEBFortran
- **NetCDF**: https://www.unidata.ucar.edu/software/netcdf/
- **HDF5**: https://portal.hdfgroup.org/documentation/
- **MPI**: https://www.mpi-forum.org/
- **CUDA**: https://docs.nvidia.com/cuda/

### Platform-Specific
- **WSL2**: https://docs.microsoft.com/en-us/windows/wsl/
- **vcpkg**: https://vcpkg.io/
- **Homebrew**: https://brew.sh/
- **MSYS2**: https://www.msys2.org/

### Development Tools
- **VSCode C++**: https://code.visualstudio.com/docs/languages/cpp
- **CMake**: https://cmake.org/documentation/
- **Git**: https://git-scm.com/doc

---

## 👥 Contributing & Support

### Project Information
- **Author**: David G. Tarboton
- **Institution**: Utah State University
- **Email**: dtarb@usu.edu
- **Website**: http://hydrology.usu.edu/dtarb/

### License
MIT Open Source License - see `LICENSE.txt`

### Acknowledgements
- NSF Grant EPS 1135482 CI-WATER
- NASA Grant NNX11AK03G
- USDA-CREES award 2008-34552-19042

---

## ✅ Setup Checklist

Use this checklist to verify your setup:

- [ ] Decided: Dev Container (Docker) or native setup (see "Which Guide Should I Use?" above)

**If using the Dev Container:**
- [ ] Docker Desktop installed and running
- [ ] Dev Containers VS Code extension installed
- [ ] "Dev Containers: Reopen in Container" completed (first build takes a few minutes)
- [ ] Project builds successfully (`make` or `Cmd/Ctrl+Shift+B`)
- [ ] Real run works: `cd data/TWDEF && mpirun -np 4 ../../uebpar control.dat` completes with
      `Done! return value: 0` (test data is auto-extracted on first container creation)
- [ ] Can set breakpoints and debug in VSCode

**If using a native setup:**
- [ ] Platform identified (macOS, Linux, Windows)
- [ ] Quick start guide read
- [ ] VSCode installed
- [ ] Recommended extensions installed
- [ ] C++ compiler installed and working
- [ ] MPI installed (`mpicxx --version` works)
- [ ] NetCDF/HDF5 built **with parallel support** — `nc-config --has-parallel4` prints `yes`
      (run `./build-parallel-netcdf.sh` per `BUILD-PARALLEL-NETCDF.md` if not; a plain
      `brew install netcdf` / `apt install libnetcdf-dev` is usually **not** enough)
- [ ] Project builds successfully (`make` or equivalent)
- [ ] Test data extracted (`mkdir -p data && unzip -q TWDEF.zip -d data`)
- [ ] Real run works: `cd data/TWDEF && mpirun -np 4 ../../uebpar control.dat` completes with
      `Done! return value: 0` (a bare `./uebpar` only confirms the binary launches, not that it works)
- [ ] Can set breakpoints and debug in VSCode
- [ ] IntelliSense working (code completion)

---

## 🎉 You're Ready!

Once your checklist is complete:
1. ✅ Start coding in VSCode
2. ✅ Use `Ctrl+Shift+B` to build
3. ✅ Use `F5` to debug
4. ✅ Refer to comprehensive guides as needed

Happy developing with UEB! 🚀

---

*Last updated: 2024*  
*For the latest updates, check the repository documentation.*
