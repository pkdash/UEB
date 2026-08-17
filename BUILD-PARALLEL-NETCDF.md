# Building Parallel NetCDF for UEB

## Why this is needed

UEB uses parallel NetCDF I/O (`#include <netcdf_par.h>`, `nc_open_par()`, MPI-based collective
reads/writes for its distributed grid computation). Standard package-manager NetCDF builds
(including Homebrew's) don't include parallel support, so it has to be built from source.

## Prerequisites

- A C/C++ compiler and an MPI implementation (MPICH or OpenMPI) providing `mpicc`/`mpicxx`
- `make`, `wget` or `curl`

```bash
# macOS
xcode-select --install
brew install mpich wget

# Ubuntu/Debian
sudo apt install -y build-essential wget mpich libmpich-dev
```

## Build it

Run the build script from the project root. It builds zlib, HDF5 (with `--enable-parallel`), and
NetCDF-C (with parallel support) in order, skipping any step whose output already exists:

```bash
./build-parallel-netcdf.sh [install_prefix]   # defaults to $HOME/local/netcdf-parallel
```

It finishes by checking `nc-config --has-parallel` / `--has-hdf5` and writing
`<install_prefix>/env-setup.sh` (sets `PATH`, `LDFLAGS`, `CPPFLAGS`, and `CC`/`CXX`/`FC` for that
install — source it if you want to use these tools directly, e.g. `nc-config`, outside the makefile).

## Point the makefile at it

The `makefile`'s `NCPREFIX` variable already defaults to `$(HOME)/local/netcdf-parallel` — the
script's default install location — so if you built with defaults, `make` picks it up automatically.
If you installed elsewhere, override it:

```bash
make NCPREFIX=/path/to/your/netcdf-parallel
```

Then rebuild:
```bash
make clean && make
```

## Troubleshooting

### `nc-config --has-parallel` returns "no"

NetCDF wasn't configured with parallel support. Delete the extracted `netcdf-c-*` build directory
under `$HOME/src/netcdf-build` and re-run `build-parallel-netcdf.sh` so it reconfigures from scratch.

### `netcdf_par.h: No such file`

Include path isn't reaching the compiler. Confirm `ls $NCPREFIX/include/netcdf_par.h` exists, and
that `make` is picking up the right `NCPREFIX` (see above).

### HDF5 configure fails with "C compiler cannot create executables"

`mpicc` isn't on `PATH`. Run `which mpicc`; on Apple Silicon Homebrew you may need
`export PATH="/opt/homebrew/bin:$PATH"` first.

### "symbol not found" / "library not loaded" at runtime

The makefile links the parallel NetCDF lib with `-Wl,-rpath,$(NCPREFIX)/lib`, so a normal `make`
build shouldn't need `DYLD_LIBRARY_PATH`/`LD_LIBRARY_PATH` set. If you're running a binary built
before that rpath flag was added, rebuild with `make clean && make`, or set the library path env var
manually as a workaround.

### Build is slow

`build-parallel-netcdf.sh` already parallelizes each library's `make` step using all detected cores.

## Resources

- [NetCDF documentation](https://docs.unidata.ucar.edu/nug/current/)
- [HDF5 parallel documentation](https://portal.hdfgroup.org/documentation/)
