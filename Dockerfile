FROM ubuntu:18.04

ARG NGSOLVE_VERSION
# if it's not repeated it's only usable in FROM
ARG PYVER

RUN apt-get update && \
    apt-get -y install libxmu-dev tk-dev tcl-dev cmake git g++ \
    libglu1-mesa-dev ccache openssh-client openmpi-bin libopenmpi-dev \
    python3 libpython3-dev python3-pytest python3-numpy python3-sphinx python3-pip \
    liboce-ocaf-dev libsuitesparse-dev python3-tk  libicu-dev && \
    pip3 install sphinx_rtd_theme && \
    python3 -m pip install git+https://github.com/sizmailov/pybind11-stubgen.git
ENV PATH="/opt/netgen/bin:${PATH}" \
    NGSOLVE_SRC_DIR=/root/src/ngsolve_src \
    NGSOLVE_BUILD_DIR=/root/src/ngsolve_build \
    NGSXFEM_SRC_DIR=/root/src/ngsxfem_src \
    NGSXFEM_BUILD_DIR=/root/src/ngsxfem_build \
    PETSC_DIR=/usr/local/petsc-32
ENV MUMPS_DIR=${PETSC_DIR}

COPY --from=petsclayer ${PETSC_DIR} ${PETSC_DIR}

ADD catch.hpp /usr/local/include/
# fake lsb-release to get ngsolve cmake to configure for deb package building
RUN echo "DISTRIB_CODENAME=buster" > /etc/lsb-release && \
    git clone https://github.com/NGSolve/ngsolve.git ${NGSOLVE_SRC_DIR} && \
    cd ${NGSOLVE_SRC_DIR} && \
    git checkout v6.2.1906 && \
    cd ${NGSOLVE_SRC_DIR}  && \
    git submodule update --init --recursive && \
    mkdir -p ${NGSOLVE_BUILD_DIR} && \
    cd ${NGSOLVE_BUILD_DIR} && \
    cmake ${NGSOLVE_SRC_DIR} \
    -DUSE_NATIVE_ARCH=OFF \
    -DUSE_OCC=ON \
    -DUSE_MPI=ON \
     -DMKL_STATIC=OFF\
      -DMKL_SDL=OFF \
     -DUSE_HYPRE=OFF\
     -DMKL_MULTI_THREADED=OFF \
     -DUSE_GUI=OFF \
    -DUSE_MUMPS=OFF \
    -DOpenGL_GL_PREFERENCE=GLVND \
    -DUSE_CCACHE=OFF \
    -DUSE_MKL=OFF \
    -DUSE_UMFPACK=ON \
    -DINSTALL_PROFILES=OFF \
    -DENABLE_UNIT_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DNG_INSTALL_DIR_LIB=lib/netgen \
    -DNG_INSTALL_DIR_INCLUDE=include/netgen \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCMAKE_CXX_FLAGS="-Wenum-compare" \
    -DCPACK_PACKAGING_INSTALL_PREFIX=/usr \
    "-DCPACK_DEBIAN_PACKAGE_NAME=ngsolve${PACKAGE_NAME_SUFFIX}" && \
    make -j "$(nproc)" && \
    cd ${NGSOLVE_BUILD_DIR} && \
    make package && \
    mv ${NGSOLVE_BUILD_DIR}/ngsolve-*_amd64.deb /root/ && \
    rm -rf ${NGSOLVE_BUILD_DIR}

RUN git clone https://github.com/ngsxfem/ngsxfem.git ${NGSXFEM_SRC_DIR} && \
    cd ${NGSXFEM_SRC_DIR} && \
    git checkout ${NGSXFEM_VERSION} && \
    cd ${NGSXFEM_SRC_DIR}  && \
    git submodule update --init --recursive && \
    mkdir -p ${NGSXFEM_BUILD_DIR} && \
    cd ${NGSXFEM_BUILD_DIR} && \
    cmake ${NGSXFEM_SRC_DIR} \
    -DCMAKE_CXX_COMPILER=ngscxx -DCMAKE_LINKER=ngsld \
    -DNG_INSTALL_DIR_LIB=lib/netgen \
    -DNG_INSTALL_DIR_INCLUDE=include/netgen \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DCPACK_PACKAGING_INSTALL_PREFIX=/usr \
    "-DCPACK_DEBIAN_PACKAGE_NAME=ngsxfem${PACKAGE_NAME_SUFFIX}" && \
    make -j "$(nproc)" && \
    cd ${NGSXFEM_BUILD_DIR} && \
    make package && \
    mv ${NGSXFEM_BUILD_DIR}/ngsxfem-*_amd64.deb /root/ && \
    rm -rf ${NGSXFEM_BUILD_DIR}


   
