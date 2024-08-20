foreach(component "DUMMY_COMPONENT" "COMPILER_C99_/usr/bin/dummy" "OMP_DUMMY")
    find_package(
        ScoreP
        "0.0.0.1"
        EXACT
        COMPONENTS "${component}"
    )

    if(ScoreP_FOUND)
        message(FATAL_ERROR "found Score-P with wrong component: ${component}")
    endif()
endforeach()


find_package(
    ScoreP
    "0.0.0.1"
    EXACT
    REQUIRED
    COMPONENTS "COMPILER"
    OPTIONAL_COMPONENTS "DUMMY_COMPONENT"
)

if(NOT ScoreP_COMPILER_FOUND)
    message(FATAL_ERROR "ScoreP_COMPILER_FOUND not set")
endif()
if(ScoreP_DUMMY_COMPONENT_FOUND)
    message(FATAL_ERROR "ScoreP_DUMMY_COMPONENT_FOUND set")
endif()


find_package(
    ScoreP
    "0.0.0.1"
    EXACT
    REQUIRED
    COMPONENTS
    "COMPILER_C99_/usr/bin/gcc"
    "COMPILER_CXX11_/usr/bin/g++"
    "COMPILER_Fortran_/usr/bin/gfortran"
    "COMPILER_Fortran77_/usr/bin/gfortran"
    "MPI_COMPILER_C99_/usr/bin/mpicc"
    "MPI_COMPILER_CXX11_/usr/bin/mpicxx"
    "MPI_COMPILER_Fortran_/usr/bin/mpif90"
    "MPI_COMPILER_Fortran77_/usr/bin/mpif77"
    "SHMEM_COMPILER_C99_/usr/bin/oshcc"
    "SHMEM_COMPILER_CXX11_/usr/bin/oshcc"
    "SHMEM_COMPILER_Fortran_/usr/bin/oshfort"
    "SHMEM_COMPILER_Fortran77_/usr/bin/oshfort"
    "PTHREAD"
    "MPP_mpi"
    "MPP_shmem"
    "IO_posix"
    "COMPILER"
    "CUDA"
    "OMP_C"
    "OMP_CXX"
    "OMP_Fortran"
    "OPARI2"
    "OMPT"
    "PDT"
    "OPENCL"
    "OPENACC"
    "MEMORY"
    "LIBWRAP"
    "KOKKOS"
    "HIP"
)