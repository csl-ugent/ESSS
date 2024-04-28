#!/bin/bash

if [ ! -f ".ready" ]; then
    ./install_deps.sh
    exit
fi

set -euxo pipefail

# The instructions used in the artifact appendix and README assume that the user is called "evaluation" and the home directory is "/home/evaluation".

# Install wllvm
pip3 install wllvm
export PATH="$PATH:/home/evaluation/.local/bin"

# Download and install CodeQL
cd
mkdir tools
cd tools
wget https://github.com/github/codeql-action/releases/download/codeql-bundle-20230524/codeql-bundle-linux64.tar.gz
wget https://github.com/github/codeql/archive/refs/tags/codeql-cli/v2.13.3.tar.gz
tar xfz codeql-bundle-linux64.tar.gz
tar xfz v2.13.3.tar.gz
rm codeql-bundle-linux64.tar.gz
rm v2.13.3.tar.gz
export PATH="$PATH:/home/evaluation/tools/codeql"
echo "export PATH=$PATH:/home/evaluation/tools/codeql" >> ~/.bashrc
codeql query compile codeql-codeql-cli-v2.13.3/cpp/ql/src/Critical/MissingNullTest.ql
codeql query compile codeql-codeql-cli-v2.13.3/cpp/ql/src/Critical/ReturnValueIgnored.ql
codeql query compile codeql-codeql-cli-v2.13.3/cpp/ql/src/Critical/InconsistentNullnessTesting.ql
codeql query compile codeql-codeql-cli-v2.13.3/cpp/ql/src/Likely\ Bugs/InconsistentCheckReturnNull.ql
codeql query compile codeql-codeql-cli-v2.13.3/cpp/ql/src/Critical/MissingNegativityTest.ql

# Download and install EESI
cd ~/tools
git clone https://github.com/nielsdos/eesi-updated.git eesi
cd eesi
git checkout 687180d496dadb9110bbfeddb0b5353341f4933b
mkdir build
cd build
cmake ../src
make

# Build Docker images
cd
mkdir deploy
cd deploy
mkdir apisan
cd apisan
wget https://raw.githubusercontent.com/nielsdos/apisan/7273b7fedbff79b8d18cf69f304f2d6e9cee1f89/Dockerfile
wget https://raw.githubusercontent.com/nielsdos/apisan/15b697819610b4dd0671c8f420a552dbf0a46e04/0001.patch
docker build -t apisan .

# Download and checkout benchmarks
cd
mkdir benchmarks
cd benchmarks
git clone https://github.com/openssl/openssl.git
cd openssl
git checkout 8d927e55b751ba1af6c08cd4e37d565a43c56157
cd ..
git clone https://github.com/openssh/openssh-portable.git
cd openssh-portable/
git checkout 36c6c3eff5e4a669ff414b9daf85f919666e8e03
cd ..
git clone https://github.com/php/php-src.git
cd php-src
git checkout abc41c2e008d4d861e047bd67a616cb1ed324677
cd ..
git clone https://github.com/pnggroup/libpng.git
cd libpng
git checkout e519af8b49f52c4ac400f50f23b48ebe36a5f4df
cd ..
git clone https://github.com/freetype/freetype.git
cd freetype
git checkout bd6208b7126888826b1246bbe06c166afd177516
cd ..
git clone https://github.com/webmproject/libwebp.git
cd libwebp/
git checkout 233960a0ad8c640acd458a6966dea09e12c1325a
cd ..
git clone https://github.com/madler/zlib.git
cd zlib
git checkout 12b345c4309b37ab905e7e702021c1c2d2c095cc

# Download and build ESSS
cd
git clone https://github.com/csl-ugent/ESSS.git
cd ESSS
cd llvm
mkdir llvm-project
cd llvm-project
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang-14.0.6.src.tar.xz
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz
tar xf llvm-14.0.6.src.tar.xz 
tar xf clang-14.0.6.src.tar.xz 
mv clang-14.0.6.src clang
mv llvm-14.0.6.src llvm
cd ..
./build-llvm.sh
cd ../analyzer
make

# Setup wllvm
export LLVM_COMPILER=clang
export LLVM_COMPILER_PATH=$HOME/ESSS/llvm/llvm-project/prefix/bin
alias wllvm="wllvm -g"

# Build musl
cd
mkdir build-musl-1.2.3
cd build-musl-1.2.3
wget https://git.musl-libc.org/cgit/musl/snapshot/musl-1.2.3.tar.gz
tar -xvf musl-1.2.3.tar.gz
mv musl-1.2.3 musl
cd musl
mkdir prefix
export CC=wllvm
WLLVM_CONFIGURE_ONLY=1 ./configure --prefix="$(realpath prefix)"
make -j4
make install
extract-bc prefix/lib/libc.so

# Build benchmark: OpenSSL
cd ~/benchmarks
cd openssl
mkdir -p tmp
CC=wllvm CXX=wllvm++ ./Configure -g
make -j4
extract-bc --manifest libcrypto.so
extract-bc --manifest libssl.so
cat *.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
$LLVM_COMPILER_PATH/llvm-link libcrypto.so.bc --override=libssl.so.bc -o combined.bc

# Build benchmark: OpenSSH
cd ~/benchmarks
cd openssh-portable
mkdir -p tmp
autoreconf
CC=wllvm CXX=wllvm++ ./configure --with-pam --with-zlib
make -j6
extract-bc --manifest sshd
extract-bc --manifest scp
extract-bc --manifest ssh-agent
extract-bc --manifest ssh-add
extract-bc --manifest ssh
extract-bc --manifest ssh-sk-helper
extract-bc --manifest ssh-pkcs11-helper
extract-bc --manifest sftp
extract-bc --manifest sftp-server
extract-bc --manifest ssh-keygen
extract-bc --manifest ssh-keyscan
extract-bc --manifest ssh-keysign
cat *.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done

# Build benchmark: libwebp
cd ~/benchmarks
cd libwebp
mkdir -p tmp
mkdir -p prefix
./autogen.sh
CFLAGS="-g" CC=wllvm CXX=wllvm++ ./configure --prefix="$(realpath prefix)/usr/local"
make -j4
make install
extract-bc --manifest prefix/usr/local/lib/libwebp.so
cat prefix/usr/local/lib/libwebp.so.llvm.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
$LLVM_COMPILER_PATH/llvm-link tmp/.*.o.bc -o combined.bc

# Build benchmark: libpng
cd ~/benchmarks
cd libpng
mkdir -p tmp
CC=wllvm CXX=wllvm++ ./configure
make -j4
extract-bc --manifest ./.libs/libpng16.a
cat ./.libs/*.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done

# Build benchmark: freetype
cd ~/benchmarks
cd freetype
mkdir -p tmp
./autogen.sh
CC=wllvm CXX=wllvm++ ./configure --with-zlib --with-png
make -j4
extract-bc --manifest ./objs/.libs/libfreetype.a
cat ./objs/.libs/*.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done

# Build benchmark: php
cd ~/benchmarks
cd php-src
mkdir -p tmp
./buildconf
CC=wllvm CXX=wllvm++ ./configure --disable-gcc-global-regs --enable-bcmath=shared --enable-calendar=shared --enable-dba=shared --enable-exif=shared --enable-ftp=shared --enable-gd=shared --enable-intl=shared --enable-mbstring --enable-pcntl --enable-shmop=shared --enable-soap=shared --enable-sockets=shared --enable-sysvmsg=shared --enable-sysvsem=shared --enable-sysvshm=shared --with-bz2=shared --with-curl=shared --with-enchant=shared --with-ffi=shared --with-gdbm --with-gettext=shared --with-gmp=shared --with-iconv=shared --with-imap-ssl --with-imap=shared --with-kerberos --with-ldap=shared,/usr --with-ldap-sasl --with-mhash --with-mysql-sock=/run/mysqld/mysqld.sock --with-mysqli=shared,mysqlnd --with-openssl --with-password-argon2 --with-pdo-dblib=shared --with-pdo-mysql=shared,mysqlnd --with-pdo-odbc=unixODBC,/usr/ --with-pdo-pgsql=shared --with-pdo-sqlite=shared --with-pgsql=shared --with-readline --with-snmp=shared --with-sodium=shared --with-sqlite3=shared --with-tidy=shared --with-unixODBC=shared --with-xsl=shared --with-zip=shared --with-zlib
make -j4
find . -type f -name "*.o.bc"| sort|uniq&>./sapi/cli/php.llvm.manifest
cat ./sapi/cli/php.llvm.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done

# Build benchmark: zlib
cd ~/benchmarks
cd zlib
mkdir -p tmp
CC=wllvm CXX=wllvm++ CFLAGS="-g" CXXFLAGS="-g" ./configure
make -j4
extract-bc --manifest libz.so.1
cat *.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
$LLVM_COMPILER_PATH/llvm-link tmp/.*.o.bc -o combined.bc

# Build OpenSSL 1.1.1 for old httpd from APIMU4C
cd
mkdir build-openssl-1.1.1
cd build-openssl-1.1.1
git clone https://github.com/openssl/openssl.git
cd openssl
git checkout OpenSSL_1_1_1w
mkdir prefix
./Configure -g linux-x86_64-clang --prefix="$(realpath prefix)"
make -j4
make install

# Get APIMU4C (with curl patch)
cd
git clone https://github.com/imchecker/compsac19.git
mv compsac19 APIMU4C
cd APIMU4C/APIMU4C
unzip -d curl-curl-7_63_0_patched curl-curl-7_63_0_patched.zip
unzip -d httpd-2.4.37_patched httpd-2.4.37_patched.zip
unzip -d openssl-1-1-pre8_patched openssl-1-1-pre8_patched.zip

# Build APIMU4C curl benchmark
cd ~/APIMU4C/APIMU4C/curl-curl-7_63_0_patched/curl-curl-7_63_0
wget https://raw.githubusercontent.com/csl-ugent/ESSS/main/vm/curl-apimu4c-patch.patch
patch -p0 < curl-apimu4c-patch.patch
mkdir -p tmp
CFLAGS="-g" CC=wllvm CXX=wllvm++ ./configure --enable-smtp --enable-dict --enable-tftp --with-ssl --enable-optimize --disable-ldap --enable-debug
make -j4
extract-bc --manifest ./src/.libs/curl
extract-bc --manifest ./lib/.libs/libcurl.so.4.5.0
cat src/.libs/curl.llvm.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
cat lib/.libs/libcurl.so.4.5.0.llvm.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done

# Build APIMU4C openssl benchmark
cd ~/APIMU4C/APIMU4C/openssl-1-1-pre8_patched/openssl-1-1-pre8_patched
make clean # remove build files from packer's build
mkdir -p tmp
CC=wllvm CXX=wllvm++ ./Configure -g linux-x86_64-clang
make -j4
extract-bc --manifest libcrypto.so
extract-bc --manifest libssl.so
cat *.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
$LLVM_COMPILER_PATH/llvm-link libcrypto.so.bc --override=libssl.so.bc -o combined.bc

# Build APIMU4C httpd benchmark
cd ~/APIMU4C/APIMU4C/httpd-2.4.37_patched/httpd-2.4.37
mkdir -p tmp
CFLAGS='-g -Xclang -disable-O0-optnone' CC=wllvm CXX=wllvm++ ./configure --enable-ssl=~/build-openssl-1.1.1/openssl/prefix/  --enable-md --enable-lua --enable-http --enable-mods-static=all
make -j4
extract-bc --manifest .libs/httpd
cat .libs/*.manifest | sort | uniq | awk 'NF' | while read line; do cp -nf $line tmp; done
