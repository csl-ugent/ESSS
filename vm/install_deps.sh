#!/bin/bash

set -euxo pipefail

# The instructions used in the artifact appendix and README assume that the user is called "evaluation" and the home directory is "/home/evaluation".

# Install dependencies
sudo apt update
sudo apt upgrade
sudo apt install -y git
sudo apt install -y build-essential
sudo apt install -y vim
sudo apt install -y gcc-12
sudo apt install -y docker.io
sudo apt install -y cmake
sudo apt install -y libboost-dev
sudo apt install -y libboost-program-options-dev
sudo apt install -y python3-pip
sudo apt install -y libgoogle-glog-dev libunwind-dev
sudo apt install -y --no-install-recommends clang
sudo apt install -y llvm-dev
sudo apt install -y libstdc++-12-dev
sudo apt install -y autoconf
sudo apt install -y libtool
sudo apt install -y libpng-dev
sudo apt install -y pkg-config
sudo apt install -y re2c flex bison
sudo apt install -y libxml2-dev libxslt-dev
sudo apt install -y libkrb5-dev
sudo apt install -y libssl-dev
sudo apt install -y libsqlite3-dev
sudo apt install -y libbz2-dev
sudo apt install -y libcurl4-openssl-dev
sudo apt install -y libqdbm-dev
sudo apt install -y libgdbm-dev
sudo apt install -y libenchant-2-dev
sudo apt install -y libgmp-dev
sudo apt install -y libc-client2007e-dev
sudo apt install -y libldap2-dev
sudo apt install -y libsasl2-dev
sudo apt install -y libldb-dev libldap2-dev
sudo apt install -y libonig-dev
sudo apt install -y unixodbc-dev
sudo apt install -y freetds-dev
sudo apt install -y libpq-dev
sudo apt install -y libreadline-dev
sudo apt install -y libsnmp-dev
sudo apt install -y libsodium-dev
sudo apt install -y libargon2-dev
sudo apt install -y libtidy-dev
sudo apt install -y libzip-dev
sudo apt install -y lua5.1
sudo apt install -y liblua5.1-dev
sudo apt install -y libjansson-dev
sudo apt install -y libreoffice-calc --no-install-recommends

sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

touch .ready
read -n1 -r -p "System will reboot now, execute the VM build script again after rebooting. Press any key to continue..." key
sudo reboot
