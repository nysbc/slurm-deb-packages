ARG BASE_IMAGE=debian:bullseye
FROM $BASE_IMAGE
ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
ARG LIBJWT_PKG=libjwt0
RUN apt-get update && \
    apt-get install -y \
        git  \
        build-essential \
        devscripts \
        debhelper \
        fakeroot \
        wget \
        curl \
        equivs \
        autoconf \
        pkg-config \
        libssl-dev \
        libpam0g-dev \
        libtool \
        libjansson-dev \
        libjson-c-dev \
        munge \
        libmunge-dev \
        ${LIBJWT_PKG} \
        libjwt-dev \
        libhwloc-dev \
        liblz4-dev \
        flex \
        libevent-dev \
        jq \
        squashfs-tools \
        zstd \
        zlib1g \
        zlib1g-dev \
        libpmix2 \
        libpmix-dev

# Install Openmpi
ARG OPENMPI_VERSION=1.13
RUN apt-get update && \
    apt-get install -y mpi-default-bin=${OPENMPI_VERSION} mpi-default-dev=${OPENMPI_VERSION}

# Download Slurm
ARG SLURM_VERSION=23.11.11
ARG GITHUB_ORG=SchedMD
ARG GITHUB_REPO=slurm
ARG GIT_BRANCH=slurm-25-05-2-1
ADD "https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/commits?per_page=1&sha=${GIT_BRANCH}" latest_commit
RUN cd /usr/src && \
    git clone -b ${GIT_BRANCH}  https://github.com/${GITHUB_ORG}/${GITHUB_REPO}.git slurm-${SLURM_VERSION}


#ENV PATH=$PATH:/usr/mpi/gcc/openmpi-${OPENMPI_VERSION}/bin

# Build deb packages for Slurm
RUN cd /usr/src/slurm-${SLURM_VERSION} && \
    ARCH=$(uname -m) && \
#    sed -i "s|--with-pmix\b|--with-pmix=/usr/lib/${ARCH}-linux-gnu/pmix2|" debian/rules && \
    mk-build-deps -i debian/control -t "apt-get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" && \
    debuild -b -uc -us

################################################################
# RESULT
################################################################
# /usr/src/slurm-smd-client_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-dev_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-doc_24.05.02-1_all.deb
# /usr/src/slurm-smd-libnss-slurm_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-libpam-slurm-adopt_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-libpmi0_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-libpmi2-0_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-libslurm-perl_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-openlava_24.05.02-1_all.deb
# /usr/src/slurm-smd-sackd_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-slurmctld_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-slurmd_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-slurmdbd_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-slurmrestd_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-sview_24.05.02-1_amd64.deb
# /usr/src/slurm-smd-torque_24.05.02-1_all.deb
# /usr/src/slurm-smd_24.05.02-1_amd64.deb
################################################################

# Move deb files
RUN mkdir /usr/src/debs && \
    mv /usr/src/*.deb /usr/src/debs/
