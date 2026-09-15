cmake_minimum_required(VERSION 3.15)
project(UEB C CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Export compile commands for VSCode IntelliSense
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Parallel NetCDF/HDF5 built from source (devcontainer: /opt/netcdf-parallel).
# The Dockerfile sets NCPREFIX; use it to locate the from-source install which
# only ships a pkg-config file (no netCDFConfig.cmake / FindnetCDF.cmake).
set(UEB_USE_SOURCE_NETCDF FALSE)
if(UNIX AND DEFINED ENV{NCPREFIX})
    set(UEB_USE_SOURCE_NETCDF TRUE)
    set(NCPREFIX $ENV{NCPREFIX})
    list(APPEND CMAKE_PREFIX_PATH ${NCPREFIX})
    set(ENV{PKG_CONFIG_PATH} "${NCPREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")
    set(HDF5_ROOT ${NCPREFIX})
    set(ZLIB_ROOT ${NCPREFIX})
    message(STATUS "Using NCPREFIX: ${NCPREFIX}")
endif()

# Find MPI
find_package(MPI REQUIRED)
include_directories(${MPI_CXX_INCLUDE_DIRS})

# Find NetCDF
# vcpkg provides netCDF with CONFIG mode
find_package(netCDF CONFIG QUIET)
if(NOT netCDF_FOUND)
    # Fallback to pkg-config (used by the from-source parallel build)
    if(UEB_USE_SOURCE_NETCDF)
        find_package(PkgConfig QUIET)
        if(PkgConfig_FOUND)
            pkg_check_modules(netCDF netcdf)
        endif()
    endif()
    if(NOT netCDF_FOUND)
        # Last resort: manual installation with a FindnetCDF.cmake module
        find_package(netCDF REQUIRED)
    endif()
endif()

# Find HDF5
find_package(HDF5 REQUIRED COMPONENTS C HL)
include_directories(${HDF5_INCLUDE_DIRS})

# Find CURL
find_package(CURL REQUIRED)

# Find ZLIB
find_package(ZLIB REQUIRED)

# Detect Windows and choose appropriate NetCDF functions file
if(WIN32)
    set(NCFUNCTIONS_SRC ncfunctions_mswin.cpp)
    message(STATUS "Using Windows NetCDF functions: ${NCFUNCTIONS_SRC}")
else()
    set(NCFUNCTIONS_SRC ncfunctions.cpp)
    message(STATUS "Using Unix NetCDF functions: ${NCFUNCTIONS_SRC}")
endif()

# Source files for MPI version
set(UEB_SOURCES
    main.cpp
    canopy.cpp
    matrixnvector.cpp
    ${NCFUNCTIONS_SRC}
    snowdgtv.cpp
    snowdv.cpp
    snowxv.cpp
    uebdecls.cpp
    uebinputs.cpp
)

# Create executable
add_executable(uebpar ${UEB_SOURCES})

# Include directories
target_include_directories(uebpar PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${MPI_CXX_INCLUDE_DIRS}
)

# Link libraries
target_link_libraries(uebpar
    PRIVATE
    MPI::MPI_CXX
    ${HDF5_LIBRARIES}
    ${HDF5_HL_LIBRARIES}
    CURL::libcurl
    ZLIB::ZLIB
)

# Handle NetCDF linking based on how it was found
if(TARGET netCDF::netcdf)
    target_link_libraries(uebpar PRIVATE netCDF::netcdf)
else()
    target_link_libraries(uebpar PRIVATE ${netCDF_LIBRARIES})
    target_include_directories(uebpar PRIVATE ${netCDF_INCLUDE_DIRS})
    # pkg-config path: add library search dirs (e.g. /opt/netcdf-parallel/lib)
    if(netCDF_LIBRARY_DIRS)
        target_link_directories(uebpar PRIVATE ${netCDF_LIBRARY_DIRS})
    endif()
endif()

# Compiler definitions
if(MSVC)
    target_compile_definitions(uebpar PRIVATE
        _CRT_SECURE_NO_WARNINGS
        NOMINMAX
        _USE_MATH_DEFINES
    )
    # Disable specific MSVC warnings
    target_compile_options(uebpar PRIVATE /wd4996)
else()
    target_compile_options(uebpar PRIVATE -Wall)
endif()

# Add math library on Unix
if(UNIX)
    target_link_libraries(uebpar PRIVATE m dl)
endif()

# Option to build GPU version
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

    target_include_directories(uebgpu PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${MPI_CXX_INCLUDE_DIRS}
        ${CUDA_INCLUDE_DIRS}
    )

    target_link_libraries(uebgpu
        PRIVATE
        MPI::MPI_CXX
        ${HDF5_LIBRARIES}
        ${HDF5_HL_LIBRARIES}
        CURL::libcurl
        ZLIB::ZLIB
        ${CUDA_LIBRARIES}
        cudart
    )

    if(TARGET netCDF::netcdf)
        target_link_libraries(uebgpu PRIVATE netCDF::netcdf)
    else()
        target_link_libraries(uebgpu PRIVATE ${netCDF_LIBRARIES})
        target_include_directories(uebgpu PRIVATE ${netCDF_INCLUDE_DIRS})
    endif()

    # CUDA architecture
    set_target_properties(uebgpu PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
        CUDA_ARCHITECTURES "52;61;75;86"
    )

    if(MSVC)
        target_compile_definitions(uebgpu PRIVATE
            _CRT_SECURE_NO_WARNINGS
            NOMINMAX
            _USE_MATH_DEFINES
        )
    endif()
endif()

# Installation
install(TARGETS uebpar
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

if(BUILD_GPU_VERSION)
    install(TARGETS uebgpu
        RUNTIME DESTINATION bin
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
    )
endif()

# Print configuration summary
message(STATUS "")
message(STATUS "UEB Configuration Summary")
message(STATUS "=========================")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "MPI Include: ${MPI_CXX_INCLUDE_DIRS}")
message(STATUS "HDF5 Include: ${HDF5_INCLUDE_DIRS}")
message(STATUS "Build GPU version: ${BUILD_GPU_VERSION}")
message(STATUS "")
