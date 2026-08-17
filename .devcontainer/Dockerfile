FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Base toolchain + UEB's runtime/link dependencies -----------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        gdb \
        make \
        cmake \
        git \
        wget \
        curl \
        unzip \
        ca-certificates \
        mpich \
        libmpich-dev \
        libcurl4-openssl-dev \
        m4 \
        pkg-config \
        python3 \
        python3-pip \
        sudo \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir netCDF4

# --- Parallel-enabled HDF5 + NetCDF-C, built from source --------------------
# Ubuntu's own libnetcdf-dev/libhdf5-dev packages are not reliably parallel-enabled,
# and UEB's ncfunctions.cpp requires netcdf_par.h / nc_open_par / nc_create_par /
# nc_var_par_access, so this reuses the exact same from-source build documented in
# BUILD-PARALLEL-NETCDF.md for native macOS/Linux setups. Built to a fixed path (not
# tied to $HOME) so it works the same regardless of which user later runs `make`.
COPY build-parallel-netcdf.sh /tmp/build-parallel-netcdf.sh
RUN chmod +x /tmp/build-parallel-netcdf.sh \
    && /tmp/build-parallel-netcdf.sh /opt/netcdf-parallel \
    && rm -rf /root/src/netcdf-build /tmp/build-parallel-netcdf.sh \
    && chmod -R a+rX /opt/netcdf-parallel

# Picked up by makefile's `NCPREFIX ?= ...` so `make` needs no changes in the container.
ENV NCPREFIX=/opt/netcdf-parallel

# --- Non-root user (keeps bind-mounted repo files owned by you, not root) ---
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
