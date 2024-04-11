# ESSS

The artifact evaluation VM already contains the ESSS tool and the LLVM toolchain pre-built.
The LLVM version used is 14.0.6.
The reason we perform the build ourselves rather than a distro-provided version is to ensure reproducibility of the exact results without having potentially-interfering distro-specific patches.


## Tool build instructions

If you wish to manually build the ESSS tool and/or the LLVM toolchain, follow these instructions.

### Dependencies

The following dependencies are required to build the ESSS tool:
  * CMake
  * A C and C++ compiler to build the LLVM dependency

### Build LLVM
```sh
$ cd /home/evaluation/ESSS/llvm
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
Additionally, the _optional_ options `--missing-ct=0.725` and `--incorrect-ct=0.725` can be used to set the threshold for missing and incorrect specifications, respectively. They are 0.725 by default.

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

## License

This tool is based on the [Crix](https://github.com/umnsec/crix) tool from the University of Minnesota.
In particular, we reuse the MLTA component of Crix
ESSS is distributed under the same license.

## More details

Link to paper: TBD

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

