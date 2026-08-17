# UEB Windows Quick Start Guide

## 🚀 Choose Your Development Approach

Windows developers have **three options** for building UEB. Choose the one that fits your needs:

| Approach | Best For | Difficulty | Compatibility |
|----------|----------|------------|---------------|
| **WSL2** ⭐ | Most users | Easy | Excellent |
| **Visual Studio (MSVC)** | Native Windows | Medium | Good |
| **MinGW** | Unix-like on Windows | Medium | Very Good |

---

## Option 1: WSL2 (Recommended) ⭐

**Why WSL2?** Best compatibility, easiest dependency installation, same commands as Linux/macOS.

### Quick Setup (5-10 minutes)

#### 1. Install WSL2 with Ubuntu
Open PowerShell **as Administrator**:
```powershell
# Install WSL2 and Ubuntu in one command
wsl --install -d Ubuntu-22.04

# Restart your computer when prompted
```

#### 2. Set Up Ubuntu
After restart, open "Ubuntu" from Start menu:
```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Install everything needed (one command!)
sudo apt install -y \
  build-essential \
  gdb \
  mpich \
  libmpich-dev \
  libcurl4-openssl-dev \
  zlib1g-dev \
  libhdf5-mpich-dev \
  libnetcdf-dev \
  libnetcdf-mpi-dev \
  git

# Verify installations
g++ --version
mpicxx --version
nc-config --version
```

#### 3. Get Your Project
```bash
# Option A: Navigate to Windows project (slower but accessible from Windows)
cd /mnt/c/Users/YourUsername/path/to/UEB

# Option B: Clone in WSL home (faster performance)
cd ~
git clone <your-repo-url>
cd UEB
```

#### 4. Install VSCode with WSL Extension
1. **Download VSCode** for Windows: https://code.visualstudio.com/
2. **Open VSCode** on Windows
3. **Install WSL extension**:
   - Press `Ctrl+Shift+X`
   - Search: "WSL"
   - Install "WSL" by Microsoft

#### 5. Open Project in WSL
From WSL terminal:
```bash
cd ~/UEB  # or wherever your project is
code .
```

Or from VSCode: `Ctrl+Shift+P` → "WSL: Open Folder in WSL"

#### 6. Build and Run
```bash
# Build (in WSL terminal or VSCode terminal)
make

# Run with single process
./uebpar

# Run with 4 processes (parallel)
mpirun -np 4 ./uebpar
```

#### 7. Debug in VSCode
1. Set breakpoint: Click left margin in `main.cpp`
2. Press `F5`
3. Select: "Debug UEB (WSL - pipeTransport)"

### ✅ WSL2 Advantages
- ✅ All dependencies via `apt install`
- ✅ Same commands as Linux/macOS team members
- ✅ Existing Makefile works without changes
- ✅ Best MPI support
- ✅ Near-native Linux performance

### ⚠️ WSL2 Tips
- **Performance**: Keep files in WSL filesystem (`~/`) for best speed
- **Access files**: Windows can access WSL at `\\wsl$\Ubuntu-22.04\`
- **VS Code**: Always use WSL extension when working with WSL projects
- **Git**: Configure line endings: `git config --global core.autocrlf true`

---

## Option 2: Visual Studio (MSVC)

**Why MSVC?** Native Windows binaries, best Windows performance, integrated debugger.

### Quick Setup (15-20 minutes)

#### 1. Install Visual Studio
1. Download: https://visualstudio.microsoft.com/downloads/
2. Select: **Desktop development with C++**
3. Also select:
   - ✅ C++ MPI support
   - ✅ Windows 10/11 SDK
   - ✅ C++ CMake tools
   - ✅ Git for Windows

#### 2. Install vcpkg (Package Manager)
Open PowerShell:
```powershell
# Clone vcpkg
cd C:\
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg

# Bootstrap
.\bootstrap-vcpkg.bat

# Add to PATH (run PowerShell as Admin)
[Environment]::SetEnvironmentVariable(
    "Path", 
    "$env:Path;C:\vcpkg", 
    "Machine"
)
```

#### 3. Install Dependencies
```powershell
# Install all libraries (this may take 15-30 minutes)
cd C:\vcpkg
.\vcpkg install netcdf-c:x64-windows
.\vcpkg install hdf5:x64-windows
.\vcpkg install curl:x64-windows
.\vcpkg install zlib:x64-windows
.\vcpkg install msmpi:x64-windows

# Integrate with Visual Studio
.\vcpkg integrate install
```

#### 4. Install MS-MPI
Download and install both:
1. **MS-MPI Runtime**: https://www.microsoft.com/en-us/download/details.aspx?id=100593
2. **MS-MPI SDK**: Same download page

#### 5. Build with CMake
```powershell
# Navigate to project
cd C:\path\to\UEB

# Create build directory
mkdir build
cd build

# Configure (first time only)
cmake .. -DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake

# Build
cmake --build . --config Release

# Run
.\Release\uebpar.exe
```

#### 6. VSCode Setup
1. Open project in VSCode
2. Press `Ctrl+Shift+P` → "CMake: Configure"
3. Select "Visual Studio Community 2022 Release - amd64"
4. Press `Ctrl+Shift+B` → "Build UEB (CMake)"

#### 7. Debug
1. Press `F5`
2. Select: "Debug UEB (MSVC)"

### ✅ MSVC Advantages
- ✅ Native Windows performance
- ✅ Excellent debugger (Visual Studio)
- ✅ Good IDE integration
- ✅ vcpkg simplifies dependencies

### ⚠️ MSVC Considerations
- Takes longer to set up than WSL2
- Requires more disk space (~10GB for VS)
- Different commands than Linux/macOS team

---

## Option 3: MinGW-w64

**Why MinGW?** Unix-like toolchain on Windows, good compatibility with Makefile.

### Quick Setup (10-15 minutes)

#### 1. Install MSYS2
1. Download: https://www.msys2.org/
2. Run installer, use default location: `C:\msys64`
3. Open "MSYS2 MinGW 64-bit" from Start menu

#### 2. Install Packages
In MSYS2 terminal:
```bash
# Update package database
pacman -Syu
# Close terminal when prompted, reopen, then:
pacman -Su

# Install compiler and tools
pacman -S --needed base-devel mingw-w64-x86_64-toolchain

# Install dependencies
pacman -S mingw-w64-x86_64-netcdf \
          mingw-w64-x86_64-hdf5 \
          mingw-w64-x86_64-curl \
          mingw-w64-x86_64-zlib \
          mingw-w64-x86_64-msmpi
```

#### 3. Add MinGW to Windows PATH
1. Open: Settings → System → About → Advanced system settings
2. Click: "Environment Variables"
3. Under "System variables", select "Path", click "Edit"
4. Click "New", add: `C:\msys64\mingw64\bin`
5. Click "OK" on all dialogs

#### 4. Update Makefile
Edit `makefile` for MinGW paths:
```makefile
LIBDIRS = -LC:/msys64/mingw64/lib
INCDIRS = -IC:/msys64/mingw64/include
```

#### 5. Build
Open MSYS2 MinGW 64-bit terminal:
```bash
cd /c/path/to/UEB
make
./uebpar.exe
mpiexec -n 4 ./uebpar.exe
```

#### 6. VSCode Setup
1. Open project in VSCode (Windows)
2. Select configuration: "MinGW-w64" (bottom-right status bar)
3. Press `Ctrl+Shift+B` → "Build UEB (MinGW)"

#### 7. Debug
1. Press `F5`
2. Select: "Debug UEB (MinGW - gdb)"

### ✅ MinGW Advantages
- ✅ Unix-like environment on Windows
- ✅ Existing Makefile works with minor changes
- ✅ Smaller than Visual Studio
- ✅ GCC compiler (same as Linux)

### ⚠️ MinGW Considerations
- Need to use MSYS2 terminal for building
- PATH configuration required
- MPI support not as robust as WSL2

---

## Comparison Table

| Feature | WSL2 | MSVC | MinGW |
|---------|------|------|-------|
| **Setup Time** | 5-10 min | 15-20 min | 10-15 min |
| **Disk Space** | ~2 GB | ~10 GB | ~3 GB |
| **Compatibility** | Excellent | Good | Very Good |
| **Performance** | Native Linux | Native Windows | Good |
| **Debugger** | GDB | Visual Studio | GDB |
| **Dependencies** | `apt install` | vcpkg | pacman |
| **Team Compatibility** | Same as Linux/macOS | Windows-specific | Unix-like |
| **Build System** | Existing makefile | CMake | Existing makefile |
| **MPI Support** | Excellent | Good | Limited |

---

## Recommended Workflow by Use Case

### 🎓 Learning / Development
**→ Use WSL2**
- Easiest to get started
- Best learning resources online
- Same as most tutorials

### 🏢 Enterprise / Production Windows
**→ Use Visual Studio (MSVC)**
- Best native Windows performance
- Professional debugging tools
- Better Windows integration

### 🔧 Cross-Platform Development
**→ Use WSL2 or MinGW**
- Easier to maintain single Makefile
- Better Linux/macOS compatibility
- Same GCC compiler across platforms

### 🎮 GPU Development (CUDA)
**→ Use Native Windows (MSVC or MinGW)**
- Direct GPU access
- CUDA toolkit for Windows
- No WSL2 GPU passthrough needed

---

## Common Windows Issues & Solutions

### Issue: "wsl: command not found"
**Solution**: You're on Windows 10 version older than 2004.
```powershell
# Check Windows version
winver

# If older, manual install:
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# Restart, then:
wsl --set-default-version 2
```

### Issue: "vcpkg: command not found"
**Solution**:
```powershell
# Check if in PATH
$env:Path -split ';' | Select-String vcpkg

# If not, add it:
[Environment]::SetEnvironmentVariable(
    "Path",
    "$env:Path;C:\vcpkg",
    "Machine"
)

# Restart PowerShell
```

### Issue: "Cannot find netcdf.dll"
**Solution**:
```powershell
# Add DLL directory to PATH
$env:Path += ";C:\vcpkg\installed\x64-windows\bin"

# Or copy DLLs to executable directory
Copy-Item "C:\vcpkg\installed\x64-windows\bin\*.dll" ".\build\Release\"
```

### Issue: Permission denied in WSL
**Solution**:
```bash
# Make scripts executable
chmod +x makeUEB.sh runUEB.sh

# Fix ownership
sudo chown -R $USER:$USER .
```

### Issue: Slow builds in WSL with project on /mnt/c/
**Solution**: Move project to WSL filesystem
```bash
# Copy project to WSL home
cp -r /mnt/c/path/to/UEB ~/UEB
cd ~/UEB

# Much faster builds now!
```

### Issue: Line ending errors (^M characters)
**Solution**:
```bash
# Configure Git
git config --global core.autocrlf true

# Convert files (in WSL or Git Bash)
sudo apt install dos2unix
find . -name "*.cpp" -o -name "*.h" | xargs dos2unix
```

---

## File Locations Reference

### WSL2
- **Windows drives**: `/mnt/c/`, `/mnt/d/`
- **WSL home**: `~/` (equals `/home/username/`)
- **Access from Windows**: `\\wsl$\Ubuntu-22.04\home\username\`
- **Project location**: `/home/username/UEB` or `/mnt/c/path/to/UEB`

### MSVC/vcpkg
- **vcpkg root**: `C:\vcpkg\`
- **Libraries**: `C:\vcpkg\installed\x64-windows\`
- **Includes**: `C:\vcpkg\installed\x64-windows\include\`
- **DLLs**: `C:\vcpkg\installed\x64-windows\bin\`
- **Build output**: `.\build\Release\`

### MinGW/MSYS2
- **MSYS2 root**: `C:\msys64\`
- **MinGW binaries**: `C:\msys64\mingw64\bin\`
- **Libraries**: `C:\msys64\mingw64\lib\`
- **Includes**: `C:\msys64\mingw64\include\`
- **Project (in MSYS2)**: `/c/path/to/UEB`

---

## VSCode Configuration Summary

### Select Configuration (Bottom-Right Status Bar)
- **WSL** - For WSL2 development
- **Win32 MSVC** - For Visual Studio development
- **MinGW-w64** - For MinGW development
- **Mac Homebrew** - For macOS (ignored on Windows)

### Build Tasks (Ctrl+Shift+B)
- **Build UEB (WSL)** - Build in WSL2
- **Build UEB (CMake)** - Build with Visual Studio
- **Build UEB (MinGW)** - Build with MinGW
- **Configure CMake (Windows)** - Set up CMake first time

### Debug Configurations (F5)
- **Debug UEB (WSL - pipeTransport)** - Debug in WSL2
- **Debug UEB (MSVC)** - Debug with Visual Studio
- **Debug UEB (MinGW - gdb)** - Debug with GDB

---

## Next Steps

After setup:

1. **✅ Verify build works**
   ```bash
   # In appropriate terminal for your choice
   make          # or cmake --build build
   ./uebpar      # or .\uebpar.exe
   ```

2. **✅ Test MPI**
   ```bash
   mpirun -np 4 ./uebpar     # WSL/MinGW
   mpiexec -n 4 uebpar.exe   # Windows
   ```

3. **✅ Set breakpoint and debug**
   - Open `main.cpp`
   - Click left margin to set breakpoint
   - Press `F5`

4. **✅ Read main documentation**
   - `ueb-vscode-setup.md` - General setup guide
   - `UEB-WINDOWS-SETUP.md` - Full Windows details
   - `README.md` - About UEB model

---

## Getting Help

### Documentation
- **General Setup**: `ueb-vscode-setup.md`
- **Windows Details**: `UEB-WINDOWS-SETUP.md`
- **Quick Start**: `QUICK-START.md` (macOS/Linux)

### Online Resources
- **WSL**: https://docs.microsoft.com/en-us/windows/wsl/
- **vcpkg**: https://vcpkg.io/
- **MSYS2**: https://www.msys2.org/
- **UEB**: https://github.com/dtarb/UEBFortran

### Contact
- **UEB Questions**: David Tarboton - dtarb@usu.edu
- **Build Issues**: Check troubleshooting sections in documentation

---

## Summary

✅ **WSL2 (Recommended)**: Easiest, most compatible, best for most users  
✅ **Visual Studio**: Best native Windows performance, professional tools  
✅ **MinGW**: Unix-like environment, good middle ground

**Choose WSL2 if unsure - you can always switch later!**

Happy coding! 🚀
