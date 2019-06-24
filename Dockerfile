# Dockerfile
#
# Dev Docker Env for STM32MP1
# STM32MP1 Developer Package SDK - STM32MP15-Ecosystem-v1.0.0 release
# Thanks to https://github.com/gmacario/easy-build
# Thanks to https://github.com/tecnickcom/alldev
#
# @author      Jean Diaconu <jean.diaconu@gmail.com>
# ------------------------------------------------------------------------------

FROM phusion/baseimage:master
MAINTAINER jean.diaconu@gmail.com

ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux
ENV HOME /home/dev
ENV DISPLAY :0
WORKDIR /home/dev

# Add i386 architecture
RUN dpkg --add-architecture i386 \
	# Add repositories and update
	&& apt-get update && apt-get -y dist-upgrade \
	&& apt-get install -y apt-utils software-properties-common \
	&& apt-add-repository universe \
	&& apt-add-repository multiverse \
	&& apt-get update 

# Upgrade & Update
RUN apt-get update && apt-get -y upgrade

# Required Packages for Yocto
# Additional host packages required by poky/scripts/wic
# Additional host packages required by TF-A, U-Boot
RUN apt-get install -y apt-utils astyle autoconf automake autotools-dev binfmt-support binutils-mingw-w64 build-essential \
	bzip2 checkinstall chrpath clang clang-format clang-tidy cmake cpio cppcheck curl dblatex debhelper debianutils \
	devscripts dh-make diffstat dnsutils docbook-utils dos2unix dosfstools doxygen doxygen-latex dpkg fastjar flawfinder fop g++ \
	g++-multilib gawk gcc gcc-8 gcc-multilib gdb gettext ghostscript git git-core gitk gridengine-drmaa-dev gtk-sharp2 \
	htop intltool iputils-ping language-pack-en lcov libboost-all-dev libbz2-dev libc6 libc6-dev libc6-dev-i386 \
	libcurl4-openssl-dev libcurlpp-dev libffi-dev libglib2.0-0 libglib2.0-dev libgsl-dev libicu-dev liblapack-dev \
	liblzma-dev libncurses5-dev libncursesw5-dev libsane-extras libsdl1.2-dev libssl-dev libssl1.0.0 libtool \
	libwine-development libxml2 libxml2-dev libxml2-utils libxmlsec1 libxmlsec1-dev libxmlsec1-openssl libxslt1-dev \
	libxslt1.1 live-build llvm-5.0 lsof make mawk mingw-w64 mingw-w64-i686-dev mingw-w64-tools mingw-w64-x86-64-dev \
	mtools nuget openssl parted pass pbuilder pkg-config pyflakes pylint python python-git python3 \
	python3-all python3-all-dev python3-pexpect python3-pip python3-setuptools r-base rpm rsync ruby-all-dev screen \
	socat ssh strace sudo swig syslinux texinfo texlive-base time tmux tree ubuntu-restricted-addons ubuntu-restricted-extras \
	unzip upx-ucl vim virtualenv wget xmldiff xmlindent xmlsec1 xmlto xsltproc xterm xz-utils zbar-tools zip zlib1g zlib1g-dev

# Add "repo" tool (used by many Yocto-based projects)
RUN curl http://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
RUN chmod a+x /usr/local/bin/repo

# Create a non-root user that will perform the actual build
RUN id dev 2>/dev/null || useradd --uid 30000 --create-home dev
RUN apt-get install -y sudo
RUN echo "dev ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers

# Configure default git user
RUN echo "	email = default@example.com" >> /home/dev/.gitconfig \
	&& echo "	name = default" >> /home/dev/.gitconfig 

# Configure simple vim
RUN echo "\
filetype plugin indent on \n\
syntax on \n\
set term=xterm-256color \n\
set backspace=indent,eol,start \n\
set tabstop=4 \n\
set shiftwidth=4 \n\
set softtabstop=4 \n\
set expandtab\
" > /home/dev/.vimrc

# Fix error "Please use a locale setting which supports utf-8."
# See https://wiki.yoctoproject.org/wiki/TipsAndTricks/ResolvingLocaleIssues
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
	echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
	dpkg-reconfigure --frontend=noninteractive locales && \
	update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Create temp dir
RUN mkdir /home/dev/tmp \
	&& chown -R dev:sudo /home/dev

# Switch user
USER dev

# Download STM32MP1 SDK - STM32MP15-Ecosystem-v1.0.0 release
RUN wget https://www.st.com/content/ccc/resource/technical/software/sw_development_suite/group0/32/5e/0d/c9/05/87/40/c0/stm32mp1dev_yocto_sdk/files/SDK-x86_64-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz/jcr:content/translations/en.SDK-x86_64-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz  -P /home/dev/tmp \
	&& tar -xvf /home/dev/tmp/en.SDK-x86_64-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz -C /home/dev/tmp \
	&& chmod +x /home/dev/tmp/stm32mp1-openstlinux-4.19-thud-mp1-19-02-20/sdk/st-image-weston-openstlinux-weston-stm32mp1-x86_64-toolchain-2.6-openstlinux-4.19-thud-mp1-19-02-20.sh

# Download STM32MP1 TF-A - STM32MP15-Ecosystem-v1.0.0 release
RUN wget https://www.st.com/content/ccc/resource/technical/sw-updater/firmware2/group0/26/13/6b/ee/c1/73/4b/03/stm32cube_standard_a7_bsp_components_tf_a/files/SOURCES-tf-a-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz/jcr:content/translations/en.SOURCES-tf-a-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz  -P /home/dev/tmp \
	&& tar -xvf /home/dev/tmp/en.SOURCES-tf-a-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz -C /home/dev/tmp

# Download STM32MP1 U-Boot - STM32MP15-Ecosystem-v1.0.0 release
RUN wget https://www.st.com/content/ccc/resource/technical/sw-updater/firmware2/group0/6c/b7/e5/68/0b/d5/49/13/stm32cube_Standard_A7_BSP_components_u-boot/files/SOURCES-u-boot-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz/jcr:content/translations/en.SOURCES-u-boot-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz  -P /home/dev/tmp \
	&& tar -xvf /home/dev/tmp/en.SOURCES-u-boot-stm32mp1-openstlinux-4.19-thud-mp1-19-02-20.tar.xz -C /home/dev/tmp

# Install STM32MP1 SDK
RUN /bin/bash /home/dev/tmp/stm32mp1-openstlinux-4.19-thud-mp1-19-02-20/sdk/st-image-weston-openstlinux-weston-stm32mp1-x86_64-toolchain-2.6-openstlinux-4.19-thud-mp1-19-02-20.sh -d /home/dev/.stm32mp1-sdk

# Move sources
RUN cp -R /home/dev/tmp/stm32mp1-openstlinux-4.19-thud-mp1-19-02-20/sources /home/dev/src

# Patch TF-A
RUN cd /home/dev/src/arm-openstlinux_weston-linux-gnueabi/tf-a-stm32mp-2.0-r0 \
    && mkdir /home/dev/src/arm-openstlinux_weston-linux-gnueabi/tf-a-stm32mp-2.0-r0/tf-a-stm32mp-src \
    && tar -xvf v2.0.tar.gz -C /home/dev/src/arm-openstlinux_weston-linux-gnueabi/tf-a-stm32mp-2.0-r0/tf-a-stm32mp-src --strip-components=1 \ 
    && rm v2.0.tar.gz \
    && cd tf-a-stm32mp-src \
    && for p in `ls -1 ../*.patch`; do patch -p1 < $p; done 

# Patch U-Boot
RUN cd /home/dev/src/arm-openstlinux_weston-linux-gnueabi/u-boot-stm32mp-2018.11-r0 \
    && mkdir /home/dev/src/arm-openstlinux_weston-linux-gnueabi/u-boot-stm32mp-2018.11-r0/u-boot-stm32mp-src \
    && tar -xvf v2018.11.tar.gz -C /home/dev/src/arm-openstlinux_weston-linux-gnueabi/u-boot-stm32mp-2018.11-r0/u-boot-stm32mp-src --strip-components=1 \
    && rm v2018.11.tar.gz \
    && cd u-boot-stm32mp-src \
    && for p in `ls -1 ../*.patch`; do patch -p1 < $p; done 

# Clean
RUN rm -rvf /home/dev/tmp

# Source the SDK
RUN echo "source /home/dev/.stm32mp1-sdk/environment-setup-cortexa7t2hf-neon-vfpv4-openstlinux_weston-linux-gnueabi" > /home/dev/.bashrc
