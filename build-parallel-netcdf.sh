#!/bin/bash
#
# Build Parallel NetCDF Stack for UEB
# 
# This script builds zlib, curl, HDF5, and NetCDF-C with parallel support
# Required for UEB's parallel I/O operations
#
# Usage: ./build-parallel-netcdf.sh [install_prefix]
#
# Default install location: $HOME/local/netcdf-parallel
#

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
if [ -z "$1" ]; then
    INSTALL_PREFIX=$HOME/local/netcdf-parallel
else
    INSTALL_PREFIX=$1
fi

BUILD_DIR=$HOME/src/netcdf-build
NPROC=$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)

# Versions
ZLIB_VERSION=1.3.1
CURL_VERSION=8.5.0
HDF5_VERSION=1.14.3
NETCDF_VERSION=4.9.2
PNETCDF_VERSION=1.12.3

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Building Parallel NetCDF Stack for UEB${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Install prefix: $INSTALL_PREFIX"
echo "Build directory: $BUILD_DIR"
echo "Parallel jobs: $NPROC"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v mpicc &> /dev/null; then
    echo -e "${RED}ERROR: mpicc not found. Please install MPI first.${NC}"
    echo "  macOS: brew install mpich"
    echo "  Linux: sudo apt install mpich libmpich-dev"
    exit 1
fi

if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo -e "${RED}ERROR: wget or curl required for downloading.${NC}"
    echo "  macOS: brew install wget"
    echo "  Linux: sudo apt install wget"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}"
echo ""

# Set up environment
export CC=mpicc
export CXX=mpicxx
export FC=mpifort
export PATH=$INSTALL_PREFIX/bin:$PATH

# Detect OS for library path
if [[ "$OSTYPE" == "darwin"* ]]; then
    export DYLD_LIBRARY_PATH=$INSTALL_PREFIX/lib:$DYLD_LIBRARY_PATH
    LIB_PATH_VAR="DYLD_LIBRARY_PATH"
else
    export LD_LIBRARY_PATH=$INSTALL_PREFIX/lib:$LD_LIBRARY_PATH
    LIB_PATH_VAR="LD_LIBRARY_PATH"
fi

export LDFLAGS="-L$INSTALL_PREFIX/lib"
export CPPFLAGS="-I$INSTALL_PREFIX/include"

# Create directories
mkdir -p $INSTALL_PREFIX
mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Download helper function
download_file() {
    local url=$1
    local filename=$(basename $url)
    
    if [ -f "$filename" ]; then
        echo "  ✓ Already downloaded: $filename"
        return 0
    fi
    
    echo "  Downloading: $filename"
    if command -v wget &> /dev/null; then
        wget -q --show-progress $url
    else
        curl -f -L -O $url
    fi
}

# Build zlib
echo -e "${YELLOW}[1/3] Building zlib ${ZLIB_VERSION}...${NC}"
if [ -f "$INSTALL_PREFIX/lib/libz.a" ]; then
    echo -e "  ${GREEN}✓ zlib already installed${NC}"
else
    download_file https://zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz
    tar -xzf zlib-${ZLIB_VERSION}.tar.gz
    cd zlib-${ZLIB_VERSION}
    ./configure --prefix=$INSTALL_PREFIX
    make -j$NPROC
    make install
    cd ..
    echo -e "  ${GREEN}✓ zlib installed${NC}"
fi
echo ""

# curl is intentionally not built here: HDF5 doesn't link it, and NetCDF-C is
# configured below with --disable-dap so it doesn't need it either. The final
# UEB link step can use the curl already provided by Homebrew.

# Build HDF5
echo -e "${YELLOW}[2/3] Building HDF5 ${HDF5_VERSION} with parallel support...${NC}"
if [ -f "$INSTALL_PREFIX/lib/libhdf5.a" ]; then
    echo -e "  ${GREEN}✓ HDF5 already installed${NC}"
else
    HDF5_MAJOR=$(echo $HDF5_VERSION | cut -d. -f1-2)
    download_file https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_MAJOR}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz
    tar -xzf hdf5-${HDF5_VERSION}.tar.gz
    cd hdf5-${HDF5_VERSION}
    CC=mpicc ./configure \
        --prefix=$INSTALL_PREFIX \
        --enable-parallel \
        --enable-shared \
        --with-zlib=$INSTALL_PREFIX
    make -j$NPROC
    make install
    cd ..
    echo -e "  ${GREEN}✓ HDF5 installed${NC}"
fi
echo ""

# Build NetCDF-C
echo -e "${YELLOW}[3/3] Building NetCDF-C ${NETCDF_VERSION} with parallel support...${NC}"
if [ -f "$INSTALL_PREFIX/lib/libnetcdf.a" ]; then
    echo -e "  ${GREEN}✓ NetCDF-C already installed${NC}"
else
    download_file https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_VERSION}/netcdf-c-${NETCDF_VERSION}.tar.gz
    tar -xzf netcdf-c-${NETCDF_VERSION}.tar.gz
    cd netcdf-c-${NETCDF_VERSION}
    CC=mpicc CPPFLAGS="-I$INSTALL_PREFIX/include" LDFLAGS="-L$INSTALL_PREFIX/lib" \
        ./configure \
        --prefix=$INSTALL_PREFIX \
        --enable-parallel-tests \
        --enable-shared \
        --disable-dap \
        --disable-libxml2
    make -j$NPROC
    make install
    cd ..
    echo -e "  ${GREEN}✓ NetCDF-C installed${NC}"
fi
echo ""

# Verify installation
echo -e "${YELLOW}Verifying installation...${NC}"

if [ ! -f "$INSTALL_PREFIX/bin/nc-config" ]; then
    echo -e "${RED}ERROR: nc-config not found${NC}"
    exit 1
fi

NC_PARALLEL=$($INSTALL_PREFIX/bin/nc-config --has-parallel)
NC_HDF5=$($INSTALL_PREFIX/bin/nc-config --has-hdf5)

if [ "$NC_PARALLEL" != "yes" ]; then
    echo -e "${RED}ERROR: NetCDF does not have parallel support!${NC}"
    exit 1
fi

if [ "$NC_HDF5" != "yes" ]; then
    echo -e "${RED}WARNING: NetCDF does not have HDF5 support${NC}"
fi

echo -e "${GREEN}✓ NetCDF parallel support: $NC_PARALLEL${NC}"
echo -e "${GREEN}✓ NetCDF HDF5 support: $NC_HDF5${NC}"
echo ""

# Create environment setup script
ENV_SCRIPT="$INSTALL_PREFIX/env-setup.sh"
cat > $ENV_SCRIPT << EOF
#!/bin/bash
# Environment setup for parallel NetCDF
# Source this file: source $ENV_SCRIPT

export INSTALL_PREFIX=$INSTALL_PREFIX
export PATH=\$INSTALL_PREFIX/bin:\$PATH
export $LIB_PATH_VAR=\$INSTALL_PREFIX/lib:\$$LIB_PATH_VAR
export LDFLAGS="-L\$INSTALL_PREFIX/lib"
export CPPFLAGS="-I\$INSTALL_PREFIX/include"
export CC=mpicc
export CXX=mpicxx
export FC=mpifort

echo "Parallel NetCDF environment configured:"
echo "  Install prefix: \$INSTALL_PREFIX"
echo "  nc-config: \$(which nc-config)"
echo "  Parallel support: \$(nc-config --has-parallel)"
EOF

chmod +x $ENV_SCRIPT

# Success message
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✓ Build Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Installation location: $INSTALL_PREFIX"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "1. Add to your shell configuration (~/.zshrc or ~/.bashrc):"
echo ""
echo "   export INSTALL_PREFIX=$INSTALL_PREFIX"
echo "   export PATH=\$INSTALL_PREFIX/bin:\$PATH"
echo "   export $LIB_PATH_VAR=\$INSTALL_PREFIX/lib:\$$LIB_PATH_VAR"
echo ""
echo "2. Or source the environment setup script:"
echo ""
echo "   source $ENV_SCRIPT"
echo ""
echo "3. Rebuild UEB (the makefile's NCPREFIX already defaults to $HOME/local/netcdf-parallel;"
echo "   pass NCPREFIX=$INSTALL_PREFIX explicitly if you installed elsewhere):"
echo ""
echo "   cd /path/to/UEB"
echo "   make clean"
echo "   make NCPREFIX=$INSTALL_PREFIX"
echo ""
echo "For more information, see: BUILD-PARALLEL-NETCDF.md"
echo ""
