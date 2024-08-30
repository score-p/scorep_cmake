# Find Module

The find module `FindScoreP.cmake` can be used independently of any instrumentation infrastructure
while supporting multiple installed versions and version ranges.

## Components

`COMPILER_<LANGUAGE>_<PATH>`, representing the compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`MPI_COMPILER_<LANGUAGE>_<PATH>`, representing the MPI compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`SHMEM_COMPILER_<LANGUAGE>_<PATH>`, representing the SHMEM compiler suite used by Score-P.

Possible values for LANGUAGE:

 - C99

 - CXX11

 - Fortran

 - Fortran77

PATH contains the path to the requested compiler executable.

`PTHREADS`, representing pthread support.

`MPP_<PARADIGM>`, representing multi-process support.

Possible values for PARADIGM:

 - mpi

 - shmem

`IO_<PARADIGM>`, representing I/O recording support.

Possible values for PARADIGM:

 - posix

`COMPILER`, representing compiler instrumentation support.

`CUDA`, representing CUDA instrumentation support.

`OMP_<LANG>`, representing OpenMP language support.

Possible values for LANG:

 - C

 - CXX

 - Fortran

`OPARI2`, representing OPARI2 instrumentation support.

`OMPT`, representing OMPT instrumentation support.

`PDT`, representing PDT instrumentation support.

`OPENCL`, representing OpenCL support.

`OPENACC`, representing OpenACC support.

`MEMORY`, representing memory usage instrumentation support.

`LIBWRAP`, representing library wrapper support

`KOKKOS`, representing Kokkos support

`HIP`, representing HIP support.

## Imported Targets

`ScoreP::ScoreP`, the scorep executable.

`ScoreP::Config`, the scorep-config executable.

`ScoreP::Info`, the scorep-info executable.

## Result Variables

`SCOREP_FOUND`, True if a matching Score-P installation was found.

`SCOREP_<COMPONENT>_FOUND`, True if the component was found.

`SCOREP_EXECUTABLE`, the path of the scorep executable.

`SCOREP_CONFIG_EXECUTABLE`, the path of the scorep-config executable.

`SCOREP_INFO_EXECUTABLE`, the path of the scorep-info executable

`SCOREP_VERSION_STRING`, the version of Score-P found.