CXX = g++
MPICXX = mpicxx 
CUDAXX = nvcc 
CUDAFLAGS = -x cu -arch=sm_20 -dc -lineinfo
CUDALFLAGS = -arch=sm_20 
CXXFLAGS = -std=c++0x -g -Wall 
#--compiler-options -Wall
LINKFLAGS = -std=c++0x -g
# Parallel-enabled NetCDF/HDF5 built from source per BUILD-PARALLEL-NETCDF.md - required
# for UEB's nc_open_par/nc_create_par/nc_var_par_access calls; Homebrew's netcdf/hdf5 are
# not built with parallel support. Listed first so its headers/libs win over Homebrew's.
# `?=` lets the devcontainer image override this via an NCPREFIX env var instead of
# depending on $(HOME), which may not match the user that later runs `make`.
NCPREFIX ?= $(HOME)/local/netcdf-parallel
# Library and include paths - updated for Homebrew on macOS
LIBDIRS = -L$(NCPREFIX)/lib -L/opt/homebrew/lib -L/usr/local/lib
LDFLAGS = -lnetcdf -lhdf5_hl -lhdf5 -lcurl -lm -lz -ldl -Wl,-rpath,$(NCPREFIX)/lib
#LDFLAGS = -lpnetcdf -lnetcdf -lhdf5_hl -lhdf5 -lm -lz -ldl -lmpi -lmpicxx
INCDIRS = -I$(NCPREFIX)/include -I/opt/homebrew/include -I/usr/local/include
TARGET = uebpar
CXX_SRCS = main.cpp canopy.cpp matrixnvector.cpp ncfunctions.cpp snowdgtv.cpp snowdv.cpp snowxv.cpp uebdecls.cpp uebinputs.cpp
OBJS = $(CXX_SRCS:.cpp=.o)

$(TARGET) : $(OBJS)
	$(MPICXX) $(LINKFLAGS) -o $@ $^ $(LIBDIRS) $(LDFLAGS)
#$(CUDAXX) $(CUDALFLAGS) $(LINKFLAGS) -o $@ $^ $(LIBDIRS) $(LDFLAGS)

%.o : %.cpp
	$(MPICXX) $(CXXFLAGS) $(INCDIRS) -c $<

clean :
	$(RM) $(OBJS) $(TARGET)
