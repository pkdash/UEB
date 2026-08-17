# UEB VSCode Setup - Quick Start Summary

> **Setting this up on Windows, or for someone else?** Consider the
> [Dev Container (Docker)](ueb-vscode-setup.md#dev-container-setup-docker---recommended) instead —
> it works identically on macOS/Windows/Linux with no native dependency installation (parallel
> NetCDF/HDF5, MPI, and gdb are pre-built into the container image). Everything below is the
> native macOS/Homebrew path instead.

## ✅ What Has Been Created

I've analyzed the UEB (Utah Energy Balance Snowmelt Model) codebase and created a complete VSCode development environment setup for you.

### 📄 Documentation Created:
- **`ueb-vscode-setup.md`** - Comprehensive setup guide (24KB) with:
  - Prerequisites and dependency installation instructions
  - VSCode extension recommendations
  - Build and debug configuration
  - Troubleshooting guide
  - Project structure overview

### ⚙️ VSCode Configuration Files Created (`.vscode/` directory):
1. **`c_cpp_properties.json`** - IntelliSense configuration with 3 profiles:
   - Linux/Mac MPI (standard)
   - Mac Homebrew (your system ✓)
   - CUDA GPU (if needed)

2. **`tasks.json`** - Build tasks you can run with `Cmd+Shift+B`:
   - Build UEB MPI (default)
   - Build UEB GPU
   - Clean builds
   - Rebuild (clean + build)

3. **`launch.json`** - Debug configurations you can run with `F5`:
   - Debug single process
   - Debug with lldb (macOS)
   - Debug GPU version
   - Attach to running MPI process

4. **`settings.json`** - Workspace settings:
   - C++ standard (C++11)
   - File associations
   - Editor preferences
   - Makefile configuration

5. **`extensions.json`** - Recommended VSCode extensions list

### 🔧 Makefile Updated:
- Updated library and include paths to use Homebrew locations (`/opt/homebrew`)

---

## 🎯 Your System Status

### ✅ Already Installed:
- ✓ C++ Compiler (Apple Clang 17.0.0)
- ✓ MPI (mpicxx available)
- ✓ NetCDF 4.10.0 (via Homebrew)
- ✓ HDF5 2.1.1 (via Homebrew)
- ✓ LLDB debugger
- ✓ Homebrew package manager

### ⚠️ Not Installed (Optional):
- CUDA toolkit (only needed for GPU version)

### 🚫 Still Missing (Required Before You Can Build)

The Homebrew `netcdf`/`hdf5` above are **not** parallel-enabled (`nc-config --has-parallel4` reports
`no`, and `netcdf_par.h` doesn't exist under `/opt/homebrew`). UEB's `ncfunctions.cpp` requires the
parallel NetCDF4 API to compile at all — `make` will fail with `fatal error: 'netcdf_par.h' file not
found` as soon as it reaches that file. See **[Step 0 below](#0-build-parallel-netcdfhdf5-required-first)**
before building — this is not optional, and Homebrew alone will not get you a working build.

---

## 🚀 Next Steps

### 0. Build Parallel NetCDF/HDF5 (Required First)

```bash
# Builds HDF5 (--enable-parallel) and NetCDF-C from source into ~/local/netcdf-parallel,
# without touching your Homebrew netcdf/hdf5 (which other tools like gdal may depend on).
# Takes ~15-50 minutes.
./build-parallel-netcdf.sh

# Verify:
~/local/netcdf-parallel/bin/nc-config --has-parallel4   # should print: yes
```

`makefile` already points at `~/local/netcdf-parallel` via its `NCPREFIX` variable, so no further
makefile edits are needed if you used the default install location. Full details:
`BUILD-PARALLEL-NETCDF.md`.

### 1. Install VSCode Extensions
Open VSCode in this project and you'll see a notification to install recommended extensions, or:
1. Press `Cmd+Shift+X` to open Extensions view
2. Click "Install" on the recommended extensions shown

**Essential Extensions:**
- C/C++ (by Microsoft)
- C/C++ Extension Pack
- Makefile Tools

### 2. Select the Correct Configuration
1. Look at the bottom-right of VSCode status bar
2. Click on the configuration name
3. Select **"Mac Homebrew"** (this matches your system)

### 3. Build the Project
Option A - Using VSCode:
- Press `Cmd+Shift+B`
- Select "Build UEB MPI (makefile)"

Option B - Using Terminal:
```bash
make
```

### 4. Test the Build

```bash
# Check if executable was created
ls -lh uebpar

# Running with no arguments just confirms the binary launches - it exits immediately
# ("file not found exiting") since it always requires a control file argument:
./uebpar

# For an actual smoke test, run it against the bundled sample dataset:
mkdir -p data
unzip -q TWDEF.zip -d data
cd data/TWDEF
mpirun -np 1 ../../uebpar control.dat
cd ../..
```

A real run prints per-time-step progress and ends with `Done! return value: 0`, having (re)written
`SWE.nc`, `SWIT.nc`, `SWISM.nc`, and `aggout.nc` in `data/TWDEF/`. See "Running with Test Data" in
`ueb-vscode-setup.md` for how to compare against the bundled reference output.

### 5. Try Debugging
1. Set a breakpoint by clicking in the left margin of `main.cpp`
2. Press `F5` to start debugging
3. Select "Debug UEB MPI (macOS lldb)"

---

## 📚 Project Overview

### What is UEB?
The Utah Energy Balance (UEB) is a C++ snowmelt model that calculates energy and water balance in snowpack. It uses:
- Physical calculations for heat exchanges
- NetCDF file I/O for climate data
- MPI for parallel processing across grid cells
- Optional GPU/CUDA acceleration

### Project Variants:
1. **MPI/CPU Version** (Ready to build ✓)
   - Files: `main.cpp`, `canopy.cpp`, `snowdgtv.cpp`, etc.
   - Target: `uebpar`
   - Makefile: `makefile`

2. **GPU/CUDA Version** (Requires NVIDIA GPU + CUDA)
   - Files: `gpumain.cpp`, `gpucanopy.cpp`, etc.
   - Target: `uebgpu`
   - Makefile: `uebGpuMake`

### Key Files:
- `main.cpp` - Main entry point with MPI initialization
- `uebpgdecls.h` - Function declarations and includes
- `ncfunctions.cpp` - NetCDF I/O operations
- `snowdgtv.cpp` - Snow model differential equations
- `canopy.cpp` - Vegetation canopy calculations
- `makefile` - Build configuration (now updated for your system)

---

## 🔍 Useful VSCode Keyboard Shortcuts

### Building & Running:
- `Cmd+Shift+B` - Build (run build task)
- `F5` - Start debugging
- `Ctrl+C` in terminal - Stop running program

### Debugging:
- `F9` - Toggle breakpoint
- `F5` - Continue
- `F10` - Step over
- `F11` - Step into
- `Shift+F11` - Step out
- `Cmd+K, Cmd+I` - Show hover information

### Navigation:
- `Cmd+P` - Quick file open
- `Cmd+Shift+O` - Go to symbol in file
- `Cmd+T` - Go to symbol in workspace
- `Cmd+Click` - Go to definition
- `Cmd+K F12` - Open definition to the side

### Search:
- `Cmd+F` - Find in current file
- `Cmd+Shift+F` - Find in all files
- `Cmd+H` - Replace in current file
- `Cmd+Shift+H` - Replace in all files

### Terminal:
- `` Ctrl+` `` - Toggle integrated terminal
- `Cmd+Shift+` - Create new terminal
- `Cmd+\` - Split terminal

---

## 🐛 Common Issues & Quick Fixes

### Issue: IntelliSense shows errors but code compiles
**Fix:** 
1. Make sure "Mac Homebrew" configuration is selected (bottom-right status bar)
2. Run: `Cmd+Shift+P` → "C/C++: Reset IntelliSense Database"
3. Reload window: `Cmd+Shift+P` → "Developer: Reload Window"

### Issue: `fatal error: 'netcdf_par.h' file not found`
**Fix:** This means Step 0 hasn't been done (or didn't finish) — Homebrew's `netcdf.h` exists but
isn't parallel-enabled, and `netcdf_par.h` only ships with a parallel build. Run
`./build-parallel-netcdf.sh` and confirm `~/local/netcdf-parallel/bin/nc-config --has-parallel4`
prints `yes`. See `BUILD-PARALLEL-NETCDF.md` for details.

### Issue: Library not found when running (`dyld: Library not loaded`)
**Fix:** `makefile` links `uebpar` with an rpath (`-Wl,-rpath,$(NCPREFIX)/lib`) pointing at
`~/local/netcdf-parallel/lib`, so this shouldn't normally happen. If it does, confirm the parallel
NetCDF/HDF5 build (Step 0) actually completed, then rebuild: `make clean && make`.

### Issue: Build fails with linker errors
**Fix:** Make sure makefile has correct paths (already updated for you):
```bash
grep -E "^NCPREFIX|^LIBDIRS|^INCDIRS" makefile
# Should show:
# NCPREFIX = $(HOME)/local/netcdf-parallel
# LIBDIRS = -L$(NCPREFIX)/lib -L/opt/homebrew/lib -L/usr/local/lib
# INCDIRS = -I$(NCPREFIX)/include -I/opt/homebrew/include -I/usr/local/include
```

---

## 📖 Documentation Reference

For detailed information, see:
- **`ueb-vscode-setup.md`** - Complete setup guide, including the Dev Container option and
  test-data workflow
- **`.devcontainer/`** - Docker/Dev Container setup (skips everything in this doc entirely)
- **`BUILD-PARALLEL-NETCDF.md`** - Parallel NetCDF/HDF5 build (required, see Step 0 above)
- **`README.md`** - Project README
- **`compile parallel netcdf_mpich.txt`** - Older, manual dependency build instructions

---

## 🎓 Learning Resources

### C++ & MPI:
- MPI Tutorial: https://mpitutorial.com/
- C++ Reference: https://en.cppreference.com/

### NetCDF:
- NetCDF Documentation: https://www.unidata.ucar.edu/software/netcdf/docs/

### VSCode:
- C++ in VSCode: https://code.visualstudio.com/docs/languages/cpp
- Debugging Guide: https://code.visualstudio.com/docs/editor/debugging

### UEB:
- Original Fortran version: https://github.com/dtarb/UEBFortran
- Author: David Tarboton (dtarb@usu.edu)

---

## 💡 Tips for Getting Started

1. **Start Simple**: Try building and running with 1 process first
   ```bash
   make
   ./uebpar
   ```

2. **Explore the Code**: Open `main.cpp` and use `Cmd+Click` to navigate to function definitions

3. **Use IntelliSense**: Type `Ctrl+Space` to see available functions and parameters

4. **Set Breakpoints**: Click in the left margin to add breakpoints, then press `F5`

5. **Check Build Output**: Watch the Terminal pane when building to see compilation progress

6. **Use Git Integration**: VSCode has built-in Git support (Source Control panel on left sidebar)

---

## ✅ Summary Checklist

- [x] Documentation created (`ueb-vscode-setup.md`)
- [x] VSCode configuration files created (`.vscode/` directory)
- [x] Makefile updated for Homebrew + parallel-NetCDF paths (`NCPREFIX`)
- [x] Base dependencies verified (compiler, MPI, curl, zlib all installed ✓)
- [ ] Parallel NetCDF/HDF5 built (`./build-parallel-netcdf.sh`) - **not done automatically, see Step 0**

### Your Action Items:
- [ ] Run `./build-parallel-netcdf.sh` and confirm `nc-config --has-parallel4` says `yes`
- [ ] Open project in VSCode
- [ ] Install recommended extensions
- [ ] Select "Mac Homebrew" configuration
- [ ] Build project (`Cmd+Shift+B`)
- [ ] Extract test data (`mkdir -p data && unzip -q TWDEF.zip -d data`) and run:
      `cd data/TWDEF && mpirun -np 1 ../../uebpar control.dat`
- [ ] Try debugging (`F5`)

---

## 🎉 You're All Set! (Once Step 0 Is Done)

Your VSCode environment is fully configured. The one step that isn't automatic is building
parallel-enabled NetCDF/HDF5 (Step 0 above) — without it, `make` fails at `ncfunctions.cpp` with
`fatal error: 'netcdf_par.h' file not found`. Once that's built, the project builds and runs cleanly.

**To get started:**
1. Run `./build-parallel-netcdf.sh` (once, ~15-50 min)
2. Open VSCode in this directory
3. Press `Cmd+Shift+B` to build
4. Press `F5` to debug

Happy coding! 🚀

---

*For questions about UEB, contact: David Tarboton (dtarb@usu.edu)*  
*For VSCode or build issues, refer to `ueb-vscode-setup.md`*
