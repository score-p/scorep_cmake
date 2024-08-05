include("${CMAKE_CURRENT_LIST_DIR}/utils.cmake")
include(ScorePUtilities)

_scorep_arguments2settings("" 10 TEST1)
_scorep_arguments2settings("" 10 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "")

_scorep_arguments2settings("--openacc;--user;--thread=omp" 10 TEST1)
_scorep_arguments2settings("--compiler;--openacc;--thread=omp:ompt" 10 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "--openacc;--user;--thread=omp:ompt;--compiler")

_scorep_arguments2settings("--nocompiler;--openacc;--user;--thread=omp" 10 TEST1)
_scorep_arguments2settings("--compiler;--noopenacc;--thread=omp:ompt" 100 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "--nocompiler;--openacc;--user;--thread=omp")


_scorep_arguments2settings("--pdt=a -b -c;--io=a,b,c;-x;-y" 10 TEST1)
_scorep_arguments2settings("--pdt;--io=c,d,e;-z" 10 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "--pdt=a -b -c;--io=a,b,c,c,d,e;-x;-y;-z")

_scorep_arguments2settings("--opencl:a" 10 TEST1)
_scorep_arguments2settings("--opencl" 10 TEST2)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "--opencl:a")

_scorep_arguments2settings("--thread=pthread" 10 TEST1)
_scorep_arguments2settings("--thread=omp" 10 TEST2)
_scorep_arguments2settings("--thread=omp" 1 TEST3)
_scorep_merge_settings(TEST1 TEST2 MERGED)
_scorep_merge_settings(TEST3 MERGED MERGED)
_scorep_settings2arguments(MERGED merged)
_check_lists_equal("${merged}" "--thread=omp")
