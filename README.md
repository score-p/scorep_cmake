# FindScoreP

CMake integration for [Score-P](https://score-p.org).

## Usage

1. Place the contents of the `src` directory somewhere in your
[`CMAKE_MODULE_PATH`](https://cmake.org/cmake/help/latest/variable/CMAKE_MODULE_PATH.html) and include `ScorePUtilities` in your CMake configuration.

2. Call `scorep_mark` on targets which should be instrumented by Score-P.

3. After all targets have been defined call `scorep_determine_instrumentations` and use its output
   to call [`find_package(ScoreP ...)`](https://cmake.org/cmake/help/latest/command/find_package.html).

4. Call `scorep_enable` to enable Score-P instrumentation.

  - it is advised to call everything after step 2 based on an option for a flexible build configuration

  - if you don't want to vendor the `ScorePUtilities` module it should only be included
    when the option is enabled and its used functions replaced with dummies otherwise

### Examples

Examples for using this Score-P integration are located in the `examples` directory.

## ScorePUtilities Module

See [`UTILITIES.md`](docs/UTILITIES.md) and [`AUTODETECT.md`](docs/AUTODETECT.md)

## Find Module

See [`FINDMODULE.md`](docs/FINDMODULE.md)

## Tests

Testing using the [CTest](https://cmake.org/cmake/help/latest/module/CTest.html)
module requires a POSIX compatible shell to be installed.

The following labels exist:

 - `cmake`, indicating a CMake-only test

 - `scorep`, indicating a test requiring Score-P (with supported components based on the other labels and the compiler selected by CMake)

 - `c`, indicating a test requiring a C compiler

 - `openmp`, indicating a test requiring OpenMP

 - `pthread`, indicating a test requiring pthreads

 - `openacc`, indicating a test requiring OpenACC

 - `kokkos`, indicating a test requiring Kokkos with an enabled OpenMP backend

 - `cuda`, indicating a test requiring CUDA

 - `boost`, indicating a test requiring certain boost components

 - `examples`, indicating a test building code examples

The C++ compiler used for compiling examples can be selected with `-DCMAKE_CXX_COMPILER=...`.
