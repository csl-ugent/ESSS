# ESSS

ESSS is a static analysis tool to detect missing and incorrect error checks in C and C++ codebases.
The tool automatically deduces error specifications for functions, without needing a priori knowledge, and then it finds code locations where error checks are either missing or inconsistent with those specifications. 

This repository contains the ESSS source code, as well as the scripts and data to run the tool and EESI on the benchmarks used in the paper.

The artifact evaluation VM already contains the ESSS tool and the LLVM toolchain pre-built.
The LLVM version used is 14.0.6.
The reason we perform the build ourselves rather than a distro-provided version is to ensure reproducibility of the exact results without having potentially-interfering distro-specific patches.

The tool is supported on any recent Linux distribution. We confirmed that it works for sure on Ubuntu 22.04.
No special hardware requirements are necessary to run ESSS, although we do recommend at least 8 GiB of RAM. Even though the tool can run with less, it may take up to 2 GiB of RAM for the largest benchmark, leaving fewer memory for other processes.

## Tool build instructions

If you wish to manually build the ESSS tool and/or the LLVM toolchain, follow these instructions.

### Dependencies

The following dependencies are required to build the ESSS tool:
  * CMake
  * A C and C++ compiler to build the LLVM dependency

### Build LLVM
```sh
$ cd /home/evaluation/ESSS/llvm
$ mkdir llvm-project
$ cd llvm-project
$ wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang-14.0.6.src.tar.xz
$ wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/llvm-14.0.6.src.tar.xz
$ tar xf llvm-14.0.6.src.tar.xz 
$ tar xf clang-14.0.6.src.tar.xz 
$ mv clang-14.0.6.src clang
$ mv llvm-14.0.6.src llvm
$ cd ..
$ ./build-llvm.sh
```

### Build the analyzer
```sh
$ cd /home/evaluation/ESSS/analyzer
$ make
```

This will build the analyzer tool and place the binary in the `/home/evaluation/ESSS/analyzer/build/lib` directory.

## Tool usage instructions

### Prerequisites

When applying the tool to your own benchmarks, you'll need to generate the bitcode files first.
To do so, you should use [wllvm](https://github.com/travitch/whole-program-llvm). Follow the installation instructions on the wllvm README page.

Furthermore, we also rely on [musl](https://musl.libc.org/) to infer specifications from libc.
While not strictly necessary for the tool to work, this will increase the precision of the inferred specifications.
The version used in the paper was musl 1.2.3, but any version should work.
These are the steps to build musl into a bitcode file:
```sh
cd musl
mkdir prefix
export CC=wllvm
./configure --prefix="$(realpath prefix)"
make -j4
make install
extract-bc prefix/lib/libc.so
```

### Compiling a program

To compile a program for use with our tool, you should follow the build instructions of said program, but use the wllvm wrapper as a compiler. This will result in bitcode files that can be analyzed by our tool. Ideally, you pass all bitcode files separately to our tool, as giving the entire program at once (which is what happens by default by extract-bc) will be slower to process than separate files.

### Running the tool

The tool can be executed directly by executing `./kanalyzer` inside `/home/evaluation/ESSS/analyzer/build/lib`.
The arguments are the paths to the bitcode files. The output is written to stdout.
The tool also contains some optional arguments that can be listed using the `--help` option.

To run the tool for inferring specifications and detecting bugs in a program, you can use the following command:
```sh
./kanalyzer /path/to/mysl/libc.so.bc /path/to/bitcode1.bc /path/to/bitcode2.bc ...
```

The output will be written to stdout, this includes the inferred specifications and the bugs.

### Options

The tool supports configuration options that can be set using command line arguments.

The most important configuration options are:
  * `--missing-ct`: The threshold for missing checks. Only reports with a score that is at least this value will be reported. The default value is 0.725.
  * `--incorrect-ct`: The threshold for incorrect specifications. Only reports with a score that is at least this value will be reported. The default value is 0.725.

Other useful options include:
  * `--refine-vsa`: This enables taking the intersection between the error value set and the possible constant return values of the function to increase the precision of the error specifications. Defaults to true.
  * `--st`: Association analysis confidence between [0, 1]. The higher the more confident the association must be. Defaults to 0.925.
  * `--interval-ct`: Confidence threshold between [0, 1]. The higher the more similar the error intervals should be.
  * `-c <number>`: Sets the number of threads to `<number>`. Not thoroughly tested for values other than 1.

There are a few debugging options as well:
  * `--print-random-non-void-function-samples <number>`: How many random non-void function names to print, useful for sampling functions to compute a recall. Defaults to 0.
  * `--ssc`: Prints the detected error checks out separately. Defaults to false.

### Minimal example

We provide a minimal example in the `example` directory. There is some simple toy code in `example/example.c` that you can run through the analyzer using the `example/build_and_run.sh` script. Upon running you should get the following output:

```
Function error return intervals (3, pre-libc-pruning 3):
Function: func {return index 0}
  [0, 0]
Function: generate_error {return index 0}
  [-2147483648, -1] U [1, 2147483647]
Function: malloc {return index 0}
  [0, 0]
```

## Repository structure

The repository is structured as follows. Files adapted from [Crix](https://github.com/umnsec/crix) are marked as such.

```
📁 ESSS
│ ├── 📁 analyzer [the ESSS tool source code]
│ │   │ ├── 📃 Makefile [adapted from Crix]
│ │   │ └── 📁 src
│ │   │     │ ├── 📃 ...
│ │   │     │ └── 📁 src
│ │   │     │     │ ├── 📃 Analyzer.{cc, h} [Entry point of the application, adapted from Crix]
│ │   │     │     │ ├── 📃 CallGraph.{cc, h} [MLTA component from Crix]
│ │   │     │     │ ├── 📃 ClOptForward.h [Forward declarations of command line options]
│ │   │     │     │ ├── 📃 Common.{cc, h} [Common utility functions, adapted from Crix]
│ │   │     │     │ ├── 📃 DataFlowAnalysis.{cc, h} [Dataflow analysis helpers]
│ │   │     │     │ ├── 📃 DebugHelpers.{cc, h} [Debugging helpers]
│ │   │     │     │ ├── 📃 EHBlockDetector.{cc, h} [Specification inference component]
│ │   │     │     │ ├── 📃 ErrorCheckViolationFinder.{cc, h} [Bug detection component]
│ │   │     │     │ ├── 📃 FunctionErrorReturnIntervals.{cc, h} [Data structure file]
│ │   │     │     │ ├── 📃 FunctionVSA.{cc, h} [Value set analysis of return values component]
│ │   │     │     │ ├── 📃 Helpers.{cc, h} [Common utility functions]
│ │   │     │     │ ├── 📃 Interval.{cc, h} [Interval data structure]
│ │   │     │     │ ├── 📃 Lazy.h [Lazy execution utility class]
│ │   │     │     │ ├── 📃 MLTA.{cc, h} [MLTA component from Crix]
│ │   │     │     │ └── 📃 PathSpan.h [Data structure to store (parts of) paths]
│ └── 📁 evaluation [Scripts and data to run the tool on the benchmarks]
│     │ ├── 📁 benchmark-instructions [Instructions to compile each benchmark into bitcode files]
│     │ ├── 📃 ...
│     │ ├── 📃 eesi-<program>-output [Our EESI output for <program>]
│     │ ├── 📃 eesi-<program>-precision [Random sample from EESI's output for <program> for precision calculation]
│     │ ├── 📃 run-eesi-<program>.sh [Runs EESI for <program> (e.g. openssl)]
│     │ ├── 📃 my-<program>-output [Our ESSS output for <program>]
│     │ ├── 📃 run-my-<program>.sh [Runs ESSS for <program> (e.g. openssl)]
│     │ ├── 📃 <program>-bugs [Bug categorisations for <program> (e.g. openssl)]
│     │ ├── 📃 <program>-recall-sample [Random sample from error-returning functions in <program> for recall calculation]
│     │ ├── 📃 <program>-precision-ground-truth [Ground truth for precision evaluation for ESSS]
│     │ ├── 📃 <program>-random-functions-for-precision-my-tool [Random sample from ESSS's output for <program> for precision calculation]
│     │ ├── 📃 compute_my_stats.py [Computes stats for ESSS for a program]
│     │ └── 📃 compute_eesi_stats.py [Computes stats for EESI for a program]
```

In particular, the specification inference is implemented in EHBlockDetector.cc and the bug detection in ErrorCheckViolationFinder.cc.

## Evaluation scripts

The instructions for running each benchmark are provided in the `evaluation/benchmark-instructions` directory.
To run one of the benchmarks, execute the corresponding script in the `evaluation` directory (as described in the above repository structure overview).

* `compute_my_stats.py`: This script computes the precision, recall, and F1 score of the ESSS tool for a given benchmark.
* `compute_eesi_stats.py`: This script computes the precision, recall, and F1 score of the EESI tool for a given benchmark.
* `run-eesi-<program>.sh`: This script runs the EESI tool on the given benchmark.
* `run-my-<program>.sh`: This script runs the ESSS tool on the given benchmark.

## Tool evaluation

To ease the evaluation, we provided for each benchmark a run script to run the tool.
These can be found in `/home/evaluation/ESSS/evaluation`:
  * `run-my-openssl.sh`
  * `run-my-openssh.sh`
  * `run-my-php.sh`
  * `run-my-zlib.sh`
  * `run-my-libpng.sh`
  * `run-my-freetype.sh`
  * `run-my-libwebp.sh`

## Virtual Machine

The evaluation artifact is provided as a [VirtualBox VM image](https://zenodo.org/doi/10.5281/zenodo.10843435) on Zenodo.
To build the VM image, we started from a Ubuntu 22.04 LTS (x86-64) installation.
We can then use the script provided in `vm/build-vm.sh` to install and setup everything needed for the evaluation.

## License

This tool is based on the [Crix](https://github.com/umnsec/crix) tool from the University of Minnesota.
In particular, we reuse the MLTA component of Crix.
ESSS is distributed under the same license.

## More details

Link to the Usenix paper publication page: https://www.usenix.org/conference/usenixsecurity24/presentation/dossche

Link to the final publication PDF: https://www.usenix.org/system/files/usenixsecurity24-dossche.pdf

```
@inproceedings{dossche2024inferenceoferrorspecifications,
  author       = {Niels Dossche and Bart Coppens},
  title        = {{Inference of Error Specifications and Bug Detection Using Structural Similarities}},
  booktitle    = {33rd {USENIX} Security Symposium ({USENIX} Security 2024)},
  year         = {2024},
  month        = {August},
  address      = {Philadelphia, PA},
}
```

