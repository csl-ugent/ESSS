# ESSS

The artifact evaluation VM already contains the ESSS tool and the LLVM toolchain pre-built.
The LLVM version used is 14.0.6.
The reason we perform the build ourselves rather than a distro-provided version is to ensure reproducibility of the exact results without having potentially-interfering distro-specific patches.


## Tool build instructions

If you wish to manually build the ESSS tool and/or the LLVM toolchain, follow these instructions.

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

The tool can be executed directly by executing `./kanalyzer` inside `/home/evaluation/ESSS/analyzer/build/lib`.
The arguments are the paths to the bitcode files. The output is written to stdout.
The tool also contains some optional arguments that can be listed using the `--help` option.

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
