CUR_DIR = $(shell pwd)
LLVM_BUILD := ${CUR_DIR}/../llvm/llvm-project/prefix
ANALYZER_DIR := ${CURDIR}/src
ANALYZER_BUILD := ${CURDIR}/build


UNAME := $(shell uname)
ifeq ($(UNAME), Linux)
	NPROC := ${shell nproc}
else
	NPROC := ${shell sysctl -n hw.ncpu}
endif

build_analyzer_func = \
	(mkdir -p ${2} \
		&& cd ${2} \
		&& PATH=${LLVM_BUILD}/bin:${PATH} \
			LLVM_TOOLS_BINARY_DIR=${LLVM_BUILD}/bin \
			LLVM_LIBRARY_DIRS=${LLVM_BUILD}/lib \
			LLVM_INCLUDE_DIRS=${LLVM_BUILD}/include \
			CC=gcc CXX=g++ \
			cmake ${1}	\
				-DCMAKE_BUILD_TYPE=Release \
				-DLLVM_ENABLE_ASSERTIONS=OFF \
				-DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
				-DCMAKE_CXX_FLAGS_RELEASE="-std=c++20 -fno-rtti -gdwarf-4 -Og -march=native -fpic -Wall -Wno-type-limits -Wextra -Wno-cpp -Wno-unused-parameter -Wl,--build-id -Wno-unused-command-line-argument" \
		&& make -j${NPROC})

all: kanalyzer

kanalyzer:
	$(call build_analyzer_func, ${ANALYZER_DIR}, ${ANALYZER_BUILD})

clean:
	rm -rf ${ANALYZER_BUILD}
